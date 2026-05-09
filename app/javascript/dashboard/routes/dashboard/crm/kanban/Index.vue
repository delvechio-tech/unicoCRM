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
const stages = ref([]);
const cards = ref([]);
const metrics = ref({});
const products = ref([]);
const webhooks = ref([]);
const contactResults = ref([]);
const selectedCardId = ref(null);
const draggedCardId = ref(null);
const pendingCardMoveIds = ref([]);
const isLoading = ref(false);
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

const resetCardForm = stageId => {
  selectedCardId.value = null;
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

const loadBoard = async () => {
  isLoading.value = true;
  try {
    const [boardResponse, productsResponse] = await Promise.all([
      kanbanAPI.get(),
      productsAPI.get(),
    ]);

    pipeline.value = boardResponse.data.pipeline;
    stages.value = boardResponse.data.stages;
    cards.value = boardResponse.data.cards;
    metrics.value = boardResponse.data.metrics;
    webhooks.value = boardResponse.data.webhooks || [];
    products.value = productsResponse.data;
    rulesForm.ai_rules = pipeline.value.ai_rules || '';

    if (!cardForm.stage_id) resetCardForm();
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel carregar o Kanban.');
  } finally {
    isLoading.value = false;
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
    resetCardForm(cardForm.stage_id);
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

  await kanbanAPI.deleteCard(card.id);
  useAlert('Card arquivado.');
  if (selectedCardId.value === card.id) resetCardForm();
  await loadBoard();
};

const saveRules = async () => {
  try {
    const response = await kanbanAPI.updatePipeline({
      pipeline: { ai_rules: rulesForm.ai_rules },
    });
    pipeline.value = response.data.pipeline;
    stages.value = response.data.stages;
    cards.value = response.data.cards;
    metrics.value = response.data.metrics;
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

  await kanbanAPI.completeActivity(selectedCard.value.id, activity.id);
  useAlert('Atividade concluida.');
  await loadBoard();
};

const createWebhook = async () => {
  try {
    await kanbanAPI.createWebhook({
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
    await kanbanAPI.updateCard(card.id, { card: { stage_id: stage.id } });
    const response = await kanbanAPI.get();
    pipeline.value = response.data.pipeline;
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

      <div class="crm-metrics mt-4 grid gap-3 md:grid-cols-3 xl:grid-cols-6">
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

    <section class="crm-workspace grid min-h-0 flex-1 grid-cols-1 overflow-hidden xl:grid-cols-[minmax(0,1fr)_360px]">
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
                  <input v-model="stage.name" class="min-w-0 flex-1 bg-transparent text-sm font-bold text-n-slate-12 outline-none" @change="updateStage(stage)" />
                </div>
                <span class="rounded-md bg-n-alpha-2 px-2.5 py-1 text-xs font-semibold text-n-blue-11">{{ visibleCards(stage.id).length }}</span>
              </div>
              <div class="mt-2 grid grid-cols-2 gap-2 text-xs text-n-slate-11">
                <label class="flex items-center gap-1">
                  Parado
                  <input v-model="stage.stale_after_days" type="number" min="0" class="w-14 rounded border border-n-weak bg-n-alpha-2 px-2 py-1" @change="updateStage(stage)" />
                  d
                </label>
                <label class="flex items-center gap-1">
                  Chance
                  <input v-model="stage.win_probability" type="number" min="0" max="100" class="w-14 rounded border border-n-weak bg-n-alpha-2 px-2 py-1" @change="updateStage(stage)" />
                  %
                </label>
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
        </div>
      </div>

      <aside class="crm-detail-panel min-h-0 overflow-y-auto border-l border-n-weak bg-n-solid-1 p-5">
        <div class="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-semibold text-n-slate-12">{{ selectedCard ? 'Editar card' : 'Novo card' }}</h2>
            <p class="text-sm text-n-slate-11">Cliente, conversa, agenda e contexto comercial.</p>
          </div>
          <button v-if="selectedCard" class="text-sm text-n-blue-text" type="button" @click="resetCardForm(cardForm.stage_id)">Limpar</button>
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
  --crm-panel-radius: 8px;
  --crm-page-padding: clamp(0.875rem, 1.35vw, 1.25rem);
  --crm-shadow-soft: 0 1px 2px rgba(15, 23, 42, 0.04), 0 8px 24px rgba(15, 23, 42, 0.05);
  --crm-stage-accent: rgb(var(--blue-9));
  --alpha-1: 15, 118, 110, 0.055;
  --alpha-2: 15, 118, 110, 0.075;
  --background-input-box: 255, 255, 255, 0.82;
}

.crm-page-header {
  padding: var(--crm-page-padding);
  background:
    radial-gradient(circle at 12% 0%, rgba(var(--alpha-1)) 0, transparent 34%),
    linear-gradient(180deg, rgb(var(--surface-2)) 0%, rgb(var(--background-color)) 100%);
}

.crm-title-row {
  align-items: center;
}

.crm-title-row h1 {
  font-size: clamp(1.5rem, 1.8vw, 2rem);
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
  background: rgb(var(--solid-blue-2));
  color: rgb(var(--text-blue));
  padding: 0.25rem 0.625rem;
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
  box-shadow: 0 1px 1px rgba(15, 23, 42, 0.03);
}

.crm-metrics {
  grid-template-columns: repeat(auto-fit, minmax(136px, 1fr));
}

.crm-metric-card {
  position: relative;
  min-height: 4.75rem;
  overflow: hidden;
  padding: 0.85rem;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.035);
}

.crm-metric-card::before {
  position: absolute;
  inset: 0 0 auto;
  height: 3px;
  background: linear-gradient(90deg, rgb(var(--blue-8)), rgb(var(--teal-7)));
  content: '';
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
  box-shadow: 0 1px 2px rgba(14, 33, 31, 0.04);
}

.crm-config-panel textarea {
  max-height: 8rem;
  resize: vertical;
}

.crm-workspace {
  background:
    linear-gradient(rgba(var(--black-alpha-2)), rgba(var(--black-alpha-2))),
    rgb(var(--background-color));
}

.crm-board-scroll {
  padding: var(--crm-page-padding);
  scrollbar-color: rgba(var(--border-container)) transparent;
  scrollbar-width: thin;
}

.crm-stage {
  position: relative;
  width: clamp(18rem, 22vw, 20.5rem);
  max-height: 100%;
  overflow: hidden;
  border-color: rgba(var(--border-container));
  background:
    linear-gradient(180deg, rgba(var(--alpha-3)) 0%, rgb(var(--surface-1)) 100%);
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.crm-stage > div:first-child {
  padding: 0.875rem 1rem;
}

.crm-stage > div:last-child {
  padding: 0.875rem;
}

.crm-stage::before {
  position: absolute;
  inset: 0 0 auto;
  height: 3px;
  background: var(--crm-stage-accent);
  content: '';
}

.crm-stage.accent-green {
  --crm-stage-accent: rgb(var(--teal-9));
}

.crm-stage.accent-blue {
  --crm-stage-accent: rgb(var(--blue-9));
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
  box-shadow: 0 0 0 3px rgba(var(--alpha-1));
}

.crm-deal-card {
  border-color: rgba(var(--border-container));
  background: rgb(var(--surface-2));
  padding: 0.875rem;
  box-shadow: 0 1px 1px rgba(15, 23, 42, 0.03);
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
  transform: translateY(-1px);
}

.crm-deal-card.is-moving {
  border-color: rgb(var(--border-blue-strong));
  opacity: 0.78;
}

.crm-detail-panel {
  padding: 1rem;
  background:
    linear-gradient(180deg, rgb(var(--surface-2)) 0%, rgb(var(--surface-1)) 100%);
  box-shadow: -1px 0 0 rgba(var(--border-container));
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
  background: rgb(var(--label-background));
  padding: 0.25rem 0.5rem;
  color: rgb(var(--slate-11));
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
  background: linear-gradient(135deg, rgb(var(--solid-blue-2)), rgb(var(--surface-2)));
  color: rgb(var(--text-blue));
  font-size: 0.75rem;
  font-weight: 800;
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
.crm-detail-panel input,
.crm-detail-panel select,
.crm-detail-panel textarea,
.crm-config-panel input,
.crm-config-panel textarea {
  min-height: 2.25rem;
  background: rgba(var(--background-input-box));
  outline: none;
  transition:
    border-color 160ms ease,
    background-color 160ms ease,
    box-shadow 160ms ease;
}

.crm-stage input:focus,
.crm-detail-panel input:focus,
.crm-detail-panel select:focus,
.crm-detail-panel textarea:focus,
.crm-config-panel input:focus,
.crm-config-panel textarea:focus {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--surface-2));
  box-shadow: 0 0 0 3px rgba(var(--border-blue));
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

:global(.dark) .crm-kanban-page {
  --background-color: 18 20 22;
  --surface-1: 24 26 28;
  --surface-2: 30 32 34;
  --solid-1: 28 30 32;
  --solid-2: 34 36 38;
  --solid-3: 39 42 44;
  --card-color: 32 34 36;
  --border-container: 255, 255, 255, 0.085;
  --border-weak: 56 61 64;
  --alpha-1: 255, 255, 255, 0.045;
  --alpha-2: 255, 255, 255, 0.06;
  --alpha-3: 30, 32, 34, 0.96;
  --background-input-box: 255, 255, 255, 0.045;
  --label-background: 255 255 255;
  --label-border: 255, 255, 255, 0.075;
}

:global(.dark) .crm-workspace {
  background: rgb(15 17 18);
}

:global(.dark) .crm-stage {
  background: linear-gradient(180deg, rgb(29 31 33) 0%, rgb(24 26 28) 100%);
}

:global(.dark) .crm-deal-card {
  background: rgb(32 34 36);
}

:global(.dark) .crm-deal-card:hover {
  background: rgb(37 40 42);
}

:global(.dark) .crm-card-chip {
  background: rgba(255, 255, 255, 0.055);
}

:global(.dark) .crm-contact-avatar {
  background: linear-gradient(135deg, rgba(94, 234, 212, 0.16), rgba(255, 255, 255, 0.055));
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
