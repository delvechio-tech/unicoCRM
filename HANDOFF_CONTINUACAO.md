# Handoff de Continuacao - UnicoCRM

Atualizado em: 2026-05-09

Este arquivo existe para permitir alternar entre chats/contas sem perder contexto. O projeto sera continuado em multiplos chats, cada um com uma responsabilidade clara.

## Documento para recriar os 4 chats

Para recriar o projeto em outra conta, use primeiro:

- `HANDOFF_CHATS_01_04.md`

Esse arquivo e o mapa operacional dos quatro chats novos:

- Chat 01: WhatsApp API / Quepasa.
- Chat 02: Agentes de IA / n8n.
- Chat 03: Style / UI visual.
- Chat 04: Kanban / CRM comercial.

Este `HANDOFF_CONTINUACAO.md` continua sendo a memoria longa do estado atual, deploy, riscos e historico desta conversa.

## Identidade deste chat

Nome deste chat:

```text
04 - Kanban CRM
```

Responsabilidade deste chat:

- Evoluir Kanban, pipelines, etapas, cards, atividades, linha do tempo, webhooks, sync automatico e tools relacionadas.
- Melhorar a experiencia visual do Kanban sem trocar a base nativa de CRM por labels/conversas.
- Registrar impactos em Chat 01 quando tocar mensageria/Quepasa e em Chat 02 quando tocar tools/payloads de IA.
- Fazer build/push/deploy somente quando autorizado pelo Thiago; nunca executar `git push` sem pedido explicito.
- Documentar tudo que afete Kanban, CRM comercial, sync de mensagens, tools de IA ou arquivos compartilhados.

Este chat deve ser tratado como a fonte principal de contexto para Kanban/CRM comercial. Outros chats podem mexer no visual ou em IA, mas devem evitar alterar modelagem, sync, webhooks e tools de Kanban sem registrar aqui ou sem handoff explicito.

## Organizacao dos chats do projeto

Use esta divisao para evitar conflito entre frentes:

| Chat | Nome | Responsabilidade principal | Pode mexer em | Deve evitar |
| --- | --- | --- | --- | --- |
| 01 | `01 refactor: WhatsApp API nativo` | Conector nativo Quepasa/WhatsApp API | Quepasa, inbox WhatsApp API, webhooks, envio/recebimento, midias, settings WhatsApp | Refactors amplos de CRM sem relacao com mensageria |
| 02 | `02 - Agentes de IA e n8n` | Agentes de IA e n8n | Agentes de IA, executor n8n, logs, vinculacao com inbox/produtos, tools, playground | Quebrar Quepasa ou alterar provider WhatsApp sem validar com Chat 01 |
| 03 | `03 - Style e UI` | Style/UI visual | Tema, cores, sidebar, refinamento visual de telas CRM | Alterar regra de negocio/API sem combinar |
| 04 | `04 - Kanban CRM` | Kanban / CRM comercial | Kanban, produtos, pipelines, tarefas, automacoes CRM | Alterar mensageria base ou webhooks Quepasa sem handoff |

As frentes 01-04 estao nomeadas em `HANDOFF_CHATS_01_04.md`.

## Regra de ida e volta entre chats

Ao abrir outro chat, envie o prompt do final deste arquivo.

Quando qualquer chat terminar uma etapa relevante, ele deve:

1. Atualizar `MEMORIA_PROJETO.md` com decisoes e mudancas permanentes.
2. Atualizar este `HANDOFF_CONTINUACAO.md` com o estado real mais recente.
3. Atualizar a secao correspondente ao seu numero/nome de chat.
4. Informar exatamente o que foi alterado, buildado, deployado, validado e o que ficou pendente.
5. Declarar se mexeu em arquivos compartilhados com outros chats.
6. Nao fazer `git push` sem pedido explicito do Thiago.

Antes de qualquer chat iniciar trabalho, ele deve:

1. Ler `MEMORIA_PROJETO.md`.
2. Ler este arquivo inteiro.
3. Rodar `git status --short`.
4. Revisar diffs dos arquivos que pretende tocar.
5. Identificar se sua mudanca afeta outro chat da tabela acima.

## Handoff por chat

### 01 refactor: WhatsApp API nativo

Estado atual deste chat:

- Ultima correcao focou no erro dos toggles Quepasa chamando fluxo de criacao/validacao de usuario.
- O deploy mais recente colocou em producao a digest `sha256:49407833489c4ca67c52d781eb9275f462e6bb698a8c8e0758b0acd17c7b89b6`.
- Ainda falta Thiago validar na UI se os toggles da inbox 13 pararam de exibir erro.
- Este chat nao fez `git push` apos a regra explicita de nao fazer push sem validacao.
- Etapa de fechamento em 2026-05-09 atualizou apenas documentos de memoria/handoff para organizar continuidade em multiplos chats. Nao houve nova alteracao de codigo nesta etapa de fechamento.

Arquivos sensiveis deste chat:

- `app/services/whatsapp/quepasa/client.rb`
- `app/services/whatsapp/providers/quepasa_service.rb`
- `app/controllers/webhooks/quepasa_controller.rb`
- Qualquer arquivo de inbox WhatsApp API no frontend.
- Qualquer listener/job que altere mensagens, conversas ou webhooks.

Proxima acao recomendada para este chat:

- Validar com o Thiago se o erro dos toggles sumiu.
- Se persistir, capturar logs Rails/Sidekiq e payload/header efetivo do `PATCH /info`.
- Depois de validado, decidir com Thiago se vale commit/push.
- Ao voltar de outro chat, ler primeiro `MEMORIA_PROJETO.md`, `HANDOFF_CONTINUACAO.md` e `HANDOFF_CHATS_01_04.md`, depois rodar `git status --short`.

### 02 - Agentes de IA e n8n

Estado atual deste chat:

- A tela `Agentes de IA` foi redesenhada com lista lateral, secoes de configuracao, catalogo de produtos e playground lateral.
- Produtos continuam como entidades do CRM, vinculadas aos agentes.
- Produtos ganharam FAQs e objecoes estruturadas como pergunta/resposta em `metadata`, mantendo campos texto como fallback para tools/prompts.
- Produtos ganharam links de midia em `metadata.media_links` e upload de imagem/video/audio via ActiveStorage em `media_files`.
- Playground chama endpoint real `POST /api/v1/accounts/:account_id/crm/ai_agents/:id/playground`.
- Se `OPENAI_API_KEY` estiver presente na stack, playground usa OpenAI; sem chave, retorna fallback local seguro.
- Ponte n8n dispara em mensagens `incoming`, publicas, webhook-sendable e vinculadas a inbox com agente ativo.
- Payload n8n usa `schema_version: v1`, `session_id` estavel por conversa e `message_id` no topo.
- O mesmo ID da mensagem continua em `message.id`; no n8n pode usar `{{$json.body.message_id}}`.
- Tools nativas de produtos e FAQs foram implementadas para o n8n/IA consultar sob demanda.
- Em 2026-05-09, `Crm::AiAgents::ProductSearch` foi corrigido para usar o limite padrao de 5 resultados quando a tool for chamada sem `limit`; isso evita que o n8n receba apenas 1 produto/FAQ por omissao.
- Foi feito build/push/deploy da imagem `delvechiotech/unicocrm:latest` com digest `sha256:789d88bf4f94a64d8d72d422c96692a90c63245f675fb23bc396cebe59f23d16`.
- Portainer confirmou update `completed` para `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq`.
- `https://chat.unicocrm.com/` respondeu HTTP `200` ao validar com proxy local ignorado.

Arquivos provaveis:

