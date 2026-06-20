class DataImportsController < ApplicationController
  before_action :require_admin

  def index
    @imports = DataImport.where(user: current_user).order(created_at: :desc)
  end

  def new
    @import = DataImport.new
  end

  def create
    @import = DataImport.new(import_params)
    @import.user = current_user

    if @import.save
      DataImportJob.perform_later(@import.id)
      redirect_to data_import_path(@import),
                  notice: "Import queued — this may take several minutes. This page will update automatically."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @import = DataImport.find(params[:id])
  end

  private

  def import_params
    params.require(:data_import).permit(:start_date, :end_date, :generate_csv, :input_json)
  end

  def require_admin
    redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
  end
end
