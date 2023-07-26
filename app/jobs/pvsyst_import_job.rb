class PvsystImportJob < ApplicationJob
  def initialize(file)
    @file = file
  end

  def perform
    Importer.import_pvsysts(@file)
  end
end