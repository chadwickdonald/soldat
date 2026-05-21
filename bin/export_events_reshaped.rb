#!/usr/bin/env ruby
# bin/export_events_reshaped.rb
#
# Fetches events for each station entry in a JSON config, then writes
# reshaped CSVs split by calc period (1m, 5m, others).
#
# Usage:
#   ruby bin/export_events_reshaped.rb stations.json out_1m.csv out_5m.csv [--others other.csv]

require_relative '../config/environment'
require 'csv'
require 'json'
require 'time'

INPUT  = ARGV[0] or abort("Usage: #{File.basename($0)} stations.json out_1m.csv out_5m.csv [--others other.csv]")
OUT_1M = ARGV[1] or abort("Please provide out_1m.csv path")
OUT_5M = ARGV[2] or abort("Please provide out_5m.csv path")

OTHERS_PATH =
  if ARGV.include?("--others")
    ARGV[ARGV.index("--others") + 1]
  end

@api_key    = ENV['SCADA_API_KEY']
@start_date = '20250901T000000Z'
@end_date   = '20250908T000000Z'
@site_uuid  = ScadaSite.find_by_name("Danish Fields - T3")&.uuid

SeriesKey = Struct.new(:mloc_apcode, :segment_name) do
  def base_label = "#{mloc_apcode}-#{segment_name}"
end

def fmt_ev_time(s)
  return nil if s.nil? || s.to_s.empty?
  t = Time.strptime(s.to_s, "%Y%m%dT%H%M%SZ")
  t.getlocal.strftime("%Y-%m-%d %H:%M:%S")
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
      return "#{hours / 24}d" if (hours % 24).zero?
    end
  end
  "#{sec}s"
end

def dominant_delta_seconds(times)
  return nil if times.length < 2
  deltas = (1...times.length).map { |i| (times[i] - times[i - 1]).to_i.abs }
  deltas.tally.max_by { |_, c| c }[0]
end

def write_block(path, keys, series_label, series_meta, series_events)
  return if path.nil? || path.empty? || keys.nil? || keys.empty?

  keys = keys.sort_by do |k|
    sid = series_meta.dig(k, "station_id").to_s
    sid_num = Integer(sid, 10) rescue nil
    [sid_num.nil? ? 1 : 0, sid_num || sid, series_label[k].to_s]
  end

  all_times = series_events.values_at(*keys).compact.flat_map(&:keys).uniq
  all_times.sort_by! { |s| Time.parse(s) rescue s }

  meta_vars = %w[
    segment_apcode segment_name mloc_apcode source_calc_period
    measurement_name eng_unit station_type station_element station_id relevance
  ]

  CSV.open(path, "w") do |csv|
    csv << ["variable"] + keys.map { |k| series_label[k] }
    meta_vars.each { |v| csv << [v] + keys.map { |k| series_meta[k][v] } }
    csv << []
    csv << ["time"] + keys.map { |k| series_label[k] }
    all_times.each { |ts| csv << [ts] + keys.map { |k| series_events[k][ts] } }
  end
end

stations = JSON.parse(File.read(INPUT, mode: "r:BOM|UTF-8"), symbolize_names: true)

