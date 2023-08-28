class PvsystSimulationsController < ApplicationController
  def index
    @project = Project.last
  end

  def new_import
  end

  def table_data
    simulations = Project.last.pvsyst_simulations
    render json: simulations
  end

  def import
    begin
      file = params[:file]
      # SimulationImportJob.new(file).perform
      Importer.new(file).import_simulations
      flash[:success] = "<strong>Pvsyst Simulation imported</strong>"
      redirect_to projects_path
    rescue => exception
      flash[:error] = "There was a problem importing Pvsyst Simulation file.<br>
        <strong>#{exception.message}</strong><br>"
      redirect_to root_path
    end
  end
end