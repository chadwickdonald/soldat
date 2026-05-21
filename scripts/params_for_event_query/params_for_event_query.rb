#!/usr/bin/env ruby
# export_events_reshaped.rb
#
# Writes the *reshaped* CSVs directly (same layout as reshape_events_split.rb),
# but now first checks the DB for events for each measurement_source before
# calling the API. If events exist locally in the time window, they are used;
# otherwise the API is called and persisted events are used.
#
# Usage:
#   ruby params_for_event_query.rb stations.json out_1m.csv out_5m.csv [--others other_periods.csv]

require_relative '../../config/environment'
require 'csv'
require 'json'
require 'time'

# -----------------------
# CLI & constants
# -----------------------
INPUT   = ARGV[0] or abort("Usage: ruby #{File.basename($0)} stations.json out_1m.csv out_5m.csv [--others other.csv]")
OUT_1M  = ARGV[1] or abort("Please provide path for out_1m.csv")
OUT_5M  = ARGV[2] or abort("Please provide path for out_5m.csv")

OTHERS_PATH = begin
  if ARGV.include?("--others")
    i = ARGV.index("--others")
    ARGV[i + 1]
  end
end

@api_key    = ENV['SCADA_API_KEY']
@start_date = '20250901T000000Z'
@end_date   = '20250908T000000Z'
@site_uuid  = ScadaSite.find_by_name("Danish Fields - T3").uuid

# -----------------------
# Helpers
# -----------------------

def log(msg)
  puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{msg}"
end

