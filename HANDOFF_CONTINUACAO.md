# Handoff de Continuacao - UnicoCRM

Atualizado em: 2026-05-09

Este arquivo existe para permitir alternar entre chats/contas sem perder contexto. O projeto sera continuado em multiplos chats, cada um com uma responsabilidade clara.

## Documento para recriar os chats

Para recriar o projeto em outra conta, use primeiro:

- `HANDOFF_CHATS_01_04.md`
- `PROMPT_NOVA_CONTA.md`

Esse arquivo e o mapa operacional dos chats/frentes do projeto:

- Chat 01: WhatsApp API / Quepasa.
- Chat 02: Agentes de IA / n8n.
- Chat 03: Style / UI visual.
- Chat 04: Kanban / CRM comercial.
- Chat 05: Estoque / Produtos Comerciais.

Este `HANDOFF_CONTINUACAO.md` continua sendo a memoria longa do estado atual, deploy, riscos e historico desta conversa.

## Estado consolidado para limpeza

Atualizado em: 2026-05-11.

- Frente atual de limpeza: `00 - Revisao e Orquestracao de Handoffs`.
- Objetivo imediato: organizar documentacao, deploy atual, riscos e proximas frentes antes de mexer em codigo funcional.
- Deploy atual em producao: `delvechiotech/unicocrm:latest@sha256:b83d3af607d767d35d72fe28536771860e731bee5689fd5707395aa057a251cf`.
- Esse deploy corresponde a frente `04 - Kanban CRM` e passou por build, push, update Portainer e health check via Node/OpenSSL.
- Os demais digests espalhados neste arquivo sao historico por frente. Quando houver conflito, considerar esta secao consolidada como fonte atual.
- Proxima limpeza recomendada apos documentos: frente `05 - Estoque`, focando em ciclo de vida de produto, duplicacao de UI entre Estoque e Agentes, e validacoes minimas.

## Identidade deste chat

Nome deste chat:

```text
05 - Estoque
```

Responsabilidade deste chat:

- Planejar e implementar Estoque/Produtos Comerciais no UnicoCRM.
- Evoluir `crm_products` sem duplicar a fonte de verdade ja usada por Agentes de IA e Kanban.
- Registrar impactos em Chat 02 quando tocar tools/payloads de IA, em Chat 03 quando tocar UI/Style e em Chat 04 quando tocar Kanban/oportunidades.
- Fazer build/push/deploy somente quando autorizado pelo Thiago; nunca executar `git push` sem pedido explicito.
- Documentar tudo que afete produtos, estoque, disponibilidade, precos, midias, tools de IA, Kanban ou arquivos compartilhados.

Este chat deve ser tratado como a fonte principal de contexto para Estoque/Produtos Comerciais. Outros chats podem mexer no visual, IA ou Kanban, mas devem evitar alterar modelagem de produto/estoque sem registrar aqui ou sem handoff explicito.

## Organizacao dos chats do projeto

Use esta divisao para evitar conflito entre frentes:

| Chat | Nome | Responsabilidade principal | Pode mexer em | Deve evitar |
| --- | --- | --- | --- | --- |
| 01 | `01 refactor: WhatsApp API nativo` | Conector nativo Quepasa/WhatsApp API | Quepasa, inbox WhatsApp API, webhooks, envio/recebimento, midias, settings WhatsApp | Refactors amplos de CRM sem relacao com mensageria |
| 02 | `02 - Agentes de IA e n8n` | Agentes de IA e n8n | Agentes de IA, executor n8n, logs, vinculacao com inbox/produtos, tools, playground | Quebrar Quepasa ou alterar provider WhatsApp sem validar com Chat 01 |
| 03 | `03 - Style e UI` | Style/UI visual | Tema, cores, sidebar, refinamento visual de telas CRM | Alterar regra de negocio/API sem combinar |
| 04 | `04 - Kanban CRM` | Kanban / CRM comercial | Kanban, produtos, pipelines, tarefas, automacoes CRM | Alterar mensageria base ou webhooks Quepasa sem handoff |
| 05 | `05 - Estoque` | Estoque / Produtos Comerciais | `crm_products`, disponibilidade, quantidade, status comercial, SKU, preco, categoria, midias e integracoes com IA/Kanban | Duplicar produto sem necessidade, alterar Quepasa, mexer em Style/UI global ou Kanban/IA alem dos pontos combinados |

As frentes 00-05 estao nomeadas em `HANDOFF_CHATS_01_04.md`.

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
3. Ler `PATAGON.md`.
4. Rodar `git status --short`.
5. Revisar diffs dos arquivos que pretende tocar.
6. Identificar se sua mudanca afeta outro chat da tabela acima.
7. Para feature nova, refatoracao relevante ou mudanca de API/payload/tool/webhook/modelagem, registrar o gate Patagon antes de implementar.

## Gate Patagon obrigatorio

Patagon e o padrao de benchmarking e analise comparativa do UnicoCRM.

Antes de qualquer feature ou refatoracao relevante, o chat deve responder de forma curta:

