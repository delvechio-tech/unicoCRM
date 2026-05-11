# Handoff dos Chats 01-05 - UnicoCRM

Atualizado em: 2026-05-09

Este documento serve para recriar o projeto em outra conta dividindo o trabalho em frentes/chats. Ele deve ser enviado para cada novo chat junto com a orientacao especifica da sua frente.

## Como usar este documento

Para abrir um novo chat:

1. Se estiver migrando para outra conta, crie primeiro o chat `00 - Revisao e Orquestracao de Handoffs`.
2. Depois escolha a frente correta na secao `Divisao dos chats`.
3. Copie o bloco chamado `PROMPT DE ABERTURA` da frente escolhida.
4. Cole esse prompt como a primeira mensagem do novo chat.
5. Depois de o chat trabalhar, copie o bloco chamado `PROMPT DE FECHAMENTO`.
6. Cole o prompt de fechamento no final do chat para obrigar o novo chat a atualizar memorias e devolver um handoff completo.

Para uma feature nova que nao se encaixa nos chats 01-05:

1. Use a secao `Modelo para nova feature ou novo escopo`.
2. Crie um novo numero/nome, por exemplo `05 - Relatorios CRM`.
3. Defina claramente o dono da feature, arquivos provaveis, limites e impactos nos outros chats.
4. Ao terminar, atualize este arquivo com a nova frente.

Arquivos obrigatorios para qualquer chat novo ler antes de agir:

- `MEMORIA_PROJETO.md`
- `HANDOFF_CONTINUACAO.md`
- `HANDOFF_CHATS_01_04.md`
- `PATAGON.md`
- `PROMPT_NOVA_CONTA.md`, quando estiver migrando para outra conta/chat

Regra central: cada chat trabalha no seu escopo, atualiza os documentos ao terminar e deixa um handoff claro para o Thiago voltar ao chat atual sem perder contexto.

Regra Patagon: toda feature nova, refatoracao relevante ou mudanca de API/payload/tool/webhook/modelagem deve passar por benchmarking e critica arquitetural antes da execucao.

## Estado global do projeto

- Produto: UnicoCRM, baseado em Chatwoot Enterprise customizado.
- Workspace principal: `C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop`
- Repositorio: `https://github.com/delvechio-tech/unicoCRM.git`
- Imagem Docker atual: `delvechiotech/unicocrm:latest`
- Stack Portainer: `chatwoot`, stack id `7`, endpoint `1`
- URL: `https://chat.unicocrm.com`
- Ultimo deploy conhecido em producao: digest `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`
- Frente do deploy atual: `05 - Estoque`
- O deploy pode conter alteracoes locais ainda nao commitadas. Nao assumir que GitHub e producao estao iguais.
- Nao executar `git push` sem pedido explicito do Thiago.
- Nao montar volume externo em `/app/public`, pois isso pode servir assets antigos e esconder telas novas.
- A pasta `docs_referencia` e qualquer codigo de Whaticket, Planka, Quepasa Swagger ou outras bases sao apenas referencias. Sempre seguir primeiro o escopo e arquitetura do UnicoCRM atual. So adaptar ideias dessas referencias quando for realmente necessario para o projeto, mantendo padroes do Chatwoot/UnicoCRM e registrando a decisao no handoff.

## Divisao dos chats

| Chat | Nome recomendado | Responsabilidade | Pode mexer | Deve evitar |
| --- | --- | --- | --- | --- |
| 00 | `00 - Revisao e Orquestracao de Handoffs` | Revisar memorias, consolidar handoffs e apontar conflitos entre frentes | Documentos de memoria/handoff, prompts, matriz de escopo, riscos entre chats | Implementar feature, deployar ou fazer push sem pedido explicito |
| 01 | `01 refactor: WhatsApp API nativo` | Criar, corrigir e proteger a feature WhatsApp API / Quepasa | Quepasa, inbox WhatsApp API, QR Code, toggles, webhooks, midias, envio/recebimento, exclusao de bot | Refactors amplos de CRM, Style, IA ou Kanban sem relacao com mensageria |
| 02 | `02 - Agentes de IA e n8n` | Criar/atualizar a feature de agente IA, produtos, tools e executor n8n | Agentes IA, produtos CRM usados por IA, payload n8n, logs, playground, tools | Alterar provider Quepasa ou fluxo base de webhook sem avisar Chat 01 |
| 03 | `03 - Style e UI` | Padronizar visual, tema, sidebar, telas CRM e experiencia frontend | SCSS, tema, cores, componentes visuais, sidebar, refinamento visual de IA/Kanban | Mudar regras de negocio, migrations ou integracoes sem combinar |
| 04 | `04 - Kanban CRM` | Criar/atualizar Kanban, pipeline, cards, atividades, automacoes e tools de Kanban | Models/controllers/jobs/services/UI de Kanban, pipeline, cards, atividades, webhooks CRM | Mexer em Quepasa ou IA fora das tools/contratos combinados |
| 05 | `05 - Estoque` | Criar/atualizar Estoque e Produtos Comerciais | `crm_products`, disponibilidade, quantidade, status comercial, SKU, preco, categoria, midias, tools de produto e integracao produto-Kanban | Duplicar produto sem necessidade, alterar Quepasa, mexer em Style/UI global ou Kanban/IA fora dos contratos combinados |

## Protocolo de inicio para qualquer chat

