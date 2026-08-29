# Docker — Cheatsheet

Referência de comandos Docker para desenvolvimento backend no macOS.

> **Pré-requisito:** Docker Desktop instalado (`brew install --cask docker`)

---

## 1. Containers

### Criar e executar

```bash
docker run imagem                      # Executar container
docker run -it imagem bash             # Executar com terminal interativo
docker run -d imagem                   # Executar em background (detached)
docker run --name meu-app imagem       # Executar com nome personalizado
docker run --rm imagem                 # Remover container ao sair

# Mapeamento de portas e volumes
docker run -p 8080:80 imagem           # Porta host:container
docker run -v $(pwd):/app imagem       # Volume: diretório atual → /app no container
docker run -e VAR=valor imagem         # Passar variável de ambiente
```

### Gerenciar containers

```bash
docker ps                              # Listar containers em execução
docker ps -a                           # Listar todos os containers (incluindo parados)
docker stop nome_ou_id                 # Parar container (graceful)
docker kill nome_ou_id                 # Forçar parada do container
docker start nome_ou_id                # Iniciar container parado
docker restart nome_ou_id             # Reiniciar container
docker rm nome_ou_id                   # Remover container parado
docker rm -f nome_ou_id               # Forçar remoção (mesmo em execução)
```

### Inspecionar e acessar

```bash
docker logs nome_ou_id                 # Ver logs do container
docker logs -f nome_ou_id             # Logs em tempo real (follow)
docker logs --tail 50 nome_ou_id      # Últimas 50 linhas de log
docker exec -it nome_ou_id bash       # Abrir terminal dentro do container
docker exec -it nome_ou_id sh         # Usar sh se bash não disponível
docker inspect nome_ou_id             # Ver todas as configurações do container
docker stats                           # Monitor de uso de recursos (CPU/RAM)
```

---

## 2. Imagens

```bash
docker images                          # Listar imagens locais
docker pull imagem:tag                 # Baixar imagem do registry
docker push imagem:tag                 # Enviar imagem para registry
docker rmi imagem                      # Remover imagem
docker tag imagem novo:tag             # Criar alias/tag para imagem
docker history imagem                  # Ver camadas da imagem
```

### Build de imagem

```bash
docker build -t minha-app .            # Build com tag a partir do Dockerfile atual
docker build -t minha-app:1.0 .        # Build com versão
docker build -f Dockerfile.prod .      # Build usando Dockerfile específico
```

---

## 3. Dockerfile básico

```dockerfile
# Exemplo para aplicação Node.js
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 3000

CMD ["node", "src/index.js"]
```

```dockerfile
# Exemplo para aplicação Java (Spring Boot)
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

### Multi-stage build — imagem final pequena

Compila em uma imagem com todas as ferramentas e copia só o resultado para uma imagem enxuta. Reduz de centenas de MB para dezenas.

```dockerfile
# Etapa 1 — build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Etapa 2 — runtime (só o necessário para rodar)
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/dist ./dist
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
USER node
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

```dockerfile
# Python (FastAPI) com multi-stage
FROM python:3.12-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=build /install /usr/local
COPY . .
RUN useradd -m app && chown -R app:app /app
USER app
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### .dockerignore

Sem ele, o `docker build` envia `node_modules`, `.git` e `.venv` inteiros para o daemon — build lento e imagem inchada. **Sempre crie**, no mesmo nível do Dockerfile:

```
.git
.gitignore
node_modules
.venv
__pycache__
*.pyc
.env
.env.*
dist
build
target
*.log
.DS_Store
README.md
```

### Boas práticas de Dockerfile

- Copie primeiro `package.json` / `requirements.txt` e só depois o código: o cache de camadas evita reinstalar dependências a cada build.
- Fixe versões de imagem base (`node:20-alpine`, não `node:latest`) — build reprodutível.
- Rode como usuário não-root (`USER node`, `USER app`).
- Uma responsabilidade por container; nada de app + banco na mesma imagem.
- Segredos entram por variável de ambiente ou secret, **nunca** com `COPY .env` ou `ENV SENHA=`.

---

## 4. Docker Compose

### Comandos principais

```bash
docker compose up                      # Subir todos os serviços
docker compose up -d                   # Subir em background
docker compose up --build              # Subir reconstruindo imagens
docker compose down                    # Parar e remover containers
docker compose down -v                 # Parar, remover containers e volumes
docker compose ps                      # Ver status dos serviços
docker compose logs                    # Ver logs de todos os serviços
docker compose logs -f nome-servico    # Logs em tempo real de um serviço
docker compose exec nome-servico bash  # Terminal em um serviço específico
docker compose restart nome-servico    # Reiniciar serviço específico
```

### Exemplo de `docker-compose.yml`

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"                    # única porta pública
    environment:
      DATABASE_URL: postgresql://app:${POSTGRES_PASSWORD}@db:5432/minha_db
      REDIS_URL: redis://cache:6379
    depends_on:
      db:
        condition: service_healthy     # espera o banco ficar PRONTO, não só iniciar
      cache:
        condition: service_started
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: minha_db
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:5432:5432"          # só o host acessa (ver aviso abaixo)
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d minha_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    ports:
      - "127.0.0.1:6379:6379"
    restart: unless-stopped

volumes:
  postgres_data:
```