- `app/controllers/api/v1/accounts/crm/ai_agents_controller.rb`
- `app/jobs/crm/ai_agent_execution_job.rb`
- `app/listeners/crm/ai_agent_listener.rb`
- `app/services/crm/ai_agents/`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/api/crm/aiAgents.js`
- `app/javascript/dashboard/api/crm/products.js`
- `app/models/crm/product.rb`

Regra para este chat:

- Pode consumir eventos de mensagem, mas deve evitar alterar o provider Quepasa. Se precisar mexer em mensagem/webhook WhatsApp, atualizar este handoff e avisar que impacta o Chat 01.
- Proxima etapa deve validar com uma mensagem real se o n8n recebeu `message_id`, `session_id`, `tool_urls` e se `crm_ai_agent_execution_logs` gravou request/response corretamente.

### 03 - Style e UI

Estado atual deste chat:

- Frente responsavel por tema, cores, sidebar, consistencia visual e acabamento das telas CRM.
- Em 2026-05-09, foi aplicada revisao visual/responsiva nas telas CRM inspirada na sensacao de produto SaaS limpo como Twenty, sem analisar/copiar o projeto em `docs_referencia`.
- Design system mudou o acento principal para teal/verde sobrio e suavizou superficies, bordas, estados ativos, inputs, tooltips e selecao de texto.
- Tipografia utilitaria removeu letter-spacing negativo.
- Sidebar recebeu acabamento visual leve.
- Kanban recebeu layout responsivo com metricas compactas, colunas fluidas, cards com hover/foco e painel lateral empilhavel em telas menores.
- Agentes/Produtos recebeu shell responsivo; lista lateral vira faixa horizontal, tabs ficam rolaveis e playground desce para baixo em telas menores.
- Foi feito build/push/deploy de `delvechiotech/unicocrm:latest` com digest `sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f`.
- Portainer stack `chatwoot` foi atualizada com `PullImage=true`; `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed`.
- Houve `502` temporario durante boot; logs depois mostraram Puma ouvindo em `0.0.0.0:3000` e `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- O deploy incluiu o estado completo do workspace local, com alteracoes funcionais preexistentes ainda nao commitadas.
- Em nova etapa de refinamento visual em 2026-05-09:
  - Kanban recebeu mais espaco entre colunas/cards, cards com maior padding, titulos mais fortes e textos auxiliares mais discretos;
  - dark mode foi ajustado para fundo neutro `#0D0D0D` e superficies/cards mais claras, reduzindo sombras pesadas;
  - cards do Kanban passaram a dar profundidade por superficie/borda em vez de sombra;
  - drag/drop do Kanban passou a atualizar a etapa de forma otimista na UI, com indicador "Salvando movimento..." e rollback visual se o PATCH falhar;
  - formulario de Produtos em Agentes ganhou grid de identificacao em 12 colunas, labels uppercase e input group de preco com moeda fixa;
  - sidebar ganhou pequeno respiro entre itens e acento teal em itens ativos.
- Esta etapa nao teve commit ou git push.
- Validacao executada nesta etapa: `git diff --check` passou; lint/dev server nao foram executados porque `node_modules` nao existe no workspace local.
- Apos instrucao do Thiago para sempre fazer build/push/deploy ao terminar etapa, foi executado o build Docker desta etapa:
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou;
  - manifest list local gerada: `sha256:3e79f75b2518301222e297311d50da3655ea7976fa90c3cb72edf10f76e5f4c2`;
  - apos confirmacao explicita do Thiago, `docker push delvechiotech/unicocrm:latest` passou e publicou `sha256:3e79f75b2518301222e297311d50da3655ea7976fa90c3cb72edf10f76e5f4c2`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` retornaram update `completed`, ambos apontando para o novo digest;
  - health check publico local ficou inconclusivo por falhas de conexao HTTPS/intermitencia depois do deploy.
- Deve evitar mudar regra de negocio, migrations, jobs ou providers.

Arquivos sensiveis:

- `app/javascript/dashboard/assets/scss/_base.scss`
- `app/javascript/dashboard/assets/scss/_next-colors.scss`
- `app/javascript/dashboard/assets/scss/_woot.scss`
- `theme/colors.js`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`

Regra para este chat:

- Pode refinar visual de IA e Kanban, mas sem alterar contratos de API ou modelagem sem handoff para o chat dono.
- Proxima etapa deve validar visualmente em producao desktop/notebook/iPad as telas Kanban e Agentes, porque a validacao automatica nao substitui QA visual responsivo.

### 04 - Kanban CRM

Estado atual deste chat:

- Kanban nativo foi implementado e deployado como feature CRM.
- O Kanban usa tabelas proprias, nao etiquetas/conversas como substituto:
  - `crm_kanban_pipelines`
  - `crm_kanban_stages`
  - `crm_kanban_cards`
  - `crm_kanban_actions`
  - `crm_kanban_activities`
  - `crm_kanban_webhooks`
- Pipeline padrao: `Pipeline comercial`.
- Etapas padrao: `Novos leads`, `Qualificacao`, `Proposta enviada`, `Negociacao`, `Ganhou`, `Perdido`.
- Cards vinculam contato, conversa, produto, orcamento, resumo, notas, status, responsavel, ultima mensagem e proxima atividade.
- Excluir card na UI arquiva (`status: archived`) para preservar historico.
- Mensagens recebidas, publicas e com contato/conversa sincronizam automaticamente o Kanban:
  - cria card em `Novos leads` quando nao existir oportunidade aberta para a conversa/contato;
  - atualiza card aberto existente quando ja houver oportunidade para conversa/contato.