- Benchmark: como Salesforce, HubSpot, Pipedrive, Intercom/Zendesk, Twenty ou outra referencia resolvem problema semelhante.
- Adaptacao: o que faz sentido para o UnicoCRM e o que nao deve ser copiado.
- Arquitetura: fonte de verdade, contratos afetados, acoplamentos e fronteiras entre frentes.
- Performance/escala: queries, payloads, jobs, listeners, indices, paginacao, limites e risco de degradar o Chatwoot original.
- Riscos: impactos em Quepasa, IA/n8n, Kanban, Estoque, Style/UI e Enterprise.
- Decisao: executar, simplificar, dividir em fases ou bloquear ate esclarecer.

Ordem recomendada:

```text
GSD status -> GitNexus contexto/impacto -> Patagon gate -> implementacao -> validacao -> handoff
```

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
- `DESIGN_SYSTEM.md` passa a ser a fonte de verdade da identidade visual UnicoCRM.
- Toda alteracao frontend do UnicoCRM deve seguir `DESIGN_SYSTEM.md`. A frente 03 - Style e UI e a fonte de verdade para identidade visual. Outras frentes podem implementar UI funcional, mas nao devem inventar novos padroes visuais sem registrar handoff para a frente 03.
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
- Em 2026-05-09, foi aplicada revisao ampla de identidade visual CRM inspirada no `docs_referencia/Exemplo leyout`:
  - referencia analisada: portal Lovable/shadcn com Inter, dark SaaS, sidebar escura, cards com borda/radius, inputs padronizados e acento laranja;
  - acento principal migrou de teal para laranja (`#FF5B25`) em `theme/colors.js` e nos tokens `n-blue`; teal/verde foi preservado para estados de sucesso/estoque;
  - sidebar recebeu item ativo em bloco arredondado, cor ativa laranja, maior respiro e radius 12px;
  - superficies dark foram reorganizadas para fundo quase preto/azulado, cards mais claros, bordas finas e menos sombras pesadas;
  - telas CRM visualmente afetadas: Agentes/Produtos, Kanban e Estoque;
  - nenhuma regra de negocio, controller, model, job, migration, payload ou contrato de API foi alterado intencionalmente nesta etapa.
  - build/push/deploy da etapa visual passou: digest publicado `sha256:e694c939d954c321219816900c7a766bbfc0839e30558ea1ec5504fe052d7105`; Portainer retornou update `completed` para `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq`; health publico respondeu HTTP `200`.
- Em 2026-05-10, a identidade visual foi refinada para um estilo mais Linear/Shadcn minimalista:
  - laranja `#FF5B25` mantido apenas como accent de acao/ativo/foco;
  - removidos gradientes, radiais e sombras fortes das telas CRM;
  - dark mode alinhado a fundo `hsl(220 15% 8%)`, cards `hsl(220 15% 11%)`, bordas finas e sidebar `hsl(220 15% 6%)`;
  - botoes primarios solidos, altura 40px, radius 12px; inputs com ring laranja no foco;
  - conteudo de configuracao de Agentes/Produtos e Estoque limitado em largura para melhor leitura em telas largas;
  - Kanban manteve densidade operacional, mas recebeu colunas/cards mais silenciosos no estilo Linear;
  - escopo intencional restrito a CSS/SCSS/tokens/classes de layout, sem alterar controllers, models, migrations, jobs, services ou contratos de API.
  - build/push/deploy passou: digest `sha256:68f3f1f2e34f6cf7691084c981f3c47c1becdfe2cd10ab35255be58854d4456a`; app e sidekiq `completed`; health publico HTTP `200`.
- Em 2026-05-10, o Kanban recebeu ajuste visual de configuracao de etapas:
  - `Parado apos`, `Chance` e exclusao de etapa ficaram escondidos no painel `Etapas`;
  - colunas do board passaram a mostrar apenas nome da etapa e contador, sem lixeira ou inputs tecnicos;
  - `Excluir funil` foi movido para dentro de `Configurar funil`;
  - regra de negocio mantida: os valores continuam manuais e salvos pelos fluxos existentes;
  - build/push/deploy passou com digest `sha256:d16499366903b5411b5e321cb77f657c04b4ffb0d7887986aaaf9d8fca079dc8`; app e sidekiq `completed`; health publico HTTP `200`.
- Em 2026-05-10, as metricas do Kanban foram recolhidas atras do botao `Metricas`:
  - o board abre mais limpo por padrao, e o botao mostra o resumo de cards ativos;
  - o titulo editavel da etapa ganhou override visual para ficar sem fundo de input, removendo o retangulo preto atras do texto;
  - escopo restrito ao `Index.vue` do Kanban, sem alterar contratos, API, services, jobs, controllers ou models;
  - build/push/deploy passou com digest `sha256:8b3f17fd27ae5a4dd9f9dc1f3922d966af2a5412973ac0efcd4f1cec9f14cc6c`; Portainer aceitou redeploy; health publico HTTP `200`; leitura final de status da API Portainer falhou por TLS intermitente.