1. Ler `MEMORIA_PROJETO.md`.
2. Ler `HANDOFF_CONTINUACAO.md`.
3. Ler este `HANDOFF_CHATS_01_04.md`.
4. Ler `PATAGON.md`.
5. Rodar `git status --short`.
6. Revisar `git diff` dos arquivos que pretende tocar.
7. Declarar se a tarefa encosta no escopo de outro chat.
8. Para feature nova, refatoracao relevante ou mudanca de contrato, registrar o gate Patagon antes de executar.
9. Trabalhar somente no escopo recebido, salvo pedido explicito do Thiago.
10. Tratar `docs_referencia` como inspiracao/consulta, nao como fonte para copiar escopo ou arquitetura sem necessidade real.

## Protocolo de encerramento para qualquer chat

Ao terminar uma etapa relevante, o chat deve atualizar:

- `MEMORIA_PROJETO.md`, com decisoes permanentes e estado tecnico real.
- `HANDOFF_CONTINUACAO.md`, com estado operacional, deploy, validacoes e pendencias.
- `HANDOFF_CHATS_01_04.md`, se o escopo, status ou arquivos sensiveis da sua frente mudarem.

O handoff final da resposta deve conter:

1. O que foi alterado.
2. Arquivos alterados.
3. Build/deploy feitos ou nao feitos.
4. Testes/validacoes executados.
5. Problemas encontrados.
6. Proximos passos recomendados.
7. Se houve ou nao commit/push.
8. Se mexeu em arquivo compartilhado com outro chat.
9. Bloco Patagon quando a etapa envolveu feature, refatoracao ou mudanca de contrato.

## Prompt de fechamento universal

Use este prompt no final de qualquer chat, independente da frente. Ele serve para fechar o ciclo e trazer a memoria de volta para o chat atual.

```text
PROMPT DE FECHAMENTO

Antes de encerrar esta etapa, atualize os documentos de memoria do projeto:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md, se o escopo/status/arquivos sensiveis desta frente mudaram

Depois responda com um handoff completo para eu colar no chat principal, contendo obrigatoriamente:

1. Nome da frente/chat.
2. Objetivo da etapa.
3. O que voce mudou.
4. Arquivos criados/alterados/removidos.
5. Build/deploy feitos ou nao feitos.
6. Testes e validacoes executados.
7. Problemas, riscos ou decisoes importantes.
8. Proximos passos recomendados.
9. Se houve commit, push ou PR.
10. Se mexeu em arquivo compartilhado com outra frente.
11. O que o proximo chat deve ler primeiro.

Regras:
- Nao execute git push se eu nao pedi explicitamente.
- Nao esconda pendencias.
- Se alguma validacao nao foi feita, diga claramente.
- Se voce alterou algo que afeta WhatsApp/Quepasa, IA/n8n, Style/UI ou Kanban, registre o impacto.
- Se usou alguma referencia externa/local (`docs_referencia`, Whaticket, Planka, Swagger etc.), explique o que foi aproveitado e por que isso era necessario dentro do escopo atual do UnicoCRM.
```

## Chat 00 - Revisao e Orquestracao de Handoffs

Missao:

- Ser o orquestrador de handoffs entre as frentes do projeto.
- Revisar memorias e handoffs produzidos pelos chats 01, 02, 03, 04 e futuros chats.
- Detectar conflitos entre frentes antes que virem regressao.
- Manter `MEMORIA_PROJETO.md`, `HANDOFF_CONTINUACAO.md` e `HANDOFF_CHATS_01_04.md` consistentes.
- Preparar prompts de abertura/fechamento para novos chats quando necessario.

Memoria essencial:

- Este chat nao implementa features por padrao.
- Este chat nao faz deploy, push ou alteracao de produto sem pedido explicito do Thiago.
- Ele pode corrigir documentos de memoria/handoff, matriz de escopo, prompts e regras de coordenacao.
- Deve garantir que `docs_referencia` seja tratado como referencia/inspiracao, nao como escopo automatico.

Arquivos sensiveis:

- `MEMORIA_PROJETO.md`
- `HANDOFF_CONTINUACAO.md`
- `HANDOFF_CHATS_01_04.md`

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
00 - Revisao e Orquestracao de Handoffs

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Sua responsabilidade e ser o chat orquestrador de handoffs entre as frentes do projeto. Voce nao deve implementar features por padrao. Seu papel principal e revisar memorias, detectar conflitos entre chats, manter os handoffs consistentes e garantir que cada frente saiba exatamente o que fazer.

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Depois rode:
git status --short

Escopo deste chat:
- Revisar handoffs produzidos pelos chats 01, 02, 03, 04 e futuros chats.
- Consolidar mudancas importantes em MEMORIA_PROJETO.md.
- Atualizar HANDOFF_CONTINUACAO.md com o estado operacional mais recente.
- Atualizar HANDOFF_CHATS_01_04.md quando houver nova frente, mudanca de escopo, risco entre frentes ou novo protocolo.
- Apontar conflitos entre WhatsApp/Quepasa, Agentes de IA/n8n, Style/UI, Kanban CRM e novas features.
- Garantir que docs_referencia, Whaticket, Planka, Swagger do Quepasa e outras bases sejam tratados apenas como referencia/inspiracao, nunca como escopo automatico.
- Preparar prompts de abertura e fechamento para novos chats quando necessario.

Fora de escopo:
- Nao implemente features sem eu pedir explicitamente.
- Nao faca deploy sem eu pedir explicitamente.
- Nao execute git push sem eu pedir explicitamente.
- Nao altere codigo de produto, exceto se eu pedir uma correcao pequena nos documentos ou no proprio sistema de handoff.
- Nao sobrescreva alteracoes locais.

