<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useAlert } from 'dashboard/composables';

import aiAgentsAPI from 'dashboard/api/crm/aiAgents';
import productsAPI from 'dashboard/api/crm/products';
import inboxesAPI from 'dashboard/api/inboxes';

const agents = ref([]);
const products = ref([]);
const inboxes = ref([]);
const activeResource = ref('agents');
const activeAgentSection = ref('profile');
const isLoading = ref(false);
const isPlaygroundLoading = ref(false);
const selectedAgentId = ref(null);
const selectedProductId = ref(null);
const playgroundInput = ref('Quero conhecer as opcoes disponiveis.');
const playgroundResponse = ref('');
const productMediaFiles = ref([]);
const faqItems = ref([{ question: '', answer: '' }]);
const objectionItems = ref([{ question: '', answer: '' }]);
const mediaLinks = ref([{ label: '', url: '' }]);

const toneOptions = [
  'Consultivo',
  'Objetivo',
  'Amigavel',
  'Premium',
  'Tecnico',
];

const salesTechniqueOptions = [
  'SPIN Selling',
  'AIDA',
  'Challenger',
  'Consultiva',
  'Sandler',
];

const roleOptions = ['Vendas', 'SDR', 'Suporte', 'CS', 'Ecommerce'];

const availabilityOptions = [
  { value: 'in_stock', label: 'Disponivel' },
  { value: 'out_of_stock', label: 'Sem estoque' },
  { value: 'pre_order', label: 'Pre-venda' },
  { value: 'discontinued', label: 'Descontinuado' },
];

const agentSections = [
  {
    key: 'profile',
    label: 'Perfil',
    icon: 'i-lucide-id-card',
    description: 'Nome, papel e identidade do agente.',
  },
  {
    key: 'knowledge',
    label: 'Conhecimento',
    icon: 'i-lucide-library-big',
    description: 'Produtos e contexto comercial consultados pela IA.',
  },
  {
    key: 'behavior',
    label: 'Comportamento',
    icon: 'i-lucide-message-square-text',
    description: 'Tom, objetivo, personalidade e tecnica de venda.',
  },
  {
    key: 'channels',
    label: 'Canais',
    icon: 'i-lucide-inbox',
    description: 'Caixas onde o agente pode atuar.',
  },
  {
    key: 'automation',
    label: 'Automacao',
    icon: 'i-lucide-workflow',
    description: 'Webhook do n8n e modo de resposta.',
  },
];

const agentForm = reactive({
  name: '',
  gender: '',
  role: '',
  communication_tone: '',
  sales_technique: '',
  n8n_webhook_url: '',
  company_context: '',
  objective: '',
  personality: '',
  active: true,
  auto_reply_enabled: false,
  product_ids: [],
  inbox_ids: [],
});

const productForm = reactive({
  name: '',
  sku: '',
  category: '',
  currency: 'BRL',
  price: '',
  active: true,
  availability_status: 'in_stock',
  track_inventory: false,
  stock_quantity: 0,
  reserved_quantity: 0,
  low_stock_threshold: 0,
  description: '',
  faq: '',
  objections: '',
  media_notes: '',
  metadata: {},
});

const selectedAgent = computed(() =>
  agents.value.find(agent => agent.id === selectedAgentId.value)
);

const selectedProduct = computed(() =>
  products.value.find(product => product.id === selectedProductId.value)
);

const linkedProducts = computed(() =>
  products.value.filter(product => agentForm.product_ids.includes(product.id))
);

const linkedInboxes = computed(() =>
  inboxes.value.filter(inbox => agentForm.inbox_ids.includes(inbox.id))
);

const selectedProductLinkedAgents = computed(() =>
  agents.value.filter(agent =>
    (agent.product_ids || []).includes(selectedProductId.value)
  )
);

const activeSectionMeta = computed(() =>
  agentSections.find(section => section.key === activeAgentSection.value)
);

const currentPreviewMessage = computed(() => {
  if (playgroundResponse.value) return playgroundResponse.value;

  if (linkedProducts.value.length) {
    return `Encontrei ${linkedProducts.value[0].name}. Posso te explicar preco, beneficios e tirar duvidas antes de indicar o melhor caminho.`;
  }

  return 'Vincule produtos para o agente consultar catalogo, FAQs e objecoes antes de responder.';
});

const resetAgentForm = () => {
  selectedAgentId.value = null;
  activeAgentSection.value = 'profile';
  Object.assign(agentForm, {
    name: '',
    gender: '',
    role: '',
    communication_tone: '',
    sales_technique: '',
    n8n_webhook_url: '',
    company_context: '',
    objective: '',
    personality: '',
    active: true,
    auto_reply_enabled: false,
    product_ids: [],
    inbox_ids: [],
  });
};

const resetProductForm = () => {
  selectedProductId.value = null;
  productMediaFiles.value = [];
  faqItems.value = [{ question: '', answer: '' }];
  objectionItems.value = [{ question: '', answer: '' }];
  mediaLinks.value = [{ label: '', url: '' }];
  Object.assign(productForm, {
    name: '',
    sku: '',
    category: '',
    currency: 'BRL',
    price: '',
    active: true,
    availability_status: 'in_stock',
    track_inventory: false,
    stock_quantity: 0,
    reserved_quantity: 0,
    low_stock_threshold: 0,
    description: '',
    faq: '',
    objections: '',
    media_notes: '',
    metadata: {},
  });
};

const loadData = async () => {
  isLoading.value = true;
  try {
    const [agentsResponse, productsResponse, inboxesResponse] =
      await Promise.all([aiAgentsAPI.get(), productsAPI.get(), inboxesAPI.get()]);

    agents.value = agentsResponse.data;
    products.value = productsResponse.data;
    inboxes.value = inboxesResponse.data.payload || inboxesResponse.data || [];

    if (!selectedAgentId.value && agents.value.length) {
      editAgent(agents.value[0]);
    }

    if (!selectedProductId.value && products.value.length) {
      editProduct(products.value[0]);
    }
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel carregar os dados do CRM.');
  } finally {
    isLoading.value = false;
  }
};

const selectAgent = agent => {
  activeResource.value = 'agents';
  editAgent(agent);
};

const selectProduct = product => {
  activeResource.value = 'products';
  editProduct(product);
};

