class PvsystSimulation < ApplicationRecord
	belongs_to :project

	def self.import(file)
		puts "---PvsystSimulation.import"
		puts "---file: #{file.inspect}"
		File.foreach(file.path).with_index do |line, index|
			puts "---index: #{index}, line: #{line}"
			if index == 21
				file_line = line.split(',')
				puts "---file_line: #{file_line.inspect}"
				pvsyst = PvsystSimulation.new
				pvsyst.project_id = Project.first.id,
				pvsyst.simulation_time = Time.now
				pvsyst.glob_hor = file_line[1]
				pvsyst.diff_hor = file_line[2]
				pvsyst.beam_hor = file_line[3]
				pvsyst.t_amb = file_line[4]
				pvsyst.wind_vel = file_line[5]
				pvsyst.glob_inc = file_line[6]
				pvsyst.shd_loss = file_line[7]
				pvsyst.iam_loss = file_line[8]
				pvsyst.slg_loss = file_line[9]
				pvsyst.glob_eff = file_line[10]
				pvsyst.e_arr_nom = file_line[11]
				pvsyst.g_inc_lss = file_line[12]
				pvsyst.temp_lss = file_line[13]
				pvsyst.mod_qual = file_line[14]
				pvsyst.mis_loss = file_line[15]
				pvsyst.ohm_loss = file_line[16]
				pvsyst.e_arr_mpp = file_line[17]
				pvsyst.e_array = file_line[18]
				pvsyst.t_array = file_line[19]
				pvsyst.il_oper = file_line[20]
				pvsyst.il_pmin = file_line[21]
				pvsyst.il_pmax = file_line[22]
				pvsyst.il_vmin = file_line[23]
				pvsyst.e_out_inv =file_line[24]
				pvsyst.e_grid = file_line[25]
				pvsyst.u_array = file_line[26]
				pvsyst.save
				puts "--pvsyst: #{pvsyst.inspect}"
			end
		end
	end
end