- Em 2026-05-11, foi iniciada a frente `03 - Style e UI / Identidade Visual SaaS`:
  - Patagon aplicado para benchmark visual: adaptar disciplina de Linear/Twenty/HubSpot/Intercom, sem copiar layout ou arquitetura externa;
  - problemas identificados: telas novas tinham escala tipografica, cards, inputs, radius, botoes e metricas definidos localmente de formas diferentes;
  - primeira rodada implementada como fundacao compartilhada para paginas/classes `crm-*` em `_woot.scss`: tokens de acento/radius/espaco, escala de headings, superficies, cards, inputs, foco, botoes e chips;
  - `_next-colors.scss` recebeu ajuste pequeno no dark mode para fundo mais profundo e superficies mais legiveis;
  - `Sidebar.vue` recebeu ajuste visual leve na busca, botao de nova conversa e altura minima dos itens, sem alterar rotas ou comportamento;
  - escopo visual apenas; sem controller, model, migration, job, service, payload, Quepasa ou contrato alterado;
  - validacao inicial: `git diff --check` passou e `docker image build -f docker/Dockerfile -t unicocrm-style-check .` passou;
  - publicacao/deploy apos pedido explicito do Thiago: commit `657d5f1 style(crm): add SaaS visual foundation` foi enviado para `origin/main`; `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou; `docker image push delvechiotech/unicocrm:latest` publicou `sha256:c756030a16aa98be58d6aba73414e78af2bc553f76cabae0bca3f960be6a4704`; Portainer redeployou a stack; `app` e `sidekiq` ficaram `completed`; health publico HTTP `200`. Houve `502` temporario durante boot e falhas TLS intermitentes no PowerShell contra Portainer, mas validacao via Node confirmou status.
- Em 2026-05-11, foi criado `DESIGN_SYSTEM.md`:
  - documenta paleta, tokens, tipografia, espacamentos, radius, sombras, botoes, inputs/selects/textareas, cards/paineis, tabelas/listas, chips/badges/status, sidebar/navegacao, estados, responsividade, padroes CRM operacionais e anti-padroes visuais;
  - regra para proximas frentes: se a tarefa envolver frontend/UI, ler `DESIGN_SYSTEM.md` antes de editar e registrar handoff para a frente 03 quando houver necessidade de novo padrao visual.
- Em 2026-05-11, foi aplicada segunda rodada visual usando `DESIGN_SYSTEM.md` e a referencia `docs_referencia/canvas-visual.aura.build`:
  - adaptado: Inter, dark mode operacional, cards por superficie/borda, labels pequenas, acento laranja moderado, metricas com mais respiro e hierarquia mais clara;
  - nao copiado: hero/landing, beams, glow forte, cards inclinados, efeitos decorativos e arquitetura externa;
  - `_woot.scss` passou a concentrar tokens visuais CRM mais completos e padroes comuns para cards, inputs, botoes, tabelas, hover/focus e estados ativos;
  - `_next-colors.scss` recebeu ajuste visual pequeno em `border-container` no dark mode;
  - CSS local de Kanban, Agentes de IA/Produtos e Estoque foi harmonizado visualmente com o DS, sem alterar scripts, chamadas de API ou contratos;
  - validacao: `git diff --check` passou e busca por `letter-spacing` negativo nos arquivos CRM nao encontrou ocorrencias;
  - pendente: QA visual em browser para desktop/notebook/iPad e build/deploy apenas se o Thiago pedir explicitamente.
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
- Rodada de configuracao/regras em 2026-05-12:
  - Kanban ganhou abas persistentes de configuracao por funil: `Kanban`, `Etapas`, `Regras`, `Webhooks` e `Metricas`;
  - cabecalho superior do funil foi compactado: o nome do funil virou seletor principal e foram removidos badges/textos auxiliares para reduzir altura visual;
  - painel de regras deixou de ser apenas texto livre e passou a ter regras estruturadas em `pipeline.settings['automation_rules']`;
  - template `Conversas atrasadas` cria etapas e regras iniciais para `Novas Conversas`, `Nao Lidas`, `Lidas` e `Respondida`;
  - `Crm::Kanban::AutoSyncService` avalia regras ativas por funil antes do fallback para o pipeline comercial;
  - mensagens recebidas podem criar/atualizar card no funil/etapa configurados; mensagens enviadas pelo time podem mover card existente para `Respondida`, mas nao criam card novo sozinhas;
  - impacto Chat 01: listener do Kanban agora tambem enfileira mensagens publicas de saida para classificar cards existentes; nao houve mudanca no provider Quepasa nem no parsing de webhook;
  - impacto Chat 03: ajuste visual/UX localizado no Kanban seguindo `DESIGN_SYSTEM.md`;
  - validacao parcial: `git diff --check` passou; Ruby/specs via Docker ficaram bloqueados porque o Docker Desktop nao expos `dockerDesktopLinuxEngine` no pipe local durante esta etapa.
  - build/push/deploy executados apos autorizacao do Thiago:
    - `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou;
    - `docker image push delvechiotech/unicocrm:latest` publicou `sha256:aa3715260cce30505565d715a085f1fa56b293429a07586ae4c95b62d7c43302`;
    - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
    - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` usando o digest novo;
    - `https://chat.unicocrm.com/` respondeu HTTP `200 OK`;
    - `https://chat.unicocrm.com/health` respondeu HTTP `200 OK` com `{"status":"woot"}`.