As variáveis `${...}` vêm de um arquivo `.env` ao lado do `docker-compose.yml`:

```bash
# .env  (nunca versionar — coloque no .gitignore)
POSTGRES_PASSWORD=uma-senha-forte
```

> [!CAUTION]
> **Docker ignora o firewall (UFW/iptables).** Publicar `-p 5432:5432` deixa o banco acessível pela internet mesmo com a porta "bloqueada" no UFW. Em servidor, publique serviços internos só no loopback (`127.0.0.1:5432:5432`) ou não publique porta nenhuma — containers na mesma rede do Compose já se enxergam pelo nome do serviço (`db:5432`).

### Comandos que faltam no dia a dia

```bash
docker compose up -d --build           # rebuild + subir
docker compose pull && docker compose up -d   # atualizar imagens de terceiros
docker compose config                  # validar e ver o arquivo já resolvido
docker compose down --remove-orphans   # remove serviços que saíram do arquivo
docker compose logs -f --tail 50       # logs de todos, últimas 50 linhas
docker compose exec -T db pg_dump -U app minha_db > backup.sql   # -T = sem TTY (scripts)
```

---

## 4.1. Healthcheck, restart e limites

```yaml
services:
  api:
    build: .
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s              # carência inicial durante o boot da app
    restart: unless-stopped          # sobe sozinho após reboot da VPS
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M               # evita que um container derrube o servidor
    logging:
      driver: json-file
      options:
        max-size: "10m"              # sem isso o log cresce até encher o disco
        max-file: "3"
```

| Política de `restart` | Comportamento |
|---|---|
| `no` (padrão) | Nunca reinicia |
| `on-failure` | Reinicia só se sair com erro |
| `unless-stopped` | Sempre, exceto se você parou manualmente — **melhor para servidor** |
| `always` | Sempre, mesmo após parada manual |

---

## 5. Volumes e Redes

### Volumes

```bash
docker volume ls                       # Listar volumes
docker volume create meu-volume        # Criar volume
docker volume rm meu-volume            # Remover volume
docker volume inspect meu-volume       # Inspecionar volume
docker volume prune                    # Remover volumes não utilizados
```

### Redes

```bash
docker network ls                      # Listar redes
docker network create minha-rede       # Criar rede
docker network rm minha-rede           # Remover rede
docker network inspect minha-rede      # Inspecionar rede
docker network connect minha-rede container  # Conectar container à rede
```

---

## 6. Limpeza

```bash
docker system prune                    # Remover containers parados, redes e imagens sem uso
docker system prune -a                 # Remover tudo que não está em uso por um container ativo
docker builder prune                   # Remover cache de build (costuma ser o que mais ocupa)
docker system prune --volumes          # Incluir volumes na limpeza
docker container prune                 # Remover só containers parados
docker image prune                     # Remover só imagens sem tag (dangling)
docker volume prune                    # Remover só volumes sem uso

docker system df                       # Ver uso de espaço em disco pelo Docker
```

---

## 7. Registry (Docker Hub / GHCR)

```bash
docker login                           # Login no Docker Hub
docker login ghcr.io -u usuario        # Login no GitHub Container Registry

# Enviar imagem para Docker Hub
docker tag minha-app usuario/minha-app:1.0
docker push usuario/minha-app:1.0

# Enviar para GHCR
docker tag minha-app ghcr.io/usuario/minha-app:1.0
docker push ghcr.io/usuario/minha-app:1.0
```

---

## Ver também

- [VPS-Ubuntu.md](VPS-Ubuntu.md) — instalar o Docker na VPS, deploy, limpeza de disco e backup de volumes
- [Nginx.md](Nginx.md) — proxy reverso na frente dos containers, com HTTPS
- [CI-CD.md](CI-CD.md) — build e push de imagens no pipeline
- [Makefile.md](Makefile.md) — encurtar os comandos de build e deploy
- [../banco-de-dados/PostgreSQL.md](../banco-de-dados/PostgreSQL.md) — Postgres em container, com healthcheck
