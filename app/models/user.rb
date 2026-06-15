class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum :role, { user: 0, admin: 1 }, default: :user

  validates :email_address, presence: true, uniqueness: true
  validates :role, presence: true
end
