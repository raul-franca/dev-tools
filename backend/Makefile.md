# Makefile — Cheatsheet

Referência de sintaxe e uso do Makefile para automação de tarefas em projetos de desenvolvimento.

> **O que é:** Um `Makefile` é um arquivo que define "atalhos" para comandos longos ou repetitivos.
> Você escreve uma vez e chama com `make nome-do-atalho`.

---

## 1. Estrutura básica

Um Makefile é composto por **regras**. Cada regra tem:

```
alvo: dependências
	comando
	comando
```

- **alvo** → o nome que você vai chamar com `make`
- **dependências** → outros alvos que precisam rodar antes (opcional)
- **comando** → o shell command que será executado

> **ATENÇÃO:** A indentação dos comandos **obrigatoriamente usa TAB**, nunca espaços.
> Esse é o erro mais comum em Makefiles.

### Exemplo mínimo

```makefile
build:
	mvn clean package

run:
	java -jar target/app.jar

test:
	mvn test
```

```bash
make build   # executa: mvn clean package
make run     # executa: java -jar target/app.jar
make test    # executa: mvn test
```

---

## 2. Dependências entre alvos

Você pode dizer que um alvo depende de outro:

```makefile
build:
	mvn clean package

run: build
	java -jar target/app.jar
```

```bash
make run
# 1. executa "build" primeiro
# 2. depois executa "run"
```

Múltiplas dependências:

```makefile
deploy: test build
	./scripts/deploy.sh
```

> `make deploy` vai executar `test`, depois `build`, depois o deploy.

---

## 3. Alvo padrão

O primeiro alvo do arquivo é executado quando você roda `make` sem argumentos:

```makefile
# Este é o alvo padrão (o primeiro)
all: build test

build:
	mvn clean package

test:
	mvn test
```

```bash
make       # executa "all" automaticamente
make build # executa somente "build"
```

Convenção: nomear o alvo padrão de `all`.

---

## 4. Alvos falsos (.PHONY)

Por padrão, o Make verifica se existe um **arquivo** com o nome do alvo. Se existir,
ele pode pular a execução achando que o alvo já está "feito".

Use `.PHONY` para dizer que um alvo é sempre um comando, nunca um arquivo:

```makefile
.PHONY: build run test clean

build:
	mvn clean package

clean:
	rm -rf target/
```

> Boa prática: declare `.PHONY` para todo alvo que não gera um arquivo com esse nome.

---

## 5. Variáveis

Defina variáveis para evitar repetição:

```makefile
APP_NAME = minha-app
JAR = target/$(APP_NAME).jar
JAVA = java -jar

build:
	mvn clean package -Dapp.name=$(APP_NAME)

run:
	$(JAVA) $(JAR)
```

### Tipos de variável

```makefile
# Expansão simples: avaliado uma vez na definição
APP := minha-app

# Expansão recursiva: avaliado toda vez que é usado
VERSION = $(shell git describe --tags)

# Valor padrão: usa valor externo se passado, senão usa o padrão
ENV ?= development
```

### Passando variáveis na linha de comando

```bash
make build ENV=production
make deploy VERSION=2.0.0
```

---

## 6. Comandos shell no Makefile

### Executar e capturar resultado

```makefile
GIT_BRANCH := $(shell git branch --show-current)
DATE       := $(shell date +%Y-%m-%d)

info:
	@echo "Branch: $(GIT_BRANCH)"
	@echo "Data:   $(DATE)"
```

### Suprimir a exibição do comando

Por padrão, o Make imprime o comando antes de executar. Use `@` para suprimir:

```makefile
build:
	@echo "Compilando..."    # imprime só a mensagem, não o "echo" em si
	@mvn clean package -q   # executa silenciosamente
```

Sem `@`:
```
$ make build
echo "Compilando..."
Compilando...
mvn clean package -q
```

Com `@`:
```
$ make build
Compilando...
```

---

## 7. Ignorar erros

Por padrão, se um comando falhar (código de saída != 0), o Make para tudo.
Use `-` antes do comando para ignorar erros:

```makefile
clean:
	-rm -rf target/      # não falha se target/ não existir
	-docker stop app     # não falha se o container não estiver rodando
```

---

## 8. Comandos multilinha

Cada linha de comando roda em um **shell separado**. Para manter estado entre linhas, use `;` ou `\`:

```makefile
# ERRADO — cada linha é um shell diferente, o cd não persiste
deploy:
	cd scripts/
	./deploy.sh           # roda no diretório original, não em scripts/

