#!/usr/bin/env ruby
require 'active_record'
require 'csv'
require_relative 'app/models/scada_event'

# Define the ActiveRecord model for your table
class YourModel < ActiveRecord::Base
  self.table_name = 'your_table_name'
end

# Establish connection to the database
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'soldat_development'
  # username: 'your_username',
  # password: 'your_password'
)

# Check if correct number of command-line arguments is provided
if ARGV.length != 1
  puts "Usage: ruby export_to_csv.rb table_name csv_name"
  exit(1)
end

# Extract command-line arguments
csv_name = ARGV[0]

# Fetch data from the specified table
# data = ScadaEvent.all
# data = ScadaEvent.first(5)
# data = ScadaEvent.select(YourModel.attribute_names - ['created_at', 'updated_at']).limit(5)
data = ScadaEvent.select(YourModel.attribute_names)

# Define the path for the CSV file
csv_file_path = "#{csv_name}.csv"

# Open a CSV file in write mode
CSV.open(csv_file_path, 'w') do |csv|
  # Write the column headers to the CSV file
  # csv << ScadaEvent.attribute_names - ['created_at', 'updated_at']
  csv << ScadaEvent.attribute_names

  # Iterate over the data and write each row to the CSV file
  data.each do |row|
    csv << row.attributes.values
    # csv << row.attributes.values_at(*data.column_names)
  end
end

puts "Data exported to #{csv_file_path}"
