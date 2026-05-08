import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

import AiAgentsIndex from './aiAgents/Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm/ai-agents'),
    name: 'crm_ai_agents_index',
    component: AiAgentsIndex,
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CRM,
    },
  },
];
