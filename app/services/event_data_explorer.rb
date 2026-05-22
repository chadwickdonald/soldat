class EventDataExplorer
  DEFAULT_START = "2025-09-01T00:00:00Z"
  DEFAULT_END   = "2025-09-08T00:00:00Z"

  PERIOD_BUCKETS = { "1m" => "1m", "5m" => "5m" }.freeze

  def initialize(start_date: DEFAULT_START, end_date: DEFAULT_END)
    @start_date = start_date
    @end_date   = end_date
  end

  def series_by_period
    @series_by_period ||= begin
      grouped = Hash.new { |h, k| h[k] = [] }
      measurement_sources_with_metadata.each do |source|
        grouped[period_bucket(source.calc_period)] << serialize_series(source)
      end
      grouped
    end
  end

  def available_periods
    series_by_period.keys.sort
  end

  def events_for(measurement_source_uuid)
    source = ScadaMeasurementSource.find_by(uuid: measurement_source_uuid)
    return [] unless source

    source.scada_events
          .between(@start_date, @end_date)
          .ordered
          .pluck(:date, :val)
          .map { |date, val| { date: date.iso8601, val: val } }
  end

  private

  def measurement_sources_with_metadata
    ScadaMeasurementSource
      .joins(scada_measurement: :field_alias)
      .includes(scada_measurement: :field_alias)
      .where.not(calc_period: [nil, ""])
      .order("field_aliases.station_id ASC")
  end

  def serialize_series(source)
    measurement = source.scada_measurement
    fa          = measurement.field_alias

    {
      uuid:             source.uuid,
      calc_period:      source.calc_period,
      eng_unit:         source.eng_unit,
      station_id:       fa.station_id,
      station_type:     fa.station_type,
      station_element:  fa.measurement_type,
      segment_apcode:   measurement.segment_apcode,
      segment_name:     measurement.segment_name,
      mloc_apcode:      measurement.apcode,
      measurement_name: measurement.name,
      relevance:        fa.relevance,
      label:            "#{measurement.apcode}-#{measurement.segment_name}-#{source.calc_period}"
    }
  end

  def period_bucket(cp)
    PERIOD_BUCKETS[cp&.downcase] || "other"
  end
end
