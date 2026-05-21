#!/usr/bin/env ruby
# fix_inverter_names.rb
#
# Usage:
#   ruby fix_inverter_names.rb input.txt output.txt

input_path  = ARGV[0] or abort "Usage: ruby #{$0} input output"
output_path = ARGV[1] or abort "Usage: ruby #{$0} input output"

text = File.read(input_path)

# Convert:
#   "Inverter module 039-2"
#   "Inverter module 39-2"
# to:
#   "Inverter module INV-039.MOD-2"
text.gsub!(/Inverter module\s+(\d+)-(\d+)/i) do
  inv = $1.rjust(3, "0")  # ensure INV-XXX style
  mod = $2
  "Inverter module INV-#{inv}.MOD-#{mod}"
end

File.write(output_path, text)
puts "Wrote #{output_path}"
