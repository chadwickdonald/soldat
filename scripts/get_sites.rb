require 'net/http'
require 'uri'
require 'json'
require 'csv'

# Define the URL and API key
url = 'https://portal.solarpark-online.com/ifms/agents/4b5dc3b7-4ea5-4ed4-a32b-a78645085104/sites'
api_key = SCADA_API_KEY

# Set up the URI and HTTP request
uri = URI(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Get.new(uri)
request['API-Key'] = api_key

# Send the request and parse the response
response = http.request(request)
data = JSON.parse(response.body)

# Open or create the CSV file
CSV.open("sites.csv", "w") do |csv|
  # Write the headers
  csv << data.first.keys
  
  # Write each row of data
  data.each do |row|
    csv << row.values
  end
end

puts "Data has been saved to sites.csv"
