require_relative '../../config/environment'

def extract_number(string)
  match = string.match(/(\d+)(?!m)/)
  match ? match[1].rjust(3, '0') : nil
end


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
  meter: 'Main Meter',
  pv: 'PV Inverter station / PV Array',
  met: 'Met Station',
  ppc: 'Power Plant Controller',
  na: nil
}

STATION_NUMBER = {
  yes: true,
  no: false
}

MEASUREMENT_TYPE_FILTER_RULES = {
  ['W', 'KW', 'kW', 'MW', 'kilowatt', 'Watt', 'Megawatt'] =>                 [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na], STATION_NUMBER[:no]],
  ['meter', 'main power', 'revenue'] =>                                      [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:na], STATION_TYPE[:meter], STATION_NUMBER[:no]],
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
  ['VAR', 'kVAR', 'MVAR', 'reactive', 'react power'] =>                      [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:var], STATION_TYPE[:na], STATION_NUMBER[:no]]
}

# pass in mloc.name - segment.name and source uuid / id instead of data
# then save these new fields with source uuid / id in a new table - enthasys_measurements ?
def categorize_data(data, rules)
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
        puts 'No Match'
      end
    end
  end
  puts "---return categorized_data: #{categorized_data}"
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


########################

# Sample input data
data = {
  'Field Name' => 'Ambient Temperature (1m)-MET.028-1m',
  'Engineering Unit' => 'C',
  'Calc Period' => '1m',
  'Segment Name' => 'MET.028',
  'Segment Apcode' => 'WeatherStation',
  'Mloc Name' => 'Ambient Temperature (1m)',
  'Mloc apcode' => 'AmbientAirTemperatureTr2',
  'Measurement name' => 'Ambient Temperature (1m)',
  'Measurement apcode' => 'AmbientAirTemperatureTr2',
  'Source uuid' => 'b68cb0a8-8854-11ee-a4ff-42010afa015a',
  'Site id' => '5658d43-0ffd-42b4-a4e4-d3b808e85087'
}

measurement = ScadaMeasurement.find(172)
categorized_data = categorize_data(data, MEASUREMENT_TYPE_FILTER_RULES)
field_alias = create_field_alias(measurement, categorized_data)

puts "---field_alias: #{field_alias.inspect}"
# # Output the result
# puts "Categorized Data:"
# categorized_data.each do |key, value|
#   puts "#{key}: #{value}"
# end
