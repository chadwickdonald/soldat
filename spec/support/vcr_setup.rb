# spec/support/vcr_setup.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<SCADA_API_KEY>') { ENV['SCADA_API_KEY'] }
end
