# export_segment_mloc_apcodes.rb
require "csv"
require "fileutils"
require_relative "../config/environment"

# segment_apcodes = %w[
#   PanelGroup Transformer ArrayGroup InverterModule
#   StringMonitor Subfield Inverter
# ].uniq

segment_apcodes = %w[
  Pyranometer TempSensor WindSpeedSensor WindDirectionSensor TempTransducer
  RainGaugeSensor PyranometerTransducer WeatherStation HumiditySensor
  DustSensor BarometricPressureSensor WeatherStations HailSensor
  AlbedometerTransducer Albedometer
].uniq

OUTPUT_PATH = File.expand_path("output/segment_mloc_apcodes_B1.csv", __dir__)
FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))

count = 0
data = []

site = ScadaSite.find_by_name("Danish Fields - T3")

segment_apcodes.each do |segment_apcode|
  puts "working on segment: #{segment_apcode}"
  segments = ScadaSegment.where(apcode: segment_apcode, site_id: site.uuid)
  segments.each do |segment|
    segment.scada_mlocs.each do |mloc|
      mloc_apcode = mloc.apcode&.to_s&.strip
      next if mloc_apcode.nil? || mloc_apcode.empty?

      measurement = mloc.scada_measurements.first
      next unless measurement

      sources = measurement.scada_measurement_sources
      data << [
        segment.apcode,
        segment.name,
        measurement.apcode,
        measurement.name,
        sources.pluck(:eng_unit),
        sources.pluck(:calc_period)
      ]
      count += 1
    end
  end
end

data.sort_by! { |row| [row[0].to_s, row[1].to_s, row[2].to_s] }

CSV.open(OUTPUT_PATH, "w") do |csv|
  csv << %w[segment_apcode segment_name measurement_apcode measurement_name eng_unit calc_periods]
  data.each { |row| csv << row }
end

puts "Wrote #{data.size} rows to #{OUTPUT_PATH}"
