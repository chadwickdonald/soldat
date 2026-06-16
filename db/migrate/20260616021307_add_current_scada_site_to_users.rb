class AddCurrentScadaSiteToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :current_scada_site_id, :integer
  end
end
