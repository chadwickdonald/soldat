class EventsChartController < ApplicationController
  DEFAULT_START = "2025-09-01"
  DEFAULT_END   = "2025-09-08"

  def index
    @default_start = DEFAULT_START
    @default_end   = DEFAULT_END
  end

  def sources
    period = params[:period].presence_in(%w[1m 5m]) || "5m"
    query  = params[:q].to_s.strip.downcase

    scope = site_scoped_sources
      .joins(scada_measurement: :field_alias)
      .includes(scada_measurement: :field_alias)
      .where(calc_period: period)

    if query.length >= 2
      scope = scope.where(
        "LOWER(scada_measurements.name) LIKE :q OR " \
        "LOWER(scada_measurements.apcode) LIKE :q OR " \
        "LOWER(field_aliases.measurement_type) LIKE :q OR " \
        "LOWER(scada_measurements.segment_name) LIKE :q",
        q: "%#{query}%"
      )
    end

    results = scope.limit(60).map do |source|
      m  = source.scada_measurement
      fa = m.field_alias
      {
        value:    source.uuid,
        text:     "#{m.apcode} — #{m.segment_name}",
        subtext:  "#{fa.measurement_type} · #{source.eng_unit}",
        eng_unit: source.eng_unit.presence || "—",
        label:    "#{m.apcode} — #{m.segment_name} (#{fa.measurement_type})"
      }
    end

    render json: results
  end

  def data
    uuid       = params[:uuid]
    start_date = params[:start_date].presence || DEFAULT_START
    end_date   = params[:end_date].presence   || DEFAULT_END

    return render json: { error: "No parameter selected" }, status: :bad_request if uuid.blank?

    source = site_scoped_sources
               .where(scada_measurement_sources: { uuid: uuid })
               .first

    return render json: { error: "Source not found" }, status: :not_found unless source

    date_format = /\A\d{4}-\d{2}-\d{2}\z/
    unless start_date.match?(date_format) && end_date.match?(date_format)
      return render json: { error: "Invalid dates" }, status: :bad_request
    end

    start_dt = Time.zone.parse("#{start_date}T00:00:00Z") rescue nil
    end_dt   = Time.zone.parse("#{end_date}T23:59:59Z")   rescue nil

    return render json: { error: "Invalid dates" }, status: :bad_request unless start_dt && end_dt

    points = source.scada_events
                   .between(start_dt, end_dt)
                   .ordered
                   .pluck(:date, :val)
                   .map { |date, val| [date.to_i * 1000, val&.to_f] }

    m  = source.scada_measurement
    fa = m.field_alias

    render json: {
      points:   points,
      label:    "#{m.apcode} — #{m.segment_name}",
      eng_unit: source.eng_unit.presence || "—",
      period:   source.calc_period,
      count:    points.size
    }
  end

  private

  def site_scoped_sources
    scope = ScadaMeasurementSource.all
    uuid  = current_user.current_scada_site&.uuid
    if uuid.present?
      scope = scope
        .joins(scada_measurement: { scada_mloc: :scada_segment })
        .where(scada_segments: { site_id: uuid })
    end
    scope
  end
end
