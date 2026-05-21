# spec/models/project_spec.rb

require 'rails_helper'

describe Project do
  fixtures :projects

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
