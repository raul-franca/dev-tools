# codebase-memory-mcp — Guia rápido

Referência prática para indexar repositórios e consultar a estrutura do código por meio do `codebase-memory-mcp`.

> **Versão verificada neste ambiente:** `0.10.8`
>
> O servidor está configurado no Codex em `~/.codex/config.toml` e também pode ser usado diretamente pelo comando `codebase-memory-mcp`.

---

## 1. O que é e como funciona

O `codebase-memory-mcp` é um servidor MCP que transforma um repositório em um grafo de conhecimento do código.

Em vez de procurar somente texto, ele analisa a estrutura do projeto e relaciona elementos como:

- arquivos, pastas e módulos;
- classes, interfaces, funções e métodos;
- imports e símbolos usados;
- chamadas entre funções (`CALLS`);
- rotas e chamadas HTTP (`HTTP_CALLS`);
- fluxos de dados e chamadas assíncronas;
- relações entre projetos, quando o modo cross-repo é usado.

O agente de IA usa esse grafo para responder perguntas estruturais, por exemplo:

- “Quem chama esta função?”
- “O que esta função chama?”
- “Quais são as rotas da aplicação?”
- “Qual é o impacto desta alteração?”
- “Existem funções possivelmente não utilizadas?”
- “Como a aplicação está organizada?”

### Fluxo normal

```text
Repositório
    │
    ▼
index_repository
    │  análise por linguagem + resolução de símbolos
    ▼
Grafo de arquivos, símbolos e relacionamentos
    │
    ├── search_graph       encontra elementos estruturais
    ├── trace_path         percorre chamadas e dependências
    ├── get_architecture   resume a arquitetura
    ├── get_code_snippet   lê o código de um símbolo
    ├── query_graph        executa consultas Cypher-like
    └── detect_changes     relaciona diff com impacto
```

O grafo não substitui a busca textual: para strings, mensagens de erro, valores de configuração ou comentários, use `grep`/`search_code`.

---

## 2. Integração com Codex e outros agentes

O executável pode funcionar como servidor MCP via `stdio`:

```bash
codebase-memory-mcp
```

No Codex, a configuração instalada é equivalente a:

```toml
[mcp_servers.codebase-memory-mcp]
command = "/Users/raulfranca/.local/bin/codebase-memory-mcp"
args = []
env_vars = ["CBM_CACHE_DIR", "CBM_RUNTIME_DIR"]
```

O projeto também possui hooks para enriquecer o contexto no início ou retomada de uma sessão e ao iniciar um subagente:

```bash
/Users/raulfranca/.local/bin/codebase-memory-mcp hook-augment
```

A disponibilidade dos tools depende do cliente MCP e da configuração dele. A forma mais simples de confirmar a integração é iniciar uma sessão do Codex e pedir uma análise estrutural de um projeto indexado.

---

## 3. Comandos gerais do executável

```bash
codebase-memory-mcp --version             # Mostra a versão instalada
codebase-memory-mcp --help                # Lista os modos disponíveis
codebase-memory-mcp                       # Inicia o servidor MCP em stdio

codebase-memory-mcp config list           # Lista configurações
codebase-memory-mcp config get auto_index # Consulta uma configuração
codebase-memory-mcp config set auto_index true
codebase-memory-mcp config reset auto_index

codebase-memory-mcp install --dry-run     # Mostra o que a instalação alteraria
codebase-memory-mcp update -n              # Simula atualização, sem confirmar
codebase-memory-mcp uninstall -n           # Simula remoção, sem confirmar
```

Opções da interface web do grafo:

```bash
codebase-memory-mcp --ui=true --port=9749
codebase-memory-mcp --ui=false
```

A interface usa a porta `9749` por padrão quando está habilitada.

---

## 4. Modo CLI

O modo CLI executa um tool, imprime o resultado e encerra:

```bash
codebase-memory-mcp cli [--progress] [--json] <tool> [argumentos]
```

A sintaxe preferida usa flags:

```bash
codebase-memory-mcp cli <tool> --flag valor
```

Também é possível fornecer JSON por stdin ou por arquivo:

```bash
echo '{"project":"NOME_DO_PROJETO"}' \
  | codebase-memory-mcp cli index_status

codebase-memory-mcp cli search_graph --args-file argumentos.json
```

> A passagem de um JSON bruto como último argumento ainda funciona, mas é considerada legada. Prefira flags, `--args-file` ou stdin.

