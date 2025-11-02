#!/usr/bin/env ruby
# export_events_reshaped.rb
#
# Does what your original exporter did (fetch events from PF::EventDataService2),
# but directly writes the *reshaped* CSVs in the same layout your
# reshape_events_split.rb produces:
#   - First section: metadata rows (variable + columns per series)
#   - Blank line
#   - Time grid with aligned values
#
# Usage:
#   ruby export_events_reshaped.rb stations.json out_1m.csv out_5m.csv [--others other_periods.csv]

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
@start_date = '20250901T010000Z'
@end_date   = '20250907T010000Z'
@site_uuid  = ScadaSite.find_by_name("Danish Fields - T3").uuid

# -----------------------
# Helpers
# -----------------------
def fmt_ev_time(s, tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
  return nil if s.nil? || s.empty?
  t = Time.strptime(s, "%Y%m%dT%H%M%SZ")   # parse "20250901T010000Z"
  t = (tz == :local) ? t.getlocal : t.utc  # choose local time or keep UTC
  t.strftime(fmt)                          # "2025-09-01 06:00:00" (PT)
rescue
  nil
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

  # Stable column order
  keys = keys.sort_by { |k| series_label[k] }

  # Union of timestamps (sorted)
  all_times = series_events.values_at(*keys).compact.flat_map(&:keys).uniq
  all_times.sort_by! { |s| Time.parse(s) rescue s }

  meta_vars = [
    "segment_apcode",
    "segment_name",
    "mloc_apcode",
    "source_calc_period",
    "measurement_name",
    "eng_unit",
    "station_type",
    "station_element",
    "station_id",
    "relevance"
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
# FieldAlias helper (unchanged from your flow)
# -----------------------
def create_field_alias(measurement, station_data, eng_unit)
  fa = FieldAlias.find_by_scada_measurement_id(measurement.id)
  return fa if fa
  FieldAlias.create(
    scada_measurement_id: measurement.id,
    measurement_type: station_data[:station_element],
    engineering_unit: eng_unit,
    station_type: station_data[:station_type],
    station_id: station_data[:station_id],
    relevance: station_data[:relevance]
  )
end

# Build one item of data (header + events array)
def build_item(segment, measurement, source, station_data)
  field_alias = create_field_alias(measurement, station_data, source.eng_unit)

  header = {
    segment_apcode:      segment.apcode,
    segment_name:        segment.name,
    measurement_apcode:  measurement.apcode,
    measurement_name:    measurement.name,
    eng_unit:            source.eng_unit,
    relevance:           field_alias.relevance,
    station_type:        field_alias.station_type,
    station_number:      field_alias.station_id,
    station_element:     field_alias.measurement_type
  }

  service = Pf::EventDataService2.new(@api_key)
  events = service.fetch_and_persist_events(
    start_date:        @start_date,
    end_date:          @end_date,
    source_uuid:       source.uuid,
    measurement_apcode: measurement.apcode,
    site_id:           @site_uuid,
    cp_name:           source.calc_period
  )

  {
    measurement: measurement.id,
    header: header,
    events: events
  }
end

def get_create_events_field_alias(datum, collector)
  segment     = ScadaSegment.where(apcode: datum[:segment_apcode], name: datum[:segment_name]).first
  mloc        = segment.scada_mlocs.where(apcode: datum[:mloc_apcode]).first
  measurement = mloc.scada_measurements.first
  source      = measurement.scada_measurement_sources.where(calc_period: datum[:source_calc_period]).first
  station_data = {
    station_type:   datum[:station_type],
    station_element: datum[:station_element],
    station_id:     datum[:station_id],
    relevance:      datum[:relevance]
  }
  collector << build_item(segment, measurement, source, station_data)
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
  end
end

abort "No items collected." if items.empty?

# -----------------------
# Flatten to row-wise table (like events_merged.csv input)
# -----------------------
rows = []  # array of hashes with the column names used by reshape script
items.each do |item|
  hdr = item[:header] || {}
  (item[:events] || []).each do |ev|
    ts = fmt_ev_time(ev["date"], tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
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
      "event_value"         => ev["val"].to_s
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
      "" # unknown
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
write_block(OUT_1M, keys_1m, series_label, series_meta, series_events)
write_block(OUT_5M, keys_5m, series_label, series_meta, series_events)
write_block(OTHERS_PATH, keys_other, series_label, series_meta, series_events) if OTHERS_PATH

puts "Wrote:"
puts "  #{OUT_1M} (#{keys_1m.size} series)"   if keys_1m.any?
puts "  #{OUT_5M} (#{keys_5m.size} series)"   if keys_5m.any?
puts "  #{OTHERS_PATH} (#{keys_other.size} series)" if OTHERS_PATH && keys_other.any?
