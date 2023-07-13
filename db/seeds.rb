# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)


project1 = Project.create({
	project: 'Test_IEA_GA_Perry.PRJ',
	pvsyst_version: 'v6.86',
	geographical_site: '32_36 -83_77_SA_Perry_GA_TMY.SIT',
	meteo_data: '32_36 -83_77_SA_Perry_GA_TMY.MET',
	satelite_data: 'SUNY model;TMY',
	simulation_date: '0004-06-20 16:21:00 UTC',
	simulation_variant: 'IEA_GA_Perry.VC9',
	simulation_hourly_values: 'from 01/01/90 to 31/12/90' 
})

project2 = Project.create({
	project: 'Test_IEA_GA_Perry_2.PRJ',
	pvsyst_version: 'v6.86.2',
	geographical_site: '32_36 -83_77_SA_Perry_GA_TMY_2.SIT',
	meteo_data: '32_36 -83_77_SA_Perry_GA_TMY_2.MET',
	satelite_data: 'SUNY model;TMY_2',
	simulation_date: '0004-07-20 16:21:00 UTC',
	simulation_variant: 'IEA_GA_Perry_2.VC9',
	simulation_hourly_values: 'from 01/01/90 to 31/12/90' 
})

simulation1 = PvsystSimulation.create({
	project_id: project1.id,
	simulation_time:	'2023-07-13 03:14:37 UTC',
	glob_hor: 0,	
	diff_hor: 120,	
	beam_hor: 138.9,	
	t_amb: -129,
	wind_vel: 182,	
	glob_inc: 339.2,	
	shd_loss: 232.8,	
	iam_loss: 0,	
	slg_loss: 0,	
	glob_eff: 123.5,	
	e_arr_nom: -124,	
	g_inc_lss: -135.7,	
	temp_lss: 0,	
	mod_qual: 123,	
	mis_loss: 347.2,	
	ohm_loss: -288,	
	e_arr_mpp: 0,	
	e_array: 0,
	t_array: 222.2,
	il_oper: 0,
	il_pmin: 298,
	il_pmax: 88,
	il_vmin: 0,
	e_out_inv: 123,	
	e_grid: 349.2,
	u_array: 111.1
	})

simulation2 = PvsystSimulation.create({
	project_id: project1.id,
	simulation_time:	'2023-07-14 03:14:37 UTC',
	glob_hor: 120,	
	diff_hor: 126,	
	beam_hor: 137.9,	
	t_amb: -122,
	wind_vel: 0,	
	glob_inc: 329.2,	
	shd_loss: 234.8,	
	iam_loss: 220,	
	slg_loss: 230,	
	glob_eff: 0,	
	e_arr_nom: -224,	
	g_inc_lss: -235.7,	
	temp_lss: 20,	
	mod_qual: 122,	
	mis_loss: 345.2,	
	ohm_loss: -258,	
	e_arr_mpp: 0,	
	e_array: 0,
	t_array: 252.2,
	il_oper: 0,
	il_pmin: 258,
	il_pmax: 885,
	il_vmin: 50,
	e_out_inv: 125,	
	e_grid: 349.5,
	u_array: 115.1
	})

simulation3 = PvsystSimulation.create({
	project_id: project2.id,
	simulation_time:	'2023-07-15 03:14:37 UTC',
	glob_hor: 126,	
	diff_hor: 166,	
	beam_hor: 167.9,	
	t_amb: -126,
	wind_vel: 0,	
	glob_inc: 369.2,	
	shd_loss: 634.8,	
	iam_loss: 620,	
	slg_loss: 236,	
	glob_eff: 0,	
	e_arr_nom: -264,	
	g_inc_lss: -635.7,	
	temp_lss: 26,	
	mod_qual: 162,	
	mis_loss: 365.2,	
	ohm_loss: -268,	
	e_arr_mpp: 0,	
	e_array: 0,
	t_array: 256.2,
	il_oper: 0,
	il_pmin: 268,
	il_pmax: 685,
	il_vmin: 506,
	e_out_inv: 165,	
	e_grid: 369.5,
	u_array: 165.1
	})

