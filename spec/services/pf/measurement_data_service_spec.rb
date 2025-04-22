require 'rails_helper'
require 'vcr'

RSpec.describe Pf::MeasurementDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  describe '#fetch_measurements', :vcr do
    let(:mloc_id) { "4e6418a8-8855-11ee-a4ff-42010afa015a" }

    it 'fetches measurements for a given mloc' do
      response = service.fetch_measurements(mloc_id)
      expect(response.first).to include("name", "Power Inverter Module AC (1m)")
    end
  end

  describe '#fetch_all_measurements', :vcr do
    let!(:scada_org) { ScadaOrganization.create!(uuid: SecureRandom.uuid, name: "Org") }

    let!(:scada_site) do
      ScadaSite.create!(
        uuid: SecureRandom.uuid,
        name: "Site",
        scada_organization: scada_org
      )
    end

    let!(:scada_segment) do
      ScadaSegment.create!(
        uuid: SecureRandom.uuid,
        apcode: "InverterModule",
        scada_site: scada_site
      )
    end

    let!(:scada_mloc) do
      ScadaMloc.create!(
        uuid: "4e6418a8-8855-11ee-a4ff-42010afa015a",
        scada_segment: scada_segment
      )
    end

    before do
      ScadaMeasurement.destroy_all
      ScadaMeasurementSource.destroy_all
    end

    it 'fetches and persists measurements for all mlocs' do
      expect {
        service.fetch_all_measurements
      }.to change(ScadaMeasurement, :count).by_at_least(1)
       .and change(ScadaMeasurementSource, :count).by_at_least(1)

      last = ScadaMeasurement.last
      expect(last.name).to be_present
      expect(last.scada_mloc.uuid).to eq("4e6418a8-8855-11ee-a4ff-42010afa015a")
    end
  end
end
