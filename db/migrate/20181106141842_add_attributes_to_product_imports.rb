class AddAttributesToProductImports < SolidusSupport::Migration[4.2]
  def change
    add_reference :spree_product_imports, :product_import_source, index: true
  end
end