Regras:
- Sempre seguir primeiro o escopo e arquitetura do UnicoCRM atual.
- Se algum handoff mencionar mudanca em arquivo compartilhado, registre qual frente foi impactada.
- Se algum chat mexer em WhatsApp/Quepasa, avisar impacto para Chat 01.
- Se algum chat mexer em tools/payload/logs de IA, avisar impacto para Chat 02.
- Se algum chat mexer em SCSS, tema, sidebar ou telas compartilhadas, avisar impacto para Chat 03.
- Se algum chat mexer em Kanban, pipeline, cards, atividades ou sync de mensagens, avisar impacto para Chat 04.
- Ao revisar um handoff, diga se ele esta completo ou quais campos faltam.

Sua primeira tarefa:
1. Leia os tres documentos obrigatorios.
2. Rode git status --short.
3. Me entregue um resumo curto do estado atual por frente:
   - 00 Orquestracao
   - 01 WhatsApp API nativo
   - 02 Agentes de IA e n8n
   - 03 Style e UI
   - 04 Kanban CRM
4. Liste riscos de conflito entre frentes.
5. Liste quais documentos devem ser atualizados antes de abrir os demais chats.
6. Nao edite nada ainda, a menos que seja claramente necessario para corrigir o proprio handoff.
```

## Chat 01 - 01 refactor: WhatsApp API nativo

Missao:

- Manter o Quepasa como conector nativo WhatsApp API dentro do UnicoCRM.
- Garantir criacao de inbox, QR Code, status conectado, toggles, webhooks, midias, grupos, contatos, envio/recebimento e exclusao do bot.
- Corrigir bugs de mensageria sem quebrar as features CRM.

Memoria essencial:

- A opcao `WhatsApp API` ja aparece na criacao de caixa.
- Existe aba `WhatsApp API` nas configuracoes da inbox.
- O bot Quepasa deve ser criado automaticamente.
- O QR Code deve sumir quando conectado.
- Toggles devem aplicar no Quepasa sem chamar fluxo errado de criacao/validacao de usuario.
- `.vcf` e eventos internos/contatos nao devem virar conversa indevida.
- Midias sem texto real nao devem ganhar legenda generica `Audio`, `Foto` ou `Video`.
- Ao excluir inbox Quepasa, excluir o bot correspondente.

Estado atual conhecido:

- Ultima correcao separou chamadas administrativas das chamadas normais do bot.
- `update_settings!` deve usar apenas `PATCH /info`.
- Chamadas normais do bot devem usar `X-QUEPASA-TOKEN`.
- Master key, usuario e senha ficam reservados para criacao/setup.
- Validacao pendente: Thiago testar toggles da inbox 13.

Arquivos sensiveis:

- `app/services/whatsapp/quepasa/client.rb`
- `app/services/whatsapp/providers/quepasa_service.rb`
- `app/controllers/webhooks/quepasa_controller.rb`
- Frontend de inbox WhatsApp API.
- Listeners/jobs que mexam em mensagem, conversa ou webhook.

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
01 refactor: WhatsApp API nativo

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade e criar, corrigir e proteger a feature WhatsApp API nativo / Quepasa.

Contexto critico:
- O conector Quepasa ja existe e nao pode ser quebrado.
- A ultima correcao separou chamadas administrativas das chamadas normais do bot.
- update_settings! deve usar PATCH /info sem recriar usuario/bot.
- Chamadas normais usam X-QUEPASA-TOKEN.
- O ultimo ponto pendente era validar os toggles da inbox 13.

Regras:
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Nao execute git push sem eu pedir.
- Se mexer em IA, Style ou Kanban, registre impacto no handoff.
- Use `docs_referencia` apenas como referencia. Nao copie escopo/arquitetura de Whaticket, Planka ou outras bases se isso nao for necessario para o UnicoCRM atual.
- Ao terminar, atualize MEMORIA_PROJETO.md, HANDOFF_CONTINUACAO.md e, se necessario, HANDOFF_CHATS_01_04.md.
```

## Chat 02 - Agentes de IA e n8n

Missao:

- Evoluir a feature `Agentes de IA`.
- Manter produtos como entidades do CRM consultadas pelo agente.
- Validar e melhorar a ponte com n8n.
- Garantir logs, playground e tools nativas.

Memoria essencial:

- Usa a feature flag existente `crm`.
- Rota frontend: `/app/accounts/:accountId/crm/ai-agents`.
- Agente consulta produtos vinculados, mas produtos nao pertencem exclusivamente ao agente.
- n8n e o executor inicial.
- Banco do UnicoCRM e a fonte de verdade.
- Listener dispara apenas mensagens `incoming`, publicas e vinculadas a inbox com agente ativo para evitar loop.
- Payload n8n usa `schema_version: v1`.
- `session_id`: `account:<account_id>:conversation:<conversation_id>`.
- Produtos/FAQs nao devem ir em massa no payload; n8n deve consultar tools.

Estado atual conhecido:

- Tela de agentes existe, salva configuracoes e foi redesenhada com experiencia estilo Intercom/Linear.
- Playground chama endpoint real; usa OpenAI quando `OPENAI_API_KEY` estiver na stack e fallback local quando nao estiver.
- Produtos CRM foram expandidos com FAQs e objecoes estruturadas como pergunta/resposta em `metadata`.
- Midias de apoio de produto suportam links estruturados e upload de imagem/video/audio via ActiveStorage.
- Products controller e UI foram expandidos.
- Existem tools nativas para produtos, FAQs e Kanban.
- Tools de Kanban expostas para IA incluem busca/atualizacao de cards e criacao de atividades.
- Payload n8n inclui `session_id` e `message_id` no topo; `message.id` continua existindo.
- Em 2026-05-09, a busca nativa `Crm::AiAgents::ProductSearch` foi corrigida para usar 5 resultados por padrao quando `limit` nao for enviado nas tools.
- Ultimo deploy da frente IA/n8n colocou em producao a digest `sha256:789d88bf4f94a64d8d72d422c96692a90c63245f675fb23bc396cebe59f23d16`.
- Falta validar com uma mensagem real se mensagens incoming disparam n8n, se `{{$json.body.message_id}}` chega corretamente e se `crm_ai_agent_execution_logs` grava request/response.

