# spec/models/project_spec.rb

require 'spec_helper'

describe Project do
	fixtures :projects

	before(:context) do
		project = projects(:default)
	end

  it "is valid with valid attributes"
  it "is not valid without a project" do
  	# project = projects(:default)
  	puts "---project: #{project.inspect}"
  	# expect(project.project).to be_valid
  	# it { is_expected.to validate_presence_of :project }
  end

  it "is not valid without a pvsyst_version"
  it "is not valid without a geographical_site"
  it "is not valid without a meteo_data"
  it "is not valid without a satelite_data"
  it "is not valid without a simulation_date"
  it "is not valid without a simulation_variant"
  it "is not valid without a simulation_hourly_values"
end