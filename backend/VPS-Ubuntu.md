# VPS Ubuntu 24.04 — Cheatsheet

Referência de setup inicial e operação diária de VPS **Hostinger** com **Ubuntu 24.04 LTS** (kernel 6.8, x86_64), com foco em deploy via **Docker + Docker Compose**.

> [!NOTE]
> Todos os comandos assumem shell `bash` como usuário com `sudo`. Substitua `deploy`, `meu-app` e IPs de exemplo pelos seus valores.

---

## 1. Reconhecimento do servidor

```bash
# Identificação do sistema
lsb_release -a                          # versão do Ubuntu (24.04.4 LTS)
cat /etc/os-release                     # idem, formato key=value
uname -a                                # kernel completo (6.8.0-138-generic x86_64)
hostnamectl                             # hostname, SO, kernel, virtualização (KVM na Hostinger)

# Recursos disponíveis
nproc                                   # nº de vCPUs
free -h                                 # memória RAM e swap
df -h                                   # uso de disco por partição
lsblk                                   # discos e partições
uptime                                  # tempo ligado + load average

# Rede
ip a                                    # interfaces e IPs
ip r                                    # tabela de rotas
curl -s ifconfig.me                     # IP público de saída
```

---

## 2. Primeiro acesso e usuário sudo

A Hostinger entrega a VPS com acesso `root` por senha. **Nunca opere no dia a dia como root.**

```bash
# 1. Acessar como root (primeira vez, do seu Mac)
ssh root@203.0.113.10

# 2. Atualizar o sistema antes de qualquer coisa
apt update && apt upgrade -y

# 3. Criar usuário de trabalho
adduser deploy                          # pede senha e dados (pode deixar em branco)
usermod -aG sudo deploy                 # dá permissão de sudo

# 4. Copiar as chaves SSH do root para o novo usuário
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy/

# 5. Testar em OUTRO terminal (não feche a sessão root ainda!)
ssh deploy@203.0.113.10
sudo whoami                             # deve responder: root
```

### Sudo sem senha (opcional, útil para scripts de deploy)

```bash
echo "deploy ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/deploy
sudo chmod 440 /etc/sudoers.d/deploy
sudo visudo -c                          # valida a sintaxe do sudoers
```

---

## 3. SSH — acesso por chave

No **seu Mac** (ver também [SSH.md](SSH.md)):

```bash
ssh-keygen -t ed25519 -C "hostinger-vps"        # gerar par de chaves
ssh-copy-id deploy@203.0.113.10                 # enviar a pública para a VPS
```

Atalho no `~/.ssh/config` do Mac:

```
Host vps
    HostName 203.0.113.10
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```

Depois disso basta `ssh vps`.

### Endurecer o SSH do servidor

No Ubuntu 24.04 o `sshd` lê `/etc/ssh/sshd_config.d/*.conf` — prefira um arquivo próprio a editar o principal:

```bash
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 3
EOF

sudo sshd -t                            # valida a configuração (obrigatório!)
sudo systemctl restart ssh              # no 24.04 o serviço chama "ssh", não "sshd"
```

> [!WARNING]
> Antes de reiniciar o SSH, confirme em **outra aba** que o login por chave funciona. Se errar, você perde o acesso e precisa do console web da Hostinger para recuperar.

### Trocar a porta padrão (opcional)

No 24.04 o SSH usa socket activation, então mudar `Port` no config não basta:

```bash
sudo systemctl edit ssh.socket
# adicione:
# [Socket]
# ListenStream=
# ListenStream=2222

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
sudo ufw allow 2222/tcp                 # libere ANTES de derrubar a porta 22
```

---

## 4. APT — gerenciamento de pacotes

