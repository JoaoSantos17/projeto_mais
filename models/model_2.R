#==============================================================================
#Modelo de predição de morte na Insuficiência Cardiaca - 4 variaveis
#Regressão logistica: serum_creatinine, ejection_fraction, age, serum_sodium
#===============================================================================

library(tidyverse)
library(here)
library(pROC)

#==============================================================================
#IMPORTAR E VERIFICAR OS DADOS
#==============================================================================

dataset <- read.csv(here("data/raw/heart_failure_clinical_records_dataset.csv"))

glimpse(dataset)
summary(dataset)
sum(is.na(dataset))

summary(dataset[, c("DEATH_EVENT", "serum_creatinine", "ejection_fraction", "age", "serum_sodium")])

#INTERPRETAÇÃO PARA O MODELO DE 4 VARIAVEIS
# -> 299 observações e 4 variáveis, todas guardadas como numéricas (int/dbl)
# -> As 4 variáveis deste modelo são numéricas: age, ejection_fraction, serum_creatinine, serum_sodium
# -> Não há Na(missings)
#NOTA: a variável 'time' NÃO entra no modelo. Só é conhecida no fim do seguimento e é consequência do desfecho (quem morre tem seguimento curto PORQUE morreu).


#NUMERO DE MORTES
dataset |> count(DEATH_EVENT)
# 1 - 96 OU SEJA 96 MORTES

#==============================================================================
# MODELO E PROBABILIDADES
#==============================================================================
# A regressão logística estima a probabilidade de um desfecho binário (morte ou não) a partir de 4 variáveis. 

# glm(): ajusta uma regressão logística com as 4 variáveis do internamento.
modelo <- glm(
  DEATH_EVENT ~ age + ejection_fraction + serum_creatinine + serum_sodium, data = dataset, family = binomial)

# exp(coef()): 
#odds ratios (OR). OR=1 Sem associação; OR>1 Aumenta as odds do desfecho (fator de risco); OR<1 Diminui as odds do desfecho (fator protetor)

round(exp(coef(modelo)), 2)

#RESULTADOS:
#Age: 1.05; Ejection_Fraction: 0.94; Serum_Creatinine: 1.88; Serum_Sodium: 0.95


#predict(): Calcula a probabilidade pre ista de morte para cada doente e guarda-a numa nova coluna chamada p - resultados em probabilidades

dataset <- dataset |> mutate(p = predict(modelo, type = "response"))   

summary(dataset)
summary(modelo)

round(exp(cbind(OR = coef(modelo), confint(modelo))), 3)

# Interpretação (significância vista em summary(modelo), p < 0.05):

#Estatisticamente significativa
#Idade: OR 1.05, p<0.001, - Cada ano a mais, as odds de morte aumentam ≈ 5%
#Fraçaõ de Ejeção: OR 0.94, p<0.001 - Cada ponto percentual a mais de FE reduz as odds de morte em ≈ 6,4%
# Creatinina Sérica: OR 1.88, p<0.001 - Cada aumento de 1 mg/dL quase duplica as odds de morte (+88%)

#Estatisticamente não significativa
#Sódio Sérico: OR 0.95, p=0.141 - maior de 0.05 logo a associação entre o sódio e a morte não é estatisticamente significativa

#Conclusão: Neste modelo a idade, fração de ejeção e creatinina sérica são os principais fatores associados a morte

#==============================================================================
# CURVA ROC
#==============================================================================

# Cria a curva ROC e mostra num gráfico
curva_roc <- roc(dataset$DEATH_EVENT, dataset$p)
plot(curva_roc, print.auc = TRUE)

#AUC = 0.790 

ci.auc(roc_mod)
#O modelo apresentou discriminação aceitável a boa, com AUC aparente de 0,790 (IC 95% 0,737–0,848; método de DeLong), significativamente superior ao acaso.