class CreateScadaSites < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_sites do |t|
      t.string :uuid
      t.string :site_id
      t.integer :organization_id
      t.string :name
      t.string :site_type_apcode
      t.string :enterprise_name
      t.string :enterprise_id
      t.string :state
      t.string :timezone
      t.string :address
      t.string :longitude
      t.string :latitude
      t.string :test_results
      t.string :crmid
      t.string :type_of_project
      t.string :number_of_controllers
      t.string :ac_load
      t.string :cabins_designs
      t.string :rnoc_tests_end_date
      t.string :address_zip_code
      t.string :activation_date
      t.string :power_source_provision
      t.string :grid_connected
      t.string :plant_designer
      t.string :type_of_plant
      t.string :city
      t.string :cabin_group
      t.string :plant_operator
      t.string :installation_implementor
      t.string :maintenance_contractor
      t.string :country
      t.string :district
      t.string :maintenance_date
      t.string :contract
      t.string :telco_area
      t.string :odss_presence
      t.string :dslam_code
      t.string :odss_active
      t.string :related_market_site
      t.string :information
      t.string :recording_period
      t.string :number_of_active_equipment
      t.string :market_timezone
      t.string :admin_region
      t.string :tech_department
      t.string :cabin_vendor
      t.string :activation_date_nms
      t.string :plant_installer
      t.string :cabin_type
      t.string :cabin_kv_number
      t.string :portfolio
      t.string :warranty_expiration_date
      t.string :severity
      t.string :typical_use
      t.string :rnoc_notification_date
      t.string :num_of_tcps
      t.string :serial
      t.string :sub_types
      t.string :dslam_network_ip_address
      t.string :address_street
      t.string :eett_code
      t.string :available_calculation_periods
      t.string :altitude

      t.timestamps
    end
    add_index :scada_sites, :id
  end
end

