module Api
  module V1
    class ScadaOrganizationsController < ApplicationController
      include ExceptionHandler
      
      def index
        @scada_organizations = ScadaOrganization.all
        render json: @scada_organizations
      end

      def show
        @scada_organization = ScadaOrganization.find(params[:id])
        render json: @scada_organization
      end
    end
  end
end
