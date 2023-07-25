# db/migrate/20230626173058_create_projects.rb #

class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :project, null: false
      t.datetime :project_file_date
      t.string :project_description
      t.string :pvsyst_version
      t.string :geographical_site
      t.datetime :geographical_site_file_date
      t.string :geographical_site_description
      t.string :meteo_data
      t.datetime :meteo_data_file_date
      t.string :meteo_data_description
      t.string :satelite_data
      t.string :simulation_variant
      t.datetime :simulation_variant_file_date
      t.string :simulation_variant_description
      t.datetime :simulation_date, null: false
      t.string :simulation_hourly_values_from
      t.string :simulation_hourly_values_to
      t.timestamps
    end
  end
end
