require 'rails_helper'

RSpec.describe "Pvsysts", type: :request do
  let(:user) { User.create!(email_address: "pvsyst_test@example.com", password: "password123!", role: :user) }

  # Minimum valid Project attributes — all presence-validated fields
  def project_attrs(overrides = {})
    {
      project:                      "Test.PRJ",
      pvsyst_version:               "v6.86",
      geographical_site:            "32.36  -83.77.SIT",
      meteo_data:                   "32.36  -83.77.MET",
      satelite_data:                "SUNY model;TMY",
      simulation_date:              Time.zone.parse("2024-01-01 00:00:00"),
      simulation_variant:           "Test.VC9",
      simulation_hourly_values_from: "from 01/01/90",
      simulation_hourly_values_to:   "to 31/12/90"
    }.merge(overrides)
  end

  before do
    post session_path, params: { email_address: user.email_address, password: "password123!" }
  end

  describe "GET /pvsysts" do
    context "with no projects" do
      it "renders the empty state without error" do
        get "/pvsysts"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("PVsyst Data")
      end
    end

    context "with a project that has no pvsysts" do
      before { Project.create!(project_attrs) }

      it "renders without error" do
        get "/pvsysts"
        expect(response).to have_http_status(:success)
      end
    end

    context "with lat/lng stored as degree-symbol strings" do
      before do
        project = Project.create!(project_attrs(project: "DegreeTest.PRJ"))
        project.pvsysts.create!(
          situation_latitude:  "32.35\xC2\xB0 N",
          situation_longitude: "83.77\xC2\xB0 W",
          country:             "United States"
        )
      end

      it "renders the location without raising a Float conversion error" do
        get "/pvsysts"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("32.35")
      end
    end

    context "with a decimal performance ratio" do
      before do
        project = Project.create!(project_attrs(project: "PRTest.PRJ"))
        project.pvsysts.create!(
          main_simulation_perf_ratio:      "0.8534",
          main_simulation_produced_energy: "1234567",
          main_simulation_specific_prod:   "1423"
        )
      end

      it "renders the performance ratio without a format string error" do
        get "/pvsysts"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("85.3%")
      end
    end

    context "with a fully populated pvsyst" do
      before do
        project = Project.create!(project_attrs(
          project:             "FullTest.PRJ",
          project_description: "Full Test Project",
          pvsyst_version:      "v7.2",
          simulation_date:     Time.zone.parse("2024-03-15 10:00:00")
        ))
        project.pvsysts.create!(
          situation_latitude:                 "32.35\xC2\xB0 N",
          situation_longitude:                "83.77\xC2\xB0 W",
          altitude:                           "120",
          country:                            "United States",
          time_zone:                          "UTC-5",
          tracking_algorithm:                 "1-Axis",
          number_of_trackers:                 "500",
          total_pv_modules:                   "3200",
          pv_module:                          "Q.PEAK DUO BLK ML-G10+/405W",
          inverter_model:                     "SMA Sunny Tripower 25000TL",
          main_simulation_perf_ratio:         "0.8421",
          main_simulation_produced_energy:    "8470000",
          main_simulation_specific_prod:      "1580",
          grid_power_limitation_active_power: "5000",
          power_factor_cos:                   "0.95"
        )
      end

      it "renders all stat boxes without error" do
        get "/pvsysts"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Full Test Project")
        expect(response.body).to include("1-Axis")
        expect(response.body).to include("3200")
        expect(response.body).to include("84.2%")
        expect(response.body).to include("Show all parameters")
      end

      it "shows module and inverter details in the collapsible section" do
        get "/pvsysts"
        expect(response.body).to include("Q.PEAK DUO BLK ML-G10+/405W")
        expect(response.body).to include("SMA Sunny Tripower 25000TL")
      end
    end
  end
end
