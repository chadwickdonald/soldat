class CreateFieldAliases < ActiveRecord::Migration[7.0]
  def change
    create_table :field_aliases do |t|
      t.string :enthasys_id
      t.integer :scada_measurement_id
      t.string :measurement_type
      t.string :engineering_unit
      t.string :station_type
      t.string :station_id

      t.timestamps
    end
  end
end
