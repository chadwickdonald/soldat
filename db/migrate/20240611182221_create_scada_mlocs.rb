class CreateScadaMlocs < ActiveRecord::Migration[7.0]
  def change
    create_table :scada_mlocs do |t|
    	t.string :segment_id
    	t.string :apcode
    	t.string :uuid
    	t.string :name
    	t.string :sscode
    	t.string :uri
    	t.string :measurementTypeId
      t.timestamps
    end
  end
end
