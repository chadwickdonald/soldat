class CreateScadaMeasurementSources < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_measurement_sources do |t|
      t.integer :scada_measurement_id
      t.string :uuid
      t.string :calc_period
      t.integer :calc_time_span_count
      t.string :calc_time_span_mode
      t.boolean :manual_ingest
      t.string :eng_unit
      t.string :quality
      t.string :range
      t.string :uri
      t.string :calc_type_apcode
      t.datetime :date
      t.decimal :val

      t.timestamps
    end

    add_index :scada_measurement_sources, :scada_measurement_id
    add_index :scada_measurement_sources, :uuid, unique: true
  end
end
