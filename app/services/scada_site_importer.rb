class ScadaSiteImporter
  API_URL = 'https://portal.solarpark-online.com/ifms/agents/4b5dc3b7-4ea5-4ed4-a32b-a78645085104/sites'
  API_KEY = ENV['SCADA_API_KEY']

  def self.fetch_and_import
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['API-Key'] = API_KEY

    response = http.request(request)
    data = JSON.parse(response.body)

    org = ScadaOrganization.find_by!(name: 'First Organization')

    data.each do |row|
      ScadaSite.import_from_api_data(row, org.id)
    end
  end
end
