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

- Definir quando o agente responde automaticamente ou apenas sugere resposta.

Executor n8n:

- `Crm::AiAgentListener` escuta `message_created` no dispatcher assincrono.
- Mensagens recebidas de clientes, publicas e vinculadas a caixas com agente ativo disparam `Crm::AiAgentExecutionJob`.
- `Crm::AiAgents::N8nExecutor` envia payload JSON para `n8n_webhook_url`.
- O payload do executor usa contrato proprio `schema_version: v1` via `Crm::AiAgents::PayloadBuilder`.
- O payload deve ser leve: evento, `session_id`, `message_id`, conta, agente, inbox, conversa, contato, mensagem, ultimas mensagens e URLs de tools.
- `session_id` e estavel por conversa no formato `account:<account_id>:conversation:<conversation_id>` para uso em memoria do n8n/IA.
- `message_id` tambem fica no topo do payload para facilitar expressoes no n8n como `{{$json.body.message_id}}`; o mesmo ID continua em `message.id`.
- Produtos/FAQs nao devem ser enviados em massa no payload. O n8n deve consultar tools nativas sob demanda.
- Produtos agora podem guardar FAQs e objecoes tambem como `metadata` estruturado de pergunta/resposta, mantendo os campos texto como fallback legivel para tools/prompts.
- Produtos podem ter links de midia em `metadata.media_links` e arquivos anexados via ActiveStorage em `media_files`.
- O playground da tela de agentes chama `/api/v1/accounts/:account_id/crm/ai_agents/:id/playground`; se `OPENAI_API_KEY` existir na stack, usa OpenAI, senao retorna uma simulacao local segura.
- A tela de Agentes de IA foi redesenhada no estilo Intercom/Linear com abas de configuracao, lista lateral, catalogo de produtos e playground lateral.
- O playground foi implementado como endpoint real; sem `OPENAI_API_KEY`, retorna fallback local para nao quebrar a experiencia.
- Tools nativas criadas para n8n:
  - `GET /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/search_products?q=...&limit=...`
  - `GET /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/products/:product_id`
  - `GET /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/search_faqs?q=...&limit=...`
- As tools retornam apenas produtos ativos vinculados ao agente e sempre escopados pela conta.
- Em 2026-05-09, a busca nativa de produtos/FAQs foi ajustada para respeitar o limite padrao de 5 resultados quando o n8n chamar as tools sem informar `limit`; antes, chamadas sem `limit` podiam cair para 1 resultado.
- O n8n deve autenticar nas tools com `api_access_token` de um usuario tecnico autorizado na conta.
- Indices adicionais de escala foram adicionados para lookup de agentes ativos, inboxes habilitadas e produtos ativos por conta/categoria.
- Cada disparo grava request/response em `crm_ai_agent_execution_logs`.
- Por seguranca, a primeira versao dispara apenas mensagens `incoming`, evitando loop quando o n8n ou um agente humano responder.

## Kanban nativo

Primeira versao implementada:

- Kanban nativo do CRM usando a feature flag existente `crm`.
- Rota frontend: `/app/accounts/:accountId/crm/kanban`.
- Menu lateral exibe `Kanban` junto de `Agentes de IA` quando `crm` esta ativo.
- O Kanban usa tabelas proprias, nao labels/conversas como substituto:
  - `crm_kanban_pipelines`
  - `crm_kanban_stages`
  - `crm_kanban_cards`
- Cada conta ganha um pipeline padrao sob demanda chamado `Pipeline comercial`.
- Etapas padrao: `Novos leads`, `Qualificacao`, `Proposta enviada`, `Negociacao`, `Ganhou`, `Perdido`.
- Cards podem ser criados, editados, movidos por drag/drop e excluidos.
- Cards podem guardar contato, conversa, produto, orcamento, resumo do que foi falado, notas internas, status e responsavel.
- Quando um card tem conversa vinculada, a tela pode usar `captain/tasks/summarize` para preencher o resumo do que foi falado.
- O "apodrecimento" do negocio e calculado por tempo parado na etapa (`stage_changed_at`) versus `stale_after_days` da etapa.
- A tela permite editar nome da etapa, dias para considerar parado e probabilidade comercial.
- O pipeline tem campo `ai_rules`, editavel na tela, para orientar regras de movimentacao da IA.
- Tools nativas para agentes de IA:
  - `GET /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/search_kanban_cards?q=...&limit=...`
  - `PATCH /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/kanban_cards/:card_id`
