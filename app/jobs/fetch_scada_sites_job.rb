# app/jobs/fetch_scada_sites_job.rb
class FetchScadaSitesJob < ApplicationJob
  queue_as :default

  def perform
    api_key = ENV['SCADA_API_KEY']
    Pf::SiteDataService.new(api_key).fetch_and_persist_sites
  end
end
