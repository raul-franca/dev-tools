# Meu Zed — personalizações e exemplos de uso

Tudo que foi ajustado no Zed: onde está, o que faz e como usar. Resumo dos
atalhos em [`ATALHOS.md`](ATALHOS.md).

Versão conferida: **Zed 1.23.2** (macOS).

## Onde ficam os arquivos

| Caminho | O que é |
|---|---|
| `~/.config/zed/settings.json` | configurações gerais (tema, fonte, painéis, IA…) |
| `~/.config/zed/keymap.json` | atalhos de teclado |
| `~/.config/zed/tasks.json` | tasks **globais** (aparecem em qualquer projeto) |
| `~/.config/zed/scripts/rodar-bloco.sh` | helper chamado pela task global "Rodar bloco de código" |
| `<projeto>/.zed/tasks.json` | tasks **do projeto** (só naquele projeto) |

Atalhos para chegar nos arquivos: `Cmd+,` (UI de settings), `Cmd+Alt+,`
(`settings.json` cru), `Cmd+K Cmd+S` (keymap).

## Base keymap: JetBrains

`settings.json` → `"base_keymap": "JetBrains"`.

Isso **não substitui** o keymap padrão do Zed: o JetBrains entra como uma camada
por cima, sobrescrevendo algumas teclas. Exemplos colhidos do próprio arquivo do
Zed (`assets/keymaps/macos/jetbrains.json`):

- `Cmd+B` = ir para definição (no padrão era `workspace::ToggleLeftDock`)
- `Cmd+0` = painel do Git (no padrão era "resetar tamanho da fonte")
- `Cmd+E` / `Cmd+Shift+O` / `Cmd+Shift+N` = file finder (no padrão era `Cmd+P`)
- `Cmd+P` = assinatura/parâmetros do método
- `Ctrl+Shift+.` e `Ctrl+Shift+,` = fonte do editor **gravando** no `settings.json`

## settings.json — o que está personalizado

### Aparência e fonte

```json
{
  "theme": { "mode": "system", "light": "One Light", "dark": "One Dark" },
  "ui_font_size": 16,
  "buffer_font_size": 16,
  "diagnostics": { "inline": { "enabled": true } },
  "git": { "inline_blame": { "show_commit_summary": true } }
}
```

- Tema segue o sistema (claro/escuro automático).
- Diagnósticos aparecem **na linha** (não só no painel).
- O git blame inline mostra o resumo do commit.

### Painéis

```json
{
  "project_panel": {
    "dock": "left",
    "hide_root": false,
    "git_status_indicator": true,
    "diagnostic_badges": true,
    "bold_folder_labels": true,
    "indent_size": 10.0,
    "default_width": 240.0
  },
  "outline_panel": { "dock": "right" },
  "collaboration_panel": { "dock": "right" },
  "git_panel": { "dock": "left" }
}
```

Projeto e Git à esquerda, outline e colaboração à direita. A árvore mostra status
do Git e badges de diagnóstico.

### Terminal

```json
{
  "terminal": {
    "shell": { "program": "/bin/zsh" },
    "copy_on_select": true,
    "working_directory": "current_project_directory",
    "dock": "bottom",
    "font_size": 14
  }
}
```

- Copiar já ao selecionar (sem `Cmd+C`).
- Sempre abre no diretório do projeto.
- Fonte menor que a do editor (14 vs 16).

### Edição e linguagens

```json
{
  "autosave": "on_focus_change",
  "prettier": { "allowed": true },
  "lsp": { "ltex": { "settings": { "ltex": { "language": "pt-BR" } } } }
}
```

- Salva ao trocar de aba/arquivo.
- Prettier autorizado a formatar (`Cmd+Alt+L`).
- LTeX (LanguageTool) configurado para **português (pt-BR)**.

### IA e agente

```json
{
  "disable_ai": false,
  "edit_predictions": { "mode": "eager", "provider": "zed" },
  "agent": {
    "dock": "left",
    "default_profile": "write",
    "default_model": {
      "provider": "deepseek",
      "model": "deepseek-flash",
      "effort": "high",
      "enable_thinking": true
    }
  }
}
```

- Sugestões inline agressivas (`eager`).
- Agente no painel esquerdo, perfil `write`, modelo DeepSeek Flash com esforço
  alto e raciocínio ligado.

### Permissões do agente (atenção)

```json
{
  "agent": {
    "sandbox_permissions": {
      "allow_unsandboxed": true,
      "write_paths": ["~/.local", "~/.npm"],
      "network_hosts": ["zed.dev", "registry.npmjs.org"]
    }
  }
}
```

Isso foi salvo ao aprovar a instalação do `httpyac` e as consultas à documentação
do Zed, escolhendo "lembrar". `allow_unsandboxed: true` significa que o agente
pode rodar comandos sem sandbox sem pedir de novo — vale revisar quando quiser
voltar a aprovar caso a caso.

