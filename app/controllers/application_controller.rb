class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  skip_before_action :verify_authenticity_token

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_user

  def current_user
    Current.session&.user
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform that action."
    redirect_back(fallback_location: root_path)
  end
end
