class UserOrganizationsController < ApplicationController
  before_action :require_admin

  def new
    @user_organization = UserOrganization.new
    @users         = User.order(:email_address)
    @organizations = ScadaOrganization.order(:name)
  end

  def create
    @user_organization = UserOrganization.new(user_organization_params)

    if @user_organization.save
      user = @user_organization.user
      org  = @user_organization.scada_organization
      redirect_to dashboard_path, notice: "#{user.email_address} was associated with #{org.name}."
    else
      @users         = User.order(:email_address)
      @organizations = ScadaOrganization.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin
    redirect_to dashboard_path, alert: "Not authorized." unless current_user.admin?
  end

  def user_organization_params
    params.require(:user_organization).permit(:user_id, :scada_organization_id)
  end
end
