class CreatePvsysts < ActiveRecord::Migration[7.0]
  def change
    create_table :pvsysts do |t|
    	t.string :project
    	t.string :version
    	t.string :geographical_site
    	t.string :situation_latitude
    	t.string :situation_longitude
    	t.string :time_defined_as
    	t.string :time_zone
    	t.string :altitude
    	t.string :meteo_data
    	t.string :country
    	t.string :simulation_variant
    	t.datetime :simulation_date
    	# simlulation params
    	t.integer :axis_tilt
    	t.integer :axis_azimuth
    	t.integer :minimum_phi
    	t.integer :maximum_phi
    	t.string :tracking_algorithm
    	t.integer :number_of_trackers
    	t.float :tracker_spacing
    	t.float :collector_width
    	t.float :phi_limits
    	t.float :ground_cover_ratio
    	t.string :models_used
    	t.string :horizon
    	t.string :near_shadings
    	t.string :users_needs
    	t.float :grid_power_limitation_active_power
    	t.float :grid_power_limitation_pnom_ratio
    	t.float :power_factor_cos
    	t.float :power_factor_phi
    	# pv array characteristics
    	# pv module
    	t.string :pv_module
    	t.string :original_pysyst_db_manufacturer
    	t.integer :pv_modules_in_series
    	t.integer :pv_modules_in_parallel
    	t.integer :total_pv_modules
    	t.integer :module_unit_nom_power
    	t.integer :global_power_nominal
    	t.integer :global_power_operating_cond
    	t.integer :u_mpp
    	t.integer :i_mpp
    	t.integer :module_area
    	t.integer :cell_area
    	# inverter
    	t.string :inverter_model
    	t.string :custom_params_def_manufacturer
    	t.string :operating_voltage
    	t.integer :inverter_unit_nom_power
    	# pv array loss factors
    	t.float :avg_loss_fraction
    	t.float :array_soiling_losses_jan
    	t.float :array_soiling_losses_feb
    	t.float :array_soiling_losses_mar
    	t.float :array_soiling_losses_apr
    	t.float :array_soiling_losses_may
    	t.float :array_soiling_losses_jun
    	t.float :array_soiling_losses_jul
    	t.float :array_soiling_losses_aug
    	t.float :array_soiling_losses_sep
    	t.float :array_soiling_losses_oct
    	t.float :array_soiling_losses_nov
    	t.float :array_soiling_losses_dec
    	t.float :thermal_loss_factor_uc
    	t.float :thermal_loss_factor_uv
    	t.float :wiring_ohmic_loss_global_array_res
    	t.float :wiring_ohmic_loss_fraction
    	t.float :module_quality_loss_fraction
    	t.float :module_mismatch_loss_fraction
    	t.float :strings_mismatch_loss_fraction
    	t.float :incidence_effect_0
    	t.float :incidence_effect_30
    	t.float :incidence_effect_55
    	t.float :incidence_effect_60
    	t.float :incidence_effect_65
    	t.float :incidence_effect_70
    	t.float :incidence_effect_75
    	t.float :incidence_effect_80
    	t.float :incidence_effect_90
    	t.integer :grid_voltage
    	t.integer :wires
    	t.float :wires_loss_fraction
    	t.integer :iron_loss
    	t.float :iron_loss_fraction
    	t.float :inductive_loss
    	t.float :inductive_loss_fraction
    	t.float :aux_loss_constant
    	t.float :aux_loss_power_thresh
    	t.float :night_aux_consumption
    	# main system params
    	t.string :system_type
    	t.float :field_orientation_axis_tilt
    	t.float :field_orientation_axis_azimuth
    	t.string :pv_modules_model
    	t.string :pv_modules_pnom_total
    	t.integer :pv_array_number_modules
    	t.integer :pv_array_pnom_total
    	t.string :main_system_inverter_model
    	t.integer :main_system_pnom
    	t.float :main_system_inverter_pack
    	t.integer :main_system_pnom_total
    	t.float :user_needs_unlimited_load
    	t.float :user_needs_cos_phi

      t.timestamps
    end
  end
end
