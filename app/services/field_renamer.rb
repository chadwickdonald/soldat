class FieldRenamer

  MEASUREMENT_TYPE = {
    pmp: 'Power Measurement Parameter',
    pva: 'PV Array',
    ess: 'Energy Storage System (ESS)',
    met: 'Met and Enviro',
    ppc: 'Power Quality / Substation / PPC / Controls'
  }

  ENG_UNIT = {
    watt: 'W / kW / MW',
    wm2: 'Watts/m^2',
    deg: 'deg C',
    volt: 'Volts',
    amp: 'Amps',
    kva: 'kVA',
    var: 'VAR / Phase Angle',
    na: nil
  }

  STATION_TYPE = {
    meter: 'Main Meter', # Revenue Meter?
    pv: 'PV Inverter station / PV Array',
    met: 'Met Station',
    ppc: 'Power Plant Controller', # PPC?
    na: nil
  }

  STATION_NUMBER = {
    yes: true,
    no: false
  }

  MEASUREMENT_TYPE_FILTER_RULES = {
    ['W', 'KW', 'kW', 'MW', 'kilowatt', 'Watt', 'Megawatt'] =>                 [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na], STATION_NUMBER[:no]],
    ['meter', 'main power', 'revenue', ' P '] =>                               [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:na], STATION_TYPE[:meter], STATION_NUMBER[:no]],
    ['AC kW','MW', 'Watts'] =>                                                 [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na], STATION_NUMBER[:yes]],
    ['DC kW', 'DC MW', 'DC Watts'] =>                                          [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na], STATION_NUMBER[:no]],
    ['inverter', 'inv', 'PV', 'solar', 'station', 'pad'] =>                    [MEASUREMENT_TYPE[:pva], ENG_UNIT[:na], STATION_TYPE[:pv], STATION_NUMBER[:yes]],
    ['PCS', 'Battery' , 'ESS', 'Storage', 'EMS'] =>                            [MEASUREMENT_TYPE[:ess], ENG_UNIT[:na], STATION_TYPE[:na], STATION_NUMBER[:yes]],
    ['Irr', 'irradiance', 'W/m2', 'insolation'] =>                             [MEASUREMENT_TYPE[:met], ENG_UNIT[:wm2], STATION_TYPE[:met], STATION_NUMBER[:yes]],
    ['Temp', 'temperature', 'deg', 'deg C', 'deg F'] =>                        [MEASUREMENT_TYPE[:met], ENG_UNIT[:deg], STATION_TYPE[:met], STATION_NUMBER[:yes]],
    ['PPC', 'Controller', 'Power Control', 'Plant Controller', 'Set Point'] => [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:na], STATION_TYPE[:ppc], STATION_NUMBER[:no]],
    ['V', 'Volts', 'kV', 'MV'] =>                                              [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:volt], STATION_TYPE[:na], STATION_NUMBER[:no]],
    ['A', 'amps', 'amperage'] =>                                               [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:amp], STATION_TYPE[:na], STATION_NUMBER[:no]],
    ['VA', 'kVA', 'MVA', 'apparent', 'app'] =>                                 [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:kva], STATION_TYPE[:na], STATION_NUMBER[:no]],
    ['VAR', 'kVAR', 'MVAR', 'reactive', 'react power', ' Q '] =>               [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:var], STATION_TYPE[:na], STATION_NUMBER[:no]]
  }

  # Need to used this somehow
  parameter_map = {
    "1.01" => "Main Meter Real Power (P)",
    "1.02" => "Main Meter Apparent Power (S)",
    "1.03" => "Main Meter Reactive Power (Q)",
    "1.04" => "Main Meter Voltage",
    "1.05" => "Main Meter Phase Angle",
    "1.06" => "Main Meter Power Factor",
    "1.07" => "Energy (kWh) Main Meter total since COD",
    "1.08" => "Frequency Main Meter",
    "1.09" => "Curtailment Flag",
    "1.10" => "Frequency droop Main Meter",
    "1.11" => "Flicker Main Meter",
    "2.1.1" => "PPC - Active Power",
    "2.1.2" => "PPC - Active Apparent Power -kVA",
    "2.1.3" => "PPC - Active Power Factor",
    "2.1.4" => "PPC - Active Reactive Power kVAR",
    "2.1.5" => "PPC - Phase Angle Active",
    "2.1.6" => "PPC - Active Frequency",
    "2.1.7" => "PPC - Ramp Rate Active",
    "2.1.8" => "PPC - Apparent Power Set point -kVA",
    "2.1.9" => "PPC - Power Factor set point",
    "2.1.10" => "PPC - Reactive Power Mode - VAR/PF/AVR/Manual",
    "2.1.11" => "PPC - kVA command",
    "2.1.12" => "PPC - Ramp Rate command",
    "2.1.13" => "PPC - Voltage command",
    "2.1.14" => "PPC - Frequency command",
    "2.1.15" => "PPC - Curtailment command",
    "2.1.16" => "PPC - Utility/ISO control command",
    "2.1.17" => "Tracker - Plant Setpoint command angle of inclination",
    "2.2.1" => "PV Gen - Total Active Power",
    "2.2.2" => "PV Gen - Active Apparent Power -kVA",
    "2.2.3" => "PV Gen - Active Power Factor",
    "2.2.4" => "PV Gen - Active Reactive Power kVAR",
    "2.2.5" => "Alarm",
    "2.3.1" => "Instantaneous Average angle of inclination",
    "2.3.2" => "Command Average Angle of Inclination",
    "2.3.3" => "Wind stow command",
    "2.3.4" => "Flood stow command",
    "2.3.5" => "Average wind speed",
    "2.3.6" => "Maximum wind speed",
    "2.3.7" => "Alarm",
    "2.4.1" => "Instantaneous Charge/Discharge Power Status -kW (+/-)",
    "2.4.2" => "Instantaneous Ramp Rate",
    "2.4.3" => "Instantaneous ESS kVA",
    "2.4.4" => "Instantaneous ESS kVAR",
    "2.4.6" => "Charge/Discharge Set point - MW",
    "2.4.7" => "Charge/Discharge Instantaneous - MW",
    "2.4.8" => "Frequency Set point",
    "2.4.9" => "Ramp Rate Set point",
    "2.4.10" => "Ramp Rate instantaneous",
    "2.4.11" => "kVA Set point",
    "2.4.12" => "kVA Instantaneous",
    "3.1.1" => "AC Power Total (low voltage)",
    "3.1.2" => "AC voltage",
    "3.1.3" => "AC kVA",
    "3.1.4" => "AC kVAR - reactive power",
    "3.1.5.1" => "AC Power - Stage 1",
    "3.1.5.1.1" => "DC Voltage -AC power stage 1",
    "3.1.5.1.2.1" => "DC Amp Zone 1 - AC power stage 1",
    "3.1.5.1.2.2" => "DC Volts Zone 1 - AC power stage 1",
    "3.1.5.1.3" => "IGBT Temp - AC power stage 1",
    "3.1.5.2" => "AC Power - Stage 2",
    "3.1.6" => "MVT (transformer) temp",
    "3.1.7" => "AC kWh total history",
    "3.1.8.1" => "AC kW Set point (command)",
    "3.1.8.2" => "AC Reactive Power Set point (command)",
    "3.1.9.1" => "Alarm 1",
    "3.1.9.2" => "Alarm 2",
    "3.2.1" => "AC Power",
    "3.2.2" => "DC voltage",
    "3.2.3" => "AC kVA",
    "4.1.01" => "Charge/Discharge Set point - MW",
    "4.1.02" => "Charge/Discharge Instantaneous - MW",
    "4.1.03" => "Frequency Set point",
    "4.1.04" => "Frequency Instantaneous",
    "4.1.05" => "Ramp Rate Set point",
    "4.1.06" => "Ramp Rate instantaneous",
    "4.1.07" => "kVA Set point",
    "4.1.08" => "kVA Instantaneous",
    "4.2.1" => "ESS PCS -01",
    "4.2.1.1" => "ESS DC Battery Block 01-A",
    "4.2.2" => "ESS PCS -02",
    "4.2.2.1" => "ESS DC Battery Block 02-A",
    "4.3.1" => "ESS PCS -01",
    "4.106.1" => "ESS PCS -01",
    "5.1.1" => "POA Irradiance - Plane of Array",
    "5.1.1.1" => "Angle of inclination - POA tilt angle",
    "5.1.2" => "GHI Irradiance - Global Horizontal",
    "5.1.3" => "Albedo Irradiance - Ground Reflected",
    "5.1.4" => "RPOA Irradiance - Rear Plane of Array",
    "5.1.5.1" => "Ambient Temp 1",
    "5.1.5.2" => "Ambient Temp 2",
    "5.1.6.1" => "Back of Module temp 1 - Cell temp 1",
    "5.1.6.2" => "Back of Module temp 2 - Cell temp 2",
    "5.1.6.3" => "Back of Module temp 3 - Cell temp 3",
    "5.1.7" => "wind speed",
    "5.1.8" => "soiling Isc percent",
    "5.1.9" => "wind speed",
    "5.1.10" => "DNI Irradiance - Direct Normal Irradiance",
    "5.1.11" => "Primary/ Aux MET Station designation",
    "5.2.1" => "POA Irradiance - Plane of Array",
    "5.2.2" => "GHI Irradiance - Global Horizontal",
    "5.2.3" => "Albedo Irradiance - Ground Reflected Irr",
    "6.1.1" => "Plant Setpoint command angle of inclination",
    "6.1.2" => "Wind stow command",
    "6.1.3" => "Flood stow command",
    "6.1.4" => "Average wind speed",
    "6.1.5" => "Maximum wind speed",
    "6.1.6" => "Alarm",
    "6.2.1" => "Zone (NCU) Setpoint command angle of inclination",
    "6.2.2" => "Zone Wind stow command",
    "6.2.3" => "Zone Flood stow command",
    "6.2.4.1.1" => "Tracker Motor 01-01 (SPC) Setpoint command angle of incline",
    "6.2.4.1.2" => "Tracker Motor 01-01 (IPC) Actual angle of inclination",
    "6.2.4.2.1" => "Tracker Motor 01-02 (SPC) Setpoint command angle of incline",
    "6.2.4.2.2" => "Tracker Motor 01-02 (IPC) Actual angle of inclination",
    "6.3.1" => "Zone (NCU) Setpoint command angle of inclination"
  }

  def initialize(data)
    @data = data
  end

  def call
    renamed_data = categorize_data(MEASUREMENT_TYPE_FILTER_RULES)
  end

  private

  attr_reader :data

  def extract_number(string)
    match = string.match(/(\d+)(?!m)/)
    match ? match[1].rjust(3, '0') : nil
  end

  def categorize_data(rules)
    categorized_data = {}

    data.each do |key, value|
      next unless key == 'Field Name'

      rules.keys.each do |rule_keys|
        matched_category = rule_keys.find { |keyword| value.downcase.include?(keyword) }
        if matched_category
          new_header = rules[rule_keys]
          categorized_data['Measurement Type'] = new_header[0]
          categorized_data['Engineering Unit'] = new_header[1]
          categorized_data['Station Type'] = new_header[2]
          if new_header[3]
            station_id = extract_number(data['Field Name'])
            categorized_data['Station Id'] = station_id
          end
        else
          # puts 'No Match'
        end
      end
    end
    # puts "---return categorized_data: #{categorized_data}"
    categorized_data
  end

  def create_field_alias(measurement, categorized_data)
    field_alias = FieldAlias.create(
      scada_measurement: measurement,
      enthasys_id: nil,
      measurement_type: categorized_data['Measurement Type'],
      engineering_unit: categorized_data['Engineering Unit'],
      station_type: categorized_data['Station Type'],
      station_id: categorized_data['Station Id']
    )
  end
end