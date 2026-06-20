require 'rails_helper'

RSpec.describe DataImportJob, type: :job do
  let(:user) { User.create!(email_address: "admin@test.com", password: "password") }

  def create_import(json: '{"023":[]}')
    imp = DataImport.new(
      user:       user,
      start_date: "20250901T000000Z",
      end_date:   "20250908T000000Z",
      status:     :pending
    )
    imp.input_json.attach(
      io:           StringIO.new(json),
      filename:     "test.json",
      content_type: "application/json"
    )
    imp.save!
    imp
  end

  it "transitions to processing then completed on success" do
    imp = create_import
    allow(DataImportService).to receive(:new).and_return(
      instance_double(DataImportService, call: DataImportService::Result.new(
        event_count: 10, skipped_count: 2, station_count: 1, csv_1m: nil, csv_5m: nil
      ))
    )
    DataImportJob.perform_now(imp.id)
    imp.reload
    expect(imp).to be_completed
    expect(imp.event_count).to eq(10)
    expect(imp.skipped_count).to eq(2)
  end

  it "transitions to failed and stores error message on exception" do
    imp = create_import
    allow(DataImportService).to receive(:new).and_raise(RuntimeError, "API timeout")
    expect { DataImportJob.perform_now(imp.id) }.to raise_error(RuntimeError)
    imp.reload
    expect(imp).to be_failed
    expect(imp.error_message).to include("API timeout")
  end

  it "strips // comments before parsing JSON" do
    json = %({\n  // "023": [],\n  "024": []\n})
    imp  = create_import(json: json)
    service_double = instance_double(DataImportService, call: DataImportService::Result.new(
      event_count: 0, skipped_count: 0, station_count: 0, csv_1m: nil, csv_5m: nil
    ))
    allow(DataImportService).to receive(:new).and_return(service_double)
    DataImportJob.perform_now(imp.id)
    expect(DataImportService).to have_received(:new).with(
      hash_including(stations_json: { "024" => [] })
    )
  end

  it "attaches CSV files when service returns them" do
    imp = create_import
    allow(DataImportService).to receive(:new).and_return(
      instance_double(DataImportService, call: DataImportService::Result.new(
        event_count: 5, skipped_count: 0, station_count: 1,
        csv_1m: "time,col\n", csv_5m: "time,col\n"
      ))
    )
    DataImportJob.perform_now(imp.id)
    imp.reload
    expect(imp.csv_1m).to be_attached
    expect(imp.csv_5m).to be_attached
  end
end
