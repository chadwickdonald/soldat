require 'rails_helper'

# Tests the logic exercised by scripts/fix_station_ids.rb — that iterating
# FieldAlias records and applying StationIdExtractor.call(segment_name)
# produces correct station_id values.
RSpec.describe "fix_station_ids script logic" do
  def build_field_alias(segment_name:, station_id:)
    org  = ScadaOrganization.create!(uuid: SecureRandom.uuid, name: "Org #{SecureRandom.hex(4)}")
    site = ScadaSite.create!(uuid: SecureRandom.uuid, site_id: SecureRandom.uuid,
                             organization_id: org.id, name: "Site")
    seg  = ScadaSegment.create!(uuid: SecureRandom.uuid, site_id: site.uuid,
                                name: segment_name, apcode: "SEG#{SecureRandom.hex(3)}")
    mloc = ScadaMloc.create!(uuid: SecureRandom.uuid, segment_id: seg.uuid,
                             name: "MLOC", apcode: "ML#{SecureRandom.hex(3)}")
    measurement = ScadaMeasurement.create!(
      uuid:         SecureRandom.uuid,
      mloc_id:      mloc.uuid,
      segment_name: segment_name,
      apcode:       "TEST#{SecureRandom.hex(3)}"
    )
    FieldAlias.create!(
      scada_measurement: measurement,
      station_id:        station_id,
      relevance:         :unknown
    )
  end

  def run_fix
    FieldAlias.includes(:scada_measurement).find_each do |fa|
      correct_id = StationIdExtractor.call(fa.scada_measurement&.segment_name)
      fa.update_column(:station_id, correct_id) unless fa.station_id == correct_id
    end
  end

  it "corrects a numeric station_id, preserving leading zeros" do
    fa = build_field_alias(segment_name: "Solar Inverter Block 089", station_id: "20")
    run_fix
    expect(fa.reload.station_id).to eq("089")
  end

  it "corrects an alphanumeric station_id" do
    fa = build_field_alias(segment_name: "Battery String 32A1.BESS.10B.S3", station_id: "999")
    run_fix
    expect(fa.reload.station_id).to eq("32A1.BESS.10B.S3")
  end

  it "corrects a hyphenated identifier" do
    fa = build_field_alias(segment_name: "Tracker TCU-080-072", station_id: "1")
    run_fix
    expect(fa.reload.station_id).to eq("TCU-080-072")
  end

  it "sets station_id to nil when segment name has no identifier token" do
    fa = build_field_alias(segment_name: "Met Station", station_id: "42")
    run_fix
    expect(fa.reload.station_id).to be_nil
  end

  it "does not update records that already have the correct station_id" do
    fa = build_field_alias(segment_name: "Solar Inverter Block 089", station_id: "89")
    expect { run_fix }.not_to(change { fa.reload.updated_at })
  end

  it "handles multiple records independently" do
    fa1 = build_field_alias(segment_name: "Solar Inverter Block 089", station_id: "20")
    fa2 = build_field_alias(segment_name: "Tracker TCU-080-072",       station_id: "5")
    fa3 = build_field_alias(segment_name: "Battery String 32A1.BESS.10B.S3", station_id: "99")
    run_fix
    expect(fa1.reload.station_id).to eq("089")
    expect(fa2.reload.station_id).to eq("TCU-080-072")
    expect(fa3.reload.station_id).to eq("32A1.BESS.10B.S3")
  end
end
