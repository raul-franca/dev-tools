# curl — Cheatsheet

Referência de curl para testar APIs, baixar/enviar arquivos, depurar HTTP/TLS e automatizar requisições.

> **Instalação (macOS):** já vem instalado. Versão mais nova: `brew install curl`

---

## 1. Requisição básica

```bash
curl https://api.exemplo.com                 # GET simples (corpo vai para stdout)
curl -s https://api.exemplo.com              # silencioso (sem barra de progresso)
curl -sS https://api.exemplo.com             # silencioso, mas mostra erros
curl -i https://api.exemplo.com              # inclui headers da resposta
curl -I https://api.exemplo.com              # só headers (método HEAD)
curl -v https://api.exemplo.com              # verbose: request + response + TLS
curl --trace-ascii - https://api.exemplo.com # dump completo de bytes trafegados
curl -L http://exemplo.com                   # segue redirecionamentos (301/302)
curl -m 10 https://api.exemplo.com           # timeout total de 10 s
curl --connect-timeout 5 https://exemplo.com # timeout só da conexão
curl -sS https://api.sjdh.pe.gov.br/api-portal/docs#/ | jq
```

### Flags mais usadas

| Flag | Significado |
|---|---|
| `-X MÉTODO` | Define o método HTTP (GET, POST, PUT, PATCH, DELETE) |
| `-H "K: V"` | Adiciona header |
| `-d dados` | Corpo da requisição (muda o método para POST) |
| `-o arquivo` | Salva a saída em `arquivo` |
| `-O` | Salva usando o nome do arquivo remoto |
| `-s` / `-S` | Silencioso / mostra erro mesmo em modo silencioso |
| `-i` / `-I` | Headers + corpo / só headers |
| `-v` | Verbose (debug) |
| `-L` | Segue redirects |
| `-k` | Ignora validação do certificado TLS (só em dev) |
| `-u user:senha` | Basic Auth |
| `-f` | Falha (exit ≠ 0) em respostas HTTP 4xx/5xx |
| `-w formato` | Imprime métricas/variáveis após a requisição |

---

## 2. Métodos HTTP

```bash
curl https://api.exemplo.com/users                       # GET
curl -X POST   https://api.exemplo.com/users -d '...'    # POST
curl -X PUT    https://api.exemplo.com/users/1 -d '...'  # PUT (substitui)
curl -X PATCH  https://api.exemplo.com/users/1 -d '...'  # PATCH (parcial)
curl -X DELETE https://api.exemplo.com/users/1           # DELETE
curl -X OPTIONS -i https://api.exemplo.com/users         # descobrir métodos/CORS
```

> **Dica:** `-d` já implica POST; não precisa de `-X POST`. Use `-X` só para os demais métodos. Nunca use `-X GET` com `-d` — para enviar parâmetros em GET use `-G` (veja seção 4).

---

## 3. Enviar dados (corpo)

### JSON

```bash
curl -X POST https://api.exemplo.com/users \
  -H "Content-Type: application/json" \
  -d '{"nome": "Raul", "email": "raul@exemplo.com"}'

# Atalho (curl ≥ 7.82): define Content-Type e Accept como JSON
curl --json '{"nome": "Raul"}' https://api.exemplo.com/users

# JSON a partir de arquivo
curl -X POST https://api.exemplo.com/users \
  -H "Content-Type: application/json" \
  -d @payload.json

# JSON via stdin (heredoc)
curl -X POST https://api.exemplo.com/users \
  -H "Content-Type: application/json" \
  -d @- <<'EOF'
{
  "nome": "Raul",
  "cargo": "Desenvolvedor"
}
EOF
```

### Formulário (`application/x-www-form-urlencoded`)

```bash
curl -X POST https://api.exemplo.com/login \
  -d "usuario=raul" \
  -d "senha=segredo"

# Com caracteres especiais: codifica o valor automaticamente
curl -X POST https://api.exemplo.com/busca \
  --data-urlencode "q=café com leite & pão"
```

