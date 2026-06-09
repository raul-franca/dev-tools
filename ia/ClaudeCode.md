# Claude Code — Cheatsheet

Referência de comandos e funcionalidades do Claude Code CLI.

> **Instalação:** `npm install -g @anthropic-ai/claude-code`

---

## 1. CLI — Iniciar sessão

```bash
claude                              # Inicia sessão interativa
claude "descreva a tarefa"          # Inicia com prompt inicial
claude -p "query"                   # Modo não-interativo (headless): executa e sai
claude -c                           # Continua a conversa mais recente
claude --resume                     # Abre picker para escolher sessão anterior

cat arquivo.ts | claude -p "review" # Processa stdin
```

---

## 2. CLI — Flags úteis

```bash
# Modelo e esforço
claude --model opus                  # Usar Opus (mais poderoso)
claude --model sonnet                # Usar Sonnet (balanceado)
claude --effort high                 # Nível de esforço: low | medium | high | max

# Permissões
claude --permission-mode plan        # Analisa mas não edita nem executa
claude --allowedTools "Bash,Read,Edit"        # Pré-aprovar ferramentas
claude --disallowedTools "Bash(git push *)"   # Bloquear ferramentas específicas

# Contexto extra
claude --add-dir ../libs ../shared   # Adicionar diretórios ao contexto

# Headless (scripts)
claude -p "query" --output-format json           # Saída JSON estruturada
claude -p "query" --output-format stream-json    # Streaming JSON
claude -p "query" --max-turns 5                  # Limitar turns agentic
claude -p "query" --max-budget-usd 1.00          # Limitar custo

# Debug
claude --debug                       # Habilita debug completo
claude --verbose                     # Saída detalhada
```

---

## 3. Comandos slash (modo interativo)

### Sessão e contexto

```
/clear              # Limpa histórico e inicia nova conversa
/compact            # Compacta histórico (libera contexto sem perder estado)
/context            # Visualiza uso do contexto atual
/cost               # Mostra tokens e custo da sessão
/resume [sessão]    # Retoma sessão anterior por ID ou nome
/rename [nome]      # Renomeia sessão atual
```

### Código e revisão

```
/diff               # Abre visualizador de diff interativo
/rewind             # Desfaz mudanças e volta a ponto anterior
/plan               # Entra em Plan Mode (analisa sem modificar)
```

### Modelo e configuração

```
/model [nome]       # Troca o modelo da sessão
/effort [nível]     # Define esforço: low | medium | high | max
/fast               # Toggle Fast Mode (saída mais rápida)
/vim                # Ativa modo vim no input
/status             # Versão, modelo e conta em uso
```

### Automação e permissões

```
/permissions        # Ver e editar regras de permissão
/hooks              # Ver configurações de hooks
/memory             # Editar CLAUDE.md e gerenciar auto-memory
/init               # Inicializa CLAUDE.md no projeto
```

### Outros

```
/help               # Lista todos os comandos disponíveis
/doctor             # Diagnostica instalação e configuração
/feedback           # Enviar feedback sobre o Claude Code
/exit               # Sair da sessão
```

---

## 4. Atalhos de teclado

| Atalho | Ação |
|---|---|
| `Ctrl+C` | Cancela input ou geração atual |
| `Ctrl+D` | Sai da sessão |
| `Ctrl+L` | Limpa tela (mantém histórico) |
| `Ctrl+R` | Busca no histórico de comandos |
| `Ctrl+O` | Toggle verbose output |
| `Ctrl+T` | Toggle lista de tasks |
| `Shift+Tab` | Alterna modos de permissão |
| `Esc + Esc` | Rewind / resume a conversa |
| `Option+Enter` | Nova linha no input (macOS) |
| `\ + Enter` | Nova linha (todos os terminais) |
| `@` + texto | Autocomplete de caminhos de arquivo |
| `!` + comando | Executa comando bash diretamente |

---

## 5. Modos de permissão

| Modo | Comportamento |
|---|---|
| `default` | Pede permissão na primeira vez que usa cada ferramenta |
| `acceptEdits` | Auto-aceita edições de arquivo sem pedir |
| `plan` | Apenas analisa — não edita arquivos nem executa comandos |
| `dontAsk` | Nega automaticamente (só ferramentas pré-aprovadas funcionam) |
| `bypassPermissions` | Pula todos os prompts (usar apenas em containers/VMs) |

Trocar durante a sessão: `Shift+Tab`

---

