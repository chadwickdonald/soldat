require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

segment_uuids = ScadaSegment.pluck(:uuid)
api_key = SCADA_API_KEY

segment_uuids.each do |segment_id|
  uri = URI("https://portal.solarpark-online.com/ifms/segments/#{segment_id}/mlocs")
  request = Net::HTTP::Get.new(uri)
  request['API-Key'] = api_key

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    mlocs = JSON.parse(response.body)
    mlocs.each do |mloc|
      unless ScadaMloc.exists?(uuid: mloc['id'])
        ScadaMloc.create!(
          segment_id: segment_id,
          apcode: mloc['apcode'],
          uuid: mloc['id'],
          name: mloc['name'],
          sscode: mloc['sscode'],
          uri: mloc['uri'],
          measurementTypeId: mloc['measurementTypeId']
        )
      else
        puts "Mloc with UUID #{mloc['id']} already exists. Skipping..."
      end
    end
  else
    puts "Error: #{response.message} for segment_id: #{segment_id}"
  end
end

puts "Mlocs persisted successfully."
