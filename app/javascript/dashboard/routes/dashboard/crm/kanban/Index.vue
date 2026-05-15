<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';

import kanbanAPI from 'dashboard/api/crm/kanban';
import productsAPI from 'dashboard/api/crm/products';
import contactsAPI from 'dashboard/api/contacts';
import captainTasksAPI from 'dashboard/api/captain/tasks';

const route = useRoute();

const pipeline = ref({});
const pipelines = ref([]);
const selectedPipelineId = ref(null);
const stages = ref([]);
const cards = ref([]);
const metrics = ref({});
const products = ref([]);
const webhooks = ref([]);
const contactResults = ref([]);
const selectedCardId = ref(null);
const isDetailOpen = ref(false);
const draggedCardId = ref(null);
const pendingCardMoveIds = ref([]);
const isLoading = ref(false);
const isPipelineOpen = ref(false);
const isPipelineMenuOpen = ref(false);
const openStageMenuId = ref(null);
const openCardMenuId = ref(null);
const isSearchingContacts = ref(false);
const isSummarizing = ref(false);
const isSavingActivity = ref(false);
const boardSearch = ref('');
const boardFilter = ref('all');
const activeConfigTab = ref('board');

const cardForm = reactive({
  title: '',
  stage_id: null,
  contact_id: '',
  conversation_id: '',
  product_id: '',
  budget_amount: '',
  budget_currency: 'BRL',
  summary: '',
  notes: '',
  status: 'open',
});

const rulesForm = reactive({
  ai_rules: '',
});

const automationRuleForm = reactive({
  name: '',
  enabled: true,
  trigger: 'message_created',
  condition: 'incoming_message',
  stage_id: '',
});

const pipelineForm = reactive({
  id: null,
  name: '',
  description: '',
  ai_rules: '',
  template: 'sales',
});

const pipelineTemplates = [
  { value: 'sales', label: 'Vendas' },
  { value: 'delayed_conversations', label: 'Conversas atrasadas' },
  { value: 'support', label: 'Suporte' },
  { value: 'recovery', label: 'Recuperacao' },
  { value: 'onboarding', label: 'Onboarding' },
];

const configTabs = [
  { value: 'board', label: 'Kanban', icon: 'i-lucide-kanban-square' },
  { value: 'stages', label: 'Etapas', icon: 'i-lucide-columns-3' },
  { value: 'rules', label: 'Regras', icon: 'i-lucide-git-branch-plus' },
  { value: 'webhooks', label: 'Webhooks', icon: 'i-lucide-webhook' },
  { value: 'metrics', label: 'Metricas', icon: 'i-lucide-bar-chart-3' },
];

const ruleConditions = [
  { value: 'incoming_message', label: 'Mensagem recebida', description: 'Cliente enviou uma nova mensagem publica.' },
  { value: 'unread', label: 'Nao lida', description: 'Ha mensagem recebida ainda nao lida pelo atendimento.' },
  { value: 'waiting_reply', label: 'Aguardando resposta', description: 'Cliente esta esperando resposta do time.' },
  { value: 'agent_replied', label: 'Respondida', description: 'Ultima acao publica veio do time/agente.' },
  { value: 'open_conversation', label: 'Conversa aberta', description: 'Conversa segue aberta no Chatwoot.' },
  { value: 'any', label: 'Qualquer conversa', description: 'Regra coringa para fallback do funil.' },
];

const stageColors = [
  { value: 'blue', label: 'Azul' },
  { value: 'teal', label: 'Verde' },
  { value: 'amber', label: 'Amarelo' },
  { value: 'violet', label: 'Roxo' },
  { value: 'ruby', label: 'Vermelho' },
  { value: 'green', label: 'Ganho' },
  { value: 'slate', label: 'Neutro' },
];

const stageForm = reactive({
  name: '',
  stale_after_days: 2,
  win_probability: 10,
  color: 'teal',
});

const activityForm = reactive({
  title: '',
  activity_type: 'follow_up',
  due_at: '',
  description: '',
});

const webhookForm = reactive({
  name: '',
  url: '',
  access_token: '',
  events: '',
});

const selectedCard = computed(() =>
  cards.value.find(card => card.id === selectedCardId.value)
);

const pipelineSettings = computed(() => pipeline.value?.settings || {});

const automationRules = computed(() =>
  Array.isArray(pipelineSettings.value.automation_rules)
    ? pipelineSettings.value.automation_rules
    : []
);

const filteredCards = computed(() => {
  const searchTerm = boardSearch.value.trim().toLowerCase();

  return cards.value.filter(card => {
    const matchesSearch =
      !searchTerm ||
      [
        card.title,
        card.summary,
        card.notes,
        card.contact?.name,
        card.contact?.email,
        card.contact?.phone_number,
        card.product?.name,
        card.conversation?.display_id ? `#${card.conversation.display_id}` : '',
      ]
        .filter(Boolean)
        .some(value => String(value).toLowerCase().includes(searchTerm));

    if (!matchesSearch) return false;

    if (boardFilter.value === 'urgent') {
      return ['stale', 'critical'].includes(card.urgency?.level || card.stale_level);
    }

    if (boardFilter.value === 'sla') {
      return card.urgency?.source === 'chatwoot_sla' && card.urgency?.level === 'critical';
    }

    if (boardFilter.value === 'today') {
      return Boolean(card.next_activity_at);
    }

    if (boardFilter.value === 'auto') {
      return Boolean(card.auto_created);
    }

    if (boardFilter.value === 'product') {
      return Boolean(card.product);
    }

    return true;
  });
});

const visibleCards = stageId =>
  filteredCards.value
    .filter(card => card.stage_id === stageId)
    .sort((a, b) => a.position - b.position || b.id - a.id);

const normalizeList = response =>
  response?.data?.payload || response?.data?.data || response?.data || [];

const updateBoardState = data => {
  pipeline.value = data.pipeline;
  pipelines.value = data.pipelines || [data.pipeline].filter(Boolean);
  selectedPipelineId.value = pipeline.value?.id || null;
  stages.value = data.stages || [];
  cards.value = data.cards || [];
  metrics.value = data.metrics || {};
  webhooks.value = data.webhooks || [];
  rulesForm.ai_rules = pipeline.value?.ai_rules || '';
};

const updatePipelineSettings = async nextSettings => {
  const response = await kanbanAPI.updatePipeline(pipeline.value.id, {
    pipeline: {
      settings: {
        ...pipelineSettings.value,
        ...nextSettings,
      },
    },
  });
  updateBoardState(response.data);
};

const resetAutomationRuleForm = () => {
  Object.assign(automationRuleForm, {
    name: '',
    enabled: true,
    trigger: 'message_created',
    condition: 'incoming_message',
    stage_id: stages.value[0]?.id || '',
  });
};

const resetCardForm = (stageId, shouldOpen = true) => {
  selectedCardId.value = null;
  isDetailOpen.value = shouldOpen;
  Object.assign(cardForm, {
    title: '',
    stage_id: stageId || stages.value[0]?.id || null,
    contact_id: '',
    conversation_id: '',
    product_id: '',
    budget_amount: '',
    budget_currency: 'BRL',
    summary: '',
    notes: '',
    status: 'open',
  });
};

const closeDetailPanel = () => {
  selectedCardId.value = null;
  isDetailOpen.value = false;
};

const loadBoard = async () => {
  isLoading.value = true;
  try {
    const boardParams = selectedPipelineId.value
      ? { pipeline_id: selectedPipelineId.value }
      : {};
    const [boardResponse, productsResponse] = await Promise.all([
      kanbanAPI.getBoard(boardParams),
      productsAPI.get(),
    ]);

    updateBoardState(boardResponse.data);
    products.value = normalizeList(productsResponse);
    if (!automationRuleForm.stage_id) resetAutomationRuleForm();

    if (!stages.value.some(stage => String(stage.id) === String(cardForm.stage_id))) {
      resetCardForm(null, false);
    }
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel carregar o Kanban.');
  } finally {
    isLoading.value = false;
  }
};

const reloadCurrentBoard = async () => {
  const response = await kanbanAPI.getBoard(
    selectedPipelineId.value ? { pipeline_id: selectedPipelineId.value } : {}
  );
  updateBoardState(response.data);
};

const selectPipeline = async () => {
  closeDetailPanel();
  await loadBoard();
};

const openPipelineForm = (record = null) => {
  Object.assign(pipelineForm, {
    id: record?.id || null,
    name: record?.name || '',
    description: record?.description || '',
    ai_rules: record?.ai_rules || '',
    template: 'sales',
  });
  isPipelineOpen.value = true;
};

const runPipelineMenuAction = action => {
  isPipelineMenuOpen.value = false;
  action();
};

const runStageMenuAction = action => {
  openStageMenuId.value = null;
  action();
};

const runCardMenuAction = action => {
  openCardMenuId.value = null;
  action();
};

const openConfigTab = tab => {
  activeConfigTab.value = tab;
};

const openStageSettings = () => {
  activeConfigTab.value = 'stages';
};

const toggleStageMenu = stageId => {
  openStageMenuId.value = openStageMenuId.value === stageId ? null : stageId;
};

