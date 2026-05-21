
ruby ../../bin/export_events_reshaped.rb data_block_020.json output/out_020_1m.csv output/out_020_5m.csv
ruby ../../bin/export_events_reshaped.rb data_block_028.json output/out_028_1m.csv output/out_028_5m.csv
ruby ../../bin/export_events_reshaped.rb data_blocks_023_093.json output/out_023_093_1m.csv output/out_023_093_5m.csv

ruby merge_csvs.rb output/out_020_5m.csv output/out_028_5m.csv output/out_020_028_5m.csv
ruby merge_csvs.rb output/out_020_028_5m.csv output/out_023_093_5m.csv output/events_020_093_5m.csv