Arquivos sensiveis:

- `app/controllers/api/v1/accounts/crm/ai_agents_controller.rb`
- `app/controllers/api/v1/accounts/crm/products_controller.rb`
- `app/controllers/api/v1/accounts/crm/ai_agent_tools_controller.rb`
- `app/jobs/crm/ai_agent_execution_job.rb`
- `app/listeners/crm/ai_agent_listener.rb`
- `app/services/crm/ai_agents/`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/api/crm/aiAgents.js`
- `app/javascript/dashboard/api/crm/products.js`

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
02 - Agentes de IA e n8n

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade e criar/atualizar a feature Agentes de IA, incluindo produtos CRM, tools nativas, playground, logs e executor n8n.

Contexto critico:
- Use a feature flag crm, nao crie nova flag que estoure bitset.
- Produtos sao do CRM e vinculados ao agente.
- n8n deve receber payload leve e consultar tools sob demanda.
- Disparar apenas mensagens incoming para evitar loop.
- Nao altere provider Quepasa ou fluxo de webhook WhatsApp sem registrar impacto para o Chat 01.

Regras:
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Nao execute git push sem eu pedir.
- Ao terminar, atualize MEMORIA_PROJETO.md, HANDOFF_CONTINUACAO.md e, se necessario, HANDOFF_CHATS_01_04.md.
- Use `docs_referencia` apenas como referencia. Nao copie escopo/arquitetura de Whaticket, Planka ou outras bases se isso nao for necessario para o UnicoCRM atual.
```

## Chat 03 - Style e UI

Missao:

- Criar/atualizar o style do UnicoCRM.
- Padronizar tema, cores, sidebar, telas CRM e acabamento visual.
- Melhorar experiencia frontend sem alterar regra de negocio.

Memoria essencial:

- O UnicoCRM esta deixando de parecer Chatwoot puro e ganhando identidade CRM.
- A sidebar ja exibe itens CRM quando `FEATURE_FLAGS.CRM` esta ativa.
- `Agentes de IA` substitui Captain quando CRM esta ativo; Captain fica como fallback.
- Kanban e IA precisam de UI consistente entre si.
- Evitar quebrar responsividade, contraste, legibilidade e estados interativos.

Estado atual conhecido:

- Em 2026-05-09 foi aplicada revisao visual/responsiva nas telas CRM, inspirada na sensacao de SaaS limpo como Twenty, sem analisar/copiar o projeto de `docs_referencia`.
- Ha alteracoes locais em SCSS, tema, sidebar e telas CRM.
- A tela de `Agentes de IA` recebeu shell responsivo, playground adaptavel e tabs/listas melhores para notebook/iPad.
- A tela de Kanban recebeu metricas compactas, board responsivo, colunas fluidas, cards com hover/foco e painel lateral empilhavel em telas menores.
- Refinamento adicional da frente Style/UI:
  - reforcou hierarquia visual e respiro dos cards CRM;
  - ajustou dark mode para fundo neutro e cards/superficies mais claros;
  - melhorou o formulario de Produtos com labels uppercase, grid alinhado e input group de preco;
  - reduziu a percepcao de lentidao no drag/drop do Kanban com atualizacao otimista na UI;
  - manteve contratos de API, models, migrations, jobs e providers fora do escopo.
- Revisao ampla de identidade visual CRM inspirada no `docs_referencia/Exemplo leyout`:
  - adotou accent laranja `#FF5B25`, superficies dark SaaS mais organizadas e cards com raio 12px/bordas finas;
  - alinhou sidebar, tokens globais, botoes primarios, formularios e hierarquia tipografica;
  - refinou visualmente Agentes/Produtos, Kanban e Estoque sem alterar contratos de API, services, jobs, migrations ou providers;
  - preservou chips verdes/teal para estados positivos de estoque/status, usando laranja apenas como cor de navegacao/acao.
  - validacao/deploy: `git diff --check` passou; build Docker passou; push publicou `sha256:e694c939d954c321219816900c7a766bbfc0839e30558ea1ec5504fe052d7105`; Portainer concluiu update de `app` e `sidekiq`; health publico respondeu HTTP `200`.
- Refatoracao visual Linear/Shadcn em 2026-05-10:
  - reduziu a identidade para superficies minimalistas, sem gradientes/radiais/sombras fortes;
  - manteve o laranja `#FF5B25` como accent de botoes primarios, ativo de menu, icones e foco;
  - alinhou dark mode a fundo `hsl(220 15% 8%)`, cards `hsl(220 15% 11%)`, bordas discretas e sidebar `hsl(220 15% 6%)`;
  - aplicou botoes de 40px, radius 12px, inputs com ring laranja e containers max-width nas telas de configuracao;
  - manteve o Kanban produtivo, mas com colunas/cards mais limpos no estilo Linear;
  - escopo foi visual: CSS/SCSS/tokens/classes de layout, sem alteracao intencional em API, model, controller, migration, job ou service;
  - validacao/deploy: `git diff --check` passou; build Docker passou; push publicou `sha256:68f3f1f2e34f6cf7691084c981f3c47c1becdfe2cd10ab35255be58854d4456a`; Portainer concluiu update de `app` e `sidekiq`; health publico respondeu HTTP `200`.
