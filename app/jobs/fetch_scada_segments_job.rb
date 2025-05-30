class FetchScadaSegmentsJob < ApplicationJob
  queue_as :default

  def perform()
    api_key = ENV['SCADA_API_KEY']
    Pf::SegmentDataService.new(api_key).fetch_all_segments
  end
end