const editAgent = agent => {
  selectedAgentId.value = agent.id;
  playgroundResponse.value = '';
  Object.assign(agentForm, {
    name: agent.name || '',
    gender: agent.gender || '',
    role: agent.role || '',
    communication_tone: agent.communication_tone || '',
    sales_technique: agent.sales_technique || '',
    n8n_webhook_url: agent.n8n_webhook_url || '',
    company_context: agent.company_context || '',
    objective: agent.objective || '',
    personality: agent.personality || '',
    active: agent.active,
    auto_reply_enabled: agent.auto_reply_enabled,
    product_ids: agent.product_ids || [],
    inbox_ids: agent.inbox_ids || [],
  });
};

const editProduct = product => {
  selectedProductId.value = product.id;
  productMediaFiles.value = [];
  faqItems.value = normalizeStructuredItems(product.metadata?.faq_items, product.faq);
  objectionItems.value = normalizeStructuredItems(
    product.metadata?.objection_items,
    product.objections
  );
  mediaLinks.value = normalizeMediaLinks(product.metadata?.media_links);
  Object.assign(productForm, {
    name: product.name || '',
    sku: product.sku || '',
    category: product.category || '',
    currency: product.currency || 'BRL',
    price: product.price || '',
    active: product.active,
    availability_status: product.availability_status || 'in_stock',
    track_inventory: product.track_inventory || false,
    stock_quantity: product.stock_quantity || 0,
    reserved_quantity: product.reserved_quantity || 0,
    low_stock_threshold: product.low_stock_threshold || 0,
    description: product.description || '',
    faq: product.faq || '',
    objections: product.objections || '',
    media_notes: product.media_notes || '',
    metadata: product.metadata || {},
  });
};

const saveAgent = async () => {
  try {
    const payload = { ai_agent: { ...agentForm } };
    if (selectedAgentId.value) {
      await aiAgentsAPI.update(selectedAgentId.value, payload);
      useAlert('Agente atualizado.');
    } else {
      await aiAgentsAPI.create(payload);
      useAlert('Agente criado.');
    }
    await loadData();
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel salvar o agente.');
  }
};

const saveProduct = async () => {
  try {
    const payload = buildProductPayload();
    if (selectedProductId.value) {
      await productsAPI.updateWithFiles(selectedProductId.value, payload);
      useAlert('Produto atualizado.');
    } else {
      await productsAPI.createWithFiles(payload);
      useAlert('Produto criado.');
    }
    await loadData();
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel salvar o produto.');
  }
};

const deleteAgent = async agent => {
  if (!window.confirm(`Excluir o agente ${agent.name}?`)) return;
  await aiAgentsAPI.delete(agent.id);
  useAlert('Agente excluido.');
  if (selectedAgentId.value === agent.id) resetAgentForm();
  await loadData();
};

const deleteProduct = async product => {
  if (!window.confirm(`Excluir o produto ${product.name}?`)) return;
  await productsAPI.delete(product.id);
  useAlert('Produto excluido.');
  if (selectedProductId.value === product.id) resetProductForm();
  await loadData();
};

const setAgentField = (field, value) => {
  agentForm[field] = value;
};

const toggleArrayValue = (collection, value) => {
  const index = collection.indexOf(value);
  if (index >= 0) {
    collection.splice(index, 1);
  } else {
    collection.push(value);
  }
};

const formatPrice = product => {
  if (!product.price) return 'Sem preco';

  return `${product.currency || 'BRL'} ${product.price}`;
};

const normalizeStructuredItems = (items, legacyText = '') => {
  if (Array.isArray(items) && items.length) {
    return items.map(item => ({
      question: item.question || '',
      answer: item.answer || '',
    }));
  }

  if (legacyText) {
    return [{ question: '', answer: legacyText }];
  }

  return [{ question: '', answer: '' }];
};

const normalizeMediaLinks = links => {
  if (Array.isArray(links) && links.length) {
    return links.map(link => ({ label: link.label || '', url: link.url || '' }));
  }

  return [{ label: '', url: '' }];
};

const compactStructuredItems = items =>
  items
    .map(item => ({
      question: item.question.trim(),
      answer: item.answer.trim(),
    }))
    .filter(item => item.question || item.answer);

const compactMediaLinks = () =>
  mediaLinks.value
    .map(link => ({ label: link.label.trim(), url: link.url.trim() }))
    .filter(link => link.label || link.url);

const serializeStructuredItems = items =>
  compactStructuredItems(items)
    .map(item =>
      [
        item.question && `Pergunta: ${item.question}`,
        item.answer && `Resposta: ${item.answer}`,
      ]
        .filter(Boolean)
        .join('\n')
    )
    .join('\n\n');

const buildProductPayload = () => {
  const payload = new FormData();
  const product = {
    ...productForm,
    faq: serializeStructuredItems(faqItems.value),
    objections: serializeStructuredItems(objectionItems.value),
    media_notes: [
      productForm.media_notes,
      compactMediaLinks()
        .map(link => `${link.label || 'Link'}: ${link.url}`)
        .join('\n'),
    ]
      .filter(Boolean)
      .join('\n\n'),
    metadata: {
      ...(productForm.metadata || {}),
      faq_items: compactStructuredItems(faqItems.value),
      objection_items: compactStructuredItems(objectionItems.value),
      media_links: compactMediaLinks(),
    },
  };

  Object.entries(product).forEach(([key, value]) => {
    if (key === 'metadata') {
      Object.entries(value).forEach(([metadataKey, metadataValue]) => {
        payload.append(
          `product[metadata][${metadataKey}]`,
          JSON.stringify(metadataValue)
        );
      });
    } else {
      payload.append(`product[${key}]`, value ?? '');
    }
  });

  productMediaFiles.value.forEach(file => {
    payload.append('product[media_files][]', file);
  });

  return payload;
};

const addStructuredItem = items => {
  items.push({ question: '', answer: '' });
};

const removeStructuredItem = (items, index) => {
  if (items.length === 1) {
    Object.assign(items[0], { question: '', answer: '' });
    return;
  }

  items.splice(index, 1);
};

const addMediaLink = () => {
  mediaLinks.value.push({ label: '', url: '' });
};

const removeMediaLink = index => {
  if (mediaLinks.value.length === 1) {
    Object.assign(mediaLinks.value[0], { label: '', url: '' });
    return;
  }

  mediaLinks.value.splice(index, 1);
};

const handleMediaFiles = event => {
  productMediaFiles.value = Array.from(event.target.files || []);
};

const runPlayground = async () => {
  if (!selectedAgentId.value) {
    useAlert('Salve ou selecione um agente antes de testar.');
    return;
  }

  isPlaygroundLoading.value = true;
  try {
    const { data } = await aiAgentsAPI.playground(selectedAgentId.value, {
      message: playgroundInput.value,
    });
    playgroundResponse.value = data.message;
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel testar o agente.');
  } finally {
    isPlaygroundLoading.value = false;
  }
};

