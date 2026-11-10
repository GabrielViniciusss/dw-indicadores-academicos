# Visualização dos dados (aula de 05/11/2026)

A versão publicada está em https://painel-dw-academico.vercel.app. Para usar offline, abra [`painel_academico_interativo.html`](painel_academico_interativo.html) no navegador. Funciona por arquivo local e sem internet, servidor ou instalação. No GitHub, baixe o HTML antes de abrir: a visualização de código não executa os painéis.

A [`prévia PDF`](previa_paineis.pdf) apresenta os quatro painéis em quatro páginas, sem filtros. É uma versão resumida: limita as categorias de alguns gráficos conforme indicado no topo de cada página. O HTML e seus CSVs mantêm todos os resultados. Todos os valores são calculados sobre os CSVs sintéticos já existentes no DW: **não representam indicadores reais da UFPE**.

## Organização

| Painel | Objetivo | Consultas do SQL do repositório |
| --- | --- | --- |
| Visão geral | Identificar disciplinas críticas e a composição dos resultados | C1, C6, C7 |
| Desempenho acadêmico | Investigar reprovação ao longo da trajetória, reprovação recorrente e frequência | C4, C5, C9 |
| Permanência e equidade | Comparar vínculos, assistência, cotas, renda e conclusão | C2, C3, C8, C11 |
| Turmas e docência | Comparar turmas com o histórico e ofertas entre docentes | C10, C12 |

A numeração segue o PDF da entrega ([`docs/entrega_05_11.pdf`](../docs/entrega_05_11.pdf)) e [`sql/05_consultas.sql`](../sql/05_consultas.sql).

## Uso e leitura

- Os filtros de curso, semestre da matrícula, entrada no curso e disciplina recalculam os indicadores automaticamente. Os filtros ativos aparecem em etiquetas removíveis; “Limpar filtros” volta ao recorte inicial.
- Todos os gráficos usam cartões e áreas de visualização padronizados. Gráficos com muitas categorias têm rolagem interna, sem alongar a página.
- Em C8, use os botões “Reprovação” e “Evasão” para alternar o indicador no mesmo espaço. A impressão inclui ambos.
- Cada cartão traz uma explicação curta. Abra “Como interpretar” para ler as regras de cálculo e as limitações.
- C2 e C11 usam apenas curso e turma de ingresso. O vínculo é um retrato final da base; não é reconstituído para cada semestre.
- C1, C7 e C10 exibem o último semestre disponível no recorte quando nenhum semestre está selecionado. As tabelas de detalhes e o CSV mantêm todos os semestres. C4 reúne todos os semestres do recorte.
- C12 mostra uma disciplina por vez. Sem seleção, usa a primeira disciplina do recorte em ordem alfabética.
- C6 reúne ofertas por disciplina/semestre somando numeradores e denominadores. C8 reúne coortes no gráfico, mantendo curso, cota e renda; a tabela detalhada preserva a coorte.
- Reprovação e aprovação excluem trancamentos do denominador; C7 inclui todos os estados e soma 100%. Denominador zero aparece como ausência de valor.
- As dez disciplinas críticas de C6 e C7 usam toda a base como referência, assim como os CTEs do SQL. O ranking C1 é recalculado no recorte, separado por semestre e curso, com desempate por ID da disciplina, igual ao SQL.
- C10 compara cada turma com os semestres anteriores da mesma disciplina no curso, ponderados pelas matrículas com resultado, sempre na base completa. Entram turmas com 10 ou mais matrículas com resultado. O indicador não mede causalidade nem qualidade do professor.
- C5 conta, por curso e disciplina, os alunos com duas ou mais reprovações entre os que cursaram com resultado, de 2018.1 a 2025.2.
- Em C12, ofertas com vários docentes aparecem para cada um; somar docentes duplicaria matrículas compartilhadas.
- C2 e C11 excluem ingressos anteriores a 2018: essas coortes foram observadas parcialmente. Coortes recentes ainda não têm trajetória completa. C11 considera somente concluintes.
- C8 usa a situação **final** de evasão entre os alunos participantes do recorte.
- Passe o cursor nos elementos dos gráficos para ver os valores. Use “Tabela” ou “Ver dados” para consultar os resultados e o botão CSV de cada cartão para exportá-los. O botão superior exporta as matrículas dos filtros globais.
- A impressão inclui todos os painéis com os filtros correntes e resume os gráficos mais extensos: C1 as cinco maiores de cada curso, C2 as duas coortes mais recentes de cada curso, C5 até 10 disciplinas, C8 os 6 grupos de maior reprovação, C10 até 8 turmas, C11 até 6 grupos de maior duração e C12 até 8 ofertas. A prévia PDF entregue usa o recorte inicial. O HTML é a versão indicada para ler todos os detalhes e interagir.

## Explorar e compartilhar

