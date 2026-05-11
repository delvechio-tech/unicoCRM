import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from '../../../helper/URLHelper';

import AiAgentsIndex from './aiAgents/Index.vue';
import InventoryIndex from './inventory/Index.vue';
import KanbanIndex from './kanban/Index.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm/inventory'),
    name: 'crm_inventory_index',
    component: InventoryIndex,
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CRM,
    },
  },
  {
    path: frontendURL('accounts/:accountId/crm/kanban'),
    name: 'crm_kanban_index',
    component: KanbanIndex,
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.CRM,
    },
  },
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
