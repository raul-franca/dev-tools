# CLAUDE.md

## Project Overview

This is a documentation repository containing Homebrew cheatsheets for macOS development environment setup. All content is written in Portuguese.

## Repository Structure

```
dev-tools/
├── README.md       # Index linking to cheatsheets
├── Homebrew.md     # Comprehensive Homebrew command reference
├── Git.md          # Git commands reference
├── Docker.md       # Docker and Docker Compose reference
├── terminal.md     # Terminal, network, SSH, and shell reference
└── CLAUDE.md       # This file
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

**terminal.md** — A cheatsheet covering:
- Network inspection and port management
- Process management
- File/directory operations
- SSH key generation and config
- Environment variables, clipboard, history shortcuts

## Conventions

- Documentation language: Portuguese
- Format: Markdown with code blocks for commands
- No build system, no application code — documentation only

## Common Tasks

**Adding a new cheatsheet:**
1. Create a new `.md` file in the root directory
2. Add a link to it in `README.md`

**Editing existing docs:**
- Edit the relevant `.md` file directly
- Keep commands accurate and tested on macOS with the current Homebrew version
