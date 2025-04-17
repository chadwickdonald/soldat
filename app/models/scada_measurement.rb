class ScadaMeasurement < ApplicationRecord
  has_many :scada_measurement_sources, primary_key: 'id', foreign_key: 'scada_measurement_id'
  belongs_to :scada_mloc, primary_key: 'uuid', foreign_key: 'mloc_id'
  belongs_to :scada_segment, primary_key: 'uuid', foreign_key: 'segment_id', optional: true
  has_one :field_alias, dependent: :destroy

  def self.persist_from_pf(data, mloc_id)
    measurement = ScadaMeasurement.find_or_initialize_by(uuid: data["id"])

    measurement.assign_attributes(
      apcode: data["apcode"],
      name: data["name"],
      rcv: data["rcv"],
      mloc_id: mloc_id,
      segment_id: data.dig("segment", "id")
    )

    measurement.save!

    data["sources"]&.each do |src|
      measurement.scada_measurement_sources.create!(
        uuid: src["id"],
        date: Time.zone.parse(src["date"]),
        val: src["val"].to_f,
        eng_unit: src["engUnit"],
        calc_period: src["calcPeriod"],
        calc_time_span_mode: src["calcTimeSpanMode"],
        calc_time_span_count: src["calcTimeSpanCount"],
        calc_type_apcode: src["calcTypeApcode"],
        manual_ingest: src["manualIngest"]
      )
    end
    measurement
  end
end