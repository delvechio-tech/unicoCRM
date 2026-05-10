<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
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
const isStageOpen = ref(false);
const isMetricsOpen = ref(false);
const isRulesOpen = ref(false);
const isWebhookOpen = ref(false);
const isSearchingContacts = ref(false);
const isSummarizing = ref(false);
const isSavingActivity = ref(false);

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

const pipelineForm = reactive({
  id: null,
  name: '',
  description: '',
});

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

const visibleCards = stageId =>
  cards.value
    .filter(card => card.stage_id === stageId)
    .sort((a, b) => a.position - b.position || b.id - a.id);

const normalizeList = response =>
  response?.data?.payload || response?.data?.data || response?.data || [];

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

    pipeline.value = boardResponse.data.pipeline;
    pipelines.value = boardResponse.data.pipelines || [boardResponse.data.pipeline].filter(Boolean);
    selectedPipelineId.value = pipeline.value?.id || null;
    stages.value = boardResponse.data.stages;
    cards.value = boardResponse.data.cards;
    metrics.value = boardResponse.data.metrics;
    webhooks.value = boardResponse.data.webhooks || [];
    products.value = productsResponse.data;
    rulesForm.ai_rules = pipeline.value.ai_rules || '';

    if (!stages.value.some(stage => String(stage.id) === String(cardForm.stage_id))) {
      resetCardForm(null, false);
    }
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel carregar o Kanban.');
  } finally {
    isLoading.value = false;
  }
};

const reloadCurrentBoard = async () => {
  const response = await kanbanAPI.getBoard(
    selectedPipelineId.value ? { pipeline_id: selectedPipelineId.value } : {}
  );
  pipeline.value = response.data.pipeline;
  pipelines.value = response.data.pipelines || [];
  selectedPipelineId.value = pipeline.value?.id || null;
  stages.value = response.data.stages;
  cards.value = response.data.cards;
  metrics.value = response.data.metrics;
  webhooks.value = response.data.webhooks || [];
  rulesForm.ai_rules = pipeline.value.ai_rules || '';
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
  });
  isPipelineOpen.value = true;
};

