module Api
  module V1
    class ScadaMeasurementsController < ApplicationController
      before_action :set_scada_mloc

      def index
        @scada_measurements = @scada_mloc.scada_measurements
        render json: @scada_measurements
      end

      def show
        @scada_measurement = @scada_mloc.scada_measurements.find(params[:id])
        render json: @scada_measurement
      end

      private

      def set_scada_mloc
        @scada_mloc = ScadaMloc.find(params[:scada_mloc_id])
      end
    end
  end
end