- Ajuste visual Kanban em 2026-05-10:
  - controles manuais `Parado apos` e `Chance` foram movidos do topo das colunas para o painel `Etapas`;
  - exclusao de etapa saiu do icone de lixeira visivel nas colunas e ficou no mesmo painel `Etapas`;
  - `Excluir funil` foi movido para dentro de `Configurar funil`;
  - nenhuma regra de negocio foi alterada: os campos continuam manuais e usam os mesmos metodos/contratos;
  - validacao/deploy: `git diff --check` passou; build Docker passou; push publicou `sha256:d16499366903b5411b5e321cb77f657c04b4ffb0d7887986aaaf9d8fca079dc8`; Portainer concluiu update de `app` e `sidekiq`; health publico respondeu HTTP `200`.
- Ajuste de metricas Kanban em 2026-05-10:
  - metricas do board ficaram ocultas por padrao e podem ser abertas pelo botao `Metricas`, que tambem mostra o total de cards ativos;
  - titulo editavel das colunas deixou de exibir fundo preto de input, ficando apenas como texto;
  - mudanca visual apenas em `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`, sem alterar API, models, services, jobs, controllers ou migrations;
  - validacao/deploy: `git diff --check` passou; build Docker passou; push publicou `sha256:8b3f17fd27ae5a4dd9f9dc1f3922d966af2a5412973ac0efcd4f1cec9f14cc6c`; Portainer aceitou redeploy; health publico respondeu HTTP `200`; leitura final de status do Portainer falhou por TLS intermitente.
- Primeira rodada `03 - Style e UI / Identidade Visual SaaS` em 2026-05-11:
  - Patagon usado para decidir uma fundacao SaaS operacional inspirada em Linear/Twenty/HubSpot/Intercom, sem copiar arquitetura, fluxo ou estetica externa de forma cega;
  - problemas principais: Agentes de IA, Estoque e Kanban tinham padroes locais divergentes de fonte, tamanho, peso, cards, inputs, radius, metricas, botoes e estados;
  - `_woot.scss` ganhou uma camada visual comum restrita a paginas/classes `crm-*`, padronizando tipografia, cards, inputs, botoes, chips, foco e superficies;
  - `_next-colors.scss` teve ajuste leve no dark mode para fundo mais profundo e melhor separacao das superficies;
  - `Sidebar.vue` foi refinado visualmente na busca, botao de composicao e altura dos itens, sem mudar rotas, permissoes ou comportamento;
  - validacao inicial: `git diff --check` passou; build Docker de verificacao `unicocrm-style-check` passou;
  - publicacao/deploy apos pedido explicito do Thiago: commit `657d5f1 style(crm): add SaaS visual foundation` foi enviado para `origin/main`; build Docker de `delvechiotech/unicocrm:latest` passou; push Docker publicou `sha256:c756030a16aa98be58d6aba73414e78af2bc553f76cabae0bca3f960be6a4704`; Portainer concluiu update de `app` e `sidekiq`; health publico respondeu HTTP `200`.
- Apos a instrucao permanente de fazer build/push/deploy ao terminar etapa, o build Docker local passou; depois de confirmacao explicita do Thiago, o push Docker tambem passou e o redeploy Portainer foi executado. `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` retornaram update `completed` no digest `sha256:3e79f75b2518301222e297311d50da3655ea7976fa90c3cb72edf10f76e5f4c2`; health check publico local ficou inconclusivo por falhas de conexao HTTPS/intermitencia.
- Build/push/deploy da frente Style/UI publicou `delvechiotech/unicocrm:latest@sha256:92af187b6874228fd4d3e17c585dd28dbc6da1a91b9e5e23775120c39dcd0d7f`.
- Portainer stack `chatwoot` atualizou `app` e `sidekiq`; health check final em `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Houve `502` temporario durante boot do app, resolvido apos Puma subir.
- Validacao visual manual desktop/notebook/iPad ainda e recomendada.
- O style deve respeitar componentes existentes do Chatwoot para reduzir regressao.

Arquivos sensiveis:

- `app/javascript/dashboard/assets/scss/_base.scss`
- `app/javascript/dashboard/assets/scss/_next-colors.scss`
- `app/javascript/dashboard/assets/scss/_woot.scss`
- `theme/colors.js`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`
- Componentes compartilhados usados por CRM.

Regra especial:

- Este chat pode tocar telas de IA e Kanban por visual, mas deve evitar mudar contratos de API, models, migrations, jobs ou services.
- Se uma melhoria visual exigir mudanca de dados/API, registrar para o chat dono da feature.

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
03 - Style e UI

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade e criar/atualizar o style do UnicoCRM: tema, cores, sidebar, consistencia visual, responsividade e acabamento das telas CRM.

Contexto critico:
- Nao altere regra de negocio, migrations, jobs ou providers.
- Pode refinar visual de Agentes de IA e Kanban, mas sem quebrar contratos.
- Preserve padroes existentes do Chatwoot quando isso reduzir risco.
- Se precisar de dado/API novo, registre pendencia para o chat dono da feature.

