class PvsystImportJob < ApplicationJob

  def initialize(file)
    @file = file
  end

  def perform
    begin
      Importer.new(@file).import_pvsysts
    rescue => exception
      puts exception.inspect
      puts exception.backtrace
    end
  end
end