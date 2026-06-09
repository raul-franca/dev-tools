# Git — Cheatsheet

Referência de comandos Git para o dia a dia de desenvolvimento.

---

## 1. Configuração inicial

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
git config --global core.editor "code --wait"   # VS Code como editor padrão
git config --list                               # Ver configurações ativas
```

---

## 2. Criar e clonar repositórios

```bash
git init                         # Inicializar repositório no diretório atual
git clone URL                    # Clonar repositório remoto
git clone URL pasta/             # Clonar em pasta específica
git clone --depth 1 URL          # Clone raso (só último commit — mais rápido)
```

---

## 3. Status e histórico

```bash
git status                       # Ver estado dos arquivos
git log                          # Histórico de commits
git log --oneline                # Histórico compacto (uma linha por commit)
git log --oneline --graph        # Histórico com visualização de branches
git log -p arquivo               # Histórico com diff de um arquivo específico
git diff                         # Ver mudanças não staged
git diff --staged                # Ver mudanças staged (prontas para commit)
git show HASH                    # Ver detalhes de um commit específico
```

---

## 4. Staging e commit

```bash
git add arquivo                  # Adicionar arquivo ao staging
git add .                        # Adicionar todos os arquivos modificados
git add -p                       # Adicionar mudanças interativamente (por hunk)

git commit -m "mensagem"         # Criar commit
git commit --amend               # Editar mensagem do último commit (não publicado)
git commit --amend --no-edit     # Adicionar mudanças ao último commit sem editar mensagem
```

---

## 5. Branches

```bash
git branch                       # Listar branches locais
git branch -a                    # Listar branches locais e remotas
git branch nome                  # Criar branch
git switch nome                  # Mudar para branch
git switch -c nome               # Criar e mudar para branch
git branch -d nome               # Deletar branch (seguro — só se merged)
git branch -D nome               # Forçar deleção de branch
```

---

## 6. Merge e Rebase

```bash
git merge nome-da-branch         # Merge de branch na branch atual
git merge --no-ff nome           # Merge com commit de merge explícito
git merge --abort                # Cancelar merge em conflito

git rebase main                  # Rebase da branch atual em cima de main
git rebase --interactive HEAD~3  # Rebase interativo dos últimos 3 commits
git rebase --abort               # Cancelar rebase
git rebase --continue            # Continuar rebase após resolver conflito
```

---

## 7. Repositório remoto

```bash
git remote -v                    # Ver remotes configurados
git remote add origin URL        # Adicionar remote

git fetch                        # Buscar atualizações do remote (sem merge)
git pull                         # Fetch + merge da branch atual
git pull --rebase                # Fetch + rebase (histórico mais limpo)

git push origin nome-da-branch   # Enviar branch para remote
git push -u origin nome          # Enviar e rastrear branch remota
git push --force-with-lease      # Push forçado seguro (não sobrescreve commits alheios)
```

---

## 8. Stash

```bash
git stash                        # Guardar mudanças temporariamente
git stash push -m "descrição"    # Stash com nome
git stash list                   # Listar stashes
git stash pop                    # Restaurar último stash e removê-lo
git stash apply stash@{1}        # Restaurar stash específico sem removê-lo
git stash drop stash@{1}         # Remover stash específico
git stash clear                  # Remover todos os stashes
```

---

## 9. Desfazer mudanças

```bash
git restore arquivo              # Descartar mudanças não staged em arquivo
git restore .                    # Descartar todas as mudanças não staged
git restore --staged arquivo     # Remover arquivo do staging (não perde mudança)

git reset HEAD~1                 # Desfazer último commit (mantém mudanças no working tree)
git reset --hard HEAD~1          # Desfazer último commit e descartar mudanças

git revert HASH                  # Criar commit que desfaz um commit anterior (seguro para histórico público)
```

---

## 10. Tags

```bash
git tag                          # Listar tags
git tag v1.0.0                   # Criar tag leve
git tag -a v1.0.0 -m "Release"   # Criar tag anotada
git push origin v1.0.0           # Enviar tag para remote
git push origin --tags           # Enviar todas as tags
git tag -d v1.0.0                # Deletar tag local
```

---

## 11. Busca e inspeção

```bash
git grep "texto"                 # Buscar texto no código (arquivos rastreados)
git log --all --grep="mensagem"  # Buscar commits pela mensagem
git log -S "função"              # Buscar commits que adicionaram/removeram texto
git blame arquivo                # Ver quem editou cada linha de um arquivo
git bisect start                 # Iniciar busca binária por commit que introduziu bug
```

---

## 12. Fluxo básico de trabalho (Feature Branch)

```bash
# 1. Atualizar main
git switch main
git pull

# 2. Criar branch para a feature
git switch -c feature/minha-feature

# 3. Desenvolver e commitar
git add .
git commit -m "feat: adiciona minha feature"

# 4. Atualizar com main antes de abrir PR
git fetch origin
git rebase origin/main

# 5. Enviar para remote
git push -u origin feature/minha-feature

# 6. Abrir Pull Request na plataforma (GitHub, GitLab, etc.)
```