- Rodada de follow-up nativo em 2026-05-15:
  - `IncomingIntentProcessor` passou a tratar mensagens incoming de follow-up;
  - opt-out explicito desqualifica o card, cancela agendas pendentes e grava `follow_up_intent.opted_out`;
  - negativas brandas gravam `follow_up_intent.awaiting_reschedule_preference`, preservando a diferenca entre remarcar e nao contatar mais;
  - board e painel do card passaram a exibir esses estados de forma compacta;
  - impacto Chat 01: o sync incoming agora tambem classifica intencao de follow-up, sem mudanca em Quepasa, provider ou parsing de webhook;
  - `NegotiatedScheduler` e `LongTermScheduler` foram adicionados para agendar retorno combinado e reativacao longa com regras do funil;
  - tools de IA novas: `create_kanban_follow_up` e `create_kanban_long_term_follow_up`;
  - a busca de cards para IA agora devolve `follow_up_intent` e `next_follow_up`, evitando reagendamento cego;
  - impacto Chat 02: payload n8n passou a divulgar as novas tools e instrui a IA a usa-las apenas quando houver data combinada ou retorno longo configurado.
  - execucao nativa ganhou `Crm::KanbanFollowUpDispatchJob`, `Crm::KanbanFollowUpExecutionJob` e `ExecutionService`;
  - o dispatcher roda a cada minuto via `config/schedule.yml`; agendas vencidas sem texto final passam antes por `Crm::KanbanFollowUpGenerationJob`;
  - `GenerationService` usa `Captain::KanbanFollowUpMessageService` com prompt proprio em portugues para gravar `generated_message`;
  - antes de enviar, a execucao revalida opt-out, card aberto e resposta posterior do cliente; depois cria message outgoing e chama `SendReplyJob`;
  - decisao de produto: sem mensagem final gerada/revisada, a agenda permanece pendente e nao dispara texto cru para o cliente.
  - cada funil agora define `delivery_mode` (`automatic` ou `review_before_send`);
  - no modo de revisao, mensagens geradas ficam com `review_state: pending_review`, nao sao despachadas e podem ser editadas/aprovadas/canceladas no painel do card.
  - `CadenceAdvancer` passou a abrir o proximo passo apos cada follow-up enviado, respeitando `max_attempts`;
  - quando a cadencia se esgota, o sistema registra `cadence_exhausted` ou agenda retorno longo se essa opcao estiver habilitada no funil.

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

### 05 - Estoque

Estado atual deste chat:

- Frente iniciada em 2026-05-09 para planejar/criar Estoque dentro do UnicoCRM.
- Documentos obrigatorios foram lidos: `MEMORIA_PROJETO.md`, `HANDOFF_CONTINUACAO.md` e `HANDOFF_CHATS_01_04.md`.
- `git status --short` estava limpo no inicio da etapa.
- Estado atual de produtos CRM revisado:
  - `app/models/crm/product.rb`
  - `app/controllers/api/v1/accounts/crm/products_controller.rb`
  - `app/javascript/dashboard/api/crm/products.js`
  - `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
  - referencias de IA/Kanban que consomem produtos.
- `crm_products` ja contem nome, SKU, categoria, moeda, preco, ativo, descricao, FAQ, objecoes, notas de midia, `metadata` e anexos ActiveStorage.
- Produtos ja alimentam Agentes de IA via `crm_ai_agent_products` e Kanban via `crm_kanban_cards.product_id`.
- Recomendacao inicial: Estoque deve evoluir `crm_products`, com tabela relacionada para movimentos/reservas caso o controle precise de historico transacional.
- Implementacao inicial aplicada apos confirmacao do Thiago:
  - migration `20260509100000_add_inventory_fields_to_crm_products.rb` adiciona disponibilidade, quantidade, reservado, alerta de baixo estoque e controle de inventario;
  - `Crm::Product` valida status/quantidades e calcula `available_quantity`, `low_stock?` e `sale_available?`;
  - Products API aceita/retorna campos de estoque e indicadores derivados;
  - sidebar ganhou acesso direto `Estoque`;
  - rota `/app/accounts/:accountId/crm/inventory` ganhou tela operacional com lista lateral, busca, metricas, editor comercial e midias;
  - tela de Agentes/Produtos tambem edita os campos novos para preservar compatibilidade;
  - tools de IA e payload n8n incluem disponibilidade/quantidade e instruem a IA a nao presumir estoque;
  - Kanban recebe dados de estoque no produto e exibe chip de disponibilidade nos cards.
- Nao houve deploy, commit ou push nesta etapa.
- Validacoes:
  - `git diff --check` passou;
  - `node --check app/javascript/dashboard/routes/dashboard/crm/crm.routes.js` passou;
  - `node --check app/javascript/dashboard/api/crm/products.js` passou;
  - `docker image build -f docker/Dockerfile -t unicocrm-inventory-check .` passou e gerou manifest list local `sha256:371821deb1cd78386b3ab7bcbdb1a8e96270f199469d1b3765b3fd0b9f4236f9`;
  - `ruby` e `pnpm` nao estavam disponiveis diretamente no PATH local, mas o build Docker executou bundle/pnpm/assets dentro da imagem.
- Build/push/deploy executados apos pedido explicito do Thiago:
  - `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`;
  - `docker image push delvechiotech/unicocrm:latest` passou e publicou digest `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` usando `delvechiotech/unicocrm:latest@sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`;
  - `https://chat.unicocrm.com` respondeu HTTP `200 OK` via Node/OpenSSL;
  - `https://chat.unicocrm.com/health` respondeu HTTP `200 OK` com `{"status":"woot"}`;
  - PowerShell/curl locais apresentaram falhas de TLS/conexao durante validacao HTTPS, entao a validacao final foi feita via Node.
