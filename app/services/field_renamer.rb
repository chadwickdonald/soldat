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


# -------- Public API --------

  def self.call(measurement)
    new(measurement).call
  end

# -------- Instance --------

  def initialize(measurement_or_data)
    if measurement_or_data.is_a?(Hash)
      @data = measurement_or_data
    else
      @measurement = measurement_or_data
      mloc = measurement_or_data.scada_mloc
      @data = {"Field Name" => "#{mloc.name}-#{measurement_or_data.segment_name}-1m"}
    end
  end

  def call
    puts "-----call"
    renamed_data = categorize_data(MEASUREMENT_TYPE_FILTER_RULES)
    return renamed_data unless @measurement

    create_field_alias(@measurement, renamed_data)
  end

  private

  attr_reader :data, :measurement

  def extract_number(string)
    puts "---extract_number"
    match = string.match(/(\d+)(?!m)/)
    match ? match[1].rjust(3, '0') : nil
  end

  def categorize_data(rules)
    puts "---categorize_data"
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
        elsif categorized_data.empty?
          puts '---No Match'
        end
      end
    end
    puts "---return categorized_data: #{categorized_data}"
    categorized_data
  end

  # TODO: Add relevance field (see Charly's spreadsheet)
  def create_field_alias(measurement, categorized_data)
    puts "---create_field_alias"
    field_alias = FieldAlias.create(
      scada_measurement: measurement,
      enthasys_id: nil,
      measurement_type: categorized_data['Measurement Type'],
      engineering_unit: categorized_data['Engineering Unit'],
      station_type: categorized_data['Station Type'],
      station_id: StationIdExtractor.call(measurement.segment_name)
    )
  end
end
