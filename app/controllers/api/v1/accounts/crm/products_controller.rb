class Api::V1::Accounts::Crm::ProductsController < Api::V1::Accounts::BaseController
  before_action :fetch_product, only: [:show, :update, :destroy]

  def index
    render json: Current.account.crm_products.order(updated_at: :desc)
  end

  def show
    render json: @product
  end

  def create
    @product = Current.account.crm_products.create!(product_params)
    render json: @product, status: :created
  end

  def update
    @product.update!(product_params)
    render json: @product
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
    params.require(:product).permit(
      :name, :sku, :category, :currency, :price, :active, :description,
      :faq, :objections, :media_notes, metadata: {}
    )
  end
end