const toggleCardMenu = cardId => {
  openCardMenuId.value = openCardMenuId.value === cardId ? null : cardId;
};

const closeKanbanOverlays = () => {
  isPipelineMenuOpen.value = false;
  openStageMenuId.value = null;
  openCardMenuId.value = null;
  isPipelineOpen.value = false;
  activeConfigTab.value = 'board';
  if (isDetailOpen.value) closeDetailPanel();
};

const handleEscape = event => {
  if (event.key === 'Escape') closeKanbanOverlays();
};

const savePipeline = async () => {
  try {
    const payload = {
      pipeline: {
        name: pipelineForm.name,
        description: pipelineForm.description,
        ai_rules: pipelineForm.ai_rules,
      },
    };
    if (!pipelineForm.id) payload.pipeline.template = pipelineForm.template;

    const response = pipelineForm.id
      ? await kanbanAPI.updatePipeline(pipelineForm.id, payload)
      : await kanbanAPI.createPipeline(payload);

    updateBoardState(response.data);
    isPipelineOpen.value = false;
    useAlert(pipelineForm.id ? 'Funil atualizado.' : 'Funil criado.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel salvar o funil.');
  }
};

const deletePipeline = async () => {
  if (!pipeline.value?.id) return;
  if (!window.confirm(`Excluir o funil ${pipeline.value.name}?`)) return;

  try {
    const response = await kanbanAPI.deletePipeline(pipeline.value.id);
    updateBoardState(response.data);
    closeDetailPanel();
    useAlert('Funil excluido.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel excluir o funil.');
  }
};

const createStage = async () => {
  try {
    await kanbanAPI.createStage({
      pipeline_id: selectedPipelineId.value,
      stage: { ...stageForm },
    });
    Object.assign(stageForm, {
      name: '',
      stale_after_days: 2,
      win_probability: 10,
      color: 'teal',
    });
    useAlert('Etapa criada.');
    await reloadCurrentBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel criar a etapa.');
  }
};

const searchContacts = async event => {
  const query = event.target.value.trim();
  if (query.length < 2) {
    contactResults.value = [];
    return;
  }

  isSearchingContacts.value = true;
  try {
    const response = await contactsAPI.search(query, 1);
    contactResults.value = normalizeList(response).slice(0, 8);
  } catch {
    contactResults.value = [];
  } finally {
    isSearchingContacts.value = false;
  }
};

const selectContact = contact => {
  cardForm.contact_id = contact.id;
  if (!cardForm.title) cardForm.title = contact.name || contact.phone_number || contact.email;
  contactResults.value = [];
};

const editCard = card => {
  selectedCardId.value = card.id;
  isDetailOpen.value = true;
  Object.assign(cardForm, {
    title: card.title || '',
    stage_id: card.stage_id,
    contact_id: card.contact_id || '',
    conversation_id: card.conversation_id || '',
    product_id: card.product_id || '',
    budget_amount: card.budget_amount || '',
    budget_currency: card.budget_currency || 'BRL',
    summary: card.summary || '',
    notes: card.notes || '',
    status: card.status || 'open',
  });
};

const resetActivityForm = () => {
  Object.assign(activityForm, {
    title: '',
    activity_type: 'follow_up',
    due_at: '',
    description: '',
  });
};

const compactCardPayload = () => ({
  pipeline_id: selectedPipelineId.value,
  card: {
    ...cardForm,
    contact_id: cardForm.contact_id || null,
    conversation_id: cardForm.conversation_id || null,
    product_id: cardForm.product_id || null,
    budget_amount: cardForm.budget_amount || null,
  },
});

const saveCard = async () => {
  try {
    if (selectedCardId.value) {
      await kanbanAPI.updateCard(selectedCardId.value, compactCardPayload());
      useAlert('Card atualizado.');
    } else {
      await kanbanAPI.createCard(compactCardPayload());
      useAlert('Card criado.');
    }
    closeDetailPanel();
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel salvar o card.');
  }
};

const summarizeConversation = async () => {
  const conversationDisplayId = selectedCard.value?.conversation?.display_id;
  if (!conversationDisplayId) {
    useAlert('Vincule uma conversa salva para gerar o resumo.');
    return;
  }

  isSummarizing.value = true;
  try {
    const response = await captainTasksAPI.summarize(conversationDisplayId);
    cardForm.summary = response.data.message || cardForm.summary;
    useAlert('Resumo gerado.');
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel gerar o resumo.');
  } finally {
    isSummarizing.value = false;
  }
};

const saveAutomationRule = async () => {
  if (!automationRuleForm.stage_id) {
    useAlert('Escolha uma etapa para a regra.');
    return;
  }

  const stage = stages.value.find(item => String(item.id) === String(automationRuleForm.stage_id));
  const nextRule = {
    id: `rule-${Date.now()}`,
    name: automationRuleForm.name || `${automationRuleForm.condition} -> ${stage?.name || 'etapa'}`,
    enabled: automationRuleForm.enabled,
    trigger: automationRuleForm.trigger,
    condition: automationRuleForm.condition,
    stage_id: Number(automationRuleForm.stage_id),
  };

  try {
    await updatePipelineSettings({
      automation_rules: [...automationRules.value, nextRule],
    });
    resetAutomationRuleForm();
    useAlert('Regra adicionada.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel salvar a regra.');
  }
};

const toggleAutomationRule = async rule => {
  try {
    await updatePipelineSettings({
      automation_rules: automationRules.value.map(item =>
        item.id === rule.id ? { ...item, enabled: !item.enabled } : item
      ),
    });
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel atualizar a regra.');
  }
};

const deleteAutomationRule = async rule => {
  try {
    await updatePipelineSettings({
      automation_rules: automationRules.value.filter(item => item.id !== rule.id),
    });
    useAlert('Regra removida.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel remover a regra.');
  }
};

const applyDelayedConversationPreset = async () => {
  const findStage = terms =>
    stages.value.find(stage =>
      terms.some(term => stage.name.toLowerCase().includes(term))
    );

  const rules = [
    { condition: 'agent_replied', stage: findStage(['respondida', 'respondido']) },
    { condition: 'unread', stage: findStage(['nao lida', 'nao lidas', 'não lida', 'não lidas']) },
    { condition: 'waiting_reply', stage: findStage(['lida', 'lidas', 'aguardando']) },
    { condition: 'incoming_message', stage: findStage(['nova', 'novas']) || stages.value[0] },
  ]
    .filter(item => item.stage)
    .map((item, index) => ({
      id: `preset-${item.condition}-${Date.now()}-${index}`,
      name: ruleConditions.find(condition => condition.value === item.condition)?.label || item.condition,
      enabled: true,
      trigger: 'message_created',
      condition: item.condition,
      stage_id: item.stage.id,
    }));

  if (!rules.length) {
    useAlert('Crie etapas no funil antes de aplicar o modelo.');
    return;
  }

  try {
    await updatePipelineSettings({ automation_rules: rules });
    useAlert('Modelo de conversas atrasadas aplicado.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel aplicar o modelo.');
  }
};

const summarizeCardConversation = card => {
  editCard(card);
  summarizeConversation();
};

const deleteCard = async card => {
  if (!window.confirm(`Arquivar o card ${card.title}?`)) return;

  try {
    await kanbanAPI.deleteCard(card.id, { pipeline_id: selectedPipelineId.value });
    useAlert('Card arquivado.');
    if (selectedCardId.value === card.id) closeDetailPanel();
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel arquivar o card.');
  }
};

const saveRules = async () => {
  try {
    const response = await kanbanAPI.updatePipeline(pipeline.value.id, {
      pipeline: {
        ai_rules: rulesForm.ai_rules,
        settings: pipelineSettings.value,
      },
    });
    updateBoardState(response.data);
    useAlert('Regras atualizadas.');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel salvar as regras.');
  }
};

const createActivity = async () => {
  if (!selectedCard.value) return;

  isSavingActivity.value = true;
  try {
    await kanbanAPI.createActivity(selectedCard.value.id, {
      pipeline_id: selectedPipelineId.value,
      activity: {
        ...activityForm,
        due_at: activityForm.due_at || null,
      },
    });
    useAlert('Atividade criada.');
    resetActivityForm();
    await loadBoard();
    selectedCardId.value = selectedCard.value?.id || selectedCardId.value;
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel criar a atividade.');
  } finally {
    isSavingActivity.value = false;
  }
};

const completeActivity = async activity => {
  if (!selectedCard.value) return;

  try {
    await kanbanAPI.completeActivity(selectedCard.value.id, activity.id, {
      pipeline_id: selectedPipelineId.value,
    });
    useAlert('Atividade concluida.');
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel concluir a atividade.');
  }
};

const createWebhook = async () => {
  try {
    await kanbanAPI.createWebhook({
      pipeline_id: selectedPipelineId.value,
      webhook: {
        name: webhookForm.name,
        url: webhookForm.url,
        access_token: webhookForm.access_token,
        events: webhookForm.events
          .split(',')
          .map(event => event.trim())
          .filter(Boolean),
      },
    });
    Object.assign(webhookForm, { name: '', url: '', access_token: '', events: '' });
    useAlert('Webhook criado.');
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel criar o webhook.');
  }
};

