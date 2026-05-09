class Api::V1::Accounts::Crm::ProductsController < Api::V1::Accounts::BaseController
  before_action :fetch_product, only: [:show, :update, :destroy]

  def index
    products = Current.account.crm_products.with_attached_media_files.order(updated_at: :desc)

    render json: products.map { |product| product_payload(product) }
  end

  def show
    render json: product_payload(@product)
  end

  def create
    @product = Current.account.crm_products.create!(product_params)
    attach_media_files
    render json: product_payload(@product), status: :created
  end

  def update
    @product.update!(product_params)
    attach_media_files
    render json: product_payload(@product)
  end

  def destroy
    @product.destroy!
    head :ok
  end

  private

  def fetch_product
    @product = Current.account.crm_products.find(params[:id])
  end

  def product_params
    permitted = params.require(:product).permit(
      :name, :sku, :category, :currency, :price, :active, :description,
      :faq, :objections, :media_notes, metadata: {}, media_files: []
    )

    permitted[:metadata] = parsed_metadata(permitted[:metadata]) if permitted[:metadata].present?
    permitted.except(:media_files)
  end

  def attach_media_files
    return if params.dig(:product, :media_files).blank?

    @product.media_files.attach(params[:product][:media_files])
  end

  def product_payload(product)
    product.as_json.merge(
      media_files: product.media_files.map { |file| media_file_payload(file) }
    )
  end

  def media_file_payload(file)
    {
      id: file.id,
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size,
      url: url_for(file)
    }
  end

  def parsed_metadata(metadata)
    metadata.to_h.transform_values do |value|
      JSON.parse(value)
    rescue JSON::ParserError, TypeError
      value
    end
  end
end
