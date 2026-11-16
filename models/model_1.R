# O caso ----------------------------------------------------------------------
library(tidyverse)
library(here)
library(pROC)

# 1. Os dados -----------------------------------------------------------------
# Import dos dados
dataset <- read.csv(here("data/raw/heart_failure_clinical_records_dataset.csv"))

# Visão geral do dataset
glimpse(dataset)
summary(dataset)
#
# Interpretação:
# -> 299 observações e 13 variáveis, todas guardadas como numéricas (int/dbl)
# -> 7 variáveis são numéricas: age, creatinine_phosphokinase, ejection_fraction, platelets, serum_creatinine, serum_sodium e time
# -> 6 variáveis são categóricas binárias codificadas como 0/1 (anaemia, diabetes, high_blood_pressure, sex, smoking, DEATH_EVENT
# -> Não há Na(missings)


# numero de mortes
dataset |> count(DEATH_EVENT)
# Resultado: 1 = 96 | 0 = 203

# 2. O modelo e as probabilidades -------------------------------------------
#
# A regressão logística estima a probabilidade de um valor binário
# (morte ou não) a partir de 2 variáveis. 

# glm(): ajusta uma regressão logística com as 2 variáveis do internamento.
modelo <- glm(
  DEATH_EVENT ~ ejection_fraction + serum_creatinine, data = dataset, family = binomial)

# exp(coef()): odds ratios (OR). Acima de 1, a variável aumenta o risco; abaixo de 1, diminui.
round(exp(coef(modelo)), 2)

# predict(): a probabilidade prevista de morrer de cada doente. response -> para dar o resultado em probabilidades
dataset <- dataset |> mutate(p = predict(modelo, type = "response"))   

summary(modelo)
# Interpretação (significância vista em summary(modelo), p < 0.05):
#
# Variáveis significativas:
# - fração de ejeção: OR 0.93 (p < 0.001) -> cada 1% a mais, chance de morte desce ~7%
# - creatinina sérica: OR 1.94 (p < 0.001) -> cada 1 mg/dL a mais, chance de morte quase duplica
#

round(exp(cbind(OR = coef(modelo), confint(modelo))), 3)

# 3. Curva ROC --------------------------------------------------------
# 
# Cria a curva ROC e mostra num gráfico
curva_roc <- roc(dataset$DEATH_EVENT, dataset$p)
plot(curva_roc, print.auc = TRUE)

ci.auc(curva_roc)