```bash
sudo apt update                         # atualiza o índice de pacotes
sudo apt upgrade -y                     # atualiza pacotes instalados
sudo apt full-upgrade -y                # permite remover pacotes para resolver dependências
sudo apt install -y pacote              # instalar
sudo apt remove pacote                  # remover (mantém configs)
sudo apt purge pacote                   # remover incluindo configs
sudo apt autoremove --purge -y          # limpa dependências órfãs
sudo apt clean                          # limpa cache de .deb baixados

apt search termo                        # buscar pacote
apt show pacote                         # detalhes do pacote
apt list --installed                    # tudo que está instalado
apt list --upgradable                   # o que tem atualização pendente
apt-cache policy pacote                 # versão instalada vs disponível
dpkg -l | grep pacote                   # verificar instalação (dpkg)
dpkg -L pacote                          # arquivos que o pacote instalou
```

### Repositórios e chaves (padrão do 24.04)

```bash
ls /etc/apt/sources.list.d/             # repositórios extras (.list e .sources)
ls /etc/apt/keyrings/                   # chaves GPG (não use mais apt-key)
sudo add-apt-repository ppa:usuario/ppa # adicionar PPA
sudo add-apt-repository --remove ppa:usuario/ppa
```

### Travas do APT (erro comum)

```bash
# "Could not get lock /var/lib/dpkg/lock-frontend"
ps aux | grep -E 'apt|dpkg'             # veja quem está segurando
sudo systemctl stop unattended-upgrades # normalmente é o culpado
sudo dpkg --configure -a                # conclui instalações interrompidas
sudo apt --fix-broken install
```

### needrestart (novidade que trava scripts)

O 24.04 abre um diálogo perguntando quais serviços reiniciar após updates. Para automatizar:

```bash
sudo sed -i 's/#\$nrconf{restart} = .*/\$nrconf{restart} = "a";/' /etc/needrestart/needrestart.conf
# ou, pontualmente:
sudo NEEDRESTART_MODE=a apt upgrade -y
```

---

## 5. Pacotes essenciais

```bash
sudo apt update && sudo apt install -y \
  curl wget git vim nano \
  htop btop ncdu tree jq unzip zip \
  ca-certificates gnupg lsb-release \
  ufw fail2ban \
  net-tools dnsutils iputils-ping traceroute mtr \
  rsync tmux build-essential
```

| Pacote | Para que serve |
|---|---|
| `htop` / `btop` | Monitor interativo de CPU, RAM e processos |
| `ncdu` | Descobrir o que está ocupando disco, navegável |
| `jq` | Formatar e consultar JSON no terminal |
| `tmux` | Sessões persistentes (o deploy sobrevive à queda do SSH) |
| `ufw` | Firewall simplificado |
| `fail2ban` | Bane IPs após tentativas de login falhas |
| `dnsutils` | `dig`, `nslookup` para depurar DNS |
| `mtr` | `ping` + `traceroute` contínuo |
| `rsync` | Sincronização e backup incremental |
| `ncdu`, `tree` | Inspeção de diretórios |

### Python no 24.04 (PEP 668)

O Ubuntu 24.04 marca o Python do sistema como *externally managed* — `pip install` global falha de propósito:

```bash
sudo apt install -y python3-venv python3-pip pipx

python3 -m venv .venv && source .venv/bin/activate    # projetos: sempre venv
pipx install ruff                                     # CLIs isoladas, no PATH

# Evite --break-system-packages: quebra pacotes do sistema de verdade.
```

---

## 6. Firewall (UFW)

```bash
sudo ufw status verbose                 # estado atual
sudo ufw default deny incoming          # bloqueia tudo que entra
sudo ufw default allow outgoing         # libera tudo que sai

sudo ufw allow OpenSSH                  # ou: sudo ufw allow 22/tcp
sudo ufw allow 80/tcp                   # HTTP
sudo ufw allow 443/tcp                  # HTTPS
sudo ufw allow from 203.0.113.55 to any port 3306 proto tcp   # MySQL só para um IP

sudo ufw enable                         # ativa (confirme o SSH liberado antes!)
sudo ufw status numbered                # lista com índices
sudo ufw delete 3                       # remove a regra nº 3
sudo ufw reload
sudo ufw disable
```

