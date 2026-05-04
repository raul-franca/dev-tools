# SSH — Cheatsheet

Referência completa de SSH: conexão, chaves, config, tunelamento, SCP, SFTP e casos práticos.

---

## 1. Conexão básica

```bash
ssh usuario@host                        # conectar
ssh usuario@192.168.1.10               # por IP
ssh usuario@host -p 2222               # porta personalizada (padrão: 22)
ssh host                               # usa usuário local atual
ssh -v usuario@host                    # verbose (debug nível 1)
ssh -vv usuario@host                   # debug nível 2
ssh -vvv usuario@host                  # debug máximo

# Executar comando remoto sem abrir shell
ssh usuario@host 'ls -la /var/www'
ssh usuario@host 'sudo systemctl restart nginx'
ssh usuario@host 'df -h && free -h'

# Com pseudo-terminal (necessário para comandos interativos)
ssh -t usuario@host 'sudo su -'
ssh -t usuario@host 'htop'
```

---

## 2. Chaves SSH

### Gerar par de chaves

```bash
# Ed25519 — recomendado (mais seguro e rápido)
ssh-keygen -t ed25519 -C "seu@email.com"

# RSA 4096 — compatibilidade máxima com sistemas legados
ssh-keygen -t rsa -b 4096 -C "seu@email.com"

# Com nome de arquivo personalizado
ssh-keygen -t ed25519 -f ~/.ssh/servidor_producao -C "prod"

# Flags úteis
# -t tipo     → algoritmo (ed25519, rsa, ecdsa)
# -b bits     → tamanho da chave (para RSA: 2048, 4096)
# -C comment  → comentário (aparece no final da chave pública)
# -f arquivo  → caminho do arquivo de saída
# -N ""       → sem passphrase (cuidado: não recomendado para produção)
```

### Onde ficam os arquivos

```
~/.ssh/
├── id_ed25519          # chave privada (NUNCA compartilhe)
├── id_ed25519.pub      # chave pública (essa você distribui)
├── config              # configurações de hosts
├── known_hosts         # servidores conhecidos
└── authorized_keys     # chaves autorizadas a acessar ESTA máquina
```

### Copiar chave pública para o servidor

```bash
# Forma recomendada (automática)
ssh-copy-id usuario@host
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@host
ssh-copy-id -i ~/.ssh/servidor_prod.pub -p 2222 usuario@host

# Forma manual (se ssh-copy-id não estiver disponível)
cat ~/.ssh/id_ed25519.pub | ssh usuario@host 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'

# Ver conteúdo da chave pública
cat ~/.ssh/id_ed25519.pub
```

### Permissões corretas (obrigatório)

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519          # chave privada
chmod 644 ~/.ssh/id_ed25519.pub      # chave pública
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config
```

---

## 3. Arquivo ~/.ssh/config

Evita digitar host, porta, usuário e chave toda vez.

```
# Sintaxe
Host apelido
    HostName ip-ou-dominio
    User usuario
    Port 22
    IdentityFile ~/.ssh/chave_privada
```

### Exemplos práticos

```
# Servidor de produção
Host prod
    HostName 203.0.113.10
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519

# Servidor de staging
Host staging
    HostName 203.0.113.20
    User ubuntu
    Port 2222
    IdentityFile ~/.ssh/id_ed25519

# Bastion / jump host
Host bastion
    HostName bastion.empresa.com
    User ec2-user
    IdentityFile ~/.ssh/aws_key.pem

# Servidor interno via bastion (ProxyJump)
Host interno
    HostName 10.0.1.50
    User ubuntu
    ProxyJump bastion
    IdentityFile ~/.ssh/id_ed25519

# AWS EC2 com chave .pem
Host minha-ec2
    HostName ec2-54-123-45-67.compute-1.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/minha-chave.pem
    StrictHostKeyChecking no

# Manter conexão viva e reutilizar sockets
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
    AddKeysToAgent yes
