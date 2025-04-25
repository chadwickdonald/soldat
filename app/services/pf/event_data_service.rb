module Pf
  class EventDataService < BaseApiService

    def fetch_events(site_ids:, start_date:, end_date:, apcodes:)
      payload = {
        siteIds: site_ids,
        startDate: start_date,
        endDate: end_date,
        measurementLocationApcodes: apcodes
      }

      post("/sites/sources/events", payload)
    end

    def fetch_and_persist_events(site_ids:, start_date:, end_date:, apcodes:)
      # puts "---fetching events for #{site_ids.count} site(s) between #{start_date} and #{end_date}"

      events = fetch_events(
        site_ids: site_ids,
        start_date: start_date,
        end_date: end_date,
        apcodes: apcodes
      )

      Rails.logger.info "Fetched #{events.count} events"

      events.each do |event_data|
        begin
          source_id = event_data["measurementSourceId"]
          ScadaEvent.persist_from_pf(event_data, source_id)
        rescue => e
          Rails.logger.error "Failed to persist event: #{e.message}"
        end
      end
    end
  end
end

