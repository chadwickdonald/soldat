require 'rails_helper'
require 'vcr'

RSpec.describe Pf::EventDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  describe '#fetch_events', :vcr do
    let(:site_ids) { ["25658d43-0ffd-42b4-a4e4-d3b808e85087"] }
    let(:start_date) { "20250301T010000Z" }
    let(:end_date)   { "20250301T010500Z" }
    let(:apcodes)    { ["PPCActivePowerTr2"] }

    it 'returns an array of events from the API' do
      response = service.fetch_events(
        site_ids: site_ids,
        start_date: start_date,
        end_date: end_date,
        apcodes: apcodes
      )

      expect(response).to be_an(Array)
      expect(response.first).to include("siteId", "date", "val")
    end
  end

  describe '#fetch_and_persist_events', :vcr do
    let(:site_ids) { ["25658d43-0ffd-42b4-a4e4-d3b808e85087"] }
    let(:start_date) { "20250301T010000Z" }
    let(:end_date)   { "20250301T010500Z" }
    let(:apcodes)    { ["PPCActivePowerTr2"] }

    let!(:scada_org) { ScadaOrganization.create!(uuid: SecureRandom.uuid, name: "Org") }
    let!(:scada_site) { ScadaSite.create!(uuid: site_ids.first, name: "Site", scada_organization: scada_org) }
    let!(:scada_segment) { ScadaSegment.create!(uuid: SecureRandom.uuid, apcode: "TestApcode", scada_site: scada_site) }
    let!(:scada_mloc) { ScadaMloc.create!(uuid: SecureRandom.uuid, scada_segment: scada_segment) }
    let!(:scada_measurement) do
      ScadaMeasurement.create!(
        uuid: SecureRandom.uuid,
        name: "Test Measurement",
        apcode: apcodes.first,
        rcv: true,
        mloc_id: scada_mloc.uuid,
        segment_id: scada_segment.uuid
      )
    end
    let!(:source) do
      ScadaMeasurementSource.create!(
        uuid: "b8bcd7ae-8854-11ee-a4ff-42010afa015a",
        scada_measurement: scada_measurement,
        date: Time.zone.now,
        val: 123.4,
        eng_unit: "kW",
        calc_period: "5m",
        calc_time_span_mode: "Fixed",
        calc_time_span_count: 1,
        calc_type_apcode: "SomeType",
        manual_ingest: false
      )
    end

    before do
      ScadaEvent.delete_all
    end

    it 'fetches and persists events from the API' do
      expect {
        service.fetch_and_persist_events(
          site_ids: site_ids,
          start_date: start_date,
          end_date: end_date,
          apcodes: apcodes
        )
      }.to change(ScadaEvent, :count).by_at_least(1)
    end
  end
end
