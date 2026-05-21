# spec/models/scada_segment_spec.rb
require 'rails_helper'

RSpec.describe ScadaSegment, type: :model do
  describe '.persist_from_pf' do
    let!(:org) { ScadaOrganization.create!(uuid: 'org-uuid', name: 'Test Org') }
    let!(:site) { ScadaSite.create!(uuid: 'site-uuid-123', name: 'Test Site', organization_id: org.id) }

    let(:segment_data) do
      {
        'id' => 'segment-uuid-001',
        'siteId' => site.uuid,
        'name' => 'Segment A',
        'apcode' => 'test_apcode',
        'uri' => 'test_uri',
        'apcode_idx' => 'test_apcode_idx',
        'createdAt' => '2024-01-01T00:00:00Z',
        'updatedAt' => '2024-02-01T00:00:00Z'
      }
    end

    it 'creates a new ScadaSegment if it does not exist' do
      expect {
        ScadaSegment.persist_from_pf(segment_data, site.uuid)
      }.to change(ScadaSegment, :count).by(1)

      segment = ScadaSegment.last
      expect(segment.uuid).to eq('segment-uuid-001')
      expect(segment.name).to eq('Segment A')
    end

    it 'does not create a duplicate ScadaSegment' do
      ScadaSegment.create!(uuid: 'segment-uuid-001', site_id: site.uuid, name: 'Existing Segment')
      
      expect {
        ScadaSegment.persist_from_pf(segment_data, site.uuid)
      }.not_to change(ScadaSegment, :count)
    end
  end
end
