class ScadaSegment < ApplicationRecord
  has_many :scada_mloc, primary_key: 'uuid', foreign_key: 'segment_id'
  belongs_to :scada_site, primary_key: 'uuid', foreign_key: 'site_id'
end