### Upload de arquivo (`multipart/form-data`)

```bash
curl -F "arquivo=@relatorio.pdf" https://api.exemplo.com/upload
curl -F "arquivo=@foto.png;type=image/png" https://api.exemplo.com/upload
curl -F "arquivo=@doc.pdf" -F "titulo=Relatório" -F "ano=2026" https://api.exemplo.com/upload
curl -F "arquivos=@a.txt" -F "arquivos=@b.txt" https://api.exemplo.com/upload   # vários

# Upload binário puro (PUT)
curl -T backup.tar.gz https://servidor.com/backups/backup.tar.gz
curl -X POST --data-binary @imagem.png -H "Content-Type: image/png" https://api.exemplo.com/img
```

> **`-d` vs `--data-binary`:** `-d` remove quebras de linha do arquivo. Use `--data-binary @arquivo` para preservar o conteúdo byte a byte.

---

## 4. Query string e parâmetros

```bash
# URL com & precisa de aspas (senão o shell interpreta o &)
curl "https://api.exemplo.com/users?page=2&limit=50"

# -G transforma os -d em query string
curl -G https://api.exemplo.com/users \
  -d "page=2" \
  -d "limit=50"

curl -G https://api.exemplo.com/busca --data-urlencode "q=São Paulo"

# Globbing: várias URLs em uma linha
curl "https://api.exemplo.com/users/[1-5]"              # 1,2,3,4,5
curl "https://api.exemplo.com/{users,orders,products}"  # três endpoints
curl -g "https://api.exemplo.com/?filtro[]=a"           # -g desativa globbing ([] e {})
```

---

## 5. Headers

```bash
curl -H "Accept: application/json" https://api.exemplo.com
curl -H "Content-Type: application/json" -H "X-Api-Key: abc123" https://api.exemplo.com
curl -H "Accept-Language: pt-BR" https://api.exemplo.com
curl -H "Authorization:" https://api.exemplo.com        # remove um header padrão (valor vazio)
curl -H "X-Custom;" https://api.exemplo.com             # envia header com valor vazio

curl -A "Mozilla/5.0" https://exemplo.com               # User-Agent (--user-agent)
curl -e "https://google.com" https://exemplo.com        # Referer (--referer)
curl -H "Host: meusite.com" http://192.168.1.10         # testar virtual host por IP
curl --compressed https://exemplo.com                   # pede gzip/br e descompacta
```

---

## 6. Autenticação

```bash
# Basic Auth
curl -u usuario:senha https://api.exemplo.com
curl -u usuario https://api.exemplo.com                 # pede a senha no prompt (não vai pro histórico)

# Bearer token (JWT, OAuth2)
curl -H "Authorization: Bearer $TOKEN" https://api.exemplo.com/me

# API Key (header ou query)
curl -H "X-Api-Key: $API_KEY" https://api.exemplo.com
curl "https://api.exemplo.com?api_key=$API_KEY"

# Digest / NTLM
curl --digest -u usuario:senha https://api.exemplo.com
curl --ntlm -u usuario:senha https://intranet.exemplo.com

# .netrc (credenciais fora do comando)
curl -n https://api.exemplo.com                         # lê ~/.netrc
```

Arquivo `~/.netrc` (permissão `chmod 600`):

```
machine api.exemplo.com
login usuario
password segredo
```

### Fluxo completo: login → token → chamada (com `jq`)

```bash
TOKEN=$(curl -s -X POST https://api.exemplo.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"raul","senha":"segredo"}' | jq -r '.token')

curl -s -H "Authorization: Bearer $TOKEN" https://api.exemplo.com/me | jq
```

> **Segurança:** senhas e tokens digitados na linha de comando ficam no histórico do shell e aparecem em `ps`. Prefira variáveis de ambiente, `-u usuario` (prompt), `.netrc` ou `-K arquivo` (config).

