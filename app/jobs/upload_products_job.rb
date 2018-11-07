class UploadProductsJob < ApplicationJob
  queue_as :default

  def perform(product_import)
    user = product_import.user
    begin
      product_import.parse!
    rescue StandardError => exception
      Rails.logger.error("[ActiveJob] [UploadProductsJob] [#{job_id}] ID: #{product_import} #{exception}")
      raise
    end
  end
end
