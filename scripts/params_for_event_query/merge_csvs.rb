# merge_csvs.rb
require "csv"

inputs  = ["events1.csv", "events.csv"]
output  = "events_20_28.csv"

CSV.open(output, "w") do |out|
  headers_written = false

  inputs.each do |path|
    CSV.foreach(path, headers: true) do |row|
      unless headers_written
        out << row.headers
        headers_written = true
      end
      out << row
    end
  end
end