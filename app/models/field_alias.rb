class FieldAlias < ApplicationRecord
  belongs_to :scada_measurement
  enum :relevance, {
    high_priority: 1,
    detailed_analysis: 2,
    alarms_notifications_diagnostics: 3,
    unknown: 4
  }
end