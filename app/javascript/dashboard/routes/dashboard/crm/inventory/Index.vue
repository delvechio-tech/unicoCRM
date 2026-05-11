<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useAlert } from 'dashboard/composables';

import productsAPI from 'dashboard/api/crm/products';

const products = ref([]);
const selectedProductId = ref(null);
const isLoading = ref(false);
const productMediaFiles = ref([]);
const searchQuery = ref('');
const mediaLinks = ref([{ label: '', url: '' }]);

const availabilityOptions = [
  { value: 'in_stock', label: 'Disponivel' },
  { value: 'out_of_stock', label: 'Sem estoque' },
  { value: 'pre_order', label: 'Pre-venda' },
  { value: 'discontinued', label: 'Descontinuado' },
];

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
  media_notes: '',
  metadata: {},
});

const selectedProduct = computed(() =>
  products.value.find(product => product.id === selectedProductId.value)
);

const filteredProducts = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return products.value;

  return products.value.filter(product =>
    [product.name, product.sku, product.category]
      .filter(Boolean)
      .some(value => value.toLowerCase().includes(query))
  );
});

const inventoryMetrics = computed(() => {
  const tracked = products.value.filter(product => product.track_inventory);
  const lowStock = products.value.filter(product => product.low_stock);
  const unavailable = products.value.filter(product => !product.sale_available);

  return {
    total: products.value.length,
    tracked: tracked.length,
    lowStock: lowStock.length,
    unavailable: unavailable.length,
  };
});

const resetProductForm = () => {
  selectedProductId.value = null;
  productMediaFiles.value = [];
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
    media_notes: '',
    metadata: {},
  });
};

const loadProducts = async () => {
  isLoading.value = true;
  try {
    const { data } = await productsAPI.get();
    products.value = data;

    if (!selectedProductId.value && products.value.length) {
      editProduct(products.value[0]);
    }
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel carregar o estoque.');
  } finally {
    isLoading.value = false;
  }
};

const editProduct = product => {
  selectedProductId.value = product.id;
  productMediaFiles.value = [];
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
    media_notes: product.media_notes || '',
    metadata: product.metadata || {},
  });
};

const normalizeMediaLinks = links => {
  if (Array.isArray(links) && links.length) {
    return links.map(link => ({ label: link.label || '', url: link.url || '' }));
  }

  return [{ label: '', url: '' }];
};

const compactMediaLinks = () =>
  mediaLinks.value
    .map(link => ({ label: link.label.trim(), url: link.url.trim() }))
    .filter(link => link.label || link.url);

