class CreateApiClients < ActiveRecord::Migration[7.0]
  def change
    create_table :api_clients do |t|
      t.string :name
      t.string :api_key, null: false, unique: true

      t.timestamps
    end
  end
end
