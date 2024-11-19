require_relative '../../../rails_helper'

RSpec.describe "ScadaEvents API", type: :request do
  fixtures :scada_events, :scada_organizations, :scada_sites, :scada_segments, :scada_mlocs,
    :scada_measurements, :scada_measurement_sources

  let(:api_key) { ApiClient.create!(name: "Test Client", api_key: SecureRandom.hex(20)).api_key }
  let(:headers) { { "API-KEY" => api_key, "Content-Type" => "application/json" } }
  let(:body) do
    {
      "scada_organization_uuid": "57208d3d-4c02-4aeb-91ab-7f9f064196fb",
      "scada_site_uuid": "25658d43-0ffd-42b4-a4e4-d3b808e85087",
      "scada_segment_uuid": "9b182fdc-8854-11ee-a4ff-42010afa015a",
      "scada_mloc_uuid": "b68cadd8-8854-11ee-a4ff-42010afa015a",
      "scada_measurement_uuid": "b68cadd8-8854-11ee-a4ff-42010afa015a",
      "scada_measurement_source_uuid": "b68cb0a8-8854-11ee-a4ff-42010afa015a",
      "start_time": "2024-03-01 00:00:00 UTC",
      "end_time": "2024-03-01 00:10:00 UTC"
    }.to_json
  end  

  describe "POST /api/v1/scada_events" do
    it "returns all events within a date range" do
      post "/api/v1/scada_events", params: body, headers: headers
      expect(response).to have_http_status(:success)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_a(Array)
      expect(parsed_response.size).to eq(3)
    end
  end

  describe "POST /api/v1/scada_events" do
    it "returns all events within a date range" do
      body2 = body
      body2["start_time"] = "2022-03-01 00:00:00 UTC"
      body2["end_time"] = "2022-03-01 00:10:00 UTC"
      post "/api/v1/scada_events", params: body, headers: headers
      expect(response).to have_http_status(:success)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to be_a(Array)
      expect(parsed_response.size).to eq(0)
    end
  end
end