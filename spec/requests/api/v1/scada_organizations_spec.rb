require_relative '../../../rails_helper'

RSpec.describe "ScadaOrganizations API", type: :request do
  fixtures :scada_organizations

  let(:api_key) { ApiClient.create!(name: "Test Client", api_key: SecureRandom.hex(20)).api_key }
  let(:headers) { { "API-KEY" => api_key } }

  describe "GET /api/v1/scada_organizations" do
    it "returns all organizations" do
      get "/api/v1/scada_organizations", headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end

  describe "GET /api/v1/scada_organizations/:id" do
    context "when the organization exists" do
      it "returns the organization" do
        get "/api/v1/scada_organizations/#{scada_organizations(:one).id}", headers: headers
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['name']).to eq("Test Organization One")
      end
    end

    context "when the organization does not exist" do
      it "returns a 404 not found error" do
        get "/api/v1/scada_organizations/9999", headers: headers
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include("error" => "Couldn't find ScadaOrganization with 'id'=9999")
      end
    end
  end
end
