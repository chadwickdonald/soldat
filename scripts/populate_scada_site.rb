require 'csv'
require 'json'
# require 'active_record'
require_relative '../config/environment'

# Read the CSV file
csv_file_path = 'sites.csv'

CSV.foreach(csv_file_path, headers: true) do |row|
  # Parse the properties and enterprise fields
  properties_json = row['properties'].gsub('=>', ':').gsub('nil', 'null')
  enterprise_json = row['enterprise'].gsub('=>', ':').gsub('nil', 'null')
  
  # Parse the properties and enterprise fields
  properties = JSON.parse(properties_json)
  enterprise = JSON.parse(enterprise_json)

  org = ScadaOrganization.find(1)
  
  # Create a new ScadaSite record
  ScadaSite.create!(
    uuid: row['id'],
    site_id: row['id'],
    organization_id: org.id,
    name: row['name'],
    site_type_apcode: row['siteTypeApcode'],
    enterprise_name: enterprise['name'],
    enterprise_id: enterprise['id'],
    state: row['state'],
    timezone: properties['Timezone'],
    address: properties['Address'],
    longitude: properties['Longitude'],
    latitude: properties['Latitude'],
    test_results: properties['TestResults'],
    crmid: properties['CRMID'],
    type_of_project: properties['TypeOfProject'],
    number_of_controllers: properties['NumberOfControllers'],
    ac_load: properties['ACLoad'],
    cabins_designs: properties['CabinsDesigns'],
    rnoc_tests_end_date: properties['RNOCTestsEndDate'],
    address_zip_code: properties['AddressZIPCode'],
    activation_date: properties['ActivationDate'],
    power_source_provision: properties['PowerSourceProvision'],
    grid_connected: properties['GridConnected'],
    plant_designer: properties['PlantDesigner'],
    type_of_plant: properties['TypeOfPlant'],
    city: properties['City'],
    cabin_group: properties['CabinGroup'],
    plant_operator: properties['PlantOperator'],
    installation_implementor: properties['InstallationImplementor'],
    maintenance_contractor: properties['MaintenanceContractor'],
    country: properties['Country'],
    district: properties['District'],
    maintenance_date: properties['MaintenanceDate'],
    contract: properties['Contract'],
    telco_area: properties['TelcoArea'],
    odss_presence: properties['ODSSPresence'],
    dslam_code: properties['DSLAMCode'],
    odss_active: properties['ODSSActive'],
    related_market_site: properties['RelatedMarketSite'],
    information: properties['Information'],
    recording_period: properties['RecordingPeriod'],
    number_of_active_equipment: properties['NumberOfActiveEquipment'],
    market_timezone: properties['MarketTimezone'],
    admin_region: properties['AdminRegion'],
    tech_department: properties['TechDepartment'],
    cabin_vendor: properties['CabinVendor'],
    activation_date_nms: properties['ActivationDateNMS'],
    plant_installer: properties['PlantInstaller'],
    cabin_type: properties['CabinType'],
    cabin_kv_number: properties['CabinKVNumber'],
    portfolio: properties['Portfolio'],
    warranty_expiration_date: properties['WarrantyExpirationDate'],
    severity: properties['Severity'],
    typical_use: properties['TypicalUse'],
    rnoc_notification_date: properties['RNOCNotificationDate'],
    num_of_tcps: properties['NumOfTCPs'],
    serial: properties['Serial'],
    sub_types: properties['SubTypes'],
    dslam_network_ip_address: properties['DSLAMNetworkIPAddress'],
    address_street: properties['AddressStreet'],
    eett_code: properties['EETTCode'],
    available_calculation_periods: properties['AvailableCalculationPeriods'],
    altitude: properties['Altitude']
  )
end
