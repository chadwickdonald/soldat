class ScadaSiteSelectionsController < ApplicationController
  def update
    site = current_user.available_scada_sites.find_by(id: params[:current_scada_site_id])

    if site
      current_user.update!(current_scada_site: site)
      redirect_to dashboard_path, notice: "Switched to #{site.scada_organization.name} → #{site.name}."
    else
      redirect_to dashboard_path, alert: "Site not found or not accessible."
    end
  end
end