### Outros

| Setting | Valor | Efeito |
|---|---|---|
| `session.trust_all_worktrees` | `true` | não pergunta "confia neste projeto?" (o Zed avisa que é arriscado) |
| `cli_default_open_behavior` | `existing_window` | `zed .` reusa a janela aberta |
| `telemetry.metrics` | `false` | não envia métricas |
| `instrumentation.performance_profiler.enabled` | `false` | profiler desligado |
| `proxy` | `""` | sem proxy |
| `ssh_connections` | `github.com` | host SSH salvo |

## keymap.json — cada atalho explicado

O arquivo, na ordem:

### 1. `Cmd+Enter` no terminal manda `Esc`+`Enter`

```json
{ "context": "Terminal", "bindings": {
  "cmd-enter": ["terminal::SendText", "\u001b\r"] } }
```

`\u001b` é `Esc` e `\r` é `Enter`. Uso: com um comando digitado no terminal,
`Cmd+Enter` fecha o autocompletar (`Esc`) e já executa (`Enter`).

### 2. `Cmd+Enter` em `.md` roda o bloco de código

```json
{ "context": "Editor && extension == md", "bindings": {
  "cmd-enter": ["task::Spawn", { "task_name": "Rodar bloco de código" }] } }
```

Uso: cursor dentro de um bloco de código `bash` do `README.md` → `Cmd+Enter`
roda aquele bloco no terminal. Serve para os `curl` de várias linhas, com as
continuações `\`.

### 3. `Ctrl+`` ` `` abre o terminal no diretório do arquivo

```json
{ "bindings": { "ctrl-`": "workspace::OpenInTerminal" } }
```

Sem contexto = vale em qualquer lugar. O terminal já abre no diretório do arquivo
atual, não só na raiz do projeto.

### 4. `Ctrl+Alt+T` alterna o painel do terminal

```json
{ "context": "Workspace", "bindings": { "ctrl-alt-t": "terminal_panel::ToggleFocus" } }
```

### 5. `Cmd+.` no editor joga o arquivo inteiro no terminal

```json
{ "context": "Editor", "bindings": {
  "cmd-.": ["workspace::SendKeystrokes", "cmd-a cmd-c ctrl-alt-t cmd-v"] } }
```

Seleciona tudo → copia → abre o terminal → cola. Era a gambiarra para "rodar o
que está no arquivo"; hoje o `Cmd+Enter` nos `.md` faz isso de forma correta.
Pegadinha: isso **sobrescreve o `Cmd+.` do Zed** (code actions) em qualquer editor.

### 6. `Cmd+.` no terminal alterna o painel

```json
{ "context": "Terminal", "bindings": { "cmd-.": "terminal_panel::ToggleFocus" } }
```

### 7. `Ctrl+`` ` `` padrão desvinculado

```json
{ "context": "Workspace", "unbind": { "ctrl-`": "terminal_panel::Toggle" } }
```

Garante que `` Ctrl+` `` só dispare o `OpenInTerminal` (item 3), e não o toggle
padrão.

### 8. `Cmd+Enter` / `Cmd+Shift+Enter` em `.http`

```json
{ "context": "Editor && extension == http", "bindings": {
  "cmd-enter":       ["task::Spawn", { "task_name": "http: tudo (request.http --all)" }],
  "cmd-shift-enter": ["task::Spawn", { "task_name": "http: login" }] } }
```

## Tasks

### Global — "Rodar bloco de código"

`~/.config/zed/tasks.json`:

```json
{
  "label": "Rodar bloco de código",
  "command": "$HOME/.config/zed/scripts/rodar-bloco.sh",
  "args": ["$ZED_FILE", "${ZED_ROW:1}"],
  "cwd": "$ZED_DIRNAME",
  "tags": ["bash-script"],
  "reveal": "always"
}
```

Duas partes importantes:

- `tags: ["bash-script"]` **sobrescreve o runnable padrão de Bash** do Zed
  (precedência: projeto > global > linguagem). É isso que faz o botão de play na
  margem de um bloco `bash` do markdown parar de rodar o `.md` e passar a rodar o
  bloco.
- `args`/`cwd` usam as variáveis do Zed: `$ZED_FILE` (arquivo atual), `$ZED_ROW`
  (linha do cursor) e `$ZED_DIRNAME` (diretório do arquivo).

### Do projeto — 10 tasks `http:`

Em `<projeto>/.zed/tasks.json` (hoje no `keycloak-full`): uma task para rodar
tudo e uma por requisição do `request.http`. Todas chamam o `httpyac`:

```text
http: tudo (request.http --all)   http: login        http: adminToken
http: health                      http: userinfo     http: adminUsers
http: discovery                   http: refresh      http: adminClients
                                  http: logout
```

