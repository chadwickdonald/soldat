# app/services/pf/measurement_data_service.rb
module Pf
  class MeasurementDataService < BaseApiService

    def fetch_measurements(mloc_id)
      get("/mlocs/#{mloc_id}")
    end

    def fetch_all_measurements
      mloc_ids = ScadaMloc.pluck(:uuid)
      # mloc_ids = ["4fe3ad0a-1820-11ef-a962-42010afa015a", "4fe3b8f4-1820-11ef-a962-42010afa015a"]

      mloc_ids.each do |mloc_id|
        begin
          measurements = fetch_measurements(mloc_id)
          measurements = [measurements] if measurements.class == Hash
          Rails.logger.info "Fetched #{measurements.count} measurements for mloc #{mloc_id}"

          measurements.each do |measurement_data|
            if ScadaMeasurement.exists?(uuid: measurement_data['id'])
              Rails.logger.info "Skipping existing measurement #{measurement_data['id']}"
              next
            end

            begin
              ScadaMeasurement.persist_from_pf(measurement_data, mloc_id)
              Rails.logger.info "Created measurement #{measurement_data['id']}"
            rescue => e
              Rails.logger.error "Failed to persist measurement #{measurement_data['id']}: #{e.message}"
            end
          end
        rescue => e
          Rails.logger.error "Failed to fetch measurements for mloc #{mloc_id}: #{e.message}"
        end
      end
    end
  end
end
