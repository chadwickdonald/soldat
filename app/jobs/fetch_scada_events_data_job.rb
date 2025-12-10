class FetchScadaEventsDataJob < ApplicationJob
  queue_as :default

  # using MeasurementLocation apcodes

  # Expected args:
  # site_ids:   Array[String]
  # start_date: Time | String
  # end_date:   Time | String
  # apcodes:    Array[String]
  def perform(site_ids:, start_date:, end_date:, apcodes:)
    api_key = ENV.fetch('SCADA_API_KEY')

    start_date = normalize_time(start_date)
    end_date   = normalize_time(end_date)

    Pf::EventDataService
      .new(api_key)
      .fetch_and_persist_events(
        site_ids: site_ids,
        start_date: start_date,
        end_date: end_date,
        apcodes: apcodes
      )
  end

  private

  def normalize_time(value)
    case value
    when Time
      value.utc.strftime('%Y%m%dT%H%M%SZ')
    when String
      Time.parse(value).utc.strftime('%Y%m%dT%H%M%SZ')
    else
      raise ArgumentError, "Invalid time value: #{value.inspect}"
    end
  end
end




# FetchScadaEventsDataJob.perform_later(
#   site_ids: ["25658d43-0ffd-42b4-a4e4-d3b808e85087"],
#   start_date: "2025-03-01T00:00:00Z",
#   end_date:   "2025-03-02T00:00:00Z",
#   apcodes: ScadaMloc.distinct.pluck(:apcode)
# )





# class FetchScadaEventsDataJob < ApplicationJob
#   queue_as :default

#   def perform(*args)
#     api_key = ENV['SCADA_API_KEY']
#     site_ids = ["25658d43-0ffd-42b4-a4e4-d3b808e85087"]
#     start_date = Time.parse('2025-03-01T00:00:00Z').utc.strftime('%Y%m%dT%H%M%SZ')
#     end_date = Time.parse('2025-03-02T00:00:00Z').utc.strftime('%Y%m%dT%H%M%SZ')
#     apcodes = ["PPCActivePowerTr2"]
#     Pf::EventDataService.new(api_key).fetch_and_persist_events(site_ids: site_ids, start_date: start_date, end_date: end_date, apcodes: apcodes)
#   end
# end