```

```bash
# Usando o config
ssh prod
ssh staging
ssh interno    # passa automaticamente pelo bastion
```

---

## 4. SSH Agent

Gerencia chaves em memória para não digitar passphrase toda vez.

```bash
# Iniciar o agent
eval "$(ssh-agent -s)"

# Adicionar chave (pede passphrase uma vez)
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/servidor_prod

# Adicionar e manter por 8 horas (macOS)
ssh-add --apple-use-keychain -t 8h ~/.ssh/id_ed25519

# Listar chaves carregadas
ssh-add -l

# Remover chave específica
ssh-add -d ~/.ssh/id_ed25519

# Remover todas as chaves
ssh-add -D

# Verificar se o agent está rodando
echo $SSH_AUTH_SOCK
```

### macOS — Keychain (persistente entre reinicializações)

```bash
# Adicionar ao keychain do macOS
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# ~/.ssh/config para usar keychain automaticamente
Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
```

---

## 5. Copiar arquivos (SCP)

```bash
# Local → Remoto
scp arquivo.txt usuario@host:~/destino/
scp arquivo.txt prod:/var/www/app/
scp -P 2222 arquivo.txt usuario@host:~/

# Remoto → Local
scp usuario@host:~/arquivo.txt .
scp prod:/var/log/app.log ./logs/

# Diretório inteiro (recursivo)
scp -r ./dist/ usuario@host:/var/www/app/
scp -r prod:/backup/2024/ ./backups/

# Múltiplos arquivos
scp arquivo1.txt arquivo2.txt usuario@host:~/

# Entre dois servidores remotos
scp usuario@host1:/path/arquivo.txt usuario@host2:/path/

# Opções úteis
# -P porta     → porta personalizada (maiúsculo no SCP)
# -r           → recursivo (diretórios)
# -p           → preservar permissões e timestamps
# -C           → comprimir durante transferência
# -i chave     → especificar chave privada
# -l limite    → limitar largura de banda em Kbit/s
scp -C -l 1000 arquivo_grande.zip usuario@host:~/
```

---

## 6. SFTP

Transferência interativa de arquivos via SSH.

```bash
sftp usuario@host
sftp -P 2222 usuario@host
sftp prod                        # usando alias do config

# Comandos dentro do SFTP
ls                               # listar remoto
lls                              # listar local
pwd                              # diretório remoto atual
lpwd                             # diretório local atual
cd /var/www                      # navegar remoto
lcd ~/Downloads                  # navegar local

get arquivo.txt                  # baixar
get arquivo.txt /local/destino/  # baixar para caminho específico
get -r pasta/                    # baixar diretório

put arquivo.txt                  # enviar
put -r dist/                     # enviar diretório

mkdir backup                     # criar diretório remoto
rm arquivo.txt                   # remover arquivo remoto
rename old.txt new.txt           # renomear remoto

exit                             # sair
```

---

## 7. Tunelamento (Port Forwarding)

### Local forwarding — acessa porta remota localmente

```
Você → localhost:PORTA_LOCAL → servidor SSH → destino:PORTA_REMOTA
```

```bash
ssh -L PORTA_LOCAL:DESTINO:PORTA_REMOTA usuario@host

# Exemplos:
# Acessar banco MySQL remoto como se fosse local
ssh -L 3307:localhost:3306 usuario@servidor-db
# → conecte em localhost:3307 para chegar ao MySQL do servidor

# Acessar serviço interno da rede do servidor
ssh -L 8080:servidor-interno:80 usuario@bastion
# → localhost:8080 chega ao servidor-interno:80 via bastion

# Acessar Redis remoto
ssh -L 6380:localhost:6379 usuario@servidor
# → redis-cli -p 6380 conecta no Redis remoto

# Sem abrir shell (só o túnel)
ssh -NL 3307:localhost:3306 usuario@servidor-db

# Em background
ssh -fNL 3307:localhost:3306 usuario@servidor-db

# Flags:
# -N  → não abre shell (só o túnel)
# -f  → vai para background antes de executar
# -L  → local forwarding
```

### Remote forwarding — expõe porta local para o servidor

```
Servidor → PORTA_REMOTA → você → localhost:PORTA_LOCAL
```

```bash
ssh -R PORTA_REMOTA:localhost:PORTA_LOCAL usuario@host

