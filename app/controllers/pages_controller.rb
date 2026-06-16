class PagesController < ApplicationController
  allow_unauthenticated_access only: :contact

  def contact
  end
end