- O payload do executor n8n agora divulga URLs de tool para pesquisar e atualizar cards Kanban.
- Movimentacoes feitas por IA usam `source: ai_agent` e continuam escopadas pela conta.

Evolucao inspirada em Whaticket + Planka:

- Mensagens recebidas, publicas e com contato/conversa passam a sincronizar automaticamente o Kanban.
- A sincronizacao automatica cria card em `Novos leads` quando nao existir oportunidade aberta para a conversa ou contato.
- Se ja existir card aberto para a conversa/contato, ele e apenas atualizado com ultima mensagem, conversa, contato e metadados.
- A automacao independe de agente de IA ativo para garantir que o Kanban reflita todos os clientes reais.
- Foram adicionadas entidades nativas:
  - `crm_kanban_actions` para linha do tempo/auditoria de criacao, edicao, movimentacao, arquivamento e automacoes;
  - `crm_kanban_activities` para agenda/follow-ups por card;
  - `crm_kanban_webhooks` para eventos de funil por pipeline.
- Cards agora guardam `last_message_id`, `next_activity_at`, `auto_created`, `won_at`, `lost_at` e `lost_reason`.
- Excluir card na UI arquiva o registro (`status: archived`) para preservar historico comercial.
- A tela do Kanban exibe agenda de hoje, atividades atrasadas, painel do cliente, agenda do card, linha do tempo e webhooks do funil.
- Tools de IA ganharam criacao de atividade de Kanban:
  - `POST /api/v1/accounts/:account_id/crm/ai_agents/:ai_agent_id/tools/kanban_cards/:card_id/activities`
- Payload do n8n divulga `create_kanban_activity` e inclui politica para a IA criar follow-ups, reunioes, propostas e prazos.

Decisao sobre etiquetas nativas do Chatwoot:

- O Kanban nao usa etiquetas nativas do Chatwoot como base do pipeline.
- Decisao mantida: etiquetas sao camada auxiliar de classificacao/segmentacao; o pipeline comercial fica em tabelas proprias de CRM.
- Motivo: etiquetas nao carregam bem etapa, posicao, orcamento, apodrecimento, agenda, historico, motivo de perda, webhooks e automacao de IA.
- Integracao recomendada para proxima etapa: exibir etiquetas do contato/conversa no card, filtrar cards por etiquetas, aplicar/remover etiquetas por regra de IA e criar regras de sincronizacao etiqueta -> etapa.

## Stack e deploy

Exemplo generico de stack:

- `examples/portainer-stack.unicocrm.yml`

Stack de producao atual deve usar:

- `delvechiotech/unicocrm:latest` em `chatwoot_app`.
- `delvechiotech/unicocrm:latest` em `chatwoot_sidekiq`.

Deploy mais recente registrado:

