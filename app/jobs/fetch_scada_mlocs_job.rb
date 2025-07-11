class FetchScadaMlocsJob < ApplicationJob
  queue_as :default

  def perform(site_name=nil)
    api_key = ENV['SCADA_API_KEY']
    Pf::MlocDataService.new(api_key).fetch_all_mlocs(site_name)
  end
end
