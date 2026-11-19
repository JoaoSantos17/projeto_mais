
# 0. Pacotes
library(tidyverse)
library(here)
library(pROC)
library(gtsummary)

theme_gtsummary_language("pt", decimal.mark = ",", big.mark = " ")


# 1. Importar e preparar os dados -------------------------------------------
dataset <- read_csv(
  here("data/raw/heart_failure_clinical_records_dataset.csv")
)

# Confirmar o nome das variáveis, incluindo o desfecho (DEATH_EVENT)
names(dataset)

# Desfecho como coluna y DENTRO dos dados, em 0/1 numérico:
# as funções das secções 4 a 7 usam dados$y e a calibração faz contas com ele
dataset <- dataset |>
  mutate(y = DEATH_EVENT)


# 2. Table 1 ----------------------------------------------------------------
# Características dos doentes estratificadas pelo desfecho, mais a coluna do total.
# O fator com rótulos é criado só dentro deste pipe, para não alterar o y
# numérico guardado em dados.
# O time fica de fora: é o tempo de seguimento, não uma característica do doente.
# Contínuas em mediana [IIQ]: várias são muito assimétricas (CPK, creatinina).
# Nas binárias (0/1), o gtsummary conta os doentes com valor 1.
table_1 <- dataset |>
  mutate(y = factor(y, levels = c(0, 1), labels = c("Sobreviveu", "Morreu"))) |>
  select(y, age, sex, smoking, anaemia, diabetes, high_blood_pressure,
         ejection_fraction, serum_creatinine, serum_sodium,
         creatinine_phosphokinase, platelets) |>
  tbl_summary(
    by = y,
    statistic = list(all_continuous() ~ "{median} [{p25}–{p75}]"),
    digits = list(serum_sodium ~ 0),
    label = list(
      age                      ~ "Idade, anos",
      sex                      ~ "Sexo masculino",
      smoking                  ~ "Fumador",
      anaemia                  ~ "Anemia",
      diabetes                 ~ "Diabetes",
      high_blood_pressure      ~ "Hipertensão arterial",
      ejection_fraction        ~ "Fração de ejeção, %",
      serum_creatinine         ~ "Creatinina sérica, mg/dL",
      serum_sodium             ~ "Sódio sérico, mEq/L",
      creatinine_phosphokinase ~ "Creatina fosfoquinase (CPK), mcg/L",
      platelets                ~ "Plaquetas, kiloplaquetas/mL"
    ),
    missing_text = "Em falta"
  ) |>
  add_overall(col_label = "**Total**  \nN = {N}") |>
  bold_labels()

table_1



# 3. Pressupostos e forma das variáveis ---------------------------------------
#
# Porquê esta secção: a regressão logística assume que cada variável contínua
# tem uma relação em linha reta com o logit do risco. Ex.: com a creatinina tal
# como está, o modelo diz que passar de 1 para 2 mg/dL tem o mesmo efeito que
# passar de 8 para 9. Se isso não for verdade, a creatinina fica mal modelada e
# o modelo 1 (só 2 variáveis) fica prejudicado na comparação com o modelo 4,
# que tem mais variáveis para compensar. O resultado desta secção é decidir a
# forma de cada variável nas fórmulas: tal como está ou em logaritmo.
# Nota: os preditores NÃO precisam de ter distribuição simétrica ou normal.

# logit_por_decil(): divide os doentes em 10 grupos (decis) pela variável,
# calcula a proporção de mortes em cada grupo e passa-a para a escala logit
# (a escala em que a regressão logística traça uma reta).
# - ntile(..., 10): decis, como na função calibracao() da sessão 4;
# - mediana: valor típico da variável em cada decil;
# - mean(y): proporção de mortes, porque y é 0/1;
# - qlogis(): passa a proporção para a escala logit;
# - {{ variavel }}: permite escrever o nome da coluna sem aspas.
logit_por_decil <- function(dados, variavel) {
  dados |>
    mutate(decil = ntile({{ variavel }}, 10)) |>
    group_by(decil) |>
    summarise(mediana = median({{ variavel }}), prop_mortes = mean(y)) |>
    mutate(logit = qlogis(prop_mortes))
}