onMounted(loadData);
</script>

<template>
  <main class="crm-ai-page flex-1 overflow-auto bg-n-background">
    <header class="crm-ai-header border-b border-n-weak px-8 py-6">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2 text-sm text-n-slate-11">
            <span class="i-lucide-bot size-4" />
            <span>CRM / Agentes de IA</span>
          </div>
          <h1 class="mt-2 text-2xl font-semibold tracking-normal text-n-slate-12">
            Central de agentes
          </h1>
        </div>

        <div class="flex rounded-lg border border-n-weak bg-n-alpha-2 p-1">
          <button
            type="button"
            class="flex h-10 items-center gap-2 rounded-xl px-4 text-sm font-medium transition-colors"
            :class="
              activeResource === 'agents'
                ? 'bg-n-solid-2 text-n-slate-12'
                : 'text-n-slate-11 hover:text-n-slate-12'
            "
            @click="activeResource = 'agents'"
          >
            <span class="i-lucide-bot size-4" />
            Agentes
          </button>
          <button
            type="button"
            class="flex h-10 items-center gap-2 rounded-xl px-4 text-sm font-medium transition-colors"
            :class="
              activeResource === 'products'
                ? 'bg-n-solid-2 text-n-slate-12'
                : 'text-n-slate-11 hover:text-n-slate-12'
            "
            @click="activeResource = 'products'"
          >
            <span class="i-lucide-package size-4" />
            Produtos
          </button>
        </div>
      </div>
    </header>

    <section
      v-if="activeResource === 'agents'"
      class="crm-ai-shell grid min-h-[calc(100vh-104px)] grid-cols-[300px_minmax(0,1fr)_360px]"
    >
      <aside class="crm-resource-list border-r border-n-weak bg-n-solid-1/40 p-4">
        <div class="mb-4 flex items-center justify-between">
          <p class="text-sm font-medium text-n-slate-12">Agentes</p>
          <button
            type="button"
            class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
            title="Novo agente"
            @click="resetAgentForm"
          >
            <span class="i-lucide-plus size-4" />
          </button>
        </div>

        <div v-if="isLoading" class="rounded-lg border border-n-weak p-4 text-sm text-n-slate-11">
          Carregando...
        </div>

        <div v-else class="space-y-2">
          <button
            v-for="agent in agents"
            :key="agent.id"
            type="button"
            class="crm-resource-card w-full rounded-lg border p-4 text-left transition-colors"
            :class="
              selectedAgentId === agent.id
                ? 'border-n-blue-8 bg-n-blue-3/40'
                : 'border-transparent hover:border-n-weak hover:bg-n-alpha-2'
            "
            @click="selectAgent(agent)"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-n-slate-12">
                  {{ agent.name }}
                </p>
                <p class="mt-1 truncate text-xs text-n-slate-11">
                  {{ agent.role || 'Sem funcao definida' }}
                </p>
              </div>
              <span
                class="shrink-0 rounded-full px-2 py-0.5 text-xs"
                :class="
                  agent.active
                    ? 'bg-n-teal-4 text-n-teal-11'
                    : 'bg-n-alpha-2 text-n-slate-11'
                "
              >
                {{ agent.active ? 'Ativo' : 'Pausado' }}
              </span>
            </div>
            <div class="mt-3 flex items-center gap-3 text-xs text-n-slate-10">
              <span class="flex items-center gap-1">
                <span class="i-lucide-package size-3.5" />
                {{ (agent.product_ids || []).length }}
              </span>
              <span class="flex items-center gap-1">
                <span class="i-lucide-inbox size-3.5" />
                {{ (agent.inbox_ids || []).length }}
              </span>
            </div>
          </button>
        </div>
      </aside>

      <form class="crm-editor-panel overflow-auto px-8 py-6" @submit.prevent="saveAgent">
        <div class="mb-6 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ selectedAgent ? 'Configurar agente' : 'Novo agente' }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ activeSectionMeta.description }}
            </p>
          </div>

          <div class="flex items-center gap-2">
            <button
              v-if="selectedAgent"
              type="button"
              class="flex h-10 items-center gap-2 rounded-xl px-3 text-sm text-n-ruby-10 hover:bg-n-ruby-3"
              @click="deleteAgent(selectedAgent)"
            >
              <span class="i-lucide-trash-2 size-4" />
              Excluir
            </button>
            <button
              type="submit"
              class="flex h-10 items-center gap-2 rounded-xl bg-n-brand px-4 text-sm font-semibold text-white hover:brightness-110"
            >
              <span class="i-lucide-save size-4" />
              Salvar
            </button>
          </div>
        </div>

        <nav class="crm-section-tabs mb-6 grid grid-cols-5 gap-2">
          <button
            v-for="section in agentSections"
            :key="section.key"
            type="button"
            class="rounded-lg border p-3 text-left transition-colors"
            :class="
              activeAgentSection === section.key
                ? 'border-n-blue-8 bg-n-blue-3/40 text-n-slate-12'
                : 'border-n-weak bg-n-solid-1 text-n-slate-11 hover:bg-n-alpha-2'
            "
            @click="activeAgentSection = section.key"
          >
            <span :class="[section.icon, 'mb-3 block size-4']" />
            <span class="block text-sm font-medium">{{ section.label }}</span>
          </button>
        </nav>

        <section
          v-if="activeAgentSection === 'profile'"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-6"
        >
          <div class="grid gap-4 md:grid-cols-2">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Nome</span>
              <input
                v-model="agentForm.name"
                required
                class="h-10 w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                placeholder="Agente comercial"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Identidade</span>
              <input
                v-model="agentForm.gender"
                class="h-10 w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                placeholder="Neutro, feminino, masculino..."
              />
            </label>
          </div>

          <div class="mt-5">
            <p class="mb-2 text-sm font-medium text-n-slate-12">Papel principal</p>
            <div class="grid gap-2 sm:grid-cols-3 lg:grid-cols-5">
              <button
                v-for="role in roleOptions"
                :key="role"
                type="button"
                class="rounded-lg border px-3 py-2 text-left text-sm transition-colors"
                :class="
                  agentForm.role === role
                    ? 'border-n-blue-8 bg-n-blue-3/40 text-n-slate-12'
                    : 'border-n-weak text-n-slate-11 hover:bg-n-alpha-2'
                "
                @click="setAgentField('role', role)"
              >
                {{ role }}
              </button>
            </div>
          </div>
        </section>

        <section
          v-if="activeAgentSection === 'knowledge'"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-6"
        >
          <div class="mb-4 flex items-center justify-between gap-3">
            <div>
              <h3 class="text-base font-semibold text-n-slate-12">Conhecimento comercial</h3>
              <p class="mt-1 text-sm text-n-slate-11">
                O agente consulta apenas os produtos vinculados aqui.
              </p>
            </div>
            <button
              type="button"
              class="flex h-10 items-center gap-2 rounded-xl border border-n-weak px-3 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="activeResource = 'products'"
            >
              <span class="i-lucide-package-plus size-4" />
              Produtos
            </button>
          </div>

          <label class="block">
            <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Contexto da empresa</span>
            <textarea
              v-model="agentForm.company_context"
              rows="5"
              class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
              placeholder="Proposta de valor, diferenciais, politicas comerciais..."
            />
          </label>

          <div class="mt-5 grid gap-3 md:grid-cols-2">
            <button
              v-for="product in products"
              :key="product.id"
              type="button"
              class="rounded-lg border p-3 text-left transition-colors"
              :class="
                agentForm.product_ids.includes(product.id)
                  ? 'border-n-blue-8 bg-n-blue-3/40'
                  : 'border-n-weak hover:bg-n-alpha-2'
              "
              @click="toggleArrayValue(agentForm.product_ids, product.id)"
            >
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <p class="truncate text-sm font-medium text-n-slate-12">
                    {{ product.name }}
                  </p>
                  <p class="mt-1 truncate text-xs text-n-slate-11">
                    {{ product.category || product.sku || 'Sem categoria' }}
                  </p>
                </div>
                <span
                  class="i-lucide-check size-4 text-n-blue-10"
                  :class="{ invisible: !agentForm.product_ids.includes(product.id) }"
                />
              </div>
            </button>
          </div>
        </section>

        <section
          v-if="activeAgentSection === 'behavior'"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-6"
        >
          <div class="grid gap-5">
            <div>
              <p class="mb-2 text-sm font-medium text-n-slate-12">Tom de voz</p>
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="tone in toneOptions"
                  :key="tone"
                  type="button"
                  class="rounded-full border px-3 py-1.5 text-sm transition-colors"
                  :class="
                    agentForm.communication_tone === tone
                      ? 'border-n-blue-8 bg-n-blue-3/40 text-n-slate-12'
                      : 'border-n-weak text-n-slate-11 hover:bg-n-alpha-2'
                  "
                  @click="setAgentField('communication_tone', tone)"
                >
                  {{ tone }}
                </button>
              </div>
            </div>

            <div>
              <p class="mb-2 text-sm font-medium text-n-slate-12">Tecnica de venda</p>
              <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                <button
                  v-for="technique in salesTechniqueOptions"
                  :key="technique"
                  type="button"
                  class="rounded-lg border p-3 text-left text-sm transition-colors"
                  :class="
                    agentForm.sales_technique === technique
                      ? 'border-n-blue-8 bg-n-blue-3/40 text-n-slate-12'
                      : 'border-n-weak text-n-slate-11 hover:bg-n-alpha-2'
                  "
                  @click="setAgentField('sales_technique', technique)"
                >
                  <span class="i-lucide-target mb-2 block size-4" />
                  {{ technique }}
                </button>
              </div>
            </div>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Objetivo</span>
              <textarea
                v-model="agentForm.objective"
                rows="4"
                class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                placeholder="Qual resultado o agente deve buscar em uma conversa?"
              />
            </label>

            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Personalidade</span>
              <textarea
                v-model="agentForm.personality"
                rows="4"
                class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                placeholder="Como ele deve se comportar quando atende?"
              />
            </label>
          </div>
        </section>

        <section
          v-if="activeAgentSection === 'channels'"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-6"
        >
          <div class="mb-4">
            <h3 class="text-base font-semibold text-n-slate-12">Caixas atendidas</h3>
            <p class="mt-1 text-sm text-n-slate-11">
              O webhook dispara apenas para mensagens recebidas nessas caixas.
            </p>
          </div>

          <div class="grid gap-3 md:grid-cols-2">
            <button
              v-for="inbox in inboxes"
              :key="inbox.id"
              type="button"
              class="rounded-lg border p-3 text-left transition-colors"
              :class="
                agentForm.inbox_ids.includes(inbox.id)
                  ? 'border-n-blue-8 bg-n-blue-3/40'
                  : 'border-n-weak hover:bg-n-alpha-2'
              "
              @click="toggleArrayValue(agentForm.inbox_ids, inbox.id)"
            >
              <div class="flex items-center justify-between gap-3">
                <span class="truncate text-sm font-medium text-n-slate-12">
                  {{ inbox.name }}
                </span>
                <span
                  class="i-lucide-check size-4 text-n-blue-10"
                  :class="{ invisible: !agentForm.inbox_ids.includes(inbox.id) }"
                />
              </div>
              <p class="mt-1 truncate text-xs text-n-slate-11">
                {{ inbox.channel_type || inbox.channel?.type || 'Canal conectado' }}
              </p>
            </button>
          </div>
        </section>

        <section
          v-if="activeAgentSection === 'automation'"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-6"
        >
          <div class="grid gap-5">
            <label class="block">
              <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Webhook do n8n</span>
              <input
                v-model="agentForm.n8n_webhook_url"
                type="url"
                class="h-10 w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                placeholder="https://n8n..."
              />
            </label>

            <div class="grid gap-3 sm:grid-cols-2">
              <button
                type="button"
                class="rounded-lg border p-4 text-left transition-colors"
                :class="
                  agentForm.active
                    ? 'border-n-blue-8 bg-n-blue-3/40'
                    : 'border-n-weak hover:bg-n-alpha-2'
                "
                @click="agentForm.active = !agentForm.active"
              >
                <span class="i-lucide-power mb-3 block size-4" />
                <span class="block text-sm font-semibold text-n-slate-12">Agente ativo</span>
                <span class="mt-1 block text-sm text-n-slate-11">
                  Recebe eventos das caixas vinculadas.
                </span>
              </button>

              <button
                type="button"
                class="rounded-lg border p-4 text-left transition-colors"
                :class="
                  agentForm.auto_reply_enabled
                    ? 'border-n-blue-8 bg-n-blue-3/40'
                    : 'border-n-weak hover:bg-n-alpha-2'
                "
                @click="agentForm.auto_reply_enabled = !agentForm.auto_reply_enabled"
              >
                <span class="i-lucide-send mb-3 block size-4" />
                <span class="block text-sm font-semibold text-n-slate-12">Resposta automatica</span>
                <span class="mt-1 block text-sm text-n-slate-11">
                  Alterna entre sugestao e envio automatico.
                </span>
              </button>
            </div>
          </div>
        </section>
      </form>

      <aside class="crm-playground-panel border-l border-n-weak bg-n-solid-1/40 p-4">
        <div class="crm-playground-card rounded-lg border border-n-weak bg-n-solid-1">
          <div class="border-b border-n-weak p-4">
            <div class="flex items-center justify-between">
              <p class="text-sm font-semibold text-n-slate-12">Playground</p>
              <span class="rounded-full bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11">
                Preview
              </span>
            </div>
          </div>

          <div class="space-y-4 p-4">
            <label class="block">
              <span class="mb-1.5 block text-xs font-medium text-n-slate-11">
                Mensagem do cliente
              </span>
              <textarea
                v-model="playgroundInput"
                rows="3"
                class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
              />
            </label>

            <button
              type="button"
              class="flex h-10 w-full items-center justify-center gap-2 rounded-xl bg-n-brand px-3 text-sm font-semibold text-white transition-opacity hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isPlaygroundLoading"
              @click="runPlayground"
            >
              <span
                class="size-4"
                :class="
                  isPlaygroundLoading
                    ? 'i-lucide-loader-circle animate-spin'
                    : 'i-lucide-sparkles'
                "
              />
              {{ isPlaygroundLoading ? 'Testando...' : 'Testar agente' }}
            </button>

            <div class="rounded-lg border border-n-blue-8 bg-n-blue-3/30 p-3">
              <div class="mb-2 flex items-center gap-2 text-xs text-n-blue-11">
                <span class="i-lucide-bot size-3.5" />
                {{ agentForm.name || 'Agente' }}
              </div>
              <p class="text-sm leading-5 text-n-slate-12">
                {{ currentPreviewMessage }}
              </p>
            </div>

            <div class="grid gap-2">
              <div class="flex items-center justify-between rounded-lg border border-n-weak p-3">
                <span class="text-sm text-n-slate-11">Produtos</span>
                <span class="text-sm font-semibold text-n-slate-12">{{ linkedProducts.length }}</span>
              </div>
              <div class="flex items-center justify-between rounded-lg border border-n-weak p-3">
                <span class="text-sm text-n-slate-11">Caixas</span>
                <span class="text-sm font-semibold text-n-slate-12">{{ linkedInboxes.length }}</span>
              </div>
              <div class="flex items-center justify-between rounded-lg border border-n-weak p-3">
                <span class="text-sm text-n-slate-11">Modo</span>
                <span class="text-sm font-semibold text-n-slate-12">
                  {{ agentForm.auto_reply_enabled ? 'Automatico' : 'Sugestao' }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </section>

    <section
      v-else
      class="crm-products-shell grid min-h-[calc(100vh-104px)] grid-cols-[360px_minmax(0,1fr)]"
    >
      <aside class="crm-resource-list border-r border-n-weak bg-n-solid-1/40 p-4">
        <div class="mb-4 flex items-center justify-between">
          <p class="text-sm font-medium text-n-slate-12">Catalogo</p>
          <button
            type="button"
            class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
            title="Novo produto"
            @click="resetProductForm"
          >
            <span class="i-lucide-plus size-4" />
          </button>
        </div>

        <div class="space-y-2">
          <button
            v-for="product in products"
            :key="product.id"
            type="button"
            class="w-full rounded-lg border p-3 text-left transition-colors"
            :class="
              selectedProductId === product.id
                ? 'border-n-blue-8 bg-n-blue-3/40'
                : 'border-transparent hover:border-n-weak hover:bg-n-alpha-2'
            "
            @click="selectProduct(product)"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-n-slate-12">
                  {{ product.name }}
                </p>
                <p class="mt-1 truncate text-xs text-n-slate-10">
                  {{ product.category || product.sku || 'Sem categoria' }}
                </p>
              </div>
              <span
                class="rounded-full px-2 py-0.5 text-xs"
                :class="
                  product.active
                    ? 'bg-n-teal-4 text-n-teal-11'
                    : 'bg-n-alpha-2 text-n-slate-11'
                "
              >
                {{ product.active ? 'Ativo' : 'Pausado' }}
              </span>
            </div>
            <p class="mt-4 text-xs font-medium text-n-slate-11">{{ formatPrice(product) }}</p>
          </button>
        </div>
      </aside>

      <form class="crm-editor-panel overflow-auto px-8 py-6" @submit.prevent="saveProduct">
        <div class="mb-6 flex items-start justify-between gap-4">
          <div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ selectedProduct ? 'Editar produto' : 'Novo produto' }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-11">
              Produtos bem descritos melhoram as respostas das tools.
            </p>
          </div>

          <div class="flex items-center gap-2">
            <button
              v-if="selectedProduct"
              type="button"
              class="flex h-10 items-center gap-2 rounded-xl px-3 text-sm text-n-ruby-10 hover:bg-n-ruby-3"
              @click="deleteProduct(selectedProduct)"
            >
              <span class="i-lucide-trash-2 size-4" />
              Excluir
            </button>
            <button
              type="submit"
              class="flex h-10 items-center gap-2 rounded-xl bg-n-brand px-4 text-sm font-semibold text-white hover:brightness-110"
            >
              <span class="i-lucide-save size-4" />
              Salvar
            </button>
          </div>
        </div>

        <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_320px]">
          <section class="space-y-6">
            <div class="crm-form-card rounded-lg border border-n-weak bg-n-solid-1 p-6">
              <h3 class="mb-5 text-base font-semibold tracking-tight text-n-slate-12">Identificacao</h3>
              <div class="grid grid-cols-12 gap-4">
                <label class="col-span-12 block md:col-span-8">
                  <span class="crm-field-label">Nome</span>
                  <input
                    v-model="productForm.name"
                    required
                    class="crm-field-control"
                    placeholder="Caixa de Bis"
                  />
                </label>
                <label class="col-span-12 block md:col-span-4">
                  <span class="crm-field-label">SKU</span>
                  <input
                    v-model="productForm.sku"
                    class="crm-field-control"
                    placeholder="BIS-001"
                  />
                </label>
                <label class="col-span-12 block md:col-span-6">
                  <span class="crm-field-label">Categoria</span>
                  <input
                    v-model="productForm.category"
                    class="crm-field-control"
                    placeholder="Doce"
                  />
                </label>
                <div class="col-span-12 grid grid-cols-[minmax(0,1fr)_112px] gap-3 md:col-span-6">
                  <label class="block">
                    <span class="crm-field-label">Preco</span>
                    <div class="crm-price-field">
                      <span>{{ productForm.currency || 'BRL' }}</span>
                      <input
                        v-model="productForm.price"
                        type="number"
                        step="0.01"
                        placeholder="0,00"
                      />
                    </div>
                  </label>
                  <label class="block">
                    <span class="crm-field-label">Moeda</span>
                    <input
                      v-model="productForm.currency"
                      class="crm-field-control"
                    />
                  </label>
                </div>
              </div>
            </div>

            <div class="crm-form-card rounded-lg border border-n-weak bg-n-solid-1 p-6">
              <h3 class="mb-5 text-base font-semibold tracking-tight text-n-slate-12">Estoque</h3>
              <div class="grid grid-cols-12 gap-4">
                <label class="col-span-12 block md:col-span-4">
                  <span class="crm-field-label">Disponibilidade</span>
                  <select v-model="productForm.availability_status" class="crm-field-control">
                    <option
                      v-for="option in availabilityOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </label>
                <label class="col-span-12 flex items-end md:col-span-4">
                  <button
                    type="button"
                    class="crm-stock-toggle"
                    :class="{ 'is-on': productForm.track_inventory }"
                    @click="productForm.track_inventory = !productForm.track_inventory"
                  >
                    <span class="i-lucide-clipboard-list size-4" />
                    {{ productForm.track_inventory ? 'Controlado' : 'Sem controle' }}
                  </button>
                </label>
                <label class="col-span-12 block md:col-span-4">
                  <span class="crm-field-label">Alerta baixo</span>
                  <input
                    v-model="productForm.low_stock_threshold"
                    type="number"
                    min="0"
                    step="0.01"
                    class="crm-field-control"
                  />
                </label>
                <label class="col-span-12 block md:col-span-4">
                  <span class="crm-field-label">Quantidade</span>
                  <input
                    v-model="productForm.stock_quantity"
                    type="number"
                    min="0"
                    step="0.01"
                    class="crm-field-control"
                  />
                </label>
                <label class="col-span-12 block md:col-span-4">
                  <span class="crm-field-label">Reservado</span>
                  <input
                    v-model="productForm.reserved_quantity"
                    type="number"
                    min="0"
                    step="0.01"
                    class="crm-field-control"
                  />
                </label>
                <div class="col-span-12 md:col-span-4">
                  <span class="crm-field-label">Disponivel</span>
                  <div class="crm-stock-summary">
                    {{ productForm.track_inventory ? Math.max(Number(productForm.stock_quantity || 0) - Number(productForm.reserved_quantity || 0), 0) : 'Livre' }}
                  </div>
                </div>
              </div>
            </div>

            <div class="crm-form-card rounded-lg border border-n-weak bg-n-solid-1 p-6">
              <h3 class="mb-5 text-base font-semibold tracking-tight text-n-slate-12">Conteudo usado pela IA</h3>
              <div class="grid gap-4">
                <label class="block">
                  <span class="mb-1.5 block text-sm font-medium text-n-slate-12">Descricao</span>
                  <textarea
                    v-model="productForm.description"
                    rows="4"
                    class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8 focus:bg-n-solid-1"
                  />
                </label>
                <div class="space-y-3">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-n-slate-12">FAQs do produto</p>
                    <button
                      type="button"
                      class="flex h-8 items-center gap-2 rounded-md px-2 text-sm text-n-blue-11 hover:bg-n-blue-3"
                      @click="addStructuredItem(faqItems)"
                    >
                      <span class="i-lucide-plus size-4" />
                      FAQ
                    </button>
                  </div>

                  <div
                    v-for="(item, index) in faqItems"
                    :key="`faq-${index}`"
                    class="rounded-lg border border-n-weak bg-n-alpha-2 p-3"
                  >
                    <div class="mb-3 flex items-center justify-between">
                      <span class="text-xs font-medium text-n-slate-11">
                        Pergunta {{ index + 1 }}
                      </span>
                      <button
                        type="button"
                        class="flex size-7 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-10"
                        title="Remover FAQ"
                        @click="removeStructuredItem(faqItems, index)"
                      >
                        <span class="i-lucide-x size-4" />
                      </button>
                    </div>
                    <div class="grid gap-3 md:grid-cols-2">
                      <input
                        v-model="item.question"
                        class="h-10 rounded-lg border border-n-weak bg-n-solid-1 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                        placeholder="Ex: Quantas unidades ainda tem?"
                      />
                      <textarea
                        v-model="item.answer"
                        rows="2"
                        class="rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                        placeholder="Ex: Temos 8 unidades disponiveis."
                      />
                    </div>
                  </div>
                </div>

                <div class="space-y-3">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-n-slate-12">Objecoes e respostas</p>
                    <button
                      type="button"
                      class="flex h-8 items-center gap-2 rounded-md px-2 text-sm text-n-blue-11 hover:bg-n-blue-3"
                      @click="addStructuredItem(objectionItems)"
                    >
                      <span class="i-lucide-plus size-4" />
                      Objecao
                    </button>
                  </div>

                  <div
                    v-for="(item, index) in objectionItems"
                    :key="`objection-${index}`"
                    class="rounded-lg border border-n-weak bg-n-alpha-2 p-3"
                  >
                    <div class="mb-3 flex items-center justify-between">
                      <span class="text-xs font-medium text-n-slate-11">
                        Objecao {{ index + 1 }}
                      </span>
                      <button
                        type="button"
                        class="flex size-7 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-10"
                        title="Remover objecao"
                        @click="removeStructuredItem(objectionItems, index)"
                      >
                        <span class="i-lucide-x size-4" />
                      </button>
                    </div>
                    <div class="grid gap-3 md:grid-cols-2">
                      <input
                        v-model="item.question"
                        class="h-10 rounded-lg border border-n-weak bg-n-solid-1 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                        placeholder="Ex: Esta caro"
                      />
                      <textarea
                        v-model="item.answer"
                        rows="2"
                        class="rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                        placeholder="Ex: Entendo. O valor reflete..."
                      />
                    </div>
                  </div>
                </div>

                <div class="space-y-3">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-n-slate-12">Midias de apoio</p>
                    <button
                      type="button"
                      class="flex h-8 items-center gap-2 rounded-md px-2 text-sm text-n-blue-11 hover:bg-n-blue-3"
                      @click="addMediaLink"
                    >
                      <span class="i-lucide-link size-4" />
                      Link
                    </button>
                  </div>

                  <div class="rounded-lg border border-n-weak bg-n-alpha-2 p-3">
                    <label class="block">
                      <span class="mb-1.5 block text-xs font-medium text-n-slate-11">
                        Observacoes para a IA
                      </span>
                      <textarea
                        v-model="productForm.media_notes"
                        rows="2"
                        class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                        placeholder="Ex: use a foto principal quando o cliente pedir referencia visual."
                      />
                    </label>
                  </div>

                  <div
                    v-for="(link, index) in mediaLinks"
                    :key="`media-link-${index}`"
                    class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-2 p-3 md:grid-cols-[1fr_minmax(0,2fr)_32px]"
                  >
                    <input
                      v-model="link.label"
                      class="h-10 rounded-lg border border-n-weak bg-n-solid-1 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                      placeholder="Nome do link"
                    />
                    <input
                      v-model="link.url"
                      type="url"
                      class="h-10 rounded-lg border border-n-weak bg-n-solid-1 px-3 text-sm text-n-slate-12 outline-none transition-colors focus:border-n-blue-8"
                      placeholder="https://..."
                    />
                    <button
                      type="button"
                      class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-ruby-10"
                      title="Remover link"
                      @click="removeMediaLink(index)"
                    >
                      <span class="i-lucide-x size-4" />
                    </button>
                  </div>

                  <label
                    class="flex cursor-pointer flex-col items-center justify-center rounded-lg border border-dashed border-n-weak bg-n-alpha-2 px-4 py-6 text-center transition-colors hover:border-n-blue-8 hover:bg-n-blue-3/30"
                  >
                    <span class="i-lucide-upload-cloud mb-2 size-5 text-n-blue-11" />
                    <span class="text-sm font-medium text-n-slate-12">
                      Enviar imagem, video ou audio
                    </span>
                    <span class="mt-1 text-xs text-n-slate-11">
                      Os arquivos ficam anexados ao produto no CRM.
                    </span>
                    <input
                      type="file"
                      multiple
                      accept="image/*,video/*,audio/*"
                      class="hidden"
                      @change="handleMediaFiles"
                    />
                  </label>

                  <div
                    v-if="productMediaFiles.length"
                    class="space-y-2 rounded-lg border border-n-weak bg-n-alpha-2 p-3"
                  >
                    <p class="text-xs font-medium text-n-slate-11">Novos arquivos</p>
                    <div
                      v-for="file in productMediaFiles"
                      :key="file.name"
                      class="flex items-center gap-2 text-sm text-n-slate-12"
                    >
                      <span class="i-lucide-paperclip size-4 text-n-slate-11" />
                      <span class="truncate">{{ file.name }}</span>
                    </div>
                  </div>

                  <div
                    v-if="selectedProduct?.media_files?.length"
                    class="space-y-2 rounded-lg border border-n-weak bg-n-alpha-2 p-3"
                  >
                    <p class="text-xs font-medium text-n-slate-11">Arquivos salvos</p>
                    <a
                      v-for="file in selectedProduct.media_files"
                      :key="file.id"
                      :href="file.url"
                      target="_blank"
                      rel="noreferrer"
                      class="flex items-center gap-2 text-sm text-n-blue-11 hover:underline"
                    >
                      <span class="i-lucide-paperclip size-4" />
                      <span class="truncate">{{ file.filename }}</span>
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <aside class="space-y-4">
            <div class="rounded-lg border border-n-weak bg-n-solid-1 p-4">
              <div class="flex items-center justify-between">
                <p class="text-sm font-semibold text-n-slate-12">Disponibilidade</p>
                <button
                  type="button"
                  class="rounded-full px-3 py-1 text-xs font-medium"
                  :class="
                    productForm.active
                      ? 'bg-n-teal-4 text-n-teal-11'
                      : 'bg-n-alpha-2 text-n-slate-11'
                  "
                  @click="productForm.active = !productForm.active"
                >
                  {{ productForm.active ? 'Ativo' : 'Pausado' }}
                </button>
              </div>
            </div>

            <div class="rounded-lg border border-n-weak bg-n-solid-1 p-4">
              <p class="text-sm font-semibold text-n-slate-12">Vinculos</p>
              <p class="mt-1 text-sm text-n-slate-11">
                {{ selectedProductLinkedAgents.length }} agente(s) podem consultar este produto.
              </p>
              <div class="mt-3 flex flex-wrap gap-2">
                <span
                  v-for="agent in selectedProductLinkedAgents"
                  :key="agent.id"
                  class="rounded-full bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11"
                >
                  {{ agent.name }}
                </span>
              </div>
            </div>

            <div class="rounded-lg border border-n-weak bg-n-solid-1 p-4">
              <p class="text-sm font-semibold text-n-slate-12">Preview da busca</p>
              <div class="mt-3 rounded-lg bg-n-alpha-2 p-3 text-sm text-n-slate-11">
                <p class="font-medium text-n-slate-12">{{ productForm.name || 'Produto' }}</p>
                <p class="mt-1">{{ productForm.category || 'Categoria' }}</p>
                <p class="mt-2 line-clamp-4">
                  {{ productForm.description || 'Adicione uma descricao para melhorar a busca.' }}
                </p>
              </div>
            </div>
          </aside>
        </div>
      </form>
    </section>
  </main>
