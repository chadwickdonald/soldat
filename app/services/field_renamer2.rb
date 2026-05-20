class FieldRenamer2
  
  MEASUREMENT_TYPE = {
    pmp: 'Power Measurement Parameter',
    pva: 'PV Array',
    ess: 'Energy Storage System (ESS)',
    met: 'Met and Enviro',
    ppc: 'Power Quality / Substation / PPC / Controls'
  }.freeze

  ENG_UNIT = {
    watt: 'W / kW / MW',
    wm2: 'Watts/m^2',
    deg: 'deg C',
    volt: 'Volts',
    amp:  'Amps',
    kva:  'kVA',
    var:  'VAR / Phase Angle',
    na:   nil
  }.freeze

  STATION_TYPE = {
    meter: 'Main Meter',
    pv:    'PV Inverter station / PV Array',
    met:   'Met Station',
    ppc:   'Power Plant Controller',
    na:    nil
  }.freeze

  STATION_NUMBER = { yes: true, no: false }.freeze

  # Keep your rules but normalize to regex => tuple.
  RULES = {
    ['W', 'KW', 'kW', 'MW', 'kilowatt', 'Watt', 'Megawatt']                 => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na],   STATION_NUMBER[:no]],
    ['meter', 'main power', 'revenue', ' P ']                                => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:na],   STATION_TYPE[:meter], STATION_NUMBER[:no]],
    ['AC kW', 'MW', 'Watts']                                                 => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na],   STATION_NUMBER[:yes]],
    ['DC kW', 'DC MW', 'DC Watts']                                           => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:watt], STATION_TYPE[:na],   STATION_NUMBER[:no]],
    ['inverter', 'inv', 'PV', 'solar', 'station', 'pad']                    => [MEASUREMENT_TYPE[:pva], ENG_UNIT[:na],   STATION_TYPE[:pv],   STATION_NUMBER[:yes]],
    ['PCS', 'Battery', 'ESS', 'Storage', 'EMS']                             => [MEASUREMENT_TYPE[:ess], ENG_UNIT[:na],   STATION_TYPE[:na],   STATION_NUMBER[:yes]],
    ['Irr', 'irradiance', 'W/m2', 'insolation']                             => [MEASUREMENT_TYPE[:met], ENG_UNIT[:wm2],  STATION_TYPE[:met],  STATION_NUMBER[:yes]],
    ['Temp', 'temperature', 'deg', 'deg C', 'deg F']                        => [MEASUREMENT_TYPE[:met], ENG_UNIT[:deg],  STATION_TYPE[:met],  STATION_NUMBER[:yes]],
    ['PPC', 'Controller', 'Power Control', 'Plant Controller', 'Set Point'] => [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:na],   STATION_TYPE[:ppc],  STATION_NUMBER[:no]],
    ['V', 'Volts', 'kV', 'MV']                                              => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:volt], STATION_TYPE[:na],   STATION_NUMBER[:no]],
    ['A', 'amps', 'amperage']                                                => [MEASUREMENT_TYPE[:pmp], ENG_UNIT[:amp],  STATION_TYPE[:na],   STATION_NUMBER[:no]],
    ['VA', 'kVA', 'MVA', 'apparent', 'app']                                 => [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:kva],  STATION_TYPE[:na],   STATION_NUMBER[:no]],
    ['VAR', 'kVAR', 'MVAR', 'reactive', 'react power', ' Q ']              => [MEASUREMENT_TYPE[:ppc], ENG_UNIT[:var],  STATION_TYPE[:na],   STATION_NUMBER[:no]]
  }.freeze

  # Precompile case-insensitive regexes once
  COMPILED_RULES = RULES.map do |keywords, payload|
    # \b around words where it makes sense; keep odd tokens like " Q " literal.
    escaped = keywords.map { |k| Regexp.escape(k.strip) }
    [Regexp.new("(?:#{escaped.join('|')})", Regexp::IGNORECASE), payload]
  end.freeze

  # -------- Public API --------

  # Convenience: process one ScadaMeasurement
  def self.call(measurement)
    new(measurement).call
  end

  # Convenience: process many in batches
  # scope: ActiveRecord::Relation of ScadaMeasurement
  def self.bulk(scope, batch_size: 1000, dry_run: false, upsert: true)
    scope.in_batches(of: batch_size) do |relation|
      rows = []

      relation.each do |m|
        hash = new(m).call
        next if hash.blank?

        rows << {
          scada_measurement_id: m.id,
          enthasys_id: nil,
          measurement_type: hash['Measurement Type'],
          engineering_unit: hash['Engineering Unit'],
          station_type:     hash['Station Type'],
          station_id:       hash['Station Id'],
          created_at: Time.current, updated_at: Time.current
        }
      end

      next if rows.empty?

      if dry_run
        # Let caller inspect what would be written
        yield rows if block_given?
      else
        if upsert
          FieldAlias.upsert_all(
            rows,
            unique_by: :index_field_aliases_on_scada_measurement_id # define this unique index
          )
        else
          FieldAlias.insert_all(rows)
        end
      end
    end
  end

  # -------- Instance --------

  def initialize(measurement_or_hash)
    # Support either a ScadaMeasurement or a raw hash { 'Field Name' => ... }
    @measurement = measurement_or_hash if measurement_or_hash.respond_to?(:attributes)
    # @data = if @measurement
    if @measurement
      # { 'Field Name' => @measurement.try(:name).to_s.presence || @measurement.try(:field_name).to_s }
      @data = { 'Field Name' => "#{@measurement.name.to_s},#{@measurement.apcode.to_s},#{@measurement.monitor_eng_unit.to_s}"}
      # puts "---@data: #{@data.inspect}"
    # else
    #   measurement_or_hash
    end
  end

  def call
    categorized = categorize_field(@data['Field Name'].to_s)
    return {} if categorized.empty?

    # Persist if we were constructed with an AR record
    create_field_alias(@measurement, categorized) if @measurement
    categorized
  end

  private

  def extract_number(str)
    # first 1–3 digit number not part of a trailing 'm' token; zero-pad to 3
    num = str.to_s.match(/\b(\d{1,3})(?!m)\b/i)&.[](1)
    num&.rjust(3, '0')
  end

  # pure function that categorizes a single field name
  def categorize_field(field_name)
    return {} if field_name.blank?

    COMPILED_RULES.each do |regex, (mtype, eunit, stype, needs_station_num)|
      if field_name =~ regex
        h = {
          'Measurement Type' => mtype,
          'Engineering Unit' => eunit,
          'Station Type'     => stype
        }
        h['Station Id'] = extract_number(field_name) if needs_station_num
        return h
      end
    end
    {}
  end

  def create_field_alias(measurement, categorized_data)
    return unless measurement

    FieldAlias.create!(
      scada_measurement: measurement,
      enthasys_id: nil,
      measurement_type:  categorized_data['Measurement Type'],
      engineering_unit:  categorized_data['Engineering Unit'],
      station_type:      categorized_data['Station Type'],
      station_id:        categorized_data['Station Id']
    )
  end
end


# # One record
# FieldRenamer.call(ScadaMeasurement.find(123))

# # Whole site, dry run to inspect

# FieldRenamer.bulk(
#   ScadaMeasurement.where(site_id: site.uuid),
#   batch_size: 2_000,
#   dry_run: true
# ) { |rows| puts rows.first(5).inspect }

# # Whole site, upsert into FieldAliases keyed by scada_measurement_id
# FieldRenamer.bulk(ScadaMeasurement.where(site_id: site.uuid))




