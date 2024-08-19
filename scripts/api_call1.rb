require 'net/http'
require 'uri'

def get_api_response(source_id)
  # Define the API endpoint URL with the provided source ID
  api_url = URI("https://portal.solarpark-online.com/ifms/sources/#{source_id}/events")

  # Add your API key to the headers
  api_key = '4babde93-07c2-428c-9bd4-6f04b038afe1.01'
  headers = { 'API-Key' => api_key }

  # Make a GET request to the API endpoint
  response = Net::HTTP.start(api_url.hostname, api_url.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(api_url, headers)
    http.request(request)
  end

  # Check if the response was successful (status code 200)
  if response.code == '200'
    return response.body
  else
    puts "Failed to retrieve API data. Status code: #{response.code}"
    return nil
  end
end

def save_response_to_file(response, file_name)
  if response.nil?
    puts "No response to save."
    return
  end

  # Save the response to a file
  File.open(file_name, 'w') do |file|
    file.write(response)
  end
  puts "API response saved to #{file_name}"
end

# Check if the source ID is provided as a command-line argument
if ARGV.empty?
  puts "Please provide the source ID as an argument."
  exit(1)
end

source_id = ARGV[0]
response = get_api_response(source_id)
save_response_to_file(response, "api_response_#{source_id}.json")