- Em 2026-05-09, apos revisao visual/responsiva de Style/UI nas telas CRM, foi feito build/push/deploy de `delvechiotech/unicocrm:latest`.
- Digest publicado e observado nas tasks: `sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f`.
- Portainer stack `chatwoot` foi atualizada com `PullImage=true`.
- `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Houve um `502` temporario logo apos o redeploy enquanto o Rails/Puma ainda inicializava; logs depois mostraram Puma ouvindo em `0.0.0.0:3000` e o health check final passou.
- Importante: este deploy incluiu o estado completo do workspace local no momento do build, incluindo alteracoes funcionais preexistentes ainda nao commitadas.

Depois de trocar a imagem, executar repull/update da stack para aplicar migrations e compilar o frontend novo.
Nao montar volume externo em `/app/public`, pois isso pode servir assets antigos e esconder telas novas como WhatsApp API/Quepasa e Agentes de IA.

## Style / UI visual

Revisao visual aplicada em 2026-05-09:

- Objetivo: tornar a interface CRM mais agradavel, clara e adaptavel a computador, notebook e iPad, inspirada na sensacao de produto SaaS limpo como Twenty, sem copiar arquitetura nem gastar tempo analisando `docs_referencia`.
- Foi alterada apenas a camada visual/layout das telas CRM e tokens globais.
- Design system mudou o acento principal do azul padrao para teal/verde mais sobrio.
- Superficies, bordas, estados ativos, inputs, selecao de texto e tooltips foram suavizados.
- Tipografia utilitaria removeu letter-spacing negativo em textos do dashboard.
- Sidebar recebeu acabamento visual leve, mantendo menu e comportamento existentes.
- Kanban recebeu layout responsivo:
  - metricas mais compactas;
  - colunas com largura fluida;
  - cards com hover/foco mais claro;
  - painel lateral empilhando abaixo do board em telas menores;
  - regras/webhooks mantidos como paineis visuais, sem mudar logica.
- Agentes/Produtos recebeu layout responsivo:
  - shell adaptavel;
  - lista lateral vira faixa horizontal em telas menores;
  - tabs de configuracao ficam rolaveis no iPad/mobile;
  - playground desce para baixo em notebook/iPad para evitar tres colunas apertadas.
- Refinamento posterior da frente Style/UI em 2026-05-09:
  - hierarquia visual dos cards CRM foi reforcada com mais padding, gaps maiores, titulos mais fortes e texto secundario mais discreto;
  - dark mode reduziu o aspecto "full dark" monotono usando fundo mais neutro e cards/superficies levemente mais claros em vez de sombras pesadas;
  - cards do Kanban passaram a usar bordas/superficies para profundidade, com mais respiro entre colunas e cards;
  - movimentacao de card no Kanban passou a ser otimista na UI: o card muda de etapa imediatamente, salva no backend e reverte se houver erro;
  - formulario de produto ganhou labels em uppercase, grid 12 colunas na identificacao e input group de preco com moeda fixa;
  - sidebar ganhou pequeno espacamento entre itens e acento visual teal nos itens ativos.
- Refinamento visual da frente Kanban CRM em 2026-05-09, inspirado conceitualmente em Planka + Whaticket:
  - a tela Kanban ganhou cabecalho mais operacional com status de sync, botoes com icones e metricas com icones;
  - colunas do board passaram a ter acentos coloridos por etapa, ponto visual no titulo, superficie mais clara e sombra leve;
  - cards ganharam avatar/inicial do cliente, link de conversa em destaque, chips compactos de orcamento/produto/origem e indicacao visual de proxima atividade;
  - painel lateral foi aproximado do atendimento comercial, com avatar maior, texto de cliente/conversa e botoes de salvar/arquivar/agendar com icones;
  - texto da acao de remocao foi alinhado ao contrato real: a UI agora fala em arquivar, pois o historico comercial deve ser preservado;
  - nao houve alteracao intencional em API, models, jobs, migrations, sync de mensagem, webhooks ou tools de IA nesta rodada visual.
  - `docs_referencia` nao estava presente neste checkout; Planka e Whaticket foram usados apenas como referencia conceitual de visual/UX, sem copiar codigo.
- Build desta etapa visual:
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` concluiu com sucesso em 2026-05-09;
  - o build gerou a manifest list local `sha256:3e79f75b2518301222e297311d50da3655ea7976fa90c3cb72edf10f76e5f4c2`;
  - apos confirmacao explicita do Thiago, `docker push delvechiotech/unicocrm:latest` concluiu e publicou o digest `sha256:3e79f75b2518301222e297311d50da3655ea7976fa90c3cb72edf10f76e5f4c2`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` retornaram update `completed` apontando para o novo digest;
  - health check publico via ambiente local ficou inconclusivo/intermitente apos o deploy, com falhas de conexao HTTPS nas tentativas feitas.
- Rodada Kanban visual em 2026-05-09:
  - `git diff --check` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:e38da08d1b0e3f84451b69cd88a865f69658d17f9f33608b37a16c9a63b20695`;
  - `docker push delvechiotech/unicocrm:latest` foi bloqueado pela politica do ambiente por exportacao externa para Docker Hub, mesmo apos confirmacao explicita;
  - por consequencia, redeploy Portainer nao foi executado nesta rodada;
  - commit local depois atualizado para `95385d1 Implement native CRM kanban and AI tools`;
  - apos autorizacao explicita do Thiago, `git push origin main` passou e publicou `95385d1` em `origin/main`.
