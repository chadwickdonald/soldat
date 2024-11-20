require_relative '../../../rails_helper'

RSpec.describe "ScadaSegments API", type: :request do
  fixtures :scada_segments

  let(:api_key) { ApiClient.create!(name: "Test Client", api_key: SecureRandom.hex(20)).api_key }
  let(:headers) { { "API-KEY" => api_key } }

  describe "GET /api/v1/scada_organizations/1/scada_sites/1/scada_segments" do
    it "returns all segments for a site" do
      get "/api/v1/scada_organizations/1/scada_sites/1/scada_segments", headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET /api/v1/scada_organizations/1/scada_sites/1/scada_segments/13" do
    context "when the segment exists" do
      it "returns the segment" do
        get "/api/v1/scada_organizations/1/scada_sites/1/scada_segments/#{scada_segments(:one).id}", headers: headers
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['apcode']).to eq("WeatherStation")
      end
    end

    context "when the segment does not exist" do
      it "returns a 404 not found error" do
        get "/api/v1/scada_organizations/1/scada_sites/1/scada_segments/9999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end