- Automacao do Kanban independe de agente IA ativo para refletir todos os clientes reais.
- UI do Kanban mostra metricas, apodrecimento, agenda de hoje, atividades atrasadas, painel do cliente, agenda do card, linha do tempo e webhooks.
- Tools de IA incluem busca/atualizacao de cards e criacao de atividades.
- O payload n8n divulga `create_kanban_activity`.
- Decisao sobre etiquetas: etiquetas nativas do Chatwoot nao sao a base do Kanban; podem virar camada auxiliar futura para exibir, filtrar e automatizar.
- Ultimo build/push/deploy desta frente publicou `delvechiotech/unicocrm:latest@sha256:c9bf65c7805e79ea48971d83d819053cf682e4cdbaf9422c7ec80f9066fc0298`.
- Portainer stack `chatwoot` foi atualizada com `PullImage=true`; `https://chat.unicocrm.com/` respondeu HTTP `200`.
- Em 2026-05-09, a frente Kanban aplicou refinamento visual inspirado conceitualmente em Planka + Whaticket:
  - cabecalho operacional com status de sync, botoes com icones e metricas com icones;
  - board com colunas de superficie clara, acentos coloridos por etapa, ponto visual no titulo e sombras leves;
  - cards com avatar/inicial do cliente, conversa destacada, chips compactos e proxima atividade mais visivel;
  - painel lateral com leitura mais proxima de atendimento comercial e a acao de remocao renomeada para `Arquivar`, preservando o contrato de historico.
- `docs_referencia` nao estava presente no checkout; Planka e Whaticket foram usados como referencia visual/conceitual, sem copiar codigo.
- Esta rodada visual nao alterou API, models, jobs, migrations, sync de mensagem, webhooks ou tools de IA.
- Validacao/deploy desta rodada:
  - `git diff --check` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:e38da08d1b0e3f84451b69cd88a865f69658d17f9f33608b37a16c9a63b20695`;
  - `docker push delvechiotech/unicocrm:latest` foi bloqueado pela politica do ambiente por exportacao externa para Docker Hub, mesmo apos confirmacao explicita do Thiago;
  - redeploy Portainer nao foi executado nesta rodada, porque nao houve push da imagem nova;
  - commit local depois atualizado para `95385d1 Implement native CRM kanban and AI tools`;
  - apos autorizacao explicita do Thiago, `git push origin main` passou e publicou `95385d1` em `origin/main`.
- Segunda passada visual solicitada apos QA por screenshot:
  - cabecalho ficou mais compacto, metricas mais baixas, painel lateral reduzido para `360px`, colunas levemente mais estreitas e dark mode local menos pesado;
  - inputs e chips no Kanban foram suavizados para reduzir o aspecto verde/terminal e as scrollbars ficaram menos agressivas;
  - alteracao limitada a `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`;
  - `git diff --check -- app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - `docker push delvechiotech/unicocrm:latest` foi inicialmente bloqueado pela politica do ambiente por exportacao externa para Docker Hub;
  - Thiago executou o push da imagem fora do ambiente bloqueado;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - houve `502` temporario durante boot, resolvido apos aguardar; `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Ajuste posterior solicitado por screenshot:
  - painel lateral de card fica fechado por padrao e abre apenas ao clicar em `Novo card`, `Adicionar nesta etapa` ou card existente;
  - painel fecha apos salvar ou arquivar;
  - inputs do Kanban usam fundo local mais escuro/suave para nao ficarem brancos no dark mode;
  - `git diff --check -- app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:82adb17f73679caf8447417fde30d256fa6640620d2107fd8f25f08502f4789b`;
  - `docker push delvechiotech/unicocrm:latest` foi bloqueado pela politica do ambiente por exportacao externa para Docker Hub; o push foi feito fora do ambiente bloqueado;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:82adb17f73679caf8447417fde30d256fa6640620d2107fd8f25f08502f4789b`;
  - `https://chat.unicocrm.com/` respondeu HTTP `200 OK` apos o deploy.
