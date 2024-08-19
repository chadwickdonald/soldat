
import json
import csv
import sys

def extract_unique_apcodes(json_file, output_file):
    # Read JSON file
    with open(json_file) as f:
        data = json.load(f)

    # Extract unique 'apcode' values
    unique_apcodes = set(item['measurementApcode'] for item in data)

    # Write unique 'apcode' values to CSV file
    with open(output_file, 'w', newline='') as csvfile:
        fieldnames = ['measurementApcode']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for apcode in unique_apcodes:
            writer.writerow({'measurementApcode': apcode})

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <json_file> <output_file>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    output_file = sys.argv[2]
    extract_unique_apcodes(json_file, output_file)


# {"AmbientAirTemperatureTr2"=>5759,
#  "ArrayOutputPowerTr2"=>151185,
#  "InclIrradianceTr2"=>5759,
#  "ModuleTemperature1Tr2"=>2879,
#  "ModuleTemperature2Tr2"=>4319,
#  "ModuleTemperature3Tr2"=>4319,
#  "PPCActivePowerTr2"=>1440,
#  "PPCTotalPowerFactorTr2"=>1440,
#  "SecInclIrradianceTr2"=>5759}



["AmbientAirTemperature",
"ArrayOutputPower",
"HorizIrradiance",
"HorizIrradianceTr2",
"InclIrradiance",
"ModuleTemperature1",
"ModuleTemperature2",
"ModuleTemperature3",
"PPCActivePower",
"PPCFrequencyF",
"PPCFrequencyFTr2",
"PPCLineVoltage",
"PPCLineVoltageTr2",
"PPCReactivePower",
"PPCReactivePowerTr2",
"PPCTotalPowerFactor",
"ReflIrradiance",
"ReflIrradianceTr2",
"SecInclIrradiance",
"WindSpeed",
"WindSpeedTr2"]








