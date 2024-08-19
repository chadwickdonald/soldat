class CreateScadaEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_events do |t|
      t.string :site_id
      t.datetime :date
      t.string :measurement_source_id
      t.float :val
      t.string :cp_name
      t.string :measurement_apcode

      t.timestamps
    end
  end
end