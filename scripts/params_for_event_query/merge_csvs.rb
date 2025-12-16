# merge_csvs_side_by_side_with_meta.rb
require "csv"

INPUT1 = ARGV[0] or abort("Usage: ruby #{File.basename($0)} events1.csv events2.csv out.csv")
INPUT2 = ARGV[1] or abort("Please provide path for second input csv")
OUTPUT = ARGV[2] or abort("Please provide path for output csv")

JOIN_KEY = ENV["JOIN_KEY"] # optional; if nil we use first shared header

# Preferred order of metadata keys for the left column
META_ORDER = %w[
  variable
  segment_apcode
  segment_name
  mloc_apcode
  source_calc_period
  measurement_name
  eng_unit
  station_type
  station_element
  station_id
  relevance
]

def read_sections(path)
  raw = File.read(path)
  meta_text, grid_text = raw.split(/\r?\n\r?\n/, 2)

  # Parse metadata as 2-column CSV without headers (key, value)
  meta_pairs = []
  if meta_text
    CSV.parse(meta_text, headers: false) do |row|
      next if row.nil? || row.compact.empty?
      key = row[0].to_s.strip
      val = row[1] ? row[1].to_s : nil
      next if key.empty?
      meta_pairs << [key, val]
    end
  end

  # Parse grid; if no blank line existed assume whole file is grid
  grid =
    if grid_text && !grid_text.strip.empty?
      CSV.parse(grid_text, headers: true, return_headers: false)
    else
      CSV.parse(raw, headers: true, return_headers: false)
    end

  [meta_pairs, grid]
end

meta1, grid1 = read_sections(INPUT1)
meta2, grid2 = read_sections(INPUT2)

h1 = grid1.headers || []
h2 = grid2.headers || []

join_key = JOIN_KEY || (h1 & h2).first
abort("No shared header to join on. Specify one via JOIN_KEY=...") unless join_key

# Which value columns (aka series) from each file?
vals1 = h1.reject { |c| c == join_key }
vals2 = h2.reject { |c| c == join_key }

# Disambiguate collisions from right file
vals2_out = vals2.map { |c| (vals1.include?(c) ? "#{c}_2" : c) }

# Build a lookup to map final series name -> source meta hash
meta_hash1 = meta1.to_h
meta_hash2 = meta2.to_h

series_names = vals1 + vals2_out
series_sources = {}
vals1.each { |c| series_sources[c] = meta_hash1 }
vals2.each_with_index { |c, i| series_sources[vals2_out[i]] = meta_hash2 }

# Index grids by join key
def index_by_key(table, key)
  table.each_with_object({}) do |row, acc|
    k = row[key]
    acc[k] = row if k
  end
end
idx1 = index_by_key(grid1, join_key)
idx2 = index_by_key(grid2, join_key)
all_keys = (idx1.keys | idx2.keys).sort

# Build per-series extractors to read values in the same order as series_names
readers = []
vals1.each { |c| readers << ->(k) { (idx1[k] && idx1[k][c]) } }
vals2.each { |c| readers << ->(k) { (idx2[k] && idx2[k][c]) } }

# Compose metadata table: first column = meta key (in desired order),
# subsequent columns = one column per series; 'variable' row is the series name itself
ordered_meta_keys = (META_ORDER + (series_sources.values.flat_map(&:keys) - META_ORDER)).uniq

CSV.open(OUTPUT, "w") do |out|
  # ---- METADATA (TOP) ----
  out << [""] + series_names # header row: meta key label + one column per series

  ordered_meta_keys.each do |mk|
    row = [mk]
    series_names.each do |sname|
      if mk == "variable"
        row << sname
      else
        row << series_sources[sname][mk]
      end
    end
    out << row
  end

  # Blank line between metadata block and grid
  out << []

  # ---- GRID (SIDE-BY-SIDE) ----
  out << [join_key] + series_names

  all_keys.each do |k|
    vals = readers.map { |r| r.call(k) }
    out << [k] + vals
  end
end
