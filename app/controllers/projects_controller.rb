class ProjectsController < ApplicationController
  def index
  end

  def table_data
    simulations = Project.last.pvsyst_simulations
    render json: simulations
  end
end
