#!/usr/bin/env ruby
# One-time script to correct FieldAlias.station_id values by extracting the
# station identifier from the associated ScadaMeasurement.segment_name rather
# than the field name string that was previously used.
#
# Usage:
#   rails runner scripts/fix_station_ids.rb
#   rails runner scripts/fix_station_ids.rb -- --dry-run

require_relative '../config/environment'

dry_run  = ARGV.include?("--dry-run")
updated  = 0
skipped  = 0
errored  = 0

puts dry_run ? "DRY RUN — no changes will be saved.\n\n" : "Running fix...\n\n"

FieldAlias.includes(:scada_measurement).find_each do |fa|
  segment_name = fa.scada_measurement&.segment_name
  correct_id   = StationIdExtractor.call(segment_name)

  if fa.station_id == correct_id
    skipped += 1
    next
  end

  puts "  [#{fa.id}] #{segment_name.inspect}: #{fa.station_id.inspect} => #{correct_id.inspect}"

  unless dry_run
    if fa.update_column(:station_id, correct_id)
      updated += 1
    else
      errored += 1
      puts "    ERROR: could not update FieldAlias #{fa.id}"
    end
  else
    updated += 1
  end
end

puts "\nDone. Updated: #{updated}, Skipped: #{skipped}, Errored: #{errored}"
