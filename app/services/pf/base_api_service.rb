# app/services/pf/base_api_service.rb
require 'net/http'
require 'json'

module Pf
  class BaseApiService
    AGENT_ID = "4b5dc3b7-4ea5-4ed4-a32b-a78645085104".freeze
    BASE_URL = "https://portal.solarpark-online.com/ifms".freeze

    def initialize(api_key)
      @api_key = api_key.strip
    end

    def get(endpoint)
      uri = URI("#{BASE_URL}#{endpoint}")
      request = Net::HTTP::Get.new(uri)
      request['API-Key'] = @api_key

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def post(endpoint, payload)
      uri = URI("#{BASE_URL}#{endpoint}")
      request = Net::HTTP::Post.new(uri)
      request['API-Key'] = @api_key
      request['Content-Type'] = 'application/json'
      request.body = payload.to_json

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
end
