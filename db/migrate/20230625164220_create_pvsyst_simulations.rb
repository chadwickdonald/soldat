class CreatePvsystSimulations < ActiveRecord::Migration[7.0]
  def change
    create_table :pvsyst_simulations do |t|
    	t.integer :simulation_id, foreign_key: true
    	t.float :glob_hor
    	t.float :diff_hor
    	t.float :beam_hor
    	t.float :t_amb
    	t.float :wind_vel
    	t.float :glob_inc
    	t.float :shd_loss
    	t.float :iam_loss
    	t.float :slg_loss
    	t.float :glob_eff
    	t.float :e_arr_nom
    	t.float :g_inc_lss
    	t.float :temp_lss
    	t.float :mod_qual
    	t.float :mis_loss
    	t.float :ohm_loss
    	t.float :e_arr_mpp
    	t.float :e_array
    	t.float :t_array
    	t.float :il_oper
    	t.float :il_pmin
    	t.float :il_pmax
    	t.float :il_vmin
    	t.float :e_out_inv
    	t.float :e_grid
    	t.float :u_array
      t.timestamps
    end
  end
end
