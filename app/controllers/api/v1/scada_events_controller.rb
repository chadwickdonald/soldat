module Api
  module V1
    class ScadaEventsController < ApplicationController
      before_action :set_scada_measurement_source

      def index
        @scada_events = @scada_measurement_source.scada_events
        render json: @scada_events
      end

      def show
        @scada_event = @scada_measurement_source.scaca_events.find(params[:id])
        render json: @scada_events
      end

      private

      def set_scada_measurement_source
        @scada_measurement_source = ScadaMeasurementSource.find(params[:scada_measurement_source_id])
      end
    end
  end
end