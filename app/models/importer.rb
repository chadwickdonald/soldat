class Importer
  require 'pdf-reader'

  def self.import_simulations(file)
    puts "---file: #{file.inspect}"
    project = Project.new
    File.foreach(file.path).with_index do |line, index|
      puts "---index: #{index}, line: #{line}"
      begin
        file_line = line.split(',')
      rescue => exception
        puts "---exception: #{exception.inspect}"
      end
      if index < 10
        if file_line[0][0..5] == 'PVSYST'
          project.pvsyst_version = file_line[0][7..].strip
        elsif file_line[0] == 'Project'
          project.project = file_line[1].strip
          project.project_file_date = fix_date(file_line[2])
          project.project_description = file_line[3].strip
        elsif file_line[0] == 'Geographical Site'
          project.geographical_site = file_line[1].strip
          project.geographical_site_file_date = fix_date(file_line[2])
          project.geographical_site_description = file_line[3].strip
        elsif file_line[0] == 'Meteo data'
          project.meteo_data = file_line[1].strip
          project.meteo_data_file_date = fix_date(file_line[2])
          project.meteo_data_description = file_line[3].strip
          project.satelite_data = file_line[5].strip
        elsif file_line[0] == 'Simulation variant'
          project.simulation_variant = file_line[1].strip
          project.simulation_variant_file_date = fix_date(file_line[2])
          project.simulation_variant_description = file_line[3].strip
        elsif file_line[0] == 'Simulation date'
          project.simulation_date = fix_date(file_line[2])
        elsif file_line[0] == 'Simulation:'
          project.simulation_hourly_values_from = file_line[2].strip
          project.simulation_hourly_values_to = file_line[3].strip
          begin
            project.save!
          rescue => exception
            puts "---exception: #{exception.inspect}"
          end
        end
      end
      # if index > 13
      if [21, 22, 23].include?(index)
      # if index == 21
        pvsyst = PvsystSimulation.new
        pvsyst.project_id = project.id
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
        begin
          pvsyst.save!
        rescue => exception
          puts "---exception: #{exception.inspect}"
        end
      end
    end
  end

  def self.import_pvsysts(file)
    puts "--import_pvsysts---file: #{file.inspect}"
    pvsyst = Pvsyst.new
    reader = PDF::Reader.new(Rails.root.join(file))
    project_name = reader.pages.first.text.split(' ')[16]
    # project_date = project.project_file_date.strftime("%D")
    project = Project.where(project_description: project_name).last
    return nil if project.nil?
    pvsyst.project_id = project.id
    reader.pages.each_with_index do |page, index|
      break unless index == 0 || index == 1 || index == 2
      page_text = page.text.split(' ')
      puts page_text.inspect
      page_number = page.number
      if page_number == 1
        page_text.each_with_index do |word, i|
          word2 = "#{word} #{page_text[i+1]}"
          word3 = "#{word2} #{page_text[i+2]}"
          begin
            if word == 'Situation'
              if page_text[i+1] == 'Latitude'
                pvsyst.situation_latitude = page_text[i+2] + ' ' + page_text[i+3]
              end
              if page_text[i+4] == 'Longitude'
                pvsyst.situation_longitude = page_text[i+5] + ' ' + page_text[i+6]
              end
            elsif "#{word2} #{page_text[i+2]}" == 'Time defined as'
              pvsyst.time_defined_as = page_text[i+3] + ' ' + page_text[i+4]
            elsif word2 == 'Time zone'
              pvsyst.time_zone = page_text[i+2]
            elsif word == 'Altitude'
              pvsyst.altitude = page_text[i+1]
            elsif word == 'Country'
              pvsyst.country = "#{page_text[i+1]} #{page_text[i+2]}"
            elsif word2 == 'Axis Tilt'
              pvsyst.axis_tilt = page_text[i+2]
            elsif word2 == 'Axis Azimuth'
              pvsyst.axis_azimuth = page_text[i+2]
            elsif word2 == 'Minimum Phi'
              pvsyst.minimum_phi = page_text[i+2]
            elsif word2 == 'Maximum Phi'
              pvsyst.maximum_phi = page_text[i+2]
            elsif word2 == 'Tracking algorithm'
              pvsyst.tracking_algorithm = "#{page_text[i+2]} #{page_text[i+3]}"
            elsif "#{word2} #{page_text[i+2]}" == 'Nb. of trackers'
              pvsyst.number_of_trackers = page_text[i+3]
            elsif word2 == 'Tracker Spacing'
              pvsyst.tracker_spacing = page_text[i+2]
            elsif word2 == 'Collector width'
              pvsyst.collector_width = page_text[i+2]
            elsif word2 == 'Phi limits'
              pvsyst.phi_limits = page_text[i+3]
            elsif "#{word2} #{page_text[i+2]} #{page_text[i+3]}" == 'Ground cov. Ratio (GCR)'
              pvsyst.ground_cover_ratio = "#{page_text[i+4]}#{page_text[i+5]}"
            elsif word2 == 'Models used'
              pvsyst.models_used = page_text[i+2] + ' ' + page_text[i+3]
            elsif word == 'Horizon' && page_text[i+3] == 'Near'
              pvsyst.horizon = page_text[i+1] + ' ' + page_text[i+2]
              next
            elsif word2 == 'Near Shadings'
              pvsyst.near_shadings = page_text[i+2] + ' ' + page_text[i+3]
            elsif "#{word2} #{page_text[i+2]}" == "User's needs :"
              pvsyst.users_needs = page_text[i+3]
            elsif word2 == 'Active Power'
              pvsyst.grid_power_limitation_active_power = page_text[i+2]
            elsif word2 == 'Pnom ratio'
              pvsyst.grid_power_limitation_pnom_ratio = page_text[i+2]
            elsif word2 == 'Power factor'
              if page_text[i+2] == 'Cos(phi)'
                pvsyst.power_factor_cos = page_text[i+3]
              end
              if page_text[i+5] == 'Phi'
                pvsyst.power_factor_phi = page_text[i+6]
              end
            elsif word2 == 'PV module'
              pvsyst.pv_module = page_text[i+4]
            elsif "#{word2} #{page_text[i+2]} #{page_text[i+3]}" == 'Original PVsyst database Manufacturer'
              pvsyst. original_pysyst_db_manufacturer = "#{page_text[i+4]} #{page_text[i+5]}"
            elsif "#{word2} #{page_text[i+2]} #{page_text[i+3]}" == 'Number of PV modules'
              if page_text[i+5] == 'series'
                pvsyst.pv_modules_in_series = page_text[i+6]
              end
              if page_text[i+9] == 'parallel'
                pvsyst.pv_modules_in_parallel = page_text[i+10]
              end
            elsif "#{word2} #{page_text[i+2]} #{page_text[i+3]} #{page_text[i+4]}" == 'Total number of PV modules'
              if "#{page_text[i+5]} #{page_text[i+6]}" == 'Nb. modules'
                pvsyst.total_pv_modules = page_text[i+7]
              end
              if "#{page_text[i+8]} #{page_text[i+9]} #{page_text[i+10]}" == 'Unit Nom. Power'
                pvsyst.module_unit_nom_power = page_text[i+11]
              end
            elsif "#{word2} #{page_text[i+2]}" == 'Array global power'
              if "#{page_text[i+3]} #{page_text[i+4]}" == 'Nominal (STC)'
                pvsyst.global_power_nominal = page_text[i+5]
              end
              if "#{page_text[i+7]} #{page_text[i+8]} #{page_text[i+9]}" == 'At operating cond.'
                pvsyst.global_power_operating_cond = page_text[i+10]
              end
            elsif word3 == 'Array operating characteristics'
              if "#{page_text[i+4]} #{page_text[i+5]}" == 'U mpp'
                pvsyst.u_mpp = page_text[i+6]
              end
              if "#{page_text[i+8]} #{page_text[i+9]}" == 'I mpp'
                pvsyst.i_mpp = page_text[i+10]
              end
            elsif word2 == 'Total area'
              if "#{page_text[i+2]} #{page_text[i+3]}" == 'Module area'
                pvsyst.module_area = page_text[i+4]
              end
              if "#{page_text[i+6]} #{page_text[i+7]}" == 'Cell area'
                pvsyst.cell_area = page_text[i+8]
              end
            elsif word2 == 'Inverter Model'
              pvsyst.inverter_model = "#{page_text[i+2]} #{page_text[i+3]} #{page_text[i+4]} #{page_text[i+5]}"
            elsif word3 == 'Custom parameters definition'
              pvsyst.custom_params_def_manufacturer = page_text[i+4]
            elsif word == 'Characteristics'
              if "#{page_text[i+1]} #{page_text[i+2]}" == 'Operating Voltage'
                pvsyst.operating_voltage = page_text[i+3]
              end
              if "#{page_text[i+5]} #{page_text[i+6]} #{page_text[i+7]}" == 'Unit Nom. Power'
                pvsyst.inverter_unit_nom_power = page_text[i+8]
              end
            elsif "#{page_text[i+3]} #{page_text[i+4]} #{page_text[i+5]}" == 'Average loss Fraction'
              pvsyst.avg_loss_fraction = page_text[i+6]
            elsif word3 == 'Thermal Loss factor'
              if "#{page_text[i+3]} #{page_text[i+4]}" == 'Uc (const)'
                pvsyst.thermal_loss_factor_uc = page_text[i+5]
              end
              if "#{page_text[i+7]} #{page_text[i+8]}" == 'Uv (wind)'
                pvsyst.thermal_loss_factor_uv = page_text[i+9]
              end
            elsif word3 == 'Wiring Ohmic Loss'
              if "#{page_text[i+3]} #{page_text[i+4]} #{page_text[i+5]}" == 'Global array res.'
                pvsyst.wiring_ohmic_loss_global_array_res = page_text[i+6]
              end
              if "#{page_text[i+8]} #{page_text[i+9]}" == 'Loss Fraction'
                pvsyst.wiring_ohmic_loss_fraction = page_text[i+10]
              end
            elsif word3 == 'Module Quality Loss'
              pvsyst.module_quality_loss_fraction = page_text[i+5]
            elsif word3 == 'Module Mismatch Losses'
              pvsyst.module_mismatch_loss_fraction = page_text[i+5]
            elsif word3 == 'Strings Mismatch loss'
              pvsyst.strings_mismatch_loss_fraction = page_text[i+5]
            end

            soiling_losses = page.runs[145..156].map(&:to_s)
            pvsyst.array_soiling_losses_jan = soiling_losses[0]
            pvsyst.array_soiling_losses_feb = soiling_losses[1]
            pvsyst.array_soiling_losses_mar = soiling_losses[2]
            pvsyst.array_soiling_losses_apr = soiling_losses[3]
            pvsyst.array_soiling_losses_may = soiling_losses[4]
            pvsyst.array_soiling_losses_jun = soiling_losses[5]
            pvsyst.array_soiling_losses_jul = soiling_losses[6]
            pvsyst.array_soiling_losses_aug = soiling_losses[7]
            pvsyst.array_soiling_losses_sep = soiling_losses[8]
            pvsyst.array_soiling_losses_oct = soiling_losses[9]
            pvsyst.array_soiling_losses_nov = soiling_losses[10]
            pvsyst.array_soiling_losses_dec = soiling_losses[11]

          rescue => exception
            puts "---exception: #{exception.inspect}"
          end
        end
      elsif page_number == 2
        begin
          page_runs = page.runs[15..23].map(&:to_s)
          pvsyst.incidence_effect_0  = page_runs[0]
          pvsyst.incidence_effect_30 = page_runs[1]
          pvsyst.incidence_effect_55 = page_runs[2]
          pvsyst.incidence_effect_60 = page_runs[3]
          pvsyst.incidence_effect_65 = page_runs[4]
          pvsyst.incidence_effect_70 = page_runs[5]
          pvsyst.incidence_effect_75 = page_runs[6]
          pvsyst.incidence_effect_80 = page_runs[7]
          pvsyst.incidence_effect_90 = page_runs[8]
          pvsyst.grid_voltage = page.runs[27].to_s
          pvsyst.wires = page.runs[29].to_s
          pvsyst.wires_loss_fraction = page.runs[31].to_s
          pvsyst.iron_loss = page.runs[34].to_s
          pvsyst.iron_loss_fraction = page.runs[36].to_s
          pvsyst.inductive_loss = page.runs[38].to_s
          pvsyst.inductive_loss_fraction = page.runs[40].to_s
          pvsyst.aux_loss_constant = page.runs[43].to_s
          pvsyst.aux_loss_power_thresh = page.runs[45].to_s
          pvsyst.night_aux_consumption = page.runs[47].to_s
        rescue => exception
          puts "---exception: #{exception.inspect}"
        end
      elsif page_number == 3
        begin
          pvsyst.system_type = page.runs[11].to_s
          pvsyst.field_orientation_axis_tilt = page.runs[16].to_s
          pvsyst.field_orientation_axis_azimuth = page.runs[18].to_s
          pvsyst.pv_modules_model = page.runs[21].to_s
          pvsyst.pv_modules_pnom_total = page.runs[23].to_s
          pvsyst.pv_array_number_modules = page.runs[26].to_s
          pvsyst.pv_array_pnom_total = page.runs[28].to_s
          pvsyst.main_system_inverter_model = page.runs[31].to_s
          pvsyst.main_system_pnom = page.runs[33].to_s
          pvsyst.main_system_inverter_pack = page.runs[36].to_s
          pvsyst.main_system_pnom_total = page.runs[38].to_s
          pvsyst.user_needs_unlimited_load = page.runs[40].to_s
          pvsyst.user_needs_cos_phi = page.runs[42].to_s
        rescue => exception
          puts "---exception: #{excption.inspect}"
        end
      end
    end
    # begin
    #   # pvsyst.save!
    # rescue => exception
    #   puts "---exception: #{exception.inspect}"
    # end
    puts "---pvsyst: #{pvsyst.inspect}"
  end

  def self.fix_date(date_str)
    date_1 = date_str.split(' ')
    date_2 = date_1.first.split('/')
    year = date_2[2]
    new_year = nil
    if year.length == 2
      if year.to_i <= 99 && year.to_i > 60
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