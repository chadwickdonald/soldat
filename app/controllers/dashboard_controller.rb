class DashboardController < ApplicationController
  def index
    if current_user.admin?
      render :admin
    else
      @current_site    = current_user.current_scada_site
      @current_org     = @current_site&.scada_organization
      @available_sites = current_user.available_scada_sites
                                     .includes(:scada_organization)
    end
  end
end
