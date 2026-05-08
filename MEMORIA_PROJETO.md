# Memoria do Projeto UnicoCRM

Este arquivo registra o contexto tecnico e as decisoes principais do projeto para reduzir risco de regressao nas proximas etapas.

## Identidade do projeto

- Produto: UnicoCRM, baseado em Chatwoot Enterprise customizado.
- Repositorio atual: `https://github.com/delvechio-tech/unicoCRM.git`.
- Imagem Docker atual: `delvechiotech/unicocrm:latest`.
- Imagem anterior: `delvechiotech/chatwoot-quepasa:latest`.
- O objetivo e transformar o Chatwoot em um CRM completo, mantendo o inbox/mensageria como base operacional.

## Quepasa nativo

Ja foi criado um conector nativo WhatsApp API/Quepasa no Chatwoot.

Pontos importantes:

- A criacao de caixa de entrada WhatsApp tem a opcao `WhatsApp API`.
- A configuracao da caixa tem aba `WhatsApp API`.
- O bot Quepasa e criado automaticamente.
- O QR Code deve desaparecer quando o numero estiver conectado.
- As configuracoes Quepasa refletem toggles no Chatwoot e devem ser aplicadas automaticamente.
- Ao excluir uma caixa de entrada Quepasa, o bot correspondente tambem deve ser removido no Quepasa.
- Webhooks do Quepasa alimentam conversas, contatos, grupos, midias, avatar, respostas citadas e mensagens enviadas/recebidas.

Cuidados:

- Nao quebrar o fluxo de webhook Quepasa.
- Nao reintroduzir captions genericas como `Audio`, `Foto`, `Video` quando a mensagem tiver apenas anexo.
- Arquivos `.vcf` vindos como eventos internos/contatos nao devem virar conversa indevida.
- Variaveis aceitas pelo cliente Quepasa:
  - `QUEPASA_API_URL` ou `QUEPASA_BASE_URL`;
  - `QUEPASA_MASTER_KEY`;
  - opcionalmente `QUEPASA_USER`/`QUEPASA_USERNAME` e `QUEPASA_PASSWORD`.

## Agentes de IA

Primeira fatia implementada:

- Usa a feature flag existente `crm` para evitar estourar o limite do bitset `feature_flags`.
- Super Admin / All Features exibe `CRM / Agentes de IA`.
- Quando `crm` esta ativo, o menu lateral mostra `Agentes de IA` no lugar do Captain.
- Captain fica como fallback caso a feature seja desligada.
- Produtos sao entidades do CRM, nao do agente.
- O agente consulta produtos vinculados.
- n8n sera o executor inicial da automacao.
- O banco do Chatwoot/UnicoCRM e a fonte de verdade desde o inicio.

Tabelas criadas:

- `crm_ai_agents`
- `crm_products`
- `crm_ai_agent_products`
- `crm_ai_agent_inboxes`
- `crm_ai_agent_execution_logs`

APIs criadas:

- `/api/v1/accounts/:account_id/crm/ai_agents`
- `/api/v1/accounts/:account_id/crm/products`

Tela criada:

- Rota frontend: `/app/accounts/:accountId/crm/ai-agents`
- Arquivo principal: `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`

Proxima etapa natural:

- Ligar eventos de mensagem/conversa ao executor n8n usando a configuracao salva em `crm_ai_agents`.
- Persistir logs de execucao em `crm_ai_agent_execution_logs`.
- Definir quando o agente responde automaticamente ou apenas sugere resposta.

## Stack e deploy

Exemplo generico de stack:

- `examples/portainer-stack.unicocrm.yml`

Stack de producao atual deve usar:

- `delvechiotech/unicocrm:latest` em `chatwoot_app`.
- `delvechiotech/unicocrm:latest` em `chatwoot_sidekiq`.

Depois de trocar a imagem, executar repull/update da stack para aplicar migrations e compilar o frontend novo.
Nao montar volume externo em `/app/public`, pois isso pode servir assets antigos e esconder telas novas como WhatsApp API/Quepasa e Agentes de IA.

## Cuidados de desenvolvimento

- Nao commitar segredos reais em arquivos versionados.
- Nao sobrescrever alteracoes locais do usuario.
- `.gitignore` tem uma alteracao local relacionada ao GitNexus que ficou fora do commit inicial do UnicoCRM.
- Builds Docker recentes passaram com sucesso, apesar de avisos antigos do Dockerfile/Sass.
- Se novas migrations forem adicionadas, garantir que `rails db:chatwoot_prepare` rode na inicializacao da stack.