const savePipeline = async () => {
  try {
    const payload = {
      pipeline: {
        name: pipelineForm.name,
        description: pipelineForm.description,
      },
    };

    const response = pipelineForm.id
      ? await kanbanAPI.updatePipeline(pipelineForm.id, payload)
      : await kanbanAPI.createPipeline(payload);

    pipeline.value = response.data.pipeline;
    pipelines.value = response.data.pipelines || [];
    selectedPipelineId.value = pipeline.value.id;
    stages.value = response.data.stages;
    cards.value = response.data.cards;
    metrics.value = response.data.metrics;
    webhooks.value = response.data.webhooks || [];
    rulesForm.ai_rules = pipeline.value.ai_rules || '';
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
    pipeline.value = response.data.pipeline;
    pipelines.value = response.data.pipelines || [];
    selectedPipelineId.value = pipeline.value.id;
    stages.value = response.data.stages;
    cards.value = response.data.cards;
    metrics.value = response.data.metrics;
    webhooks.value = response.data.webhooks || [];
    rulesForm.ai_rules = pipeline.value.ai_rules || '';
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
    isStageOpen.value = false;
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
    useAlert(error.message || 'Nao foi possivel salvar o card.');
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

const deleteCard = async card => {
  if (!window.confirm(`Arquivar o card ${card.title}?`)) return;

  await kanbanAPI.deleteCard(card.id, { pipeline_id: selectedPipelineId.value });
  useAlert('Card arquivado.');
  if (selectedCardId.value === card.id) closeDetailPanel();
  await loadBoard();
};

const saveRules = async () => {
  try {
    const response = await kanbanAPI.updatePipeline(pipeline.value.id, {
      pipeline: { ai_rules: rulesForm.ai_rules },
    });
    pipeline.value = response.data.pipeline;
    pipelines.value = response.data.pipelines || [];
    stages.value = response.data.stages;
    cards.value = response.data.cards;
    metrics.value = response.data.metrics;
    webhooks.value = response.data.webhooks || [];
    useAlert('Regras da IA atualizadas.');
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel salvar as regras.');
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
    useAlert(error.message || 'Nao foi possivel criar a atividade.');
  } finally {
    isSavingActivity.value = false;
  }
};

const completeActivity = async activity => {
  if (!selectedCard.value) return;

  await kanbanAPI.completeActivity(selectedCard.value.id, activity.id, {
    pipeline_id: selectedPipelineId.value,
  });
  useAlert('Atividade concluida.');
  await loadBoard();
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
    useAlert(error.message || 'Nao foi possivel criar o webhook.');
  }
};

const deleteWebhook = async webhook => {
  if (!window.confirm(`Excluir webhook ${webhook.name}?`)) return;

  await kanbanAPI.deleteWebhook(webhook.id);
  useAlert('Webhook excluido.');
  await loadBoard();
};

const updateStage = async stage => {
  try {
    await kanbanAPI.updateStage(stage.id, {
      pipeline_id: selectedPipelineId.value,
      stage: {
        name: stage.name,
        stale_after_days: stage.stale_after_days,
        win_probability: stage.win_probability,
      },
    });
    useAlert('Etapa atualizada.');
    await loadBoard();
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel salvar a etapa.');
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
    pipeline.value = response.data.pipeline;
    pipelines.value = response.data.pipelines || [];
    stages.value = response.data.stages;
    cards.value = response.data.cards;
    metrics.value = response.data.metrics;
    webhooks.value = response.data.webhooks || [];
    rulesForm.ai_rules = pipeline.value.ai_rules || '';
  } catch (error) {
    card.stage_id = previousStageId;
    useAlert(error.message || 'Nao foi possivel mover o card.');
  } finally {
    pendingCardMoveIds.value = pendingCardMoveIds.value.filter(id => id !== card.id);
  }
};

const staleClass = card => {
  if (card.stale_level === 'critical') return 'border-n-ruby-8';
  if (card.stale_level === 'stale') return 'border-n-amber-8';
  return 'border-n-weak';
};

const staleLabel = card => {
  if (card.stale_level === 'critical') return `${card.stale_days}d parado`;
  if (card.stale_level === 'stale') return `${card.stale_days}d sem avanco`;
  return 'Em dia';
};

const stageAccentClass = index =>
  ['accent-green', 'accent-blue', 'accent-amber', 'accent-violet', 'accent-teal', 'accent-ruby'][
    index % 6
  ];

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

onMounted(loadBoard);
</script>

<template>
  <main class="crm-kanban-page flex h-full min-h-0 flex-1 flex-col bg-n-background">
    <header class="crm-page-header border-b border-n-weak px-6 py-4">
      <div class="crm-title-row flex flex-wrap items-start justify-between gap-4">
        <div>
          <div class="mb-2 flex items-center gap-2">
            <span class="crm-eyebrow">CRM Pipeline</span>
            <span class="crm-live-pill">
              <span class="i-lucide-radio size-3.5" />
              Sync ativo
            </span>
          </div>
          <h1 class="text-2xl font-semibold text-n-slate-12">Kanban comercial</h1>
          <p class="crm-page-subtitle mt-1 max-w-3xl text-sm text-n-slate-11">
            Oportunidades, conversas e proximas acoes no mesmo fluxo.
          </p>
        </div>
        <div class="crm-header-actions flex flex-wrap gap-2">
          <button
            class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12"
            :class="{ 'bg-n-alpha-2 text-n-blue-11': isMetricsOpen }"
            type="button"
            @click="isMetricsOpen = !isMetricsOpen"
          >
            <span class="i-lucide-bar-chart-3 size-4" />
            Metricas · {{ metrics.total_cards || 0 }} ativos
          </button>
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12" type="button" @click="isRulesOpen = !isRulesOpen">
            <span class="i-lucide-sparkles size-4" />
            Regras da IA
          </button>
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12" type="button" @click="isWebhookOpen = !isWebhookOpen">
            <span class="i-lucide-webhook size-4" />
            Webhooks
          </button>
          <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="button" @click="resetCardForm()">
            <span class="i-lucide-plus size-4" />
            Novo card
          </button>
        </div>
      </div>

      <div class="crm-pipeline-toolbar mt-4 flex flex-wrap items-end justify-between gap-3">
        <label class="min-w-[240px] flex-1">
          <span class="mb-1 block text-xs font-semibold uppercase text-n-slate-10">Funil ativo</span>
          <select v-model="selectedPipelineId" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" @change="selectPipeline">
            <option v-for="item in pipelines" :key="item.id" :value="item.id">
              {{ item.name }}
            </option>
          </select>
        </label>
        <div class="crm-header-actions flex flex-wrap gap-2">
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12" type="button" @click="openPipelineForm(pipeline)">
            <span class="i-lucide-settings-2 size-4" />
            Configurar funil
          </button>
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12" type="button" @click="openPipelineForm()">
            <span class="i-lucide-folder-plus size-4" />
            Novo funil
          </button>
          <button class="rounded-md border border-n-weak px-3 py-2 text-sm text-n-slate-12" type="button" @click="isStageOpen = !isStageOpen">
            <span class="i-lucide-columns-3 size-4" />
            Etapas
          </button>
        </div>
      </div>

      <form v-if="isPipelineOpen" class="crm-config-panel mt-4 border border-n-weak bg-n-solid-1 p-4" @submit.prevent="savePipeline">
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
        <div class="grid gap-3 md:grid-cols-[1fr_1.3fr_auto]">
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Nome do funil</span>
            <input v-model="pipelineForm.name" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Descricao</span>
            <input v-model="pipelineForm.description" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <div class="flex items-end gap-2">
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-save size-4" />
              Salvar
            </button>
          </div>
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

      <section v-if="isStageOpen" class="crm-config-panel mt-4 border border-n-weak bg-n-solid-1 p-4">
        <div class="mb-4 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-sm font-semibold tracking-tight text-n-slate-12">Configuracao das etapas</h2>
            <p class="mt-1 text-xs text-n-slate-11">
              Defina manualmente os prazos e probabilidades sem poluir o board.
            </p>
          </div>
          <button class="text-sm text-n-slate-11 hover:text-n-slate-12" type="button" @click="isStageOpen = false">
            Fechar
          </button>
        </div>

        <form class="grid gap-3 md:grid-cols-[1fr_140px_140px_auto]" @submit.prevent="createStage">
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Nome da etapa</span>
            <input v-model="stageForm.name" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Ex: Proposta aceita" />
          </label>
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Parado apos</span>
            <input v-model="stageForm.stale_after_days" type="number" min="0" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <label>
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Chance %</span>
            <input v-model="stageForm.win_probability" type="number" min="0" max="100" required class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
          </label>
          <div class="flex items-end gap-2">
            <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
              <span class="i-lucide-plus size-4" />
              Adicionar
            </button>
          </div>
        </form>

        <div v-if="stages.length" class="mt-5 space-y-2">
          <article
            v-for="stage in stages"
            :key="`stage-config-${stage.id}`"
            class="crm-stage-config-row grid gap-3 border border-n-weak bg-n-alpha-1 p-3 md:grid-cols-[minmax(0,1fr)_140px_140px_auto]"
          >
            <label>
              <span class="mb-1 block text-xs font-medium uppercase text-n-slate-10">Etapa</span>
              <input v-model="stage.name" class="crm-control w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" @change="updateStage(stage)" />
            </label>
            <label>
              <span class="mb-1 block text-xs font-medium uppercase text-n-slate-10">Parado apos</span>
              <div class="crm-stage-number">
                <input v-model="stage.stale_after_days" type="number" min="0" @change="updateStage(stage)" />
                <b>d</b>
              </div>
            </label>
            <label>
              <span class="mb-1 block text-xs font-medium uppercase text-n-slate-10">Chance</span>
              <div class="crm-stage-number">
                <input v-model="stage.win_probability" type="number" min="0" max="100" @change="updateStage(stage)" />
                <b>%</b>
              </div>
            </label>
            <div class="flex items-end">
              <button class="rounded-md border border-n-ruby-7 px-3 py-2 text-sm text-n-ruby-10 hover:bg-n-ruby-3" type="button" @click="deleteStage(stage)">
                Excluir
              </button>
            </div>
          </article>
        </div>
      </section>

      <div v-if="isMetricsOpen" class="crm-metrics mt-4 grid gap-3 md:grid-cols-3 xl:grid-cols-6">
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
      </div>

      <form v-if="isRulesOpen" class="crm-config-panel mt-4 border border-n-weak bg-n-solid-1 p-4" @submit.prevent="saveRules">
        <label class="block">
          <span class="mb-2 block text-sm font-medium text-n-slate-12">Regras para movimentacao da IA</span>
          <textarea v-model="rulesForm.ai_rules" rows="5" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" />
        </label>
        <button class="mt-3 rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">
          Salvar regras
        </button>
      </form>

      <section v-if="isWebhookOpen" class="crm-config-panel mt-4 grid gap-4 border border-n-weak bg-n-solid-1 p-4 lg:grid-cols-[1fr_360px]">
        <div>
          <h2 class="text-sm font-semibold text-n-slate-12">Webhooks do funil</h2>
          <div v-if="webhooks.length" class="mt-3 space-y-2">
            <article v-for="webhook in webhooks" :key="webhook.id" class="flex items-start justify-between gap-3 border border-n-weak p-3">
              <div class="min-w-0">
                <strong class="block truncate text-sm text-n-slate-12">{{ webhook.name }}</strong>
                <span class="block truncate text-xs text-n-slate-11">{{ webhook.url }}</span>
                <span class="mt-1 block text-xs text-n-slate-10">{{ webhook.events?.join(', ') || 'Todos os eventos' }}</span>
              </div>
              <button class="text-sm text-n-ruby-10" type="button" @click="deleteWebhook(webhook)">Excluir</button>
            </article>
          </div>
          <p v-else class="mt-3 text-sm text-n-slate-11">Nenhum webhook configurado.</p>
        </div>
        <form class="space-y-3" @submit.prevent="createWebhook">
          <input v-model="webhookForm.name" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Nome do webhook" />
          <input v-model="webhookForm.url" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="https://..." />
          <input v-model="webhookForm.access_token" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="Segredo para assinatura" />
          <input v-model="webhookForm.events" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12" placeholder="card.created, card.moved" />
          <button class="rounded-md bg-n-blue-9 px-3 py-2 text-sm font-semibold text-white" type="submit">Adicionar webhook</button>
        </form>
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
            :class="stageAccentClass(stageIndex)"
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
                <div class="flex items-start justify-between gap-3">
                  <h3 class="min-w-0 text-sm font-bold leading-5 text-n-slate-12">{{ card.title }}</h3>
                  <span class="shrink-0 rounded-md bg-n-alpha-2 px-2 py-1 text-[11px] font-medium text-n-blue-11">{{ staleLabel(card) }}</span>
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

          <button class="crm-add-stage flex w-[260px] shrink-0 flex-col items-center justify-center gap-2 border border-dashed border-n-weak bg-n-alpha-1 p-6 text-sm font-semibold text-n-slate-11 hover:border-n-blue-8 hover:bg-n-alpha-2 hover:text-n-blue-11" type="button" @click="isStageOpen = true">
            <span class="i-lucide-columns-3 size-5" />
            Adicionar etapa
          </button>
        </div>
      </div>

      <aside
        v-if="isDetailOpen"
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
  padding: var(--crm-page-padding);
  background: rgb(var(--background-color));
}

