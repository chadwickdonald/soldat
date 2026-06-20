require 'csv'

class DataImportService
  Result = Struct.new(:event_count, :skipped_count, :station_count, :csv_1m, :csv_5m, keyword_init: true)

  def initialize(stations_json:, start_date:, end_date:, generate_csv: false, site_name: nil)
    @stations    = stations_json
    @start_date  = start_date
    @end_date    = end_date
    @generate_csv = generate_csv
    @site_name   = site_name
    @api_key     = ENV['SCADA_API_KEY']
  end

  def call
    datums = flatten_datums
    items  = process_in_parallel(datums)

    event_count   = items.sum { |i| i[:event_count] }
    skipped_count = items.sum { |i| i[:skipped_count] }

    csv_1m = csv_5m = nil
    if @generate_csv
      csv_1m, csv_5m = build_csvs(items)
    end

    Result.new(
      event_count:   event_count,
      skipped_count: skipped_count,
      station_count: datums.size,
      csv_1m:        csv_1m,
      csv_5m:        csv_5m
    )
  end

  private

  def flatten_datums
    @stations.flat_map { |_station_key, entries| entries }
  end

  def process_in_parallel(datums)
    datums.filter_map { |datum| process_datum(datum) }
  end

  def process_datum(datum)
    datum = datum.transform_keys(&:to_s)

    segment = ScadaSegment.find_by(apcode: datum["segment_apcode"], name: datum["segment_name"])
    return nil unless segment

    mloc = segment.scada_mlocs.find_by(apcode: datum["mloc_apcode"]) ||
           ScadaMloc.find_by(apcode: datum["mloc_apcode"])
    return nil unless mloc

    measurement = mloc.scada_measurements.first
    return nil unless measurement

    source = measurement.scada_measurement_sources
                        .find_by(calc_period: datum["source_calc_period"])
    return nil unless source

    site_uuid = segment.site_id

    existing_count = source.scada_events.between(@start_date, @end_date).count

    if existing_count > 0
      events = source.scada_events.between(@start_date, @end_date).ordered.to_a
      return build_item(datum, measurement, source, events, skipped: existing_count)
    end

    api_events = fetch_from_api(source, measurement, site_uuid)
    persisted  = bulk_insert_events(api_events, source, measurement, site_uuid)

    build_item(datum, measurement, source, persisted, skipped: 0)
  rescue => e
    Rails.logger.error "DataImportService#process_datum error: #{e.message} — datum=#{datum.inspect}"
    nil
  end

  def fetch_from_api(source, measurement, site_uuid)
    service = Pf::EventDataService2.new(@api_key)
    service.fetch_events(
      start_date:  @start_date,
      end_date:    @end_date,
      source_uuid: source.uuid
    )
  rescue => e
    Rails.logger.error "API fetch failed for source #{source.uuid}: #{e.message}"
    []
  end

  def bulk_insert_events(api_events, source, measurement, site_uuid)
    return [] if api_events.blank?

    now = Time.current
    rows = api_events.filter_map do |ev|
      date = parse_event_date(ev["date"])
      next unless date
      {
        measurement_source_id: source.uuid,
        site_id:               site_uuid,
        measurement_apcode:    measurement.apcode,
        cp_name:               source.calc_period,
        date:                  date,
        val:                   ev["val"],
        created_at:            now,
        updated_at:            now
      }
    end

    return [] if rows.empty?

    ScadaEvent.upsert_all(
      rows,
      unique_by: :index_scada_events_on_source_and_date,
      update_only: [:val]
    )

    source.scada_events.between(@start_date, @end_date).ordered.to_a
  end

  def parse_event_date(raw)
    return nil if raw.blank?
    if raw.match?(/\A\d{8}T\d{6}Z\z/)
      Time.strptime(raw, "%Y%m%dT%H%M%SZ").utc
    else
      Time.parse(raw).utc
    end
  rescue
    nil
  end

  def build_item(datum, measurement, source, events, skipped:)
    {
      datum:         datum,
      measurement:   measurement,
      source:        source,
      events:        events,
      event_count:   skipped > 0 ? 0 : events.size,
      skipped_count: skipped
    }
  end

  # ── CSV generation (mirrors write_block logic from params_for_event_query.rb) ──

  def build_csvs(items)
    series = build_series(items)
    keys_1m    = series[:period].keys.select { |k| series[:period][k].downcase == "1m" }
    keys_5m    = series[:period].keys.select { |k| series[:period][k].downcase == "5m" }

    [
      keys_1m.any?  ? write_csv_string(keys_1m,  series) : nil,
      keys_5m.any?  ? write_csv_string(keys_5m,  series) : nil
    ]
  end

  def build_series(items)
    meta   = {}
    events = {}
    period = {}
    label  = {}

    items.each do |item|
      next if item[:events].blank?
      d   = item[:datum]
      src = item[:source]
      key = "#{d['mloc_apcode']}-#{d['segment_name']}"

      times = item[:events].map { |e| e.respond_to?(:date) ? e.date : nil }.compact
      dom   = dominant_delta(times)
      p     = dom ? format_period(dom) : src.calc_period.to_s

      period[key] = p
      label[key]  = "#{key}-#{p}"

      meta[key] = {
        "station_id"         => d["station_id"],
        "segment_apcode"     => d["segment_apcode"],
        "segment_name"       => d["segment_name"],
        "mloc_apcode"        => d["mloc_apcode"],
        "source_calc_period" => p,
        "measurement_name"   => item[:measurement].name,
        "eng_unit"           => item[:source].eng_unit,
        "station_type"       => d["station_type"],
        "station_element"    => d["station_element"],
        "relevance"          => d["relevance"]
      }

      events[key] = {}
      item[:events].each do |ev|
        ts = ev.respond_to?(:date) ? ev.date.localtime.strftime("%Y-%m-%d %H:%M:%S") : nil
        events[key][ts] = ev.respond_to?(:val) ? ev.val : nil
      end
    end

    { meta: meta, events: events, period: period, label: label }
  end

  META_VARS = %w[station_id segment_apcode segment_name mloc_apcode source_calc_period
                 measurement_name eng_unit station_type station_element relevance].freeze

  def write_csv_string(keys, series)
    keys = keys.sort_by { |k| series[:meta].dig(k, "station_id").to_s }
    all_times = keys.flat_map { |k| series[:events][k].keys }.uniq.sort

    CSV.generate do |csv|
      csv << ["variable"] + keys.map { |k| series[:label][k] }
      META_VARS.each { |v| csv << [v] + keys.map { |k| series[:meta].dig(k, v) } }
      csv << []
      csv << ["time"] + keys.map { |k| series[:label][k] }
      all_times.each { |ts| csv << [ts] + keys.map { |k| series[:events][k][ts] } }
    end
  end

  def dominant_delta(times)
    return nil if times.size < 2
    deltas = (1...times.size).map { |i| (times[i] - times[i - 1]).to_i.abs }
    deltas.tally.max_by { |_, c| c }&.first
  end

  def format_period(sec)
    return "#{sec}s"  if sec < 60
    mins = sec / 60
    return "#{mins}m" if mins < 60 && (sec % 60).zero?
    "#{mins / 60}h"   if (mins % 60).zero?
  end
end