</template>

<style scoped>
.crm-ai-page {
  --crm-panel-radius: 12px;
  --crm-page-padding: clamp(1rem, 1.8vw, 1.75rem);
  --crm-card-shadow: none;
}

.crm-ai-header {
  padding: var(--crm-page-padding);
  background: rgb(var(--background-color));
}

.crm-ai-header h1 {
  color: rgb(var(--slate-12));
  font-weight: 650;
  letter-spacing: 0;
}

.crm-ai-header > div > div:first-child > div:first-child {
  display: inline-flex;
  border: 1px solid rgb(var(--border-weak));
  border-radius: 999px;
  background: rgba(var(--alpha-1));
  padding: 0.25rem 0.625rem;
  color: rgb(var(--slate-10));
  font-size: 0.6875rem;
  font-weight: 600;
  text-transform: uppercase;
}

.crm-ai-shell,
.crm-products-shell {
  background: rgb(var(--background-color));
}

.crm-resource-list,
.crm-playground-panel {
  min-width: 0;
}

.crm-resource-list {
  background: rgb(var(--background-color));
}

.crm-resource-card {
  border-color: rgb(var(--border-weak));
  background: rgb(var(--surface-2));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.025), var(--crm-card-shadow);
}

.crm-resource-card:hover {
  background: rgb(var(--solid-2));
}

