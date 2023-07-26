class SimulationImportJob < ApplicationJob
	def initialize(file)
		@file = file
	end

	def perform
		Importer.import_simulations(@file)
	end
end