# Prompt para Continuar em Nova Conta

Use este prompt como primeira mensagem em uma nova conta/chat.

```text
Estou continuando o projeto UnicoCRM.

Workspace:
C:\Users\thiago.delvechio_v4c\Desktop\Chatwoot CRM - Codex\Chatwoot-custom-develop

Antes de editar qualquer coisa, leia nesta ordem:
1. MEMORIA_PROJETO.md
2. HANDOFF_CONTINUACAO.md
3. HANDOFF_CHATS_01_04.md
4. PATAGON.md
5. AGENTS.md

Depois rode:
git status --short

Contexto essencial:
- O UnicoCRM e um Chatwoot Enterprise customizado.
- Existem frentes separadas:
  - 01 WhatsApp API / Quepasa
  - 02 Agentes de IA / n8n
  - 03 Style / UI
  - 04 Kanban CRM
  - 05 Estoque / Produtos Comerciais
- GSD organiza escopo, handoff e execucao.
- GitNexus deve ser usado para entender impacto tecnico antes de mudancas sensiveis.
- Patagon e obrigatorio antes de feature nova, refatoracao relevante ou mudanca de API/payload/tool/webhook/modelagem.
- Nao execute git push sem pedido explicito do Thiago.
- Nao sobrescreva alteracoes locais.
- Nao faca deploy enquanto outro deploy estiver em andamento.
- Nao mexa em Quepasa/WhatsApp sem ler a memoria e registrar impacto para a frente 01.
- Nao copie Salesforce, HubSpot, Whaticket, Planka ou outra referencia externa; use apenas como benchmark e adapte ao UnicoCRM.

Sua primeira resposta deve conter:
1. Estado do git status.
2. Estado atual por frente.
3. Arquivos modificados agrupados por frente.
4. Riscos de conflito.
5. Qual seria o proximo passo seguro.

Nao edite nada ate apresentar esse diagnostico inicial.
```

## Resumo de operacao

Para qualquer nova etapa:

```text
Ler memorias -> git status -> GitNexus se houver impacto tecnico -> Patagon se houver feature/refatoracao -> implementar -> validar -> atualizar handoff
```

Para deploy:

```text
confirmar deploy parado -> git status -> git diff --check -> build -> push autorizado -> Portainer -> health check -> atualizar handoff
```
