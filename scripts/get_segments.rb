require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

site_ids = ScadaSite.pluck(:uuid)

site_ids.each do |site_id|
  uri = URI("https://portal.solarpark-online.com/ifms/sites/#{site_id}/segments?recursive=true")
  request = Net::HTTP::Get.new(uri)
  request['API-Key'] = SCADA_API_KEY

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    segments = JSON.parse(response.body)
    segments.each do |segment|
      unless ScadaSegment.exists?(uuid: segment['id'])
        ScadaSegment.create!(
          site_id: site_id,
          uuid: segment['id'],
          apcode: segment['apcode'],
          uri: segment['uri'],
          name: segment['name'],
          apcode_idx: segment['apcode_idx']
        )
      else
        puts "Segment with UUID #{segment['id']} already exists. Skipping..."
      end
    end
  else
    puts "Error for site_id #{site_id}: #{response.message}"
  end
end

puts "Segments persisted successfully."