> [!CAUTION]
> **Docker ignora o UFW.** Ao publicar `-p 5432:5432`, o container fica exposto na internet mesmo com a porta "bloqueada" no UFW, porque o Docker escreve direto no `iptables` (cadeia `DOCKER`). Solução: publique só no loopback — `-p 127.0.0.1:5432:5432` — e exponha ao mundo apenas 80/443 via Nginx.

### fail2ban (proteção do SSH)

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo tee /etc/fail2ban/jail.d/sshd.local > /dev/null <<'EOF'
[sshd]
enabled = true
port    = ssh
maxretry = 4
findtime = 10m
bantime  = 1h
EOF

sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd        # IPs banidos
sudo fail2ban-client set sshd unbanip 203.0.113.99
```

---

## 7. Docker + Docker Compose (instalação oficial)

Não use o `docker.io` do repositório do Ubuntu — ele fica para trás e não traz o plugin `compose`. Use o repositório oficial da Docker:

```bash
# 1. Remover versões antigas/conflitantes
for p in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt remove -y $p
done

# 2. Chave GPG oficial
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. Repositório (noble = Ubuntu 24.04)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# 5. Usar docker sem sudo
sudo usermod -aG docker $USER
newgrp docker                           # aplica sem precisar deslogar

# 6. Verificar
docker --version
docker compose version                  # plugin v2 (sem hífen!)
docker run --rm hello-world
sudo systemctl enable --now docker
```

### Configuração recomendada do daemon

Sem isso, os logs de containers crescem até encher o disco da VPS:

```bash
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "live-restore": true
}
EOF

sudo systemctl restart docker
docker info | grep -i 'logging driver'
```

---

## 8. Docker no dia a dia

Referência completa em [Docker.md](Docker.md). Aqui, o recorte de servidor:

```bash
# Estado geral
docker ps                               # containers rodando
docker ps -a                            # inclui parados
docker stats                            # CPU/RAM ao vivo por container
docker inspect meu-app | jq '.[0].State'
docker system df                        # espaço usado por imagens/volumes/cache

# Logs
docker logs -f --tail 100 meu-app       # seguir os últimos 100
docker logs --since 30m meu-app         # últimos 30 minutos
docker logs --timestamps meu-app

# Entrar no container
docker exec -it meu-app bash            # ou sh, em imagens alpine
docker exec -it meu-db mysql -uroot -p

# Ciclo de vida
docker restart meu-app
docker stop meu-app && docker rm meu-app
```

### Compose — deploy e atualização

```bash
cd /opt/meu-app                         # convenção: apps em /opt ou /srv

docker compose up -d                    # subir em background
docker compose ps                       # status dos serviços
docker compose logs -f --tail 50 api    # logs de um serviço
docker compose exec api bash
docker compose restart api
docker compose down                     # derruba (mantém volumes)
docker compose down -v                  # derruba E APAGA volumes (cuidado!)

# Atualizar para a nova versão da imagem
docker compose pull && docker compose up -d

# Rebuild após mudança no código
docker compose up -d --build

# Validar o arquivo antes de aplicar
docker compose config
```

### Deploy típico via Git na VPS

```bash
cd /opt/meu-app
git pull origin main
docker compose build --pull
docker compose up -d --remove-orphans
docker image prune -f
docker compose ps
```

### Limpeza de disco (rode quando o disco apertar)

```bash
docker system df                        # ver o que está ocupando
docker image prune -f                   # imagens dangling
docker image prune -a -f                # TODAS as imagens sem container em uso
docker container prune -f               # containers parados
docker builder prune -f                 # cache de build (costuma ser o maior)
docker volume ls -qf dangling=true      # volumes órfãos (confira antes!)
docker system prune -a --volumes        # nuclear — leia duas vezes
```

### Backup de volume Docker

```bash
# Exportar um volume para .tar.gz
docker run --rm -v meu-app_dbdata:/data -v $(pwd):/backup alpine \
  tar czf /backup/dbdata-$(date +%F).tar.gz -C /data .

# Restaurar
docker run --rm -v meu-app_dbdata:/data -v $(pwd):/backup alpine \
  sh -c "cd /data && tar xzf /backup/dbdata-2026-08-28.tar.gz"