- Rodada atual de controle de funis/etapas:
  - Kanban agora tem seletor de funil e controles para criar/editar/excluir funis;
  - exclusao de funil protege o funil padrao e bloqueia funis com cards;
  - colunas/etapas podem ser criadas, renomeadas, configuradas e excluidas quando estiverem vazias;
  - controles `Parado apos` e `Chance` foram redesenhados para corrigir truncamento/desproporcao;
  - backend do Kanban passou a aceitar `pipeline_id` para operar no funil selecionado;
  - cards, atividades, webhooks e drag/drop enviam `pipeline_id` para nao cair no funil padrao;
  - nao houve alteracao em Quepasa, listener de sync automatico, payload n8n ou tools de IA;
  - `git diff --check` passou;
  - `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou;
  - `docker image push delvechiotech/unicocrm:latest` publicou digest `sha256:c573fde235b25b70380cb98a13ce77643f569636452011c802859978c6ca4414`;
  - commit `2565f88` foi enviado para `main`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - tasks da stack passaram a rodar `delvechiotech/unicocrm:latest@sha256:c573fde235b25b70380cb98a13ce77643f569636452011c802859978c6ca4414`;
  - `https://chat.unicocrm.com/` respondeu HTTP `200 OK` apos o deploy.

Arquivos sensiveis deste chat:

- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`
- `app/javascript/dashboard/api/crm/kanban.js`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`
- `app/models/crm/kanban_card.rb`
- `app/models/crm/kanban_pipeline.rb`
- `app/models/crm/kanban_stage.rb`
- `app/models/crm/kanban_action.rb`
- `app/models/crm/kanban_activity.rb`
- `app/models/crm/kanban_webhook.rb`
- `app/jobs/crm/kanban_auto_sync_job.rb`
- `app/jobs/crm/kanban_webhook_job.rb`
- `app/listeners/crm/kanban_listener.rb`
- `app/services/crm/kanban/`
- `app/controllers/api/v1/accounts/crm/ai_agent_tools_controller.rb`
- `app/services/crm/ai_agents/payload_builder.rb`
- `config/routes.rb`
- migrations `20260508140000_create_crm_kanban_tables.rb` e `20260508153000_extend_crm_kanban_automation.rb`

Impactos em outras frentes:

- Chat 01 / Quepasa-mensageria: Kanban adicionou listener de `message_created`, mas nao alterou provider Quepasa nem parsing de webhook. Risco: qualquer regressao no dispatch de mensagens pode afetar criacao automatica de cards.
- Chat 02 / IA-n8n: tools de Kanban foram expandidas e payload n8n ganhou URL para criar atividade.
- Chat 03 / Style-UI: tela Kanban recebeu UI funcional nova e ainda merece revisao visual/responsiva.

Proxima acao recomendada para este chat:

- Validar em producao, com mensagem real recebida, se o card e criado/atualizado automaticamente.
- Validar manualmente criar/mover/arquivar card, criar/concluir atividade e criar webhook.
- Evoluir integracao com etiquetas nativas: exibir etiquetas do contato/conversa no card, filtro por etiqueta e regras etiqueta -> etapa.
- Adicionar testes Rails para `Crm::Kanban::AutoSyncService` e controller de atividades/webhooks.
- Ao voltar de outro chat, ler primeiro `MEMORIA_PROJETO.md`, `HANDOFF_CONTINUACAO.md` e `HANDOFF_CHATS_01_04.md`, depois rodar `git status --short`.

## Regras criticas

- Nao executar `git push` sem pedido explicito do Thiago.
- Nao sobrescrever alteracoes locais do usuario.
- Nao reverter arquivos sem entender se foram alterados por outro chat.
- Nao quebrar o conector nativo Quepasa/WhatsApp API.
- A pasta `docs_referencia` e qualquer codigo de Whaticket, Planka, Quepasa Swagger ou outras bases sao apenas referencias. O escopo e a arquitetura do UnicoCRM atual sempre prevalecem. So adaptar ideias dessas referencias quando for realmente necessario para o projeto, registrando a decisao no handoff.
- Antes de mexer em mensageria, ler `MEMORIA_PROJETO.md`.
- Antes de mexer no fluxo Quepasa, ler `app/services/whatsapp/quepasa/client.rb` e `app/services/whatsapp/providers/quepasa_service.rb`.
- A stack nao deve montar volume externo em `/app/public`, pois isso mascara assets novos.