const buildProductPayload = () => {
  const payload = new FormData();
  const product = {
    ...productForm,
    metadata: {
      ...(productForm.metadata || {}),
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

const saveProduct = async () => {
  try {
    const payload = buildProductPayload();
    if (selectedProductId.value) {
      await productsAPI.updateWithFiles(selectedProductId.value, payload);
      useAlert('Item atualizado.');
    } else {
      await productsAPI.createWithFiles(payload);
      useAlert('Item criado.');
    }
    await loadProducts();
  } catch (error) {
    useAlert(error.message || 'Nao foi possivel salvar o item.');
  }
};

const deleteProduct = async () => {
  if (!selectedProduct.value) return;
  if (!window.confirm(`Excluir o item ${selectedProduct.value.name}?`)) return;

  await productsAPI.delete(selectedProduct.value.id);
  useAlert('Item excluido.');
  resetProductForm();
  await loadProducts();
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

const availableQuantity = product =>
  product.track_inventory ? product.available_quantity : null;

const availabilityLabel = product => {
  const option = availabilityOptions.find(
    item => item.value === product.availability_status
  );
  return option?.label || 'Disponivel';
};

const availabilityClass = product => {
  if (product.availability_status === 'discontinued') return 'is-muted';
  if (product.availability_status === 'out_of_stock') return 'is-danger';
  if (product.low_stock) return 'is-warning';
  if (product.availability_status === 'pre_order') return 'is-info';
  return 'is-success';
};

const formatPrice = product => {
  if (!product.price) return 'Sem preco';
  return `${product.currency || 'BRL'} ${product.price}`;
};

onMounted(loadProducts);
</script>

<template>
  <main class="crm-inventory-page flex h-full min-h-0 flex-1 flex-col bg-n-background">
    <header class="crm-inventory-header border-b border-n-weak">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <div class="flex items-center gap-2 text-sm text-n-slate-11">
            <span class="i-lucide-package-check size-4" />
            <span>CRM / Estoque</span>
          </div>
          <h1 class="mt-2 text-2xl font-semibold text-n-slate-12">
            Estoque comercial
          </h1>
        </div>

        <button
          type="button"
          class="crm-primary-button"
          @click="resetProductForm"
        >
          <span class="i-lucide-plus size-4" />
          Novo item
        </button>
      </div>

      <section class="crm-inventory-metrics mt-5 grid gap-3 md:grid-cols-4">
        <div class="crm-metric-card">
          <span class="i-lucide-boxes size-4 text-n-blue-11" />
          <p>Total</p>
          <strong>{{ inventoryMetrics.total }}</strong>
        </div>
        <div class="crm-metric-card">
          <span class="i-lucide-scan-barcode size-4 text-n-teal-11" />
          <p>Controlados</p>
          <strong>{{ inventoryMetrics.tracked }}</strong>
        </div>
        <div class="crm-metric-card">
          <span class="i-lucide-triangle-alert size-4 text-n-amber-11" />
          <p>Baixo estoque</p>
          <strong>{{ inventoryMetrics.lowStock }}</strong>
        </div>
        <div class="crm-metric-card">
          <span class="i-lucide-circle-x size-4 text-n-ruby-10" />
          <p>Indisponiveis</p>
          <strong>{{ inventoryMetrics.unavailable }}</strong>
        </div>
      </section>
    </header>

    <section class="crm-inventory-shell grid min-h-0 flex-1 grid-cols-[360px_minmax(0,1fr)]">
      <aside class="crm-inventory-list min-h-0 border-r border-n-weak bg-n-solid-1">
        <div class="border-b border-n-weak p-4">
          <label class="crm-search-field">
            <span class="i-lucide-search size-4" />
            <input
              v-model="searchQuery"
              placeholder="Buscar por nome, SKU ou categoria"
            />
          </label>
        </div>

        <div v-if="isLoading" class="p-4 text-sm text-n-slate-11">
          Carregando estoque...
        </div>

        <div v-else class="crm-item-list space-y-2 p-3">
          <button
            v-for="product in filteredProducts"
            :key="product.id"
            type="button"
            class="crm-inventory-item"
            :class="{ 'is-active': selectedProductId === product.id }"
            @click="editProduct(product)"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-n-slate-12">
                  {{ product.name }}
                </p>
                <p class="mt-1 truncate text-xs text-n-slate-10">
                  {{ product.sku || 'Sem SKU' }} - {{ product.category || 'Sem categoria' }}
                </p>
              </div>
              <span class="crm-status-pill" :class="availabilityClass(product)">
                {{ availabilityLabel(product) }}
              </span>
            </div>

            <div class="mt-3 flex items-center justify-between gap-3 text-xs text-n-slate-11">
              <span>{{ formatPrice(product) }}</span>
              <span v-if="product.track_inventory">
                Disp. {{ availableQuantity(product) }}
              </span>
              <span v-else>Sem controle</span>
            </div>
          </button>

          <div v-if="!filteredProducts.length" class="rounded-lg border border-n-weak p-4 text-sm text-n-slate-11">
            Nenhum item encontrado.
          </div>
        </div>
      </aside>

      <form class="crm-inventory-editor min-h-0 overflow-y-auto" @submit.prevent="saveProduct">
        <div class="mb-5 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ selectedProduct ? 'Editar item' : 'Novo item' }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-11">
              Cadastro comercial usado por atendimento, IA e oportunidades.
            </p>
          </div>

          <div class="flex flex-wrap gap-2">
            <button
              v-if="selectedProduct"
              type="button"
              class="crm-danger-button"
              @click="deleteProduct"
            >
              <span class="i-lucide-trash-2 size-4" />
              Excluir
            </button>
            <button type="submit" class="crm-primary-button">
              <span class="i-lucide-save size-4" />
              Salvar
            </button>
          </div>
        </div>

        <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_340px]">
          <section class="space-y-6">
            <div class="crm-form-card">
              <h3>Identificacao</h3>
              <div class="grid grid-cols-12 gap-4">
                <label class="col-span-12 md:col-span-8">
                  <span class="crm-field-label">Nome</span>
                  <input v-model="productForm.name" required class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-4">
                  <span class="crm-field-label">SKU</span>
                  <input v-model="productForm.sku" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-5">
                  <span class="crm-field-label">Categoria</span>
                  <input v-model="productForm.category" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-3">
                  <span class="crm-field-label">Preco</span>
                  <input v-model="productForm.price" type="number" step="0.01" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-2">
                  <span class="crm-field-label">Moeda</span>
                  <input v-model="productForm.currency" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-2">
                  <span class="crm-field-label">Status</span>
                  <button
                    type="button"
                    class="crm-toggle-button"
                    :class="{ 'is-on': productForm.active }"
                    @click="productForm.active = !productForm.active"
                  >
                    {{ productForm.active ? 'Ativo' : 'Pausado' }}
                  </button>
                </label>
              </div>
            </div>

            <div class="crm-form-card">
              <h3>Estoque</h3>
              <div class="grid grid-cols-12 gap-4">
                <label class="col-span-12 md:col-span-4">
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
                <label class="col-span-12 flex items-end md:col-span-3">
                  <button
                    type="button"
                    class="crm-toggle-button"
                    :class="{ 'is-on': productForm.track_inventory }"
                    @click="productForm.track_inventory = !productForm.track_inventory"
                  >
                    <span class="i-lucide-clipboard-list size-4" />
                    {{ productForm.track_inventory ? 'Controlado' : 'Sem controle' }}
                  </button>
                </label>
                <label class="col-span-12 md:col-span-5">
                  <span class="crm-field-label">Alerta de baixo estoque</span>
                  <input v-model="productForm.low_stock_threshold" type="number" min="0" step="0.01" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-4">
                  <span class="crm-field-label">Quantidade total</span>
                  <input v-model="productForm.stock_quantity" type="number" min="0" step="0.01" class="crm-field-control" />
                </label>
                <label class="col-span-12 md:col-span-4">
                  <span class="crm-field-label">Reservado</span>
                  <input v-model="productForm.reserved_quantity" type="number" min="0" step="0.01" class="crm-field-control" />
                </label>
                <div class="col-span-12 md:col-span-4">
                  <span class="crm-field-label">Disponivel para venda</span>
                  <div class="crm-available-box">
                    {{ productForm.track_inventory ? Math.max(Number(productForm.stock_quantity || 0) - Number(productForm.reserved_quantity || 0), 0) : 'Livre' }}
                  </div>
                </div>
              </div>
            </div>

            <div class="crm-form-card">
              <h3>Conteudo comercial</h3>
              <label>
                <span class="crm-field-label">Descricao</span>
                <textarea v-model="productForm.description" rows="5" class="crm-field-control is-textarea" />
              </label>
            </div>

            <div class="crm-form-card">
              <h3>Midias</h3>
              <label>
                <span class="crm-field-label">Notas para atendimento e IA</span>
                <textarea v-model="productForm.media_notes" rows="3" class="crm-field-control is-textarea" />
              </label>

              <div class="mt-4 space-y-3">
                <div
                  v-for="(link, index) in mediaLinks"
                  :key="`media-${index}`"
                  class="grid gap-3 md:grid-cols-[1fr_minmax(0,2fr)_36px]"
                >
                  <input v-model="link.label" class="crm-field-control" placeholder="Nome do link" />
                  <input v-model="link.url" type="url" class="crm-field-control" placeholder="https://..." />
                  <button type="button" class="crm-icon-button" title="Remover link" @click="removeMediaLink(index)">
                    <span class="i-lucide-x size-4" />
                  </button>
                </div>
                <button type="button" class="crm-secondary-button" @click="addMediaLink">
                  <span class="i-lucide-link size-4" />
                  Adicionar link
                </button>
              </div>

              <label class="crm-upload-box mt-4">
                <span class="i-lucide-upload-cloud size-5 text-n-blue-11" />
                <span>Enviar imagem, video ou audio</span>
                <input type="file" multiple accept="image/*,video/*,audio/*" class="hidden" @change="handleMediaFiles" />
              </label>

              <div v-if="productMediaFiles.length" class="mt-3 space-y-2 text-sm text-n-slate-11">
                <p v-for="file in productMediaFiles" :key="file.name" class="truncate">
                  {{ file.name }}
                </p>
              </div>
            </div>
          </section>

          <aside class="space-y-4">
            <div class="crm-side-card">
              <p class="text-sm font-semibold text-n-slate-12">Leitura comercial</p>
              <div class="mt-3 space-y-2 text-sm text-n-slate-11">
                <p>Produto: <strong class="text-n-slate-12">{{ productForm.name || 'Novo item' }}</strong></p>
                <p>SKU: {{ productForm.sku || 'Sem SKU' }}</p>
                <p>Preco: {{ productForm.currency || 'BRL' }} {{ productForm.price || '0.00' }}</p>
                <p>
                  Estoque:
                  {{ productForm.track_inventory ? `${Math.max(Number(productForm.stock_quantity || 0) - Number(productForm.reserved_quantity || 0), 0)} disponivel` : 'nao controlado' }}
                </p>
              </div>
            </div>

            <div class="crm-side-card">
              <p class="text-sm font-semibold text-n-slate-12">Uso no CRM</p>
              <p class="mt-2 text-sm text-n-slate-11">
                Este item alimenta agentes de IA e oportunidades do Kanban quando estiver vinculado aos respectivos fluxos.
              </p>
            </div>

            <div v-if="selectedProduct?.media_files?.length" class="crm-side-card">
              <p class="text-sm font-semibold text-n-slate-12">Arquivos salvos</p>
              <a
                v-for="file in selectedProduct.media_files"
                :key="file.id"
                :href="file.url"
                target="_blank"
                rel="noreferrer"
                class="mt-2 flex items-center gap-2 text-sm text-n-blue-11 hover:underline"
              >
                <span class="i-lucide-paperclip size-4" />
                <span class="truncate">{{ file.filename }}</span>
              </a>
            </div>
          </aside>
        </div>
      </form>
    </section>
  </main>
</template>

<style scoped>
.crm-inventory-page {
  --crm-panel-radius: 12px;
  --crm-page-padding: clamp(1rem, 1.6vw, 1.5rem);
  --crm-card-shadow: none;
}

.crm-inventory-header,
.crm-inventory-editor {
  padding: var(--crm-page-padding);
}

.crm-inventory-header {
  background: rgb(var(--background-color));
}

.crm-inventory-header h1 {
  color: rgb(var(--slate-12));
  font-weight: 650;
  letter-spacing: 0;
}

.crm-inventory-header > div > div:first-child > div:first-child {
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

.crm-inventory-editor > * {
  width: 100%;
  max-width: 72rem;
  margin-inline: auto;
}

.crm-metric-card,
.crm-form-card,
.crm-side-card,
.crm-inventory-item {
  border: 1px solid rgb(var(--border-weak));
  border-radius: var(--crm-panel-radius);
  background: rgb(var(--surface-2));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.025), var(--crm-card-shadow);
}

.crm-metric-card {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 0.25rem 0.625rem;
  min-height: 5.25rem;
  padding: 1.125rem;
}

.crm-metric-card p {
  color: rgb(var(--slate-10));
  font-size: 0.75rem;
}

.crm-metric-card strong {
  grid-column: 2;
  color: rgb(var(--slate-12));
  font-size: 1.25rem;
}

.crm-search-field {
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: center;
  gap: 0.5rem;
  border: 1px solid rgb(var(--border-weak));
  border-radius: var(--crm-panel-radius);
  background: rgba(var(--background-input-box));
  padding: 0 0.75rem;
}

.crm-search-field input {
  height: 2.5rem;
  min-width: 0;
  border: 0;
  background: transparent;
  color: rgb(var(--slate-12));
  font-size: 0.875rem;
  outline: none;
}

.crm-item-list {
  max-height: 100%;
  overflow-y: auto;
}

.crm-inventory-item {
  width: 100%;
  padding: 1rem;
  text-align: left;
  transition:
    border-color 160ms ease,
    background-color 160ms ease;
}

.crm-inventory-item:hover,
.crm-inventory-item.is-active {
  border-color: rgb(var(--border-blue-strong));
  background: rgba(255, 91, 37, 0.1);
}

.crm-status-pill {
  flex-shrink: 0;
  border-radius: 999px;
  padding: 0.1875rem 0.5rem;
  font-size: 0.6875rem;
  font-weight: 700;
}

.crm-status-pill.is-success {
  background: rgb(var(--teal-4));
  color: rgb(var(--teal-11));
}

.crm-status-pill.is-warning {
  background: rgb(var(--amber-4));
  color: rgb(var(--amber-11));
}

.crm-status-pill.is-danger {
  background: rgb(var(--ruby-4));
  color: rgb(var(--ruby-10));
}

.crm-status-pill.is-info {
  background: rgb(var(--blue-4));
  color: rgb(var(--blue-11));
}

.crm-status-pill.is-muted {
  background: rgb(var(--slate-4));
  color: rgb(var(--slate-11));
}

.crm-form-card,
.crm-side-card {
  padding: 1.5rem;
}

.crm-form-card h3 {
  margin-bottom: 1.5rem;
  color: rgb(var(--slate-12));
  font-size: 1rem;
  font-weight: 650;
  letter-spacing: 0;
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

.crm-field-control {
  height: 2.5rem;
  width: 100%;
  border: 1px solid rgb(var(--border-weak));
  border-radius: var(--crm-panel-radius);
  background: rgba(var(--background-input-box));
  color: rgb(var(--slate-12));
  padding: 0 0.875rem;
  font-size: 0.875rem;
  outline: none;
}

.crm-field-control.is-textarea {
  height: auto;
  min-height: 7rem;
  padding: 0.75rem 0.875rem;
  resize: vertical;
}

.crm-field-control:focus {
  border-color: rgb(var(--border-blue-strong));
  background: rgb(var(--solid-2));
  box-shadow: 0 0 0 3px rgba(255, 91, 37, 0.14);
}

.crm-available-box,
.crm-toggle-button,
.crm-primary-button,
.crm-secondary-button,
.crm-danger-button,
.crm-icon-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border-radius: var(--crm-panel-radius);
  font-size: 0.875rem;
  font-weight: 700;
}

.crm-available-box {
  height: 2.5rem;
  width: 100%;
  border: 1px solid rgb(var(--border-weak));
  background: rgb(var(--surface-1));
  color: rgb(var(--slate-12));
}

.crm-toggle-button,
.crm-secondary-button,
.crm-danger-button {
  height: 2.5rem;
  border: 1px solid rgb(var(--border-weak));
  background: rgb(var(--surface-1));
  color: rgb(var(--slate-11));
  padding: 0 0.875rem;
}

.crm-toggle-button {
  width: 100%;
}

.crm-toggle-button.is-on {
  border-color: rgb(var(--teal-7));
  background: rgb(var(--teal-3));
  color: rgb(var(--teal-11));
}

.crm-primary-button {
  height: 2.5rem;
  background: #ff5b25;
  color: white;
  padding: 0 1rem;
}

.crm-primary-button:hover {
  background: #ff6a3a;
}

.crm-secondary-button:hover,
.crm-danger-button:hover,
.crm-icon-button:hover {
  background: rgb(var(--solid-2));
}

.crm-danger-button {
  color: rgb(var(--ruby-10));
}

.crm-icon-button {
  height: 2.25rem;
  width: 2.25rem;
  border: 1px solid rgb(var(--border-weak));
  background: rgb(var(--surface-1));
  color: rgb(var(--slate-11));
}

.crm-upload-box {
  display: flex;
  cursor: pointer;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border: 1px dashed rgb(var(--border-weak));
  border-radius: var(--crm-panel-radius);
  background: rgb(var(--surface-1));
  padding: 1.25rem;
  text-align: center;
  color: rgb(var(--slate-12));
  font-size: 0.875rem;
  font-weight: 700;
}

@media (max-width: 1180px) {
  .crm-inventory-shell {
    grid-template-columns: minmax(15rem, 20rem) minmax(0, 1fr);
  }
}

@media (max-width: 900px) {
  .crm-inventory-shell {
    display: flex;
    flex-direction: column;
  }

  .crm-inventory-list {
    border-right: 0;
    border-bottom: 1px solid rgb(var(--border-weak));
  }

  .crm-item-list {
    display: flex;
    gap: 0.75rem;
    overflow-x: auto;
  }

  .crm-inventory-item {
    width: min(18rem, 78vw);
    flex: 0 0 auto;
  }
}

@media (max-width: 640px) {
  .crm-inventory-header,
  .crm-inventory-editor {
    padding: 1rem;
  }
}
</style>