.crm-editor-panel {
  min-width: 0;
  padding: var(--crm-page-padding);
}

.crm-editor-panel > * {
  width: 100%;
  max-width: 64rem;
  margin-inline: auto;
}

.crm-products-shell .crm-editor-panel > * {
  max-width: 72rem;
}

.crm-form-card {
  background: rgb(var(--surface-2));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.025), var(--crm-card-shadow);
}

.crm-editor-panel > section,
.crm-editor-panel :deep(.rounded-lg),
.crm-playground-card,
.crm-form-card,
.crm-resource-card {
  border-radius: var(--crm-panel-radius);
}

.crm-ai-page :deep(label > span:not([class*='i-lucide'])),
.crm-ai-page :deep(.crm-field-label) {
  color: rgb(var(--slate-10));
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0;
  text-transform: uppercase;
}

.crm-ai-page :deep(input),
.crm-ai-page :deep(textarea),
.crm-ai-page :deep(select),
.crm-field-control,
.crm-price-field {
  border-radius: 10px;
  background: rgba(var(--background-input-box));
}

.crm-ai-page :deep(input:focus),
.crm-ai-page :deep(textarea:focus),
.crm-ai-page :deep(select:focus) {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--solid-2));
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.14);
}

.crm-ai-page :deep(button.bg-n-brand),
.crm-ai-page :deep(button.bg-n-blue-9) {
  min-height: 2.5rem;
  border-radius: 0.75rem;
  background: #ff5b25;
  box-shadow: none;
}

