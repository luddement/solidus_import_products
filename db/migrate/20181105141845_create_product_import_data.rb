class CreateProductImportData < SolidusSupport::Migration[4.2]
  def self.up
    create_table :spree_product_import_data do |t|
      t.references :product_import, null: false, index: true
      t.jsonb "data", default: {}, null: false
      t.timestamps
    end
  end

  def self.down
    drop_table :spree_product_import_data
  end
end