# Dump de MySQL rodando em container
docker compose exec -T db mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" meubanco \
  | gzip > backup-$(date +%F).sql.gz
```

---

## 9. systemd — serviços

```bash
sudo systemctl status nginx             # estado detalhado
sudo systemctl start|stop|restart nginx
sudo systemctl reload nginx             # recarrega config sem derrubar conexões
sudo systemctl enable nginx             # inicia no boot
sudo systemctl disable nginx
sudo systemctl enable --now docker      # habilita e inicia de uma vez
sudo systemctl is-active docker
sudo systemctl is-enabled docker

systemctl list-units --type=service --state=running    # o que está rodando
systemctl list-unit-files --state=enabled              # o que sobe no boot
systemctl --failed                                     # serviços que falharam

sudo systemctl daemon-reload            # após criar/editar um .service
systemd-analyze blame                   # o que demora no boot
```

### Criar um serviço próprio

```bash
sudo tee /etc/systemd/system/meu-app.service > /dev/null <<'EOF'
[Unit]
Description=Meu App
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/meu-app
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now meu-app
```

---

## 10. Logs (journalctl)

```bash
journalctl -u nginx -f                  # seguir os logs de um serviço
journalctl -u docker --since "1 hour ago"
journalctl --since "2026-08-28 09:00" --until "2026-08-28 10:00"
journalctl -p err -b                    # só erros desde o último boot
journalctl -b -1                        # logs do boot anterior
journalctl -xe                          # últimos eventos com explicação
journalctl -u meu-app -n 200 --no-pager

# Tamanho e limpeza do journal
journalctl --disk-usage
sudo journalctl --vacuum-time=7d        # mantém 7 dias
sudo journalctl --vacuum-size=200M

# Logs clássicos em arquivo
sudo tail -f /var/log/syslog
sudo tail -f /var/log/auth.log          # tentativas de login SSH
sudo tail -f /var/log/nginx/error.log
```

---

## 11. Disco, memória e swap

```bash
# Disco
df -h                                   # uso por partição
df -i                                   # uso de inodes (disco "cheio" com espaço livre)
du -sh /var/lib/docker                  # tamanho de um diretório
du -h --max-depth=1 /var | sort -hr | head -20
ncdu /                                  # navegador interativo de uso de disco
sudo find /var/log -type f -size +100M -exec ls -lh {} \;

# Memória
free -h
vmstat 1 5
ps aux --sort=-%mem | head -10          # top 10 consumidores de RAM
```

### Criar swap (VPS pequena não vem com swap)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

swapon --show                           # confirmar
sudo sysctl vm.swappiness=10            # usar swap só quando necessário
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swap.conf
```

---

## 12. Processos e CPU

```bash
htop                                    # interativo (F6 ordena, F9 mata)
btop                                    # alternativa mais visual
top -o %CPU
ps aux --sort=-%cpu | head -10
ps -ef | grep python
pgrep -a nginx                          # PIDs + linha de comando

kill -15 PID                            # SIGTERM (encerramento limpo)
kill -9 PID                             # SIGKILL (último recurso)
pkill -f "gunicorn"                     # por padrão na linha de comando
killall nginx

uptime                                  # load average (1, 5, 15 min)
# Regra prática: load acima do nº de vCPUs (nproc) = servidor saturado
```

---

## 13. Rede e portas

```bash
ss -tulpn                               # portas em escuta (substitui netstat)
ss -tulpn | grep :80
ss -tan state established | wc -l       # conexões ativas
sudo lsof -i :8080                      # quem ocupa a porta 8080

curl -I https://meudominio.com.br       # só os headers
curl -v telnet://203.0.113.10:5432      # testar porta TCP
ping -c 4 8.8.8.8
mtr google.com                          # rota + perda de pacotes

# DNS
dig meudominio.com.br +short
dig meudominio.com.br A @8.8.8.8
resolvectl status                       # DNS em uso (systemd-resolved)

# Configuração de rede (Netplan — padrão no Ubuntu)
cat /etc/netplan/*.yaml
sudo netplan try                        # aplica com rollback automático
sudo netplan apply
```

