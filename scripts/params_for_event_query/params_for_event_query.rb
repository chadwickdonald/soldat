#!/usr/bin/env ruby
require_relative '../../config/environment'

station_type_1 = 'PVGEN'

station_element_1 = 'ACPWR'
station_element_2 = 'ACENRGTOT'
station_element_3 = 'MOD1-KVAR'
station_element_4 = 'MOD1-PF'
station_element_5 = 'MOD1-DCAMP'
station_element_6 = 'MOD1-DCVOLT'
station_element_7 = 'MOD2-KVAR'
station_element_8 = 'MOD2-DCAMP'
station_element_9 = 'MOD2-DCVOLT'


def create_field_alias(measurement, station_data, eng_unit)
  fa = FieldAlias.find_by_scada_measurement_id(measurement.id)
  return fa if fa
  FieldAlias.create( 
    scada_measurement_id: measurement.id,
    measurement_type: station_data[:station_element],
    engineering_unit: eng_unit,
    station_type: station_data[:station_type],
    station_id: station_data[:station_id],
    relevance: station_data[:relevance]
  )
end

def create_header_and_data(segment, measurement, source, station_data)
  field_alias = create_field_alias(measurement, station_data, source.eng_unit)
  header = {
    segment_apcode: segment.apcode,
    segment_name: segment.name,
    measurement_apcode: measurement.apcode,
    measurement_name: measurement.name,
    eng_unit: source.eng_unit,
    relevance: field_alias.relevance,
    station_type: field_alias.station_type,
    station_number: field_alias.station_id,
    station_element: field_alias.measurement_type
  }
  # get events
  events = source.scada_events.pluck(:date, :val)
  event_data = {
    measurement: measurement.id,
    header: header,
    events: events 
  }
  event_data
end

#####

segment = ScadaSegment.where(apcode: 'ArrayGroup', name: 'Solar Inverter Block 020').first
mloc = segment.scada_mlocs.where(apcode: 'ArrayOutputPower').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_1,
  station_id: '20',
  relevance: 1
}

data = create_header_and_data(segment, measurement, source, station_data)

puts data

#####

segment = ScadaSegment.where(apcode: 'ArrayGroup', name: 'Solar Inverter Block 020').first
mloc = segment.scada_mlocs.where(apcode: 'CumulativeArrayOutputEnergy').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_2,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data

####

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-1').first
mloc = segment.scada_mlocs.where(apcode: 'ArrayReactiveOutputPower').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_3,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data


#######

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-1').first
mloc = segment.scada_mlocs.where(apcode: 'TotalPowerFactor').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_4,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data


####


segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-1').first
mloc = segment.scada_mlocs.where(apcode: 'PanelGroupOutputCurrent').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_5,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data


####

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-1').first
mloc = segment.scada_mlocs.where(apcode: 'PanelGroupOutputVoltage').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_6,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data

####

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-2').first
mloc = segment.scada_mlocs.where(apcode: 'ArrayReactiveOutputPower').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_7,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data

####

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-2').first
mloc = segment.scada_mlocs.where(apcode: 'PanelGroupOutputCurrent').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_8,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data

####

segment = ScadaSegment.where(apcode: 'InverterModule', name: 'Inverter module 020-2').first
mloc = segment.scada_mlocs.where(apcode: 'PanelGroupOutputVoltage').first
measurement = mloc.scada_measurements.first
source = measurement.scada_measurement_sources.where(calc_period: '5m').first
station_data = {
  station_type: station_type_1,
  station_element: station_element_9,
  station_id: '20',
  relevance: 1
}
data = create_header_and_data(segment, measurement, source, station_data)

puts data