rows = []
stations.each do |_site_key, entries|
  Array(entries).each do |datum|
    segment = ScadaSegment.where(apcode: datum[:segment_apcode], name: datum[:segment_name]).first
    unless segment
      warn "[skip] segment not found: apcode=#{datum[:segment_apcode]} name=#{datum[:segment_name]}"
      next
    end

    mloc = segment.scada_mlocs.where(apcode: datum[:mloc_apcode]).first
    unless mloc
      warn "[skip] mloc not found: apcode=#{datum[:mloc_apcode]}"
      next
    end

    measurement = mloc.scada_measurements.first
    unless measurement
      warn "[skip] no measurement under mloc=#{datum[:mloc_apcode]}"
      next
    end

    source = measurement.scada_measurement_sources.where(calc_period: datum[:source_calc_period]).first
    unless source
      warn "[skip] no source with calc_period=#{datum[:source_calc_period]}"
      next
    end

    field_alias = FieldAlias.find_by_scada_measurement_id(measurement.id)
    field_alias ||= FieldAlias.create(
      scada_measurement_id: measurement.id,
      measurement_type:     datum[:station_element],
      station_type:         datum[:station_type],
      station_id:           datum[:station_id],
      relevance:            datum[:relevance]
    )

    events = Pf::EventDataService2.new(@api_key).fetch_and_persist_events(
      start_date:         @start_date,
      end_date:           @end_date,
      source_uuid:        source.uuid,
      measurement_apcode: measurement.apcode,
      site_id:            @site_uuid,
      cp_name:            source.calc_period
    )

    events.each do |ev|
      raw_date = ev.respond_to?(:date) ? ev.date.utc.strftime("%Y%m%dT%H%M%SZ") : ev["date"]
      ts = fmt_ev_time(raw_date)
      next if ts.nil?
      rows << {
        "segment_apcode"     => segment.apcode.to_s,
        "segment_name"       => segment.name.to_s,
        "measurement_apcode" => measurement.apcode.to_s,
        "measurement_name"   => measurement.name.to_s,
        "eng_unit"           => source.eng_unit.to_s,
        "relevance"          => field_alias.relevance.to_s,
        "station_type"       => field_alias.station_type.to_s,
        "station_number"     => field_alias.station_id.to_s,
        "station_element"    => field_alias.measurement_type.to_s,
        "event_date"         => ts,
        "event_value"        => (ev.respond_to?(:val) ? ev.val : ev["val"]).to_s
      }
    end
  end
end

abort "No event rows found." if rows.empty?

grouped = Hash.new { |h, k| h[k] = [] }
rows.each { |r| grouped[SeriesKey.new(r["measurement_apcode"], r["segment_name"])] << r }

series_meta   = {}
series_events = {}
series_period = {}
series_label  = {}

grouped.each do |key, arr|
  times  = arr.map { |r| Time.parse(r["event_date"]) rescue nil }.compact.sort
  period = (dom = dominant_delta_seconds(times)) ? format_period_from_seconds(dom) : ""
  label  = "#{key.base_label}-#{period}"

  series_period[key] = period
  series_label[key]  = label

  r0 = arr.first
  series_meta[key] = {
    "segment_apcode"     => r0["segment_apcode"],
    "segment_name"       => r0["segment_name"],
    "mloc_apcode"        => r0["measurement_apcode"],
    "source_calc_period" => period,
    "measurement_name"   => r0["measurement_name"],
    "eng_unit"           => r0["eng_unit"],
    "station_type"       => r0["station_type"],
    "station_element"    => r0["station_element"],
    "station_id"         => r0["station_number"],
    "relevance"          => r0["relevance"]
  }

  series_events[key] = arr.each_with_object({}) { |r, h| h[r["event_date"]] = r["event_value"] }
end

keys_1m    = series_period.keys.select { |k| series_period[k].downcase == "1m" }
keys_5m    = series_period.keys.select { |k| series_period[k].downcase == "5m" }
keys_other = series_period.keys - keys_1m - keys_5m

write_block(OUT_1M,      keys_1m,    series_label, series_meta, series_events)
write_block(OUT_5M,      keys_5m,    series_label, series_meta, series_events)
write_block(OTHERS_PATH, keys_other, series_label, series_meta, series_events) if OTHERS_PATH

puts "Wrote:"
puts "  #{OUT_1M} (#{keys_1m.size} series)"         if keys_1m.any?
puts "  #{OUT_5M} (#{keys_5m.size} series)"         if keys_5m.any?
puts "  #{OTHERS_PATH} (#{keys_other.size} series)" if OTHERS_PATH && keys_other.any?
