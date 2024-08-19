class ScadaMloc < ApplicationRecord
  has_many :scada_measurements, primary_key: 'uuid', foreign_key: 'mloc_id'
  belongs_to :scada_segment, primary_key: 'uuid', foreign_key: 'segment_id'
end