# CORRETO — tudo na mesma linha com ;
deploy:
	cd scripts/ && ./deploy.sh

# CORRETO — continuação com \
build:
	mvn clean package \
		-DskipTests \
		-Pprod
```

---

## 9. Condicionais

```makefile
ENV ?= development

run:
ifeq ($(ENV), production)
	@echo "Iniciando em modo produção"
	java -jar -Xmx2g target/app.jar
else
	@echo "Iniciando em modo desenvolvimento"
	java -jar target/app.jar
endif
```

```bash
make run             # usa ENV=development (padrão)
make run ENV=production
```

---

## 10. Exibir ajuda automaticamente

Convenção muito usada: adicionar comentários `##` e um alvo `help` que os lista:

```makefile
.PHONY: help build run test clean

help: ## Exibe esta mensagem de ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Compila o projeto
	mvn clean package

run: ## Inicia a aplicação
	java -jar target/app.jar

test: ## Executa os testes
	mvn test

clean: ## Remove arquivos gerados
	rm -rf target/
```

```bash
$ make help
  build           Compila o projeto
  run             Inicia a aplicação
  test            Executa os testes
  clean           Remove arquivos gerados
```

---

## 11. Exemplo real — projeto Java/Spring Boot

```makefile
.PHONY: all build run test clean docker-build docker-up docker-down help

APP     = minha-api
VERSION = $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
JAR     = target/$(APP).jar
ENV    ?= development

all: build ## Build padrão

help: ## Exibe ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compila e empacota (sem testes)
	@echo "Compilando $(APP) v$(VERSION)..."
	@mvn clean package -DskipTests -q

build-full: ## Compila, testa e empacota
	mvn clean verify

run: build ## Compila e inicia a aplicação
	java -jar -Dspring.profiles.active=$(ENV) $(JAR)

test: ## Executa os testes unitários
	mvn test

test-it: ## Executa os testes de integração
	mvn verify -Pfailsafe

clean: ## Remove arquivos gerados
	@mvn clean -q
	@echo "Limpeza concluída."

docker-build: build ## Gera a imagem Docker
	docker build -t $(APP):$(VERSION) .
	docker tag $(APP):$(VERSION) $(APP):latest

docker-up: ## Sobe o ambiente com Docker Compose
	docker compose up -d

docker-down: ## Derruba o ambiente Docker Compose
	docker compose down

logs: ## Exibe logs do container
	docker compose logs -f $(APP)

info: ## Exibe informações do projeto
	@echo "App:     $(APP)"
	@echo "Versão:  $(VERSION)"
	@echo "Env:     $(ENV)"
	@echo "JAR:     $(JAR)"
```

---

## 12. Exemplo real — projeto Node.js

```makefile
.PHONY: install dev build test lint clean help

NODE_ENV ?= development

help: ## Exibe ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Instala dependências
	npm install

dev: ## Inicia em modo desenvolvimento
	npm run dev

build: ## Gera o bundle de produção
	npm run build

test: ## Executa os testes
	npm test

lint: ## Verifica o código com ESLint
	npm run lint

lint-fix: ## Corrige erros de lint automaticamente
	npm run lint -- --fix

clean: ## Remove node_modules e dist/
	-rm -rf node_modules dist .next
```

---

## 13. Referência rápida

| Sintaxe | Significado |
|---|---|
| `alvo: dep1 dep2` | Alvo com dependências |
| `.PHONY: alvo` | Alvo que não gera arquivo |
| `VAR = valor` | Variável com expansão recursiva |
| `VAR := valor` | Variável com expansão simples |
| `VAR ?= valor` | Variável com valor padrão |
| `$(VAR)` | Usar variável |
| `$(shell cmd)` | Executar comando shell e capturar saída |
| `@comando` | Executar sem imprimir o comando |
| `-comando` | Executar ignorando erros |
| `ifeq / else / endif` | Condicional |
| `\` no fim da linha | Continuar linha |

### Comandos úteis

```bash
make               # executa o alvo padrão (primeiro do arquivo)
make alvo          # executa um alvo específico
make alvo VAR=val  # executa passando variável
make -n alvo       # simulação: mostra o que seria executado, sem executar
make -f outro.mk   # usa um Makefile com nome diferente
make --dry-run     # mesmo que -n
```