.crm-ai-page :deep(button.border-n-blue-8),
.crm-ai-page :deep(.bg-n-blue-3\/40) {
  border-color: rgb(var(--border-blue-strong));
}

.crm-field-label {
  display: block;
  margin-bottom: 0.375rem;
  color: rgb(var(--slate-10));
  font-size: 0.6875rem;
  font-weight: 600;
  line-height: 1rem;
  text-transform: uppercase;
}

.crm-field-control,
.crm-price-field {
  height: 2.5rem;
  width: 100%;
  border: 1px solid rgb(var(--border-weak));
  border-radius: 10px;
  background: rgba(var(--background-input-box));
  color: rgb(var(--slate-12));
  font-size: 0.875rem;
  outline: none;
  transition:
    border-color 160ms ease,
    background-color 160ms ease;
}

.crm-field-control {
  padding: 0 0.875rem;
}

.crm-field-control:focus,
.crm-price-field:focus-within {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--solid-2));
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.14);
}

.crm-price-field {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: center;
  overflow: hidden;
}

.crm-price-field span {
  display: flex;
  height: 100%;
  align-items: center;
  border-right: 1px solid rgb(var(--border-weak));
  background: rgb(var(--solid-3));
  padding: 0 0.75rem;
  color: rgb(var(--slate-10));
  font-size: 0.75rem;
  font-weight: 700;
}

