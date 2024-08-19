# import_curl_data.rb

require 'json'
# require 'active_record'
# require 'sqlite3'
# require_relative 'app/models/scada_def'

require_relative '../config/environment'


# Assuming this is the ActiveRecord model for scada_metas
class ScadaDef < ActiveRecord::Base
end

def create_scada_defs()
  # Connect to the database
  # ActiveRecord::Base.establish_connection(
  #   adapter: 'sqlite3',
  #   database: 'db/development.sqlite3' # Adjust this based on your database configuration
  # )

  # Read and parse the JSON file
  file_path = '../curl_results.txt'
  file_content = File.read(file_path)

  # Process each JSON object and create records
  file_content.each_line do |line|
    next unless line.strip.start_with?('{') # Skip lines that do not start with a JSON object

    begin
      json_data = JSON.parse(line)
    rescue JSON::ParserError => e
      puts "Skipping line due to JSON parsing error: #{e.message}"
      next
    end

    meta = json_data

    # Extract relevant fields from JSON
    uuid = meta['id']
    source_id = meta['sources'][0]['id']
    apcode = meta['apcode']
    data_type = meta['measureType']['dataType']
    name1 = meta['name']
    eng_unit = meta['sources'][0]['engUnit']
    calc_period = meta['sources'][0]['calcPeriod']

    # Create a new ScadaMeta record
    scada_def = ScadaDef.new(
      uuid: uuid,
      source_id: source_id,
      apcode: apcode,
      data_type: data_type,
      name: name1,
      eng_unit: eng_unit,
      calc_period: calc_period
    )

    # Save the record
    if scada_def.save
      puts "---Saved ScadaDef record with UUID #{uuid}"
    else
      puts "---Failed to save ScadaDef record with UUID #{uuid}: #{scada_def.errors.full_messages.join(', ')}"
    end
  end
end

create_scada_defs







# result = ScadaEvent.joins("OUTER JOIN scada_defs ON scada_events.measurement_apcode = scada_defs.apcode")
#                    .select("scada_events.*, scada_defs.*")
#                    .limit(100)

# result = ScadaEvent.joins("INNER JOIN scada_defs ON scada_events.measurement_apcode = scada_defs.apcode")
#                    .limit(10)
