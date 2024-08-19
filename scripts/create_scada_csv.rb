require 'csv'
require_relative '../config/environment'

start_time = Time.now
# Fetch all ScadaEvents 
# scada_events = ScadaEvent.all
scada_events = ScadaEvent.where(measurement_apcode: "PPCActivePowerTr2")
# measurement_apcodes = ScadaEvent.pluck(:measurement_apcode).uniq
# scada_events = ScadaEvent.where(measurement_apcode: measurement_apcodes.first(3))

# Prepare the column headers
headers = ['Date']

# Prepare a hash to store the unique scada_measurement_source and scada_measurement combinations
unique_sources = {}

# Populate unique_sources hash
scada_events.each do |event|
  source = event.scada_measurement_source
  measurement = source.scada_measurement
  mloc = measurement.scada_mloc
  segment = mloc&.scada_segment
  measurement_key = "#{measurement.apcode}_#{source.id}"
  unique_sources[measurement_key] = { source: source, segment: segment, mloc: mloc, measurement: measurement }
end

# Prepare a hash to store the data by date and measurement_key
data_by_date = Hash.new { |hash, key| hash[key] = {} }

# Populate the data_by_date hash
scada_events.each do |event|
  date = event.date
  source = event.scada_measurement_source
  measurement = source.scada_measurement
  measurement_key = "#{measurement.apcode}_#{source.id}"
  data_by_date[date][measurement_key] = event.val
end

# Remove columns without any values
unique_sources.select! do |key, _|
  data_by_date.values.any? { |date_data| date_data.key?(key) }
end

# Create headers grouped by measurement_apcode and source_id
unique_sources.each do |key, value|
  measurement = value[:measurement]
  headers << "#{measurement.name}"
end

# Function to calculate statistics
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

  [min, nonzero_min, max, mean, median]
end

# Function to write data to CSV
def write_to_csv(filename, headers, data_by_date, unique_sources)
  CSV.open(filename, 'wb') do |csv|
    # Add the headers to the CSV
    csv << headers

    # Add statistics rows (min, max, mean, median)
    statistics = { 
      'min' => [], 
      'nonzero_min' => [], 
      'max' => [], 
      'mean' => [], 
      'median' => [] 
    }
    details = { 
      'eng_unit' => [], 
      'calc_period' => [], 
      'segment_name' => [], 
      'segment_apcode' => [], 
      'mloc_name' => [], 
      'mloc_apcode' => [], 
      'measurement_name' => [], 
      'measurement_apcode' => [], 
      # 'segment_uri' => [], 
      # 'mloc_uri' => [], 
      # 'source_uri' => [], 
      'source_uuid' => [], 
      'site_id' => [] 
    }

    unique_sources.each do |key, value|
      column_data = data_by_date.values.map { |row| row[key] }
      min, nonzero_min, max, mean, median = calculate_statistics(column_data)

      source = value[:source]
      measurement = value[:measurement]
      segment = value[:segment]
      mloc = value[:mloc]

      statistics['min'] << min
      statistics['nonzero_min'] << nonzero_min
      statistics['max'] << max
      statistics['mean'] << mean
      statistics['median'] << median

      details['eng_unit'] << source.eng_unit
      details['calc_period'] << source.calc_period
      details['segment_name'] << (segment ? segment.name : 'Unknown Segment')
      details['segment_apcode'] << (segment ? segment.apcode : 'Unknown ApCode')
      details['mloc_name'] << (mloc ? mloc.name : 'Unknown MlocName')
      details['mloc_apcode'] << (mloc ? mloc.apcode : 'Unknown MlocApCode')
      details['measurement_name'] << measurement.name
      details['measurement_apcode'] << measurement.apcode
      # details['segment_uri'] << (segment ? segment.uri : 'Unknown segment URI')
      # details['mloc_uri'] << (mloc ? mloc.uri : 'Unknown Mloc URI')
      # details['measurement_uri'] << measurement.uri
      # details['source_uri'] << source.uri
      details['source_uuid'] << source.uuid
      details['site_id'] << source.scada_event.site_id
    end

    csv << ['Min'] + statistics['min']
    csv << ['NonzeroMin'] + statistics['nonzero_min']
    csv << ['Max'] + statistics['max']
    csv << ['Mean'] + statistics['mean']
    csv << ['Median'] + statistics['median']

    csv << ['Eng Unit'] + details['eng_unit']
    csv << ['Calc Period'] + details['calc_period']
    csv << ['Segment Name'] + details['segment_name']
    csv << ['Segment ApCode'] + details['segment_apcode']
    csv << ['Mloc Name'] + details['mloc_name']
    csv << ['Mloc ApCode'] + details['mloc_apcode']
    csv << ['Measurement Name'] + details['measurement_name']
    csv << ['Measurement Apcode'] + details['measurement_apcode']
    # csv << ['Segment URI'] + details['segment_uri']
    # csv << ['Mloc URI'] + details['mloc_uri']
    # csv << ['Measurement URI'] + details['measurement_uri']
    # csv << ['Source URI'] + details['source_uri']
    csv << ['Source UUID'] + details['source_uuid']
    csv << ['Site ID'] + details['site_id']


    # Add the data rows to the CSV
    data_by_date.keys.sort.each do |date|
      row = [date]
      unique_sources.each do |key, _|
        row << data_by_date[date][key]
      end
      csv << row
    end
  end
end

# Separate data for '1m' and '5m'
data_by_date_1m = {}
data_by_date_5m = {}

puts "data_by_date count: #{data_by_date.count}"

data_by_date.each do |date, measurements|
  measurements.each do |key, value|
    source = unique_sources[key][:source]
    if source.calc_period == '1m'
      data_by_date_1m[date] ||= {}
      data_by_date_1m[date][key] = value
    elsif source.calc_period == '5m'
      data_by_date_5m[date] ||= {}
      data_by_date_5m[date][key] = value
    end
  end
end

# puts "data_by_date_1m: #{data_by_date_1m.inspect}"

# Write to respective CSV files
write_to_csv('scada_data_1m.csv', headers, data_by_date_1m, unique_sources.select { |key, value| value[:source].calc_period == '1m' })
# write_to_csv('scada_data_5m.csv', headers, data_by_date_5m, unique_sources.select { |key, value| value[:source].calc_period == '5m' })
end_time = Time.now
total_time = end_time - start_time
puts "runtime: #{total_time} seconds"