---

## 14. Arquivos, permissões e usuários

```bash
# Navegação e busca
ls -lah                                 # detalhado com ocultos
tree -L 2 /opt
find /opt -name "*.env" -type f
find / -type f -size +500M 2>/dev/null   # arquivos grandes
grep -rn "DATABASE_URL" /opt/meu-app --include="*.py"

# Permissões
chmod 600 .env                          # só o dono lê/escreve (segredos!)
chmod 755 script.sh
chmod +x deploy.sh
chown -R deploy:deploy /opt/meu-app
stat arquivo                            # dono, permissões, datas

# Usuários e grupos
id deploy
groups deploy
sudo usermod -aG docker deploy
sudo passwd deploy
who                                     # quem está logado agora
last -n 20                              # histórico de logins
```

---

## 15. Timezone, hostname e locale

```bash
timedatectl                             # data, hora, fuso, NTP
sudo timedatectl set-timezone America/Recife
timedatectl list-timezones | grep Brazil
sudo timedatectl set-ntp true

sudo hostnamectl set-hostname vps-sjdh
sudo vim /etc/hosts                     # ajuste a linha 127.0.1.1

sudo locale-gen pt_BR.UTF-8
sudo update-locale LANG=pt_BR.UTF-8
locale
```

---

## 16. Agendamento (cron e timers)

```bash
crontab -e                              # tarefas do usuário atual
crontab -l                              # listar
sudo crontab -e                         # tarefas do root

# Sintaxe:  min hora dia mês dia-semana comando
# 0 3 * * *          → todo dia às 03:00
# */15 * * * *       → a cada 15 minutos
# 0 4 * * 0          → domingos às 04:00
```

Exemplos práticos:

```cron
# Backup do banco às 3h, com log
0 3 * * * cd /opt/meu-app && /usr/bin/docker compose exec -T db mysqldump -uroot -p"$SENHA" app | gzip > /backups/app-$(date +\%F).sql.gz 2>> /var/log/backup.log

# Limpeza de imagens Docker aos domingos
0 4 * * 0 /usr/bin/docker system prune -af >> /var/log/docker-prune.log 2>&1

# Renovação de certificados (o certbot já instala o próprio timer)
0 5 * * 1 /usr/bin/certbot renew --quiet
```

> [!TIP]
> No cron, o `%` precisa ser escapado (`\%`) e o `PATH` é mínimo — sempre use caminhos absolutos (`/usr/bin/docker`, não `docker`).

Timers do systemd (alternativa moderna):

```bash
systemctl list-timers --all
systemctl status certbot.timer
systemctl status apt-daily-upgrade.timer
```

---

## 17. Atualizações e reboot

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove --purge -y

# O sistema pede reboot?
ls /var/run/reboot-required             # existe = precisa reiniciar
cat /var/run/reboot-required.pkgs       # por causa de quais pacotes
sudo reboot

# Atualizações automáticas de segurança
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
cat /etc/apt/apt.conf.d/50unattended-upgrades
sudo unattended-upgrade --dry-run -d    # simular
```

> [!NOTE]
> Ubuntu 24.04 LTS tem suporte padrão até **abril de 2029** (e até 2034 com Ubuntu Pro/ESM, gratuito para uso pessoal em até 5 máquinas: `sudo pro attach <token>`).

---

## 18. Transferência de arquivos e backup

Do **seu Mac** para a VPS (ver [SSH.md](SSH.md)):

```bash
scp arquivo.zip vps:/opt/meu-app/               # enviar
scp vps:/var/log/app/erro.log ./                # baixar
scp -r ./dist vps:/opt/meu-app/                 # recursivo

# rsync — melhor para diretórios e re-envios
rsync -avz --progress ./dist/ vps:/opt/meu-app/dist/
rsync -avz --exclude='.venv' --exclude='.git' ./ vps:/opt/meu-app/
rsync -avzn ./dist/ vps:/opt/meu-app/dist/      # dry-run
rsync -avz vps:/backups/ ./backups-locais/      # trazer backups
```

Rotina de backup na própria VPS:

```bash
sudo mkdir -p /backups && sudo chown deploy:deploy /backups

