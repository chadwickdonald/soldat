class SimulationImportJob < ApplicationJob
	def initialize(file)
		@file = file
	end

	def perform
		Importer.new(@file).import_simulations
	end
end