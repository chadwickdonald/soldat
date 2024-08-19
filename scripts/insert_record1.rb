# script.rb

require 'json'
require 'active_record'
require_relative 'app/models/event_data'


# Connect to the database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'development.sqlite3' # Update with your database configuration
)

# Read data from the file argument and create records
file_path = ARGV[0]
File.open(file_path, 'r') do |file|
  file.each_line do |line|
    begin
      line.gsub!(/"null"/, 'null')
      data_array = JSON.parse(line)
      data_array.each do |data|
        puts "data: #{data}"
        EventData.create!(
          date: DateTime.parse(data["date"]),
          uri: data['uri'],
          val: data['val'].to_f,
          quality: data['quality'].to_f,
          multiValues: data['multiValues'],
          reception: DateTime.parse(data['reception'])
        )
        puts "Record created successfully!"
      end
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e.message}"
    rescue StandardError => e
      puts "Error creating record: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

[{"date":"20240108T120000Z","uri":"http://portal.solarpark-online.com/ifms/sources/b68c9654-8854-11ee-a4ff-42010afa015a/events/20240108T120000Z","val":"0.0","quality":"100.0","multiValues":nil,"reception":"20240108T115527Z"},{"date":"20240108T120100Z","uri":"http://portal.solarpark-online.com/ifms/sources/b68c9654-8854-11ee-a4ff-42010afa015a/events/20240108T120100Z","val":"0.0","quality":"100.0","multiValues":nil,"reception":"20240108T115617Z"}]