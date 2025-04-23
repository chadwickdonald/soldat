class ScadaMloc < ApplicationRecord
  has_many :scada_measurements, primary_key: 'uuid', foreign_key: 'mloc_id'
  belongs_to :scada_segment, primary_key: 'uuid', foreign_key: 'segment_id'

  def self.persist_from_pf(mloc_data, segment_id)

    uuid = mloc_data['id']

    return if exists?(uuid: uuid)

    create!(
      uuid: uuid,
      segment_id: segment_id,
      apcode: mloc_data['apcode'],
      name: mloc_data['name'],
      sscode: mloc_data['sscode'],
      uri: mloc_data['uri'],
      measurementTypeId: mloc_data['measurementTypeId']
    )
  end
end