module Api
  module V1
    class ScadaMlocsController < ApplicationController
      before_action :set_scada_segment

      def index
        @scada_mlocs = @scada_segment.scada_mlocs
        render json: @scada_mlocs
      end

      def show
        @scada_mloc = @scada_segment.scada_mlocs.find(params[:id])
        render json: @scada_mloc
      end

      private

      def set_scada_segment
        @scada_segment = ScadaSegment.find(params[:scada_segment_id])
      end
    end
  end
end