.crm-price-field input {
  min-width: 0;
  border: 0;
  background: transparent;
  padding: 0 0.875rem;
  color: rgb(var(--slate-12));
  outline: none;
}

.crm-stock-toggle,
.crm-stock-summary {
  display: flex;
  height: 2.5rem;
  width: 100%;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border: 1px solid rgb(var(--border-weak));
  border-radius: 10px;
  background: rgba(var(--background-input-box));
  color: rgb(var(--slate-11));
  font-size: 0.875rem;
  font-weight: 700;
}

.crm-stock-toggle.is-on {
  border-color: rgb(var(--teal-7));
  background: rgb(var(--teal-3));
  color: rgb(var(--teal-11));
}

.crm-stock-summary {
  background: rgb(var(--surface-2));
  color: rgb(var(--slate-12));
}

.crm-section-tabs {
  grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr));
}

.crm-section-tabs button {
  min-height: 6.25rem;
  background: rgb(var(--surface-2));
  box-shadow: var(--crm-card-shadow);
}

.crm-playground-panel {
  background: rgb(var(--background-color));
}

.crm-playground-card {
  position: sticky;
  top: 1rem;
  background: rgb(var(--surface-2));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.025), var(--crm-card-shadow);
}

.crm-ai-page :deep(table) {
  border-collapse: collapse;
}