const deleteWebhook = async webhook => {
  if (!window.confirm(`Excluir webhook ${webhook.name}?`)) return;

  try {
    await kanbanAPI.deleteWebhook(webhook.id, { pipeline_id: selectedPipelineId.value });
    useAlert('Webhook excluido.');
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel excluir o webhook.');
  }
};

const updateStage = async stage => {
  try {
    await kanbanAPI.updateStage(stage.id, {
      pipeline_id: selectedPipelineId.value,
      stage: {
        name: stage.name,
        color: stage.color,
        stale_after_days: stage.stale_after_days,
        win_probability: stage.win_probability,
      },
    });
    useAlert('Etapa atualizada.');
    await loadBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel salvar a etapa.');
  }
};

const deleteStage = async stage => {
  if (!window.confirm(`Excluir a etapa ${stage.name}?`)) return;

  try {
    await kanbanAPI.deleteStage(stage.id, { pipeline_id: selectedPipelineId.value });
    useAlert('Etapa excluida.');
    await reloadCurrentBoard();
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel excluir a etapa.');
  } finally {
    openStageMenuId.value = null;
  }
};

const onDragStart = card => {
  draggedCardId.value = card.id;
};

const onDrop = async stage => {
  const cardId = draggedCardId.value;
  draggedCardId.value = null;
  if (!cardId) return;

  const card = cards.value.find(item => item.id === cardId);
  if (!card || card.stage_id === stage.id) return;

  const previousStageId = card.stage_id;
  pendingCardMoveIds.value = [...pendingCardMoveIds.value, card.id];
  card.stage_id = stage.id;
  card.stage_changed_at = new Date().toISOString();

  try {
    await kanbanAPI.updateCard(card.id, {
      pipeline_id: selectedPipelineId.value,
      card: { stage_id: stage.id },
    });
    const response = await kanbanAPI.getBoard(
      selectedPipelineId.value ? { pipeline_id: selectedPipelineId.value } : {}
    );
    updateBoardState(response.data);
  } catch (error) {
    card.stage_id = previousStageId;
    useAlert(error.response?.data?.error || error.message || 'Nao foi possivel mover o card.');
  } finally {
    pendingCardMoveIds.value = pendingCardMoveIds.value.filter(id => id !== card.id);
  }
};

const staleClass = card => {
  const level = card.urgency?.level || card.stale_level;
  if (level === 'critical') return 'border-n-ruby-8';
  if (level === 'stale') return 'border-n-amber-8';
  return 'border-n-weak';
};

const compactUrgencyLabel = card => {
  if (card.urgency?.source === 'chatwoot_sla' && card.urgency?.level === 'critical') return 'SLA vencido';
  if ((card.urgency?.level || card.stale_level) === 'critical') return 'Atrasado';
  if ((card.urgency?.level || card.stale_level) === 'stale') return 'Atenção';
  return 'Em dia';
};

const urgencyChipClass = card => {
  const level = card.urgency?.level;
  if (level === 'critical') return 'crm-urgency-critical';
  if (level === 'stale') return 'crm-urgency-stale';
  return 'crm-urgency-fresh';
};

const ruleConditionLabel = condition =>
  ruleConditions.find(item => item.value === condition)?.label || condition;

const ruleStageLabel = stageId =>
  stages.value.find(stage => stage.id === Number(stageId))?.name || 'Etapa removida';

const stageAccentClass = (stage, index) => {
  if (stage?.color) return `accent-${stage.color}`;
  return ['accent-green', 'accent-blue', 'accent-amber', 'accent-violet', 'accent-teal', 'accent-ruby'][
    index % 6
  ];
};

const formatMoney = (amount, currency = 'BRL') => {
  if (!amount) return 'Sem orcamento';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency,
  }).format(Number(amount));
};

const productAvailabilityLabel = product => {
  if (!product) return '';
  if (product.availability_status === 'discontinued') return 'Descontinuado';
  if (product.availability_status === 'out_of_stock') return 'Sem estoque';
  if (product.availability_status === 'pre_order') return 'Pre-venda';
  if (product.low_stock) return 'Estoque baixo';
  if (product.track_inventory) return `Disp. ${product.available_quantity}`;
  return 'Disponivel';
};

const productAvailabilityClass = product => {
  if (!product) return '';
  if (product.availability_status === 'out_of_stock') return 'is-danger';
  if (product.availability_status === 'discontinued') return 'is-muted';
  if (product.low_stock) return 'is-warning';
  if (product.availability_status === 'pre_order') return 'is-info';
  return 'is-success';
};

const formatDateTime = value => {
  if (!value) return 'Sem data';

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value));
};

const contactUrl = contactId =>
  frontendURL(`accounts/${route.params.accountId}/contacts/${contactId}`);

const cardConversationUrl = conversation =>
  frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: conversation.display_id,
    })
  );

onMounted(() => {
  loadBoard();
  window.addEventListener('keydown', handleEscape);
});

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleEscape);
});
</script>

