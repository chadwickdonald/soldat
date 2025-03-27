# # spec/services/pf/site_data_service_spec.rb
require 'rails_helper'
require 'vcr'

RSpec.describe Pf::SiteDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  describe '#fetch_sites' do
    it 'fetches site data successfully', :vcr do
      response = service.fetch_sites
      expect(response).to be_an(Array)
      expect(response.first).to have_key('id')
      expect(response.first["id"]).to eq("01b66255-c94a-44b3-a5ba-540850108e26")
    end

    it 'handles unauthorized errors', :vcr do
      invalid_service = described_class.new('invalid_key')
      
      expect {
        invalid_service.fetch_sites
      }.to raise_error('Unauthorized: Invalid API Key')
    end
  end

  describe '#persist' do
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
        service.persist(site_data)
      }.to change(ScadaSite, :count).by(1)

      scada_site = ScadaSite.last
      expect(scada_site.uuid).to eq('test-uuid-123')
      expect(scada_site.name).to eq('Test Site')
      expect(scada_site.latitude).to eq('29.0')
    end

    it 'does not create a duplicate ScadaSite' do
      ScadaSite.create!(uuid: 'test-uuid-123', name: 'Existing', organization_id: 1)
      expect {
        service.persist(site_data)
      }.not_to change(ScadaSite, :count)
    end
  end

  describe '#fetch_and_persist_sites' do
    it 'fetches and persists site data', :vcr do
      expect {
        service.fetch_and_persist_sites
      }.to change(ScadaSite, :count).by_at_least(1)

      expect(ScadaSite.first.uuid).to be_present
    end
  end
end