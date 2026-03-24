# Nginx — Cheatsheet e Guia de Configuração

Referência de comandos e configuração do Nginx no macOS e Linux.

> **Instalação (macOS):** `brew install nginx`

---

## 1. Comandos essenciais

```bash
# macOS (Homebrew)
brew services start nginx        # Iniciar Nginx
brew services stop nginx         # Parar Nginx
brew services restart nginx      # Reiniciar Nginx

# Linux (systemd)
sudo systemctl start nginx       # Iniciar
sudo systemctl stop nginx        # Parar
sudo systemctl restart nginx     # Reiniciar (interrompe brevemente)
sudo systemctl reload nginx      # Recarregar config sem interromper conexões
sudo systemctl enable nginx      # Iniciar automaticamente com o sistema
sudo systemctl status nginx      # Ver status do serviço
```

```bash
# Comandos diretos (macOS e Linux)
nginx -t                         # Testar configuração (sem reiniciar)
nginx -T                         # Testar e exibir config completa
nginx -s reload                  # Recarregar configuração
nginx -s stop                    # Parar imediatamente
nginx -s quit                    # Parar após finalizar conexões ativas
nginx -v                         # Ver versão
nginx -V                         # Ver versão + módulos compilados
```

---

## 2. Caminhos importantes

| Recurso | macOS (Homebrew) | Linux |
|---|---|---|
| Config principal | `/opt/homebrew/etc/nginx/nginx.conf` | `/etc/nginx/nginx.conf` |
| Sites disponíveis | `/opt/homebrew/etc/nginx/servers/` | `/etc/nginx/sites-available/` |
| Sites ativos | — | `/etc/nginx/sites-enabled/` |
| Logs de acesso | `/opt/homebrew/var/log/nginx/access.log` | `/var/log/nginx/access.log` |
| Logs de erro | `/opt/homebrew/var/log/nginx/error.log` | `/var/log/nginx/error.log` |
| Raiz padrão | `/opt/homebrew/var/www/` | `/var/www/html/` |

---

## 3. Estrutura do nginx.conf

```nginx
# Configuração global
worker_processes auto;           # Número de processos (auto = núcleos da CPU)

events {
    worker_connections 1024;     # Conexões simultâneas por worker
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout 65;

    # Habilitar compressão gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    # Incluir arquivos de sites
    include servers/*.conf;      # macOS
    # include /etc/nginx/sites-enabled/*;  # Linux
}
```

---

## 4. Configurações comuns

### Servidor de arquivos estáticos

