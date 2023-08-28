class ProjectsController < ApplicationController
  def index
  end

  def table_data
    projects = Project.all
    render json: projects
  end
end
