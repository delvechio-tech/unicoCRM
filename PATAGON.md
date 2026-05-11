# Patagon - Benchmarking e Analise Comparativa

Patagon e o gate obrigatorio antes de qualquer nova feature, refatoracao relevante ou mudanca de arquitetura do UnicoCRM.

Objetivo: garantir que o projeto evolua como CRM robusto baseado no Chatwoot, usando referencias de mercado sem copiar cegamente Salesforce, HubSpot, Pipedrive, Intercom, Zendesk, Twenty, Whaticket, Planka ou qualquer outra base.

## Quando usar

Use Patagon antes de:

- criar feature nova;
- refatorar fluxo existente;
- alterar contrato de API, payload, tool, webhook ou modelagem;
- mudar tela CRM com impacto operacional;
- mexer em performance, background jobs, listeners ou sincronizacoes;
- integrar IA, n8n, Kanban, Estoque, Quepasa ou funis comerciais.

Mudancas triviais de texto, handoff ou ajuste visual muito pequeno podem registrar apenas "Patagon: nao aplicavel" com justificativa curta.

## Gate obrigatorio

Antes de implementar, responder:

1. Benchmark de mercado:
   - Como Salesforce, HubSpot, Pipedrive, Intercom/Zendesk ou outro produto comparavel resolvem este problema?
   - O que vale adaptar para o UnicoCRM?
   - O que nao devemos copiar porque aumentaria custo, complexidade ou friccao?

2. Comparacao com Chatwoot original:
   - O que o Chatwoot ja resolve bem?
   - A mudanca preserva inbox, conversas, contatos, permissoes e extensoes Enterprise?
   - A feature fica acoplada demais ao Chatwoot ou cria um modulo CRM claro?

3. Arquitetura proposta:
   - Qual e a fonte de verdade dos dados?
   - Existem contratos afetados: API, payload n8n, tools de IA, webhook, migrations, jobs?
   - A solucao evita duplicar entidades existentes?
   - A fronteira entre frentes esta clara?

4. Performance e escala:
   - A mudanca adiciona queries em loop, payload pesado, job duplicado ou listener perigoso?
   - Precisa de indice, paginacao, limite padrao, cache ou job async?
   - O novo codigo mantem ou melhora a performance esperada em relacao ao fluxo original?

5. Riscos e mitigacoes:
   - O que pode quebrar em Quepasa, IA/n8n, Kanban, Estoque, Style/UI ou Enterprise?
   - Como validar antes de deploy?
   - Qual rollback seria possivel se algo falhar?

6. Decisao:
   - Executar como proposto;
   - Simplificar antes de executar;
   - Dividir em fases;
   - Bloquear ate esclarecer requisito.

## Saida esperada

Cada feature/refatoracao deve deixar um bloco curto no plano, handoff ou resposta final:

```text
Patagon:
- Benchmark: ...
- Decisao arquitetural: ...
- Performance/escala: ...
- Riscos: ...
- Resultado: executar/simplificar/dividir/bloquear.
```

## Relacao com GSD e GitNexus

- GSD organiza fases, handoffs, escopo e execucao.
- GitNexus analisa codigo, dependencias, impacto e fluxos.
- Patagon critica produto, mercado, arquitetura e escala antes da execucao.

Ordem recomendada para features relevantes:

```text
GSD status -> GitNexus impacto/contexto -> Patagon gate -> implementacao -> validacao -> handoff
```

## Regra permanente

Nao copiar referencia externa por aparencia ou hype. Adaptar apenas o que melhora o UnicoCRM dentro do seu contexto: Chatwoot customizado, CRM operacional, WhatsApp/Quepasa, IA/n8n, Kanban, Estoque e atendimento comercial real.
