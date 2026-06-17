require 'rails_helper'

RSpec.describe "EventsChart", type: :request do
  let(:user) { User.create!(email_address: "chart_test@example.com", password: "password123!", role: :user) }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123!" }
  end

  # Build the full SCADA join chain needed by EventsChartController
  def build_scada_chain(site_uuid:, calc_period: "5m", measurement_type: "Power Output")
    org  = ScadaOrganization.create!(uuid: SecureRandom.uuid, name: "Test Org #{SecureRandom.hex(4)}")
    site = ScadaSite.create!(
      uuid: site_uuid, site_id: site_uuid, organization_id: org.id,
      name: "Test Site"
    )
    seg  = ScadaSegment.create!(uuid: SecureRandom.uuid, site_id: site_uuid, name: "Seg A", apcode: "SEG001")
    mloc = ScadaMloc.create!(uuid: SecureRandom.uuid, segment_id: seg.uuid, name: "MLOC A", apcode: "ML001")
    meas = ScadaMeasurement.create!(
      uuid: SecureRandom.uuid, mloc_id: mloc.uuid, apcode: "PWROUT",
      name: "ArrayOutputPower", segment_id: seg.uuid,
      segment_apcode: seg.apcode, segment_name: seg.name
    )
    fa = FieldAlias.create!(
      scada_measurement_id: meas.id, measurement_type: measurement_type,
      station_type: "Inverter", station_id: "001", relevance: :high_priority
    )
    source = ScadaMeasurementSource.create!(
      uuid: SecureRandom.uuid, scada_measurement_id: meas.id,
      calc_period: calc_period, eng_unit: "kW"
    )
    { site: site, source: source, measurement: meas, field_alias: fa }
  end

  def add_events(source, timestamps_and_vals)
    timestamps_and_vals.each do |ts, val|
      ScadaEvent.create!(
        measurement_source_id: source.uuid,
        date: ts, val: val,
        site_id: SecureRandom.uuid
      )
    end
  end

  # ── GET /events_chart ────────────────────────────────────────────────────────

  describe "GET /events_chart" do
    it "renders the page successfully" do
      get "/events_chart"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Events Visualization")
    end

    it "includes the period toggle buttons" do
      get "/events_chart"
      expect(response.body).to include("5m")
      expect(response.body).to include("1m")
    end

    it "includes the Plot button" do
      get "/events_chart"
      expect(response.body).to include("Plot")
    end

    it "requires authentication" do
      delete session_path
      get "/events_chart"
      expect(response).to redirect_to(new_session_path)
    end
  end

  # ── GET /events_chart/sources ────────────────────────────────────────────────

  describe "GET /events_chart/sources" do
    context "without a selected site" do
      it "returns JSON array" do
        get "/events_chart/sources", params: { period: "5m", q: "power" }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)).to be_an(Array)
      end

      it "returns empty array for queries shorter than 2 characters" do
        get "/events_chart/sources", params: { period: "5m", q: "p" }
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context "with a selected site" do
      let(:site_uuid) { SecureRandom.uuid }

      before do
        chain = build_scada_chain(site_uuid: site_uuid, calc_period: "5m",
                                  measurement_type: "Power Output Metric")
        user.update!(current_scada_site: chain[:site])
      end

      it "returns sources matching the search query" do
        get "/events_chart/sources", params: { period: "5m", q: "power" }
        results = JSON.parse(response.body)
        expect(results).not_to be_empty
        expect(results.first).to include("value", "text", "subtext", "eng_unit")
      end

      it "returns sources for the correct period" do
        build_scada_chain(site_uuid: site_uuid, calc_period: "1m",
                          measurement_type: "1min Power")
        get "/events_chart/sources", params: { period: "5m", q: "power" }
        results = JSON.parse(response.body)
        expect(results.map { |r| r["text"] }).not_to include(match(/1min/))
      end

      it "returns no results when query does not match" do
        get "/events_chart/sources", params: { period: "5m", q: "zzznomatch" }
        expect(JSON.parse(response.body)).to be_empty
      end

      it "defaults to 5m when period param is missing" do
        get "/events_chart/sources", params: { q: "power" }
        expect(response).to have_http_status(:success)
      end

      it "ignores invalid period values and defaults to 5m" do
        get "/events_chart/sources", params: { period: "bad", q: "power" }
        expect(response).to have_http_status(:success)
      end
    end
  end

  # ── GET /events_chart/data ───────────────────────────────────────────────────

  describe "GET /events_chart/data" do
    it "returns bad_request when uuid is missing" do
      get "/events_chart/data", params: { start_date: "2025-09-01", end_date: "2025-09-08" }
      expect(response).to have_http_status(:bad_request)
    end

    context "with a site and source" do
      let(:site_uuid) { SecureRandom.uuid }
      let!(:chain)    { build_scada_chain(site_uuid: site_uuid, calc_period: "5m") }

      before do
        user.update!(current_scada_site: chain[:site])
        add_events(chain[:source], [
          [Time.zone.parse("2025-09-02T08:00:00Z"), 123.4],
          [Time.zone.parse("2025-09-02T08:05:00Z"), 130.1],
          [Time.zone.parse("2025-09-02T08:10:00Z"), 128.7]
        ])
      end

      it "returns event data as JSON with expected keys" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "2025-09-01",
          end_date:   "2025-09-08"
        }
        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)
        expect(body).to include("points", "label", "eng_unit", "period", "count")
      end

      it "returns the correct number of points" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "2025-09-01",
          end_date:   "2025-09-08"
        }
        body = JSON.parse(response.body)
        expect(body["count"]).to eq(3)
        expect(body["points"].length).to eq(3)
      end

      it "returns points as [timestamp_ms, value] pairs" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "2025-09-01",
          end_date:   "2025-09-08"
        }
        points = JSON.parse(response.body)["points"]
        points.each do |point|
          expect(point.length).to eq(2)
          expect(point[0]).to be_a(Integer)
          expect(point[1]).to be_a(Float)
        end
      end

      it "returns zero points when date range has no matching events" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "2024-01-01",
          end_date:   "2024-01-07"
        }
        body = JSON.parse(response.body)
        expect(body["count"]).to eq(0)
        expect(body["points"]).to be_empty
      end

      it "returns not_found for a uuid that belongs to a different site" do
        other_chain = build_scada_chain(site_uuid: SecureRandom.uuid, calc_period: "5m")
        get "/events_chart/data", params: {
          uuid:       other_chain[:source].uuid,
          start_date: "2025-09-01",
          end_date:   "2025-09-08"
        }
        expect(response).to have_http_status(:not_found)
      end

      it "returns bad_request for invalid date strings" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "not-a-date",
          end_date:   "also-bad"
        }
        expect(response).to have_http_status(:bad_request)
      end

      it "includes the engineering unit in the response" do
        get "/events_chart/data", params: {
          uuid:       chain[:source].uuid,
          start_date: "2025-09-01",
          end_date:   "2025-09-08"
        }
        expect(JSON.parse(response.body)["eng_unit"]).to eq("kW")
      end
    end
  end
end
