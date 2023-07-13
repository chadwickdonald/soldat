class Project < ApplicationRecord
	has_many :pvsyst_simulations, dependent: :destroy
	validates :project, presence: true
	validates :pvsyst_version, presence: true
	validates :geographical_site, presence: true
	validates :meteo_data, presence: true
	validates :satelite_data, presence: true
	validates :simulation_date, presence: true
	validates :simulation_variant, presence: true
	validates :simulation_hourly_values, presence: true
end