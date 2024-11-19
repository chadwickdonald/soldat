require_relative '../../../rails_helper'

RSpec.describe "ScadaSites API", type: :request do
  fixtures :scada_sites

  let(:api_key) { ApiClient.create!(name: "Test Client", api_key: SecureRandom.hex(20)).api_key }
  let(:headers) { { "API-KEY" => api_key } }

  describe "GET /api/v1/scada_organizations" do
    it "returns all sites for an organization" do
      get "/api/v1/scada_organizations/1/scada_sites", headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end

  describe "GET /api/v1/scada_organizations/1/scada_sites/:id" do
    context "when the site exists" do
      it "returns the site" do
        get "/api/v1/scada_organizations/1/scada_sites/#{scada_sites(:one).id}", headers: headers
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['name']).to eq("Site T3")
      end
    end

    context "when the site does not exist" do
      it "returns a 404 not found error" do
        get "/api/v1/scada_organizations/1/scada_sites/9999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end