---

## 7. Cookies e sessão

```bash
curl -c cookies.txt https://exemplo.com/login -d "user=raul&pass=123"   # salva cookies (cookie jar)
curl -b cookies.txt https://exemplo.com/area-restrita                   # envia cookies salvos
curl -b cookies.txt -c cookies.txt https://exemplo.com/painel           # lê e atualiza
curl -b "sessao=abc123; tema=dark" https://exemplo.com                  # cookie inline
```

---

## 8. Download de arquivos

```bash
curl -O https://exemplo.com/arquivo.zip                  # salva como arquivo.zip
curl -o meu.zip https://exemplo.com/arquivo.zip          # salva com outro nome
curl -OL https://exemplo.com/release/latest              # segue redirect e salva
curl -JO https://exemplo.com/download?id=10              # usa o nome do header Content-Disposition
curl -O https://exemplo.com/a.zip -O https://exemplo.com/b.zip   # vários arquivos
curl --create-dirs -o pasta/sub/arq.txt https://exemplo.com/arq.txt

# Retomar download interrompido
curl -C - -O https://exemplo.com/iso-grande.iso

# Limitar velocidade / mostrar barra de progresso simples
curl --limit-rate 500k -O https://exemplo.com/grande.zip
curl -# -O https://exemplo.com/grande.zip

# Só baixa se o arquivo remoto for mais novo
curl -z arquivo.zip -O https://exemplo.com/arquivo.zip

# Baixar e executar script (confira o conteúdo antes!)
curl -fsSL https://exemplo.com/install.sh | bash
```

> **`-fsSL`** é a combinação clássica para scripts de instalação: falha em erro HTTP (`-f`), sem progresso (`-s`), mostra erros (`-S`) e segue redirects (`-L`).

---

## 9. Redirecionamentos, proxy e TLS

### Redirects

```bash
curl -L https://encurtador.com/abc                 # segue redirects (padrão: até 50)
curl -L --max-redirs 3 https://exemplo.com         # limita a 3
curl -Ls -o /dev/null -w "%{url_effective}\n" https://bit.ly/xyz   # descobrir URL final
```

### Proxy

```bash
curl -x http://proxy.empresa.com:8080 https://exemplo.com
curl -x http://usuario:senha@proxy:8080 https://exemplo.com
curl -x socks5h://127.0.0.1:1080 https://exemplo.com       # SOCKS5 (ex.: túnel ssh -D)
curl --noproxy "*" https://exemplo.com                     # ignora proxy do ambiente
# Variáveis de ambiente: http_proxy, https_proxy, no_proxy
```

### TLS / certificados

```bash
curl -k https://self-signed.local                          # ignora validação (só dev!)
curl --cacert ca.pem https://interno.exemplo.com           # CA customizada
curl --cert cliente.pem --key cliente.key https://mtls.exemplo.com   # mTLS (certificado de cliente)
curl --tlsv1.2 https://exemplo.com                         # força versão mínima
curl -v https://exemplo.com 2>&1 | grep -iE "SSL|TLS|subject|expire"   # inspecionar certificado
curl --resolve exemplo.com:443:192.168.1.10 https://exemplo.com   # força IP (sem mexer no /etc/hosts)
curl --connect-to exemplo.com:443:outro.host:8443 https://exemplo.com
```

> **Nunca** deixe `-k` em scripts de produção: desativa a verificação e permite ataque man-in-the-middle.

---

## 10. Medir desempenho e status (`-w`)

```bash
# Só o código HTTP
curl -s -o /dev/null -w "%{http_code}\n" https://exemplo.com

# Tempos detalhados
curl -s -o /dev/null -w "\
DNS:        %{time_namelookup}s
Conexão:    %{time_connect}s
TLS:        %{time_appconnect}s
1º byte:    %{time_starttransfer}s
Total:      %{time_total}s
Tamanho:    %{size_download} bytes
Status:     %{http_code}
" https://exemplo.com
```

