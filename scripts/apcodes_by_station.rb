#!/usr/bin/env ruby
# apcodes_by_station.rb
#
# Usage:
#   ruby apcodes_by_station.rb "/path/to/Unique mloc appcodes list Aug 7 2025.xlsx" [output_dir]
#
# Requires gems: roo
#   gem install roo
#
# Run from your Rails app root so we can load config/environment for DB access.

require "csv"
require "fileutils"
require "roo"

# --- CLI ---
INPUT_PATH = 'mloc_apcodes-8-7-25.xlsx'
OUTPUT_DIR = ARGV[1] || "station_csvs"

# --- Optional Rails/DB load (for ScadaSegment/ScadaMloc lookup) ---
rails_loaded = false
begin
  require_relative "./config/environment"
  rails_loaded = true
rescue LoadError
  begin
    require_relative "../config/environment"
    rails_loaded = true
  rescue LoadError
    warn "WARN: Could not load Rails environment. Will skip DB lookups and only output Excel appcodes."
  end
end

# --- Helpers ---
def safe_filename(str)
  str.to_s.strip
     .gsub(/[\/\\:*?"<>|]/, "-")
     .gsub(/\s+/, "_")
end

def norm(s)
  s.to_s.strip
      .gsub(/[“”"]/, "") # strip fancy/straight quotes
      .gsub(",", "")     # strip stray commas like in the sample sheet
end

# --- Parse Excel ---
xlsx  = Roo::Excelx.new(INPUT_PATH)
sheet = xlsx.sheet(0)

# Find the header row that contains "AppCode Names" and "Station Type".
header_row_idx = nil
(1..[sheet.last_row, 30].min).each do |r|
  row = sheet.row(r).map { |v| v.to_s.strip }
  if row.any? { |c| c =~ /AppCode\s*Names/i } && row.any? { |c| c =~ /Station\s*Type/i }
    header_row_idx = r
    break
  end
end
abort "ERROR: Could not find header row with 'AppCode Names' and 'Station Type'." unless header_row_idx

headers      = sheet.row(header_row_idx).map { |h| h.to_s.strip }
appcode_col  = headers.index { |h| h =~ /\AAppCode\s*Names\z/i }
station_col  = headers.index { |h| h =~ /\AStation\s*Type\z/i }
abort "ERROR: Columns not found." unless appcode_col && station_col

# Collect Excel appcodes by normalized station
excel_groups = Hash.new { |h, k| h[k] = [] }
((header_row_idx + 1)..sheet.last_row).each do |r|
  row     = sheet.row(r)
  appcode = row[appcode_col]
  station = row[station_col]
  next if appcode.nil? || station.nil? || appcode.to_s.strip.empty? || station.to_s.strip.empty?

  appcode_norm = norm(appcode)
  station_norm = norm(station)
  next if appcode_norm.empty? || station_norm.empty?

  excel_groups[station_norm] << appcode_norm
end

# --- Build DB-derived mloc appcodes by normalized station name (if Rails loaded) ---
segment_mloc_groups = Hash.new { |h, k| h[k] = [] }

if rails_loaded
  # Map normalized ScadaSegment.name -> [uuid,...]
  seg_name_uuid = {}

  # Option A: include PK implicitly by not using a custom select
  ScadaSegment.find_each do |seg|
    next if seg.name.nil?
    seg_name_uuid[norm(seg.name)] ||= []
    seg_name_uuid[norm(seg.name)] << seg.uuid
  end

  # For every station seen in Excel, pull ScadaMloc.apcode via segment uuid(s)
  excel_groups.keys.each do |station_norm|
    uuids = seg_name_uuid[station_norm]
    next if uuids.nil? || uuids.empty?

    # Adjust :segment_id if your FK column is different
    ScadaMloc.where(segment_id: uuids)
             .where.not(apcode: [nil, ""])
             .pluck(:apcode)
             .each do |ap|
      apn = norm(ap)
      next if apn.empty?
      segment_mloc_groups[station_norm] << apn
    end
  end
end

# --- Write CSVs ---
FileUtils.mkdir_p(OUTPUT_DIR)

stations = (excel_groups.keys | segment_mloc_groups.keys)
stations.each do |station_norm|
  path = File.join(OUTPUT_DIR, "#{safe_filename(station_norm)}.csv")

  # Deduplicate while preserving order, but keep the source label
  seen = {}
  rows = []

  (excel_groups[station_norm] || []).each do |ap|
    next if seen[ap]
    rows << ["excel", ap]
    seen[ap] = true
  end

  (segment_mloc_groups[station_norm] || []).each do |ap|
    next if seen[ap]
    rows << ["segment_mloc", ap]
    seen[ap] = true
  end

  CSV.open(path, "w") do |csv|
    csv << ["Source", "AppCode"]
    rows.each { |row| csv << row }
  end

  puts "Wrote #{rows.size} unique appcodes → #{path}"
end

puts "\nDone. Generated #{stations.size} CSV files in #{OUTPUT_DIR}/"
