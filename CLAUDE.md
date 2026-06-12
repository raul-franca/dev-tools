# CLAUDE.md

## Regras de Commit

Todos os commits devem ser escritos em **português do Brasil** e conter detalhes suficientes para entender a mudança sem precisar ler o diff:

- **Título:** resumo claro e direto do que foi feito (ex: `feat: adiciona validação de env vars obrigatórias`)
- **Corpo obrigatório:** explicar o quê, por quê e o impacto da mudança
- **Formato:**
  ```
  <tipo>: <resumo em pt-br>

  - O que mudou e onde
  - Por que a mudança foi necessária
  - Impacto ou comportamento anterior vs novo
  ```
- **Tipos permitidos:** `feat`, `fix`, `refactor`, `docs`, `chore`, `test`
- Nunca usar mensagens genéricas como "ajustes", "correções", "update" sem contexto

## Project Overview

This is a documentation repository containing cheatsheets for backend development on macOS. All content is written in Portuguese.

## Repository Structure

```
dev-tools/
├── README.md               # Index linking to all cheatsheets
├── CLAUDE.md               # This file
│
├── backend/                # Ferramentas de desenvolvimento backend
│   ├── Git.md              # Git version control reference
│   ├── Docker.md           # Docker and Docker Compose reference
│   ├── Maven.md            # Maven build tool reference (Java)
│   ├── Makefile.md         # Makefile automation reference
│   ├── Nginx.md            # Nginx web server and reverse proxy reference
│   ├── Homebrew.md         # Homebrew package manager reference
│   ├── SSH.md              # SSH keys, config, tunneling, SCP, SFTP
│   ├── Terminal.md         # Terminal, network, SSH, and shell reference
│   └── CI-CD.md            # CI/CD with GitLab CI and Jenkins
│
├── banco-de-dados/         # SQL studies and database queries
│   ├── banco-dados.md      # Database notes (gitignored)
│   ├── MySQL.md            # MySQL database reference
│   ├── SQL-Select.md       # SELECT avançado: joins, window, CTE, UUID
│   ├── SQL-Dicas.md        # Dicas práticas: índices, EXPLAIN, transações, performance
│   ├── SQL-Funcoes-Variaveis.md  # Funções (string, número, data, condicionais) e variáveis
│   └── Selects/            # SQL SELECT query examples
│       └── relatorios.sql  # Report queries
│
├── dados/                  # Python e análise de dados
│   ├── Pandas.md           # Pandas Python: Series, DataFrame, cleaning, groupby, merge, dates
│   └── Colab.md            # Google Colab + Pandas reference
│
├── documentacao/           # Documentação e diagramas
│   ├── Markdown.md         # Markdown syntax reference (CommonMark + GFM)
│   ├── Mermaid.md          # Mermaid diagram reference
│   └── BPMN.md             # BPMN 2.0 process mapping reference
│
├── ia/                     # Ferramentas de IA
│   └── ClaudeCode.md       # Claude Code CLI reference
│
└── projetos/               # Projetos reais e documentação de trabalho
    ├── BI-SEAPREV.md       # Documentação BI SEAPREV
    └── sjdh-pages/         # App Engine — site sjdh-pages
```

## Content

**Homebrew.md** — A cheatsheet covering:
- General Homebrew commands (install, update, upgrade, cleanup)
- Backend development tools: Java (Temurin), Node.js, PostgreSQL, MySQL, Redis, Docker, Kubernetes
- Service management (start/stop/restart via `brew services`)
- Quick-start bootstrap workflow for a backend dev environment

**Git.md** — A cheatsheet covering:
- Configuration, clone, status, log
- Staging, commits, branches, merge, rebase
- Remote operations, stash, undo, tags
- Typical feature branch workflow

**Docker.md** — A cheatsheet covering:
- Container lifecycle (run, stop, exec, logs)
- Image management and Dockerfile examples (Node.js, Java)
- Docker Compose with a full backend example (app + PostgreSQL + Redis)
- Volumes, networks, registry, and cleanup

**MySQL.md** — A cheatsheet covering:
- Connection commands (local and remote)
- Database and table management (DDL)
- CRUD operations: SELECT, INSERT, UPDATE, DELETE
- Users, permissions, indexes, transactions, backup/restore, diagnostics