# Exemplos:
# Expor seu servidor local (porta 3000) na porta 8080 do servidor remoto
ssh -R 8080:localhost:3000 usuario@servidor
# → quem acessar servidor:8080 chega no seu localhost:3000

# Útil para demos, webhooks e acesso a máquinas atrás de NAT
ssh -fNR 8080:localhost:3000 usuario@servidor
```

### Dynamic forwarding — proxy SOCKS5

```bash
ssh -D PORTA_LOCAL usuario@host

# Exemplo:
ssh -fND 1080 usuario@servidor
# → configure o navegador com proxy SOCKS5 em localhost:1080
# → todo tráfego passa pelo servidor SSH como ponto de saída
```

---

## 8. ProxyJump (Bastion / Jump Host)

Conectar a servidores internos que não têm acesso direto à internet.

```bash
# Na linha de comando
ssh -J usuario@bastion usuario@servidor-interno
ssh -J ec2-user@bastion.empresa.com ubuntu@10.0.1.50

# Múltiplos saltos
ssh -J user@hop1,user@hop2 user@destino-final

# No ~/.ssh/config (recomendado)
Host interno
    HostName 10.0.1.50
    User ubuntu
    ProxyJump bastion

Host bastion
    HostName bastion.empresa.com
    User ec2-user
    IdentityFile ~/.ssh/id_ed25519

# Usar
ssh interno   # passa automaticamente pelo bastion
scp arquivo.txt interno:/tmp/   # SCP também funciona
```

---

## 9. Multiplexing (conexões reutilizadas)

Reutiliza a mesma conexão TCP para múltiplas sessões SSH — mais rápido para conexões frequentes.

```bash
# ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

```bash
# Criar pasta para sockets
mkdir -p ~/.ssh/sockets

# Verificar conexões ativas
ls ~/.ssh/sockets/

# Fechar conexão master
ssh -O exit usuario@host
```

---

## 10. Gerenciar known_hosts

```bash
# Ver entradas conhecidas
cat ~/.ssh/known_hosts

# Remover entrada de um host (quando chave muda)
ssh-keygen -R hostname
ssh-keygen -R 192.168.1.10

# Ver fingerprint de um servidor antes de conectar
ssh-keyscan -t ed25519 host 2>/dev/null | ssh-keygen -lf -

# Adicionar host sem verificar (não recomendado em produção)
ssh -o StrictHostKeyChecking=no usuario@host

# Adicionar automaticamente ao known_hosts
ssh -o StrictHostKeyChecking=accept-new usuario@host
```

---

## 11. Configuração do servidor SSH (sshd_config)

```bash
# Arquivo de configuração
sudo nano /etc/ssh/sshd_config

# Recarregar após mudanças
sudo systemctl reload ssh       # Linux
```

Opções importantes:

```
Port 2222                           # trocar porta padrão
PermitRootLogin no                  # desabilitar login como root
PasswordAuthentication no           # forçar autenticação por chave
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

AllowUsers deploy ubuntu            # apenas esses usuários
DenyUsers usuario_bloqueado

MaxAuthTries 3                      # tentativas antes de bloquear
LoginGraceTime 30                   # tempo para autenticar (segundos)

ClientAliveInterval 60              # keepalive do servidor
ClientAliveCountMax 3

X11Forwarding no                    # desabilitar X11 se não usar
```

```bash
# Testar configuração antes de recarregar
sudo sshd -t

# Ver logs de autenticação
sudo journalctl -u ssh -f           # Linux
sudo tail -f /var/log/auth.log      # Ubuntu/Debian
```

---

## 12. Troubleshooting

```bash
# Debug da conexão (do lado cliente)
ssh -v usuario@host     # nível 1
ssh -vv usuario@host    # nível 2
ssh -vvv usuario@host   # nível 3 (máximo)

# Verificar se a porta está aberta
nc -zv host 22
telnet host 22
nmap -p 22 host

# Verificar serviço SSH no servidor
sudo systemctl status ssh
sudo systemctl status sshd

# Ver tentativas de login
sudo journalctl -u ssh --since "1 hour ago"
sudo tail -f /var/log/auth.log

# Permissões incorretas são a causa mais comum de falha
# No servidor, verificar:
ls -la ~/.ssh/
stat ~/.ssh/authorized_keys
```