- **Ampliar uma consulta:** clique no ícone ⛶ do cartão. A janela oferece um gráfico maior, tabela, CSV, PDF individual e link do recorte. Feche com ×, Esc ou clicando fora da janela. O foco do teclado volta ao cartão.
- **Filtros específicos:** abra “Filtros desta consulta”. A opção “Do painel” herda o filtro global; “Todos” remove essa restrição somente para a consulta. Há filtros de período do aluno em C4, cota/renda em C8 e docente em C12. “Usar filtros do painel” remove os ajustes locais. Os outros cartões e os totais do painel não mudam. O cartão ajustado recebe a indicação “Recorte específico”.
- **Gráfico ou tabela:** use os dois botões do cartão ou da janela ampliada. A tabela traz a consulta completa no recorte; gráficos como C1/C7/C10 exibem apenas o último semestre disponível, e C5 e C10 destacam até 15 linhas. O CSV da consulta preserva todas as linhas. C12 também oferece barras de aprovação por oferta; a tabela mantém notas e quantidades.
- **Comparar semestres:** a faixa “Comparação semestral” identifica o semestre selecionado (ou o mais recente do recorte) e o semestre imediatamente anterior da base. Calcula aprovação e reprovação sobre matrículas com resultado, com os mesmos filtros globais. A variação aparece em pontos percentuais. Ausência de denominador válido em qualquer dos dois períodos aparece como “Sem base comparável”, sem substituir ausência por zero. Os quatro cartões de resumo acima continuam descrevendo todo o recorte selecionado.
- **Investigar uma disciplina:** em C1, clique em uma barra ou em seu rótulo; pelo teclado, use Tab e Enter/espaço. Abre-se uma investigação com evolução histórica, faltas e turmas/docentes. Ela mantém curso e entrada no curso do ranking, mas reúne todos os semestres. O histórico inclui a disciplina escolhida mesmo que ela não pertença às dez críticas da base inteira. As referências e os denominadores aparecem na explicação de cada perspectiva.
- **Compartilhar:** “Compartilhar” e “Copiar link” guardam painel, filtros globais, filtros por consulta, visualização, métrica, janela de foco e perspectiva da investigação no fragmento `#` da URL. Reabrir o link restaura esse estado; Voltar e Avançar do navegador também funcionam. Se a cópia automática não estiver disponível, o link aparece em um campo selecionável. O destinatário precisa acessar o mesmo endereço do servidor ou possuir o HTML no caminho correspondente; o botão não publica o painel na internet.
- **Imprimir:** “Salvar PDF” no cabeçalho imprime os quatro painéis, com gráficos resumidos e os recortes específicos identificados. “Salvar consulta em PDF”, na janela de foco, imprime somente a consulta ou perspectiva aberta, respeitando seus filtros e a escolha entre gráfico e tabela. A prévia entregue mantém o recorte inicial e quatro páginas.

## Reprodução local

Na raiz do repositório, com Python 3 e Node.js para a verificação:

```bash
python3 dashboards/build_demo.py
python3 dashboards/validar.py
```

A construção usa apenas a biblioteca padrão do Python. Os arquivos editáveis são `template.html`, `painel.js`, `exploracao.js` e `build_demo.py`; o HTML final incorpora os dados e o código, sem CDN. `build_demo.py` também separa C1–C12 em arquivos SQL para o Metabase.

A validação compara os resultados JavaScript com as 12 consultas em SQLite em memória, adaptando a divisão numérica. A tolerância de 0,051 cobre o arredondamento SQL para uma casa decimal. Também verifica filtros combinados, recorte vazio, filtros de docente/período/cota/renda, histórico de C10 e comparações com ausência de base anterior (`validar_modelo.cjs`). Essa comparação de cálculos é independente da verificação nativa adicional: o importador e as perguntas foram executados em Metabase v0.64.1 com MySQL 8, na versão anterior com 13 consultas; a versão com 12 ainda não foi reexecutada no Metabase. Resultados de perguntas extensas podem ser limitados pelo padrão de 2.000 linhas do Metabase; use filtros/exportação para consultar os detalhes.

Para regenerar o PDF, abra o HTML e use “Salvar PDF” (A3 paisagem, escala padrão, sem cabeçalhos/rodapés). Com Chrome local também é possível:

```bash
google-chrome --headless --no-sandbox --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/dashboards/previa_paineis.pdf" \
  "file://$PWD/dashboards/painel_academico_interativo.html"
```

## Montagem nativa no Metabase

**O HTML é um protótipo independente, com SVG e JavaScript, e não um projeto nativo Power BI, Metabase ou Looker Studio.** Para a exigência de ferramenta BI, esta pasta inclui uma configuração inicial reproduzível para Metabase. O importador foi executado em uma instância local isolada do Metabase v0.64.1: criou quatro dashboards e as perguntas, cujas consultas executaram no MySQL 8 (versão anterior, com 13 consultas). A configuração dos gráficos é inicial; os ajustes descritos abaixo e os filtros nativos ainda precisam ser revisados no editor antes de apresentar essa versão. O HTML é a versão com interações e agregações visuais já verificadas.

