class ScadaEvent < ActiveRecord::Base
  belongs_to :scada_measurement_source, primary_key: 'uuid', foreign_key: 'measurement_source_id'
end