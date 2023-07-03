require 'rails_helper'

Rspec.describe Project, type: :model do
	subject { Project.new(project: 'Test_IEA_GA_Perry.PRJ', 
												pvsyst_version: 'v6.86',
												geographical_site: '32_36  -83_77_SA_Perry_GA_TMY.SIT',
												meteo_data: '32_36  -83_77_SA_Perry_GA_TMY.MET',
												satelite_data: 'SUNY model;TMY',
												simulation_variant: 'IEA_GA_Perry.VC9',
												simulation_date: '04/06/20 16h21',
												simulation_hourly_values:'from 01/01/90 to 31/12/90' ) }

	before subject.save

	it 'project should be present' do
		subject.project = nil
		expect(subject).to_not be_valid
	end
end