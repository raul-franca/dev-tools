# Atalhos — Zed (macOS)

Referência rápida. Sua base é o keymap **JetBrains** (`base_keymap`), com os
atalhos personalizados por cima. Detalhes e exemplos: [`ZED.md`](ZED.md).

> Os atalhos marcados como *padrão* foram conferidos no keymap oficial do Zed
> (`assets/keymaps/macos/jetbrains.json` sobre `default-macos.json`) — o base
> keymap é uma camada **por cima** do padrão, então ele sobrescreve algumas
> teclas. Para ver o que está valendo de fato na sua máquina:
> `Cmd+Shift+A` → **zed: open keymap**, ou `dev: open key context view`.

## Seus atalhos personalizados

| Atalho | Onde | O que faz |
|---|---|---|
| `Cmd+Enter` | terminal focado | envia `Esc` + `Enter` para o terminal |
| `Cmd+Enter` | arquivo `.md` | roda no terminal o bloco de código sob o cursor |
| `Cmd+Enter` | arquivo `.http` | roda **todas** as requisições (`httpyac --all`) |
| `Cmd+Shift+Enter` | arquivo `.http` | roda só o `login` (task `http: login`) |
| `` Ctrl+` `` | qualquer lugar | abre o terminal já no diretório do arquivo atual |
| `Ctrl+Alt+T` | workspace | mostra/esconde o painel do terminal |
| `Cmd+.` | editor | seleciona tudo, copia, abre o terminal e cola |
| `Cmd+.` | terminal | mostra/esconde o painel do terminal |

O `Ctrl+`` ` `` padrão (`terminal_panel::Toggle`) está **desvinculado** de
propósito — no seu setup ele só faz abrir o terminal, via `OpenInTerminal`.

## Terminal

| Atalho | O que faz |
|---|---|
| `` Ctrl+` `` | abre um terminal no diretório do arquivo (personalizado) |
| `Ctrl+Alt+T` | alterna o painel do terminal (personalizado) |
| `Cmd+.` | alterna o painel do terminal, com o terminal focado (personalizado) |
| `Cmd+Enter` | manda `Esc`+`Enter` (personalizado) |
| `Cmd+N` | novo terminal (padrão) |
| `Cmd+C` / `Cmd+V` | copiar / colar no terminal (padrão) |

## Navegação (base JetBrains)

| Atalho | O que faz |
|---|---|
| `Cmd+Shift+A` ou `Shift Shift` | paleta de comandos |
| `Cmd+E`, `Cmd+Shift+O` ou `Cmd+Shift+N` | ir para arquivo (file finder) |
| `Cmd+B` | ir para a definição |
| `Cmd+L` | ir para a linha |
| `Cmd+}` | próxima aba |
| `Cmd+P` | mostrar assinatura/parâmetros do método |
| `Cmd+1` | painel de arquivos (projeto) |
| `Cmd+0` | painel do Git |
| `Cmd+6` | painel de diagnósticos do projeto |

Atenção: **no seu setup `Cmd+0` é o painel do Git**, não o "resetar tamanho da
fonte" do keymap padrão — o JetBrains sobrescreve essa tecla.

## Edição

| Atalho | O que faz |
|---|---|
| `Cmd+S` / `Cmd+Shift+S` | salvar / salvar como |
| `Cmd+Z` | desfazer |
| `Cmd+X` / `Cmd+C` / `Cmd+V` | recortar / copiar / colar |
| `Cmd+A` | selecionar tudo |
| `Cmd+/` | comentar/descomentar linha |
| `Shift+F6` | renomear símbolo (refactor) |
| `Cmd+Alt+L` | formatar (Prettier habilitado nas suas settings) |
| `Shift+Alt+↑` | mover a linha para cima |
| `Ctrl+G` | selecionar a próxima ocorrência da seleção |

## Busca

| Atalho | O que faz |
|---|---|
| `Cmd+F` | buscar no arquivo |
| `Cmd+R` | buscar e substituir no arquivo |
| `Cmd+Shift+F` | busca dentro do diretório selecionado (painel de arquivos focado) |
| `Cmd+Shift+R` | buscar e substituir no projeto inteiro |
| `Cmd+T` | símbolos do projeto |

## Fonte (tamanho)

| Atalho | O que faz | Grava? |
|---|---|---|
| `Cmd+=` / `Cmd++` | aumenta a fonte do **editor** | não (temporário) |
| `Cmd+-` | diminui a fonte do editor | não (temporário) |
| `Ctrl+Shift+.` | aumenta a fonte do editor | **sim**, salva no `settings.json` |
| `Ctrl+Shift+,` | diminui a fonte do editor | **sim**, salva no `settings.json` |

Não há atalho para a fonte da **UI** (menus, painéis) fora das telas de boas-vindas,
nem para a do **terminal**. Essas só via `settings.json`:

```json
{
  "ui_font_size": 16,
  "buffer_font_size": 16,
  "terminal": { "font_size": 14 }
}
```

## Settings e utilitários

| Atalho | O que faz |
|---|---|
| `Cmd+,` | abre a UI de configurações |
| `Cmd+Alt+,` | abre o `settings.json` cru |
| `Cmd+K Cmd+S` | abre o keymap |
| `Cmd+Shift+P` | abrir a paleta pelo nome da tarefa (útil: `task: spawn`) |
| `Cmd+Q` | sair |
