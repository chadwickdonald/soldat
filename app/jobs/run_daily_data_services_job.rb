class RunDailyDataServicesJob < ApplicationJob
  queue_as :default

  def perform(date = Date.yesterday, apcodes = nil, site_ids = nil)
    start_time = date.beginning_of_day.utc.strftime('%Y%m%dT000000Z')
    end_time   = date.end_of_day.utc.strftime('%Y%m%dT235959Z')
    api_key    = ENV['SCADA_API_KEY']

    puts "--- Running daily data services for #{date}"

    Pf::SiteDataService.new(api_key).fetch_and_persist_sites
    Pf::SegmentDataService.new(api_key).fetch_all_segments
    Pf::MlocDataService.new(api_key).fetch_all_mlocs
    Pf::MeasurementDataService.new(api_key).fetch_all_measurements

    site_ids = site_ids || ScadaSite.pluck(:uuid)

    Pf::EventDataService.new(ENV['SCADA_API_KEY']).fetch_and_persist_events(
      site_ids: site_ids,
      start_date: start_time,
      end_date: end_time,
      apcodes: apcodes
    )
  end
end



    # apcodes = ["PPCActivePowerTr2", "ArrayOutputPower"]