<template>
  <main class="crm-kanban-page flex h-full min-h-0 flex-1 flex-col bg-n-background">
    <header class="crm-page-header border-b border-n-weak px-6 py-4">
      <div class="crm-title-row flex flex-wrap items-center gap-3">
        <label class="crm-pipeline-title-select min-w-[220px]">
          <span class="sr-only">Funil ativo</span>
          <select v-model="selectedPipelineId" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-1 px-3 py-2 text-base font-semibold text-n-slate-12 outline-none" @change="selectPipeline">
            <option v-for="item in pipelines" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>
        <div v-if="activeConfigTab === 'board'" class="crm-board-tools flex min-w-[280px] flex-1 flex-wrap items-center gap-2">
          <label class="crm-board-search min-w-[220px] flex-1">
            <span class="sr-only">Buscar cards</span>
            <div class="relative">
              <span class="i-lucide-search absolute left-3 top-1/2 size-4 -translate-y-1/2 text-n-slate-10" />
              <input
                v-model="boardSearch"
                class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 py-2 pl-9 pr-3 text-sm text-n-slate-12"
                placeholder="Procurar cards"
              />
            </div>
          </label>
          <select v-model="boardFilter" class="crm-board-filter crm-control rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
            <option value="all">Todos</option>
            <option value="urgent">Urgentes</option>
            <option value="sla">SLA vencido</option>
            <option value="today">Com agenda</option>
            <option value="auto">Automaticos</option>
            <option value="product">Com produto</option>
          </select>
        </div>
        <div class="crm-header-actions ml-auto flex flex-wrap items-center gap-2">
          <button
            class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12"
            :class="{ 'bg-n-alpha-2 text-n-blue-11': activeConfigTab === 'metrics' }"
            type="button"
            @click="openConfigTab(activeConfigTab === 'metrics' ? 'board' : 'metrics')"
          >
            <span class="i-lucide-bar-chart-3 size-4" />
            Metricas · {{ metrics.total_cards || 0 }} ativos
          </button>
          <div class="relative" v-on-clickaway="() => (isPipelineMenuOpen = false)">
            <button
              class="inline-flex size-10 items-center justify-center rounded-md border border-n-weak text-n-slate-12 hover:bg-n-alpha-2"
              :class="{ 'bg-n-alpha-2': isPipelineMenuOpen }"
              type="button"
              aria-label="Opcoes do funil"
              @click="isPipelineMenuOpen = !isPipelineMenuOpen"
            >
              <span class="i-lucide-more-horizontal size-5" />
            </button>
            <div
              v-if="isPipelineMenuOpen"
              class="absolute right-0 z-30 mt-2 w-56 overflow-hidden rounded-md border border-n-weak bg-n-solid-1 py-1 shadow-lg"
            >
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openPipelineForm(pipeline))">
                <span class="i-lucide-settings-2 size-4" />
                Configurar funil
              </button>
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openPipelineForm())">
                <span class="i-lucide-folder-plus size-4" />
                Novo funil
              </button>
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openConfigTab('stages'))">
                <span class="i-lucide-columns-3 size-4" />
                Etapas
              </button>
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openConfigTab('rules'))">
                <span class="i-lucide-git-branch-plus size-4" />
                Regras
              </button>
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openConfigTab('webhooks'))">
                <span class="i-lucide-webhook size-4" />
                Webhooks
              </button>
              <button class="crm-menu-item" type="button" @click="runPipelineMenuAction(() => openConfigTab('metrics'))">
                <span class="i-lucide-bar-chart-3 size-4" />
                Metricas
              </button>
              <button
                v-if="pipeline.id && !pipeline.default"
                class="crm-menu-item crm-menu-item-danger"
                type="button"
                @click="runPipelineMenuAction(deletePipeline)"
              >
                <span class="i-lucide-trash-2 size-4" />
                Excluir funil
              </button>
            </div>
          </div>
          <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="button" @click="resetCardForm()">
            <span class="i-lucide-plus size-4" />
            Novo card
          </button>
        </div>
      </div>

      <nav v-if="activeConfigTab !== 'board'" class="crm-config-tabs mt-2 flex flex-wrap gap-1 border-b border-n-weak">
        <button
          v-for="tab in configTabs"
          :key="tab.value"
          class="crm-config-tab"
          :class="{ 'is-active': activeConfigTab === tab.value }"
          type="button"
          @click="activeConfigTab = tab.value"
        >
          <span :class="tab.icon" class="size-4" />
          {{ tab.label }}
        </button>
      </nav>

      <form v-if="isPipelineOpen" v-on-clickaway="() => (isPipelineOpen = false)" class="crm-config-panel mt-4 border border-n-weak bg-n-solid-1 p-4" @submit.prevent="savePipeline">
        <div class="mb-4 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-sm font-semibold tracking-tight text-n-slate-12">
              {{ pipelineForm.id ? 'Configuracao do funil' : 'Novo funil' }}
            </h2>
            <p class="mt-1 text-xs text-n-slate-11">
              Ajustes administrativos ficam aqui para manter o board limpo.
            </p>
          </div>
          <button class="text-sm text-n-slate-11 hover:text-n-slate-12" type="button" @click="isPipelineOpen = false">
            Fechar
          </button>
        </div>
        <div class="grid gap-3 md:grid-cols-[1fr_1.2fr_180px_auto]">
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Nome do funil</span>
            <input v-model="pipelineForm.name" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Descricao</span>
            <input v-model="pipelineForm.description" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <label v-if="!pipelineForm.id">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Modelo</span>
            <select v-model="pipelineForm.template" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
              <option v-for="template in pipelineTemplates" :key="template.value" :value="template.value">
                {{ template.label }}
              </option>
            </select>
          </label>
          <div class="flex items-end gap-2">
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-save size-4" />
              Salvar
            </button>
          </div>
          <label class="md:col-span-4">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Regras do funil</span>
            <textarea
              v-model="pipelineForm.ai_rules"
              class="crm-control min-h-[120px] w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12"
              placeholder="Ex: criar card quando chegar mensagem nova, priorizar leads quentes, avisar se ficar parado."
            ></textarea>
          </label>
        </div>
        <button
          v-if="pipelineForm.id && !pipeline.default"
          class="mt-4 inline-flex items-center gap-2 rounded-md border border-n-ruby-7 px-3 py-2 text-sm text-n-ruby-10 hover:bg-n-ruby-3"
          type="button"
          @click="deletePipeline"
        >
          Excluir funil
        </button>
      </form>

      <section v-if="activeConfigTab === 'stages'" class="crm-config-panel crm-config-panel-compact mt-3 border border-n-weak bg-n-solid-1 p-4">
        <div class="mb-3 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-sm font-semibold tracking-tight text-n-slate-12">Etapas do funil</h2>
            <p class="mt-0.5 text-xs text-n-slate-11">Prazo, chance, cor e exclusao de colunas vazias.</p>
          </div>
          <button class="text-sm text-n-slate-11 hover:text-n-slate-12" type="button" @click="activeConfigTab = 'board'">
            Voltar ao Kanban
          </button>
        </div>

        <form class="crm-stage-add-row grid gap-2 md:grid-cols-[minmax(220px,1fr)_140px_110px_110px_auto]" @submit.prevent="createStage">
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Nova etapa</span>
            <input v-model="stageForm.name" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Ex: Proposta aceita" />
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Cor</span>
            <select v-model="stageForm.color" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
              <option v-for="color in stageColors" :key="color.value" :value="color.value">{{ color.label }}</option>
            </select>
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Parado</span>
            <input v-model="stageForm.stale_after_days" type="number" min="0" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Chance</span>
            <input v-model="stageForm.win_probability" type="number" min="0" max="100" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <div class="flex items-end gap-2">
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-plus size-4" />
              Adicionar
            </button>
          </div>
        </form>

        <div v-if="stages.length" class="crm-stage-table mt-4 overflow-hidden rounded-md border border-n-weak">
          <div class="crm-stage-table-head grid gap-2 px-3 py-2 text-xs font-semibold uppercase text-n-slate-10 md:grid-cols-[minmax(220px,1fr)_140px_110px_110px_88px]">
            <span>Etapa</span>
            <span>Cor</span>
            <span>Parado</span>
            <span>Chance</span>
            <span class="text-right">Acoes</span>
          </div>
          <article
            v-for="stage in stages"
            :key="`stage-config-${stage.id}`"
            class="crm-stage-config-row grid gap-2 border-t border-n-weak px-3 py-2 md:grid-cols-[minmax(220px,1fr)_140px_110px_110px_88px]"
          >
            <label>
              <span class="sr-only">Etapa</span>
              <input v-model="stage.name" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" @change="updateStage(stage)" />
            </label>
            <label>
              <span class="sr-only">Cor</span>
              <select v-model="stage.color" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" @change="updateStage(stage)">
                <option v-for="color in stageColors" :key="color.value" :value="color.value">{{ color.label }}</option>
              </select>
            </label>
            <label>
              <span class="sr-only">Parado apos</span>
              <div class="crm-stage-number">
                <input v-model="stage.stale_after_days" type="number" min="0" @change="updateStage(stage)" />
                <b>d</b>
              </div>
            </label>
            <label>
              <span class="sr-only">Chance</span>
              <div class="crm-stage-number">
                <input v-model="stage.win_probability" type="number" min="0" max="100" @change="updateStage(stage)" />
                <b>%</b>
              </div>
            </label>
            <div class="flex items-center justify-end">
              <button class="rounded-md px-2 py-2 text-sm text-n-ruby-10 hover:bg-n-ruby-3" type="button" @click="deleteStage(stage)">
                Excluir
              </button>
            </div>
          </article>
        </div>
      </section>

      <div v-if="activeConfigTab === 'metrics'" class="crm-metrics mt-4 grid gap-3 md:grid-cols-3 xl:grid-cols-6">
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon i-lucide-panels-top-left" />
          <span class="text-xs text-n-slate-10">Cards ativos</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.total_cards || 0 }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon i-lucide-circle-dot" />
          <span class="text-xs text-n-slate-10">Em aberto</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.open_cards || 0 }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon crm-metric-icon-warning i-lucide-hourglass" />
          <span class="text-xs text-n-slate-10">Parados</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.stale_cards || 0 }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon i-lucide-badge-dollar-sign" />
          <span class="text-xs text-n-slate-10">Pipeline aberto</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ formatMoney(metrics.budget_total) }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon i-lucide-calendar-days" />
          <span class="text-xs text-n-slate-10">Agenda hoje</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.due_today || 0 }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon crm-metric-icon-danger i-lucide-alarm-clock" />
          <span class="text-xs text-n-slate-10">Atrasadas</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.overdue_activities || 0 }}</strong>
        </div>
        <div class="crm-metric-card border border-n-weak bg-n-solid-1 p-3">
          <span class="crm-metric-icon crm-metric-icon-danger i-lucide-flame" />
          <span class="text-xs text-n-slate-10">SLA vencido</span>
          <strong class="mt-1 block text-xl text-n-slate-12">{{ metrics.sla_missed_cards || 0 }}</strong>
        </div>
      </div>

      <section v-if="activeConfigTab === 'rules'" class="crm-config-panel mt-4 border border-n-weak bg-n-solid-1 p-4">
        <div class="mb-4 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 class="text-sm font-semibold tracking-tight text-n-slate-12">Regras do funil</h2>
            <p class="mt-1 text-xs text-n-slate-11">
              Defina como mensagens reais criam, atualizam e movem cards neste funil.
            </p>
          </div>
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2" type="button" @click="applyDelayedConversationPreset">
            <span class="i-lucide-list-restart size-4" />
            Modelo conversas atrasadas
          </button>
        </div>

        <form class="grid gap-3 lg:grid-cols-[1fr_180px_180px_180px_auto]" @submit.prevent="saveAutomationRule">
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Nome</span>
            <input v-model="automationRuleForm.name" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Ex: Nao lidas" />
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Quando</span>
            <select v-model="automationRuleForm.condition" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
              <option v-for="condition in ruleConditions" :key="condition.value" :value="condition.value">
                {{ condition.label }}
              </option>
            </select>
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Mover para</span>
            <select v-model="automationRuleForm.stage_id" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
              <option v-for="stage in stages" :key="stage.id" :value="stage.id">
                {{ stage.name }}
              </option>
            </select>
          </label>
          <label>
            <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Status</span>
            <select v-model="automationRuleForm.enabled" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
              <option :value="true">Ativa</option>
              <option :value="false">Pausada</option>
            </select>
          </label>
          <div class="flex items-end">
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-plus size-4" />
              Adicionar
            </button>
          </div>
        </form>

        <div class="mt-5 overflow-hidden rounded-md border border-n-weak">
          <div class="crm-rule-row is-header grid gap-3 px-4 py-3 text-xs font-semibold uppercase text-n-slate-10 lg:grid-cols-[1fr_180px_180px_120px_auto]">
            <span>Regra</span>
            <span>Condicao</span>
            <span>Etapa</span>
            <span>Status</span>
            <span class="text-right">Acoes</span>
          </div>
          <div v-if="automationRules.length">
            <article
              v-for="rule in automationRules"
              :key="rule.id"
              class="crm-rule-row grid gap-3 border-t border-n-weak px-4 py-3 text-sm lg:grid-cols-[1fr_180px_180px_120px_auto]"
            >
              <strong class="text-n-slate-12">{{ rule.name }}</strong>
              <span class="text-n-slate-11">{{ ruleConditionLabel(rule.condition) }}</span>
              <span class="text-n-slate-11">{{ ruleStageLabel(rule.stage_id) }}</span>
              <button class="text-left text-xs font-semibold" :class="rule.enabled ? 'text-n-teal-10' : 'text-n-slate-10'" type="button" @click="toggleAutomationRule(rule)">
                {{ rule.enabled ? 'Ativa' : 'Pausada' }}
              </button>
              <button class="text-right text-sm text-n-ruby-10 hover:text-n-ruby-11" type="button" @click="deleteAutomationRule(rule)">
                Remover
              </button>
            </article>
          </div>
          <p v-else class="border-t border-n-weak px-4 py-4 text-sm text-n-slate-11">
            Nenhuma regra estruturada ainda. Sem regras, o sync usa o funil comercial padrao.
          </p>
        </div>

        <form class="mt-5" @submit.prevent="saveRules">
          <label class="block">
            <span class="mb-2 block text-sm font-medium text-n-slate-12">Orientacao livre para IA/n8n</span>
            <textarea v-model="rulesForm.ai_rules" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <button class="mt-3 rounded-md border border-n-weak px-3 py-2 text-sm font-semibold text-n-slate-12 hover:bg-n-alpha-2" type="submit">
            Salvar orientacao
          </button>
        </form>
      </section>

      <section v-if="activeConfigTab === 'webhooks'" class="crm-config-panel crm-config-panel-compact mt-3 border border-n-weak bg-n-solid-1 p-4">
        <div class="mb-3">
          <h2 class="text-sm font-semibold text-n-slate-12">Webhooks do funil</h2>
          <p class="mt-0.5 text-xs text-n-slate-11">Dispare eventos para n8n, integrações comerciais ou auditoria externa.</p>
        </div>
        <form class="crm-webhook-form grid gap-2 lg:grid-cols-[180px_minmax(260px,1fr)_180px_220px_auto]" @submit.prevent="createWebhook">
          <input v-model="webhookForm.name" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Nome" />
          <input v-model="webhookForm.url" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="https://..." />
          <input v-model="webhookForm.access_token" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Segredo" />
          <input v-model="webhookForm.events" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="card.created, card.moved" />
          <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
            Adicionar
          </button>
        </form>
        <div class="mt-4 overflow-hidden rounded-md border border-n-weak">
          <div class="crm-webhook-row is-header grid gap-3 px-3 py-2 text-xs font-semibold uppercase text-n-slate-10 lg:grid-cols-[180px_minmax(260px,1fr)_220px_80px]">
            <span>Nome</span>
            <span>URL</span>
            <span>Eventos</span>
            <span class="text-right">Acoes</span>
          </div>
          <div v-if="webhooks.length">
            <article v-for="webhook in webhooks" :key="webhook.id" class="crm-webhook-row grid gap-3 border-t border-n-weak px-3 py-2 text-sm lg:grid-cols-[180px_minmax(260px,1fr)_220px_80px]">
              <div class="min-w-0">
                <strong class="block truncate text-sm text-n-slate-12">{{ webhook.name }}</strong>
              </div>
              <span class="truncate text-xs text-n-slate-11">{{ webhook.url }}</span>
              <span class="truncate text-xs text-n-slate-10">{{ webhook.events?.join(', ') || 'Todos os eventos' }}</span>
              <button class="text-right text-sm text-n-ruby-10 hover:text-n-ruby-11" type="button" @click="deleteWebhook(webhook)">Excluir</button>
            </article>
          </div>
          <p v-else class="border-t border-n-weak px-3 py-4 text-sm text-n-slate-11">Nenhum webhook configurado.</p>
        </div>
      </section>
    </header>

    <section
      class="crm-workspace grid min-h-0 flex-1 grid-cols-1 overflow-hidden"
      :class="{ 'xl:grid-cols-[minmax(0,1fr)_360px]': isDetailOpen }"
    >
      <div class="crm-board-scroll min-h-0 overflow-x-auto p-5">
        <div v-if="isLoading" class="text-sm text-n-slate-11">Carregando Kanban...</div>
        <div v-else class="crm-board-row flex min-h-full gap-5">
          <section
            v-for="(stage, stageIndex) in stages"
            :key="stage.id"
            class="crm-stage flex w-[320px] shrink-0 flex-col border border-n-weak bg-n-alpha-1"
            :class="stageAccentClass(stage, stageIndex)"
            @dragover.prevent
            @drop="onDrop(stage)"
          >
            <div class="border-b border-n-weak p-4">
              <div class="flex items-start justify-between gap-3">
                <div class="flex min-w-0 flex-1 items-center gap-2">
                  <span class="crm-stage-dot" />
                  <input v-model="stage.name" class="crm-stage-title min-w-0 flex-1 bg-transparent text-sm font-bold text-n-slate-12 outline-none" @change="updateStage(stage)" />
                </div>
                <div class="flex shrink-0 items-center gap-2">
                  <span class="rounded-md bg-n-alpha-2 px-2.5 py-1 text-xs font-semibold text-n-blue-11">{{ visibleCards(stage.id).length }}</span>
                  <div class="relative" v-on-clickaway="() => (openStageMenuId = null)">
                    <button
                      class="inline-flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
                      :class="{ 'bg-n-alpha-2 text-n-slate-12': openStageMenuId === stage.id }"
                      type="button"
                      aria-label="Opcoes da etapa"
                      @click="toggleStageMenu(stage.id)"
                    >
                      <span class="i-lucide-more-horizontal size-4" />
                    </button>
                    <div
                      v-if="openStageMenuId === stage.id"
                      class="absolute right-0 z-30 mt-2 w-48 overflow-hidden rounded-md border border-n-weak bg-n-solid-1 py-1 shadow-lg"
                    >
                      <button class="crm-menu-item" type="button" @click="runStageMenuAction(openStageSettings)">
                        <span class="i-lucide-settings-2 size-4" />
                        Editar etapa
                      </button>
                      <button class="crm-menu-item crm-menu-item-danger" type="button" @click="runStageMenuAction(() => deleteStage(stage))">
                        <span class="i-lucide-trash-2 size-4" />
                        Excluir etapa
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="min-h-[220px] flex-1 space-y-4 overflow-y-auto p-4">
              <article
                v-for="card in visibleCards(stage.id)"
                :key="card.id"
                draggable="true"
                class="crm-deal-card cursor-grab border p-4"
                :class="[staleClass(card), { 'is-moving': pendingCardMoveIds.includes(card.id) }]"
                @dragstart="onDragStart(card)"
                @click="editCard(card)"
              >
                <div class="crm-card-head grid items-start gap-2">
                  <h3 class="min-w-0 break-words text-sm font-bold leading-5 text-n-slate-12">{{ card.title }}</h3>
                  <div class="flex shrink-0 items-center gap-2">
                    <span class="crm-urgency-chip" :class="urgencyChipClass(card)">
                      {{ compactUrgencyLabel(card) }}
                    </span>
                    <div class="relative" v-on-clickaway="() => (openCardMenuId = null)">
                      <button
                        class="inline-flex size-7 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
                        :class="{ 'bg-n-alpha-2 text-n-slate-12': openCardMenuId === card.id }"
                        type="button"
                        aria-label="Opcoes do card"
                        @click.stop="toggleCardMenu(card.id)"
                      >
                        <span class="i-lucide-more-horizontal size-4" />
                      </button>
                      <div
                        v-if="openCardMenuId === card.id"
                        class="absolute right-0 z-30 mt-2 w-52 overflow-hidden rounded-md border border-n-weak bg-n-solid-1 py-1 shadow-lg"
                        @click.stop
                      >
                        <button class="crm-menu-item" type="button" @click="runCardMenuAction(() => editCard(card))">
                          <span class="i-lucide-pencil size-4" />
                          Editar card
                        </button>
                        <a
                          v-if="card.conversation"
                          class="crm-menu-item"
                          :href="cardConversationUrl(card.conversation)"
                          @click.stop="openCardMenuId = null"
                        >
                          <span class="i-lucide-message-circle size-4" />
                          Abrir conversa
                        </a>
                        <button
                          class="crm-menu-item"
                          type="button"
                          :disabled="isSummarizing || !card.conversation"
                          @click="runCardMenuAction(() => summarizeCardConversation(card))"
                        >
                          <span class="i-lucide-sparkles size-4" />
                          Resumo IA
                        </button>
                        <button class="crm-menu-item crm-menu-item-danger" type="button" @click="runCardMenuAction(() => deleteCard(card))">
                          <span class="i-lucide-archive size-4" />
                          Arquivar card
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="mt-3 flex items-center gap-2">
                  <span class="crm-contact-avatar">
                    {{ (card.contact?.name || card.title || '?').slice(0, 1) }}
                  </span>
                  <div class="min-w-0">
                    <a v-if="card.contact" class="block truncate text-xs font-semibold text-n-slate-12" :href="contactUrl(card.contact.id)" @click.stop>{{ card.contact.name || 'Contato' }}</a>
                    <span v-else class="block truncate text-xs font-semibold text-n-slate-12">Sem contato vinculado</span>
                    <a v-if="card.conversation" class="block truncate text-[11px] text-n-blue-text" :href="cardConversationUrl(card.conversation)" @click.stop>Conversa #{{ card.conversation.display_id }}</a>
                  </div>
                </div>
                <p class="mt-2 line-clamp-3 text-sm text-n-slate-11">
                  {{ card.summary || card.notes || 'Sem resumo ainda.' }}
                </p>
                <div class="mt-3 flex flex-wrap items-center gap-2 text-xs text-n-slate-11">
                  <span class="crm-card-chip font-medium text-n-slate-12">
                    <span class="i-lucide-wallet-cards size-3.5" />
                    {{ formatMoney(card.budget_amount, card.budget_currency) }}
                  </span>
                  <span v-if="card.product" class="crm-card-chip">{{ card.product.name }}</span>
                  <span
                    v-if="card.product"
                    class="crm-card-chip crm-product-availability"
                    :class="productAvailabilityClass(card.product)"
                  >
                    {{ productAvailabilityLabel(card.product) }}
                  </span>
                  <span v-if="card.auto_created" class="crm-card-chip">Auto</span>
                  <span v-if="card.status !== 'open'" class="crm-card-chip">{{ card.status }}</span>
                </div>
                <p v-if="card.next_activity_at" class="mt-3 flex items-center gap-1.5 text-xs text-n-slate-11">
                  <span class="i-lucide-calendar-clock size-3.5 text-n-blue-11" />
                  {{ formatDateTime(card.next_activity_at) }}
                </p>
                <p v-if="pendingCardMoveIds.includes(card.id)" class="mt-2 flex items-center gap-1.5 text-xs font-medium text-n-blue-11">
                  <span class="i-lucide-loader-circle size-3 animate-spin" />
                  Salvando movimento...
                </p>
              </article>

              <button class="w-full rounded-md border border-dashed border-n-weak px-3 py-2.5 text-sm font-medium text-n-slate-11 hover:border-n-blue-8 hover:bg-n-alpha-2 hover:text-n-blue-11" type="button" @click="resetCardForm(stage.id)">
                <span class="i-lucide-plus size-4" />
                Adicionar nesta etapa
              </button>
            </div>
          </section>

          <button class="crm-add-stage flex w-[260px] shrink-0 flex-col items-center justify-center gap-2 border border-dashed border-n-weak bg-n-alpha-1 p-6 text-sm font-semibold text-n-slate-11 hover:border-n-blue-8 hover:bg-n-alpha-2 hover:text-n-blue-11" type="button" @click="activeConfigTab = 'stages'">
            <span class="i-lucide-columns-3 size-5" />
            Adicionar etapa
          </button>
        </div>
      </div>

      <aside
        v-if="isDetailOpen"
        v-on-clickaway="closeDetailPanel"
        class="crm-detail-panel min-h-0 overflow-y-auto border-l border-n-weak bg-n-solid-1 p-5"
      >
        <div class="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-semibold text-n-slate-12">{{ selectedCard ? 'Editar card' : 'Novo card' }}</h2>
            <p class="text-sm text-n-slate-11">Cliente, conversa, agenda e contexto comercial.</p>
          </div>
          <button class="text-sm text-n-blue-text" type="button" @click="closeDetailPanel">
            Fechar
          </button>
        </div>

        <section v-if="selectedCard" class="mb-5 space-y-3 border border-n-weak bg-n-alpha-1 p-3">
          <div class="flex items-start justify-between gap-3">
            <div class="flex min-w-0 items-center gap-3">
              <span class="crm-contact-avatar is-large">
                {{ (selectedCard.contact?.name || selectedCard.title || '?').slice(0, 1) }}
              </span>
              <div class="min-w-0">
              <h3 class="text-sm font-semibold text-n-slate-12">Cliente e contexto</h3>
              <p class="text-xs text-n-slate-11">{{ selectedCard.auto_created ? 'Criado automaticamente pela conversa.' : 'Criado manualmente.' }}</p>
              </div>
            </div>
            <span class="rounded bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11">{{ selectedCard.source }}</span>
          </div>
          <dl class="grid grid-cols-2 gap-2 text-xs text-n-slate-11">
            <div>
              <dt class="text-n-slate-10">Cliente</dt>
              <dd class="truncate text-n-slate-12">{{ selectedCard.contact?.name || 'Sem nome' }}</dd>
            </div>
            <div>
              <dt class="text-n-slate-10">Telefone</dt>
              <dd class="truncate text-n-slate-12">{{ selectedCard.contact?.phone_number || 'Sem telefone' }}</dd>
            </div>
            <div>
              <dt class="text-n-slate-10">Email</dt>
              <dd class="truncate text-n-slate-12">{{ selectedCard.contact?.email || 'Sem email' }}</dd>
            </div>
            <div>
              <dt class="text-n-slate-10">Ultima mensagem</dt>
              <dd class="truncate text-n-slate-12">{{ selectedCard.last_message?.content || 'Sem mensagem' }}</dd>
            </div>
          </dl>
        </section>

        <form class="space-y-4" @submit.prevent="saveCard">
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Titulo</span>
            <input v-model="cardForm.title" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>

          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Etapa</span>
            <select v-model="cardForm.stage_id" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12">
              <option v-for="stage in stages" :key="stage.id" :value="stage.id">{{ stage.name }}</option>
            </select>
          </label>

          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Buscar cliente</span>
            <input class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" placeholder="Nome, telefone ou email" @input="searchContacts" />
            <div v-if="contactResults.length" class="mt-2 border border-n-weak bg-n-solid-1">
              <button
                v-for="contact in contactResults"
                :key="contact.id"
                type="button"
                class="block w-full px-3 py-2 text-left text-sm text-n-slate-12 hover:bg-n-alpha-2"
                @click="selectContact(contact)"
              >
                {{ contact.name || contact.phone_number || contact.email }}
              </button>
            </div>
            <p v-else-if="isSearchingContacts" class="mt-1 text-xs text-n-slate-11">Buscando...</p>
          </label>

          <div class="grid grid-cols-2 gap-3">
            <label class="block">
              <span class="mb-1 block text-sm font-medium text-n-slate-12">Contato ID</span>
              <input v-model="cardForm.contact_id" type="number" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
            <label class="block">
              <span class="mb-1 block text-sm font-medium text-n-slate-12">Conversa ID</span>
              <input v-model="cardForm.conversation_id" type="number" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
          </div>

          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Produto</span>
            <select v-model="cardForm.product_id" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12">
              <option value="">Sem produto vinculado</option>
              <option v-for="product in products" :key="product.id" :value="product.id">{{ product.name }}</option>
            </select>
          </label>

          <div class="grid grid-cols-[1fr_96px] gap-3">
            <label class="block">
              <span class="mb-1 block text-sm font-medium text-n-slate-12">Orcamento</span>
              <input v-model="cardForm.budget_amount" type="number" step="0.01" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
            <label class="block">
              <span class="mb-1 block text-sm font-medium text-n-slate-12">Moeda</span>
              <input v-model="cardForm.budget_currency" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
          </div>

          <label class="block">
            <span class="mb-1 flex items-center justify-between gap-3 text-sm font-medium text-n-slate-12">
              Resumo do que foi falado
              <button
                v-if="selectedCard?.conversation"
                type="button"
                class="text-xs text-n-blue-text"
                :disabled="isSummarizing"
                @click="summarizeConversation"
              >
                {{ isSummarizing ? 'Gerando...' : 'Gerar com Captain' }}
              </button>
            </span>
            <textarea v-model="cardForm.summary" rows="5" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>

          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Notas internas</span>
            <textarea v-model="cardForm.notes" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>

          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Status</span>
            <select v-model="cardForm.status" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12">
              <option value="open">Aberto</option>
              <option value="won">Ganhou</option>
              <option value="lost">Perdido</option>
              <option value="archived">Arquivado</option>
            </select>
          </label>

          <div class="flex flex-wrap gap-2">
            <button class="rounded-md bg-n-blue-9 px-4 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-save size-4" />
              Salvar card
            </button>
            <button v-if="selectedCard" class="rounded-md border border-n-ruby-7 px-4 py-2 text-sm text-n-ruby-10" type="button" @click="deleteCard(selectedCard)">
              <span class="i-lucide-archive size-4" />
              Arquivar
            </button>
          </div>
        </form>

        <section v-if="selectedCard" class="mt-6 space-y-4 border-t border-n-weak pt-5">
          <div>
            <h3 class="text-sm font-semibold text-n-slate-12">Agenda do card</h3>
            <div v-if="selectedCard.activities?.length" class="mt-3 space-y-2">
              <article v-for="activity in selectedCard.activities" :key="activity.id" class="border border-n-weak p-3">
                <div class="flex items-start justify-between gap-3">
                  <div class="min-w-0">
                    <strong class="block text-sm text-n-slate-12">{{ activity.title }}</strong>
                    <span class="text-xs text-n-slate-11">{{ activity.activity_type }} - {{ formatDateTime(activity.due_at) }}</span>
                  </div>
                  <button
                    v-if="activity.status === 'open'"
                    class="inline-flex items-center gap-1 rounded-md bg-n-alpha-2 px-2 py-1 text-xs text-n-blue-text"
                    type="button"
                    @click="completeActivity(activity)"
                  >
                    <span class="i-lucide-check size-3.5" />
                    Concluir
                  </button>
                </div>
                <p v-if="activity.description" class="mt-2 text-xs text-n-slate-11">{{ activity.description }}</p>
              </article>
            </div>
            <p v-else class="mt-2 text-sm text-n-slate-11">Nenhuma atividade agendada.</p>
          </div>

          <form class="space-y-3 border border-n-weak bg-n-alpha-1 p-3" @submit.prevent="createActivity">
            <input v-model="activityForm.title" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Nova atividade" />
            <div class="grid grid-cols-2 gap-3">
              <select v-model="activityForm.activity_type" class="rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12">
                <option value="follow_up">Follow-up</option>
                <option value="call">Ligacao</option>
                <option value="meeting">Reuniao</option>
                <option value="proposal">Proposta</option>
                <option value="task">Tarefa</option>
              </select>
              <input v-model="activityForm.due_at" type="datetime-local" class="rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
            </div>
            <textarea v-model="activityForm.description" rows="3" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Observacao" />
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit" :disabled="isSavingActivity">
              <span class="i-lucide-calendar-plus size-4" />
              {{ isSavingActivity ? 'Salvando...' : 'Agendar atividade' }}
            </button>
          </form>

          <div>
            <h3 class="text-sm font-semibold text-n-slate-12">Linha do tempo</h3>
            <div v-if="selectedCard.actions?.length" class="mt-3 space-y-2">
              <article v-for="action in selectedCard.actions" :key="action.id" class="border-l-2 border-n-weak pl-3 text-xs text-n-slate-11">
                <strong class="block text-n-slate-12">{{ action.action_type }}</strong>
                <span>{{ action.actor_type }} - {{ formatDateTime(action.created_at) }}</span>
              </article>
            </div>
            <p v-else class="mt-2 text-sm text-n-slate-11">Sem historico registrado.</p>
          </div>
        </section>
      </aside>
    </section>
  </main>
