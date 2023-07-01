class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.string :project, null: false
      t.string :pvsyst_version
      t.string :geographical_site
      t.string :meteo_data
      t.string :satelite_data
      t.string :simulation_variant
      t.datetime :simulation_date, null: false
      t.string :simulation_hourly_values
      t.timestamps
    end
  end
end
