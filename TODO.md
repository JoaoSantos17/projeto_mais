# TODO do trabalho de grupo

**Entrega:** 22/11/2026 às 23h59, no Moodle: o `.html` do relatório e o `.zip` do projeto.
Cada dia de atraso tira 1 valor; depois de 26/11 o trabalho não é aceite.

**Questão:** tipo B, avaliar um modelo de predição ([plano do projeto](info/PLAN/project_plan.md)).

**Documentos da UC:**
[Guião](https://tiagojacinto.eu/mais-2627/avaliacao/guiao-trabalho.html) ·
[Grelha de correção](https://tiagojacinto.eu/mais-2627/avaliacao/criterios.html) ·
[Modelo do relatório](https://tiagojacinto.eu/mais-2627/avaliacao/modelo-relatorio.html) ·
[Lista de verificação da entrega](https://tiagojacinto.eu/mais-2627/avaliacao/lista-entrega.html) ·
[Política de IA](https://tiagojacinto.eu/mais-2627/politica-ia.html) ·
[Sessão 4: código da validação](https://tiagojacinto.eu/mais-2627/sessoes/04-validacao-ia/guiao.html)

Estado em 14/11/2026. Escrevam o vosso nome à frente das tarefas que ficarem convosco.

| Critério da grelha | Valores |
|---|---|
| Questão e desenho | 4 |
| Análise estatística | 6 |
| Reprodutibilidade | 4 |
| Comunicação | 4 |
| Uso de IA | 2 |

---

## Já feito

- [x] Repositório no GitHub com a `main` protegida, Pull Requests e [guia de Git](info/GIT/GUIA_GIT.md)
- [x] Projeto RStudio partilhado (`projeto_mais.Rproj`)
- [x] Base em `data/raw/` sem alterações (299 doentes, 96 mortes, sem valores em falta)
- [x] Questão do tipo B escrita em PICO, com os quatro elementos
- [x] Quatro modelos definidos, cada um com um responsável
- [x] `time` fora de todos os modelos (é a armadilha que a grelha mais penaliza)
- [x] Caminhos com `here()` em todos os scripts
- [x] Regressão logística, odds ratios e curva ROC ajustados nos quatro scripts

AUC calculada nos mesmos dados em que o modelo foi ajustado (AUC aparente). É otimista até haver validação interna.

| Modelo | Script | Variáveis | Parâmetros | AUC aparente |
|---|---|---|---|---|
| 1 | [model_1.R](models/model_1.R) | 2 | 3 | 0,761 |
| 2 | [model_2.R](models/model_2.R) | 4 | 5 | 0,790 |
| 3 | [model_3.R](models/model_3.R) | 8 | 9 | 0,800 |
| 4 | [model_4.R](models/model_4.R) | 11 | 12 | 0,809 |

---

## 1. Corrigir os scripts

- [ ] `model_2.R`, linha 82: `ci.auc(roc_mod)` dá erro porque o objeto se chama `curva_roc`. O script para aqui.
- [ ] `model_1.R`, linhas 28–57: os comentários foram copiados do modelo 4 e falam de idade, CPK e 11 variáveis. Reescrevê-los para o modelo 1 (só creatinina sérica e fração de ejeção).
- [ ] `model_1.R` e `model_4.R`, linha 28: corrigir a gralha "desfediabetescho".
- [ ] Odds ratios com IC 95 % (`confint()`) em todos os modelos. Neste momento só o modelo 2 os tem.

## 2. Completar a análise (tipo B)

Sem discriminação, calibração e validação interna, a análise não passa de Suficiente na grelha.

- [ ] **Definir a comparação principal.** Por exemplo, modelo 1 contra modelo 4, que testa a afirmação de Chicco e Jurman. As outras comparações ficam como secundárias.
- [ ] **Discriminação:** AUC com IC 95 % para os quatro modelos (`ci.auc()`).
- [ ] **Validação interna:** validação cruzada em 10 partes, com as mesmas partes para todos os modelos (`set.seed()`), ou bootstrap. Reportar a AUC aparente, a AUC validada e a diferença entre as duas (otimismo). O código está no ponto 3 da sessão 4.
- [ ] **Comparar os modelos:** diferença de AUC entre o modelo 1 e o modelo 4, com IC 95 %, calculada sobre as previsões da validação cruzada (por exemplo, `roc.test()` ou bootstrap). Um valor de p sozinho não chega.
- [ ] **Calibração:** gráfico de calibração, média prevista contra média observada, ordenada na origem e declive com IC, calculados sobre as previsões da validação cruzada. Nos dados de ajuste estes valores dão 0 e 1 por construção. As funções `calibracao()` e `resumo_calibracao()` estão no ponto 4 da sessão 4.
- [ ] **Pressupostos da regressão logística:**
  - [ ] Ver a distribuição da creatinina sérica e da CPK (caudas longas à direita) e decidir se entram em logaritmo.
  - [ ] Verificar a linearidade no logit das variáveis contínuas.
  - [ ] Verificar a multicolinearidade (`car::vif()`).
- [ ] **Número de variáveis:** o modelo 4 tem 11 variáveis para 96 mortes (cerca de 8,7 mortes por variável), abaixo da regra das 10. Justificar a escolha nos métodos e discutir o risco de sobreajustamento.
- [ ] **Análise de sensibilidade** (é o que distingue os trabalhos excelentes). Escolher uma e comparar o resultado com a análise principal:
  - creatinina sérica (e CPK) em logaritmo; ou
  - desfecho com horizonte fixo, por exemplo morte até 90 dias, excluindo quem saiu do seguimento antes desse prazo sem morrer (reportar quantos foram excluídos).
- [ ] **Table 1** com `gtsummary`, estratificada pelo desfecho, com rótulos em português e sem `add_p()`.
- [ ] **Figura principal:** curvas ROC dos quatro modelos no mesmo gráfico, ou AUC com IC por modelo, e o gráfico de calibração.
- [ ] Discutir a diferença entre modelos em termos clínicos, e não só em AUC.

## 3. Escrever o relatório em Quarto

- [ ] Descarregar o [relatorio-trabalho.qmd](https://tiagojacinto.eu/mais-2627/modelos/relatorio-trabalho.qmd) para uma pasta `scripts/` do projeto (é onde a lista de entrega o espera).
- [ ] Adaptar o modelo: título, autores, ficheiro de dados e variáveis. Apagar os exemplos de hipertensão e o texto de instruções.
- [ ] Passar o código dos quatro scripts para o `.qmd`: um bloco de preparação dos dados e uma função que ajusta e avalia cada modelo, em vez de repetir o mesmo código quatro vezes.
- [ ] **Resumo (abstract):** 250 a 350 palavras, seis movimentos, resultados com números, sem referências nem tabelas.
- [ ] **Introdução:** o problema, o que se sabe (com referências), a lacuna (confirmem no artigo de Chicco e Jurman o que avaliaram e o que ficou por avaliar, por exemplo a calibração), o objetivo e a questão em PICO.
- [ ] **Métodos:**
  - [ ] Origem da base e desenho: coorte retrospetiva observacional de dois hospitais de Faisalabad, em 2015.
  - [ ] Desfecho e variáveis de cada modelo.
  - [ ] Análise estatística, pressupostos e validação interna.
  - [ ] Software, com as versões de R e dos pacotes.
  - [ ] Seguir a norma de reporte TRIPOD+AI.
- [ ] **Resultados:** Table 1, AUC com IC, calibração e figura. Todos os números do texto vêm de código inline, e não escritos à mão.
- [ ] **Discussão:**
  - [ ] O resultado principal numa frase.
  - [ ] Comparação com Chicco e Jurman (2020) e com Ahmad et al. (2017).
  - [ ] Limitações, cada uma com o efeito provável sobre a conclusão: seguimento desigual entre doentes, dois hospitais e um ano, sem validação externa, variáveis que a base não tem, número de mortes.
  - [ ] O que seria preciso para usar o modelo noutro hospital e o que fariam a seguir.
- [ ] **Referências** em estilo Vancouver, numeradas pela ordem de citação e todas verificadas na fonte.
- [ ] **Anexo** com `sessionInfo()` (já vem no modelo).
- [ ] Extensão total de 2000 a 3500 palavras, contando o abstract e sem contar código, anexos e referências.
- [ ] Figuras e tabelas com legenda e referidas no texto.

## 4. Declaração de uso de IA

- [ ] Preencher os sete campos: ferramenta, tipo de assistência, nível HEAT-AI, secções, prompts, verificações humanas e período de utilização.
- [ ] Cada elemento lista os prompts que usou. Já há pelo menos dois registos:
  - o Claude, usado para configurar o Git e o GitHub e escrever o guia de Git, o README e este TODO;
  - a conversa da Raquel exportada em `Instruções do projeto - Claude.mhtml` (na branch `raquelmcbraganca-patch-1`).
- [ ] Mostrar o que o grupo corrigiu ou rejeitou numa resposta da IA, e porquê. É o que dá o nível Excelente neste critério.

## 5. Antes de entregar

- [ ] Revisão cruzada: cada elemento revê a secção de outro.
- [ ] Todos conseguem explicar qualquer parte do código e das escolhas, porque o docente pode perguntar a qualquer um.
- [ ] Listar no início do `.qmd` os pacotes que não fazem parte do Setup MAIS.
- [ ] Renderizar o `.html` com `embed-resources: true` e confirmar que abre com as figuras e tabelas.
- [ ] Criar o `.zip` com o `.Rproj`, `scripts/` (com o `.qmd`) e `data/raw/`.
- [ ] **Teste final:** extrair o `.zip` para outra pasta, abrir o `.Rproj` numa sessão nova de R e renderizar o `.qmd` do início ao fim. Um relatório que não renderiza custa 2 valores.
- [ ] Percorrer a [lista de verificação da entrega](https://tiagojacinto.eu/mais-2627/avaliacao/lista-entrega.html).
- [ ] Submeter o `.html` e o `.zip` no Moodle até 22/11 às 23h59 e confirmar a submissão.

## 6. Arrumar o repositório (opcional)

- [ ] Apagar no GitHub as branches que já entraram na `main`.
- [ ] Não juntar a branch `raquelmcbraganca-patch-1` à `main` (tem 51 mil linhas de `.mhtml`). Guardar o ficheiro para a declaração de IA e apagar a branch.
- [ ] Acrescentar `.claude/` ao `.gitignore`.
- [ ] Atualizar a árvore de pastas do [README](README.md) quando criarem `scripts/`.
