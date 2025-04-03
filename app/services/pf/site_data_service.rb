# app/services/pf/site_data_service.rb
module Pf
  class SiteDataService < BaseApiService

    def fetch_sites
      get("/agents/#{AGENT_ID}/sites")
    end

    def fetch_and_persist_sites
      fetch_sites.each do |site_data|
        uuid = site_data['id']
        if ScadaSite.exists?(uuid: uuid)
          Rails.logger.info "Skipping existing site #{uuid}"
          next
        end

        begin
          ScadaSite.persist_from_pf(site_data)
          Rails.logger.info "Created site #{uuid}"
        rescue => e
          Rails.logger.error "Failed to persist site #{uuid}: #{e.message}"
        end
      end
    end
  end
end
