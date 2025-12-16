module Pf
  class EventDataService2 < BaseApiService

    def fetch_events(start_date:, end_date:, source_uuid:)
      puts "---fetch_events"
      payload = {
        startDate: start_date,
        endDate: end_date
      }

      get("/sources/#{source_uuid}/events?start_date=#{start_date}&end_date=#{end_date}")
    end

    def fetch_and_persist_events(start_date:, end_date:, source_uuid:, measurement_apcode:, site_id:, cp_name:)
      puts "---fetch and persist events between #{start_date} and #{end_date}"

      events = fetch_events(
        start_date: start_date,
        end_date: end_date,
        source_uuid: source_uuid
      )

      puts "---Fetched #{events.count} events"

      events.each do |event_data|
        begin
          source_uuid = event_data["measurementSourceId"]
          event_data["site_id"] = site_id
          event_data["measurement_apcode"] = measurement_apcode
          event_data["cp_name"] = cp_name
          ScadaEvent.persist_from_pf(event_data, source_uuid)
        rescue => e
          puts "---error: #{e.message}"
          Rails.logger.error "Failed to persist event: #{e.message}"
        end
      end
    end
  end
end

