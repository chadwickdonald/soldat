class CreateScadaSegments < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_segments do |t|
      t.string :site_id
      t.string :uuid
      t.string :apcode
      t.string :uri
      t.string :name
      t.integer :apcode_idx

      t.timestamps
    end
    add_index :scada_segments, :id
  end
end
