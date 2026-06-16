class ScadaSitesController < ApplicationController
  before_action :require_admin

  def new
    @scada_site = ScadaSite.new
    @organizations = ScadaOrganization.order(:name)
  end

  def create
    @scada_site = ScadaSite.new(scada_site_params)
    @scada_site.uuid ||= SecureRandom.uuid
    @scada_site.site_id = @scada_site.uuid

    if @scada_site.save
      redirect_to dashboard_path, notice: "SCADA site \"#{@scada_site.name}\" was created."
    else
      @organizations = ScadaOrganization.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to dashboard_path, alert: "Not authorized." unless current_user.admin?
  end

  def scada_site_params
    params.require(:scada_site).permit(
      :name, :organization_id, :uuid, :state, :country,
      :city, :address, :latitude, :longitude, :timezone
    )
  end
end
