import ApiClient from '../ApiClient';

class CrmProductsAPI extends ApiClient {
  constructor() {
    super('crm/products', { accountScoped: true });
  }
}

export default new CrmProductsAPI();