Como o `request.http` usa `# @name` + `# @ref`, uma task de `userinfo` roda o
`login` antes sozinha.

## O script `rodar-bloco.sh`

Local: `~/.config/zed/scripts/rodar-bloco.sh` (executável).

Chamado como `rodar-bloco.sh <arquivo> <linha>`:

- Se o arquivo **não** for markdown → roda `bash <arquivo>` (comportamento padrão
  do runnable de Bash do Zed, mantido para não quebrar `.sh`).
- Se for `.md` → encontra o bloco de código que contém aquela linha e executa o
  conteúdo com `eval`, no terminal do Zed.
- Só executa blocos marcados como `bash`, `sh`, `zsh`, `ksh` ou `shell`. Bloco
  `json`, sem linguagem ou texto solto → recusa com mensagem, sem rodar nada.
- Se a linha não estiver em nenhum bloco, avisa e não faz nada.
- Aceita a linha vinda como 0-based ou 1-based (o Zed não documenta a base de
  `$ZED_ROW`): tenta a linha exata e, se não achar, a linha seguinte.

Usa `eval` de propósito, e não um subprocesso: assim as variáveis sobrevivem entre
blocos, o que casa com o `README.md` (a Etapa 7 define `TOKEN` e a Etapa 8 reusa).

### Por que ele existe

Bug conhecido do Zed ([zed-industries/zed#56592](https://github.com/zed-industries/zed/issues/56592)):
o botão de play em um bloco `bash` dentro de um `.md` executa o **arquivo**, ou
seja `bash README.md`. O pedido de rodar o conteúdo do fence
([#61539](https://github.com/zed-industries/zed/discussions/61539)) ainda não foi
implementado. Enquanto isso, o script faz esse trabalho.

Para testar sem o Zed:

```bash
~/.config/zed/scripts/rodar-bloco.sh README.md 137   # roda o curl da Etapa 7
~/.config/zed/scripts/rodar-bloco.sh README.md 24    # recusa: bloco sem linguagem
```

## Exemplos de uso

### Rodar um `curl` do README

1. Abra `README.md`.
2. Ponha o cursor dentro do bloco `bash` (Etapa 7, por exemplo).
3. `Cmd+Enter` — ou clique no play na margem.
4. O comando aparece no terminal já executado, com a resposta.

### Rodar as requisições do `request.http`

| O que você quer | Como |
|---|---|
| tudo, na ordem | `Cmd+Enter` no `request.http` |
| só o `login` | `Cmd+Shift+Enter` |
| `userinfo`, `adminUsers`, etc. | `Cmd+Shift+P` → `task: spawn` → `http: userinfo` |
| na mão, pelo terminal | `httpyac send request.http --name userinfo` |

### Abrir o terminal certo

`` Ctrl+` `` abre um terminal **no diretório do arquivo atual** — útil para rodar
um script que está ao lado dele.

### Ver os atalhos que estão valendo

`Cmd+Shift+A` → **zed: open keymap**. Para depurar contexto (por que uma tecla não
dispara): `dev: open key context view`.

## Pegadinhas conhecidas

- **`Cmd+0` não reseta a fonte** no seu setup: é o painel do Git (base JetBrains).
  Para voltar ao tamanho original, edite `buffer_font_size` no `settings.json`.
- **Fonte:** `Cmd+=`/`Cmd+-` são temporários (não gravam). `Ctrl+Shift+.`/
  `Ctrl+Shift+,` gravam no `settings.json` — se mexer neles, o valor fica salvo.
- **`Cmd+.` no editor** sobrescreve o "code actions" do Zed. Vale remover o item 5
  do keymap, já que o `Cmd+Enter` nos `.md` resolve o mesmo problema.
- **Cuidado com blocos destrutivos:** `Cmd+Enter` na Etapa 11 do `README.md` roda
  `docker compose down` e `rm -rf .docker/dbdata` — apaga o banco.
- O script **não** roda blocos `json`, sem linguagem ou `console` (com `$` de
  prompt), de propósito.

## Manutenção e rollback

Backups deixados no `~/.config/zed/`:

| Arquivo | De quando |
|---|---|
| `keymap.json.bak` / `.47dc542a.bak` / `.before-paste.bak` | edições anteriores suas |
| `keymap.json.bak-http` | antes de adicionar os atalhos do `.http` |
| `keymap.json.bak-bloco` | antes de renomear a task do `Cmd+Enter` nos `.md` |

Para desfazer qualquer um: `cp ~/.config/zed/keymap.json.bak-bloco ~/.config/zed/keymap.json`.

Lembretes:

- O keymap do Zed é **global** — não existe keymap por projeto.
- Ao contrário, tasks podem ser globais (`~/.config/zed/tasks.json`) ou do projeto
  (`<projeto>/.zed/tasks.json`), e as do projeto têm precedência.