</template>

<style scoped>
.crm-kanban-page {
  --crm-panel-radius: 12px;
  --crm-page-padding: clamp(1rem, 1.6vw, 1.5rem);
  --crm-shadow-soft: none;
  --crm-stage-accent: rgb(var(--blue-9));
  --crm-field-bg: rgba(var(--background-input-box));
  --crm-field-bg-focus: rgb(var(--surface-2));
  --crm-field-border: rgb(var(--border-weak));
  --alpha-1: 255, 255, 255, 0.045;
  --alpha-2: 255, 255, 255, 0.065;
}

.crm-page-header {
  padding: 0.625rem var(--crm-page-padding) 0.5rem;
  background: rgb(var(--background-color));
}

.crm-title-row {
  align-items: center;
}

.crm-pipeline-title-select select {
  width: min(100%, 21rem);
  border-radius: 0.625rem;
  line-height: 1.15;
}

.crm-pipeline-title-select select:hover,
.crm-pipeline-title-select select:focus {
  background: rgba(var(--alpha-2));
  border-color: rgb(var(--border-weak));
}

.crm-title-row h1 {
  color: rgb(var(--slate-12));
  font-size: clamp(1.5rem, 1.8vw, 2rem);
  font-weight: 650;
  letter-spacing: 0;
  line-height: 1.12;
}

