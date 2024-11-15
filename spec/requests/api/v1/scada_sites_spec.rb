require_relative '../../../rails_helper'

RSpec.describe "ScadaSites API", type: :request do
  fixtures :scada_sites

  describe "GET /api/v1/scada_organizations" do
    it "returns all sites for an organization" do
      get "/api/v1/scada_organizations/1/scada_sites"
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end

  describe "GET /api/v1/scada_organizations/1/scada_sites/:id" do
    context "when the site exists" do
      it "returns the site" do
        get "/api/v1/scada_organizations/#{scada_organizations(:one).id}/scada_sites/#{@scada_sites(:one).id}"
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['name']).to eq("Test Site One")
      end
    end

    context "when the site does not exist" do
      it "returns a 404 not found error" do
        get "/api/v1/scada_organizations/1/scada_sites/9999"
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include("error" => "Couldn't find ScadaSite with 'id'=9999")
      end
    end
  end
end