.crm-title-row {
  align-items: center;
}

.crm-title-row h1 {
  color: rgb(var(--slate-12));
  font-size: clamp(1.5rem, 1.8vw, 2rem);
  font-weight: 600;
  letter-spacing: -0.01em;
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
  background: rgb(var(--surface-1));
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
  min-height: 2.5rem;
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

.crm-metrics {
  grid-template-columns: repeat(auto-fit, minmax(136px, 1fr));
}

.crm-metric-card {
  position: relative;
  min-height: 4.75rem;
  overflow: hidden;
  padding: 1rem;
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
  font-size: clamp(1.1rem, 1.25vw, 1.5rem);
  line-height: 1.15;
}

.crm-config-panel {
  box-shadow: none;
}

.crm-config-panel textarea {
  max-height: 8rem;
  resize: vertical;
}

.crm-workspace {
  background: rgb(var(--background-color));
}

.crm-board-scroll {
  padding: var(--crm-page-padding);
  scrollbar-color: rgba(var(--border-container)) transparent;
  scrollbar-width: thin;
}

.crm-stage {
  position: relative;
  width: clamp(19rem, 23vw, 22rem);
  max-height: 100%;
  overflow: hidden;
  border-color: rgb(var(--border-weak));
  background: rgb(var(--surface-2));
  box-shadow: none;
}

.crm-stage > div:first-child {
  padding: 1rem;
}

.crm-stage > div:last-child {
  padding: 1rem;
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
  min-height: 2rem;
  padding: 0.25rem 0.35rem;
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
  border-radius: var(--crm-panel-radius);
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
  padding: 1rem;
  box-shadow: none;
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

:global(.dark) .crm-kanban-page {
  --background-color: 17 19 23;
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
    padding: 1rem;
  }

  .crm-header-actions {
    width: 100%;
  }

  .crm-header-actions button {
    flex: 1 1 auto;
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
