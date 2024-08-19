require 'json'

# Load JSON data
data = JSON.parse('
{
    "apcode": "ArrayOutputPowerTr2",
    "id": "4e6418a8-8855-11ee-a4ff-42010afa015a",
    "measureType": {
        "apcode": "Power",
        "dataType": "Float",
        "id": "3074ed0e-8264-11de-ad55-0090f586a869",
        "name": "Power",
        "uri": "http://portal.solarpark-online.com/ifms/measureTypes/3074ed0e-8264-11de-ad55-0090f586a869"
    },
    "monitor": null,
    "name": "Power Inverter Module AC (1m)",
    "rcv": false,
    "segment": {
        "apcode": "InverterModule",
        "apcode_idx": 70,
        "id": "b13245c8-8854-11ee-a4ff-42010afa015a",
        "name": "Inverter module 071-2",
        "uri": "http://portal.solarpark-online.com/ifms/segments/b13245c8-8854-11ee-a4ff-42010afa015a"
    },
    "sources": [
        {
            "calcPeriod": "1m",
            "calcTimeSpanCount": 1,
            "calcTimeSpanMode": "fixed-time-span",
            "check": null,
            "date": "20240418T174100Z",
            "engUnit": "kW",
            "id": "4e641b5a-8855-11ee-a4ff-42010afa015a",
            "manualIngest": false,
            "quality": null,
            "range": null,
            "uri": "http://portal.solarpark-online.com/ifms/sources/4e641b5a-8855-11ee-a4ff-42010afa015a",
            "val": "1242.8980712890625",
            "calcTypeApcode": "TimeSeriesAverage"
        }
    ],
    "siteId": "25658d43-0ffd-42b4-a4e4-d3b808e85087"
}')

# Create or find measure type
scada_measure_type = ScadaMeasureType.find_or_create_by(id: data['measureType']['id']) do |mt|
  mt.name = data['measureType']['name']
  mt.dataType = data['measureType']['dataType']
  mt.uri = data['measureType']['uri']
  mt.apcode = data['measureType']['apcode']
end

# Create or find segment
scada_segment = ScadaSegment.find_or_create_by(id: data['segment']['id']) do |s|
  s.name = data['segment']['name']
  s.uri = data['segment']['uri']
  s.apcode = data['segment']['apcode']
  s.apcode_idx = data['segment']['apcode_idx']
end

# Create sources
data['sources'].each do |source_data|
  scada_source = ScadaSource.find_or_create_by(id: source_data['id']) do |s|
    s.calc_period = source_data['calcPeriod']
    s.calc_time_span_count = source_data['calcTimeSpanCount']
    s.calc_time_span_mode = source_data['calcTimeSpanMode']
    s.date = DateTime.parse(source_data['date'])
    s.eng_unit = source_data['engUnit']
    s.manual_ingest = source_data['manualIngest']
    s.val = source_data['val'].to_f
    s.calc_type_apcode = source_data['calcTypeApcode']
    s.scada_measure_type = scada_measure_type
    s.scada_segment = scada_segment
  end
end