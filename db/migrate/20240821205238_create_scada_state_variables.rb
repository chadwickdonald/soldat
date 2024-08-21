class CreateScadaStateVariables < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_state_variables do |t|
      t.string :uuid
      t.string :segment_id
      t.string :name
      t.string :uri
      t.string :apcode

      t.timestamps
    end
  end
end