.crm-page-subtitle {
  line-height: 1.35;
}

.crm-eyebrow,
.crm-live-pill {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  font-size: 0.6875rem;
  font-weight: 700;
  line-height: 1rem;
}

.crm-eyebrow {
  border: 1px solid rgb(var(--border-weak));
  background: rgba(var(--alpha-1));
  color: rgb(var(--slate-10));
  padding: 0.25rem 0.625rem;
  letter-spacing: 0;
  text-transform: uppercase;
}

.crm-live-pill {
  gap: 0.25rem;
  border: 1px solid rgba(var(--label-border));
  background: rgb(var(--surface-2));
  color: rgb(var(--slate-11));
  padding: 0.25rem 0.5rem;
}

.crm-header-actions button,
.crm-config-panel,
.crm-metric-card,
.crm-stage,
.crm-deal-card,
.crm-detail-panel {
  border-radius: var(--crm-panel-radius);
}

.crm-header-actions button {
  display: inline-flex;
  min-width: 0;
  min-height: 2.25rem;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding-inline: 0.75rem;
  box-shadow: none;
}

.crm-header-actions button.bg-n-blue-9,
.crm-config-panel button.bg-n-blue-9,
.crm-detail-panel button.bg-n-blue-9 {
  background: #ff5b25;
  color: white;
  box-shadow: none;
}