| Variável | O que retorna |
|---|---|
| `%{http_code}` | Código HTTP final |
| `%{time_total}` | Tempo total |
| `%{time_namelookup}` | Tempo de resolução DNS |
| `%{time_connect}` | Tempo até conectar (TCP) |
| `%{time_appconnect}` | Tempo até terminar o handshake TLS |
| `%{time_starttransfer}` | TTFB (tempo até o primeiro byte) |
| `%{size_download}` | Bytes baixados |
| `%{speed_download}` | Velocidade média (bytes/s) |
| `%{url_effective}` | URL final após redirects |
| `%{num_redirects}` | Número de redirects seguidos |
| `%{remote_ip}` | IP do servidor |

---

## 11. Scripts, retry e códigos de saída

```bash
# Retry automático
curl --retry 5 --retry-delay 2 --retry-connrefused https://api.exemplo.com
curl --retry 5 --retry-all-errors https://api.exemplo.com   # (curl ≥ 7.71) inclui erros HTTP

# Falhar em 4xx/5xx (útil em CI)
curl -f https://api.exemplo.com/health || echo "API fora do ar"

# Health check completo
curl -fsS -m 5 -o /dev/null https://api.exemplo.com/health && echo OK || echo FALHOU

# Esperar serviço subir
until curl -fs http://localhost:8080/actuator/health > /dev/null; do
  echo "aguardando..."; sleep 2
done

# Guardar status e corpo separados
BODY=$(curl -s -w "\n%{http_code}" https://api.exemplo.com/users)
STATUS=$(tail -n1 <<< "$BODY")
JSON=$(sed '$d' <<< "$BODY")

# Arquivo de configuração (-K) — evita expor segredos na linha de comando
curl -K config.txt
```

Exemplo de `config.txt`:

```
url = "https://api.exemplo.com/me"
header = "Authorization: Bearer abc123"
silent
```

### Códigos de saída comuns

| Código | Significado |
|---|---|
| `0` | Sucesso |
| `6` | Não resolveu o host (DNS) |
| `7` | Falha ao conectar (porta fechada / servidor fora) |
| `22` | Erro HTTP ≥ 400 (com `-f`) |
| `28` | Timeout |
| `35` | Erro no handshake TLS |
| `51` / `60` | Certificado inválido / CA não confiável |

---

## 12. Trabalhando com JSON (`jq`)

```bash
brew install jq

curl -s https://api.exemplo.com/users | jq                       # formata
curl -s https://api.exemplo.com/users | jq '.[0].nome'           # primeiro nome
curl -s https://api.exemplo.com/users | jq -r '.[].email'        # lista sem aspas
curl -s https://api.exemplo.com/users | jq '.[] | select(.ativo == true)'
curl -s https://api.exemplo.com/users | jq 'length'              # contar itens
curl -s https://api.exemplo.com/users | jq -r '.[] | [.id,.nome] | @csv'   # CSV
```

---

## 13. Outros protocolos e recursos

```bash
# FTP / SFTP
curl -u user:senha ftp://ftp.exemplo.com/arquivo.txt -O
curl -T local.txt -u user:senha ftp://ftp.exemplo.com/remoto.txt         # upload
curl -u user: --key ~/.ssh/id_ed25519 sftp://host/home/user/arq.txt -O   # SFTP

# E-mail (SMTP)
curl --url smtps://smtp.gmail.com:465 --ssl-reqd \
  --mail-from "eu@exemplo.com" --mail-rcpt "voce@exemplo.com" \
  --upload-file mensagem.txt -u "eu@exemplo.com:$APP_PASSWORD"

# HTTP/2 e HTTP/3
curl --http2 -I https://exemplo.com
curl --http3 -I https://exemplo.com          # requer build com suporte a HTTP/3

# Unix socket (ex.: API do Docker)
curl --unix-socket /var/run/docker.sock http://localhost/containers/json

# Requisições em paralelo
curl --parallel --parallel-max 5 -O https://ex.com/1.zip -O https://ex.com/2.zip

# Server-Sent Events / streaming (sem buffer)
curl -N https://api.exemplo.com/stream
```

