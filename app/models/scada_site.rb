class ScadaSite < ApplicationRecord
  has_many :scada_segments, primary_key: 'uuid', foreign_key: 'site_id'
  belongs_to :scada_organization, primary_key: 'id', foreign_key: 'organization_id'

  def self.persist_from_pf(site_data)
    uuid = site_data['id']
    return if exists?(uuid: uuid)

    props = site_data['properties'] || {}
    enterprise = site_data['enterprise'] || {}

    create!(
        uuid: uuid,
        site_id: uuid,
        organization_id: 1,
        name: site_data['name'],
        site_type_apcode: site_data['siteTypeApcode'],
        enterprise_name: enterprise['name'],
        enterprise_id: enterprise['id'],
        state: site_data['state'],
        timezone: props['Timezone'],
        address: props['Address'],
        longitude: props['Longitude'],
        latitude: props['Latitude'],
        test_results: props['TestResults'],
        crmid: props['CRMID'],
        type_of_project: props['TypeOfProject'],
        number_of_controllers: props['NumberOfControllers'],
        ac_load: props['ACLoad'],
        cabins_designs: props['CabinsDesigns'],
        rnoc_tests_end_date: props['RNOCTestsEndDate'],
        address_zip_code: props['AddressZIPCode'],
        activation_date: props['ActivationDate'],
        power_source_provision: props['PowerSourceProvision'],
        grid_connected: props['GridConnected'],
        plant_designer: props['PlantDesigner'],
        type_of_plant: props['TypeOfPlant'],
        city: props['City'],
        cabin_group: props['CabinGroup'],
        plant_operator: props['PlantOperator'],
        installation_implementor: props['InstallationImplementor'],
        maintenance_contractor: props['MaintenanceContractor'],
        country: props['Country'],
        district: props['District'],
        maintenance_date: props['MaintenanceDate'],
        contract: props['Contract'],
        telco_area: props['TelcoArea'],
        odss_presence: props['ODSSPresence'],
        dslam_code: props['DSLAMCode'],
        odss_active: props['ODSSActive'],
        related_market_site: props['RelatedMarketSite'],
        information: props['Information'],
        recording_period: props['RecordingPeriod'],
        number_of_active_equipment: props['NumberOfActiveEquipment'],
        market_timezone: props['MarketTimezone'],
        admin_region: props['AdminRegion'],
        tech_department: props['TechDepartment'],
        cabin_vendor: props['CabinVendor'],
        activation_date_nms: props['ActivationDateNMS'],
        plant_installer: props['PlantInstaller'],
        cabin_type: props['CabinType'],
        cabin_kv_number: props['CabinKVNumber'],
        portfolio: props['Portfolio'],
        warranty_expiration_date: props['WarrantyExpirationDate'],
        severity: props['Severity'],
        typical_use: props['TypicalUse'],
        rnoc_notification_date: props['RNOCNotificationDate'],
        num_of_tcps: props['NumOfTCPs'],
        serial: props['Serial'],
        sub_types: props['SubTypes'],
        dslam_network_ip_address: props['DSLAMNetworkIPAddress'],
        address_street: props['AddressStreet'],
        eett_code: props['EETTCode'],
        available_calculation_periods: props['AvailableCalculationPeriods'],
        altitude: props['Altitude']
      )
  end
end