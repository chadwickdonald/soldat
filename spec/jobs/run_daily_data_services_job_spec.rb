# # spec/jobs/run_daily_data_services_job_spec.rb
# require 'rails_helper'

# RSpec.describe RunDailyDataServicesJob, type: :job do
#   let(:date) { Date.new(2025, 3, 1) }

#   before do
#     allow(Pf::MlocDataService).to receive_message_chain(:new, :fetch_mlocs).and_return(true)
#     allow(Pf::SegmentDataService).to receive_message_chain(:new, :fetch_all_segments).and_return(true)
#     allow(Pf::MeasurementDataService).to receive_message_chain(:new, :fetch_all_measurements).and_return(true)
#     allow(Pf::EventDataService).to receive_message_chain(:new, :fetch_and_persist_events).and_return(true)

#     org = ScadaOrganization.create!(uuid: "org-uuid", name: "Org")
#     site = ScadaSite.create!(uuid: "site-uuid", name: "Site", organization_id: org.id)
#   end

#   it "calls all data services with expected arguments" do
#     expect(Pf::MlocDataService).to receive_message_chain(:new, :fetch_mlocs)
#     expect(Pf::SegmentDataService).to receive_message_chain(:new, :fetch_all_segments)
#     expect(Pf::MeasurementDataService).to receive_message_chain(:new, :fetch_all_measurements)
#     expect(Pf::EventDataService).to receive_message_chain(:new, :fetch_and_persist_events)

#     described_class.perform_now(date)
#   end
# end


# spec/jobs/run_daily_data_services_job_spec.rb
require 'rails_helper'

RSpec.describe RunDailyDataServicesJob, type: :job do
  let(:date) { Date.new(2025, 3, 1) }

  before do
    # Mocks for the services we still want to fake
    allow(Pf::SiteDataService).to receive_message_chain(:new, :fetch_and_persist_sites).and_return(true)
    allow(Pf::MlocDataService).to receive_message_chain(:new, :fetch_all_mlocs).and_return(true)
    allow(Pf::SegmentDataService).to receive_message_chain(:new, :fetch_all_segments).and_return(true)
    allow(Pf::EventDataService).to receive_message_chain(:new, :fetch_and_persist_events).and_return(true)
    # ❗ No mock for MeasurementDataService anymore — we want the real thing now!

    # Setup real models
    org = ScadaOrganization.create!(uuid: "org-uuid", name: "Org")
    site = ScadaSite.create!(uuid: "site-uuid", name: "Site", organization_id: org.id)

    puts "---site: #{site.inspect}"

    # First, create Segment
    segment = ScadaSegment.create!(
      uuid: "segment-uuid",
      site_id: site.uuid,
      name: "Test Segment"
    )

    puts "---segment: #{segment.inspect}"

    # Then create Mloc tied to the Segment
    mloc = ScadaMloc.create!(
      uuid: "mloc-uuid",
      segment_id: segment.uuid,
      name: "Test MLOC"
    )

    puts "---mloc: #{mloc.inspect}"

    # Then Measurement tied to Mloc + Segment
    measurement = ScadaMeasurement.create!(
      uuid: "measurement-uuid",
      mloc_id: mloc.uuid,
      name: "Test Measurement"
    )

    puts "---measurement: #{measurement.inspect}"

    source = ScadaMeasurementSource.create!(
      uuid: "b8bcd7ae-8854-11ee-a4ff-42010afa015a",
      scada_measurement_id: measurement.id
    )

    puts "---source: #{source.inspect}"
  end

  it "calls all data services with expected arguments and fetches real measurement data", :vcr do
    # Expectations for the mocked services (we still check they get called)
    expect(Pf::SiteDataService).to receive_message_chain(:new, :fetch_and_persist_sites)
    expect(Pf::MlocDataService).to receive_message_chain(:new, :fetch_all_mlocs)
    expect(Pf::SegmentDataService).to receive_message_chain(:new, :fetch_all_segments)
    expect(Pf::EventDataService).to receive_message_chain(:new, :fetch_and_persist_events)
    # ❗ No expectation needed for MeasurementDataService anymore — real call happens

    # Actually perform the job
    described_class.perform_now(date)

    # ✅ Optionally, you could also assert something about database if you want
    # For example:
    expect(ScadaMeasurementSource.count).to eq(2)
    expect(ScadaEvent.count).to be > 0 # if your fetch saves events!
  end
end
