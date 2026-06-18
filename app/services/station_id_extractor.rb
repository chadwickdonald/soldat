module StationIdExtractor
  # Extracts a station identifier from a SCADA segment name.
  #
  # Rules:
  #   1. Find the last whitespace-delimited token containing a non-alpha character.
  #   2. If that token matches LETTERS.DIGITS (e.g. "MET.028"), return just the
  #      digits, preserving leading zeros.
  #   3. Otherwise return the token as-is (leading zeros preserved).
  #
  # Examples:
  #   "Solar Inverter Block 089"         => "089"
  #   "Battery String 32A1.BESS.10B.S3"  => "32A1.BESS.10B.S3"
  #   "Tracker TCU-080-072"              => "TCU-080-072"
  #   "MET.028"                          => "028"
  #   "Something 20-1"                   => "20-1"
  #   "Met Station"                      => nil
  def self.call(segment_name)
    return nil if segment_name.blank?

    tokens = segment_name.strip.split(/\s+/)
    identifier = tokens.reverse.find { |t| t.match?(/[^a-zA-Z]/) }
    return nil unless identifier

    # "MET.028" style: purely alpha prefix, dot, purely numeric suffix
    if (m = identifier.match(/\A[a-zA-Z]+\.(\d+)\z/))
      return m[1]
    end

    identifier
  end
end