---

## 14. Receitas práticas

```bash
# Ver meu IP público
curl -s ifconfig.me
curl -s https://api.ipify.org

# Testar se um site está no ar (só o código)
curl -s -o /dev/null -w "%{http_code}" https://exemplo.com

# Ver headers de segurança de um site
curl -sI https://exemplo.com | grep -iE "strict-transport|content-security|x-frame|x-content-type"

# Ver cadeia de redirects
curl -sIL https://exemplo.com | grep -iE "^(HTTP|location)"

# Testar CORS (preflight)
curl -i -X OPTIONS https://api.exemplo.com/users \
  -H "Origin: https://meusite.com" \
  -H "Access-Control-Request-Method: POST"

# Testar rate limit: 20 requisições seguidas
for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code} " https://api.exemplo.com; done; echo

# Testar Spring Boot Actuator
curl -s http://localhost:8080/actuator/health | jq

# Testar webhook com payload
curl -X POST https://hooks.exemplo.com/abc \
  -H "Content-Type: application/json" \
  -d '{"evento":"deploy","status":"ok"}'

# Testar Nginx atrás de proxy sem mexer no DNS
curl -H "Host: meusite.com" http://127.0.0.1

# Converter comando do DevTools: Network → botão direito → Copy → Copy as cURL
```

---

## 15. Troubleshooting

| Sintoma | Causa provável | Diagnóstico / correção |
|---|---|---|
| `curl: (6) Could not resolve host` | DNS/URL errada | `dig host`; confira a URL e a rede |
| `curl: (7) Failed to connect` | Porta fechada, serviço parado ou firewall | `lsof -i :PORTA`; `curl -v`; verifique `ufw`/security group |
| `curl: (28) Operation timed out` | Servidor lento ou pacote descartado | Aumente `-m`; teste `--connect-timeout 5` |
| `curl: (35) SSL connect error` | Versão/cifra TLS incompatível | `curl -v --tlsv1.2`; confira `openssl s_client -connect host:443` |
| `curl: (60) SSL certificate problem` | CA desconhecida ou certificado expirado | `--cacert ca.pem`; renove o cert; `-k` só para teste |
| `curl: (52) Empty reply from server` | Servidor fechou sem responder (HTTP em porta HTTPS, ou vice-versa) | Confira `http://` vs `https://` |
| `zsh: no matches found: ...?a=1&b=2` | Shell interpreta `?` e `&` | Coloque a URL entre aspas `"..."` |
| `415 Unsupported Media Type` | Falta `Content-Type` | Adicione `-H "Content-Type: application/json"` |
| `400 Bad Request` com JSON | JSON inválido ou aspas quebradas no shell | Use aspas simples externas `'{"a":"b"}'` ou `-d @arquivo.json` |
| `301/302` e corpo vazio | Redirect não seguido | Adicione `-L` |
| Corpo em branco, sem erro | `-s` escondeu a mensagem | Use `-sS` ou `-v` |
| Caracteres acentuados quebrados | Encoding/URL não codificada | Use `--data-urlencode` |

---

## 16. curl vs alternativas

| Ferramenta | Quando usar |
|---|---|
| `curl` | Scripts, CI, debug de HTTP/TLS, presente em todo servidor |
| `wget` | Downloads recursivos e espelhamento de sites (`wget -r`) |
| [`httpie`](https://httpie.io) (`brew install httpie`) | Uso interativo com sintaxe mais legível: `http POST api/users nome=Raul` |
| Postman / Insomnia / Bruno | Coleções, ambientes e testes de API com interface gráfica |
