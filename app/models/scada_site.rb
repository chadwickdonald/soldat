# app/models/scada_site.rb
class ScadaSite < ApplicationRecord
  has_many :scada_segments, primary_key: 'uuid', foreign_key: 'site_id'
  belongs_to :scada_organization, primary_key: 'id', foreign_key: 'organization_id'
end