class AccountsController < ApplicationController
  def show
  end

  def update
    unless current_user.authenticate(params[:current_password])
      return redirect_to account_path, alert: "Current password is incorrect."
    end

    if params[:password] != params[:password_confirmation]
      return redirect_to account_path, alert: "New passwords do not match."
    end

    if params[:password].blank?
      return redirect_to account_path, alert: "New password cannot be blank."
    end

    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to account_path, notice: "Password updated successfully."
    else
      redirect_to account_path, alert: current_user.errors.full_messages.to_sentence
    end
  end
end
