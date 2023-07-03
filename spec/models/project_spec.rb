# spec/models/project_spec.rb

# require 'spec_helper'
require 'project'

describe Project do
  it "is valid with valid attributes"
  it "is not valid without a project"
  it "is not valid without a pvsyst_version"
  it "is not valid without a geographical_site"
  it "is not valid without a meteo_data"
  it "is not valid without a satelite_data"
  it "is not valid without a simulation_date"
  it "is not valid without a simulation_variant"
  it "is not valid without a simulation_hourly_values"
end


# RSpec.describe Project, type: :model do
# 	subject { Project.new(project: 'Test_IEA_GA_Perry.PRJ', 
# 												pvsyst_version: 'v6.86',
# 												geographical_site: '32_36  -83_77_SA_Perry_GA_TMY.SIT',
# 												meteo_data: '32_36  -83_77_SA_Perry_GA_TMY.MET',
# 												satelite_data: 'SUNY model;TMY',
# 												simulation_variant: 'IEA_GA_Perry.VC9',
# 												simulation_date: '04/06/20 16h21',
# 												simulation_hourly_values:'from 01/01/90 to 31/12/90' ) }
# end