require 'axlsx'
require_relative '../config/environment'

# Fetch related ScadaEvent and ScadaDef records
scada_events = ScadaEvent.joins(:scada_def).includes(:scada_def).all

# Create a new Excel workbook
Axlsx::Package.new do |p|
  p.workbook.add_worksheet(name: "SCADA Data") do |sheet|
    # Prepare the column headers
    headers = ['Date']
    scada_defs = scada_events.map(&:scada_def).uniq

    scada_defs.each do |scada_def|
      headers << "#{scada_def.name} [#{scada_def.eng_unit}] - (#{scada_def.source_id})"
    end

    # Add the headers to the sheet
    sheet.add_row headers

    # Prepare a hash to store the data by date
    data_by_date = Hash.new { |hash, key| hash[key] = {} }

    # Populate the data_by_date hash
    scada_events.each do |event|
      date = event.date.to_date
      scada_def = event.scada_def
      data_by_date[date][scada_def.source_id] = event.val
    end

    # Add the data rows to the sheet
    data_by_date.keys.sort.each do |date|
      row = [date]
      scada_defs.each do |scada_def|
        row << data_by_date[date][scada_def.source_id]
      end
      sheet.add_row row
    end
  end

  # Save the Excel file
  p.serialize('scada_data.xlsx')
end
