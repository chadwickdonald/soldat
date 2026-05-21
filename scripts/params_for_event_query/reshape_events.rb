# reshape_events_split.rb
# Usage:
#   ruby reshape_events_split.rb events_merged.csv out_1m.csv out_5m.csv
# Optional: also dump any *other* periods (not 1m/5m):
#   ruby reshape_events_split.rb events_merged.csv out_1m.csv out_5m.csv --others other_periods.csv

require "csv"
require "time"

INPUT   = ARGV[0] || "events_merged.csv"
OUT_1M  = ARGV[1] || "output/events_reshaped_1m.csv"
OUT_5M  = ARGV[2] || "output/events_reshaped_5m.csv"

OTHERS_PATH = begin
  if ARGV.include?("--others")
    i = ARGV.index("--others")
    ARGV[i + 1]
  end
end

rows = CSV.read(INPUT, headers: true)
abort "No data in #{INPUT}" if rows.empty?

# Column names from your sample
COL = {
  measurement:         "measurement",
  segment_apcode:      "segment_apcode",
  segment_name:        "segment_name",
  measurement_apcode:  "measurement_apcode",
  measurement_name:    "measurement_name",
  eng_unit:            "eng_unit",
  relevance:           "relevance",
  station_type:        "station_type",
  station_id:          "station_number",
  station_element:     "station_element",
  event_time:          "event_date",
  event_value:         "event_value"
}

SeriesKey = Struct.new(:mloc_apcode, :segment_name) do
  def base_label
    "#{mloc_apcode}-#{segment_name}"
  end
end

# Group rows by series
grouped = Hash.new { |h, k| h[k] = [] }
rows.each do |r|
  key = SeriesKey.new(r[COL[:measurement_apcode]].to_s, r[COL[:segment_name]].to_s)
  grouped[key] << r
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

# Build per-series metadata/events and derive period
series_meta   = {}
series_events = {}
series_period = {}
series_label  = {}

grouped.each do |key, arr|
  times = arr.map { |r| Time.parse(r[COL[:event_time]].to_s) rescue nil }.compact.sort
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
    "segment_apcode"      => r0[COL[:segment_apcode]].to_s,
    "segment_name"        => r0[COL[:segment_name]].to_s,
    "mloc_apcode"         => r0[COL[:measurement_apcode]].to_s,
    "source_calc_period"  => period,
    "measurement_name"    => r0[COL[:measurement_name]].to_s,
    "eng_unit"            => r0[COL[:eng_unit]].to_s,
    "station_type"        => r0[COL[:station_type]].to_s,
    "station_element"     => r0[COL[:station_element]].to_s,
    "station_id"          => r0[COL[:station_id]].to_s,
    "relevance"           => r0[COL[:relevance]].to_s
  }

  series_events[key] = {}
  arr.each do |r|
    ts = r[COL[:event_time]].to_s
    series_events[key][ts] = r[COL[:event_value]].to_s
  end
end

# Partition by period
keys_1m    = series_period.keys.select { |k| series_period[k].downcase == "1m" }
keys_5m    = series_period.keys.select { |k| series_period[k].downcase == "5m" }
keys_other = series_period.keys - keys_1m - keys_5m

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

write_block(OUT_1M, keys_1m, series_label, series_meta, series_events)
write_block(OUT_5M, keys_5m, series_label, series_meta, series_events)
write_block(OTHERS_PATH, keys_other, series_label, series_meta, series_events) if OTHERS_PATH

puts "Wrote:"
puts "  #{OUT_1M} (#{keys_1m.size} series)"   if keys_1m.any?
puts "  #{OUT_5M} (#{keys_5m.size} series)"   if keys_5m.any?
puts "  #{OTHERS_PATH} (#{keys_other.size} series)" if OTHERS_PATH && keys_other.any?
