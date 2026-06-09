
# Homebrew Básico + Backend (macOS)

Cheatsheet de comandos do Homebrew para uso **geral** e para desenvolvimento **backend** no macOS.

---

## 1. Homebrew Básico

### 1.1 Informações e ajuda

```bash
brew --version       # Ver versão do Homebrew
brew help            # Ajuda geral
brew help install    # Ajuda de um comando específico
brew doctor          # Verificar se há problemas na instalação
```

### 1.2 Instalar, remover e atualizar pacotes

```bash
brew search nome     # Buscar pacote (fórmula ou cask)
brew info nome       # Ver detalhes de um pacote

brew install nome    # Instalar pacote de linha de comando
brew uninstall nome  # Remover pacote

brew install --cask nome-app    # Instalar app (GUI)
brew uninstall --cask nome-app  # Remover app (GUI)

brew update          # Atualizar Homebrew (índices)
brew upgrade         # Atualizar todos os pacotes
brew upgrade nome    # Atualizar apenas um pacote
```

### 1.3 Listar e limpar

```bash
brew list            # Listar fórmulas instaladas
brew list --cask     # Listar apps (casks) instalados

brew cleanup         # Remover versões antigas / lixo
```

### 1.4 Serviços (bancos, Redis, etc.)

```bash
brew services list           # Ver serviços gerenciados pelo Homebrew
brew services start nome     # Iniciar serviço
brew services stop nome      # Parar serviço
brew services restart nome   # Reiniciar serviço
```

### 1.5 Taps (repositórios extras)

```bash
brew tap                     # Listar taps
brew tap user/repo           # Adicionar tap
brew untap user/repo         # Remover tap
```

---

## 2. Homebrew para Backend

Cheatsheet rápido de comandos do Homebrew para desenvolvimento **backend** no macOS: Java, Node.js, bancos de dados, cache, Docker e Kubernetes.

---

### 2.1 Java (JDK – Temurin)

Instalar o Java Temurin mais recente (OpenJDK recomendado):

```bash
brew install --cask temurin
```

Instalar uma versão específica (exemplos: 17, 21, 25):

```bash
# Ver opções disponíveis
brew search temurin

# Instalar versões específicas
brew install --cask temurin@17
brew install --cask temurin@21
brew install --cask temurin@25
```

Ver onde os JDKs foram instalados:

```bash
ls /Library/Java/JavaVirtualMachines
```

---

### 2.2 Node.js e ferramentas do ecossistema JS

Instalar Node LTS via Homebrew:

```bash
brew install node
```

Instalar gerenciadores de pacotes:

```bash
brew install yarn
brew install pnpm
```

Ver versões:

```bash
node -v
npm -v
yarn -v
pnpm -v
```

---

### 2.3 Bancos de dados (PostgreSQL e MySQL)

#### PostgreSQL

Instalar PostgreSQL:

```bash
brew install postgresql
```

Gerenciar como serviço (sobe com o login no macOS):

```bash
# Iniciar
brew services start postgresql

# Parar
brew services stop postgresql

# Reiniciar
brew services restart postgresql
```

Ver status:

```bash
brew services list
```

Conectar via CLI:

```bash
psql postgres
```

#### MySQL

Instalar MySQL:

```bash
brew install mysql
```

Gerenciar como serviço:

```bash
brew services start mysql
brew services stop mysql
brew services restart mysql
```

---

### 2.4 Cache / Mensageria (Redis)

Instalar Redis:

```bash
brew install redis
```

Rodar Redis como serviço:

```bash
brew services start redis
brew services stop redis
brew services restart redis
```

Ver status geral:

```bash
brew services list
```

Observação: algumas distribuições mais completas do Redis (ex.: Redis Stack) podem ser instaladas via cask/tap específico, conforme a documentação oficial do Redis.

---

### 2.5 Docker e Docker Desktop

Instalar Docker Desktop via Homebrew (GUI + CLI):

```bash
brew install --cask docker
# ou
brew install --cask docker-desktop
```

Depois da instalação:

1. Abrir o app “Docker”/“Docker Desktop” pelo Launchpad.
2. Esperar o daemon iniciar (ícone da baleia ficar estável).
3. Testar no terminal:

```bash
docker version
docker run hello-world
```

---

### 2.6 Kubernetes (kubectl, k9s, Helm)

Instalar `kubectl` (CLI do Kubernetes):

```bash
brew install kubectl
# ou (algumas docs antigas)
brew install kubernetes-cli
```

Testar versão:

```bash
kubectl version --client
```

Extras úteis para dev backend:

```bash
# TUI para observar cluster
brew install k9s

# Helm (gerenciador de charts)
brew install helm
```

Para comandos diários de `kubectl`, é só usar esse cheatsheet em conjunto com o oficial do Kubernetes.

---

### 2.7 Workflow sugerido para setup de ambiente backend

Exemplo de “bootstrap” rápido de ambiente backend com Homebrew:

```bash
# Atualizar Homebrew
brew update && brew upgrade

# Java
brew install --cask temurin@17

# Node + Yarn
brew install node
brew install yarn

# Bancos
brew install postgresql
brew install mysql

# Cache
brew install redis

# Docker Desktop
brew install --cask docker-desktop

# Kubernetes tools
brew install kubectl
brew install k9s
brew install helm

# Subir serviços básicos
brew services start postgresql
brew services start redis
```
