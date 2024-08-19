require 'json'
require 'active_record'
# require_relative 'config/environment'
require_relative 'app/models/scada_event'

# # Define the ActiveRecord model for the scada_data table
# class ScadaEvent < ActiveRecord::Base
# end

apcodes = [
  "AmbientAirTemperatureTr2", # 5759
  "ArrayOutputPowerTr2", # has multiple types? lots of records, 151185
  "PPCActivePowerTr2", # 1440
  "PPCTotalPowerFactorTr2", # 1440
  "ModuleTemperature1Tr2", # 2879
  "ModuleTemperature2Tr2", # 4319
  "ModuleTemperature3Tr2", # 4319
  "SecInclIrradianceTr2", # multiple?, 5759
  "InclIrradianceTr2" # 5759
]


# Establish database connection
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/soldat_development.sqlite3' # Update this with your database configuration
)

# Load JSON file from argument
# json_file_path = ARGV[0]
json_file_path = 'response23.json'
unless json_file_path
  puts "Usage: ruby script.rb <path_to_json_file>"
  exit
end

# Read JSON file
begin
  json_data = File.read(json_file_path)
rescue StandardError => e
  puts "Error reading JSON file: #{e.message}"
  exit
end

# Parse JSON data
begin
  scada_events = JSON.parse(json_data)
rescue JSON::ParserError => e
  puts "Error parsing JSON: #{e.message}"
  exit
end

# Iterate over each object in the JSON array and create corresponding records in the database
scada_events.each do |event|
  ScadaEvent.create!(
    site_id: event['siteId'],
    date: DateTime.strptime(event['date'], '%Y%m%dT%H%M%SZ'),
    measurement_source_id: event['measurementSourceId'],
    val: event['val'].to_f,
    cp_name: event['cpName'],
    measurement_apcode: event['measurementApcode']
  )
end

puts "Data successfully imported."