O Compose usa um MySQL separado, com volume próprio e sem publicar sua porta. A carga do esquema roda somente na inicialização do volume vazio. O Metabase fica acessível apenas em `localhost:3033` (altere `METABASE_PORT` se essa porta estiver ocupada) e persiste sua configuração em volume; o H2 utilizado aqui é adequado para demonstração, não para produção.

Na raiz, defina duas senhas locais na sessão do terminal (não salve no Git) e inicie:

```bash
read -rs -p 'Senha root do MySQL demonstrativo: ' DW_ROOT_PASSWORD; echo
export DW_ROOT_PASSWORD
read -rs -p 'Senha do usuário painel: ' DW_PASSWORD; echo
export DW_PASSWORD
docker compose -f dashboards/metabase/compose.yaml up -d
```

1. Abra `http://localhost:3033`, conclua a configuração e crie o usuário administrador.
2. Adicione uma conexão MySQL: host `mysql`, porta `3306`, banco `dw_academico`, usuário `painel` e a senha `DW_PASSWORD`. Na conexão demonstrativa sem SSL, em opções avançadas, use `allowPublicKeyRetrieval=true` no campo de opções adicionais JDBC; essa opção foi validada na rede Docker local isolada. O host é o nome do serviço dentro da rede Docker.
3. Anote o ID da conexão no endereço da página do banco no Metabase.
4. Execute o importador abaixo, substituindo ID e email. Ele solicita a senha sem gravá-la, cria **uma nova coleção**, 12 perguntas e quatro dashboards. Cada execução cria outra coleção; se houver falha parcial, confira a coleção antes de repetir.

```bash
python3 dashboards/metabase/criar_paineis.py --database-id 1 --email seu-email@example.com
```

A API usada segue a [documentação oficial de configuração por código](https://www.metabase.com/articles/set-up-metabase-from-code-with-the-api), com imagem fixada em `v0.64.1`. O importador preserva os SQLs originais, sem filtros parametrizados nem as agregações visuais específicas do HTML. A configuração inicial dos gráficos exige revisão no editor antes da apresentação:

| Consulta | Ajuste no editor do Metabase |
| --- | --- |
| C1 | Barras horizontais empilhadas, nota/falta; selecionar semestre e curso |
| C2 | Barras de 100%, situação do vínculo; selecionar um curso |
| C3 | Duas linhas (com e sem assistência); selecionar um curso |
| C4 | Colunas empilhadas por período do aluno; somar numerador e denominador antes de reunir semestres |
| C5 | Barras horizontais de `taxa_recorrente`; selecionar um curso e mostrar `alunos_afetados` |
| C6 | Linhas por disciplina, semestre no eixo X; somar numerador e denominador antes de reunir ofertas |
| C7 | Barras empilhadas em 100%, cinco situações; selecionar semestre e curso |
| C8 | Duplicar a pergunta para barras de reprovação e evasão em gráficos separados; manter cotas, renda e coorte explícitos |
| C9 | Dispersão: média de faltas × reprovação; manter uma oferta/curso por ponto |
| C10 | Barras divergentes de `diferenca_pontos`; selecionar semestre e curso |
| C11 | Colunas agrupadas, média de semestres e prazo previsto; selecionar um curso |
| C12 | Tabela por turma e docente; selecionar disciplina e semestre |

Os filtros do HTML **não** são importados automaticamente. Para filtros nativos, adicione variáveis ao SQL e conecte-as no editor do dashboard. Filtre os registros antes da agregação e antes do ranking C1, preservando o histórico de C10. Não use média simples de taxas para reunir grupos. Veja a [documentação oficial de filtros](https://www.metabase.com/docs/latest/dashboards/filters).

Para parar mantendo os dados: `docker compose -f dashboards/metabase/compose.yaml stop`.

## Referências fornecidas na atividade

- [Painel público Power BI](https://app.powerbi.com/view?r=eyJrIjoiMzQxMWNjODQtYzhkOS00NzViLWIxNTktMzBiMjQ3ODI4ZDVhIiwidCI6IjkxMDJlZTJkLTVkZjItNGMzNC1hNTg0LWU4Mjc3ODg0N2I3MSJ9&pageName=ReportSection).
- [Registro do repositório UFPE](https://repositorio.ufpe.br/handle/123456789/65546).

O relatório Power BI depende de execução interativa e o registro da UFPE não pôde ser recuperado durante a implementação. Os links ficam como referências da atividade; não se atribuem a eles resultados ou justificativas que não foram conferidos. A organização dos painéis segue as perguntas do próprio projeto.
