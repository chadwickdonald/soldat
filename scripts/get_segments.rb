require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

site_id = '25658d43-0ffd-42b4-a4e4-d3b808e85087' # site 3
puts(site_id)

uri = URI("https://portal.solarpark-online.com/ifms/sites/#{site_id}/segments?recursive=true")
request = Net::HTTP::Get.new(uri)
request['API-Key'] = '4babde93-07c2-428c-9bd4-6f04b038afe1.01'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

if response.is_a?(Net::HTTPSuccess)
  segments = JSON.parse(response.body)
  segments.each do |segment|
    ScadaSegment.create!(
      site_id: site_id,
      uuid: segment['id'],
      apcode: segment['apcode'],
      uri: segment['uri'],
      name: segment['name'],
      apcode_idx: segment['apcode_idx']
    )
  end
else
  puts "Error: #{response.message}"
end

puts "Segments persisted successfully."
