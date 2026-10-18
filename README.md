# Projeto final de MAIS

Comparação de modelos de regressão logística para prever a morte em doentes com insuficiência cardíaca (disfunção sistólica, classe NYHA III–IV). A pergunta PICO completa está no [plano do projeto](info/PLAN/project_plan.md).

## Organização

```
projeto_mais/
├── data/                       # Dados usados nas análises
├── models/                     # Um script R por modelo
│   ├── model_1.R
│   ├── model_2.R
│   ├── model_3.R
│   └── model_4.R
├── info/                       # Documentação do projeto
│   ├── PLAN/project_plan.md    # Pergunta PICO e divisão dos modelos
│   └── GIT/GUIA_GIT.md         # Guia de Git do grupo (também em HTML)
├── .github/CODEOWNERS          # Define quem aprova as alterações
├── .gitignore                  # Ficheiros que o Git ignora (temporários do R)
└── projeto_mais.Rproj          # Projeto do RStudio
```

## Como trabalhar

1. Abre o `projeto_mais.Rproj` no RStudio.
2. Antes de alterares qualquer ficheiro, lê o [Guia de Git](info/GIT/GUIA_GIT.md).

A branch `main` está protegida: todas as alterações entram por Pull Request e têm de ser aprovadas pelo João.
