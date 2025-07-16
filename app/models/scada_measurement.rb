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

      # Segment fields
      segment_id: data.dig("segment", "id"),
      segment_apcode: data.dig("segment", "apcode"),
      segment_apcode_idx: data.dig("segment", "apcode_idx"),
      segment_name: data.dig("segment", "name"),
      segment_uri: data.dig("segment", "uri"),

      # Measure type fields
      measure_type_id: data.dig("measureType", "id"),
      measure_type_apcode: data.dig("measureType", "apcode"),
      measure_type_data_type: data.dig("measureType", "dataType"),
      measure_type_name: data.dig("measureType", "name"),
      measure_type_uri: data.dig("measureType", "uri"),

      # Monitor fields
      monitor_eng_unit: data.dig("monitor", "engUnit"),
      monitor: data.dig("monitor", "monitor"),
      monitor_status: data.dig("monitor", "status"),
      monitor_uri: data.dig("monitor", "uri")
    )

    begin
      measurement.save!
    rescue => e
      Rails.logger.error "Failed to create Measurement #{data['id']}: #{e.message} – Source data: #{data.inspect}"
    end

    begin
      data["sources"]&.each do |src|
        measurement.scada_measurement_sources.create!(
          uuid: src["id"],
          date: Time.zone.parse(src["date"]),
          val: src["val"].to_f,
          eng_unit: src["engUnit"],
          quality: src["quality"],
          range: src["range"],
          uri: src["uri"],
          calc_period: src["calcPeriod"],
          calc_time_span_mode: src["calcTimeSpanMode"],
          calc_time_span_count: src["calcTimeSpanCount"],
          calc_type_apcode: src["calcTypeApcode"],
          manual_ingest: src["manualIngest"]
        )
      end
    rescue => e
      Rails.logger.error "Failed to create MeasurementSource #{data['id']}: #{e.message} – Source data: #{data.inspect}"
    end

    measurement
  end
end