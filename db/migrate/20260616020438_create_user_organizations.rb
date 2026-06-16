class CreateUserOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :user_organizations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scada_organization, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_organizations, %i[user_id scada_organization_id], unique: true
  end
end
