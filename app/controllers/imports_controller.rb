class ImportsController < ApplicationController
  def index
  end

  def destroy
    Project.destroy_all
  end
end
