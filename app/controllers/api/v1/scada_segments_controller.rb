module Api
  module V1
    class ScadaSegmentsController < ApplicationController
      before_action :set_scada_site

      def index
        @scada_segments = @scada_site.scada_segments
        render json: @scada_segments
      end

      def show
        @scada_segment = @scada_site.scada_segments.find(params[:id])
        render json: @scada_segment
      end

      private

      def set_scada_site
        @scada_site = ScadaSite.find(params[:scada_site_id])
      end
    end
  end
end