- Nao houve commit ou git push nesta etapa.

Arquivos sensiveis deste chat:

- `app/models/crm/product.rb`
- `app/controllers/api/v1/accounts/crm/products_controller.rb`
- `app/services/crm/ai_agents/product_search.rb`
- `app/controllers/api/v1/accounts/crm/ai_agent_tools_controller.rb`
- `app/javascript/dashboard/api/crm/products.js`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`
- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`
- migrations futuras de `crm_products` ou tabelas de estoque relacionadas.
- `app/javascript/dashboard/routes/dashboard/crm/inventory/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/crm.routes.js`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/services/crm/ai_agents/payload_builder.rb`

Impactos em outras frentes:

- Chat 02 / IA-n8n: tools de produto e FAQ agora retornam disponibilidade/quantidade; payload n8n orienta a IA a checar `availability_status`, `sale_available` e `available_quantity`.
- Chat 03 / Style-UI: foi criada tela nova de Estoque e a tela Agentes/Produtos recebeu um bloco visual adicional; recomenda-se QA visual desktop/notebook/iPad.
- Chat 04 / Kanban CRM: cards passam a exibir chip de disponibilidade do produto; nao houve mudanca no fluxo de automacao, sync, stages ou movimentacao.
- Chat 01 / Quepasa: sem impacto previsto, desde que Estoque nao mexa em mensageria/webhooks.

Proxima acao recomendada para este chat:

- Rodar migration no ambiente de execucao antes de usar a tela nova.
- Validar em browser a rota `/app/accounts/:accountId/crm/inventory` e a sidebar `Estoque`.
- Validar que IA/n8n recebe os campos novos nas tools de produto.
- Validar Kanban com card vinculado a produto controlado por estoque.
- Planejar movimentos/reservas como tabela propria relacionada a produto somente se o Thiago confirmar necessidade de historico, reserva por card ou auditoria de entrada/saida.

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

Deploy atual consolidado:

- Imagem: `delvechiotech/unicocrm:latest`
- Digest em producao: `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`
- Servicos atualizados:
  - `chatwoot_chatwoot_app`
  - `chatwoot_chatwoot_sidekiq`
- Validacao feita:
  - Build Docker com `docker/Dockerfile` concluiu.
  - Push Docker concluiu.
  - Portainer aceitou update da stack `chatwoot` com `PullImage=true`.
  - Tasks observadas rodando com digest `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`.
  - `https://chat.unicocrm.com` respondeu HTTP `200 OK` via Node/OpenSSL.
  - `https://chat.unicocrm.com/health` respondeu HTTP `200 OK` com `{"status":"woot"}`.
  - PowerShell/curl locais apresentaram falhas de TLS/conexao durante validacao HTTPS; a validacao final confiavel desta etapa foi via Node/OpenSSL.

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
- O ultimo deploy conhecido em producao usa a digest sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4.
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

## Atualizacao 2026-05-11 - Frente 04 Kanban CRM

Status:

- Foi feita uma passada de estabilizacao do Kanban nativo CRM.
- A arvore estava limpa no inicio (`git status --short` sem saida).
- Nao houve commit, push ou deploy.

Alteracoes:

- `app/listeners/crm/kanban_listener.rb`: listener ignora evento sem mensagem antes de enfileirar `Crm::KanbanAutoSyncJob`.
- `app/services/crm/kanban/auto_sync_service.rb`: sync automatico procura card aberto ativo na conta inteira antes de criar no funil padrao, usa `account.with_lock` e tolera metadata nula.
- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`: metricas de atividades passaram a ser por pipeline, webhook update/delete ficou limitado ao pipeline visivel/global, e `last_message` foi preloaded no board.
- `app/javascript/dashboard/api/crm/kanban.js`: delete de webhook aceita params para enviar `pipeline_id`.
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`: tratamento de erro mais consistente e normalizacao do payload de produtos.
- `spec/listeners/crm/kanban_listener_spec.rb`: cobertura minima do listener.
- `spec/services/crm/kanban/auto_sync_service_spec.rb`: cobertura minima de criacao e anti-duplicidade entre funis.

