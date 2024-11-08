require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

# mloc_uuids = ScadaMloc.pluck(:uuid).last(23280)
all_mloc_uuids = ScadaMloc.pluck(:uuid)
first_mloc_uuids = ScadaMloc.pluck(:uuid).first(5000)
mloc_uuids = all_mloc_uuids - first_mloc_uuids

api_key = SCADA_API_KEY

mloc_uuids.each do |mloc_uuid|
  uri = URI("https://portal.solarpark-online.com/ifms/mlocs/#{mloc_uuid}")
  request = Net::HTTP::Get.new(uri)
  request['API-Key'] = api_key

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    measurement_data = JSON.parse(response.body)

    measure_type = measurement_data['measureType'] || {}
    monitor = measurement_data['monitor'] || {}
    segment = measurement_data['segment'] || {}
    sources = measurement_data['sources'] || []

    scada_measurement = ScadaMeasurement.find_by(uuid: measurement_data['id'])

    if scada_measurement.present? && scada_measurement.mloc_id.nil?
      if scada_measurement.id % 100 == 0
        puts "--updating scada_measurement #{scada_measurement.id} with mloc #{mloc_uuid}"
      end
      scada_measurement.update_attribute(:mloc_id, mloc_uuid)
    end

  else
    puts "Error: #{response.message} for mloc_uuid: #{mloc_uuid}"
  end
end

puts "Measurement updated."


# mloc_uuids = 
# ["badfb088-8854-11ee-a4ff-42010afa015a",
#  "badfaa20-8854-11ee-a4ff-42010afa015a",
#  "bc23286c-8854-11ee-a4ff-42010afa015a",
#  "bc23234e-8854-11ee-a4ff-42010afa015a",
#  "ba9ce870-8854-11ee-a4ff-42010afa015a",
#  "ba9ce3de-8854-11ee-a4ff-42010afa015a",
#  "aea52ed8-e2b8-11ee-bc83-42010afa015a",
#  "66f648b4-8855-11ee-a4ff-42010afa015a",
#  "6bc6bbe4-8855-11ee-a4ff-42010afa015a",
#  "819edd34-8855-11ee-a4ff-42010afa015a",
#  "a3d9e33a-8855-11ee-a4ff-42010afa015a",
#  "a3d9da98-8855-11ee-a4ff-42010afa015a",
#  "a3d9857a-8855-11ee-a4ff-42010afa015a",
#  "a3d9740e-8855-11ee-a4ff-42010afa015a",
#  "a3d960cc-8855-11ee-a4ff-42010afa015a",
#  "a3d94ccc-8855-11ee-a4ff-42010afa015a",
#  "a3d937be-8855-11ee-a4ff-42010afa015a",
#  "969bfdda-e2b8-11ee-bc83-42010afa015a",
#  "7641f41c-8855-11ee-a4ff-42010afa015a",
#  "ca788926-e2b7-11ee-bc83-42010afa015a",
#  "bf18d248-e2b7-11ee-bc83-42010afa015a",
#  "bbc3375e-8854-11ee-a4ff-42010afa015a",
#  "bbc33088-8854-11ee-a4ff-42010afa015a",
#  "ba98198a-e2b8-11ee-bc83-42010afa015a",
#  "4dc04f44-e2b8-11ee-bc83-42010afa015a",
#  "bcac84a4-8854-11ee-a4ff-42010afa015a",
#  "bcac7d42-8854-11ee-a4ff-42010afa015a",
#  "bb522c26-8854-11ee-a4ff-42010afa015a",
#  "bb522726-8854-11ee-a4ff-42010afa015a",
#  "b3bb763a-e2b7-11ee-bc83-42010afa015a",
#  "bbd9445e-8854-11ee-a4ff-42010afa015a",
#  "bbd93ef0-8854-11ee-a4ff-42010afa015a",
#  "ba830ad6-8854-11ee-a4ff-42010afa015a",
#  "ba830586-8854-11ee-a4ff-42010afa015a",
#  "8d1a4f36-8855-11ee-a4ff-42010afa015a",
#  "8d1a4810-8855-11ee-a4ff-42010afa015a",
#  "8d19fba8-8855-11ee-a4ff-42010afa015a",
#  "8d19e9e2-8855-11ee-a4ff-42010afa015a",
#  "8d19d6d2-8855-11ee-a4ff-42010afa015a",
#  "8d19bbde-8855-11ee-a4ff-42010afa015a",
#  "8d19a8c4-8855-11ee-a4ff-42010afa015a",
#  "bd16339a-8854-11ee-a4ff-42010afa015a",
#  "bd162d50-8854-11ee-a4ff-42010afa015a",
#  "bb955ab4-8854-11ee-a4ff-42010afa015a",
#  "bb955636-8854-11ee-a4ff-42010afa015a",
#  "7bee20ac-8855-11ee-a4ff-42010afa015a",
#  "866b8f24-8855-11ee-a4ff-42010afa015a",
#  "4d84f40c-8855-11ee-a4ff-42010afa015a",
#  "bd4648f0-8854-11ee-a4ff-42010afa015a",
#  "bd4643c8-8854-11ee-a4ff-42010afa015a",
#  "619a6882-8855-11ee-a4ff-42010afa015a",
#  "a29d96b6-e2b8-11ee-bc83-42010afa015a",
#  "bbf044ec-8854-11ee-a4ff-42010afa015a",
#  "bbf03fa6-8854-11ee-a4ff-42010afa015a",
#  "ea69728a-e2b8-11ee-bc83-42010afa015a"]





# sm_nils = []
# ScadaMloc.all.each do |sm|
#   if sm.scada_measurements.count == 0
#     sm_nils << sm.uuid
#     print "sm_nils.count: #{sm_nils.count}"
#   end
# end; nil





