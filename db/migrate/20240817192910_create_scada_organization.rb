class CreateScadaOrganization < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_organizations do |t|
      t.string :uuid
      t.string :name
      t.string :address
      t.string :city
      t.string :state

      t.timestamps
    end
  end
end
