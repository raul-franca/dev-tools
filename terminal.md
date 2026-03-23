# Terminal macOS — Cheatsheet

Referência de comandos úteis de terminal para desenvolvimento no macOS.

---

## 1. Rede

### Ver interfaces e IPs

```bash
ifconfig | grep "inet "          # Listar IPs de todas as interfaces ativas
ipconfig getifaddr en0           # IP da interface Wi-Fi (en0)
ipconfig getifaddr en8           # IP de outra interface (ex: Ethernet USB)
route get default | grep interface  # Interface sendo usada na internet agora
networksetup -listallhardwareports  # Listar todas as portas de hardware e seus devices
```

### Ver interfaces ativas

```bash
ifconfig | grep "status: active"  # Mostrar só interfaces conectadas
```

### Testar conectividade

```bash
ping -c 4 google.com             # Ping com 4 pacotes
traceroute google.com            # Rota até o destino
curl -I https://google.com       # Cabeçalho HTTP de uma URL
```

### Portas e processos

```bash
lsof -i :8080                    # Ver o que está usando a porta 8080
lsof -i tcp                      # Listar todas as conexões TCP abertas
netstat -an | grep LISTEN        # Listar portas em escuta
kill -9 $(lsof -ti :8080)        # Matar processo na porta 8080
```

---

## 2. Processos

```bash
ps aux                           # Listar todos os processos
ps aux | grep nome               # Filtrar processo por nome
top                              # Monitor de processos em tempo real
htop                             # Monitor interativo (instalar: brew install htop)

kill PID                         # Encerrar processo pelo PID (graceful)
kill -9 PID                      # Forçar encerramento de processo
killall nome-do-processo         # Encerrar todos os processos com esse nome
```

---

## 3. Arquivos e diretórios

```bash
ls -la                           # Listar arquivos com detalhes (incluindo ocultos)
pwd                              # Mostrar diretório atual
du -sh *                         # Tamanho de cada item no diretório atual
du -sh pasta/                    # Tamanho de uma pasta específica
df -h                            # Espaço em disco disponível

find . -name "*.log"             # Buscar arquivos .log recursivamente
find . -name "*.log" -delete     # Buscar e deletar arquivos .log
```

---

## 4. Busca em arquivos

```bash
grep -r "texto" .                # Buscar texto recursivamente no diretório atual
grep -rn "texto" src/            # Buscar com número de linha
grep -rl "texto" .               # Mostrar só os nomes dos arquivos com o texto
```

---

## 5. Variáveis de ambiente

```bash
printenv                         # Listar todas as variáveis de ambiente
echo $PATH                       # Ver o PATH atual
export VAR=valor                 # Definir variável de ambiente na sessão atual

# Para persistir: adicionar ao ~/.zshrc ou ~/.bash_profile
echo 'export VAR=valor' >> ~/.zshrc
source ~/.zshrc                  # Recarregar configurações do shell
```

---

## 6. SSH

### Gerar chave SSH

```bash
ssh-keygen -t ed25519 -C "seu@email.com"   # Gerar chave Ed25519 (recomendado)
ssh-keygen -t rsa -b 4096 -C "seu@email.com"  # Gerar chave RSA 4096 bits
```

### Gerenciar chaves

```bash
ls ~/.ssh/                       # Listar chaves existentes
cat ~/.ssh/id_ed25519.pub        # Ver chave pública
ssh-add ~/.ssh/id_ed25519        # Adicionar chave ao agente SSH
ssh-add -l                       # Listar chaves carregadas no agente
```

### Conectar em servidor

```bash
ssh usuario@ip                   # Conectar via SSH
ssh -p 2222 usuario@ip           # Conectar em porta diferente
ssh -i ~/.ssh/chave usuario@ip   # Conectar com chave específica
```

### Arquivo de config SSH (`~/.ssh/config`)

```
Host meu-servidor
    HostName 192.168.1.10
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    Port 22
```

Após configurar: `ssh meu-servidor`

---

## 7. Compressão e arquivos

```bash
tar -czf arquivo.tar.gz pasta/   # Compactar pasta em .tar.gz
tar -xzf arquivo.tar.gz          # Descompactar .tar.gz
tar -czf - pasta/ | pv > arq.tar.gz  # Com barra de progresso (brew install pv)

zip -r arquivo.zip pasta/        # Compactar em .zip
unzip arquivo.zip                # Descompactar .zip
unzip -l arquivo.zip             # Listar conteúdo sem extrair
```

---

## 8. Clipboard e output

```bash
comando | pbcopy                 # Copiar output de comando para clipboard
pbpaste                          # Colar conteúdo do clipboard no terminal
cat arquivo.txt | pbcopy         # Copiar conteúdo de arquivo
```

---

## 9. Histórico e shortcuts úteis

```bash
history                          # Ver histórico de comandos
history | grep "git"             # Filtrar histórico por termo
!!                               # Repetir último comando
!ssh                             # Repetir último comando que começa com "ssh"

ctrl + r                         # Buscar no histórico interativamente
ctrl + c                         # Cancelar comando atual
ctrl + z                         # Suspender processo (retomar com fg)
ctrl + l                         # Limpar tela (equivalente a clear)
```