Regras:
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Nao execute git push sem eu pedir.
- Ao terminar, atualize MEMORIA_PROJETO.md, HANDOFF_CONTINUACAO.md e, se necessario, HANDOFF_CHATS_01_04.md.
- Use `docs_referencia` apenas como referencia. Nao copie escopo/arquitetura de Whaticket, Planka ou outras bases se isso nao for necessario para o UnicoCRM atual.
```

## Chat 04 - Kanban CRM

Missao:

- Criar/atualizar o Kanban nativo do CRM.
- Evoluir pipelines, etapas, cards, agenda, linha do tempo, webhooks e automacoes.
- Integrar Kanban com conversas e tools de IA sem quebrar mensageria.

Memoria essencial:

- Usa a feature flag existente `crm`.
- Rota frontend: `/app/accounts/:accountId/crm/kanban`.
- Tabelas proprias:
  - `crm_kanban_pipelines`
  - `crm_kanban_stages`
  - `crm_kanban_cards`
  - `crm_kanban_actions`
  - `crm_kanban_activities`
  - `crm_kanban_webhooks`
- Pipeline padrao: `Pipeline comercial`.
- Etapas padrao: `Novos leads`, `Qualificacao`, `Proposta enviada`, `Negociacao`, `Ganhou`, `Perdido`.
- Cards podem vincular contato, conversa, produto, orcamento, resumo, notas, status e responsavel.
- Exclusao na UI deve arquivar card para preservar historico.
- Automacao deve criar/atualizar cards a partir de mensagens recebidas, sem depender de agente IA ativo.

Estado atual conhecido:

- Kanban nativo esta implementado e deployado em producao.
- Ultimo deploy conhecido desta frente: `delvechiotech/unicocrm:latest@sha256:c573fde235b25b70380cb98a13ce77643f569636452011c802859978c6ca4414`.
- Build Docker, push Docker e redeploy Portainer foram feitos; `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Ainda falta validacao funcional em conta real para sync automatico por mensagem, atividades, webhooks e regras de IA.
- Tools de IA incluem busca/atualizacao de cards e criacao de atividades.
- Etiquetas nativas do Chatwoot nao sao a base do Kanban; usar futuramente como camada auxiliar para exibir, filtrar e automatizar.
- Em 2026-05-09, o visual do Kanban foi refinado com inspiracao conceitual em Planka + Whaticket: colunas com acentos coloridos por etapa, cards com avatar/inicial de cliente, conversa destacada, chips compactos, metricas com icones e painel lateral mais proximo do atendimento comercial.
- A UI passou a chamar a remocao de card de `Arquivar`, mantendo o contrato de preservar historico.
- Essa rodada visual nao alterou APIs, models, jobs, migrations, sync de mensagem, webhooks ou tools de IA.
- `docs_referencia` nao estava presente neste checkout; Planka e Whaticket foram usados apenas como referencia visual/UX, sem copiar codigo.
- Validacao/deploy da rodada visual Kanban:
  - `git diff --check` passou;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou e gerou manifest list local `sha256:e38da08d1b0e3f84451b69cd88a865f69658d17f9f33608b37a16c9a63b20695`;
  - `docker push delvechiotech/unicocrm:latest` foi bloqueado pela politica do ambiente por exportacao externa para Docker Hub, mesmo apos confirmacao explicita do Thiago;
  - redeploy Portainer nao foi executado nesta rodada;
  - commit local depois atualizado para `95385d1 Implement native CRM kanban and AI tools`;
  - apos autorizacao explicita do Thiago, `git push origin main` passou e publicou `95385d1` em `origin/main`.
- Segunda passada visual apos screenshot:
  - cabecalho, metricas, colunas e painel lateral foram compactados;
  - dark mode local do Kanban ficou menos pesado e os inputs/chips menos verdes;
  - `docker build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou com manifest list local `sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - `docker push delvechiotech/unicocrm:latest` foi inicialmente bloqueado pela politica do ambiente por exportacao externa para Docker Hub;
  - Thiago executou o push da imagem fora do ambiente bloqueado;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:a5daeef4e0ddd209035d2b50d69daa072ea5c656f0bea8289e296befd4058a86`;
  - houve `502` temporario durante boot, resolvido apos aguardar; `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.
- Ajuste posterior do Kanban:
  - painel lateral fica fechado por padrao, abre por `Novo card`, `Adicionar nesta etapa` ou clique em card, e fecha apos salvar/arquivar;
  - inputs do Kanban receberam fundo local mais escuro/suave para evitar campos brancos no dark mode;
  - build Docker passou com manifest list local `sha256:82adb17f73679caf8447417fde30d256fa6640620d2107fd8f25f08502f4789b`;
  - Docker push foi bloqueado pela politica do ambiente, o push foi feito fora do ambiente bloqueado;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` ficaram com update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:82adb17f73679caf8447417fde30d256fa6640620d2107fd8f25f08502f4789b`;
  - `https://chat.unicocrm.com/` respondeu HTTP `200 OK` apos o deploy.
- Rodada atual de controle de funis/etapas:
  - API/UI do Kanban agora suportam selecionar, criar, editar e excluir funis vazios;
  - o funil padrao nao pode ser excluido e funis/etapas com cards sao bloqueados para preservar historico;
  - etapas podem ser criadas, renomeadas, configuradas e excluidas quando vazias;
  - campos `Parado apos` e `Chance` foram redesenhados para corrigir truncamento e proporcao;
  - operacoes de card, atividade, webhook e drag/drop enviam `pipeline_id` selecionado;
  - nao houve alteracao em Quepasa, sync automatico de mensagens, payload n8n ou tools de IA;
  - build Docker passou e `delvechiotech/unicocrm:latest` foi publicado com digest `sha256:c573fde235b25b70380cb98a13ce77643f569636452011c802859978c6ca4414`;
  - commit `2565f88` foi enviado para `main`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - tasks da stack passaram a rodar a digest nova e `https://chat.unicocrm.com/` respondeu HTTP `200 OK`.

Arquivos sensiveis:

- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`
- `app/javascript/dashboard/api/crm/kanban.js`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/`
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
- `db/migrate/20260508140000_create_crm_kanban_tables.rb`
- `db/migrate/20260508153000_extend_crm_kanban_automation.rb`

Regra especial:

- Se mexer no listener de mensagens para sincronizar Kanban, registrar impacto para Chat 01 porque encosta no fluxo de mensageria.
- Se alterar tools consumidas pelo agente, registrar impacto para Chat 02.
- Se integrar etiquetas nativas ao Kanban, manter etiquetas como camada auxiliar, nao como substituto das tabelas de pipeline/card.

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
04 - Kanban CRM

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade e criar/atualizar o Kanban nativo do CRM: pipelines, etapas, cards, atividades, linha do tempo, webhooks, sync automatico e tools de IA relacionadas.

Contexto critico:
- Kanban nativo ja foi implementado e deployado; antes de mudar, revise estado real, diffs e pendencias de validacao funcional.
- Use tabelas proprias de CRM, nao labels/conversas como substituto.
- Etiquetas nativas podem ser integradas como camada auxiliar, nao como base do pipeline.
- Excluir card na UI deve arquivar, nao apagar historico.
- Automacao de mensagens deve criar/atualizar cards sem depender de agente IA ativo.
- Se mexer no fluxo de mensagens/Quepasa, registre impacto para o Chat 01.
- Se alterar tools consumidas por agente IA, registre impacto para o Chat 02.

Regras:
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Nao execute git push sem eu pedir.
- Ao terminar, atualize MEMORIA_PROJETO.md, HANDOFF_CONTINUACAO.md e, se necessario, HANDOFF_CHATS_01_04.md.
- Use `docs_referencia` apenas como referencia. Nao copie escopo/arquitetura de Whaticket, Planka ou outras bases se isso nao for necessario para o UnicoCRM atual.
```

## Chat 05 - Estoque

Missao:

- Planejar e implementar Estoque/Produtos Comerciais no UnicoCRM.
- Respeitar `crm_products` como base atual de produtos ja usada por Agentes de IA e Kanban.
- Controlar disponibilidade, quantidade, SKU, preco, categoria, midias e status comercial sem criar fonte de verdade duplicada.
- Integrar disponibilidade com tools de IA e oportunidades/propostas do Kanban.

Memoria essencial:

- `crm_products` ja existe e pertence a conta.
- Campos atuais: nome, SKU, categoria, moeda, preco, ativo, descricao, FAQ, objecoes, notas de midia e `metadata` JSONB.
- Produtos ja tem anexos via ActiveStorage (`media_files`).
- Produtos sao vinculados a Agentes de IA por `crm_ai_agent_products`.
- Produtos sao vinculaveis a cards do Kanban por `crm_kanban_cards.product_id`.
- Tools de IA ja consultam produtos ativos vinculados ao agente.
- O payload n8n instrui a IA a nao presumir preco, disponibilidade ou politicas que nao venham das tools.

Estado atual conhecido:

- Frente iniciada em 2026-05-09.
- `git status --short` estava limpo no inicio.
- A primeira etapa fez diagnostico e planejamento.
- Recomendacao tecnica inicial aceita: Estoque evolui `crm_products`; se houver controle transacional futuro, criar tabelas relacionadas para movimentos/reservas em vez de duplicar produtos.
- Implementacao inicial aplicada:
  - `crm_products` ganhou campos de disponibilidade, quantidade, reservado, alerta de baixo estoque e controle de inventario;
  - Products API e `Crm::Product` expõem indicadores derivados de estoque;
  - sidebar ganhou item `Estoque`;
  - rota `/app/accounts/:accountId/crm/inventory` ganhou tela propria de Estoque;
  - tela Agentes/Produtos tambem edita os novos campos;
  - tools/payload de IA passam a carregar disponibilidade e instrucoes contra invencao de estoque;
  - Kanban exibe disponibilidade do produto no card.
- Validacoes executadas:
  - `git diff --check` passou;
  - `node --check` passou nos arquivos JS aplicaveis;
  - `docker image build -f docker/Dockerfile -t unicocrm-inventory-check .` passou com manifest list local `sha256:371821deb1cd78386b3ab7bcbdb1a8e96270f199469d1b3765b3fd0b9f4236f9`.
- Build/push/deploy executados apos pedido explicito do Thiago:
  - `docker image build -f docker/Dockerfile -t delvechiotech/unicocrm:latest .` passou;
  - `docker image push delvechiotech/unicocrm:latest` publicou digest `sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`;
  - Portainer stack `chatwoot` foi atualizada com `PullImage=true`;
  - `chatwoot_chatwoot_app` e `chatwoot_chatwoot_sidekiq` retornaram update `completed` apontando para `delvechiotech/unicocrm:latest@sha256:fdd660a0e47a8a131ac8fff7531fb88d2f6a6b70c71aed347f7da464c9b579b4`;
  - `https://chat.unicocrm.com` respondeu HTTP `200 OK` via Node/OpenSSL;
  - `https://chat.unicocrm.com/health` respondeu HTTP `200 OK` com `{"status":"woot"}`.
- Nao houve commit ou git push nesta etapa.

Arquivos sensiveis:

