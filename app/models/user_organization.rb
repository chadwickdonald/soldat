class UserOrganization < ApplicationRecord
  belongs_to :user
  belongs_to :scada_organization

  validates :user_id, uniqueness: { scope: :scada_organization_id,
                                    message: "is already associated with that organization" }
end
