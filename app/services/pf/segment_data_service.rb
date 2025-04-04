# app/services/pf/segment_data_service.rb
module Pf
  class SegmentDataService < BaseApiService

    def fetch_segments(site_id)
      get("/sites/#{site_id}/segments?recursive=true")
    end

    def fetch_all_segments
      site_ids = ScadaSite.pluck(:uuid)

      site_ids.each do |site_id|
        begin
          segments = fetch_segments(site_id)
          Rails.logger.info "Fetched #{segments.count} segments for site #{site_id}"

          segments.each do |segment_data|
            if ScadaSegment.exists?(uuid: segment_data['id'])
              Rails.logger.info "Skipping existing segment #{segment_data['id']}"
              next
            end

            begin
              ScadaSegment.persist_from_pf(segment_data, site_id)
              Rails.logger.info "Created segment #{segment_data['id']}"
            rescue => e
              Rails.logger.error "Failed to persist segment #{segment_data['id']}: #{e.message}"
            end
          end
        rescue => e
          Rails.logger.error "Failed to fetch segments for site #{site_id}: #{e.message}"
        end
      end
    end
  end
end