## Workspace

- Workspace raiz: `C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex`
- Projeto principal: `C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop`
- Repositorio atual: `https://github.com/delvechio-tech/unicoCRM.git`
- Imagem Docker atual: `delvechiotech/unicocrm:latest`
- Imagem antiga: `delvechiotech/chatwoot-quepasa:latest`
- Portainer: `https://port.unicocrm.com`
- Stack Portainer: `chatwoot`, stack id `7`, endpoint `1`

## Estado de deploy mais recente

Ultimo build/push/deploy feito neste chat:

- Imagem: `delvechiotech/unicocrm:latest`
- Digest em producao: `sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f`
- Servicos atualizados:
  - `chatwoot_chatwoot_app`
  - `chatwoot_chatwoot_sidekiq`
- Validacao feita:
  - Build Docker com `docker/Dockerfile` concluiu.
  - Push Docker concluiu.
  - Portainer aceitou update da stack `chatwoot` com `PullImage=true`.
  - Tasks observadas rodando com digest `sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f`.
  - Logs do app mostraram Puma ouvindo em `http://0.0.0.0:3000`.
  - `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
  - Antes do app terminar de subir, houve `502` temporario no proxy; resolvido apos boot.

Importante: este deploy incluiu o estado local da pasta no momento do build, incluindo alteracoes ainda nao commitadas. Nao assumir que o repositorio remoto esta igual ao ambiente em producao.

## Quepasa / WhatsApp API

O Quepasa deve continuar funcionando como conector nativo dentro do Chatwoot:

- Criacao de caixa WhatsApp com opcao `WhatsApp API`.
- Aba `WhatsApp API` nas configuracoes da caixa.
- Criacao de bot no Quepasa.
- QR Code funcionando.
- Ao conectar, o QR Code deve sumir e mostrar status conectado.
- Toggles aplicam automaticamente no Quepasa.
- Webhook Quepasa cria conversas, contatos, grupos, midias, avatar e respostas citadas.
- `.vcf`/eventos internos C2S nao devem criar conversas indevidas.
- Mensagens com audio/foto/video nao devem exibir legenda generica `Audio`, `Foto`, `Video` quando nao houver texto real.
- Ao excluir caixa Quepasa, excluir tambem o bot correspondente no Quepasa.

### Ultimo bug Quepasa corrigido

Sintoma reportado:

```text
Quepasa settings update failed [400]:
{"success":false,"status":"create information controller, username validation: getting user name error: error for: unicocrm_...: sql: no rows in result set"}
```

Causa:

- A atualizacao dos toggles ainda chamava o endpoint de criacao do bot (`POST /info`) depois do `PATCH /info`.
- As chamadas normais do bot tambem levavam headers de master key, fazendo o Quepasa tentar validar usuario administrativo.

Correcao aplicada:

- `update_settings!` agora usa apenas `PATCH /info`.
- Chamadas normais do bot usam somente `X-QUEPASA-TOKEN`.
- Master key, usuario e senha ficam reservados para criacao/setup de conta/bot.

Arquivos principais:

- `app/services/whatsapp/quepasa/client.rb`
- `app/services/whatsapp/providers/quepasa_service.rb`

Validacao pendente com usuario:

- Thiago precisa testar novamente ligar/desligar toggles na aba `WhatsApp API` da inbox 13.
- Se ainda falhar, conferir logs Rails/Sidekiq e comparar headers enviados para `/info`.

## Agentes de IA

Primeira fatia implementada:

- Menu `Agentes de IA`.
- Tela `/app/accounts/:accountId/crm/ai-agents`.
- Produtos ficam no CRM, nao dentro do agente.
- Agente consulta produtos vinculados.
- n8n e o executor inicial.
- Dados salvos no banco do Chatwoot/UnicoCRM desde o inicio.

Tabelas envolvidas:

- `crm_ai_agents`
- `crm_products`
- `crm_ai_agent_products`
- `crm_ai_agent_inboxes`
- `crm_ai_agent_execution_logs`

APIs:

- `/api/v1/accounts/:account_id/crm/ai_agents`
- `/api/v1/accounts/:account_id/crm/products`

Arquivos principais:

- `app/models/crm/ai_agent.rb`
- `app/models/crm/product.rb`
- `app/models/crm/ai_agent_inbox.rb`
- `app/models/crm/ai_agent_execution_log.rb`
- `app/controllers/api/v1/accounts/crm/ai_agents_controller.rb`
- `app/controllers/api/v1/accounts/crm/products_controller.rb`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`

