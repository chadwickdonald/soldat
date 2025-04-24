# spec/models/scada_event_spec.rb
require 'rails_helper'

RSpec.describe ScadaEvent, type: :model do
  describe '.persist_from_pf' do
    let!(:scada_segment) do
      ScadaSegment.create!(
        uuid: 'segment-uuid-789',
        apcode: 'SegmentApcode',
        scada_site: ScadaSite.create!(
          uuid: 'site-uuid-999',
          name: 'Test Site',
          scada_organization: ScadaOrganization.create!(uuid: 'org-uuid-999', name: 'Org')
        )
      )
    end

    let!(:scada_mloc) do
      ScadaMloc.create!(
        uuid: 'mloc-uuid-456',
        scada_segment: scada_segment
      )
    end

    let!(:measurement) do
      ScadaMeasurement.create!(
        uuid: 'measurement-uuid-123',
        apcode: 'SomeApcode',
        name: 'Test Measurement',
        rcv: true,
        mloc_id: scada_mloc.uuid,
        segment_id: scada_segment.uuid
      )
    end

    let!(:source) do
      ScadaMeasurementSource.create!(
        id: 'source-uuid-123',
        uuid: 'source-uuid-123',
        scada_measurement: measurement,
        date: Time.zone.now,
        val: 123.45,
        eng_unit: 'kW',
        calc_period: '5m',
        calc_time_span_mode: 'Fixed',
        calc_time_span_count: 1,
        calc_type_apcode: 'SomeCode',
        manual_ingest: false
      )
    end

    let(:event_data) do
      {
        "site_id" => "site-abc-456",
        "date" => "2024-03-01T23:55:00Z",
        "val" => 133.045,
        "cp_name" => "5m",
        "measurement_apcode" => "ArrayOutputPower"
      }
    end

    it 'creates a new ScadaEvent with the given data' do
      expect {
        ScadaEvent.persist_from_pf(event_data, source.uuid)
      }.to change(ScadaEvent, :count).by(1)

      event = ScadaEvent.last
      expect(event.site_id).to eq("site-abc-456")
      expect(event.date.utc.iso8601).to eq("2024-03-01T23:55:00Z")
      expect(event.measurement_source_id).to eq("source-uuid-123")
      expect(event.val).to eq(133.045)
      expect(event.cp_name).to eq("5m")
      expect(event.measurement_apcode).to eq("ArrayOutputPower")
    end

    it 'updates the event if it already exists' do
      existing = ScadaEvent.create!(
        site_id: event_data["site_id"],
        date: Time.zone.parse(event_data["date"]),
        measurement_source_id: source.uuid,
        val: 111.0,
        cp_name: "1m",
        measurement_apcode: "OldCode"
      )

      expect {
        ScadaEvent.persist_from_pf(event_data, source.uuid)
      }.not_to change(ScadaEvent, :count)

      existing.reload
      expect(existing.val).to eq(133.045)
      expect(existing.cp_name).to eq("5m")
      expect(existing.measurement_apcode).to eq("ArrayOutputPower")
    end
  end
end