**Maven.md** — A cheatsheet covering:
- Build lifecycle (validate → compile → test → package → verify → install → deploy)
- Common flags (-DskipTests, -pl, -am, -T, -U)
- Dependency management and analysis
- Profiles, multi-module projects, versioning, Maven Wrapper (mvnw)
- pom.xml structure and dependency scopes

**Nginx.md** — A cheatsheet covering:
- Essential commands (macOS/Homebrew and Linux/systemd)
- Configuration paths (macOS vs Linux)
- nginx.conf structure
- Common configs: static files, reverse proxy, SPA, HTTPS/SSL, load balancer
- Location routing and priority, security headers, logs
- Step-by-step setup for macOS (dev) and Linux (production with Let's Encrypt)

**ClaudeCode.md** — A cheatsheet covering:
- CLI flags (model, effort, permissions, headless/scripting options)
- Slash commands (session, code review, model config, automation)
- Keyboard shortcuts
- Permission modes
- settings.json configuration and permission syntax
- CLAUDE.md project instructions
- Hooks (events, exit codes, examples)
- Headless mode for scripts and CI
- Authentication and available models

**Makefile.md** — A cheatsheet covering:
- Rule structure (targets, dependencies, commands)
- .PHONY targets, variables (=, :=, ?=), shell execution
- Suppressing output (@), ignoring errors (-), multiline commands
- Conditionals (ifeq/else/endif)
- Auto-generated help target
- Full real-world examples: Java/Spring Boot and Node.js projects

**Markdown.md** — A cheatsheet covering:
- Headings, text formatting (bold, italic, strikethrough, code)
- Lists (unordered, ordered, task lists)
- Links, images, code blocks with syntax highlighting
- Tables with alignment, horizontal rules, line breaks
- HTML inline, escape characters, footnotes
- GitHub Flavored Markdown: alerts/callouts (NOTE, TIP, WARNING, CAUTION), emojis
- Best practices

**Mermaid.md** — A cheatsheet covering:
- Flowchart (directions, node shapes, arrow types, subgraphs)
- Sequence diagram (participants, arrow types, loops, alt/else)
- Class diagram (UML relationships, visibility modifiers)
- Entity-Relationship (ER) diagram with cardinalities
- State diagram, Gantt chart, pie chart, user journey
- Mindmap and Timeline
- Themes, node styles, and usage tips (GitHub, VS Code, CLI, playground)

**Terminal.md** — A cheatsheet covering:
- Network inspection and port management
- Process management
- File/directory operations
- SSH key generation and config
- Environment variables, clipboard, history shortcuts

**banco-de-dados/** — A folder for SQL studies and database work:
- `banco-dados.md` — personal database notes (gitignored, not tracked)
- `Selects/relatorios.sql` — SQL SELECT queries for reports
- `SQL-Select.md` — advanced SELECT: joins, window functions, CTE, subselects, UUID, deduplication
- `SQL-Dicas.md` — practical SQL tips: indexes, EXPLAIN, transactions, performance, security
- `SQL-Funcoes-Variaveis.md` — A cheatsheet covering:
  - User variables (`@var`) and local variables (`DECLARE`) in stored procedures
  - String functions: CONCAT, TRIM, SUBSTRING, REPLACE, LPAD, LOCATE, etc.
  - Numeric functions: ROUND, FLOOR, CEIL, ABS, MOD, RAND, GREATEST, etc.
  - Date/time functions: NOW, DATE_FORMAT, DATE_ADD, DATEDIFF, STR_TO_DATE, etc.
  - Conditional functions: IF, IFNULL, NULLIF, COALESCE, CASE (simple and searched)
  - Aggregation functions: COUNT, SUM, AVG, GROUP_CONCAT, HAVING, pivot with CASE
  - User-defined stored functions (CPF formatting, age calculation, progressive discount)
  - Stored procedures with IN/OUT/INOUT parameters and transactions

## Conventions

- Documentation language: Portuguese
- Format: Markdown with code blocks for commands
- No build system, no application code — documentation only

## Common Tasks

**Adding a new cheatsheet:**
1. Create a new `.md` file inside the relevant folder (`backend/`, `dados/`, `documentacao/`, etc.)
2. Add a link to it in `README.md` under the correct section
3. Add an entry to this file under Repository Structure and Content

**Editing existing docs:**
- Edit the relevant `.md` file directly
- Keep commands accurate and tested on macOS with the current Homebrew version