.crm-board-tools input,
.crm-board-filter {
  min-height: 2.25rem;
}

.crm-board-filter {
  max-width: 11rem;
}

.crm-config-tabs {
  min-height: 2rem;
}

.crm-config-tab {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  border-bottom: 2px solid transparent;
  color: rgb(var(--slate-11));
  font-size: 0.8125rem;
  font-weight: 650;
  padding: 0.4rem 0.75rem;
}

.crm-config-tab:hover {
  color: rgb(var(--slate-12));
  background: rgba(var(--alpha-2));
}

.crm-config-tab.is-active {
  border-color: #ff5b25;
  color: rgb(var(--slate-12));
}

.crm-rule-row {
  align-items: center;
  background: rgb(var(--surface-1));
}

.crm-rule-row:not(.is-header):hover {
  background: rgba(var(--alpha-2));
}

.crm-rule-row.is-header {
  background: rgba(var(--alpha-1));
}

.crm-metrics {
  grid-template-columns: repeat(auto-fit, minmax(136px, 1fr));
}

.crm-metric-card {
  position: relative;
  min-height: 4.75rem;
  overflow: hidden;
  padding: 0.875rem 1rem;
  background: rgb(var(--surface-2));
  box-shadow: none;
}

.crm-metric-card::before {
  content: none;
}

.crm-metric-icon {
  float: right;
  color: rgb(var(--blue-10));
  opacity: 0.86;
}

.crm-metric-icon-warning {
  color: rgb(var(--amber-10));
}

.crm-metric-icon-danger {
  color: rgb(var(--ruby-10));
}

.crm-metric-card strong {
  font-size: clamp(1rem, 1.1vw, 1.35rem);
  line-height: 1.15;
}

.crm-config-panel {
  box-shadow: none;
}

.crm-config-panel-compact {
  padding: 1rem;
}

.crm-config-panel textarea {
  max-height: 8rem;
  resize: vertical;
}

.crm-workspace {
  background: rgb(var(--background-color));
}

.crm-board-scroll {
  padding: 0.75rem var(--crm-page-padding);
  scrollbar-color: rgba(var(--border-container)) transparent;
  scrollbar-width: thin;
}

.crm-stage {
  position: relative;
  width: clamp(17.5rem, 21vw, 20rem);
  max-height: 100%;
  overflow: hidden;
  border-color: rgb(var(--border-weak));
  background: rgb(var(--surface-2));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.025);
}

.crm-stage > div:first-child {
  padding: 0.75rem 0.875rem;
}

.crm-stage > div:last-child {
  padding: 0.75rem 0.875rem;
}

.crm-stage::before {
  content: none;
}

.crm-stage.accent-green {
  --crm-stage-accent: rgb(var(--blue-9));
}

.crm-stage.accent-blue {
  --crm-stage-accent: rgb(var(--ruby-9));
}

.crm-stage.accent-amber {
  --crm-stage-accent: rgb(var(--amber-9));
}

.crm-stage.accent-violet {
  --crm-stage-accent: rgb(var(--violet-9));
}

.crm-stage.accent-teal {
  --crm-stage-accent: rgb(var(--teal-8));
}

.crm-stage.accent-ruby {
  --crm-stage-accent: rgb(var(--ruby-9));
}

.crm-stage.accent-slate {
  --crm-stage-accent: rgb(var(--slate-9));
}

.crm-stage-dot {
  display: block;
  width: 0.625rem;
  height: 0.625rem;
  flex: 0 0 auto;
  border-radius: 999px;
  background: var(--crm-stage-accent);
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.1);
}

.crm-stage-title {
  min-height: 1.75rem;
  padding: 0.25rem 0;
  background: transparent;
}

.crm-stage-number {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  overflow: hidden;
  border: 1px solid var(--crm-field-border);
  border-radius: 0.5rem;
  background: rgba(var(--background-input-box));
}

.crm-stage-config-row {
  align-items: center;
  background: rgb(var(--surface-1));
}

.crm-stage-table-head,
.crm-webhook-row.is-header {
  background: rgba(var(--alpha-1));
}

.crm-stage-config-row:hover,
.crm-webhook-row:not(.is-header):hover {
  background: rgba(var(--alpha-2));
}

.crm-stage-number input {
  width: 100%;
  min-width: 0;
  min-height: 2.25rem;
  border: 0;
  background: transparent;
  padding: 0.35rem 0.6rem;
  font-size: 0.9375rem;
  font-weight: 700;
  color: rgb(var(--slate-12));
  outline: none;
}