Impactos:

- Chat 01: sync automatico por mensagem foi ajustado, mas sem alterar Quepasa/WhatsApp diretamente. Precisa validar com mensagem incoming real.
- Chat 02: sem mudanca em tools/payloads de IA.
- Chat 03: sem redesenho; apenas robustez no `Index.vue`.
- Chat 05: Kanban ficou mais tolerante ao formato de resposta de produtos, sem mudar estoque/modelo.

Validacoes:

- `git diff --check` passou.
- Docker Desktop foi aberto e validado.
- Foi criado override temporario local em `C:\tmp\unicocrm-compose-postgres-override.yml` para o Postgres dev aceitar `POSTGRES_HOST_AUTH_METHOD=trust`; arquivo fora do repo.
- Banco de teste foi criado/preparado via Docker.
- `docker compose -f docker-compose.yaml -f C:\tmp\unicocrm-compose-postgres-override.yml run --rm --no-deps -e RAILS_ENV=test -e NODE_ENV=test rails bundle exec rspec spec/listeners/crm/kanban_listener_spec.rb spec/services/crm/kanban/auto_sync_service_spec.rb` passou: 4 exemplos, 0 falhas.
- `node --check app/javascript/dashboard/api/crm/kanban.js` passou.
- App local respondeu `http://localhost:3000/health` com `{"status":"woot"}`.
- Tentativa de abrir UI local ficou limitada pelo Vite Docker dev: `pnpm install --force` no start e respostas vazias/timeout enquanto reinstala dependencias. A validacao visual local ainda nao foi concluida.

Pendencias:

- Validar manualmente criar/mover/arquivar card, atividade, webhook e produto/estoque.
- Validar sync automatico com mensagem real em producao/homologacao.

### Incremento UX Kanban 2026-05-11

- Foi iniciada a implementacao incremental do Patagon de navegacao/configuracao do Kanban.
- Primeira fatia aplicada: o formulario de criar/editar funil em `Index.vue` agora inclui `Regras do funil` e salva o campo existente `ai_rules` junto com nome/descricao.
- O titulo da pagina agora mostra o nome do funil ativo quando carregado.
- Sem alteracao em backend, banco, jobs, Quepasa/WhatsApp, tools de IA ou estoque.
- Impacto Chat 03: ajuste visual/UX localizado no Kanban.
- Validacao executada: `git diff --check` passou.
- Nao houve commit, push ou deploy.

### Incremento UX Kanban - menu do funil 2026-05-11

- Segunda fatia aplicada no `Index.vue`: menu de tres pontinhos no funil ativo.
- O menu agrupa `Configurar funil`, `Regras`, `Etapas`, `Webhooks` e `Excluir funil` para funis nao padrao.
- `Novo funil` segue visivel como acao principal.
- A exclusao via menu reaproveita `deletePipeline`, sem mudar a regra atual de confirmacao/exclusao.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado.
- Validacao: `git diff --check` passou.
- Nao houve commit, push ou deploy.

### Incremento Kanban - SLA, filtros e templates 2026-05-11

- Foi implementada estrategia hibrida de SLA/urgencia:
  - cards com conversa vinculada usam o SLA nativo do Chatwoot (`applied_sla`);
  - cards sem SLA/conversa usam regra propria do Kanban por `stale_after_days` da etapa.
- `kanban_controller.rb` passou a enviar `urgency` no payload do card e `sla_missed_cards` nas metricas.
- `Index.vue` passou a renderizar chip de urgencia, metrica `SLA vencido`, busca e filtros rapidos.
- Criacao de funil ganhou templates: Vendas, Suporte, Recuperacao e Onboarding.
- Templates criam etapas iniciais com prazos e probabilidades, sem migration nova.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado no Kanban.
- Validacoes:
  - `git diff --check` passou;
  - sintaxe Ruby do controller passou via Docker;
  - banco de teste precisou de `rails db:migrate` porque estava com migrations pendentes;
  - specs de listener e auto-sync passaram com 4 exemplos, 0 falhas.
- `db/schema.rb` foi restaurado apos migracao local de teste.
- Nao houve commit, push ou deploy.

### Deploy Frente 04 Kanban CRM 2026-05-11

- Publicacao autorizada e executada.
- Build:
  - `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .`
  - build passou com assets precompilados.
- Push Docker Hub:
  - `docker image push delvechiotech/unicocrm:latest`
  - digest: `sha256:6c74ae1ac4f060c690bb72da85b586e9a7ec14dcd877db3be80e78237e091748`.
- Deploy:
  - Stack Portainer `chatwoot` atualizada com `PullImage=true`.
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram `completed/update completed`.
  - Ambos apontam para `delvechiotech/unicocrm:latest@sha256:6c74ae1ac4f060c690bb72da85b586e9a7ec14dcd877db3be80e78237e091748`.
