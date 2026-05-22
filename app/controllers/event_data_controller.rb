class EventDataController < ApplicationController
  def index
    @start_date = params.fetch(:start_date, EventDataExplorer::DEFAULT_START)
    @end_date   = params.fetch(:end_date,   EventDataExplorer::DEFAULT_END)
    @periods    = %w[1m 5m other]
  end

  def series_data
    start_date = params.fetch(:start_date, EventDataExplorer::DEFAULT_START)
    end_date   = params.fetch(:end_date,   EventDataExplorer::DEFAULT_END)
    period     = params.fetch(:period,     "5m")

    explorer = EventDataExplorer.new(start_date: start_date, end_date: end_date)
    render json: explorer.series_by_period[period] || []
  end

  def events_data
    uuid       = params[:uuid]
    start_date = params.fetch(:start_date, EventDataExplorer::DEFAULT_START)
    end_date   = params.fetch(:end_date,   EventDataExplorer::DEFAULT_END)

    return render json: [] if uuid.blank?

    explorer = EventDataExplorer.new(start_date: start_date, end_date: end_date)
    render json: explorer.events_for(uuid)
  end
end
