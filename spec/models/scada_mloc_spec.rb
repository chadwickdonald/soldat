# spec/models/scada_mloc_spec.rb
require 'rails_helper'

RSpec.describe ScadaMloc, type: :model do
  describe '.persist_from_pf' do
    let!(:org) { ScadaOrganization.create!(uuid: 'org-uuid', name: 'Test Org') }
    let!(:site) { ScadaSite.create!(uuid: '25658d43-0ffd-42b4-a4e4-d3b808e85087', name: 'Test Site', organization_id: org.id) }
    let!(:segment) { ScadaSegment.create!(uuid: "b20ab912-8854-11ee-a4ff-42010afa015a", site_id: site.uuid, name: "Tracker TCU-073-006") }

    let(:mloc_data) do
      {
        'id' => "5af838ce-8855-11ee-a4ff-42010afa015a",
        'segmentId' => segment.uuid,
        'apcode' => 'TrackerIDNumber',
        'name' => 'ID number',
        'sscode' => nil,
        'uri' => 'http://portal.example.com/mlocs/mloc-uuid-123',
        'measurementTypeId' => '3074ed08-8264-11de-ad55-0090f586a869'
      }
    end

    it 'creates a new ScadaMloc if it does not exist' do
      expect {
        ScadaMloc.persist_from_pf(mloc_data, segment.uuid)
      }.to change(ScadaMloc, :count).by(1)

      mloc = ScadaMloc.last
      expect(mloc.uuid).to eq("5af838ce-8855-11ee-a4ff-42010afa015a")
      expect(mloc.name).to eq('ID number')
    end

    before do
      ScadaMloc.destroy_all
    end

    it 'does not create a duplicate ScadaMloc' do
      ScadaMloc.create!(uuid: "5af838ce-8855-11ee-a4ff-42010afa015a", segment_id: segment.uuid, name: 'Existing MLOC')
      
      expect {
        ScadaMloc.persist_from_pf(mloc_data, segment.uuid)

      }.not_to change(ScadaMloc, :count)
    end
  end
end