---

## 5. Indexação

### Indexar um repositório

```bash
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/absoluto/do/projeto
```

O caminho absoluto evita ambiguidades. Para escolher o nome do projeto:

```bash
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/absoluto/do/projeto \
  --name meu-projeto
```

### Modos de indexação

```bash
# Arquivos filtrados, mais rápido; sem relações semânticas/similaridade
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/do/projeto --mode fast

# Arquivos filtrados com relações de similaridade/semânticas
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/do/projeto --mode moderate

# Todos os arquivos e relações semânticas/similaridade
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/do/projeto --mode full

# Relaciona rotas/canais entre projetos indexados
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/do/projeto \
  --mode cross-repo-intelligence \
  --target-projects '["*"]'
```

Use `--persistence true` quando quiser gerar um artefato compartilhável no próprio repositório:

```bash
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/do/projeto \
  --persistence true
```

### Ver projetos indexados e status

```bash
codebase-memory-mcp cli list_projects

codebase-memory-mcp cli index_status \
  --project NOME_RETORNADO_POR_list_projects
```

O nome do projeto deve ser usado exatamente como retornado por `list_projects`.

---

## 6. Principais consultas

### Encontrar funções, classes e símbolos

```bash
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --label Function \
  --name-pattern '.*Handler.*'
```

Filtros úteis:

```bash
# Procurar por caminho de arquivo
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --file-pattern 'src/**/*.ts'

# Busca textual indexada por relevância
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --query 'autenticação refresh token'

# Retornar apenas nomes qualificados, útil em listagens grandes
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --label Function \
  --detail ids
```

Paginação:

```bash
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --label Function \
  --limit 50 \
  --offset 50
```

Sempre observe `total` e `has_more` no resultado. Se `has_more` for `true`, continue com o próximo `offset`.

### Descobrir quem chama uma função

Primeiro encontre o nome exato; depois trace o caminho:

```bash
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --name-pattern '.*NomeDaFuncao.*'

codebase-memory-mcp cli trace_path \
  --project NOME_DO_PROJETO \
  --function-name NomeDaFuncao \
  --direction inbound \
  --depth 3
```

### Descobrir o que uma função chama

```bash
codebase-memory-mcp cli trace_path \
  --project NOME_DO_PROJETO \
  --function-name NomeDaFuncao \
  --direction outbound \
  --depth 3
```

Para os dois sentidos:

```bash
codebase-memory-mcp cli trace_path \
  --project NOME_DO_PROJETO \
  --function-name NomeDaFuncao \
  --direction both \
  --depth 3 \
  --risk-labels true \
  --include-evidence true
```

Modos de trace:

- `calls`: segue relações `CALLS`;
- `data_flow`: segue `CALLS` e `DATA_FLOWS`, incluindo expressões de argumentos;
- `cross_service`: segue chamadas HTTP, assíncronas e relações entre serviços/projetos.

### Entender a arquitetura

```bash
codebase-memory-mcp cli get_architecture \
  --project NOME_DO_PROJETO \
  --aspects overview
```

Para uma pasta específica:

```bash
codebase-memory-mcp cli get_architecture \
  --project NOME_DO_PROJETO \
  --path apps/api \
  --aspects overview
```

### Ler o código de um símbolo

Depois de descobrir o nome qualificado:

```bash
codebase-memory-mcp cli get_code_snippet \
  --project NOME_DO_PROJETO \
  --qualified-name 'projeto.src.modulo.NomeDaFuncao'
```

### Consultar rotas e chamadas entre serviços

```bash
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --label Route
```

Para ver as arestas reais, use `query_graph`:

```bash
codebase-memory-mcp cli query_graph \
  --project NOME_DO_PROJETO \
  --query 'MATCH (a)-[r:HTTP_CALLS]->(b) RETURN a.name, b.name, r.url_path, r.confidence LIMIT 20'
```

### Consultar o schema do grafo

```bash
codebase-memory-mcp cli get_graph_schema \
  --project NOME_DO_PROJETO
```

Use o schema antes de escrever consultas complexas.

### Detectar impacto das alterações locais

```bash
codebase-memory-mcp cli detect_changes \
  --project NOME_DO_PROJETO
```

Esse comando relaciona o diff do Git com símbolos e caminhos potencialmente afetados. Confira o código e os testes antes de aplicar qualquer conclusão.

