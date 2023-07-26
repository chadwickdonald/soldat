class PvsystSimulationsController < ApplicationController
  def index
    @projects = Project.all
    @pvsyst_simulations = @projects.first.pvsyst_simulations
  end

  def new_import
  end

  def import
    begin
      file = params[:file]
      SimulationImportJob.new(file).perform
      flash[:success] = "<strong>Pvsyst Simulation imported</strong>"
      redirect_to projects_path
    rescue => exception
      flash[:error] = "There was a problem importing Pvsyst Simulation file.<br>
        <strong>#{exception.message}</strong><br>"
      redirect_to root_path
    end
  end
end