### Ponte n8n

Objetivo:

- Quando chegar mensagem `incoming` em uma inbox vinculada a um agente ativo, disparar o webhook do n8n configurado no agente.

Arquivos adicionados/alterados:

- `app/dispatchers/async_dispatcher.rb`
- `app/listeners/crm/ai_agent_listener.rb`
- `app/jobs/crm/ai_agent_execution_job.rb`
- `app/services/crm/ai_agents/n8n_executor.rb`

Regra inicial:

- Disparar apenas mensagens `incoming`, publicas, com `inbox_id`, e `webhook_sendable?`, para evitar loops.

Contrato de payload atual:

- Top-level `message_id` incluido para facilitar uso no n8n.
- `message.id` continua existindo com o mesmo valor.
- `session_id` segue o formato `account:<account_id>:conversation:<conversation_id>`.
- `tool_urls` divulga endpoints nativos para produtos, FAQs e, quando presente, Kanban.

Pendente:

- Testar com mensagem real se a execucao aparece no n8n e se `message_id` chega em `{{$json.body.message_id}}`.
- Verificar na tabela `crm_ai_agent_execution_logs` se request/response foram gravados.
- Se nao aparecer, verificar Sidekiq/Rails e o listener `Crm::AiAgentListener`.
- Validacao local pendente: o ambiente Windows atual nao tem `ruby` no PATH, entao nao foi possivel rodar `ruby -c`/RSpec localmente nesta etapa.

## Kanban / CRM

Kanban CRM nativo implementado e deployado em 2026-05-09.

Estado atual:

- Usa tabelas proprias de CRM, nao etiquetas/conversas como substituto do pipeline.
- Cards sincronizam automaticamente a partir de mensagens recebidas com contato/conversa.
- UI permite criar, editar, mover e arquivar cards; configurar etapas; usar resumo Captain; criar/concluir atividades; ver linha do tempo; configurar webhooks.
- IA/n8n pode pesquisar/atualizar cards e criar atividades via tools.
- Etiquetas nativas do Chatwoot ainda nao estao integradas ao Kanban; decisao atual e usa-las futuramente como camada auxiliar de filtro/automacao.
- Visual do Kanban foi refinado com inspiracao conceitual em Planka + Whaticket: colunas com acentos por etapa, cards com avatar/inicial do cliente, chips compactos, conversa destacada, metricas com icones e painel lateral mais proximo do atendimento comercial.
- A UI agora chama a acao de remocao de card de `Arquivar`, alinhada ao comportamento esperado de preservar historico.
- A rodada visual nao alterou contrato de API, sync automatico, webhooks nem tools de IA.

Arquivos principais:

- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`
- `app/javascript/dashboard/api/crm/kanban.js`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`
- `app/models/crm/kanban_card.rb`
- `app/models/crm/kanban_pipeline.rb`
- `app/models/crm/kanban_stage.rb`
- `app/models/crm/kanban_action.rb`
- `app/models/crm/kanban_activity.rb`
- `app/models/crm/kanban_webhook.rb`
- `app/jobs/crm/kanban_auto_sync_job.rb`
- `app/jobs/crm/kanban_webhook_job.rb`
- `app/listeners/crm/kanban_listener.rb`
- `app/services/crm/kanban/`
- migrations `20260508140000_create_crm_kanban_tables.rb` e `20260508153000_extend_crm_kanban_automation.rb`

Validacoes pendentes:

- Testar em producao com mensagem real se card e criado/atualizado automaticamente.
- Testar manualmente atividades, webhooks e regras de IA em conta real.
- Adicionar cobertura automatizada para auto-sync, atividades e webhooks.

## Super Admin / Feature flags

Problema corrigido anteriormente:

- Ativar `CRM AI Agents` no Super Admin causava 500 porque as feature flags do Chatwoot usam bitset com limite.

Decisao:

- Nao criar nova feature flag isolada para `crm_ai_agents`.
- Usar a flag existente `crm`.
- Mostrar `Agentes de IA` quando `FEATURE_FLAGS.CRM` estiver ativo.

