# spec/services/site_data_service_spec.rb
require 'rails_helper'
require 'vcr'

RSpec.describe SiteDataService do
  let(:api_key) { ENV['SCADA_API_KEY'] }
  let(:service) { described_class.new(api_key) }

  it 'fetches site data successfully', :vcr do
    response = service.fetch_sites
    expect(response).to be_an(Array)
    expect(response.first).to have_key('id')
    expect(response.first["id"]).to eq('25658d43-0ffd-42b4-a4e4-d3b808e85087')
  end

  it 'handles unauthorized errors', :vcr do
    invalid_service = described_class.new('invalid_key')
    
    expect {
      invalid_service.fetch_sites
    }.to raise_error('Unauthorized: Invalid API Key')
  end
end
