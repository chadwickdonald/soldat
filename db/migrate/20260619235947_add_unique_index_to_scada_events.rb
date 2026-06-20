class AddUniqueIndexToScadaEvents < ActiveRecord::Migration[8.1]
  def change
    add_index :scada_events, [:measurement_source_id, :date], unique: true,
              name: "index_scada_events_on_source_and_date"
  end
end
