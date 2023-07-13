class ProjectsController < ApplicationController
	def index
		@projects = Project.all
		puts "---@projects: #{@projects.inspect}"
	end
end