- Health:
  - `https://chat.unicocrm.com/` HTTP 200;
  - `https://chat.unicocrm.com/health` HTTP 200 com `{"status":"woot"}` via Node.
- Observacao: PowerShell/curl local tiveram falhas pontuais de TLS/conexao ao validar `/health`; Node confirmou o endpoint.
- Sem git commit e sem git push de codigo.

### Incremento UX Kanban - menu de cards 2026-05-11

- Quarta fatia aplicada no `Index.vue`: menu de tres pontinhos em cada card.
- Acoes iniciais: editar card, abrir conversa, resumo IA e arquivar card.
- Abertura de conversa depende de conversa vinculada.
- Resumo IA reaproveita o fluxo existente do painel lateral; nao houve mudanca em tools/payloads de IA.
- Arquivamento reaproveita `deleteCard`, preservando a regra de arquivar em vez de apagar historico.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado.
- Validacao: `git diff --check` passou.
- Nao houve commit, push ou deploy.

### Incremento UX Kanban - menu de etapas e fechamento rapido 2026-05-11

- Terceira fatia aplicada no `Index.vue`: menu de tres pontinhos no header de cada etapa/coluna.
- Menu de etapa inclui `Editar etapa` e `Excluir etapa`.
- `Editar etapa` abre o painel existente de configuracao das etapas; `Excluir etapa` reaproveita `deleteStage`.
- `Esc` fecha menus, paineis de configuracao e painel lateral de card.
- Clique fora fecha paineis principais, menus e painel lateral.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado.
- Validacao: `git diff --check` passou.
- Nao houve commit, push ou deploy.

### Incremento UX Kanban - compactacao e configuracao 2026-05-12

- Frente 04 compactou a UI do Kanban para reduzir espaco inutil no topo, abas, metricas, colunas e cards.
- Busca/filtro ficam restritos a aba `Kanban`; abas de configuracao ficam mais diretas.
- Cards passaram a usar chip curto de urgencia (`Em dia`, `Atencao`, `Atrasado`, `SLA vencido`) para evitar sobreposicao no titulo.
- Aba `Etapas` foi refeita como tabela compacta com nome, cor, prazo parado, chance e acoes; a cor configurada alimenta o acento da coluna.
- Aba `Webhooks` foi reorganizada em formulario horizontal + lista/tabela.
- Metricas seguem como calculos automaticos de status, atividades e SLA/regra propria; gatilhos automaticos continuam na aba `Regras`.
- Ajuste posterior removeu repeticao visual entre toolbar superior, abas e menu do funil: a navegacao principal fica nas abas; o menu fica focado em configurar, criar e excluir funil.
- Impacto Chat 03: ajuste visual/UX localizado.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Build/push/deploy executados:
  - Docker Hub publicou `sha256:b83d3af607d767d35d72fe28536771860e731bee5689fd5707395aa057a251cf`;
  - Portainer atualizou `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` com update `completed`;
  - `/health` respondeu HTTP 200 com `{"status":"woot"}`.
- Sem git commit e sem git push de codigo.

### Incremento UX Kanban - board como area principal 2026-05-14

- Frente 04 aplicou uma compactacao adicional no modo board.
- Funil ativo, busca, filtro, metrica rapida, menu do funil e `Novo card` ficam na mesma faixa para reduzir espaco morto.
- As abas aparecem apenas quando uma configuracao esta aberta; em `Kanban`, o board sobe e ocupa mais tela.
- Regras, etapas, webhooks, metricas e configuracoes do funil seguem acessiveis pelo menu de tres pontos e/ou abas de configuracao quando abertas.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado.
- Validacoes:
  - `git diff --check` passou;
  - `node --check app/javascript/dashboard/api/crm/kanban.js` passou;
  - specs de listener e auto-sync passaram com 7 exemplos e 0 falhas.
- Build/push/deploy executados:
  - Docker Hub publicou `sha256:472ccedbdc120b3d15791580380bb29526eb2bfc1a3e89e71081ce9cf577acdf`;
  - Portainer atualizou `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` com update `completed`;
  - `/health` respondeu HTTP 200 com `{"status":"woot"}`.

### Incremento Kanban - resumo comercial e vinculos imutaveis 2026-05-15

- Frente 04 iniciou a fase 1 do novo plano de follow-up sem ainda implementar o motor de cadencia.
- `Metricas` saiu da toolbar principal e fica apenas no menu do funil.
- `Contato ID` e `Conversa ID` viraram vinculos imutaveis apos serem definidos:
  - readonly no painel do card;
  - update backend descarta tentativa de troca quando o card ja possui vinculo.
- Foi criado um resumo proprio do Kanban:
  - endpoint dedicado por card;
  - servico `Captain::KanbanSummaryService`;
  - prompt dedicado `kanban_summary` em portugues, 30 a 60 palavras, sem titulos.
