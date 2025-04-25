class ScadaEvent < ActiveRecord::Base
  belongs_to :scada_measurement_source, primary_key: 'uuid', foreign_key: 'measurement_source_id'

  def self.persist_from_pf(data, measurement_source_id)
    event = ScadaEvent.find_or_initialize_by(
      site_id: data["site_id"] || data["siteId"],
      date: Time.zone.parse(data["date"]),
      measurement_source_id: measurement_source_id
    )

    event.assign_attributes(
      val: data["val"],
      cp_name: data["cp_name"] || data["cpName"],
      measurement_apcode: data["measurement_apcode"] || data["measurementApcode"]
    )

    event.save!
    event
  end
end