- `app/models/crm/product.rb`
- `app/controllers/api/v1/accounts/crm/products_controller.rb`
- `app/services/crm/ai_agents/product_search.rb`
- `app/controllers/api/v1/accounts/crm/ai_agent_tools_controller.rb`
- `app/javascript/dashboard/api/crm/products.js`
- `app/javascript/dashboard/routes/dashboard/crm/aiAgents/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/inventory/Index.vue`
- `app/javascript/dashboard/routes/dashboard/crm/crm.routes.js`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/kanban/Index.vue`
- `app/controllers/api/v1/accounts/crm/kanban_controller.rb`
- migrations futuras relacionadas a `crm_products`, movimentos ou reservas de estoque.
- `app/services/crm/ai_agents/payload_builder.rb`

Regra especial:

- Se alterar tools/payloads de produto consumidos por IA/n8n, registrar impacto para Chat 02.
- Se alterar layout da tela de Agentes/Produtos ou estilos compartilhados, registrar impacto para Chat 03.
- Se alterar cards, propostas, reservas ou exibicao de produto no Kanban, registrar impacto para Chat 04.
- Nao alterar Quepasa/WhatsApp, provider de mensagens ou webhooks de mensageria.

PROMPT DE ABERTURA:

```text
Nome deste chat/frente:
05 - Estoque

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade e planejar/criar a feature de Estoque dentro do UnicoCRM.

Contexto critico:
- Este projeto e o UnicoCRM, baseado em Chatwoot customizado.
- Produtos ja existem em `crm_products` e sao usados por Agentes de IA e Kanban.
- Estoque deve respeitar essa base atual e evitar criar uma entidade duplicada sem necessidade.
- Use `crm_products` como fonte principal de produto comercial, adicionando tabelas relacionadas apenas quando houver necessidade real de historico, movimentos ou reservas.

Escopo permitido:
- Entender/evoluir `crm_products`.
- Modelar disponibilidade, quantidade, SKU, preco, categoria, midias e status.
- Planejar/implementar integracao com tools de Agentes de IA para consulta de disponibilidade.
- Planejar/implementar integracao com Kanban para oportunidades/propostas.
- Criar/alterar controllers, models, services, migrations e UI depois de revisar o estado atual.

Fora de escopo:
- Nao alterar Quepasa/WhatsApp.
- Nao alterar provider de mensagens.
- Nao mexer em Style/UI global sem registrar impacto para Chat 03.
- Nao mexer em Kanban alem dos pontos necessarios de integracao, sem registrar impacto para Chat 04.
- Nao mexer em payload/tools de IA sem registrar impacto para Chat 02.
- Nao executar deploy, commit ou git push sem pedido explicito.

Regras:
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Ao terminar, atualize MEMORIA_PROJETO.md, HANDOFF_CONTINUACAO.md e HANDOFF_CHATS_01_04.md.
- Use `docs_referencia` apenas como referencia. Nao copie escopo/arquitetura externa se isso nao for necessario para o UnicoCRM atual.
```

## Modelo para nova feature ou novo escopo

Use esta secao quando o Thiago criar uma frente nova que nao seja WhatsApp, IA, Style ou Kanban. Exemplo: relatorios, financeiro, automacoes comerciais, permissoes, mobile, marketplace, integracoes externas.

Primeiro, adicione a nova frente na tabela `Divisao dos chats` com:

- Numero do chat.
- Nome recomendado.
- Responsabilidade principal.
- Onde pode mexer.
- O que deve evitar.

Depois, cole este prompt no inicio do novo chat:

```text
PROMPT DE ABERTURA - NOVA FEATURE / NOVO ESCOPO

Nome deste chat/frente:
[NN - Nome da feature ou escopo]

Estou continuando o projeto UnicoCRM no workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de fazer qualquer coisa, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Sua responsabilidade:
[Descreva exatamente o que esta frente deve criar/atualizar/corrigir.]

Escopo permitido:
[Liste arquivos, modulos, telas, APIs, models, jobs, services ou docs que esta frente pode tocar.]

Fora de escopo:
[Liste o que este chat deve evitar. Exemplo: nao mexer em Quepasa, nao alterar IA, nao mudar Kanban, nao fazer deploy.]

Contexto critico:
- Este projeto e o UnicoCRM, baseado em Chatwoot customizado.
- Nao execute git push sem eu pedir explicitamente.
- Rode git status --short antes de editar.
- Revise diffs dos arquivos que pretende tocar.
- Nao sobrescreva alteracoes locais.
- Use `docs_referencia` apenas como referencia. Siga sempre o escopo do UnicoCRM atual e adapte ideias externas somente quando forem realmente necessarias.
- Se sua mudanca afetar WhatsApp/Quepasa, IA/n8n, Style/UI ou Kanban, registre impacto para a frente correspondente.

Tarefa inicial:
1. Leia os documentos obrigatorios.
2. Rode git status --short.
3. Me diga se encontrou risco de conflito com outra frente.
4. Continue a implementacao apenas dentro deste escopo.

Ao terminar:
- Atualize MEMORIA_PROJETO.md.
- Atualize HANDOFF_CONTINUACAO.md.
- Atualize HANDOFF_CHATS_01_04.md adicionando ou ajustando esta nova frente.
- Responda usando o PROMPT DE FECHAMENTO universal deste documento.
```

No final do novo chat, cole o `PROMPT DE FECHAMENTO` universal.

## Prompt curto para voltar ao chat atual

Use este prompt quando retornar ao chat original:

```text
Voltei para o chat atual do projeto UnicoCRM.

Antes de continuar, leia:
- MEMORIA_PROJETO.md
- HANDOFF_CONTINUACAO.md
- HANDOFF_CHATS_01_04.md

Depois rode git status --short e me diga:
1. O que mudou desde o ultimo handoff.
2. Quais chats/frentes foram atualizados.
3. Quais arquivos compartilhados foram tocados.
4. O que esta pendente por frente.
5. Se existe risco de conflito entre WhatsApp, IA, Style e Kanban.

Nao edite nada ate entender o estado atual.
```
