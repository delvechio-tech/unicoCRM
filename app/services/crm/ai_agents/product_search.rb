class Crm::AiAgents::ProductSearch
  DEFAULT_LIMIT = 5
  MAX_LIMIT = 10

  def initialize(agent:, query:, limit: DEFAULT_LIMIT)
    @agent = agent
    @query = query.to_s.strip
    requested_limit = limit.present? ? limit.to_i : DEFAULT_LIMIT
    @limit = [[requested_limit, 1].max, MAX_LIMIT].min
  end

  def products
    scope = agent.products.with_attached_media_files.where(crm_products: { account_id: agent.account_id, active: true })
    scope = scope.where(search_condition, query: "%#{escaped_query}%") if query.present?
    scope.order(:name).limit(limit)
  end

  def product_payloads
    products.map { |product| product_payload(product) }
  end

  def faq_payloads
    products.filter_map do |product|
      next if product.faq.blank? && product.objections.blank? && product.media_notes.blank?

      {
        product_id: product.id,
        product_name: product.name,
        sku: product.sku,
        availability_status: product.availability_status,
        available_quantity: product.available_quantity,
        sale_available: product.sale_available?,
        faq: product.faq,
        objections: product.objections,
        media_notes: product.media_notes
      }
    end
  end

  def product_payload(product)
    {
      id: product.id,
      name: product.name,
      sku: product.sku,
      category: product.category,
      currency: product.currency,
      price: product.price,
      active: product.active,
      availability_status: product.availability_status,
      track_inventory: product.track_inventory,
      stock_quantity: product.stock_quantity,
      reserved_quantity: product.reserved_quantity,
      available_quantity: product.available_quantity,
      low_stock_threshold: product.low_stock_threshold,
      low_stock: product.low_stock?,
      sale_available: product.sale_available?,
      description: product.description,
      faq: product.faq,
      objections: product.objections,
      media_notes: product.media_notes,
      media_files: product.media_files.map { |file| media_file_payload(file) },
      metadata: product.metadata,
      updated_at: product.updated_at&.iso8601
    }
  end

  def media_file_payload(file)
    {
      id: file.id,
      filename: file.filename.to_s,
      content_type: file.content_type,
      byte_size: file.byte_size
    }
  end

  private

  attr_reader :agent, :query, :limit

  def escaped_query
    ActiveRecord::Base.sanitize_sql_like(query)
  end

  def search_condition
    <<~SQL.squish
      crm_products.name ILIKE :query
      OR crm_products.sku ILIKE :query
      OR crm_products.category ILIKE :query
      OR crm_products.description ILIKE :query
      OR crm_products.faq ILIKE :query
      OR crm_products.objections ILIKE :query
      OR crm_products.media_notes ILIKE :query
    SQL
  end
end
