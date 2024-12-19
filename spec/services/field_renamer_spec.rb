require 'rails_helper'

RSpec.describe FieldRenamer, type: :class do
  describe '#call' do
    let(:data) do
      [
        'Ambient Temperature (1m)-MET.028-1m',
        'Power Inverter Module AC (1m)-Inverter module 079-1-1m',
        'PPC - Reactive power (1m)-PV PPC-1m',
        'Horizontal Irradiance (1m)-MET.067-1m',
        'Reflected Irradiance  (1m)-MET.081-1m',
        'Wind Speed (1m)-MET.028-1m'
      ]
    end

    let(:expected_results) do
      [
        {"Measurement Type"=>"Met and Enviro", "Engineering Unit"=>"deg C", "Station Type"=>"Met Station", "Station Id"=>"028"},
        {"Measurement Type"=>"PV Array", "Engineering Unit"=>nil, "Station Type"=>"PV Inverter station / PV Array", "Station Id"=>"079"},
        {"Measurement Type"=>"Power Quality / Substation / PPC / Controls", "Engineering Unit"=>"VAR / Phase Angle", "Station Type"=>nil},
        {"Measurement Type"=>"Met and Enviro", "Engineering Unit"=>"Watts/m^2", "Station Type"=>"Met Station", "Station Id"=>"067"},
        {"Measurement Type"=>"Met and Enviro", "Engineering Unit"=>"Watts/m^2", "Station Type"=>"Met Station", "Station Id"=>"081"},
        {}
      ]
    end

    it 'categorizes each data field correctly based on rules' do
      data.each_with_index do |field_name, index|
        renamer = described_class.new({ 'Field Name' => field_name })
        result = renamer.call
        expect(result).to eq(expected_results[index])
      end
    end
  end
end
