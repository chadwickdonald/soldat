require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

segment_ids = ScadaSegment.pluck(:uuid)

segment_ids.each do |segment_id|
	uri = URI("https://portal.solarpark-online.com/ifms/segments/#{segment_id}/svars")
	request = Net::HTTP::Get.new(uri)
	request['API-Key'] = SCADA_API_KEY

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    svars = JSON.parse(response.body)
    svars.each do |svar|
      unless ScadaStateVariable.exists?(uuid: svar['id'])
        ScadaStateVariable.create!(
        	uuid: svar['id'],
          segment_id: segment_id,
          apcode: svar['apcode'],
          uri: svar['uri'],
          name: svar['name']
        )
      else
        puts "StateVariable with UUID #{svar['id']} already exists. Skipping..."
      end
    end
  else
    puts "Error for segment_id #{segment_id}: #{response.message}"
  end
end

puts "StateVariables persisted successfully."

