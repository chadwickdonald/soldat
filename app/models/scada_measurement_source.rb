class ScadaMeasurementSource < ApplicationRecord
  belongs_to :scada_measurement, primary_key: 'id', foreign_key: 'scada_measurement_id'
  has_many :scada_events, primary_key: 'uuid', foreign_key: 'measurement_source_id'
end