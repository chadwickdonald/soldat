# script/export_scada_measurements.rb
require 'csv'
require 'set'

file_path = Rails.root.join('tmp', 'unique_scada_measurements.csv')

# Grab distinct combinations of the three fields
unique_rows = ScadaMeasurement
  .select(:apcode, :segment_name, :monitor_eng_unit)
  .distinct
  .unscope(:order)

# Build a set of unique concatenated keys
unique_keys = Set.new

unique_rows.each do |record|
  key = "#{record.apcode}_#{record.segment_name}_#{record.monitor_eng_unit}"
  unique_keys << key
end

# Write to CSV
CSV.open(file_path, 'w') do |csv|
  csv << ['unique_key']
  unique_keys.each do |key|
    csv << [key]
  end
end

puts "✅ Export complete. File saved to #{file_path}"