# Compactar diretório da aplicação
tar czf /backups/app-$(date +%F).tar.gz -C /opt meu-app

# Manter só os últimos 7 dias
find /backups -name "*.tar.gz" -mtime +7 -delete
```

---

## 19. Troubleshooting rápido

| Sintoma | Diagnóstico | Correção provável |
|---|---|---|
| Site fora do ar | `docker compose ps`, `systemctl status nginx` | `docker compose up -d`, `sudo systemctl restart nginx` |
| Disco cheio | `df -h`, `ncdu /`, `docker system df` | `docker system prune -af`, `journalctl --vacuum-time=7d` |
| "No space left" com disco livre | `df -i` (inodes esgotados) | apagar diretórios com milhares de arquivos pequenos |
| Servidor lento | `htop`, `uptime`, `docker stats` | matar processo, aumentar swap, limitar container |
| OOM (container morre sozinho) | `dmesg -T \| grep -i oom`, `docker inspect` | adicionar swap, `mem_limit` no compose, subir plano |
| Porta ocupada | `sudo lsof -i :80`, `ss -tulpn` | `kill` do processo ou trocar a porta publicada |
| SSH recusado | console web da Hostinger | `sudo systemctl status ssh`, revisar UFW e `sshd -t` |
| APT travado | `ps aux \| grep apt` | `sudo systemctl stop unattended-upgrades`, `dpkg --configure -a` |
| Container não sobe | `docker compose logs api` | corrigir env/porta e `docker compose up -d --force-recreate` |
| Certificado expirado | `sudo certbot certificates` | `sudo certbot renew --force-renewal && sudo systemctl reload nginx` |

Comandos de socorro:

```bash
dmesg -T | tail -50                     # eventos do kernel (OOM killer, disco)
sudo journalctl -p err -b --no-pager | tail -50
sudo systemctl --failed
docker ps -a --filter "status=exited"   # o que morreu
docker inspect meu-app --format '{{.State.ExitCode}} {{.State.Error}}'
```

---

## 20. Bootstrap — VPS nova em 10 passos

```bash
# 1. Acesso e atualização
ssh root@203.0.113.10
apt update && apt upgrade -y

# 2. Usuário de trabalho
adduser deploy && usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy/

# 3. Reconectar como deploy e validar
ssh deploy@203.0.113.10 && sudo whoami

# 4. Pacotes essenciais
sudo apt install -y curl wget git vim htop btop ncdu tree jq unzip \
  ca-certificates gnupg ufw fail2ban rsync tmux dnsutils

# 5. Fuso e hostname
sudo timedatectl set-timezone America/Recife
sudo hostnamectl set-hostname vps-app

# 6. Firewall
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow OpenSSH && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
sudo ufw enable

# 7. SSH sem senha e sem root
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<'EOF'
PermitRootLogin no
PasswordAuthentication no
EOF
sudo sshd -t && sudo systemctl restart ssh

# 8. Swap (se a VPS tiver ≤ 4 GB de RAM)
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 9. Docker (seção 7) + limite de logs (daemon.json)

# 10. Aplicação
sudo mkdir -p /opt/meu-app && sudo chown deploy:deploy /opt/meu-app
cd /opt/meu-app && git clone git@github.com:usuario/meu-app.git .
cp .env.example .env && chmod 600 .env
docker compose up -d && docker compose ps
```

---

## Ver também

- [SSH.md](SSH.md) — chaves, config, túneis, SCP/SFTP e ProxyJump
- [Docker.md](Docker.md) — Dockerfile, Compose, volumes e redes em detalhe
- [Nginx.md](Nginx.md) — proxy reverso, HTTPS com Let's Encrypt e load balancer
- [terminal.md](terminal.md) — comandos de shell, rede e processos no dia a dia
- [CI-CD.md](CI-CD.md) — pipelines de deploy automatizado para a VPS
