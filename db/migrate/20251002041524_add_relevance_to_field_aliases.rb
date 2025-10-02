class AddRelevanceToFieldAliases < ActiveRecord::Migration[7.1]
  def change
    add_column :field_aliases, :relevance, :integer,null: false, default: 1
  end
end
