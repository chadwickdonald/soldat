module Api
  module V1
    class ScadaMeasurementSourcesController < ApplicationController
      before_action :set_scada_measurement

      def index
        @scada_measurement_sources = @scada_measurement.scada_measurement_sources
        render json: @scada_measurement_sources
      end

      def show
        @scada_measurement_source = @scada_measurement.scada_measurement_sources.find(params[:id])
        render json: @scada_measurement_source
      end

      private

      def set_scada_measurement
        @scada_measurement = ScadaMeasurement.find(params[:scada_measurement_id])
      end
    end
  end
end