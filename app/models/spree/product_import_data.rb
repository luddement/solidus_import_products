# This model is the master routine for uploading products
# Requires Paperclip and CSV to upload the CSV file and read it nicely.

# Original Author:: Josh McArthur
# License:: MIT
module Spree
  class ProductImportData < ActiveRecord::Base
    belongs_to :product_import#, class_name: 'Spree::ProductImport'
  end
end
