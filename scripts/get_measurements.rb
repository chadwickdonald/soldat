require 'net/http'
require 'uri'
require 'json'
require_relative '../config/environment'

mloc_uuids = ScadaMloc.pluck(:uuid).last(23280)

api_key = '4babde93-07c2-428c-9bd4-6f04b038afe1.01'

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

    scada_measurement = ScadaMeasurement.create!(
    	mloc_id: mloc_uuid,
      apcode: measurement_data['apcode'],
      uuid: measurement_data['id'],
      name: measurement_data['name'],
      rcv: measurement_data['rcv'],
      measure_type_id: measure_type['id'],
      measure_type_apcode: measure_type['apcode'],
      measure_type_data_type: measure_type['dataType'],
      measure_type_name: measure_type['name'],
      measure_type_uri: measure_type['uri'],
      segment_id: segment['id'],
      segment_apcode: segment['apcode'],
      segment_apcode_idx: segment['apcode_idx'],
      segment_name: segment['name'],
      segment_uri: segment['uri'],
      monitor_eng_unit: monitor['engUnit'],
      monitor: monitor['monitor'],
      monitor_status: monitor['status'],
      monitor_uri: monitor['uri']
    )
    
    sources.each do |source|
      ScadaMeasurementSource.create!(
        scada_measurement_id: scada_measurement.id,
        uuid: source['id'],
        calc_period: source['calcPeriod'],
        calc_time_span_count: source['calcTimeSpanCount'],
        calc_time_span_mode: source['calcTimeSpanMode'],
        manual_ingest: source['manualIngest'],
        eng_unit: source['engUnit'],
        quality: source['quality'],
        range: source['range'],
        uri: source['uri'],
        calc_type_apcode: source['calcTypeApcode'],
        date: source['date'],
        val: source['val']
      )
    end
  else
    puts "Error: #{response.message} for mloc_uuid: #{mloc_uuid}"
  end
end

puts "Measurements and sources persisted successfully."
