require 'rails_helper'

RSpec.describe ScadaMeasurement, type: :model do
  describe '.persist_from_pf' do
    let(:mloc_uuid) { SecureRandom.uuid }
    let(:segment_uuid) { SecureRandom.uuid }
    let!(:org) { ScadaOrganization.create!(uuid: SecureRandom.uuid, name: "Test Org") }

    let!(:site) do
      ScadaSite.create!(
        uuid: SecureRandom.uuid,
        name: "Test Site",
        scada_organization: org
      )
    end

    let!(:segment) do
      ScadaSegment.create!(
        uuid: segment_uuid,
        apcode: "InverterModule",
        scada_site: site
      )
    end

    let!(:mloc) do
      ScadaMloc.create!(
        uuid: mloc_uuid,
        scada_segment: segment
      )
    end

    let(:measurement_data) do
      {
        "apcode" => "ArrayOutputPowerTr2",
        "id" => SecureRandom.uuid,
        "name" => "Power Inverter Module AC (1m)",
        "rcv" => false,
        "segment" => {
          "apcode" => "InverterModule",
          "id" => segment_uuid
        },
        "sources" => [
          {
            "id" => SecureRandom.uuid,
            "date" => "20250410T032300Z",
            "val" => "123.4",
            "engUnit" => "kW",
            "calcPeriod" => "1m",
            "calcTimeSpanMode" => "fixed-time-span",
            "calcTimeSpanCount" => 1,
            "calcTypeApcode" => "TimeSeriesAverage",
            "manualIngest" => false
          }
        ]
      }
    end

    it 'creates a ScadaMeasurement' do
      expect {
        ScadaMeasurement.persist_from_pf(measurement_data, mloc_uuid)
      }.to change { ScadaMeasurement.count }.by(1)
       .and change { ScadaMeasurementSource.count }.by(1)

      measurement = ScadaMeasurement.last
      source = measurement.scada_measurement_sources.last

      expect(measurement.scada_segment.uuid).to eq segment_uuid
      expect(source.val).to eq 123.4
    end
  end
end
