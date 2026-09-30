# AGENTS.md

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
├── CLAUDE.md               # Mesmo conteúdo deste arquivo, para o Claude Code
├── AGENTS.md               # This file
│
├── backend/                # Ferramentas de desenvolvimento backend
│   ├── Git.md              # Git version control reference
│   ├── Docker.md           # Docker and Docker Compose reference
│   ├── Maven.md            # Maven build tool reference (Java)
│   ├── Makefile.md         # Makefile automation reference
│   ├── Nginx.md            # Nginx web server and reverse proxy reference
│   ├── Homebrew.md         # Homebrew package manager reference
│   ├── SSH.md              # SSH keys, config, tunneling, SCP, SFTP
│   ├── Curl.md             # curl: HTTP requests, JSON, upload, auth, TLS, scripts
│   ├── Terminal.md         # Terminal, network, text processing, SSH, and shell reference
│   ├── CI-CD.md            # CI/CD with GitLab CI and Jenkins
│   └── VPS-Ubuntu.md       # Hostinger VPS on Ubuntu 24.04 LTS: setup, apt, ufw, Docker, systemd
│
├── banco-de-dados/         # SQL studies and database queries
│   ├── banco-dados.md      # Database notes (gitignored)
│   ├── MySQL.md            # MySQL database reference
│   ├── SQL-Select.md       # SELECT avançado: joins, window, CTE, UUID
│   ├── SQL-Dicas.md        # Dicas práticas: índices, EXPLAIN, transações, performance
│   ├── SQL-Funcoes-Variaveis.md  # Funções (string, número, data, condicionais) e variáveis
│   ├── PostgreSQL.md       # PostgreSQL reference: psql, DDL, JSONB, indexes, backup, tuning
│   ├── PostgreSQL-Vetorial.md    # pgvector: embeddings, HNSW/IVFFlat, hybrid search, RAG
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
│   ├── Codex.md             # Codex CLI reference
│   └── CodebaseMemory.md    # codebase-memory-mcp: grafo e análise estrutural de código
│
└── projetos/               # Projetos reais e documentação de trabalho
    ├── BI-SEAPREV.md       # Documentação BI SEAPREV
    ├── sjdh-pages/         # App Engine — site sjdh-pages
    └── ciptea_web/         # Clone independente do sistema CIPTEA Web (repo próprio)
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

**Codex.md** — A cheatsheet covering:
- CLI flags (model, effort, permissions, headless/scripting options)
- Slash commands (session, code review, model config, automation)
- Keyboard shortcuts
- Permission modes
- settings.json configuration and permission syntax
- AGENTS.md project instructions
- Hooks (events, exit codes, examples)
- Headless mode for scripts and CI
- Authentication and available models

**CodebaseMemory.md** — A cheatsheet covering:
- Como o codebase-memory-mcp indexa o repositório e constrói o grafo de código
- Integração MCP com Codex e comandos gerais do executável
- Indexação, status, buscas estruturais, traces, arquitetura e impacto
- Consultas Cypher-like, cobertura do índice, paginação e troubleshooting

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

**Curl.md** — A cheatsheet covering:
- Basic requests, flags, HTTP methods, headers, query strings and globbing
- Sending JSON, form data and multipart uploads; `--data-binary` vs `-d`
- Authentication (Basic, Bearer, API key, .netrc), cookies and sessions
- Downloads (resume, rate limit), redirects, proxy, TLS/mTLS, `--resolve`
- Timing/status metrics with `-w`, retry, exit codes and health-check scripts
- JSON with `jq`, other protocols (FTP/SFTP/SMTP), practical recipes and troubleshooting table

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

**VPS-Ubuntu.md** — A cheatsheet covering:
- Server reconnaissance (lsb_release, hostnamectl, resources, network)
- First access, sudo user creation, SSH key auth and sshd hardening (24.04 uses `ssh`, not `sshd`, and socket activation for port changes)
- APT package management, keyrings, lock troubleshooting, needrestart
- Essential packages table and Python PEP 668 (venv/pipx instead of global pip)
- UFW firewall + fail2ban, including the Docker-bypasses-UFW caveat
- Docker CE + Compose v2 install from the official repo, daemon.json log limits
- Day-to-day Docker/Compose operations, deploy via Git, disk cleanup, volume backup
- systemd services (including a Compose-backed unit), journalctl, log rotation
- Disk/memory/swap, processes, network and ports (ss, lsof, dig, netplan)
- Timezone/hostname/locale, cron and systemd timers, unattended-upgrades
- File transfer with scp/rsync, backup routine
- Troubleshooting table (symptom → diagnosis → fix) and a 10-step bootstrap for a fresh VPS

