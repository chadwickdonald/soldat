require 'rails_helper'

RSpec.describe StationIdExtractor do
  describe ".call" do
    # User-confirmed examples
    it "preserves leading zeros on a purely numeric trailing token" do
      expect(described_class.call("Solar Inverter Block 089")).to eq("089")
    end

    it "returns an alphanumeric identifier with dots as-is" do
      expect(described_class.call("Battery String 32A1.BESS.10B.S3")).to eq("32A1.BESS.10B.S3")
    end

    it "returns a hyphenated alphanumeric identifier as-is" do
      expect(described_class.call("Tracker TCU-080-072")).to eq("TCU-080-072")
    end

    it "extracts digits from an ALPHA.DIGITS token, preserving leading zeros" do
      expect(described_class.call("MET.028")).to eq("028")
    end

    it "returns a hyphenated numeric identifier as-is" do
      expect(described_class.call("Something 20-1")).to eq("20-1")
    end

    # Numeric edge cases
    it "preserves leading zeros on a zero-padded number" do
      expect(described_class.call("Inverter Block 001")).to eq("001")
    end

    it "returns a number without leading zeros as-is" do
      expect(described_class.call("Block 100")).to eq("100")
    end

    it "handles a three-digit number" do
      expect(described_class.call("Solar Inverter Block 123")).to eq("123")
    end

    # ALPHA.DIGITS edge cases
    it "does not apply ALPHA.DIGITS rule when suffix is not purely numeric" do
      expect(described_class.call("Battery String 32A1.BESS.10B.S3")).to eq("32A1.BESS.10B.S3")
    end

    it "does not apply ALPHA.DIGITS rule when prefix contains digits" do
      expect(described_class.call("Tracker TCU-080-072")).to eq("TCU-080-072")
    end

    # Nil / blank
    it "returns nil for nil input" do
      expect(described_class.call(nil)).to be_nil
    end

    it "returns nil for an empty string" do
      expect(described_class.call("")).to be_nil
    end

    it "returns nil when the segment name contains only alphabetic words" do
      expect(described_class.call("Met Station")).to be_nil
    end

    it "returns nil for a single alphabetic word" do
      expect(described_class.call("Inverter")).to be_nil
    end

    it "uses the LAST non-alpha token, not an earlier one" do
      expect(described_class.call("Site 1 Block 089")).to eq("089")
    end
  end
end
