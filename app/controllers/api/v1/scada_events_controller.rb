module Api
  module V1
    class ScadaEventsController < ApplicationController
      include ExceptionHandler

      def index
        raw_data = request.headers['RAW_POST_DATA']
        @parsed_data = JSON.parse(raw_data) if raw_data.present?

        if
          @parsed_data['scada_organization_uuid'] ||
          @parsed_data['scada_site_uuid'] ||
          @parsed_data['scada_segment_uuid'] ||
          @parsed_data['scada_mloc_uuid'] ||
          @parsed_data['scada_measurement_uuid'] ||
          @parsed_data['scada_measurement_source_uuid'] ||
          @parsed_data['start_time'] ||
          @parsed_data['end_time']

          filtered_index
        else
          error = "No Results"
          render json: error
        end
      end

      def show
        @scada_event = @scada_measurement_source.scaca_events.find(params[:id])
        render json: @scada_events
      end

      private

      def filtered_index
        scada_organization_uuid =       @parsed_data['scada_organization_uuid']
        scada_site_uuid =               @parsed_data['scada_site_uuid']
        scada_segment_uuid =            @parsed_data['scada_segment_uuid']
        scada_mloc_uuid =               @parsed_data['scada_mloc_uuid']
        scada_measurement_uuid =        @parsed_data['scada_measurement_uuid']
        scada_measurement_source_uuid = @parsed_data['scada_measurement_source_uuid']
        start_time =                    @parsed_data['start_time'].present? ? Time.parse(@parsed_data['start_time']) : Time.current.beginning_of_day
        end_time =                      @parsed_data['end_time'].present? ? Time.parse(@parsed_data['end_time']) : Time.current.end_of_day

        organization = ScadaOrganization.find_by_uuid(scada_organization_uuid)
        site = organization.scada_sites.find_by_uuid(scada_site_uuid)
        segment = site.scada_segments.find_by_uuid(scada_segment_uuid)
        mloc = segment.scada_mlocs.find_by_uuid(scada_mloc_uuid)
        measurement = mloc.scada_measurements.find_by_uuid(scada_measurement_uuid)
        measurement_source = measurement.scada_measurement_sources.find_by_uuid(scada_measurement_source_uuid)
        events = measurement_source.scada_events.where('date >= ?', start_time)
                                    .where('date <= ?', end_time)

        render json: events
      end

    end
  end
end
