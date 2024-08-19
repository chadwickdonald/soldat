require 'json'

# Your JSON data
mloc_file = 'mlocs2.json'
data = JSON.parse(File.read(mloc_file))


# File to save results
output_file = 'curl_results2.txt'

# Parse the JSON
# data = JSON.parse(json_data)

# Open file for writing results
File.open(output_file, 'w') do |file|
  # Iterate over each object and make a curl request
  data.each do |item|
    id = item['id']
    uri = item['uri']

    # Formulate the curl command
    curl_command = "curl --location 'https://portal.solarpark-online.com/ifms/mlocs/#{id}' \
    --header 'API-Key: 4babde93-07c2-428c-9bd4-6f04b038afe1.01'"

    # Execute the curl command and write results to file
    file.puts "=== #{uri}/#{id} ==="
    file.puts `#{curl_command}`
    file.puts "\n"
  end
end