- Impacto Chat 02: novo contrato de IA restrito ao Kanban.
- Sem impacto novo em Chat 01, Chat 03 ou Chat 05.

### Incremento Kanban - configuracao de follow-up 2026-05-15

- Frente 04 implementou a fase 2 do plano de follow-up: configuracao persistida por pipeline, ainda sem execucao automatica.
- `Regras` agora possui um bloco de `Follow-up automatico` com:
  - ativacao;
  - instrucao livre;
  - cadencia;
  - limite de tentativas;
  - reagendamento inteligente;
  - retorno longo;
  - horario comercial;
  - excecoes por canal.
- Persistencia feita em `pipeline.settings.follow_up_settings`, separando configuracao da futura modelagem de execucao/historico.
- Sem impacto novo em Chat 01, Chat 02 ou Chat 05.
- Impacto Chat 03: ajuste visual/UX localizado na aba `Regras`.

### Decisao de produto/arquitetura 2026-05-15

- Thiago confirmou a separacao em tres camadas:
  - `Core`;
  - `Intelligence`;
  - `Agent`.
- Follow-up inteligente sera feature da camada `Intelligence`, disponivel mesmo quando a conversa for humana e sem depender do agente autonomo premium.
- Direcao tecnica acordada para a fase 3:
  - Rails/Kanban e dono do estado e regras do follow-up;
  - IA externa/servico dedicado pode gerar/classificar, mas nao guardar a verdade do fluxo;
  - n8n permanece como integracao/orquestracao e executor do agente premium no curto prazo, nao como dono do motor nativo de follow-up.
- Esta decisao impacta o desenho futuro da frente 02, mas ainda nao houve mudanca de payload/tool nesta rodada.

### Incremento Kanban - base operacional de follow-up 2026-05-15

- Frente 04 abriu a fase 3 com modelagem propria de follow-up:
  - schedules;
  - events;
  - servico de agendamento;
  - servico de cancelamento.
- `KanbanAutoSyncJob` agora usa o card retornado pelo sync para:
  - agendar primeiro follow-up de pipelines ativos em mensagens `outgoing`;
  - cancelar schedules pendentes em mensagens `incoming`.
- Ainda nao ha sweep job nem envio automatico; esta rodada entregou somente estado/auditoria/cancelamento.
- Validacoes:
  - migration de teste executada;
  - specs de listener, auto-sync, scheduler e cancellation passaram com 10 exemplos e 0 falhas.
- Impacto Chat 01: o fluxo de mensagem continua sem mudanca em Quepasa, mas o job de sync do Kanban passou a produzir efeitos adicionais de follow-up.
- Sem impacto novo em Chat 02, Chat 03 ou Chat 05.

### Incremento Kanban - visibilidade e override local do follow-up 2026-05-15

- Payload de card agora inclui `next_follow_up`.
- Board e detalhe do card exibem o próximo contato automático quando houver schedule ativo.
- Novos serviços:
  - `ScheduleCanceler`;
  - `PipelineTransitionService`.
- Schedules pendentes passam a ser cancelados em:
  - resposta do cliente;
  - nova mensagem outgoing;
  - mudança de pipeline;
  - fechamento/arquivamento do card;
  - override local `paused`.
- O card agora permite escolher entre herdar a regra do funil ou pausar o follow-up naquele caso.
- Foi adicionado follow-up especifico por card:
  - endpoint dedicado;
  - schedule `manual_override`;
  - data/hora + instrucao livre no painel lateral;
  - substituicao da agenda geral pendente.
- O `Scheduler` agora usa:
  - `channel_overrides` no primeiro timing;
  - `business_hours_*` para empurrar a agenda ate a proxima janela comercial valida.
- Ainda faltam:
  - motor de execução/envio;
  - classificação inteligente de negativa/opt-out;
  - retorno longo automatizado.
- Impacto Chat 01: transições de pipeline vindas do sync passam a cancelar follow-ups pendentes.
- Impacto Chat 03: houve ajuste visual localizado no card e no painel lateral.

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

### Ajuste Kanban - usabilidade e consistencia do follow-up 2026-05-15

- Corrigido o scroll vertical das abas administrativas do Kanban.
- Corrigido o envio de datas de atividade/follow-up manual: a UI converte `datetime-local` para ISO/UTC antes de chamar a API.
- Adicionado cancelamento direto para qualquer `next_follow_up` pendente no painel lateral do card.
- A configuracao de etapas saiu do layout de tabela comprimida para cards por etapa com campos explicitamente rotulados.
- Menus de funil, etapa e card foram padronizados no mesmo alinhamento visual.
- Leitura atual do produto:
  - `automation_rules` sao regras executaveis do auto-sync;
  - `ai_rules` continuam sendo orientacao textual para IA/ferramentas, nao logica executavel por si so;
  - metricas atuais cobrem cards, parados, orcamento aberto, agenda, atrasos e SLA, mas ainda nao medem desempenho de follow-up.
- Impacto Chat 03: refinamento visual localizado no Kanban.
