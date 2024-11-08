module Api
  module V1
    class ScadaSitesController < ApplicationController
      include ExceptionHandler
      before_action :set_scada_organization

      def index
        @scada_sites = @scada_organization.scada_sites
        render json: @scada_sites
      end

      def show
        @scada_site = @scada_organization.scada_sites.find(params[:id])
        render json: @scada_site
      end

      private

      def set_scada_organization
        @scada_organization = ScadaOrganization.find(params[:scada_organization_id])
      end
    end
  end
end
