import ApiClient from '../ApiClient';

class CrmProductsAPI extends ApiClient {
  constructor() {
    super('crm/products', { accountScoped: true });
  }

  createWithFiles(data) {
    return axios.post(this.url, data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  updateWithFiles(id, data) {
    return axios.patch(`${this.url}/${id}`, data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }
}

export default new CrmProductsAPI();
