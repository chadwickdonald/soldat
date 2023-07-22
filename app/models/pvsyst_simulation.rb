class PvsystSimulation < ApplicationRecord
  belongs_to :project

  def self.import(file)
    puts "---file: #{file.inspect}"
    File.foreach(file.path).with_index do |line, index|
      puts "---index: #{index}, line: #{line}"
      if index == 21
        file_line = line.split(',')
        pvsyst = PvsystSimulation.new
        pvsyst.project_id = Project.first.id
        pvsyst.simulation_time = fix_date(file_line[0])
        pvsyst.glob_hor = file_line[1].to_f
        pvsyst.diff_hor = file_line[2].to_f
        pvsyst.beam_hor = file_line[3].to_f
        pvsyst.t_amb = file_line[4].to_f
        pvsyst.wind_vel = file_line[5].to_f
        pvsyst.glob_inc = file_line[6].to_f
        pvsyst.shd_loss = file_line[7].to_f
        pvsyst.iam_loss = file_line[8].to_f
        pvsyst.slg_loss = file_line[9].to_f
        pvsyst.glob_eff = file_line[10].to_f
        pvsyst.e_arr_nom = file_line[11].to_f
        pvsyst.g_inc_lss = file_line[12].to_f
        pvsyst.temp_lss = file_line[13].to_f
        pvsyst.mod_qual = file_line[14].to_f
        pvsyst.mis_loss = file_line[15].to_f
        pvsyst.ohm_loss = file_line[16].to_f
        pvsyst.e_arr_mpp = file_line[17].to_f
        pvsyst.e_array = file_line[18].to_f
        pvsyst.t_array = file_line[19].to_f
        pvsyst.il_oper = file_line[20].to_f
        pvsyst.il_pmin = file_line[21].to_f
        pvsyst.il_pmax = file_line[22].to_f
        pvsyst.il_vmin = file_line[23].to_f
        pvsyst.e_out_inv =file_line[24].to_f
        pvsyst.e_grid = file_line[25].to_f
        pvsyst.u_array = file_line[26].to_f
        pvsyst.save
      end
    end
  end

  def self.fix_date(date_str)
    date_1 = date_str.split(' ')
    date_2 = date_1.first.split('/')
    year = date_2[2]
    new_year = nil
    if year.length == 2
      if year.to_i <= 99
        new_year = '19' + year
      else
        new_year = '20' + year
      end
    end
    date_2[2] = new_year
    date_2 = date_2.join('/')
    date_1[0] = date_2
    date_1 = date_1.join(' ')
    date_1.to_datetime
  end

end
