class FetchScadaMlocsJob < ApplicationJob
  queue_as :default

  def perform
    api_key = ENV['SCADA_API_KEY']
    Pf::MlocDataService.new(api_key).fetch_all_mlocs
  end
end
