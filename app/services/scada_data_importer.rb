class ScadaDataImporter
  API_BASE_URL = 'https://portal.solarpark-online.com/ifms/agents/4b5dc3b7-4ea5-4ed4-a32b-a78645085104'
  API_KEY = ENV['SCADA_API_KEY']

  ENDPOINTS = {
    scada_sites: {
      url: "#{API_BASE_URL}/sites",
      processor: ->(data, org_id) { ScadaSite.import_from_api_data(data, org_id) }
    },
    scada_segments: {
      url: "#{API_BASE_URL}/segments",
      processor: ->(data, org_id) { ScadaSegment.import_from_api_data(data, org_id) }
    },
    scada_mlocs: {
      url: "#{API_BASE_URL}/mlocs",
      processor: ->(data, org_id) { ScadaMloc.import_from_api_data(data, org_id) }
    },
    scada_measurements: {
      url: "#{API_BASE_URL}/measurements",
      processor: ->(data, org_id) { ScadaMeasurement.import_from_api_data(data, org_id) }
    },
    scada_events: {
      url: "#{API_BASE_URL}/events",
      processor: ->(data, org_id) { ScadaEvent.import_from_api_data(data, org_id) }
    }
  }

  def self.fetch_and_import_all
    org = ScadaOrganization.find_by!(name: 'First Organization')

    ENDPOINTS.each do |key, config|
      puts "Fetching data for #{key}..."
      data = fetch_data(config[:url]) # add date window here? only fetch if data is missing?
      data.each { |row| config[:processor].call(row, org.id) } # do each row or pass data into the import method?
      puts "#{key.to_s.humanize} data import complete."
    end
  end

  def self.fetch_data(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['API-Key'] = API_KEY

    response = http.request(request)
    JSON.parse(response.body)
  rescue StandardError => e
    puts "Error fetching data from #{url}: #{e.message}"
    []
  end
end
