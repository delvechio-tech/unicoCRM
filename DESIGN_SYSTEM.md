# Design System UnicoCRM

Este documento e a fonte de verdade da identidade visual do UnicoCRM. Toda alteracao frontend deve le-lo antes de editar UI.

Regra central:

> Toda alteracao frontend do UnicoCRM deve seguir DESIGN_SYSTEM.md. A frente 03 - Style e UI e a fonte de verdade para identidade visual. Outras frentes podem implementar UI funcional, mas nao devem inventar novos padroes visuais sem registrar handoff para a frente 03.

## Direcao Visual

- SaaS moderno, limpo, profissional e operacional.
- Interface densa o suficiente para CRM, mas com respiro.
- Visual inspirado em disciplina de Linear, Twenty, HubSpot e Intercom, sem copiar arquitetura, telas ou fluxos.
- Dark mode bem acabado, com fundo profundo e superficies discretamente separadas.
- Evitar aparencia de landing page, excesso decorativo ou UI infantil.

## Paleta Oficial

### Accent

- Laranja UnicoCRM: `#FF5B25`.
- Uso: acao primaria, foco, item ativo, icones ativos, links principais e pequenos destaques.
- Nao usar como cor dominante de fundo em grandes areas.

### Dark Mode

- Background principal: `hsl(220 15% 6-8%)`, hoje representado por `--background-color`.
- Sidebar: `hsl(220 15% 6%)`.
- Superficie/painel: `hsl(220 15% 9-11%)`, via `--surface-1` e `--surface-2`.
- Bordas: cinza azulado discreto, via `--border-weak`.
- Texto principal: `--slate-12`.
- Texto secundario: `--slate-10` ou `--slate-11`.

### Light Mode

- Background principal: cinza muito claro neutro.
- Superficie: branco ou quase branco.
- Bordas: cinza frio discreto.
- Accent segue `#FF5B25`.

### Status

- Sucesso/disponivel: teal/green.
- Atencao/baixo estoque: amber.
- Erro/indisponivel: ruby/red.
- Informativo: blue quando nao conflitar com o accent; preferir uso pontual.
- Status nao devem competir com o laranja de acao primaria.

## Tokens De Cor

Use os tokens existentes antes de criar novos:

- `n-brand`: accent oficial.
- `n-background`: fundo da pagina.
- `n-surface-1`, `n-surface-2`: superficies.
- `n-solid-1`, `n-solid-2`, `n-solid-3`: superficies elevadas/hover.
- `n-weak`, `n-container`, `n-strong`: bordas.
- `n-slate-12`: texto principal.
- `n-slate-10`, `n-slate-11`: texto secundario.
- `n-blue-*`: familia mapeada para accent laranja no UnicoCRM.
- `n-teal-*`, `n-amber-*`, `n-ruby-*`: status.

Padrao CRM em CSS:

- `--crm-accent`: `#ff5b25`.
- `--crm-radius-sm`: `0.625rem`.
- `--crm-radius-md`: `0.75rem`.
- `--crm-space-page`: `clamp(1rem, 1.6vw, 1.5rem)`.
- `--crm-space-card`: `1.5rem`.
- `--crm-field-bg`: `rgba(var(--background-input-box))`.
- `--crm-ring`: `0 0 0 3px rgba(255, 91, 37, 0.14)`.

## Tipografia

- Fonte oficial: `Inter`.
- Nao usar fontes diferentes nas telas CRM sem decisao da frente 03.
- Letter spacing deve ser `0`; evitar tracking negativo.

Escala:

- Page title/H1: `24-30px`, `font-weight: 650`, line-height `1.15`.
- Section title/H2: `18-20px`, `font-weight: 650`, line-height `1.25`.
- Card title/H3: `16px`, `font-weight: 600`, line-height `1.4`.
- Body: `14px`, line-height `1.5`.
- Secondary/helper: `13-14px`, `--slate-10/11`.
- Label: `11px`, uppercase, `font-weight: 650`, `--slate-10`.
- Badge/chip: `11px`, `font-weight: 650`.
- Button: `14px`, `font-weight: 600-650`.

## Espacamentos

- Page padding: `clamp(1rem, 1.6vw, 1.5rem)`.
- Card padding: `24px`.
- Compact card/list item padding: `16px`.
- Form vertical gap: `24px`.
- Form field gap: `16px`.
- Toolbar/button gap: `8px`.
- Sidebar item gap: `4px`.

Evitar elementos grudados. Se a tela parecer apertada, aumentar gap antes de aumentar tamanho de fonte.

## Border Radius

- Inputs/buttons/chips de controle: `10px-12px`.
- Cards/painels: `12px`.
- Pills/chips: `999px`.
- Evitar radius acima de `16px` em CRM operacional.
- Evitar bordas quadradas em cards e inputs.

## Sombras

- Padrao: sem sombra pesada.
- Profundidade deve vir de superficie + borda.
- Sombras leves so em overlays, dropdowns e modais.
- Nao usar sombras pretas grandes em dark mode.

## Botoes

### Primario

- Altura: `40px`.
- Radius: `12px`.
- Background: `#FF5B25`.
- Texto: branco.
- Uso: salvar, criar, adicionar, executar acao principal.
- Hover: laranja levemente mais claro (`#FF6A3A`).

### Secundario

- Altura: `40px`.
- Fundo: superficie discreta.
- Borda: `--border-weak`.
- Texto: `--slate-11/12`.
- Uso: cancelar, configurar, abrir paineis, filtros.

