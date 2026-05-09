import ApiClient from '../ApiClient';

class CrmAiAgentsAPI extends ApiClient {
  constructor() {
    super('crm/ai_agents', { accountScoped: true });
  }

  playground(id, data) {
    return axios.post(`${this.url}/${id}/playground`, data);
  }
}

export default new CrmAiAgentsAPI();
