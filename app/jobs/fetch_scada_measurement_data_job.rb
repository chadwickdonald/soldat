class FetchScadaMeasurementDataJob < ApplicationJob
  queue_as :default

  def perform
    api_key = ENV['SCADA_API_KEY']
    Pf::MeasurementDataService.new(api_key).fetch_all_measurements
  end
end