## 6. Bash direto no terminal do Claude

Use `!` para rodar comandos sem acionar o Claude:

```bash
! git status
! npm run test
! docker compose up -d
! ls -la
```

---

## 7. Configuração (settings.json)

#### Locais

```
~/.claude/settings.json             # Global (todos os projetos)
.claude/settings.json               # Projeto (versionado)
.claude/settings.local.json         # Local (não versionado)
```

#### Exemplo de configuração

```json
{
  "model": "claude-sonnet-4-6",
  "defaultMode": "acceptEdits",
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm run *)",
      "Read",
      "Edit"
    ],
    "deny": [
      "Bash(git push --force*)"
    ]
  }
}
```

#### Sintaxe de permissões

```
Bash                          # Todos os comandos bash
Bash(npm run *)               # Comandos com prefixo
Bash(git push --force*)       # Bloquear push forçado
Read                          # Todos os reads
Edit(/src/**/*.ts)            # Edição de arquivos TypeScript
mcp__github__*                # Todos os tools do MCP server "github"
```

---

## 8. CLAUDE.md — Instruções do projeto

O Claude lê automaticamente o `CLAUDE.md` ao iniciar. Use para definir contexto, convenções e regras.

```
CLAUDE.md                           # Raiz do projeto (versionado)
.claude/CLAUDE.md                   # Pasta .claude do projeto
~/.claude/CLAUDE.md                 # Global (todos os projetos)
```

Exemplo:

```markdown
# Meu Projeto

## Stack
- Java 21 + Spring Boot
- PostgreSQL
- Docker Compose para ambiente local

## Convenções
- Commits em português
- Testes obrigatórios para novos endpoints
- Nunca commitar na branch main diretamente

## Comandos úteis
- `./mvnw test` — rodar testes
- `docker compose up -d` — subir banco e serviços
```

Criar via CLI: `claude /init`

---

## 9. Hooks — automação por evento

Hooks executam scripts automaticamente em resposta a eventos do Claude Code.

Configurados em `settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "npx prettier --write \"$CLAUDE_TOOL_INPUT_FILE_PATH\""
      }]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"Claude terminou\" with title \"Claude Code\"'"
      }]
    }]
  }
}
```

#### Eventos principais

| Evento | Quando dispara |
|---|---|
| `SessionStart` | Ao iniciar ou retomar sessão |
| `PreToolUse` | Antes de executar tool (pode bloquear) |
| `PostToolUse` | Após tool executar com sucesso |
| `Stop` | Quando Claude termina a resposta |
| `Notification` | Quando Claude precisa de atenção |

#### Exit codes

| Código | Efeito |
|---|---|
| `0` | Permite ação (stdout vira contexto) |
| `2` | **Bloqueia** ação (stderr vira feedback ao Claude) |
| Outro | Permite ação, stderr é logado |

---

## 10. Modo headless (scripts e CI)

```bash
# Análise simples
claude -p "Resumir mudanças no diff" --allowedTools "Read"

# Com output estruturado
claude -p "Listar funções exportadas" \
  --output-format json \
  --allowedTools "Read"

# Processando stdin
git diff HEAD~1 | claude -p "Revisar mudanças e sugerir melhorias"

# Limitar turns e custo
claude -p "Refatorar arquivo X" \
  --max-turns 10 \
  --max-budget-usd 0.50 \
  --allowedTools "Read,Edit"
```

---

## 11. Autenticação

```bash
claude auth login               # Login na conta Anthropic
claude auth login --sso         # Login via SSO corporativo
claude auth logout              # Logout
claude auth status              # Ver conta autenticada
```

---

## 12. Estrutura de projeto recomendada

```
.claude/
├── settings.json               # Configurações do projeto (versionado)
├── settings.local.json         # Configurações locais (gitignored)
└── hooks/                      # Scripts de hooks
    └── format.sh

CLAUDE.md                       # Instruções do projeto (versionado)
.claude.local.md                # Notas locais (gitignored)
```

---

## 13. Modelos disponíveis

| Alias | Modelo | Uso indicado |
|---|---|---|
| `opus` | claude-opus-4-6 | Tarefas complexas, arquitetura |
| `sonnet` | claude-sonnet-4-6 | Uso geral (padrão recomendado) |
| `haiku` | claude-haiku-4-5 | Tarefas rápidas e simples |

```bash
claude --model opus "Analisa a arquitetura do projeto"
claude --model haiku "Explica essa função"
```
