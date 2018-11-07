module Spree
  module Admin
    class ProductImportsController < BaseController
      def index
        @product_import = Spree::ProductImport.new
        @product_imports = Spree::ProductImport.page(params[:page]).order(id: :desc)

        @sources = Spree::Supplier.where(import_enabled: true)
        @suppliers = @sources.index_by(&:id)
      end

      def show
        @product_import = Spree::ProductImport.find(params[:id])
        @items = @product_import.items
      end

      def create
        @product_import = spree_current_user.product_imports.create(product_import_params)
        # UploadProductsJob.perform_now(@product_import)
        flash[:notice] = t('product_import_created')
        redirect_to admin_product_imports_path
      end

      def update
        redirect_to :back
      end

      def destroy
        @product_import = ::Spree::ProductImport.find(params[:id])

        if @product_import.destroy
          flash[:success] = t('delete_product_import_successful')
        end
        redirect_to admin_product_imports_path
      end

      private

      def product_import_params
        params.require(:product_import).permit!
      end
    end
  end
end
