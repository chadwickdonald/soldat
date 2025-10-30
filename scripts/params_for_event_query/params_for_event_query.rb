#!/usr/bin/env ruby

require_relative '../../config/environment'
require 'csv'
require 'json'
require 'time'

@api_key = ENV['SCADA_API_KEY']
@start_date = '20250901T010000Z'
@end_date   = '20250907T010000Z'
# @end_date   = '20250901T010500Z'
@site_uuid = ScadaSite.find_by_name("Danish Fields - T3").uuid
@data = []

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

  service = Pf::EventDataService2.new(@api_key)
  events = service.fetch_and_persist_events(
    start_date: @start_date,
    end_date: @end_date,
    source_uuid: source.uuid,
    measurement_apcode: measurement.apcode,
    site_id: @site_uuid,
    cp_name: source.calc_period
  )

  event_data = {
    measurement: measurement.id,
    header: header,
    events: events 
  }
  event_data
end

def create_csv(file_name = "events.csv")
  puts "---create_csv"
  data = @data
  preferred_header_keys = %i[
    segment_apcode segment_name measurement_apcode measurement_name
    eng_unit relevance station_type station_number station_element
  ]

  # In case some items have extra/different header keys, include them too:
  all_header_keys = (data.flat_map { |m| m[:header].keys } | preferred_header_keys).uniq
  # Order: use preferred first, then any extras alphabetically
  ordered_header_keys = preferred_header_keys + (all_header_keys - preferred_header_keys).sort

  columns = [:measurement] + ordered_header_keys + [:event_date, :event_value]

  CSV.open(file_name, "w") do |csv|
    csv << columns
    data.each do |item|
      hdr = item[:header] || {}
      (item[:events] || []).each do |ev|
        csv << [
          item[:measurement],
          *ordered_header_keys.map { |k| hdr[k] },
          fmt_ev_time(ev["date"], tz: :local, fmt: "%Y-%m-%d %H:%M:%S"),
          ev["val"]
        ]
      end
    end
  end
  puts "Wrote #{File.expand_path("events.csv")}"
end

def get_create_events_field_alias(data)
  puts "---get_create_events_field_alias"
  segment = ScadaSegment.where(apcode: data[:segment_apcode], name: data[:segment_name]).first
  mloc = segment.scada_mlocs.where(apcode: data[:mloc_apcode]).first
  measurement = mloc.scada_measurements.first
  source = measurement.scada_measurement_sources.where(calc_period: data[:source_calc_period]).first
  station_data = {
    station_type: data[:station_type],
    station_element: data[:station_element],
    station_id: data[:station_id],
    relevance: data[:relevance]
  }
  @data << create_header_and_data(segment, measurement, source, station_data)
end

def fmt_ev_time(s, tz: :local, fmt: "%Y-%m-%d %H:%M:%S")
  return nil if s.nil? || s.empty?
  t = Time.strptime(s, "%Y%m%dT%H%M%SZ")   # parse "20250901T010000Z"
  t = (tz == :local) ? t.getlocal : t.utc  # choose local time or keep UTC
  t.strftime(fmt)                          # e.g., "2025-09-01 06:00:00" (PT)
end

##########


path = 'data_blocks_023_093.json'
raw = File.read(path, mode: "r:BOM|UTF-8")
stations = JSON.parse(raw, symbolize_names: true)


stations.each do |station|
  station_number = station.first.to_s
  puts "------"
  puts "---station_number: #{station_number}"
  data = station.second
  data.each_with_index do |datum, i|
    puts "--index: #{i}"
    puts datum
    puts "------"
    get_create_events_field_alias(datum)
  end
  create_csv("events_#{station_number}.csv")
end
