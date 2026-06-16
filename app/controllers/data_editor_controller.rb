class DataEditorController < ApplicationController
  def index
    @page  = [params.fetch(:page, 1).to_i, 1].max
    scope  = sources_scope
    @total = scope.count
    @record = scope.offset(@page - 1).limit(1).first
  end

  def update
    record = sources_scope
               .where(scada_measurement_sources: { uuid: params[:id] })
               .first

    return redirect_to data_editor_path, alert: "Record not found." unless record

    fa = record.scada_measurement.field_alias
    if fa.update(measurement_type: params[:measurement_type])
      redirect_to data_editor_path(page: params[:page]),
                  notice: "Station Element updated to "#{fa.measurement_type}"."
    else
      redirect_to data_editor_path(page: params[:page]),
                  alert: "Could not save: #{fa.errors.full_messages.join(', ')}"
    end
  end

  private

  def sources_scope
    scope = ScadaMeasurementSource.all

    uuid = current_user.current_scada_site&.uuid
    if uuid.present?
      scope = scope
        .joins(scada_measurement: { scada_mloc: :scada_segment })
        .where(scada_segments: { site_id: uuid })
    end

    scope
      .joins(scada_measurement: :field_alias)
      .includes(scada_measurement: :field_alias)
      .where.not(calc_period: [nil, ""])
      .order("field_aliases.station_id ASC, scada_measurement_sources.id ASC")
  end
end
