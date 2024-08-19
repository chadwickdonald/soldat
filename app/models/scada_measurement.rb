class ScadaMeasurement < ApplicationRecord
  has_many :scada_measurement_sources, primary_key: 'id', foreign_key: 'scada_measurement_id'
  belongs_to :scada_mloc, primary_key: 'uuid', foreign_key: 'mloc_id'
end