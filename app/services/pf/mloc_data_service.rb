# app/services/pf/mloc_data_service.rb
module Pf
  class MlocDataService < BaseApiService

    def fetch_mlocs(segment_id)
      get("/segments/#{segment_id}/mlocs")
    end

    def fetch_all_mlocs(site_name=nil)
      # if site_name
      #   site = ScadaSite.where(name: site_name).first
      #   segment_ids = site.scada_segments.pluck(:uuid)
      # else
      #   segment_ids = ScadaSegment.pluck(:uuid)
      # end

      site = ScadaSite.where(name: "Danish Fields - T3").first
      segment_ids = site.scada_segments.pluck(:uuid)

      segment_ids.each do |segment_id|
        begin
          mlocs = fetch_mlocs(segment_id)
          Rails.logger.info "Fetched #{mlocs.count} mlocs for segment #{segment_id}"

          mlocs.each do |mloc_data|
            if ScadaMloc.exists?(uuid: mloc_data['id'])
              Rails.logger.info "Skipping existing mloc #{mloc_data['id']}"
              next
            end

            begin
              ScadaMloc.persist_from_pf(mloc_data, segment_id)
              Rails.logger.info "Created mloc #{mloc_data['id']}"
            rescue => e
              Rails.logger.error "Failed to persist mloc #{mloc_data['id']}: #{e.message}"
            end
          end
        rescue => e
          Rails.logger.error "Failed to fetch mlocs for segment #{segment_id}: #{e.message}"
        end
      end
    end
  end
end
