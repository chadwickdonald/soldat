# spec/integration/export_events_reshaped_spec.rb
# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "open3"
require "csv"

RSpec.describe "export_events_reshaped.rb (integration)" do
  # Adjust this to the actual location of the script in your repo.
  SCRIPT_SRC = File.expand_path("../../bin/export_events_reshaped.rb", __dir__)

  def write_fake_environment(path)
    # Defines all classes/methods the script calls so we don't need a real Rails app.
    FileUtils.mkdir_p(File.join(path, "config"))
    File.write(File.join(path, "config", "environment.rb"), <<~RUBY)
      require "ostruct"
      # ---- ActiveRecord-like stubs ----
      class ScadaSite
        def self.find_by_name(name)
          OpenStruct.new(uuid: "site-uuid-123")
        end
      end

      class ScadaSegment
        attr_reader :apcode, :name
        def initialize(apcode:, name:)
          @apcode = apcode
          @name = name
        end
        def self.where(apcode:, name:)
          [new(apcode: apcode, name: name)]
        end
        def scada_mlocs
          Class.new do
            def where(apcode:)
              [OpenStruct.new(scada_measurements: [ScadaMeasurement.new])]
            end
          end.new
        end
      end

      class ScadaMeasurement
        attr_reader :id, :apcode, :name
        def initialize
          @id = 42
          @apcode = "ML1"
          @name = "Active Power"
        end
        def scada_measurement_sources
          Class.new do
            def where(calc_period:)
              [OpenStruct.new(uuid: "source-uuid-1", calc_period: calc_period, eng_unit: "kW")]
            end
          end.new
        end
      end

      class FieldAlias
        attr_reader :relevance, :station_type, :station_id, :measurement_type
        def initialize(attrs)
          @relevance = attrs[:relevance]
          @station_type = attrs[:station_type]
          @station_id = attrs[:station_id]
          @measurement_type = attrs[:measurement_type]
        end
        def self.find_by_scada_measurement_id(_id) = nil
        def self.create(attrs) = new(attrs)
      end

      module Pf
        class EventDataService2
          def initialize(_api_key); end
          def fetch_and_persist_events(start_date:, end_date:, source_uuid:, measurement_apcode:, site_id:, cp_name:)
            # Build two series: if calc period is "1m" emit 1-minute data;
            # if it's "5m" emit 5-minute data. Dates are UTC "YYYYmmddTHHMMSSZ".
            base = Time.utc(2025, 9, 1, 1, 0, 0)
            step = (cp_name.to_s == "5m") ? 300 : 60
            5.times.map { |i|
              t = (base + i * step).strftime("%Y%m%dT%H%M%SZ")
              { "date" => t, "val" => (i * 10.0).round(1).to_s }
            }
          end
        end
      end
    RUBY
  end

  def write_script_copy(tmp_root)
    # Place the script where it expects ../../config/environment relative to itself.
    bin_dir = File.join(tmp_root, "bin")
    FileUtils.mkdir_p(bin_dir)
    FileUtils.cp(SCRIPT_SRC, File.join(bin_dir, "export_events_reshaped.rb"))
  end

  def write_stations_json(path, calc_period:)
    payload = {
      "1" => [
        {
          segment_apcode: "SEG1",
          segment_name: "Segment A",
          mloc_apcode: "ML1",
          source_calc_period: calc_period, # "1m" or "5m"
          station_type: "PVGEN",
          station_element: "ACPWR",
          station_id: "G1",
          relevance: "primary"
        }
      ]
    }
    File.write(path, JSON.pretty_generate(payload))
  end

  def run_script(tmp_root, stations, out1, out5, others: nil)
    env = { "SCADA_API_KEY" => "fake-key" }
    cmd = ["ruby", File.join(tmp_root, "bin", "export_events_reshaped.rb"), stations, out1, out5]
    if others
      cmd += ["--others", others]
    end
    Open3.capture3(env, *cmd)
  end

  it "writes a reshaped 1m CSV with metadata + time grid, and does not write 5m when no 5m series" do
    Dir.mktmpdir("reshaped_1m") do |dir|
      write_fake_environment(dir)
      write_script_copy(dir)

      stations = File.join(dir, "stations.json")
      out1     = File.join(dir, "out_1m.csv")
      out5     = File.join(dir, "out_5m.csv")
      write_stations_json(stations, calc_period: "1m")

      stdout, stderr, status = run_script(dir, stations, out1, out5)
      expect(status.exitstatus).to eq(0), "STDERR:\n#{stderr}\nSTDOUT:\n#{stdout}"

      # 1m file exists
      expect(File).to exist(out1)
      # 5m file should not exist (no 5m keys)
      expect(File).not_to exist(out5)

      rows = CSV.read(out1)
      # Header row should start with "variable"
      expect(rows.first.first).to eq("variable")

      # Metadata block should include expected rows
      meta_keys = rows[1..10].map(&:first) # next ~10 lines are meta vars
      expect(meta_keys).to include("segment_apcode", "segment_name", "mloc_apcode", "source_calc_period", "measurement_name", "eng_unit", "station_type", "station_element", "station_id", "relevance")

      # Find "time" row index
      time_row_idx = rows.index { |r| r[0] == "time" }
      expect(time_row_idx).to be > 10

      # We generated 5 timestamps; check 5 following rows are time/value lines
      time_values = rows[(time_row_idx + 1)..(time_row_idx + 5)]
      expect(time_values.size).to eq(5)
      # Each time row has 2+ columns: time in col 0, single series value in col 1
      time_values.each_with_index do |r, i|
        expect(r[0]).to match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/)
        expect(r[1]).to eq((i * 10.0).round(1).to_s)
      end
    end
  end

  it "writes a reshaped 5m CSV when calc period is 5m" do
    Dir.mktmpdir("reshaped_5m") do |dir|
      write_fake_environment(dir)
      write_script_copy(dir)

      stations = File.join(dir, "stations.json")
      out1     = File.join(dir, "out_1m.csv")
      out5     = File.join(dir, "out_5m.csv")
      write_stations_json(stations, calc_period: "5m")

      stdout, stderr, status = run_script(dir, stations, out1, out5)
      expect(status.exitstatus).to eq(0), "STDERR:\n#{stderr}\nSTDOUT:\n#{stdout}"

      # 5m file exists
      expect(File).to exist(out5)
      # 1m file should not exist (no 1m keys)
      expect(File).not_to exist(out1)

      rows = CSV.read(out5)
      expect(rows.first.first).to eq("variable")

      time_row_idx = rows.index { |r| r[0] == "time" }
      expect(time_row_idx).to be > 10
      time_values = rows[(time_row_idx + 1)..(time_row_idx + 5)]
      expect(time_values.size).to eq(5)
    end
  end

  it "optionally writes an 'others' CSV when a non-1m/5m period is present" do
    Dir.mktmpdir("reshaped_others") do |dir|
      write_fake_environment(dir)

      # Patch the fake PF service to emit 2m cadence when calc_period is "2m"
      File.open(File.join(dir, "config", "environment.rb"), "a") do |f|
        f.puts <<~RUBY
          module Pf
            class EventDataService2
              alias __orig_fetch_and_persist_events fetch_and_persist_events
              def fetch_and_persist_events(**kwargs)
                if kwargs[:cp_name].to_s == "2m"
                  base = Time.utc(2025, 9, 1, 1, 0, 0)
                  5.times.map { |i|
                    t = (base + i * 120).strftime("%Y%m%dT%H%M%SZ")
                    { "date" => t, "val" => (i * 7.5).round(1).to_s }
                  }
                else
                  __orig_fetch_and_persist_events(**kwargs)
                end
              end
            end
          end
        RUBY
      end

      write_script_copy(dir)

      stations = File.join(dir, "stations.json")
      out1     = File.join(dir, "out_1m.csv")
      out5     = File.join(dir, "out_5m.csv")
      others   = File.join(dir, "out_other.csv")

      # Create a "2m" series
      payload = { "1" => [ { segment_apcode: "SEG2", segment_name: "Seg B", mloc_apcode: "ML1",
                             source_calc_period: "2m", station_type: "PVGEN",
                             station_element: "ACPWR", station_id: "G2", relevance: "primary" } ] }
      File.write(stations, JSON.pretty_generate(payload))

      stdout, stderr, status = run_script(dir, stations, out1, out5, others: others)
      expect(status.exitstatus).to eq(0), "STDERR:\n#{stderr}\nSTDOUT:\n#{stdout}"

      expect(File).to exist(others)
      rows = CSV.read(others)
      expect(rows.first.first).to eq("variable")
      # Should show source_calc_period row equal to "2m"
      scp_row = rows.find { |r| r[0] == "source_calc_period" }
      expect(scp_row&.last).to eq("2m")
    end
  end
end
