# app/services/site_data_service.rb
require 'net/http'
require 'json'

class SiteDataService
  agent_id = "4b5dc3b7-4ea5-4ed4-a32b-a78645085104"
  API_URL = "https://portal.solarpark-online.com/ifms/agents/#{agent_id}/sites".freeze

  def initialize(api_key)
    @api_key = api_key.strip
  end

  def fetch_sites
    uri = URI(API_URL)
    request = Net::HTTP::Get.new(uri)
    request['API-Key'] = @api_key
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  private

  def handle_response(response)

    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 401
      raise 'Unauthorized: Invalid API Key'
    when 404
      raise 'Not Found: The requested resource does not exist'
    else
      raise "Error: Received HTTP #{response.code}"
    end
  end
end
