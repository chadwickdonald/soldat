require 'rails_helper'

RSpec.describe DataImport, type: :model do
  let(:user) { User.create!(email_address: "admin@test.com", password: "password") }

  def build_import(attrs = {})
    imp = DataImport.new({
      user:       user,
      start_date: "20250901T000000Z",
      end_date:   "20250908T000000Z",
      status:     :pending
    }.merge(attrs))
    imp.input_json.attach(
      io:           StringIO.new('{"023":[]}'),
      filename:     "test.json",
      content_type: "application/json"
    )
    imp
  end

  it "is valid with required fields" do
    expect(build_import).to be_valid
  end

  it "is invalid without start_date" do
    expect(build_import(start_date: nil)).not_to be_valid
  end

  it "is invalid without end_date" do
    expect(build_import(end_date: nil)).not_to be_valid
  end

  it "has pending status by default when set to 0" do
    imp = build_import(status: 0)
    expect(imp).to be_pending
  end

  it "transitions through statuses" do
    imp = build_import
    imp.save!
    imp.processing!
    expect(imp.reload).to be_processing
    imp.completed!
    expect(imp.reload).to be_completed
  end

  describe "#duration" do
    it "returns nil when not started" do
      expect(build_import.duration).to be_nil
    end

    it "returns elapsed seconds when both timestamps present" do
      imp = build_import
      imp.started_at   = 10.seconds.ago
      imp.completed_at = Time.current
      expect(imp.duration).to be_within(1).of(10)
    end
  end
end
