class DataImport < ApplicationRecord
  belongs_to :user

  has_one_attached :input_json
  has_one_attached :csv_5m
  has_one_attached :csv_1m

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :start_date, :end_date, presence: true
  validates :input_json, presence: true

  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end
end
