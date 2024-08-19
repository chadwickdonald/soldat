class ScadaOrganization < ApplicationRecord
  has_many :scada_sites, primary_key: 'id', foreign_key: 'organization_id'
end