# spec/services/pf/mloc_data_service_spec.rb
require 'rails_helper'
require 'vcr'

RSpec.describe Pf::MlocDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  describe '#fetch_mlocs', :vcr do
    it 'fetches mlocs for a given segment' do
      segment_id = '1c0bc33a-efe1-11ee-a127-42010afa015a'
      response = service.fetch_mlocs(segment_id)
      expect(response).to be_an(Array)
      expect(response.first).to have_key('id')
    end
  end

  describe '#fetch_all_mlocs', :vcr do
    before do
      scada_site = ScadaSite.create!(
        uuid: 'site-uuid-123',
        name: 'Test Site',
        scada_organization: ScadaOrganization.create!(uuid: SecureRandom.uuid, name: 'Test Org')
        )
      ScadaSegment.create!(
        uuid: '1c0bc33a-efe1-11ee-a127-42010afa015a', 
        scada_site: scada_site, 
        name: 'Segment A'
        )
    end

    it 'fetches and persists mlocs for all segments' do
      expect {
        service.fetch_all_mlocs
      }.to change(ScadaMloc, :count).by_at_least(1)
    end
  end
end