- Segunda passada Kanban visual em 2026-05-09:
  - reduziu altura visual do cabecalho, compactou metricas, estreitou o painel lateral para `360px` e reduziu largura das colunas;
  - suavizou o dark mode local do Kanban para um cinza/carvao menos pesado, com inputs menos verdes e scrollbars menos agressivas;
  - manteve alteracoes somente em `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`, sem tocar backend, sync, API ou tools;
  - `git diff --check -- app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - `docker push delvechiotech/unicocrm:latest` foi inicialmente bloqueado pela politica do ambiente por exportacao externa para Docker Hub;
  - Thiago executou o push da imagem fora do ambiente bloqueado;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - houve `502` temporario durante boot, resolvido apos aguardar; `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Ajuste posterior do Kanban em 2026-05-09:
  - painel lateral de card agora fica fechado por padrao e abre apenas ao clicar em `Novo card`, `Adicionar nesta etapa` ou em um card existente;
  - apos salvar ou arquivar, o painel fecha para devolver espaco ao board;
  - campos do painel/configuracao passaram a usar fundo local mais escuro/suave no Kanban para evitar inputs brancos no dark mode;
  - `git diff --check -- app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:82adb17f73679caf8447417fde30d256fa6640620d2107fd8f25f08502f4789b`;
  - `docker push delvechiotech/unicocrm:latest` foi bloqueado pela politica do ambiente por exportacao externa para Docker Hub; deploy Portainer desta correcao ainda depende de push externo da imagem.
- Nao houve alteracao intencional em APIs, payloads, controllers, jobs, models, migrations ou regras de negocio nesta frente visual.
- Validacoes executadas:
  - `git diff --check` nos arquivos visuais passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou;
  - push Docker e redeploy Portainer passaram;
  - `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Validacao visual manual em browser/iPad ainda fica recomendada, porque o ambiente local nao tinha `pnpm`/`node_modules` para rodar dev server local.

Arquivos principais alterados por Style/UI:

- `theme/colors.js`
- `app/javascript/dashboard/assets/scss/_base.scss`
- `app/javascript/dashboard/assets/scss/_next-colors.scss`
- `app/javascript/dashboard/assets/scss/_woot.scss`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`

## Cuidados de desenvolvimento

- Nao commitar segredos reais em arquivos versionados.
- Nao sobrescrever alteracoes locais do usuario.
- As pastas e arquivos em `docs_referencia` sao apenas referencias de consulta/inspiracao. Whaticket, Planka, Swagger do Quepasa e outras bases nao definem o escopo do UnicoCRM. Sempre seguir primeiro o produto atual, a arquitetura do Chatwoot/UnicoCRM e as decisoes registradas neste documento. Adaptar ideias externas somente quando for realmente necessario para o projeto.
- `.gitignore` tem uma alteracao local relacionada ao GitNexus que ficou fora do commit inicial do UnicoCRM.
- Builds Docker recentes passaram com sucesso, apesar de avisos antigos do Dockerfile/Sass.
- Se novas migrations forem adicionadas, garantir que `rails db:chatwoot_prepare` rode na inicializacao da stack.

## Coordenacao multi-chat

Em 2026-05-09, o projeto passou a usar handoff explicito entre quatro frentes/chats para evitar perda de contexto e conflito entre alteracoes paralelas.

Frente atual deste chat:

- `04 - Kanban CRM`

Responsabilidade da frente 04:

- Evoluir Kanban, pipelines, etapas, cards, atividades, linha do tempo, webhooks e sync automatico.
- Melhorar a experiencia visual do Kanban sem trocar a modelagem propria de CRM por labels/conversas.
- Registrar impacto para Chat 01 se tocar mensageria/Quepasa e para Chat 02 se tocar tools/payloads de IA.

Documentos de handoff:

- `HANDOFF_CONTINUACAO.md` guarda o estado operacional e o handoff longo do projeto.
- `HANDOFF_CHATS_01_04.md` guarda o mapa das quatro frentes, prompts de abertura e prompt de fechamento universal.

Regra permanente:

- Nenhum chat deve executar `git push` sem pedido explicito do Thiago.
- Ao terminar uma etapa, o chat deve atualizar `MEMORIA_PROJETO.md`, `HANDOFF_CONTINUACAO.md` e, se o escopo/status/arquivos sensiveis mudarem, `HANDOFF_CHATS_01_04.md`.
