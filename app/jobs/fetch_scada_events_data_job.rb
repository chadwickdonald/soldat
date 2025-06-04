class FetchScadaEventsDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    api_key = ENV['SCADA_API_KEY']
    site_ids = ["25658d43-0ffd-42b4-a4e4-d3b808e85087"]
    start_date = Time.parse('2025-03-01T00:00:00Z').utc.strftime('%Y%m%dT%H%M%SZ')
    end_date = Time.parse('2025-03-02T00:00:00Z').utc.strftime('%Y%m%dT%H%M%SZ')
    apcodes = ["PPCActivePowerTr2"]
    Pf::EventDataService.new(api_key).fetch_and_persist_events(site_ids: site_ids, start_date: start_date, end_date: end_date, apcodes: apcodes)
  end
end
