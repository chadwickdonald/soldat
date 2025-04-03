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

  describe '#fetch_and_persist_sites' do
    it 'fetches and persists site data', :vcr do
      expect {
        service.fetch_and_persist_sites
      }.to change(ScadaSite, :count).by_at_least(1)

      expect(ScadaSite.first.uuid).to be_present
    end
  end
end