require_relative '../config/environment'
require 'securerandom'

ScadaOrganization.find_or_create_by(name: 'First Organization') do |organization|
  organization.uuid = SecureRandom.uuid
  organization.address = '123 Fake St.'
  organization.city = 'El Campo'
  organization.state = 'CA'
end
