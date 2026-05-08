<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useAlert } from 'dashboard/composables';

import aiAgentsAPI from 'dashboard/api/crm/aiAgents';
import productsAPI from 'dashboard/api/crm/products';
import inboxesAPI from 'dashboard/api/inboxes';

const agents = ref([]);
const products = ref([]);
const inboxes = ref([]);
const activeTab = ref('agents');
const isLoading = ref(false);
const selectedAgentId = ref(null);
const selectedProductId = ref(null);

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
  description: '',
  faq: '',
  objections: '',
  media_notes: '',
});

const selectedAgent = computed(() =>
  agents.value.find(agent => agent.id === selectedAgentId.value)
);

const selectedProduct = computed(() =>
  products.value.find(product => product.id === selectedProductId.value)
);

const resetAgentForm = () => {
  selectedAgentId.value = null;
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
  Object.assign(productForm, {
    name: '',
    sku: '',
    category: '',
    currency: 'BRL',
    price: '',
    active: true,
    description: '',
    faq: '',
    objections: '',
    media_notes: '',
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
  } catch (error) {
    useAlert(error.message || 'Não foi possível carregar os dados do CRM.');
  } finally {
    isLoading.value = false;
  }
};

const editAgent = agent => {
  selectedAgentId.value = agent.id;
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
  Object.assign(productForm, {
    name: product.name || '',
    sku: product.sku || '',
    category: product.category || '',
    currency: product.currency || 'BRL',
    price: product.price || '',
    active: product.active,
    description: product.description || '',
    faq: product.faq || '',
    objections: product.objections || '',
    media_notes: product.media_notes || '',
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
    resetAgentForm();
    await loadData();
  } catch (error) {
    useAlert(error.message || 'Não foi possível salvar o agente.');
  }
};

const saveProduct = async () => {
  try {
    const payload = { product: { ...productForm } };
    if (selectedProductId.value) {
      await productsAPI.update(selectedProductId.value, payload);
      useAlert('Produto atualizado.');
    } else {
      await productsAPI.create(payload);
      useAlert('Produto criado.');
    }
    resetProductForm();
    await loadData();
  } catch (error) {
    useAlert(error.message || 'Não foi possível salvar o produto.');
  }
};

const deleteAgent = async agent => {
  if (!window.confirm(`Excluir o agente ${agent.name}?`)) return;
  await aiAgentsAPI.delete(agent.id);
  useAlert('Agente excluído.');
  if (selectedAgentId.value === agent.id) resetAgentForm();
  await loadData();
};

const deleteProduct = async product => {
  if (!window.confirm(`Excluir o produto ${product.name}?`)) return;
  await productsAPI.delete(product.id);
  useAlert('Produto excluído.');
  if (selectedProductId.value === product.id) resetProductForm();
  await loadData();
};

onMounted(loadData);
</script>

<template>
  <main class="flex-1 overflow-auto bg-n-background px-8 py-6">
    <header class="mb-6 flex flex-wrap items-start justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">Agentes de IA</h1>
        <p class="mt-2 max-w-3xl text-sm text-n-slate-11">
          Configure a personalidade, o contexto comercial e a automação do n8n.
          Os produtos ficam no CRM e podem ser consultados por qualquer agente.
        </p>
      </div>
      <div class="flex rounded-lg border border-n-weak bg-n-alpha-2 p-1">
        <button
          class="rounded-md px-4 py-2 text-sm font-medium"
          :class="activeTab === 'agents' ? 'bg-n-solid-2 text-n-blue-text' : 'text-n-slate-11'"
          @click="activeTab = 'agents'"
        >
          Agentes
        </button>
        <button
          class="rounded-md px-4 py-2 text-sm font-medium"
          :class="activeTab === 'products' ? 'bg-n-solid-2 text-n-blue-text' : 'text-n-slate-11'"
          @click="activeTab = 'products'"
        >
          Produtos
        </button>
      </div>
    </header>

    <section v-if="activeTab === 'agents'" class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
      <form class="rounded-lg border border-n-weak bg-n-solid-1 p-5" @submit.prevent="saveAgent">
        <div class="mb-5 flex items-center justify-between">
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ selectedAgent ? 'Editar agente' : 'Novo agente' }}
          </h2>
          <button type="button" class="text-sm text-n-blue-text" @click="resetAgentForm">
            Limpar
          </button>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Nome</span>
            <input v-model="agentForm.name" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Gênero</span>
            <input v-model="agentForm.gender" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Função</span>
            <input v-model="agentForm.role" placeholder="Vendedor, SDR, suporte..." class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Técnica de venda</span>
            <input v-model="agentForm.sales_technique" placeholder="SPIN Selling, AIDA..." class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Webhook do n8n</span>
            <input v-model="agentForm.n8n_webhook_url" type="url" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Tom de comunicação</span>
            <textarea v-model="agentForm.communication_tone" rows="3" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Dados da empresa</span>
            <textarea v-model="agentForm.company_context" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Objetivo</span>
            <textarea v-model="agentForm.objective" rows="3" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Personalidade</span>
            <textarea v-model="agentForm.personality" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
        </div>

        <div class="mt-5 grid gap-4 md:grid-cols-2">
          <fieldset class="rounded-lg border border-n-weak p-4">
            <legend class="px-1 text-sm font-semibold text-n-slate-12">Produtos consultados</legend>
            <p v-if="!products.length" class="text-sm text-n-slate-11">Cadastre produtos na aba Produtos.</p>
            <label v-for="product in products" :key="product.id" class="mt-3 flex items-center gap-2 text-sm text-n-slate-12">
              <input v-model="agentForm.product_ids" type="checkbox" :value="product.id" />
              <span>{{ product.name }}</span>
            </label>
          </fieldset>
          <fieldset class="rounded-lg border border-n-weak p-4">
            <legend class="px-1 text-sm font-semibold text-n-slate-12">Caixas atendidas</legend>
            <label v-for="inbox in inboxes" :key="inbox.id" class="mt-3 flex items-center gap-2 text-sm text-n-slate-12">
              <input v-model="agentForm.inbox_ids" type="checkbox" :value="inbox.id" />
              <span>{{ inbox.name }}</span>
            </label>
          </fieldset>
        </div>

        <div class="mt-5 flex flex-wrap items-center gap-5">
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <input v-model="agentForm.active" type="checkbox" />
            Agente ativo
          </label>
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <input v-model="agentForm.auto_reply_enabled" type="checkbox" />
            Resposta automática
          </label>
          <button class="rounded-lg bg-n-blue-9 px-4 py-2 text-sm font-semibold text-white" type="submit">
            Salvar agente
          </button>
        </div>
      </form>

      <aside class="space-y-3">
        <div v-if="isLoading" class="rounded-lg border border-n-weak p-4 text-sm text-n-slate-11">
          Carregando agentes...
        </div>
        <article
          v-for="agent in agents"
          :key="agent.id"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-4"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <h3 class="font-semibold text-n-slate-12">{{ agent.name }}</h3>
              <p class="mt-1 text-sm text-n-slate-11">{{ agent.role || 'Sem função definida' }}</p>
            </div>
            <span class="rounded-full px-2 py-1 text-xs" :class="agent.active ? 'bg-n-teal-4 text-n-teal-11' : 'bg-n-alpha-2 text-n-slate-11'">
              {{ agent.active ? 'Ativo' : 'Pausado' }}
            </span>
          </div>
          <p class="mt-3 line-clamp-3 text-sm text-n-slate-11">{{ agent.objective || agent.personality || 'Sem objetivo cadastrado.' }}</p>
          <div class="mt-4 flex gap-2">
            <button class="rounded-md border border-n-weak px-3 py-1.5 text-sm text-n-slate-12" type="button" @click="editAgent(agent)">
              Editar
            </button>
            <button class="rounded-md border border-n-ruby-7 px-3 py-1.5 text-sm text-n-ruby-10" type="button" @click="deleteAgent(agent)">
              Excluir
            </button>
          </div>
        </article>
      </aside>
    </section>

    <section v-else class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_420px]">
      <form class="rounded-lg border border-n-weak bg-n-solid-1 p-5" @submit.prevent="saveProduct">
        <div class="mb-5 flex items-center justify-between">
          <h2 class="text-lg font-semibold text-n-slate-12">
            {{ selectedProduct ? 'Editar produto' : 'Novo produto' }}
          </h2>
          <button type="button" class="text-sm text-n-blue-text" @click="resetProductForm">
            Limpar
          </button>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Nome</span>
            <input v-model="productForm.name" required class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">SKU</span>
            <input v-model="productForm.sku" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Categoria</span>
            <input v-model="productForm.category" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <div class="grid grid-cols-[1fr_120px] gap-3">
            <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Preço</span>
              <input v-model="productForm.price" type="number" step="0.01" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
            <label class="block">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Moeda</span>
              <input v-model="productForm.currency" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
            </label>
          </div>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Descrição</span>
            <textarea v-model="productForm.description" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">FAQs do produto</span>
            <textarea v-model="productForm.faq" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Objeções e respostas</span>
            <textarea v-model="productForm.objections" rows="4" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
          <label class="block md:col-span-2">
            <span class="mb-1 block text-sm font-medium text-n-slate-12">Mídias de apoio</span>
            <textarea v-model="productForm.media_notes" rows="3" class="w-full rounded-md border border-n-weak bg-n-alpha-2 px-3 py-2 text-n-slate-12" />
          </label>
        </div>

        <div class="mt-5 flex flex-wrap items-center gap-5">
          <label class="flex items-center gap-2 text-sm text-n-slate-12">
            <input v-model="productForm.active" type="checkbox" />
            Produto ativo
          </label>
          <button class="rounded-lg bg-n-blue-9 px-4 py-2 text-sm font-semibold text-white" type="submit">
            Salvar produto
          </button>
        </div>
      </form>

      <aside class="space-y-3">
        <article
          v-for="product in products"
          :key="product.id"
          class="rounded-lg border border-n-weak bg-n-solid-1 p-4"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <h3 class="font-semibold text-n-slate-12">{{ product.name }}</h3>
              <p class="mt-1 text-sm text-n-slate-11">{{ product.category || product.sku || 'Sem categoria' }}</p>
            </div>
            <span class="rounded-full px-2 py-1 text-xs" :class="product.active ? 'bg-n-teal-4 text-n-teal-11' : 'bg-n-alpha-2 text-n-slate-11'">
              {{ product.active ? 'Ativo' : 'Pausado' }}
            </span>
          </div>
          <p class="mt-3 line-clamp-3 text-sm text-n-slate-11">{{ product.description || 'Sem descrição cadastrada.' }}</p>
          <div class="mt-4 flex gap-2">
            <button class="rounded-md border border-n-weak px-3 py-1.5 text-sm text-n-slate-12" type="button" @click="editProduct(product)">
              Editar
            </button>
            <button class="rounded-md border border-n-ruby-7 px-3 py-1.5 text-sm text-n-ruby-10" type="button" @click="deleteProduct(product)">
              Excluir
            </button>
          </div>
        </article>
      </aside>
    </section>
  </main>
</template>
