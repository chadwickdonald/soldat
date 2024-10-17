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

def get_details(mloc, measurement_source)
  segment = mloc.scada_segment
  measurement = mloc.scada_measurements.first
  source = measurement_source
  details = {
    "Engineering Unit": source.eng_unit,
    "Calc Period": source.calc_period,
    "Segment Name": segment ? segment.name : 'Unknown Segment',
    "Segment Apcode": segment ? segment.apcode : 'Unknown ApCode',
    "Mloc Name": mloc ? mloc.name : 'Unknown MlocName',
    "Mloc apcode": mloc ? mloc.apcode : 'Unknown MlocApCode',
    "Measurement name": measurement.name,
    "Measurement apcode": measurement.apcode,
    "Source uuid": source.uuid,
    "Site id": segment.site_id
  }
  details
end


def get_mloc_data_from_apcode(apcode, calc_period, headers)
  mlocs = ScadaMloc.where(apcode: apcode)

  data = []

  mlocs.each do |mloc|
    measurement = mloc.scada_measurements.first
    sources = measurement.scada_measurement_sources
    segment = mloc.scada_segment
    param_name = "#{mloc.name}-#{measurement.segment_name}-#{calc_period}"

    # headers << "#{mloc.name}-#{mloc.scada_measurements.first.segment_name}"

    sources.each do |source|
      puts "---source.id: #{source.id}"
      if source.calc_period == calc_period
        if source.scada_events.count == 0
          puts "---#{source.scada_measurement.name} has no events"
          next
        end
        headers << "#{mloc.name}-#{mloc.scada_measurements.first.segment_name}"
        events = source.scada_events
        event_vals = events.map(&:val)
        sorted_events = events.sort_by { |event| event.date }

        puts "---sorted_events.count: #{sorted_events.count}"

        statistics = calculate_statistics(event_vals)
        details = get_details(mloc, source)

        param_data = {}
        param_data[:param_name] = param_name
        param_data[:details] = details
        param_data[:stats] = statistics
        param_data[:events] = sorted_events
        data << param_data
      else
        puts "---#{source.scada_measurement.name} has no 1m events, probably has 5m events"
      end
    end
  end
  {:data => data, :headers => headers}
end

# Prepare to write this data into a CSV
def build_csv(data, file_name)
  puts "---build_csv"
  # puts "----data: #{data}"

  # Prepare to write this data into a CSV
  CSV.open(file_name, "wb") do |csv|
    # Collect headers (flatten across multiple data sections)
    headers = ['Field Name'] + data.flat_map { |section| section[:data].map { |d| d[:param_name] } }.uniq
    csv << headers  # Write the headers as the first row

    # Write details rows
    details_keys = data.first[:data].first[:details].keys
    details_keys.each do |key|
      row = [key]  # Start with the key as the first column
      data.each do |section|
        section[:data].each do |d|
          row << d[:details][key] # Add the corresponding details value
        end
      end
      csv << row  # Write the row for this detail key
    end

    # Write stats rows
    stats_keys = data.first[:data].first[:stats].keys
    stats_keys.each do |key|
      row = [key]  # Start with the key as the first column
      data.each do |section|
        section[:data].each do |d|
          row << d[:stats][key] # Add the corresponding stats value
        end
      end
      csv << row  # Write the row for this stat key
    end

    # Now, handle the events
    events_by_date = {}

    # Collect events by date
    data.each do |section|
      section[:data].each do |d|
        next if d[:events].nil? || d[:events].empty?

        d[:events].each do |event|
          date = event[:date]
          events_by_date[date] ||= Array.new(headers.size - 1, '') # Initialize with empty cells for each column
          param_index = headers.index(d[:param_name])
          events_by_date[date][param_index - 1] = event[:val] if param_index # Add event value to the correct column
        end
      end
    end

    # Write the event rows
    events_by_date.each do |date, values|
      csv << [date] + values.map { |v| v.nil? ? '' : v } # Ensure proper alignment
    end
  end
end

def get_events_data(calc_period)
  puts "---get_events_data"
  measurement_apcodes = ScadaEvent.pluck(:measurement_apcode).uniq
  # measurement_apcodes = ["PPCLineVoltageTr2", "PPCReactivePowerTr2", "PPCFrequencyFTr2"]

  data = []
  headers = ['Field Name']

  measurement_apcodes.each_with_index do |apcode, i|
    i = i+1
    puts "APCODE and INDEX: #{apcode.inspect}, i: #{i}"
    data << get_mloc_data_from_apcode(apcode, calc_period, headers)
  end
  data.flatten
end

def execute(calc_period)
  puts "---execute, calc_period: #{calc_period}"
  results = get_events_data(calc_period)
  # puts "---results: #{results}"
  headers = results.first[:headers]
  # puts "---headers: #{headers}"
  data = results

  file_name = "output/combined_stats5_#{calc_period}.csv"
  build_csv(data, file_name)
end

#########
start_time = Time.now

# calc_periods = ['1m', '5m']
calc_periods = ['1m']
# calc_periods = ['5m']
calc_periods.each { |calc_period| execute(calc_period) }
puts "runtime: #{Time.now - start_time} seconds"
