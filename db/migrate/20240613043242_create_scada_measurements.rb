class CreateScadaMeasurements < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_measurements do |t|
      t.string :mloc_id
      t.string :apcode
      t.string :uuid
      t.string :name
      t.boolean :rcv
      t.string :measure_type_id
      t.string :measure_type_apcode
      t.string :measure_type_data_type
      t.string :measure_type_name
      t.string :measure_type_uri
      t.string :segment_id
      t.string :segment_apcode
      t.integer :segment_apcode_idx
      t.string :segment_name
      t.string :segment_uri
      t.string :monitor_eng_unit
      t.boolean :monitor
      t.string :monitor_status
      t.string :monitor_uri

      t.timestamps
    end

    add_index :scada_measurements, :uuid, unique: true
    add_index :scada_measurements, :measure_type_id
    add_index :scada_measurements, :segment_id
  end
end
