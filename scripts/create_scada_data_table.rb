require 'csv'
require_relative '../config/environment'

def calculate_statistics(data)
  sorted_data = data.compact.sort
  return [nil, nil, nil, nil, nil] if sorted_data.empty?

  non_zero_data = sorted_data.reject(&:zero?)

  min = sorted_data.first
  nonzero_min = non_zero_data.first
  max = sorted_data.last
  mean = non_zero_data.sum / non_zero_data.size.to_f unless non_zero_data.empty?
  median = if non_zero_data.size.odd?
             non_zero_data[non_zero_data.size / 2]
           else
             (non_zero_data[non_zero_data.size / 2 - 1] + non_zero_data[non_zero_data.size / 2]) / 2.0
           end unless non_zero_data.empty?

  {min: min, nonzero_min: nonzero_min, max: max, mean: mean, median: median}
end

def get_all_apcode_data(measurement_apcodes)
  data = {}
  measurement_apcodes.each do |measurement_apcode|
    puts "*"*100
    mlocs = ScadaMloc.where(apcode: measurement_apcode)
    mlocs.each do |mloc|
      puts "-"*50
      segment_name = mloc.scada_measurements.first.segment_name
      data[:apcode_segment_name] = "#{measurement_apcode}-#{segment_name}"
      puts "---apcode/segment_name: #{measurement_apcode}-#{segment_name}"
      sources = mloc.scada_measurements.first.scada_measurement_sources.where(calc_period: "1m")
      unless sources.empty?
        sources.each do |source|
          puts "---source: #{source.inspect}"
        end
      end
    end
  end
end

def get_first_apcode_data(measurement_apcodes)
  puts "---measurement_apcodes: #{measurement_apcodes}"
  data = {}
  measurement_apcodes.each do |measurement_apcode|
    mlocs = [ScadaMloc.where(apcode: measurement_apcode).first]
    mlocs.each do |mloc|
      puts "-"*50
      segment_name = mloc.scada_measurements.first.segment_name
      # data[:apcode_segment_name] = "#{measurement_apcode}-#{segment_name}"
      puts "---apcode/segment_name: #{measurement_apcode}-#{segment_name}"
      source = mloc.scada_measurements.first.scada_measurement_sources.where(calc_period: "1m").first
      if source.present? && source.scada_events.count > 0
        puts "---source: #{source.inspect}"
        puts "---events: #{source.scada_events.count}"
        data[measurement_apcode] = {
          mloc_uuid: mloc.uuid,
          apcode: measurement_apcode,
          segment_name: segment_name,
          source_uuid: source.uuid,
          events: source.scada_events.count
        }
      end
    end
  end
  # puts "---data: #{data.inspect}"
  data
end

def write_to_csv(filename, headers, data_rows)
  CSV.open(filename, 'wb') do |csv|
    # Write headers
    csv << headers

    # Write data rows
    data_rows.each { |row| csv << row }
  end
end


def get_events_data()
  measurement_apcodes = ScadaEvent.pluck(:measurement_apcode).uniq
  apcode_data = get_first_apcode_data(measurement_apcodes)

  headers = ['Field Name']
  data_rows = []

  apcode_data.each_with_index do |apcode_datum, i|
    i = i+1
    puts "apcode: #{apcode_datum.inspect}, i: #{i}"

    puts "---apcode_datum[:mloc_uuid]: #{apcode_datum[1][:mloc_uuid]}"

    mloc = ScadaMloc.find_by_uuid(apcode_datum[1][:mloc_uuid])
    segment = mloc.scada_segment
    measurement = mloc.scada_measurements.first
    source = measurement.scada_measurement_sources.where(uuid: apcode_datum[1][:source_uuid]).first
    puts "---source: #{source.inspect}"
    events = source.scada_events
    puts "---events.count: #{events.count}"
    event_vals = events.map(&:val)

    statistics = calculate_statistics(event_vals)
    puts "---------statistics: #{statistics}"
    puts "---statistics == [nil, nil, nil, nil, nil]: #{statistics == [nil, nil, nil, nil, nil]}"
    if statistics == [nil, nil, nil, nil, nil]
      next
    end
    sorted_events = events.sort_by { |event| event.date }
    apcode = apcode_datum[0]
    headers << apcode

    details = {
      eng_unit: source.eng_unit,
      calc_period: source.calc_period, 
      segment_name: segment ? segment.name : 'Unknown Segment', 
      segment_apcode: segment ? segment.apcode : 'Unknown ApCode', 
      mloc_name: mloc ? mloc.name : 'Unknown MlocName', 
      mloc_apcode: mloc ? mloc.apcode : 'Unknown MlocApCode', 
      measurement_name: measurement.name, 
      measurement_apcode: measurement.apcode, 
      source_uuid: source.uuid, 
      site_id: segment.site_id
    }

    if data_rows.empty?
      details.each { |key, value| data_rows << [key.to_s] }
      statistics.each { |key, value| data_rows << [key.to_s] }
    end

    details.values.each_with_index do |value, index|
      data_rows[index][i] = value
    end

    puts "---statistics: #{statistics.inspect}"
    stat_rows = [
      statistics[:min], statistics[:nonzero_min], 
      statistics[:max], statistics[:mean], statistics[:median]
    ]
    stat_rows.each_with_index do |value, index|
      data_rows[index + details.size][i] = value
    end

    sorted_events.each_with_index do |event, index|
      row = data_rows[details.size + 5 + index] || ['', '']
      row[0] = event.date
      row[i] = event.val
      data_rows[details.size + 5 + index] = row
    end
  end
  [headers, data_rows]
end

start_time = Time.now
results = get_events_data()
headers = results[0] 
data_rows = results[1]
# Write to a single CSV file
filename = "output/combined_stats.csv"
puts "headers: #{headers.inspect}"
# puts "data_rows: #{data_rows.inspect}"
write_to_csv(filename, headers, data_rows)

end_time = Time.now
total_time = end_time - start_time
puts "runtime: #{total_time} seconds"