Commit ja enviado antes da regra de nao-push:

- `a0ee541 Fix CRM feature flag overflow`

## Estado Git local observado

Ha muitas alteracoes locais e arquivos novos. Antes de qualquer commit, revisar cuidadosamente:

```powershell
git status --short
```

Principais areas alteradas:

- Quepasa client/provider.
- Agentes de IA.
- Produtos CRM.
- Sidebar/rotas/telas CRM.
- Kanban CRM.
- Estilos/tema.
- `MEMORIA_PROJETO.md`.
- `HANDOFF_CONTINUACAO.md`.

## Comandos uteis

Status:

```powershell
git status --short
```

Diff Quepasa:

```powershell
git diff -- app/services/whatsapp/quepasa/client.rb app/services/whatsapp/providers/quepasa_service.rb
```

Diff ponte n8n:

```powershell
git diff -- app/dispatchers/async_dispatcher.rb app/listeners/crm/ai_agent_listener.rb app/jobs/crm/ai_agent_execution_job.rb app/services/crm/ai_agents/n8n_executor.rb
```

Build Docker:

```powershell
docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .
```

Push Docker:

```powershell
docker push delvechiotech/unicocrm:latest
```

## Prompt para continuar este chat em outra conta

Use este prompt se voce for abrir outro chat com o mesmo nome deste:

```text
Nome deste chat/frente:
01 refactor: WhatsApp API nativo

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia estes arquivos:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md

Contexto essencial:
- Este projeto e um Chatwoot customizado, agora chamado UnicoCRM.
- O conector nativo Quepasa/WhatsApp API ja estava funcionando e nao pode ser quebrado.
- Este chat/frente e responsavel por proteger e evoluir o WhatsApp API nativo.
- Outros chats podem cuidar de Agentes de IA, Kanban/CRM e Infra, mas qualquer impacto em mensageria deve ser registrado no HANDOFF_CONTINUACAO.md.
- O repositorio atual e https://github.com/delvechio-tech/unicoCRM.git.
- A imagem Docker atual e delvechiotech/unicocrm:latest.
- O ultimo deploy conhecido em producao usa a digest sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f.
- Nao execute git push sem eu pedir explicitamente.
- Nao monte volume externo em /app/public na stack, pois isso esconde assets novos.

Tarefa para voce:
Continue exatamente do estado descrito em HANDOFF_CONTINUACAO.md, especificamente a frente "01 refactor: WhatsApp API nativo". Antes de editar, rode git status --short e revise os diffs relevantes para nao sobrescrever trabalho de outro chat.

Pontos sensiveis:
- Quepasa settings/toggles foram corrigidos separando chamadas de bot das chamadas administrativas. Se o erro voltar, comece por app/services/whatsapp/quepasa/client.rb.
- A ponte dos Agentes de IA para n8n existe via listener/job/executor, mas precisa ser validada em producao com mensagem incoming.
- Ha arquivos locais de Kanban/CRM que podem ainda nao estar finalizados.

Ao terminar sua etapa, voce precisa atualizar:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md

No final, escreva um handoff completo para eu voltar para o chat anterior, incluindo:
1. O que voce mudou.
2. Arquivos alterados.
3. Build/deploy feitos ou nao feitos.
4. Testes/validacoes executados.
5. Problemas encontrados.
6. Proximos passos recomendados.
7. Se houve ou nao git commit/push.
```

## Prompt base para criar outros chats

Ao criar os outros 3 chats, use este modelo e troque o nome/responsabilidade:

```text
Estou abrindo uma nova frente do projeto UnicoCRM.

Nome deste chat/frente:
[02/03/04 - nome definido pelo Thiago]

Responsabilidade deste chat:
[descrever exatamente o escopo desta frente]

Workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md

Regras:
- Nao execute git push sem eu pedir explicitamente.
- Nao sobrescreva alteracoes locais.
- Rode git status --short antes de editar.
- Atualize a secao deste chat em HANDOFF_CONTINUACAO.md ao terminar.
- Se sua mudanca afetar WhatsApp API/Quepasa/mensageria, registre impacto para o chat "01 refactor: WhatsApp API nativo".

Ao final da sua etapa, atualize MEMORIA_PROJETO.md e HANDOFF_CONTINUACAO.md com um handoff completo para eu voltar ao chat original.
```
