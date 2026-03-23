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
RUN npm ci --only=production

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
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://postgres:senha@db:5432/minha_db
      - REDIS_URL=redis://cache:6379
    depends_on:
      - db
      - cache

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: minha_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: senha
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

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
docker system prune -a                 # Remover tudo (incluindo imagens em uso)
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
