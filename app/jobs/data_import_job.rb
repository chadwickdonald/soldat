class DataImportJob < ApplicationJob
  queue_as :default

  def perform(data_import_id)
    import = DataImport.find(data_import_id)
    import.update!(status: :processing, started_at: Time.current)

    json_text = import.input_json.download
    stations  = parse_stations_json(json_text)

    result = DataImportService.new(
      stations_json: stations,
      start_date:    import.start_date,
      end_date:      import.end_date,
      generate_csv:  import.generate_csv
    ).call

    import.update!(
      status:        :completed,
      completed_at:  Time.current,
      event_count:   result.event_count,
      skipped_count: result.skipped_count,
      station_count: result.station_count
    )

    attach_csv(import, :csv_1m, result.csv_1m, "events_1m.csv") if result.csv_1m
    attach_csv(import, :csv_5m, result.csv_5m, "events_5m.csv") if result.csv_5m

  rescue => e
    import&.update!(
      status:       :failed,
      completed_at: Time.current,
      error_message: "#{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    )
    raise
  end

  private

  def parse_stations_json(text)
    clean = text.lines.reject { |l| l.strip.start_with?("//") }.join
    JSON.parse(clean)
  end

  def attach_csv(import, attachment, content, filename)
    import.send(attachment).attach(
      io:           StringIO.new(content),
      filename:     filename,
      content_type: "text/csv"
    )
  end
end
