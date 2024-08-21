class ScadaStateVariable < ApplicationRecord
  belongs_to :scada_segment, primary_key: 'uuid', foreign_key: 'segment_id'
end