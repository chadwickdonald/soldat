import json
import csv
import sys

def extract_unique_apcodes(json_file, output_file):
    # Read JSON file
    with open(json_file) as f:
        data = json.load(f)

    # Extract unique 'apcode' values
    unique_apcodes = set(item['apcode'] for item in data)

    # Write unique 'apcode' values to CSV file
    with open(output_file, 'w', newline='') as csvfile:
        fieldnames = ['apcode']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for apcode in unique_apcodes:
            writer.writerow({'apcode': apcode})

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <json_file> <output_file>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    output_file = sys.argv[2]
    extract_unique_apcodes(json_file, output_file)