### Destrutivo

- Evitar botao destrutivo visivel demais.
- Usar ruby/red somente para acao destrutiva real.
- Quando o contrato for arquivar, o texto deve dizer `Arquivar`, nao `Excluir`.

### Icon Buttons

- Usar icones Lucide quando disponivel.
- Tamanho recomendado: `36-40px`.
- Tooltip para icones ambiguos.

## Inputs, Selects E Textareas

- Altura padrao: `40px`.
- Radius: `10px`.
- Background: `--crm-field-bg`.
- Borda: `--border-weak`.
- Foco: borda laranja + ring `rgba(255, 91, 37, 0.14)`.
- Placeholder: `--slate-10`.
- Labels: pequenas, uppercase, acima do campo.
- Textareas: padding `12px 14px`, resize vertical quando fizer sentido.
- Inputs numericos devem ter contexto visual claro (ex.: moeda fixa, unidade `%`, `d`).

## Cards E Paineis

- Fundo: `--surface-2`.
- Borda: `--border-weak`.
- Radius: `12px`.
- Padding: `24px`.
- Sem gradiente e sem sombra pesada.
- Titulos: `16px`, semibold.
- Texto secundario: muted.
- Nao colocar cards dentro de cards, salvo lista repetida ou painel de detalhe inevitavel.

## Tabelas E Listas

- Sem zebra forte.
- Usar bordas horizontais simples.
- Padding de celula: `16px`.
- Header de tabela: texto pequeno/muted/semibold.
- Linhas com hover sutil.
- Lista operacional: item com borda, superficie e estado ativo claro.
- Empty state deve ser calmo: titulo curto, texto secundario e acao quando houver proximo passo.

## Chips, Badges E Status

- Radius: pill.
- Fonte: `11px`, semibold.
- Padding compacto.
- Status:
  - sucesso: teal/green;
  - alerta: amber;
  - erro: ruby/red;
  - informativo: slate/blue discreto.
- Nao usar chip colorido como decoracao sem significado.

## Sidebar E Navegacao

- Sidebar dark: `hsl(220 15% 6%)`.
- Itens com radius `12px`, altura minima `36px`.
- Hover: branco com baixa opacidade.
- Ativo: fundo laranja translucidado e icone/acento laranja.
- Busca: altura `36-40px`, fundo de superficie, borda discreta.
- Nao apertar icone e texto. Manter respiro lateral.
- Grupos devem manter a arquitetura do Chatwoot quando isso reduz risco.

## Estados

- Hover: superficie levemente mais clara, sem movimento chamativo.
- Focus: ring laranja padronizado.
- Active/selected: fundo laranja muito sutil + texto principal.
- Disabled: opacidade reduzida, cursor disabled, sem hover forte.
- Loading: manter dimensoes estaveis; usar texto curto ou spinner discreto.
- Empty: sem ilustracao pesada; texto claro e acao primaria quando aplicavel.
- Error: ruby/red com mensagem objetiva; nao usar vermelho em excesso.

## Responsividade

### Desktop amplo

- Evitar formularios ocupando largura total.
- Usar `max-width` em telas de configuracao.
- Kanban pode manter largura operacional horizontal.

### Notebook

- Priorizar densidade organizada.
- Evitar tres colunas apertadas; paineis laterais podem descer ou recolher.

### iPad

- Listas laterais podem virar trilhas horizontais.
- Tabs devem ser rolaveis.
- Botao e input precisam manter alvo de toque confortavel.

### Mobile

- Layout em coluna.
- Evitar tabelas largas; usar cards/listas.
- Sidebars devem virar painel/flyout.
- Nao esconder a acao primaria essencial.

## Telas CRM Operacionais

Padroes para Agentes de IA, Estoque, Kanban e proximas features CRM:

- Header com titulo claro, subtitulo muted e acoes a direita.
- Conteudo principal com superfices consistentes.
- Formularios em cards de 24px.
- Labels uppercase pequenas.
- Inputs de 40px.
- Metricas podem ser recolhidas quando poluirem o fluxo.
- Configuracoes administrativas devem ficar em paineis/configuracao, nao no caminho operacional principal.
- Kanban deve priorizar leitura de cards e movimento, nao controles tecnicos.
- Estoque deve priorizar busca/lista, status e edicao rapida.
- Agentes de IA deve priorizar configuracao clara, produtos vinculados e playground sem poluir a tela.

## O Que Evitar

- Inventar nova paleta por feature.
- Usar roxo/azul como cor dominante.
- Gradientes decorativos, radiais e bokeh/orbs.
- Sombras pesadas em dark mode.
- Cards enormes sem necessidade operacional.
- Landing-page/hero em telas de trabalho.
- Texto grande demais dentro de cards compactos.
- Letter-spacing negativo.
- Bordas quadradas em componentes novos.
- Inputs sem label claro.
- Misturar icones de bibliotecas diferentes sem necessidade.
- Copiar layout de referencia externa sem adaptar ao UnicoCRM.

## Regra Para Outras Frentes

- Antes de criar ou alterar UI, leia este documento.
- Use componentes, tokens e classes existentes antes de criar CSS local.
- Se precisar de novo padrao visual, registre no handoff e acione a frente `03 - Style e UI`.
- UI funcional pode ser implementada por outras frentes, mas a identidade visual continua sob responsabilidade da frente 03.
