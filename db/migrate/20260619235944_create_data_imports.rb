class CreateDataImports < ActiveRecord::Migration[8.1]
  def change
    create_table :data_imports do |t|
      t.integer :user_id
      t.integer :status
      t.string :start_date
      t.string :end_date
      t.boolean :generate_csv
      t.integer :station_count
      t.integer :event_count
      t.integer :skipped_count
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :data_imports, :user_id
    add_index :data_imports, :status
  end
end
