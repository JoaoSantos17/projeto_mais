
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
decis_creat

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

# 3.3 Teste da forma da creatinina (próximo passo) ------------------------------

# 4. Os quatro modelos e a AUC aparente
# 5. Validação cruzada (10 partes, as mesmas para todos)
# 6. Comparação principal: modelo 1 contra modelo 4
# 7. Calibração
# 8. Análise de sensibilidade
# 9. Figuras