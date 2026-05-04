from pathlib import Path

content = """# Inventário Homebrew — Versão Atualizada com Recomendações

## 🧠 Objetivo
Este documento foi atualizado com base no seu estado atual após limpeza.

Agora ele inclui:
- ✅ O que manter
- ⚠️ O que revisar
- ❌ O que você pode remover com segurança (ou quase)

---

# ✅ MANTER (CORE DO SEU AMBIENTE)

Essenciais para seu perfil (Java + backend + infra):

- git
- jq
- docker-compose
- maven
- openjdk@21
- node
- nvm
- nmap
- python@3.12
- sqlite
- openssl@3
- ca-certificates

👉 Esses são seu **kit principal de dev**

---

# ⚠️ REVISAR (DEPENDE DO SEU USO)

### Backend / Dev Tools
- httpie → útil para testar APIs
- git-delta → melhora diff
- runme → documentação executável
- protobuf → se usa gRPC
- csvkit → manipulação CSV
- mdbtools → Access (você já usou)
- pandoc → conversão docs

---

### Linguagens / Ecosistemas extras
- lua → scripting (raramente necessário)
- guile → Scheme (provavelmente não usa)
- mercurial → só se usar além do git

---

### Infra / Rede
- openvpn → só se usa VPN
- unbound → DNS local (raro)
- telnet → obsoleto (pode remover)

---

### Java duplicado
- openjdk → ⚠️ redundante
👉 você já usa openjdk@21

---

### Python duplicado
- python@3.14 → ⚠️ possivelmente desnecessário
👉 mantenha só se realmente usa

---

# ❌ PODE REMOVER (RECOMENDADO)

Esses são os mais seguros para limpeza 👇

```bash
brew uninstall telnet
brew uninstall mercurial
brew uninstall guile
brew uninstall lua
brew uninstall openjdk
brew uninstall python@3.14
```

---

# ⚠️ REMOÇÃO CONDICIONAL (verifique antes)

Use antes:

```bash
brew uses --installed --recursive NOME
```

Itens:

- httpd → Apache (provavelmente não usa)
- openvpn → só se usa VPN
- unbound → DNS server local
- pandoc → se não converte docs
- csvkit → se não usa CSV CLI
- protobuf → se não usa gRPC
- mdbtools → se não mexe mais com Access

---

# 🧩 DEPENDÊNCIAS (NÃO REMOVER MANUALMENTE)

Esses você NÃO mexe:

- lib*
- xorgproto
- cairo
- freetype
- fontconfig
- icu4c
- libpng
- libxml
- etc

👉 São usadas por outras libs

---

# 🧠 ANÁLISE FINAL DO SEU AMBIENTE

Você está com um ambiente:

✔ limpo  
✔ organizado  
✔ sem lixo crítico  
✔ com boas ferramentas  

👉 Agora só falta **enxugar o que não usa**

---

# 🚀 PRÓXIMO PASSO (RECOMENDADO)

Depois de ajustar:

```bash
brew bundle dump --force
```

👉 cria seu setup definitivo

---

# 🎯 RESUMO DIRETO

Pode remover agora com segurança:

- telnet
- mercurial
- guile
- lua
- openjdk (sem versão)
- python@3.14 (se não usa)

E avaliar:

- httpd
- openvpn
- unbound
- pandoc
- protobuf
- csvkit

---

Se quiser, no próximo passo eu faço:

👉 um **Brewfile ultra enxuto perfeito pro seu perfil (Java + Spring + Docker)**  
"""

path = Path("/mnt/data/homebrew-inventario-atualizado.md")
path.write_text(content, encoding="utf-8")
path