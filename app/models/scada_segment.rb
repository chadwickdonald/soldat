class ScadaSegment < ApplicationRecord
  has_many :scada_mlocs, primary_key: 'uuid', foreign_key: 'segment_id'
  has_many :scada_state_variables, primary_key: 'uuid', foreign_key: 'segment_id'
  belongs_to :scada_site, primary_key: 'uuid', foreign_key: 'site_id'

  def self.persist_from_pf(segment_data, site_id)
    uuid = segment_data['id']
    return if exists?(uuid: uuid)

    create!(
      uuid: uuid,
      site_id: site_id,
      apcode: segment_data['apcode'],
      uri: segment_data['uri'],
      name: segment_data['name'],
      apcode_idx: segment_data['apcode_idx']
    )
  end
end