.crm-stage-number b {
  padding-right: 0.6rem;
  color: rgb(var(--slate-11));
  font-size: 0.8125rem;
}

.crm-icon-button {
  width: 2.5rem;
  height: 2.5rem;
  border: 1px solid rgb(var(--border-weak));
  border-radius: 0.75rem;
  background: rgb(var(--surface-1));
}

.crm-add-stage {
  min-height: 16rem;
  border-radius: var(--crm-panel-radius);
}

.crm-deal-card {
  border-color: rgb(var(--border-weak));
  background: rgb(var(--surface-2));
  padding: 0.875rem;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.02);
  transition:
    border-color 160ms ease,
    box-shadow 160ms ease,
    background-color 160ms ease,
    opacity 160ms ease,
    transform 160ms ease;
}

.crm-deal-card:hover {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--solid-2));
  box-shadow: var(--crm-shadow-soft);
  transform: none;
}

.crm-deal-card.is-moving {
  border-color: rgb(var(--border-blue-strong));
  opacity: 0.78;
}

.crm-detail-panel {
  padding: 1.5rem;
  background: rgb(var(--surface-2));
  box-shadow: -1px 0 0 rgb(var(--border-weak));
  scrollbar-color: rgba(var(--border-container)) transparent;
  scrollbar-width: thin;
}

.crm-card-chip {
  display: inline-flex;
  min-width: 0;
  align-items: center;
  gap: 0.25rem;
  border: 1px solid rgba(var(--label-border));
  border-radius: 999px;
  background: rgba(var(--alpha-1));
  padding: 0.25rem 0.5rem;
  color: rgb(var(--slate-11));
}

.crm-card-head {
  grid-template-columns: minmax(0, 1fr) auto;
}

.crm-urgency-chip {
  display: inline-flex;
  max-width: 5.75rem;
  align-items: center;
  gap: 0.375rem;
  border-radius: 0.375rem;
  padding: 0.1875rem 0.45rem;
  font-size: 0.65625rem;
  font-weight: 600;
  line-height: 0.9rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.crm-urgency-fresh {
  background: rgba(var(--teal-9), 0.12);
  color: rgb(var(--teal-11));
}

.crm-urgency-stale {
  background: rgba(var(--amber-9), 0.14);
  color: rgb(var(--amber-11));
}

.crm-urgency-critical {
  background: rgba(var(--ruby-9), 0.14);
  color: rgb(var(--ruby-11));
}

.crm-detail-panel input,
.crm-detail-panel textarea,
.crm-detail-panel select,
.crm-config-panel input,
.crm-config-panel textarea {
  border-radius: 10px;
  background: rgba(var(--background-input-box));
}

.crm-detail-panel input:focus,
.crm-detail-panel textarea:focus,
.crm-detail-panel select:focus,
.crm-config-panel input:focus,
.crm-config-panel textarea:focus {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--solid-2));
  outline: none;
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.14);
}

.crm-product-availability.is-success {
  border-color: rgb(var(--teal-7));
  background: rgb(var(--teal-3));
  color: rgb(var(--teal-11));
}

.crm-product-availability.is-warning {
  border-color: rgb(var(--amber-7));
  background: rgb(var(--amber-3));
  color: rgb(var(--amber-11));
}

.crm-product-availability.is-danger {
  border-color: rgb(var(--ruby-7));
  background: rgb(var(--ruby-3));
  color: rgb(var(--ruby-10));
}

.crm-product-availability.is-info {
  border-color: rgb(var(--blue-7));
  background: rgb(var(--blue-3));
  color: rgb(var(--blue-11));
}

.crm-product-availability.is-muted {
  opacity: 0.75;
}

.crm-contact-avatar {
  display: inline-flex;
  width: 1.75rem;
  height: 1.75rem;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  border: 1px solid rgba(var(--label-border));
  border-radius: 999px;
  background: rgba(255, 91, 37, 0.12);
  color: rgb(var(--blue-11));
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
}

.crm-contact-avatar.is-large {
  width: 2.5rem;
  height: 2.5rem;
  font-size: 1rem;
}

.crm-stage button,
.crm-detail-panel button {
  display: inline-flex;
  min-width: 0;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.crm-stage input,
.crm-control,
.crm-detail-panel input,
.crm-detail-panel select,
.crm-detail-panel textarea,
.crm-config-panel input,
.crm-config-panel select,
.crm-config-panel textarea {
  min-height: 2.5rem;
  border-color: var(--crm-field-border);
  background: var(--crm-field-bg);
  color: rgb(var(--slate-12));
  outline: none;
  transition:
    border-color 160ms ease,
    background-color 160ms ease,
    box-shadow 160ms ease;
}

.crm-stage input:focus,
.crm-control:focus,
.crm-detail-panel input:focus,
.crm-detail-panel select:focus,
.crm-detail-panel textarea:focus,
.crm-config-panel input:focus,
.crm-config-panel select:focus,
.crm-config-panel textarea:focus {
  border-color: rgb(var(--border-blue-strong));
  background: var(--crm-field-bg-focus);
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.14);
}

.crm-stage .crm-stage-number input,
.crm-stage .crm-stage-number input:focus {
  border: 0;
  background: transparent;
  box-shadow: none;
}

.crm-stage .crm-stage-title,
.crm-stage .crm-stage-title:focus {
  min-height: 2rem;
  border: 0;
  background: transparent;
  box-shadow: none;
}

.crm-detail-panel input::placeholder,
.crm-detail-panel textarea::placeholder,
.crm-config-panel input::placeholder,
.crm-config-panel textarea::placeholder {
  color: rgb(var(--slate-10));
}

.crm-detail-panel form {
  gap: 0;
}

.crm-detail-panel label > span:first-child {
  color: rgb(var(--slate-11));
  font-size: 0.8125rem;
}

.crm-detail-panel textarea {
  resize: vertical;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.45;
}

.crm-menu-item {
  display: flex;
  width: 100%;
  align-items: center;
  gap: 0.625rem;
  padding: 0.625rem 0.75rem;
  color: rgb(var(--slate-12));
  font-size: 0.875rem;
  line-height: 1.25rem;
  text-align: left;
}

.crm-menu-item:hover {
  background: rgba(var(--alpha-2));
}

.crm-menu-item-danger {
  color: rgb(var(--ruby-10));
}

.crm-menu-item-danger:hover {
  background: rgb(var(--ruby-3));
}

:global(.dark) .crm-kanban-page {
  --background-color: 13 15 19;
  --surface-1: 13 14 18;
  --surface-2: 24 27 32;
  --solid-1: 24 27 32;
  --solid-2: 28 31 37;
  --solid-3: 32 36 43;
  --card-color: 24 27 32;
  --border-container: 255, 255, 255, 0.08;
  --border-weak: 40 44 51;
  --alpha-1: 255, 255, 255, 0.045;
  --alpha-2: 255, 255, 255, 0.06;
  --alpha-3: 30, 32, 34, 0.96;
  --crm-field-bg: rgba(12, 14, 17, 0.72);
  --crm-field-bg-focus: rgb(28 31 37);
  --crm-field-border: rgb(40 44 51);
  --label-background: 32 36 43;
  --label-border: 255, 255, 255, 0.075;
}

:global(.dark) .crm-workspace {
  background: hsl(220deg 15% 8%);
}

:global(.dark) .crm-stage {
  background: hsl(220deg 15% 11%);
}

:global(.dark) .crm-deal-card {
  background: hsl(220deg 15% 11%);
}

:global(.dark) .crm-deal-card:hover {
  background: rgb(28 31 37);
}

:global(.dark) .crm-card-chip {
  background: rgba(255, 255, 255, 0.055);
}

:global(.dark) .crm-contact-avatar {
  background: rgba(255, 91, 37, 0.12);
}

@media (max-width: 1279px) {
  .crm-workspace {
    grid-template-columns: minmax(0, 1fr);
    overflow: auto;
  }

  .crm-board-scroll {
    min-height: 34rem;
    overflow-y: hidden;
  }

  .crm-detail-panel {
    border-left: 0;
    border-top: 1px solid rgb(var(--border-weak));
    max-height: none;
  }
}

@media (max-width: 900px) {
  .crm-page-header {
    padding: 0.75rem 1rem;
  }

  .crm-pipeline-title-select,
  .crm-board-tools {
    width: 100%;
  }

  .crm-header-actions {
    width: 100%;
  }

  .crm-header-actions button {
    flex: 1 1 auto;
  }

  .crm-header-actions .crm-menu-item {
    flex: none;
  }

  .crm-metrics {
    display: flex;
    gap: 0.75rem;
    margin-inline: -1rem;
    overflow-x: auto;
    padding-inline: 1rem;
    scroll-snap-type: x mandatory;
  }

  .crm-metric-card {
    min-width: 10.5rem;
    scroll-snap-align: start;
  }

  .crm-board-row {
    gap: 1rem;
  }

  .crm-stage {
    width: min(82vw, 20rem);
  }
}

@media (max-width: 640px) {
  .crm-board-scroll {
    padding: 0.75rem;
  }

  .crm-detail-panel {
    padding: 1rem;
  }
}
</style>
