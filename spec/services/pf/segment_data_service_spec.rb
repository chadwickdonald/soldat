# spec/services/pf/segment_data_service_spec.rb
require 'rails_helper'
require 'vcr'

RSpec.describe Pf::SegmentDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  describe '#fetch_segments', :vcr do
    let(:site_id) { '01b66255-c94a-44b3-a5ba-540850108e26' }

    it 'fetches segments for a given site' do
      response = service.fetch_segments(site_id)
      expect(response).to be_an(Array)
      expect(response.first).to have_key('id')
      expect(response.first['id']).to eq("2f729116-9833-11ee-be18-42010afa015a")
    end
  end

  describe '#fetch_all_segments', :vcr do
    before do
      ScadaSite.create!(uuid: '01b66255-c94a-44b3-a5ba-540850108e26', name: 'Test Site', organization_id: 1)
    end

    it 'fetches and persists segments for all sites' do
      expect {
        service.fetch_all_segments
      }.to change(ScadaSegment, :count).by_at_least(1)
    end
  end
end
