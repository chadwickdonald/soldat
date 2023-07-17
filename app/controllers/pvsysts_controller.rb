class PvsystsController < ApplicationController
	def index
		@projects = Project.all
	end
end
