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
# -> Time é o período de seguimento em dias (no internamento): renomear para follow_up_days; como está ligado ao DEATH_EVENT, não usar como preditor!!!!!!


# numero de mortes
dataset |> count(DEATH_EVENT)
# Resultado: 1 = 96 | 0 = 203

# 2. O modelo e as probabilidades -------------------------------------------
#
# A regressão logística estima a probabilidade de um desfediabetescho binário
# (morte ou não) a partir de 11 variáveis. 

# glm(): ajusta uma regressão logística com as 11 variáveis do internamento.
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
# - idade: OR 1.06 (p < 0.001) -> cada ano a mais, chance de morte sobe ~6%
# - fração de ejeção: OR 0.93 (p < 0.001) -> cada 1% a mais, chance de morte desce ~7%
# - creatinina sérica: OR 1.94 (p < 0.001) -> cada 1 mg/dL a mais, chance de morte quase duplica
# - CPK: OR 1.00 por U/L (p = 0.042) -> por cada 1000 U/L, chance de morte sobe ~34%
#   (exp(0.0002905 * 1000) = 1.34; significância no limite e variável com muitos
#   outliers, por isso interpretar com cautela)
#
# Sem evidência de efeito (p ≥ 0.05), o efeito pode ser acaso:
# - sódio sérico (OR 0.94, p = 0.090, perto do limite), anemia (1.52), diabetes (1.16),
#   hipertensão (1.52), sexo (0.67), fumador (1.15), plaquetas (1.00)
#
# Conclusão: idade, função renal e função cardíaca são os principais fatores
# associados à morte; a CPK também é significativa, mas com evidência mais fraca



# 3. Curva ROC --------------------------------------------------------
# 
# Cria a curva ROC e mostra num gráfico
curva_roc <- roc(dataset$DEATH_EVENT, dataset$p)
plot(curva_roc, print.auc = TRUE)


