#!/usr/bin/env ruby
require 'active_record'
require 'csv'
require_relative '../config/environment'

result = ScadaMloc
  .joins(:scada_segment)
  .select('DISTINCT scada_segments.apcode AS segment_apcode, scada_segments.name AS segment_name, scada_mlocs.apcode AS mloc_apcode')
  .reorder(nil)

CSV.open("segment_mlocs.csv", "w") do |csv|
  csv << ["Segment APCODE", "Segment Name", "MLOC APCODE"]  # header
  result.each do |r|
    csv << [r.segment_apcode, r.segment_name, r.mloc_apcode]
  end
end