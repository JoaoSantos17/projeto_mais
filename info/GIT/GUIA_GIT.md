# Guia de Git do projeto

A branch `main` está protegida: **ninguém consegue enviar alterações diretamente para lá**.
Todas as alterações entram através de um **Pull Request (PR)**, que tem de ser aprovado pelo João (administrador).

O caminho de qualquer alteração é sempre este:

```
main  →  criar branch  →  commits  →  push  →  Pull Request  →  revisão do João  →  merge na main
```

## Regras de ouro

1. **Nunca trabalhes diretamente na `main`.** Cria sempre uma branch primeiro.
2. **Antes de começares, atualiza a `main`** (`git pull`).
3. **Uma branch por tarefa** (ex.: uma branch para o teu modelo).
4. **Cada pessoa trabalha nos seus ficheiros** (ex.: `modelo_1.R`), para evitar conflitos.
5. **Faz commits pequenos e com mensagens claras.**

---

## 1. O dia a dia (para todos, incluindo o João)

Repete estes passos para cada tarefa nova. Nos exemplos usamos a branch `raquel-modelo-1`; troca pelo teu nome e tarefa (minúsculas, sem espaços nem acentos).

> **Dica:** no RStudio, o separador **Terminal** (`Alt+Shift+R`) já abre dentro da pasta do projeto. Podes correr lá todos os comandos deste guia.

### Passo 1: Atualizar a `main`

```bash
git switch main
git pull
```

### Passo 2: Criar a tua branch

```bash
git switch -c raquel-modelo-1
```

### Passo 3: Trabalhar e guardar (commit)

Faz as tuas alterações no RStudio. Quando terminares uma parte:

```bash
git status
git add .
git commit -m "Adiciona modelo 1 com creatinina e fração de ejeção"
```

- `git status` mostra o que mudou. Confirma que só estão os ficheiros que querias.
- Podes fazer vários commits na mesma branch.

### Passo 4: Enviar para o GitHub (push)

Na **primeira vez** que envias esta branch:

```bash
git push -u origin raquel-modelo-1
```


### Passo 5: Abrir o Pull Request

1. Vai a https://github.com/JoaoSantos17/projeto_mais
2. Aparece um aviso amarelo com o botão **Compare & pull request**. Clica nele.
   - Se não aparecer: **Pull requests → New pull request**, escolhe `base: main` e `compare:` a tua branch.
3. Escreve um título e uma descrição curta do que fizeste.
4. Clica em **Create pull request**.

### Passo 6: Esperar pela revisão

- **Se o João aprovar**, ele faz o merge e as tuas alterações entram na `main`.
- **Se o João pedir alterações**, faz as correções **na mesma branch** e envia:

  ```bash
  git add .
  git commit -m "Corrige o que foi pedido na revisão"
  git push
  ```

  O PR atualiza-se sozinho.

> Se fizeres novos commits **depois** de o PR estar aprovado, a aprovação é anulada e o João tem de aprovar outra vez.

### Passo 7: Limpar depois do merge

```bash
git switch main
git pull
git branch -d raquel-modelo-1
```

Pronto. Para a próxima tarefa, volta ao Passo 1.

---

## 2. Só para o administrador (João)

### 2.1 Adicionar colaboradores (uma vez)

Em https://github.com/JoaoSantos17/projeto_mais/settings/access, clica em **Add people** e adiciona cada colega pelo username do GitHub.

### 2.2 Rever o PR de um colega

1. Abre o PR em **Pull requests**.
2. Vai ao separador **Files changed** e lê as alterações. Podes clicar numa linha para deixar um comentário.
3. Usa esta lista para validar:
   - A descrição explica o que foi feito.
   - Só estão os ficheiros esperados (sem `.Rhistory`, `.RData` ou outros ficheiros pessoais).
   - O código corre sem erros (ver 2.3).
   - Os resultados fazem sentido para a pergunta do projeto.
   - O GitHub não mostra conflitos com a `main`.
4. Clica em **Review changes** e escolhe:
   - **Approve**: está tudo bem.
   - **Request changes**: o colega tem de corrigir algo (explica o quê).
5. Depois de aprovar, clica em **Merge pull request** e a seguir em **Delete branch**.

### 2.3 Testar o código de um colega no teu computador (opcional)

```bash
git fetch origin
git switch raquel-modelo-1
```

Corre o código no RStudio. No fim, volta à `main`:

```bash
git switch main
```

> **Não faças push para a branch de um colega.** Se fores tu o último a enviar alterações, o GitHub já não te deixa aprovar esse PR. Pede ao colega que faça ele as correções.

### 2.4 Os teus próprios PRs

O GitHub **não deixa ninguém aprovar o próprio PR**. Segue os mesmos passos da secção 1 e, no fim:

1. Revê tu mesmo o separador **Files changed** com a lista da secção 2.2.
2. Na caixa de merge, marca a opção de **bypass** das regras e clica em **Merge pull request**.

---

## 3. Problemas comuns

### "Changes must be made through a pull request" ao fazer push

Fizeste commits diretamente na `main`. Passa-os para uma branch nova:

```bash
git switch -c nome-da-tarefa
git branch -f main origin/main
git push -u origin nome-da-tarefa
```

Depois abre o PR normalmente (Passo 5).

### Comecei a alterar ficheiros na `main`, mas ainda não fiz commit

Cria a branch agora. As alterações vão contigo:

```bash
git switch -c nome-da-tarefa
```

### O PR diz "This branch has conflicts"

Alguém alterou as mesmas linhas que tu. Traz a `main` mais recente para a tua branch:

```bash
git switch main
git pull
git switch nome-da-tarefa
git merge main
```

Se o Git avisar que há conflitos, abre os ficheiros indicados e procura blocos assim:

```
<<<<<<< HEAD
a tua versão
=======
a versão da main
>>>>>>> main
```

Deixa só o texto correto, apaga as linhas `<<<<<<<`, `=======` e `>>>>>>>`, e depois:

```bash
git add .
git commit -m "Resolve conflitos com a main"
git push
```

### "Your local changes would be overwritten" ao mudar de branch ou fazer pull

Tens alterações por guardar. Faz commit primeiro (Passo 3) e repete o comando.

### Quero desfazer as alterações num ficheiro (ainda sem commit)

```bash
git restore nome-do-ficheiro
```

> **Atenção:** isto apaga as alterações desse ficheiro e não dá para recuperar.

### O Git pede password e não aceita a minha

A password normal do GitHub **não funciona** no terminal. Cria um token em https://github.com/settings/tokens/new?scopes=repo&description=projeto_mais, copia-o e cola-o no lugar da password.

> Ao colar o token não aparece nada no ecrã. É normal: carrega em Enter.

---

## 4. Resumo dos comandos

| Comando | O que faz |
|---|---|
| `git status` | Mostra em que branch estás e o que mudou |
| `git switch main` | Muda para a branch `main` |
| `git pull` | Traz as últimas alterações do GitHub |
| `git switch -c nome` | Cria uma branch nova e muda para ela |
| `git add .` | Prepara todas as alterações para o commit |
| `git commit -m "mensagem"` | Guarda as alterações com uma mensagem |
| `git push -u origin nome` | Envia uma branch nova para o GitHub (primeira vez) |
| `git push` | Envia os commits novos |
| `git branch -d nome` | Apaga uma branch local (depois do merge) |
| `git log --oneline -5` | Mostra os últimos 5 commits |