```nginx
server {
    listen 80;
    server_name meusite.com www.meusite.com;

    root /var/www/meusite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Proxy reverso (API / aplicação backend)

```nginx
server {
    listen 80;
    server_name api.meusite.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SPA (React, Vue, Angular) com proxy de API

```nginx
server {
    listen 80;
    server_name meusite.com;

    root /var/www/meusite/dist;
    index index.html;

    # Rotas do frontend (SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy para API backend
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### HTTPS com SSL (Let's Encrypt)

```nginx
server {
    listen 80;
    server_name meusite.com www.meusite.com;

    # Redirecionar HTTP → HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name meusite.com www.meusite.com;

    ssl_certificate     /etc/letsencrypt/live/meusite.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/meusite.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    root /var/www/meusite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Load balancer (múltiplos backends)

```nginx
upstream minha_app {
    server localhost:8080;
    server localhost:8081;
    server localhost:8082;
    # Algoritmos disponíveis: round-robin (padrão), least_conn, ip_hash
    least_conn;
}

server {
    listen 80;
    server_name meusite.com;

    location / {
        proxy_pass http://minha_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 5. Locations — roteamento

```nginx
# Exato
location = /favicon.ico { ... }

# Prefixo (padrão)
location /api/ { ... }

# Regex (case sensitive)
location ~ \.php$ { ... }

# Regex (case insensitive)
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ { ... }

# Prefixo prioritário (não usa regex depois)
location ^~ /static/ { ... }
```

### Prioridade de location (do maior para menor)

```
1. location = /exact         (exato)
2. location ^~ /prefix       (prefixo prioritário)
3. location ~ regex          (regex case sensitive)
4. location ~* regex         (regex case insensitive)
5. location /prefix          (prefixo comum)
```

---

## 6. Headers e segurança

```nginx
server {
    # Headers de segurança recomendados
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Cache de arquivos estáticos
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Esconder versão do Nginx
    server_tokens off;
}
```

---

## 7. Logs

```bash
# Monitorar logs em tempo real
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Filtrar erros
grep "error" /var/log/nginx/error.log

# Ver últimas 100 linhas
tail -n 100 /var/log/nginx/access.log
```

Formato padrão do access.log:
```
IP - - [data] "método URI protocolo" status bytes "referrer" "user-agent"
```

---

## 8. Passo a passo — Setup completo no macOS (desenvolvimento)

### 1. Instalar

```bash
brew install nginx
```

### 2. Verificar instalação

```bash
nginx -v
nginx -t
```

### 3. Criar configuração para seu projeto

```bash
# Criar arquivo de config
touch /opt/homebrew/etc/nginx/servers/meusite.conf
```

```nginx
# /opt/homebrew/etc/nginx/servers/meusite.conf
server {
    listen 8090;
    server_name localhost;

    root /Users/seu-usuario/projetos/meusite/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. Testar e iniciar

```bash
nginx -t                         # Testar configuração
brew services start nginx        # Iniciar Nginx
```

### 5. Acessar

```
http://localhost:8090
```

---

## 9. Passo a passo — Deploy em servidor Linux (produção)

### 1. Instalar

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo dnf install nginx
```

### 2. Configurar firewall

```bash
sudo ufw allow 'Nginx Full'      # HTTP + HTTPS
sudo ufw allow 'Nginx HTTP'      # Apenas HTTP
sudo ufw status
```

### 3. Criar configuração do site

```bash
sudo nano /etc/nginx/sites-available/meusite.com
```

```nginx
server {
    listen 80;
    server_name meusite.com www.meusite.com;

    root /var/www/meusite.com;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### 4. Ativar o site

```bash
# Criar symlink para sites-enabled
sudo ln -s /etc/nginx/sites-available/meusite.com /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

### 5. Configurar HTTPS com Let's Encrypt

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx

# Obter certificado (preenche o Nginx automaticamente)
sudo certbot --nginx -d meusite.com -d www.meusite.com

# Renovação automática já configurada via cron
sudo certbot renew --dry-run    # Testar renovação
```

### 6. Verificar

```bash
sudo systemctl status nginx
curl -I https://meusite.com
```

---

## 10. Troubleshooting

```bash
# Testar configuração antes de aplicar
nginx -t

# Ver logs de erro em tempo real
tail -f /var/log/nginx/error.log

# Ver processo rodando
ps aux | grep nginx

# Verificar porta em uso
lsof -i :80
lsof -i :443

# Checar permissões do diretório root
ls -la /var/www/meusite.com

# Permissão correta para o Nginx ler os arquivos
sudo chown -R www-data:www-data /var/www/meusite.com  # Linux
chmod -R 755 /var/www/meusite.com
```

### Erros comuns

| Erro | Causa provável | Solução |
|---|---|---|
| `403 Forbidden` | Permissão negada nos arquivos | `chmod 755` no diretório |
| `502 Bad Gateway` | Backend não está rodando | Verificar se a aplicação está ativa |
| `404 Not Found` | Arquivo não encontrado / config errada | Verificar `root` e `try_files` |
| `bind() failed` | Porta já em uso | `lsof -i :80` para ver o processo |
| Config não aplica | Nginx não recarregado | `nginx -s reload` ou `systemctl reload nginx` |
