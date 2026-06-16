class DashboardController < ApplicationController
  def index
    if current_user.admin?
      render :admin
    end
  end
end