### Procurar funções possivelmente não utilizadas

```bash
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --label Function \
  --relationship CALLS \
  --direction inbound \
  --max-degree 0 \
  --exclude-entry-points true
```

O resultado é um sinal para investigação, não uma prova de que o código pode ser removido: entry points, reflexão, configuração e integração externa podem não aparecer no grafo.

---

## 7. Verificação de cobertura e limites

Depois de obter candidatos no grafo, verifique se os arquivos relevantes foram indexados:

```bash
codebase-memory-mcp cli check_index_coverage \
  --project NOME_DO_PROJETO \
  --paths 'src/app.ts' 'src/modulo.ts'
```

Ou verifique um escopo:

```bash
codebase-memory-mcp cli check_index_coverage \
  --project NOME_DO_PROJETO \
  --scopes src
```

Regras práticas:

1. Atualize ou confirme o índice antes de uma análise importante.
2. Use `search_graph` para estrutura; use `grep`/`search_code` para texto.
3. Para `trace_path`, procure primeiro o nome exato.
4. Use `direction=both` quando callers e callees forem relevantes.
5. Confira paginação (`total`, `has_more` e `next`/`cursor`).
6. Para conclusões negativas ou exaustivas, confira a cobertura e leia os arquivos indicados.
7. O grafo ajuda a investigar; não substitui testes, revisão do diff ou leitura do código.

---

## 8. Configurações úteis

```bash
codebase-memory-mcp config list
codebase-memory-mcp config get auto_index
codebase-memory-mcp config get auto_watch
codebase-memory-mcp config set auto_index true
codebase-memory-mcp config set auto_index_limit 50000
codebase-memory-mcp config set watcher_enabled false
codebase-memory-mcp config reset auto_index
```

No ambiente documentado deste guia, a configuração verificada é:

```text
auto_index     = false
auto_index_limit = 50000
auto_watch     = true
ui_enabled     = true
ui_port        = 9749
```

Isso significa que o watcher está habilitado, mas a indexação automática está desabilitada; para garantir um índice atualizado, execute `index_repository` explicitamente quando necessário.

---

## 9. Receita de uso no dia a dia

```bash
# 1. Conferir o projeto
codebase-memory-mcp cli list_projects

# 2. Atualizar o índice
codebase-memory-mcp cli index_repository \
  --repo-path /caminho/absoluto/do/projeto

# 3. Entender a arquitetura
codebase-memory-mcp cli get_architecture \
  --project NOME_DO_PROJETO --aspects overview

# 4. Encontrar o símbolo relacionado à tarefa
codebase-memory-mcp cli search_graph \
  --project NOME_DO_PROJETO \
  --query 'termo da tarefa'

# 5. Conferir callers/callees
codebase-memory-mcp cli trace_path \
  --project NOME_DO_PROJETO \
  --function-name NomeExato \
  --direction both

# 6. Ver o impacto de mudanças locais
codebase-memory-mcp cli detect_changes \
  --project NOME_DO_PROJETO
```

No Codex, normalmente basta fazer a pergunta em linguagem natural, por exemplo:

```text
Analise a arquitetura deste projeto usando o codebase-memory e mostre o fluxo de autenticação.
```

```text
Encontre quem chama a função `NomeDaFuncao` e confira a cobertura dos arquivos envolvidos.
```

---

## 10. Comandos de diagnóstico

```bash
codebase-memory-mcp --version
codebase-memory-mcp --help
codebase-memory-mcp cli list_projects
codebase-memory-mcp config list

# Ver configurações do Codex relacionadas ao MCP
 grep -n -A 10 -B 2 'codebase-memory' ~/.codex/config.toml
```

Se uma consulta retornar zero resultados:

1. confirme o nome do projeto com `list_projects`;
2. reindexe usando caminho absoluto;
3. use `search_graph` com um padrão parcial;
4. confirme o nome qualificado antes de chamar `trace_path`;
5. verifique a cobertura com `check_index_coverage`.

---

## Referências

- Repositório oficial: <https://github.com/DeusData/codebase-memory-mcp>
- Configuração: <https://github.com/DeusData/codebase-memory-mcp/blob/main/docs/CONFIGURATION.md>
- Comando local: `codebase-memory-mcp --help`
- Ajuda dos tools: `codebase-memory-mcp cli <tool> --help`