def fmt_ev_time(s, tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
  return nil if s.nil? || s.empty?
  t = Time.strptime(s, "%Y%m%dT%H%M%SZ")   # parse "20250901T010000Z"
  t = (tz == :local) ? t.getlocal : t.utc
  t.strftime(fmt)
rescue
  nil
end

def to_utc_compact(t)
  case t
  when String
    return t if t.match?(/\A\d{8}T\d{6}Z\z/)
    Time.parse(t).utc.strftime("%Y%m%dT%H%M%SZ") rescue t
  when Time, DateTime
    t.to_time.utc.strftime("%Y%m%dT%H%M%SZ")
  else
    t.to_s
  end
end

def apply_time_window(rel, em, start_z, end_z)
  time_col = em[:cols][:time]
  arel     = rel.klass.arel_table[time_col]

  if em[:time_is_datetime]
    start_t = Time.strptime(start_z, "%Y%m%dT%H%M%SZ").utc rescue Time.parse(start_z).utc
    end_t   = Time.strptime(end_z,   "%Y%m%dT%H%M%SZ").utc rescue Time.parse(end_z).utc
    rel.where(arel.gteq(start_t)).where(arel.lteq(end_t))
  else
    start_s = start_z
    end_s   = end_z
    qcn = rel.klass.connection.quote_column_name(time_col)
    rel.where("#{qcn} >= ? AND #{qcn} <= ?", start_s, end_s)
  end
end

def format_period_from_seconds(sec)
  sec = sec.to_i
  return "#{sec}s" if sec < 60
  if (sec % 60).zero?
    mins = sec / 60
    return "#{mins}m" if mins < 60
    if (mins % 60).zero?
      hours = mins / 60
      return "#{hours}h" if hours < 24
      if (hours % 24).zero?
        days = hours / 24
        return "#{days}d"
      end
    end
  end
  "#{sec}s"
end

def dominant_delta_seconds(times)
  return nil if times.length < 2
  deltas = []
  (1...times.length).each { |i| deltas << (times[i] - times[i - 1]).to_i.abs }
  return nil if deltas.empty?
  deltas.tally.max_by { |_, c| c }[0]
end

SeriesKey = Struct.new(:mloc_apcode, :segment_name) do
  def base_label
    "#{mloc_apcode}-#{segment_name}"
  end
end

def write_block(path, keys, series_label, series_meta, series_events)
  return if path.nil? || path.empty?
  return if keys.nil? || keys.empty?

  # Sort columns by station_id (ascending), with stable tie-breakers.
  keys = keys.sort_by do |k|
    sid_raw = series_meta.dig(k, "station_id").to_s
    sid_num =
      begin
        Integer(sid_raw, 10)
      rescue ArgumentError, TypeError
        nil
      end

    # Numeric station_ids first (ascending), then non-numeric, then label.
    [
      sid_num.nil? ? 1 : 0,
      sid_num || sid_raw, # if non-numeric, sort by raw string
      series_label[k].to_s
    ]
  end

  all_times = series_events.values_at(*keys).compact.flat_map(&:keys).uniq
  all_times.sort_by! { |s| Time.parse(s) rescue s }

  # station_id first in the metadata rows
  meta_vars = %w[
    station_id
    segment_apcode
    segment_name
    mloc_apcode
    source_calc_period
    measurement_name
    eng_unit
    station_type
    station_element
    relevance
  ]

  CSV.open(path, "w") do |csv|
    csv << ["variable"] + keys.map { |k| series_label[k] }
    meta_vars.each do |var|
      csv << [var] + keys.map { |k| series_meta[k][var] }
    end
    csv << []
    csv << ["time"] + keys.map { |k| series_label[k] }
    all_times.each do |ts|
      csv << [ts] + keys.map { |k| series_events[k][ts] }
    end
  end
end

# -----------------------
# Event model autodetect + DB fetch helpers
# -----------------------

# Try to find an events model and the key/value/time columns.
def detect_events_model
  klass = ScadaEvent
  unless klass.respond_to?(:column_names)
    log "ScadaEvent does not expose column_names; cannot use DB."
    return nil
  end

  cols   = klass.column_names
  schema = klass.columns_hash

  source_uuid_col = %w[source_uuid scada_measurement_source_uuid measurement_source_uuid].find { |c| cols.include?(c) }
  source_id_col   = %w[scada_measurement_source_id measurement_source_id source_id].find { |c| cols.include?(c) }
  meas_apc_col    = %w[measurement_apcode scada_measurement_apcode apcode].find { |c| cols.include?(c) }
  meas_id_col     = %w[scada_measurement_id measurement_id].find { |c| cols.include?(c) }
  site_id_col     = %w[site_id scada_site_id].find { |c| cols.include?(c) }
  cp_col          = %w[calc_period cp_name period].find { |c| cols.include?(c) }

  time_candidates = %w[date event_time timestamp occurred_at observed_at time at recorded_at event_at]
  time_col = time_candidates.find { |c| cols.include?(c) } || 'date'

  sql_type = schema[time_col]&.sql_type&.downcase || ""
  time_is_datetime = sql_type.include?("timestamp") || sql_type.include?("datetime") || sql_type.include?("timestamptz")

  val_col = %w[val value reading amount data event_value].find { |c| cols.include?(c) } || 'val'

  {
    klass: klass,
    cols: {
      source_uuid: source_uuid_col,
      source_id:   source_id_col,
      meas_apcode: meas_apc_col,
      meas_id:     meas_id_col,
      site_id:     site_id_col,
      calc_period: cp_col,
      time:        time_col,
      value:       val_col
    },
    time_is_datetime: time_is_datetime
  }
end


# Build an ActiveRecord::Relation filter matching this measurement_source/measurement.
def build_event_scope(em, measurement_source:, measurement:)
  k   = em[:klass]
  c   = em[:cols]
  rel = k.all

  # Filter by measurement_source (prefer UUID)
  if c[:source_uuid] && measurement_source.respond_to?(:uuid)
    rel = rel.where(c[:source_uuid] => measurement_source.uuid)
  elsif c[:source_id] && measurement_source.respond_to?(:id)
    rel = rel.where(c[:source_id] => measurement_source.id)
  end

  # Filter by measurement (prefer apcode if present, else id)
  if c[:meas_apcode] && measurement.respond_to?(:apcode)
    rel = rel.where(c[:meas_apcode] => measurement.apcode)
  elsif c[:meas_id] && measurement.respond_to?(:id)
    rel = rel.where(c[:meas_id] => measurement.id)
  end

  # Filter by calc period if column exists (prevents mixing 1m/5m rows)
  if c[:calc_period] && measurement_source.respond_to?(:calc_period)
    rel = rel.where(c[:calc_period] => measurement_source.calc_period)
  end

  # Optional: site filter—only if your ScadaEvent has a site_id and you can supply it.
  # If you only have @site_uuid and ScadaEvent uses numeric site_id, skip this unless you can map UUID->id.
  # if c[:site_id] && respond_to?(:site_id_for_uuid)
  #   rel = rel.where(c[:site_id] => site_id_for_uuid(@site_uuid))
  # end

  rel
end


# Convert DB row to {"date","val"} with the API's shape.
def row_to_event_hash(row, time_col, val_col)
  t  = row.send(time_col)
  v  = row.send(val_col)
  { "date" => to_utc_compact(t), "val" => v }
end

# Does at least one event exist in the time window?
def first_event_in_db(em, measurement_source:, measurement:, start_z:, end_z:)
  rel = build_event_scope(em, measurement_source: measurement_source, measurement: measurement)
  time_col = em[:cols][:time]
  return nil unless rel.klass.column_names.include?(time_col)

  rel2 = apply_time_window(rel, em, start_z, end_z).limit(1)
  log "DB probe: model=#{em[:klass].name} time_col=#{time_col} type=#{em[:time_is_datetime] ? 'datetime' : 'string'}"
  rel2.first
rescue => e
  log "first_event_in_db error: #{e.class}: #{e.message}"
  nil
end

def load_events_from_db(em, measurement_source:, measurement:, start_z:, end_z:)
  rel  = build_event_scope(em, measurement_source: measurement_source, measurement: measurement)
  time = em[:cols][:time]
  val  = em[:cols][:value]
  return [] unless rel.klass.column_names.include?(time) && rel.klass.column_names.include?(val)

  rel2 = apply_time_window(rel, em, start_z, end_z)
  rows = rel2.reorder(time => :asc).to_a
  log "DB fetch: ScadaEvent rows=#{rows.size}"
  rows.first(3).each_with_index { |r, i| log "DB sample[#{i}]: #{time}=#{r.send(time).inspect} #{val}=#{r.send(val).inspect}" }
  rows.map { |r| { "date" => to_utc_compact(r.send(time)), "val" => r.send(val) } }
rescue => e
  log "load_events_from_db error: #{e.class}: #{e.message}"
  []
end

# -----------------------
# FieldAlias helper (unchanged from your flow)
# -----------------------
def create_field_alias(measurement, station_data, eng_unit)
  fa = FieldAlias.find_by_scada_measurement_id(measurement.id)
  return fa if fa
  FieldAlias.create(
    scada_measurement_id: measurement.id,
    measurement_type:     station_data[:station_element],
    engineering_unit:     eng_unit,
    station_type:         station_data[:station_type],
    station_id:           station_data[:station_id],
    relevance:            station_data[:relevance]
  )
end

# Build one item of data (header + events array), preferring DB if present
def build_item(segment, measurement, measurement_source, station_data)
  field_alias = create_field_alias(measurement, station_data, measurement_source.eng_unit)

  header = {
    segment_apcode:      segment.apcode,
    segment_name:        segment.name,
    measurement_apcode:  measurement.apcode,
    measurement_name:    measurement.name,
    eng_unit:            measurement_source.eng_unit,
    relevance:           field_alias.relevance,
    station_type:        field_alias.station_type,
    station_number:      field_alias.station_id,
    station_element:     field_alias.measurement_type
  }

  # Context for logs
  ctx = "[segment=#{segment.apcode}|mloc=#{measurement.apcode}|cp=#{measurement_source.calc_period}]"
  log "Preparing to fetch events #{ctx} window=#{@start_date}..#{@end_date}"

  # 1) Try DB first
  db_events = []
  # em = detect_events_model
  em = measurement_source.scada_events.any?
  if em
    # log "Checking DB for existing events #{ctx} model=#{em[:klass].name}"
    # any = first_event_in_db(em, measurement_source: measurement_source, measurement: measurement,
    #                         start_z: @start_date, end_z: @end_date)
    if em
      log "→ Getting event data from DB #{ctx}"
      # db_events = load_events_from_db(em, measurement_source: measurement_source, measurement: measurement,
      #                                 start_z: @start_date, end_z: @end_date)

      db_events = measurement_source.scada_events
                                    .between(@start_date, @end_date)
                                    .ordered
    else
      log "No rows in DB for window; will hit API #{ctx}"
    end
  else
    log "No events model detected; will hit API #{ctx}"
  end

  events =
    if db_events.any?
      db_events
    else
      log "→ About to hit API PF::EventDataService2.fetch_and_persist_events #{ctx}"
      service = Pf::EventDataService2.new(@api_key)
      service.fetch_and_persist_events(
        start_date:         @start_date,
        end_date:           @end_date,
        source_uuid:        measurement_source.uuid,
        measurement_apcode: measurement.apcode,
        site_id:            @site_uuid,
        cp_name:            measurement_source.calc_period
      )
    end

  {
    measurement: measurement.id,
    header: header,
    events: events
  }
end


def ev_date_compact_utc(ev)
  # Prefer method access (AR model), else fall back to hash keys
  if ev.respond_to?(:date)
    ev.date.utc.strftime("%Y%m%dT%H%M%SZ")
  else
    raw = ev["date"] || ev[:date]
    return nil if raw.nil?

    # If already in compact UTC form, pass through
    return raw if raw.is_a?(String) && raw.match?(/\A\d{8}T\d{6}Z\z/)

    # Otherwise parse and reformat
    t =
      if raw.is_a?(Time)
        raw
      else
        begin
          Time.iso8601(raw.to_s)
        rescue ArgumentError
          Time.parse(raw.to_s)
        end
      end
    t.utc.strftime("%Y%m%dT%H%M%SZ")
  end
end

def ev_val(ev)
  ev.respond_to?(:val) ? ev.val : ev["val"]
end



# def get_create_events_field_alias(datum, collector)
#   segment      = ScadaSegment.where(apcode: datum[:segment_apcode], name: datum[:segment_name]).first
#   mloc         = segment.scada_mlocs.where(apcode: datum[:mloc_apcode]).first
#   measurement  = mloc.scada_measurements.first
#   measurement_source       = measurement.scada_measurement_sources.where(calc_period: datum[:source_calc_period]).first
#   station_data = {
#     station_type:    datum[:station_type],
#     station_element: datum[:station_element],
#     station_id:      datum[:station_id],
#     relevance:       datum[:relevance]
#   }
#   collector << build_item(segment, measurement, measurement_source, station_data)
# end


def get_create_events_field_alias(datum, collector)
  segment = ScadaSegment.find_by(apcode: datum[:segment_apcode], name: datum[:segment_name])
  unless segment
    warn "[skip] segment not found for #{datum.slice(:segment_apcode, :segment_name)}"
    return
  end

  mloc_apcode = datum[:mloc_apcode] || datum[:measurement_apcode]
  unless mloc_apcode
    warn "[skip] no :mloc_apcode (or :measurement_apcode fallback) in datum: #{datum.inspect}"
    return
  end

  mloc = segment.scada_mlocs.find_by(apcode: mloc_apcode) || ScadaMloc.find_by(apcode: mloc_apcode)
  unless mloc
    warn "[skip] mloc not found for apcode=#{mloc_apcode} (segment=#{segment.apcode})"
    return
  end

  measurement =
    if (meas_apc = datum[:measurement_apcode])
      mloc.scada_measurements.find_by(apcode: meas_apc)
    else
      mloc.scada_measurements.first
    end
  unless measurement
    warn "[skip] measurement not found under mloc=#{mloc_apcode} (wanted apcode=#{datum[:measurement_apcode].inspect})"
    return
  end

  measurement_source =
    if datum[:source_calc_period]
      measurement.scada_measurement_sources.find_by(calc_period: datum[:source_calc_period])
    else
      measurement.scada_measurement_sources.first
    end
  unless measurement_source
    warn "[skip] measurement_source not found for measurement=#{measurement.apcode} cp=#{datum[:source_calc_period].inspect}"
    return
  end

  station_data = {
    station_type:    datum[:station_type],
    station_element: datum[:station_element],
    station_id:      datum[:station_id],
    relevance:       datum[:relevance]
  }

  collector << build_item(segment, measurement, measurement_source, station_data)
end



# -----------------------
# Ingest stations.json and fetch items
# -----------------------
raw      = File.read(INPUT, mode: "r:BOM|UTF-8")
stations = JSON.parse(raw, symbolize_names: true)

items = []  # [{ measurement:, header:, events: [...] }, ...]
stations.each do |station|
  station_number = station.first.to_s
  puts "Processing station #{station_number}..."
  (station.second || []).each_with_index do |datum, i|
    puts "  - spec ##{i}"
    get_create_events_field_alias(datum, items)
    #byebug
  end
end

abort "No items collected." if items.empty?

# -----------------------
# DB-only mode: exit before CSV reshape/write
# -----------------------
if ARGV.include?("--db-only")
  puts "DB-only mode enabled: events fetched/persisted as needed; skipping CSV generation."
  exit 0
end

# -----------------------
# Flatten to row-wise table (like events_merged.csv input)
# -----------------------
rows = []
items.each do |item|
  hdr = item[:header] || {}
  (item[:events] || []).each do |ev|
    compact = ev_date_compact_utc(ev)
    ts = fmt_ev_time(compact, tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
    # ts = fmt_ev_time(ev.date.utc.strftime("%Y%m%dT%H%M%SZ"),
    #              tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
    next if ts.nil?
    rows << {
      "measurement"         => item[:measurement].to_s,
      "segment_apcode"      => hdr[:segment_apcode].to_s,
      "segment_name"        => hdr[:segment_name].to_s,
      "measurement_apcode"  => hdr[:measurement_apcode].to_s,
      "measurement_name"    => hdr[:measurement_name].to_s,
      "eng_unit"            => hdr[:eng_unit].to_s,
      "relevance"           => hdr[:relevance].to_s,
      "station_type"        => hdr[:station_type].to_s,
      "station_number"      => hdr[:station_number].to_s,
      "station_element"     => hdr[:station_element].to_s,
      "event_date"          => ts,
      "event_value"         => ev_val(ev).to_s
      # "event_value"         => ev["val"].to_s
    }
  end
end

abort "No event rows found after fetching." if rows.empty?

# -----------------------
# Reshape logic (same as your reshape_events_split.rb)
# -----------------------
grouped = Hash.new { |h, k| h[k] = [] }
rows.each do |r|
  key = SeriesKey.new(r["measurement_apcode"], r["segment_name"])
  grouped[key] << r
end

series_meta   = {}
series_events = {}
series_period = {}
series_label  = {}

grouped.each do |key, arr|
  times = arr.map { |r| Time.parse(r["event_date"]) rescue nil }.compact.sort
  period =
    if (dom = dominant_delta_seconds(times))
      format_period_from_seconds(dom)
    else
      ""
    end

  label = "#{key.base_label}-#{period}"

  series_period[key] = period
  series_label[key]  = label

  r0 = arr.first
  series_meta[key] = {
    "segment_apcode"      => r0["segment_apcode"],
    "segment_name"        => r0["segment_name"],
    "mloc_apcode"         => r0["measurement_apcode"],
    "source_calc_period"  => period,
    "measurement_name"    => r0["measurement_name"],
    "eng_unit"            => r0["eng_unit"],
    "station_type"        => r0["station_type"],
    "station_element"     => r0["station_element"],
    "station_id"          => r0["station_number"],
    "relevance"           => r0["relevance"]
  }

  series_events[key] = {}
  arr.each do |r|
    ts = r["event_date"]
    series_events[key][ts] = r["event_value"]
  end
end

# Partition keys by period
keys_1m    = series_period.keys.select { |k| series_period[k].downcase == "1m" }
keys_5m    = series_period.keys.select { |k| series_period[k].downcase == "5m" }
keys_other = series_period.keys - keys_1m - keys_5m

# Write outputs
write_block(OUT_1M,   keys_1m,   series_label, series_meta, series_events)
write_block(OUT_5M,   keys_5m,   series_label, series_meta, series_events)
write_block(OTHERS_PATH, keys_other, series_label, series_meta, series_events) if OTHERS_PATH

puts "Wrote:"
puts "  #{OUT_1M} (#{keys_1m.size} series)"                   if keys_1m.any?
puts "  #{OUT_5M} (#{keys_5m.size} series)"                   if keys_5m.any?
puts "  #{OTHERS_PATH} (#{keys_other.size} series)"           if OTHERS_PATH && keys_other.any?

