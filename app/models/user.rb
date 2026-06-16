class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_organizations, dependent: :destroy
  has_many :scada_organizations, through: :user_organizations
  belongs_to :current_scada_site, class_name: 'ScadaSite', optional: true

  def available_scada_sites
    ScadaSite.joins(scada_organization: :user_organizations)
             .where(user_organizations: { user_id: id })
             .order('scada_organizations.name', 'scada_sites.name')
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { user: 0, admin: 1 }, default: :user

  validates :email_address, presence: true, uniqueness: true
  validates :role, presence: true
end
