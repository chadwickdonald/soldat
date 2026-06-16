class ScadaOrganization < ApplicationRecord
  has_many :scada_sites, primary_key: 'id', foreign_key: 'organization_id'
  has_many :user_organizations, dependent: :destroy
  has_many :users, through: :user_organizations
end