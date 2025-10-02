class FieldAlias < ApplicationRecord
  belongs_to :scada_measurement
  enum relevance: {
    low: 1,
    medium: 2,
    high: 3,
    critical: 4
  }
end