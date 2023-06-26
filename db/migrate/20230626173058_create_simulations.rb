class CreateSimulations < ActiveRecord::Migration[7.0]
  def change
    create_table :simulations do |t|
    	t.sting :project
    	t.strin :pvsyst_version
    	t.string :geographical_site
    	t.string :meteo_data
    	t.string :satelite_data
    	t.string :simulation_variant
    	t.datetime :simulation_date
    	t.string :simulation_hourly_values
    	t.datetime :simulation_time
      t.timestamps
    end
  end
end
