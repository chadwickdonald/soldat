class PagesController < ApplicationController
  allow_unauthenticated_access only: %i[about contact send_contact]

  def about
  end

  def contact
  end

  def send_contact
    # Placeholder: in production wire this to an ActionMailer
    name    = params[:name].to_s.strip
    email   = params[:email].to_s.strip
    message = params[:message].to_s.strip

    if name.blank? || email.blank? || message.blank?
      flash[:alert] = "Please fill in all fields."
    else
      flash[:notice] = "Thanks #{name}, we'll be in touch within 24 hours."
    end

    redirect_to contact_path
  end
end