.crm-ai-page :deep(th),
.crm-ai-page :deep(td) {
  border-bottom: 1px solid rgb(var(--border-weak));
  padding: 1rem;
}

@media (max-width: 1500px) {
  .crm-ai-shell {
    grid-template-columns: minmax(13rem, 16rem) minmax(0, 1fr) minmax(18rem, 22rem);
  }

  .crm-products-shell {
    grid-template-columns: minmax(15rem, 20rem) minmax(0, 1fr);
  }
}

@media (max-width: 1180px) {
  .crm-ai-shell {
    grid-template-columns: minmax(13rem, 17rem) minmax(0, 1fr);
  }

  .crm-playground-panel {
    grid-column: 1 / -1;
    border-left: 0;
    border-top: 1px solid rgb(var(--border-weak));
  }

  .crm-playground-card {
    position: static;
  }

  .crm-products-shell {
    grid-template-columns: minmax(13rem, 17rem) minmax(0, 1fr);
  }
}

@media (max-width: 900px) {
  .crm-ai-shell,
  .crm-products-shell {
    display: flex;
    flex-direction: column;
    min-height: auto;
  }

  .crm-resource-list {
    border-right: 0;
    border-bottom: 1px solid rgb(var(--border-weak));
    overflow-x: auto;
    padding: 1rem;
  }

  .crm-resource-list > div:last-child {
    display: flex;
    gap: 0.75rem;
    min-width: max-content;
  }

  .crm-resource-list > div:last-child > button {
    width: min(16rem, 76vw);
    flex: 0 0 auto;
  }

  .crm-editor-panel {
    overflow: visible;
    padding: 1rem;
  }

  .crm-section-tabs {
    display: flex;
    gap: 0.75rem;
    margin-inline: -1rem;
    overflow-x: auto;
    padding-inline: 1rem;
    scroll-snap-type: x mandatory;
  }

  .crm-section-tabs button {
    flex: 0 0 9.5rem;
    min-height: 5.75rem;
    scroll-snap-align: start;
  }
}

@media (max-width: 640px) {
  .crm-ai-header {
    padding: 1rem;
  }

  .crm-ai-header > div {
    align-items: stretch;
  }

  .crm-ai-header > div > div:last-child {
    width: 100%;
  }

  .crm-ai-header > div > div:last-child button {
    flex: 1 1 0;
    justify-content: center;
  }

  .crm-playground-panel {
    padding: 1rem;
  }
}
</style>
