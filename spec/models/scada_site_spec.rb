# spec/models/scada_site_spec.rb
require 'rails_helper'

RSpec.describe ScadaSite, type: :model do
  describe '.persist_from_pf' do
    let(:site_data) do
      {
        'id' => 'test-uuid-123',
        'name' => 'Test Site',
        'siteTypeApcode' => 'PVPlant',
        'state' => 'online',
        'enterprise' => { 'id' => 'ent-id', 'name' => 'Fake Enterprise' },
        'properties' => {
          'Timezone' => 'US/Central',
          'Latitude' => '29.0',
          'Longitude' => '-95.0',
          'AddressStreet' => '123 Fake St.',
          'City' => 'Houston',
          'Country' => 'USA',
          'Portfolio' => 'TestCo',
          'RecordingPeriod' => '5m',
          'NumOfTCPs' => '42'
        }
      }
    end

    it 'creates a new ScadaSite if it does not exist' do
      expect {
        ScadaSite.persist_from_pf(site_data)
      }.to change(ScadaSite, :count).by(1)

      scada_site = ScadaSite.last
      expect(scada_site.uuid).to eq('test-uuid-123')
      expect(scada_site.name).to eq('Test Site')
      expect(scada_site.latitude).to eq('29.0')
    end

    it 'does not create a duplicate ScadaSite' do
      ScadaSite.create!(uuid: 'test-uuid-123', name: 'Existing', organization_id: 1)
      
      expect {
        ScadaSite.persist_from_pf(site_data)
      }.not_to change(ScadaSite, :count)
    end
  end
end