# 3.1 Distribuição -------------------------------------------------------------
#
# Conclusões:
# - Creatinina e CPK são assimétricas à direita: a maioria dos doentes tem
#   valores baixos (creatinina: mediana 1,10 mg/dL, Q3 1,40, na Table 1), mas
#   há uma cauda longa de poucos doentes com valores muito altos (até 9,4).
# - O logaritmo comprime os valores altos (de 4 para 8 passa a ocupar a mesma
#   distância que de 1 para 2). Reduz a distância dos valores extremos mas não
#   os elimina: na CPK a distribuição fica quase simétrica; na creatinina
#   mantém-se uma cauda à direita.
# - O histograma NÃO decide a forma da variável. Mostra que há doentes muito
#   afastados dos restantes, que numa reta puxam muito pela inclinação.
#   A decisão vem da relação com o risco (3.2) e do teste (3.3).

ggplot(dataset, aes(x = serum_creatinine)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Creatinina sérica (mg/dL)", y = "Número de doentes")

ggplot(dataset, aes(x = log(serum_creatinine))) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Logaritmo da creatinina sérica", y = "Número de doentes")

ggplot(dataset, aes(x = creatinine_phosphokinase)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "CPK (mcg/L)", y = "Número de doentes")

ggplot(dataset, aes(x = log(creatinine_phosphokinase))) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Logaritmo da CPK", y = "Número de doentes")

# Restantes variáveis contínuas (idade, fração de ejeção, sódio, plaquetas)
ggplot(dataset, aes(x = age)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Idade (anos)", y = "Número de doentes")

ggplot(dataset, aes(x = ejection_fraction)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Fração de ejeção (%)", y = "Número de doentes")

ggplot(dataset, aes(x = serum_sodium)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Sódio sérico (mEq/L)", y = "Número de doentes")

ggplot(dataset, aes(x = platelets)) +
  geom_histogram(bins = 20, colour = "white") +
  labs(x = "Plaquetas (kiloplaquetas/mL)", y = "Número de doentes")

# Conclusão da secção 3.1:
# - Assimetria forte (cauda longa à direita): creatinina e CPK → testar log na 3.3
# - Distribuição aproximadamente simétrica: idade, fração de ejeção, sódio, plaquetas
#   → entram como estão (lineares)

# 3.2 Relação com o risco (linearidade no logit) --------------------------------
#
# Cada ponto é um decil (cerca de 30 doentes): a creatinina típica do grupo
# contra o logit da proporção de mortes. A reta azul é a relação que o modelo
# assume. Se os pontos seguirem a reta, a forma escolhida serve.
# Conclusões:
# - Os pontos têm as MESMAS alturas nos dois gráficos (mesmos grupos, mesmas
#   proporções de mortes); o logaritmo só muda o espaçamento na horizontal.
#   A pergunta é: com que espaçamento ficam os pontos mais perto da reta?
# - Com cerca de 30 doentes por ponto há muito ruído e a diferença visual entre
#   as duas formas é pequena. Por isso a decisão fica para o teste (3.3).

decis_creat <- logit_por_decil(dataset, serum_creatinine)

ggplot(decis_creat, aes(x = mediana, y = logit)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Creatinina sérica (mg/dL), mediana do decil",
       y = "Logit da proporção de mortes")

ggplot(decis_creat, aes(x = log(mediana), y = logit)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Logaritmo da creatinina sérica, mediana do decil",
       y = "Logit da proporção de mortes")

# 3.3 Teste da forma da creatinina ------------------------------
# Neste ponto vamos decidir a forma que a creatinina entra no modelo, ou seja,
# se entra tal como está (linear) ou em logaritmo.
# Para isso comparamos o modelo linear com uma spline (curva flexível) pelo LRT:
# H0 - A relação entre a creatinina e o logit do risco de morte é uma reta
#       (a spline não melhora o ajuste).
# H1 - A relação entre a creatinina e o logit do risco de morte é curva
#       (a spline melhora o ajuste).
# Se H0 for rejeitada, usamos o AIC para decidir entre log e spline.
# 
#
# Árvore de decisão:
#   A reta falha? (LRT: linear vs. spline, test = "LRT")
#   ├── Não (p >= 0,05) → variável entra como está (linear)
#   └── Sim (p < 0,05) → o log resolve? (AIC: log vs. spline)
#       ├── AIC do log ≤ AIC da spline → usa log (mais simples)
#       └── AIC da spline menor → usa spline
#       

# teste_forma(): aplica a árvore de decisão a uma variável contínua.
# - formula_base: fórmula com a variável na forma linear
# - variavel: nome da variável a testar (string)
# A função constrói as versões log e spline usando update(), que modifica uma
# fórmula do R: remove a variável linear (- variavel) e acrescenta a versão
# transformada (+ log(...) ou + splines::ns(..., df = 3)).
# Devolve uma lista com p_lrt, aic_log e aic_spline (invisível).
teste_forma <- function(dados, formula_base, variavel) {
  formula_log <- update(formula_base,
    paste(". ~ . -", variavel, "+ log(", variavel, ")"))
  formula_spline <- update(formula_base,
    paste(". ~ . -", variavel, "+ splines::ns(", variavel, ", df = 3)"))

  mod_linear <- glm(formula_base,   family = binomial, data = dados)
  mod_log    <- glm(formula_log,    family = binomial, data = dados)
  mod_spline <- glm(formula_spline, family = binomial, data = dados)

  lrt   <- anova(mod_linear, mod_spline, test = "LRT")
  p_lrt <- lrt$`Pr(>Chi)`[2]

  aic_log    <- AIC(mod_log)
  aic_spline <- AIC(mod_spline)

  if (p_lrt >= 0.05) {
    cat(variavel, "→ a reta não falha (p =", signif(p_lrt, 3), ") → linear\n")
  } else if (aic_log <= aic_spline) {
    cat(variavel, "→ a reta falha (p =", signif(p_lrt, 3), "), log melhor",
        "(AIC log =", round(aic_log, 1), ", spline =", round(aic_spline, 1),
        ") → usar log\n")
  } else {
    cat(variavel, "→ a reta falha (p =", signif(p_lrt, 3), "), spline melhor",
        "(AIC log =", round(aic_log, 1), ", spline =", round(aic_spline, 1),
        ") → usar spline\n")
  }

  invisible(list(p_lrt = p_lrt, aic_log = aic_log, aic_spline = aic_spline))
}

# Creatinina no modelo 1 (2 variáveis)
teste_forma(dataset, y ~ ejection_fraction + serum_creatinine, "serum_creatinine")

# CPK no modelo 4 (11 variáveis; creatinina já em log, como decidido acima)
teste_forma(dataset,
  y ~ age + anaemia + diabetes + high_blood_pressure + sex + smoking +
      ejection_fraction + log(serum_creatinine) + serum_sodium +
      creatinine_phosphokinase + platelets,
  "creatinine_phosphokinase")

# Resultados:
# serum_creatinine         → reta falha (p = 0,032), log melhor → usar log
# creatinine_phosphokinase → reta não falha (p = 0,095) → linear

# 3.4 Fórmulas finais e mortes por parâmetro -----------------------------------
#
# A creatinina entra em log (decisão da 3.3). Tudo o resto entra como está.
# O time nunca entra: é o tempo de seguimento, que só se conhece depois do
# desfecho — usá-lo como preditor seria data leakage.
f1 <- y ~ log(serum_creatinine) + ejection_fraction
f4 <- y ~ log(serum_creatinine) + ejection_fraction + age + serum_sodium +
          anaemia + high_blood_pressure + diabetes + sex + smoking +
          creatinine_phosphokinase + platelets

# Mortes por parâmetro: com 96 mortes, a regra de 10 permite no máximo 9 parâmetros.
# O modelo 4 (12 parâmetros) fica abaixo → risco de sobreajustamento.
n_mortes <- sum(dataset$y)
epp_1 <- n_mortes / length(coef(glm(f1, family = binomial, data = dataset)))
epp_4 <- n_mortes / length(coef(glm(f4, family = binomial, data = dataset)))
cat("Modelo 1:", round(epp_1, 1), "mortes por parâmetro\n")
cat("Modelo 4:", round(epp_4, 1), "mortes por parâmetro\n")

# 4. Modelos e AUC aparente ---------------------------------------------------
#
# ajustar(): função reutilizável que ajusta um glm e devolve probabilidades.
# - formula: a fórmula do modelo (ex.: f1, f4)
# - treino:  dados para ajustar o modelo
# - teste:   dados para prever (por defeito = treino → previsões aparentes)
# Na secção 4 usamos teste = treino (AUC aparente, otimista).
# Na secção 5 usamos teste ≠ treino (validação cruzada, realista).
ajustar <- function(formula, treino, teste = treino) {
  modelo <- glm(formula, data = treino, family = binomial)
  predict(modelo, newdata = teste, type = "response")
}

# AUC aparente: o modelo prevê os mesmos dados em que foi ajustado
prob1 <- ajustar(f1, dataset)
prob4 <- ajustar(f4, dataset)

# Curvas ROC e AUC com IC 95 % (método DeLong)
roc1 <- roc(dataset$y, prob1, quiet = TRUE)
roc4 <- roc(dataset$y, prob4, quiet = TRUE)
ci1  <- ci.auc(roc1)
ci4  <- ci.auc(roc4)

# Gráfico ROC aparente com AUC e IC na legenda
roc_list <- setNames(
  list(roc1, roc4),
  c(paste0("Modelo 1 (AUC = ", round(auc(roc1), 3),
           "; IC 95% ", round(ci1[1], 3), "–", round(ci1[3], 3), ")"),
    paste0("Modelo 4 (AUC = ", round(auc(roc4), 3),
           "; IC 95% ", round(ci4[1], 3), "–", round(ci4[3], 3), ")"))
)

ggroc(roc_list) +
  geom_abline(intercept = 1, slope = 1, linetype = "dashed", colour = "grey50") +
  labs(x = "Especificidade", y = "Sensibilidade", colour = NULL) +
  theme_minimal()

# 5. Validação cruzada em 10 partes -------------------------------------------
#
# A AUC aparente é otimista: o modelo foi avaliado nos dados que "conhece".
# A validação cruzada corrige isto: divide os 299 doentes em 10 partes;
# em cada iteração, treina nas 9 e prevê na que ficou de fora.
# No fim, cada doente tem uma previsão feita por um modelo que não o viu.
# As mesmas 10 partes são usadas para os modelos 1 e 4 (comparação justa).

set.seed(2026)
dataset <- dataset |> mutate(parte = sample(rep(1:10, length.out = n())))

# Vetores para guardar as previsões validadas (uma por doente)
pcv1 <- numeric(nrow(dataset))
pcv4 <- numeric(nrow(dataset))

for (k in 1:10) {
  treino <- dataset |> filter(parte != k)
  teste  <- dataset |> filter(parte == k)

  # A mesma função ajustar() da secção 4, agora com treino ≠ teste
  pcv1[dataset$parte == k] <- ajustar(f1, treino, teste)
  pcv4[dataset$parte == k] <- ajustar(f4, treino, teste)
}

# AUC validada com IC 95 %
roc_cv1 <- roc(dataset$y, pcv1, quiet = TRUE)
roc_cv4 <- roc(dataset$y, pcv4, quiet = TRUE)
ci_cv1  <- ci.auc(roc_cv1)
ci_cv4  <- ci.auc(roc_cv4)

# Otimismo = AUC aparente − AUC validada
cat("Modelo 1 — aparente:", round(auc(roc1), 3),
    "| validada:", round(auc(roc_cv1), 3),
    "| otimismo:", round(auc(roc1) - auc(roc_cv1), 3), "\n")
cat("Modelo 4 — aparente:", round(auc(roc4), 3),
    "| validada:", round(auc(roc_cv4), 3),
    "| otimismo:", round(auc(roc4) - auc(roc_cv4), 3), "\n")

# Gráfico ROC validada com AUC e IC na legenda
roc_cv_list <- setNames(
  list(roc_cv1, roc_cv4),
  c(paste0("Modelo 1 (AUC = ", round(auc(roc_cv1), 3),
           "; IC 95% ", round(ci_cv1[1], 3), "–", round(ci_cv1[3], 3), ")"),
    paste0("Modelo 4 (AUC = ", round(auc(roc_cv4), 3),
           "; IC 95% ", round(ci_cv4[1], 3), "–", round(ci_cv4[3], 3), ")"))
)

ggroc(roc_cv_list) +
  geom_abline(intercept = 1, slope = 1, linetype = "dashed", colour = "grey50") +
  labs(x = "Especificidade", y = "Sensibilidade", colour = NULL,
       title = "Curvas ROC — validação cruzada (10 partes)") +
  theme_minimal()

# 6. Comparação principal: modelo 1 contra modelo 4 ---------------------------
#
# A comparação é feita sobre as previsões da validação cruzada (secção 5),
# não sobre as aparentes, para não comparar modelos com AUC infladas.
# roc.test() com paired = TRUE: os mesmos 299 doentes nos dois modelos,
# com as mesmas 10 partes → teste emparelhado (DeLong).
# O IC da diferença é o que interessa: mostra que diferenças são compatíveis
# com os dados. Um p > 0,05 não prova que são iguais.

comp <- roc.test(roc_cv1, roc_cv4, paired = TRUE, method = "delong")

cat("Diferença de AUC (modelo 4 − modelo 1):",
    round(auc(roc_cv4) - auc(roc_cv1), 3), "\n")
# O IC do roc.test() é de (modelo 1 − modelo 4); trocam-se os limites e o
# sinal para ficar na mesma direção da diferença acima (modelo 4 − modelo 1).
cat("IC 95%:", round(-comp$conf.int[2], 3), "a", round(-comp$conf.int[1], 3), "\n")
cat("p =", signif(comp$p.value, 3), "\n")

# 7. Calibração ---------------------------------------------------------------
#
# A calibração mede se as probabilidades previstas batem certo com a realidade.
# Exemplo: se o modelo diz 30 % a 100 doentes, devem morrer ~30.
# Usamos as previsões da validação cruzada (pcv1, pcv4), não as aparentes
# (nos dados de ajuste, a calibração dá valores perfeitos por construção).
#
# Funções da sessão 4 do professor (precisam de um data.frame com colunas p e y):

# calibracao(): agrupa os doentes em decis pela probabilidade prevista
# e compara a média prevista com a proporção observada em cada grupo.
calibracao <- function(dados, grupos = 10) {
  dados |>
    mutate(decil = ntile(p, grupos)) |>
    group_by(decil) |>
    summarise(prevista = mean(p), observada = mean(y), n = n(), .groups = "drop")
}

# resumo_calibracao(): calcula duas medidas numéricas de calibração.
# - Calibração global (CITL): a ordenada na origem do modelo y ~ offset(logit(p)).
#   Se = 0, a média prevista bate com a observada.
# - Declive de calibração: se = 1, as previsões não são nem otimistas nem pessimistas.
#   > 1 = variação subestimada; < 1 = sobreajustamento (previsões extremas demais).
# IC 95 % do declive e da CITL com confint.default().
resumo_calibracao <- function(dados) {
  citl <- glm(y ~ offset(qlogis(p)), data = dados, family = binomial)
  cal  <- glm(y ~ qlogis(p), data = dados, family = binomial)
  ic_citl  <- confint.default(citl)[1, ]
  ic_slope <- confint.default(cal)[2, ]

  tibble(
    media_prevista  = round(mean(dados$p), 3),
    media_observada = round(mean(dados$y), 3),
    citl            = round(unname(coef(citl)[1]), 3),
    citl_ic95       = paste0(round(ic_citl[1], 3), " a ", round(ic_citl[2], 3)),
    declive         = round(unname(coef(cal)[2]), 3),
    declive_ic95    = paste0(round(ic_slope[1], 3), " a ", round(ic_slope[2], 3))
  )
}

# Preparar os dados: data.frame com y e p (previsões da validação cruzada)
dados_cv1 <- data.frame(y = dataset$y, p = pcv1)
dados_cv4 <- data.frame(y = dataset$y, p = pcv4)

# Resumo numérico
resumo_calibracao(dados_cv1)
resumo_calibracao(dados_cv4)

# Gráficos de calibração: cada ponto é um decil (~30 doentes).
# A diagonal tracejada é a calibração perfeita (previsto = observado).
cal1 <- calibracao(dados_cv1)
cal4 <- calibracao(dados_cv4)

ggplot(cal1, aes(x = prevista, y = observada)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey50") +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Probabilidade prevista", y = "Proporção observada",
       title = "Calibração — Modelo 1 (validação cruzada)") +
  theme_minimal()

ggplot(cal4, aes(x = prevista, y = observada)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey50") +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Probabilidade prevista", y = "Proporção observada",
       title = "Calibração — Modelo 4 (validação cruzada)") +
  theme_minimal()

# 8. Análise de sensibilidade
# 9. Figuras