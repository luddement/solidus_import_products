# This model is the master routine for uploading products
# Requires Paperclip and CSV to upload the CSV file and read it nicely.

# Original Author:: Josh McArthur
# License:: MIT
module Spree
  class ProductImport < ActiveRecord::Base
    ENCODINGS = %w[UTF-8 iso-8859-1].freeze

    has_one :product_import_data, dependent: :destroy, class_name: 'Spree::ProductImportData'

    has_attached_file :data_file,
                      path: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension',
                      url: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension'

    belongs_to :user, class_name: 'Spree::User', foreign_key: 'created_by', inverse_of: :product_imports

    validates_attachment_presence :data_file
    # Content type of csv vary in different browsers.
    validates_attachment :data_file, presence: true, content_type: { content_type: ['text/csv', 'text/plain', 'text/comma-separated-values', 'application/octet-stream', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'] }

    serialize :product_ids, Array
    cattr_accessor :settings
    attr_accessor :source

    state_machine initial: :created do
      event :start do
        transition to: :started, from: :created
      end
      event :complete do
        transition to: :completed, from: :started
      end
      event :failure do
        transition to: :failed, from: %i[created started]
      end

      before_transition to: [:failed] do |import|
        import.product_ids = []
        import.failed_at = Time.current
        import.completed_at = nil
      end

      before_transition to: [:completed] do |import|
        import.failed_at = nil
        import.completed_at = Time.current
      end
    end

    def product_import_source
      Spree::Supplier.find(product_import_source_id)
    end

    def items
      # SolidusImportProducts::Parser.parse(:csv, data_file.url(:default, timestamp: false), { encoding_csv: encoding_csv, separator_char: separatorChar })
      # start!

      file = CGI::unescape(data_file.url(:default, timestamp: false))
      supplier = product_import_source

      csv_string = open(file, "r:#{supplier.import_encoding}").read.encode('utf-8')
      rows = CSV.parse(csv_string, headers: true, col_sep: supplier.import_separator)
      items = []
      skus = []

      rows.each do |row|
        skus << row['sku']
        regular_price = row['regular_price'].squish.gsub(' ','').to_i
        sale_price = row['sale_price'].squish.gsub(' ','').to_i

        price_diff = regular_price - sale_price
        step = price_diff / 7

        days = []
        current_price = regular_price

        6.times do
          days << current_price
          current_price = current_price - step
        end

        days << sale_price

        items << {
          variant: nil,
          sku: row['sku'],
          name: row['post_title'],
          description: row['description'],
          days: days,
          images: row['images'].split(' | ')
        }
      end

      variants = Spree::Variant.where(sku: skus).includes(:product).group_by(&:sku)
      skus = variants.keys.to_set

      items.each do |item|
        if skus.include?(item[:sku])
          item[:variant] = variants[item[:sku]]
        end
      end

      items
    end

    def add_product(product)
      product_ids << product.id unless product?(product)
    end

    def product?(product)
      product.id && product_ids.include?(product.id)
    end

    def products_count
      parse.product_count
    end

    def state_datetime
      if failed?
        failed_at
      elsif completed?
        completed_at
      else
        updated_at
      end
    end
  end
end