**SSH.md** — A cheatsheet covering:
- Basic connection, verbose/debug flags, remote command execution
- Key generation (Ed25519, RSA), distribution with ssh-copy-id, correct permissions
- ~/.ssh/config, SSH agent, multiplexing, known_hosts management
- SCP, SFTP, rsync over SSH
- Port forwarding (local, remote, dynamic/SOCKS) and ProxyJump/bastion
- sshd_config server-side settings, troubleshooting and practical scenarios

**CI-CD.md** — A cheatsheet covering:
- General CI/CD concepts (stages, jobs, runners, artifacts)
- GitLab CI: .gitlab-ci.yml, stages, rules, cache, environments, deploy
- Jenkins: Jenkinsfile (declarative), agents, credentials, shared libraries
- Step-by-step setup for both, plus a GitLab CI vs Jenkins comparison

**PostgreSQL.md** — A cheatsheet covering:
- Install (Homebrew, PGDG on Ubuntu, Docker), connection strings, .pgpass, psql meta-commands
- Databases, schemas, roles/permissions (including ALTER DEFAULT PRIVILEGES) and pg_hba.conf
- DDL, data types, IDENTITY vs SERIAL, constraints
- CRUD with RETURNING, ON CONFLICT upsert, UPDATE FROM, DELETE USING, DISTINCT ON, writable CTEs
- Dates, strings, arrays and JSONB (operators, jsonb_set, GIN indexes)
- Indexes (B-tree, GIN, BRIN, partial, expression, trigram, full-text, CONCURRENTLY)
- EXPLAIN/ANALYZE reading guide, transactions, isolation levels, locks, SKIP LOCKED
- Views, materialized views, PL/pgSQL functions and triggers
- pg_dump/pg_restore/pg_dumpall, VACUUM and autovacuum, pg_stat_activity, pg_stat_statements
- Tuning table (shared_buffers, work_mem, random_page_cost), extensions, Docker Compose with healthcheck
- MySQL → PostgreSQL equivalence table and a troubleshooting table

**PostgreSQL-Vetorial.md** — A cheatsheet covering:
- Vector search concepts (embeddings, dimensions, KNN/ANN, recall, RAG) and when pgvector is enough
- pgvector install (Docker image, PGDG package, Homebrew, source) and CREATE EXTENSION
- Types: vector, halfvec, bit, sparsevec, with size and index limits
- Distance operators (<=>, <->, <#>, <+>, <~>, <%>) and similarity queries with thresholds
- HNSW vs IVFFlat: parameters, trade-offs table, faster builds, ef_search/probes tuning
- Filtered search: iterative scans (0.8+), partial indexes, overfetch pattern
- Hybrid search (tsvector + vector) with Reciprocal Rank Fusion
- Space reduction: halfvec, subvector/Matryoshka, binary quantization with rerank
- Python integration: psycopg 3, SQLAlchemy models, OpenAI and sentence-transformers
- Full RAG pipeline (chunking, ingestion, retrieval, prompt) and a pitfalls table

**Pandas.md** — A cheatsheet covering:
- Series and DataFrame, loading and saving data (CSV, Excel, SQL)
- Exploration, selection (loc/iloc), column creation, cleaning and null handling
- Sorting, groupby, merges, dates, strings, pivot/reshape
- A complete sales-analysis example and performance notes for large volumes

**Colab.md** — A cheatsheet covering:
- Loading CSVs in Google Colab (upload, Drive, URL)
- Exploration, cleaning, grouping and dates with Pandas
- Charts with Matplotlib and Seaborn, exporting results
- A complete step-by-step analysis and Colab-specific tips

**BPMN.md** — A cheatsheet covering:
- BPMN 2.0 fundamentals: events, activities, gateways, flows, pools and lanes
- Step-by-step method for modelling a process
- Two complete examples (vacation approval, support ticket)
- Common beginner mistakes, tooling and best practices

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

## Imported Claude Cowork project instructions
