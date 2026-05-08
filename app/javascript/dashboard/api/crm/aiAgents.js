import ApiClient from '../ApiClient';

class CrmAiAgentsAPI extends ApiClient {
  constructor() {
    super('crm/ai_agents', { accountScoped: true });
  }
}

export default new CrmAiAgentsAPI();
