# app/models/scada_organization.rb
class ScadaOrganization < ApplicationRecord
	has_many :scada_sites, primary_key: 'id', foreign_key: 'organization_id'
end