### Erros comuns

| Erro | Causa | Solução |
|---|---|---|
| `Permission denied (publickey)` | Chave não está no `authorized_keys` ou permissão errada | `ssh-copy-id` e `chmod 600 ~/.ssh/authorized_keys` |
| `Connection refused` | SSH não está rodando ou porta errada | `sudo systemctl start ssh` |
| `Host key verification failed` | Chave do servidor mudou | `ssh-keygen -R hostname` |
| `WARNING: UNPROTECTED PRIVATE KEY` | Permissão da chave privada muito aberta | `chmod 600 ~/.ssh/id_ed25519` |
| `Too many authentication failures` | Agent com muitas chaves | `ssh -o IdentitiesOnly=yes -i ~/.ssh/chave usuario@host` |
| `Broken pipe` | Conexão caindo por inatividade | Adicionar `ServerAliveInterval 60` no config |
| `ssh_exchange_identification` | Servidor sobrecarregado ou limitando IPs | Aguardar ou verificar fail2ban |

---

## 13. Casos práticos

### Túnel para banco de dados remoto

```bash
# MySQL/PostgreSQL remoto → acesso local
ssh -fNL 5433:localhost:5432 usuario@servidor-db
# → psql -h localhost -p 5433 -U postgres

ssh -fNL 3307:localhost:3306 usuario@servidor-db
# → mysql -h 127.0.0.1 -P 3307 -u root -p

# Fechar o túnel depois
kill $(lsof -t -i:5433)
kill $(lsof -t -i:3307)
```

### Deploy via SSH

```bash
# Copiar build e reiniciar serviço
scp -r ./dist/ prod:/var/www/app/
ssh prod 'sudo systemctl restart app'

# Pipeline completo em um comando
scp ./app.jar prod:/opt/app/ && ssh prod 'sudo systemctl restart app && sudo systemctl status app'

# Com sudo sem senha interativa
ssh prod 'sudo -n systemctl restart app'
```

### Acesso a EC2 na AWS

```bash
# ~/.ssh/config
Host minha-ec2
    HostName ec2-54-123-45-67.compute-1.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/minha-chave.pem
    StrictHostKeyChecking accept-new

ssh minha-ec2

# Instâncias em sub-rede privada via bastion
Host ec2-privada
    HostName 10.0.1.100
    User ec2-user
    IdentityFile ~/.ssh/minha-chave.pem
    ProxyJump minha-ec2
```

### Manter sessão longa ativa (tmux via SSH)

```bash
# Conectar e abrir sessão tmux
ssh prod -t 'tmux new-session -A -s main'

# Reconectar a sessão existente
ssh prod -t 'tmux attach -t main'
```

### Sincronizar diretório com rsync via SSH

```bash
# Local → Remoto (sincronizar)
rsync -avz --progress ./dist/ usuario@host:/var/www/app/

# Remoto → Local (baixar backup)
rsync -avz usuario@host:/var/log/app/ ./logs/

# Excluindo arquivos
rsync -avz --exclude='node_modules' --exclude='.env' ./ usuario@host:~/app/

# Dry-run (simular sem executar)
rsync -avzn ./dist/ usuario@host:/var/www/app/

# Com porta SSH personalizada
rsync -avz -e 'ssh -p 2222' ./dist/ usuario@host:/var/www/
```

### Gerar e distribuir chave rapidamente

```bash
# Gerar + copiar + testar em 3 comandos
ssh-keygen -t ed25519 -f ~/.ssh/novo_servidor -N "" -C "acesso-novo-servidor"
ssh-copy-id -i ~/.ssh/novo_servidor.pub usuario@host
ssh -i ~/.ssh/novo_servidor usuario@host 'echo conectado com sucesso'
```
