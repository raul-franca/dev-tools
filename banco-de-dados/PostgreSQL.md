# PostgreSQL — Cheatsheet

Referência de comandos PostgreSQL para desenvolvimento backend: psql, DDL, CRUD, JSONB, índices, backup, diagnóstico e tuning.

> **Versões:** série estável atual é a **18.x**; 17, 16 e 15 seguem com suporte. Ubuntu 24.04 traz o 16 nos repositórios oficiais — use o repositório PGDG para versões mais novas.
> **Instalação:** macOS → `brew install postgresql@17` · Docker → `postgres:17-alpine` · Ubuntu → seção 1.

---

## 1. Instalação e conexão

### macOS (Homebrew)

```bash
brew install postgresql@17
brew services start postgresql@17
brew services stop postgresql@17
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc

createdb minha_db                        # criar banco pelo terminal
dropdb minha_db
psql postgres                            # conectar no banco padrão
```

### Ubuntu / VPS (repositório PGDG)

```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh   # adiciona o repo oficial
sudo apt install -y postgresql-17 postgresql-client-17

sudo systemctl status postgresql
sudo -u postgres psql                    # acesso administrativo local (peer auth)
```

### Docker (recomendado para desenvolvimento)

```bash
docker run -d --name pg \
  -e POSTGRES_PASSWORD=senha \
  -e POSTGRES_USER=app \
  -e POSTGRES_DB=minha_db \
  -p 127.0.0.1:5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:17-alpine

docker exec -it pg psql -U app -d minha_db
```

### Strings de conexão

```bash
psql -U usuario -d banco                                  # local
psql -h 203.0.113.10 -p 5432 -U app -d minha_db          # remoto
psql "postgresql://app:senha@localhost:5432/minha_db"    # URI
psql "postgresql://app@host/db?sslmode=require"          # com SSL

psql -U app -d minha_db -c "SELECT version();"           # comando avulso
psql -U app -d minha_db -f script.sql                    # executar arquivo

# Senha sem prompt (arquivo ~/.pgpass, permissão 600)
# host:porta:banco:usuario:senha
echo "203.0.113.10:5432:minha_db:app:senha" >> ~/.pgpass && chmod 600 ~/.pgpass

# Variáveis de ambiente reconhecidas pelo psql/libpq
export PGHOST=localhost PGPORT=5432 PGUSER=app PGDATABASE=minha_db PGPASSWORD=senha
```

---

## 2. psql — meta-comandos

O `psql` tem uma linguagem própria de atalhos, todos começando com `\`. É o que mais economiza tempo no dia a dia.

```
\l              Listar bancos                    \du            Listar roles/usuários
\c banco        Conectar a outro banco           \dn            Listar schemas
\dt             Listar tabelas                   \df            Listar funções
\dt+            Tabelas com tamanho              \dv            Listar views
\d tabela       Estrutura da tabela              \di            Listar índices
\d+ tabela      Estrutura detalhada              \dx            Listar extensões instaladas
\dp tabela      Permissões da tabela             \s             Histórico de comandos

\x              Alterna saída expandida (ótimo para linhas largas)
\timing         Liga/desliga o tempo de execução das queries
\e              Abre a última query no editor ($EDITOR)
\i arquivo.sql  Executa um arquivo SQL
\o saida.txt    Redireciona a saída para arquivo
\copy ...       COPY executado no CLIENTE (não precisa de superuser)
\conninfo       Mostra a conexão atual
\q              Sair
```

### Importar e exportar CSV

```sql
-- Do lado do cliente (\copy) — usa caminhos da SUA máquina
\copy clientes FROM '/Users/raul/dados/clientes.csv' WITH (FORMAT csv, HEADER true);
\copy (SELECT * FROM pedidos WHERE status = 'pago') TO '/tmp/pagos.csv' WITH (FORMAT csv, HEADER true);

-- Do lado do servidor (COPY) — caminho no SERVIDOR, exige permissão
COPY clientes FROM '/var/lib/postgresql/clientes.csv' WITH (FORMAT csv, HEADER true);
```

---

## 3. Bancos, schemas e roles

```sql
-- Bancos
CREATE DATABASE minha_db WITH ENCODING 'UTF8' LC_COLLATE 'pt_BR.UTF-8' TEMPLATE template0;
DROP DATABASE minha_db;
SELECT current_database();

-- Schemas (o Postgres separa banco de schema; o padrão é "public")
CREATE SCHEMA relatorios;
DROP SCHEMA relatorios CASCADE;
SET search_path TO relatorios, public;      -- ordem de busca de objetos
SHOW search_path;
```

### Roles e permissões

```sql
-- No Postgres, usuário e grupo são a mesma coisa: ROLE
CREATE ROLE app WITH LOGIN PASSWORD 'senha';
CREATE ROLE somente_leitura;                          -- role sem login = grupo
ALTER ROLE app WITH PASSWORD 'nova_senha';
ALTER ROLE app WITH CREATEDB;
DROP ROLE app;

-- Permissões
GRANT CONNECT ON DATABASE minha_db TO app;
GRANT USAGE ON SCHEMA public TO app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app;

-- Permissões para tabelas CRIADAS NO FUTURO (a pegadinha clássica)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;

-- Role só de leitura para BI/dashboards
CREATE ROLE bi WITH LOGIN PASSWORD 'senha';
GRANT CONNECT ON DATABASE minha_db TO bi;
GRANT USAGE ON SCHEMA public TO bi;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bi;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO bi;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM app;
\du                                                   -- conferir roles
```

### pg_hba.conf — quem pode conectar de onde

```bash
sudo -u postgres psql -c "SHOW hba_file;"     # descobrir o caminho
# /etc/postgresql/17/main/pg_hba.conf

# TIPO  BANCO    USUÁRIO  ENDEREÇO         MÉTODO
# local  all     all                       peer          # socket local pelo usuário do SO
# host   all     all      127.0.0.1/32     scram-sha-256 # senha (padrão moderno)
# host   minha_db app     10.0.0.0/8       scram-sha-256

sudo systemctl reload postgresql              # aplica sem derrubar conexões
```

---

## 4. Tabelas e tipos de dados

```sql
CREATE TABLE clientes (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- prefira a SERIAL
    uuid        uuid NOT NULL DEFAULT gen_random_uuid(),
    nome        text NOT NULL,
    cpf         varchar(11) UNIQUE,
    email       text UNIQUE,
    ativo       boolean NOT NULL DEFAULT true,
    saldo       numeric(12,2) NOT NULL DEFAULT 0,
    tags        text[],                                            -- array nativo
    metadados   jsonb NOT NULL DEFAULT '{}'::jsonb,
    criado_em   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT cpf_11_digitos CHECK (cpf ~ '^[0-9]{11}$')
);

CREATE TABLE pedidos (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id  bigint NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    total       numeric(12,2) NOT NULL,
    status      text NOT NULL DEFAULT 'pendente',
    criado_em   timestamptz NOT NULL DEFAULT now()
);
```

### Alterações de estrutura

```sql
ALTER TABLE clientes ADD COLUMN telefone text;
ALTER TABLE clientes DROP COLUMN telefone;
ALTER TABLE clientes RENAME COLUMN nome TO nome_completo;
ALTER TABLE clientes ALTER COLUMN email SET NOT NULL;
ALTER TABLE clientes ALTER COLUMN saldo TYPE numeric(14,2);
ALTER TABLE clientes ADD CONSTRAINT email_unico UNIQUE (email);
ALTER TABLE clientes DROP CONSTRAINT email_unico;
ALTER TABLE clientes RENAME TO clientes_old;

TRUNCATE TABLE pedidos;                        -- esvazia (rápido, não dispara DELETE)
TRUNCATE TABLE pedidos RESTART IDENTITY CASCADE;
DROP TABLE pedidos;
DROP TABLE IF EXISTS pedidos CASCADE;
```

### Tipos mais usados

| Tipo | Uso |
|---|---|
| `bigint` / `integer` | Inteiros; com `GENERATED ALWAYS AS IDENTITY` para chaves |
| `numeric(p,s)` | Dinheiro e valores exatos — **nunca use `float` para dinheiro** |
| `text` / `varchar(n)` | Texto; no Postgres `text` não é mais lento que `varchar` |
| `boolean` | `true` / `false` (aceita `'t'`, `'f'`) |
| `timestamptz` | Data/hora **com fuso** — o padrão recomendado |
| `date`, `time`, `interval` | Data, hora e duração |
| `uuid` | Chaves distribuídas (`gen_random_uuid()`, nativo desde o PG 13) |
| `jsonb` | JSON binário, indexável — prefira ao `json` |
| `text[]`, `int[]` | Arrays nativos |
| `numrange`, `tstzrange` | Intervalos (períodos de vigência, reservas) |
| `bytea` | Dados binários |

> [!TIP]
> `SERIAL` ainda funciona, mas o padrão SQL moderno é `GENERATED ALWAYS AS IDENTITY` — evita o problema de sequences órfãs e de `INSERT` sobrescrevendo o contador.

---

## 5. CRUD e recursos que o MySQL não tem

```sql
-- INSERT com retorno (dispensa um SELECT depois)
INSERT INTO clientes (nome, email) VALUES ('Ana', 'ana@ex.com') RETURNING id, criado_em;

-- Múltiplas linhas
INSERT INTO clientes (nome, email) VALUES ('Bia','b@ex.com'), ('Caio','c@ex.com');

-- UPSERT (equivalente ao ON DUPLICATE KEY UPDATE do MySQL)
INSERT INTO clientes (email, nome) VALUES ('ana@ex.com', 'Ana Silva')
ON CONFLICT (email) DO UPDATE SET nome = EXCLUDED.nome, criado_em = now();

INSERT INTO clientes (email, nome) VALUES ('ana@ex.com', 'Ana')
ON CONFLICT DO NOTHING;                       -- ignora duplicado

-- UPDATE com JOIN (sintaxe FROM)
UPDATE pedidos p
SET status = 'bloqueado'
FROM clientes c
WHERE p.cliente_id = c.id AND c.ativo = false
RETURNING p.id;

-- DELETE com JOIN (sintaxe USING)
DELETE FROM pedidos p USING clientes c
WHERE p.cliente_id = c.id AND c.ativo = false;

-- CTE que escreve (mover linhas em uma única transação implícita)
WITH movidos AS (
    DELETE FROM pedidos WHERE criado_em < now() - interval '2 years' RETURNING *
)
INSERT INTO pedidos_arquivo SELECT * FROM movidos;

-- DISTINCT ON — a linha mais recente por grupo (exclusivo do Postgres)
SELECT DISTINCT ON (cliente_id) cliente_id, id, total, criado_em
FROM pedidos
ORDER BY cliente_id, criado_em DESC;

-- Paginação por keyset (muito melhor que OFFSET em tabelas grandes)
SELECT * FROM pedidos WHERE id > 1000 ORDER BY id LIMIT 50;
```

Para `SELECT` avançado (joins, window functions, CTE, subselects), veja [SQL-Select.md](SQL-Select.md) — quase tudo lá vale para o Postgres.

---

## 6. Datas, strings e JSONB

```sql
-- Datas (o Postgres usa "interval", não DATE_ADD)
SELECT now(), current_date, current_timestamp;
SELECT now() - interval '30 days';
SELECT date_trunc('month', criado_em) AS mes, count(*) FROM pedidos GROUP BY 1 ORDER BY 1;
SELECT age(now(), '1990-05-20'::date);
SELECT to_char(now(), 'DD/MM/YYYY HH24:MI');          -- formatação pt-BR
SELECT to_date('28/08/2026', 'DD/MM/YYYY');
SELECT extract(year FROM criado_em), extract(dow FROM criado_em);
SELECT generate_series('2026-01-01'::date, '2026-12-01'::date, '1 month');

-- Strings
SELECT 'a' || 'b';                                    -- concatenação (não CONCAT_WS por padrão)
SELECT concat_ws(' - ', nome, email) FROM clientes;
SELECT upper(nome), lower(email), initcap(nome) FROM clientes;
SELECT trim(both ' ' FROM nome), left(nome, 3), right(nome, 3);
SELECT regexp_replace(cpf, '(\d{3})(\d{3})(\d{3})(\d{2})', '\1.\2.\3-\4');
SELECT nome ILIKE '%silva%' FROM clientes;            -- ILIKE = LIKE sem case-sensitive
SELECT split_part('a;b;c', ';', 2);                   -- 'b'
SELECT string_agg(nome, ', ' ORDER BY nome) FROM clientes;   -- = GROUP_CONCAT do MySQL

-- Arrays
SELECT * FROM clientes WHERE 'vip' = ANY(tags);
SELECT * FROM clientes WHERE tags @> ARRAY['vip','ativo'];   -- contém todos
SELECT unnest(tags) FROM clientes;                            -- explode em linhas
SELECT array_agg(DISTINCT status) FROM pedidos;
```

### JSONB

```sql
-- Operadores
SELECT metadados -> 'endereco'            FROM clientes;   -- retorna jsonb
SELECT metadados ->> 'origem'             FROM clientes;   -- retorna text
SELECT metadados #> '{endereco,cidade}'   FROM clientes;   -- caminho, jsonb
SELECT metadados #>> '{endereco,cidade}'  FROM clientes;   -- caminho, text

-- Filtros
SELECT * FROM clientes WHERE metadados @> '{"origem":"site"}';         -- contém
SELECT * FROM clientes WHERE metadados ? 'origem';                     -- tem a chave
SELECT * FROM clientes WHERE (metadados ->> 'idade')::int > 30;

-- Escrita
UPDATE clientes SET metadados = metadados || '{"vip": true}'::jsonb WHERE id = 1;
UPDATE clientes SET metadados = jsonb_set(metadados, '{endereco,cidade}', '"Recife"') WHERE id = 1;
UPDATE clientes SET metadados = metadados - 'vip' WHERE id = 1;        -- remove chave

-- Explodir e agregar
SELECT id, chave, valor FROM clientes, jsonb_each_text(metadados) AS j(chave, valor);
SELECT jsonb_agg(jsonb_build_object('id', id, 'nome', nome)) FROM clientes;

-- Índice para busca em jsonb (obrigatório se filtrar por @>)
CREATE INDEX idx_clientes_meta ON clientes USING gin (metadados);
CREATE INDEX idx_clientes_meta_path ON clientes USING gin (metadados jsonb_path_ops);  -- menor e mais rápido só para @>
```

---

## 7. Índices

```sql
-- B-tree (padrão): igualdade, ordenação, ranges
CREATE INDEX idx_pedidos_cliente ON pedidos (cliente_id);
CREATE INDEX idx_pedidos_criado ON pedidos (criado_em DESC);
CREATE UNIQUE INDEX idx_clientes_email ON clientes (lower(email));   -- índice por expressão

-- Composto: a ORDEM importa (serve para cliente_id e para cliente_id+criado_em)
CREATE INDEX idx_pedidos_cli_data ON pedidos (cliente_id, criado_em DESC);

-- Parcial: indexa só o subconjunto consultado — muito menor
CREATE INDEX idx_pedidos_pendentes ON pedidos (criado_em) WHERE status = 'pendente';

-- GIN: jsonb, arrays e full-text
CREATE INDEX idx_clientes_tags ON clientes USING gin (tags);

-- Busca textual (full-text em português)
CREATE INDEX idx_clientes_busca ON clientes
  USING gin (to_tsvector('portuguese', nome || ' ' || coalesce(email, '')));

SELECT * FROM clientes
WHERE to_tsvector('portuguese', nome) @@ plainto_tsquery('portuguese', 'joão silva');

-- Trigram: LIKE '%texto%' com índice (exige a extensão)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_clientes_nome_trgm ON clientes USING gin (nome gin_trgm_ops);
SELECT * FROM clientes WHERE nome ILIKE '%silv%';

-- BRIN: tabelas enormes e naturalmente ordenadas (logs por data) — índice minúsculo
CREATE INDEX idx_logs_data ON logs USING brin (criado_em);

-- Criar/remover SEM travar a tabela (obrigatório em produção)
CREATE INDEX CONCURRENTLY idx_pedidos_status ON pedidos (status);
DROP INDEX CONCURRENTLY idx_pedidos_status;

\di+                                    -- listar índices com tamanho
REINDEX INDEX CONCURRENTLY idx_pedidos_cliente;
```

### Índices que não estão sendo usados

```sql
SELECT schemaname, relname AS tabela, indexrelname AS indice,
       idx_scan AS usos, pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0 AND NOT indisunique
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## 8. EXPLAIN e análise de planos

```sql
EXPLAIN SELECT * FROM pedidos WHERE cliente_id = 10;              -- plano estimado
EXPLAIN ANALYZE SELECT * FROM pedidos WHERE cliente_id = 10;      -- EXECUTA e mede
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;               -- + leitura de disco/cache
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS) SELECT ...;
```

O que procurar na saída:

| Sinal | Significado | Ação |
|---|---|---|
| `Seq Scan` em tabela grande | Varredura completa | Criar índice para o filtro |
| `rows=1000` estimado vs `rows=900000` real | Estatísticas desatualizadas | `ANALYZE tabela;` |
| `Nested Loop` com muitas linhas | Join ruim para o volume | Índice na coluna de join, revisar `work_mem` |
| `external merge Disk: 50MB` | Ordenação estourou a memória | Aumentar `work_mem` na sessão |
| `Filter: ... Rows Removed by Filter: 900k` | Lendo muito e descartando | Índice parcial ou composto |

```sql
SET work_mem = '64MB';                  -- só para a sessão atual
ANALYZE pedidos;                        -- atualiza estatísticas do planner
```

> [!TIP]
> Cole o resultado do `EXPLAIN (ANALYZE, BUFFERS)` em <https://explain.dalibo.com> para ver o plano em árvore, com os gargalos destacados.

---

## 9. Transações e locks

```sql
BEGIN;
UPDATE contas SET saldo = saldo - 100 WHERE id = 1;
UPDATE contas SET saldo = saldo + 100 WHERE id = 2;
COMMIT;                                 -- ou ROLLBACK;

-- Savepoints
BEGIN;
  INSERT INTO pedidos (cliente_id, total) VALUES (1, 50);
  SAVEPOINT sp1;
  UPDATE pedidos SET total = 0;         -- ops
  ROLLBACK TO sp1;                      -- desfaz só até o savepoint
COMMIT;

-- Níveis de isolamento (padrão: READ COMMITTED)
BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN ISOLATION LEVEL SERIALIZABLE;     -- pode falhar com erro 40001 → sua app deve repetir

-- Locks explícitos
SELECT * FROM pedidos WHERE id = 1 FOR UPDATE;           -- trava a linha
SELECT * FROM pedidos WHERE id = 1 FOR UPDATE NOWAIT;    -- falha se já travada
SELECT * FROM fila ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 1;   -- padrão de fila de trabalho
```

> [!WARNING]
> No Postgres, **DDL é transacional**: `CREATE TABLE`, `ALTER TABLE` e até `DROP` podem ir dentro de `BEGIN/COMMIT` e sofrer rollback. Isso é o que torna migrations (Flyway, Alembic) muito mais seguras que no MySQL.

---

## 10. Views, funções e triggers

```sql
-- View
CREATE VIEW vw_pedidos_cliente AS
SELECT c.nome, count(p.id) AS pedidos, sum(p.total) AS total
FROM clientes c LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.nome;

CREATE OR REPLACE VIEW vw_pedidos_cliente AS SELECT ...;
DROP VIEW vw_pedidos_cliente;

-- Materialized view: resultado gravado em disco (ótimo para dashboards)
CREATE MATERIALIZED VIEW mv_vendas_mes AS
SELECT date_trunc('month', criado_em) AS mes, sum(total) AS total
FROM pedidos GROUP BY 1;

CREATE UNIQUE INDEX ON mv_vendas_mes (mes);              -- necessário para o refresh concorrente
REFRESH MATERIALIZED VIEW mv_vendas_mes;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_vendas_mes;    -- sem bloquear leituras
```

### Função PL/pgSQL

```sql
CREATE OR REPLACE FUNCTION formata_cpf(p_cpf text)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF p_cpf IS NULL OR length(p_cpf) <> 11 THEN
        RETURN p_cpf;
    END IF;
    RETURN regexp_replace(p_cpf, '(\d{3})(\d{3})(\d{3})(\d{2})', '\1.\2.\3-\4');
END;
$$;

SELECT formata_cpf('12345678901');       -- 123.456.789-01
```

### Trigger de `atualizado_em`

```sql
CREATE OR REPLACE FUNCTION set_atualizado_em()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_clientes_atualizado
BEFORE UPDATE ON clientes
FOR EACH ROW EXECUTE FUNCTION set_atualizado_em();

DROP TRIGGER trg_clientes_atualizado ON clientes;
```

---

## 11. Backup e restauração

```bash
# Dump lógico de um banco
pg_dump -U app -d minha_db -F c -f backup.dump          # formato custom (recomendado)
pg_dump -U app -d minha_db -f backup.sql                # SQL puro
pg_dump -U app -d minha_db -F c -Z 9 -f backup.dump     # comprimido
pg_dump -U app -d minha_db -t clientes -F c -f tab.dump # só uma tabela
pg_dump -U app -d minha_db --schema-only -f schema.sql  # só a estrutura
pg_dump -U app -d minha_db --data-only -f dados.sql     # só os dados

# Restaurar
pg_restore -U app -d minha_db backup.dump
pg_restore -U app -d minha_db --clean --if-exists backup.dump    # recria objetos
pg_restore -U app -d minha_db -j 4 backup.dump                   # paralelo (mais rápido)
psql -U app -d minha_db -f backup.sql                            # se for SQL puro

# Todos os bancos + roles do cluster
pg_dumpall -U postgres -f cluster.sql
pg_dumpall -U postgres --roles-only -f roles.sql

# Dentro do Docker
docker exec -t pg pg_dump -U app -F c minha_db > backup-$(date +%F).dump
cat backup.dump | docker exec -i pg pg_restore -U app -d minha_db --clean
```

Rotina diária na VPS (ver [../backend/VPS-Ubuntu.md](../backend/VPS-Ubuntu.md)):

```bash
0 3 * * * docker exec -t pg pg_dump -U app -F c minha_db > /backups/pg-$(date +\%F).dump && find /backups -name 'pg-*.dump' -mtime +7 -delete
```

---

## 12. Manutenção (VACUUM e autovacuum)

O Postgres não apaga linhas na hora: um `UPDATE`/`DELETE` deixa versões mortas (*dead tuples*) que o `VACUUM` recolhe. Ignorar isso é a causa nº 1 de banco inchado e lento.

```sql
VACUUM tabela;                          -- recolhe espaço para reuso (não bloqueia)
VACUUM ANALYZE tabela;                  -- + atualiza estatísticas
VACUUM FULL tabela;                     -- reescreve a tabela e devolve disco ao SO — BLOQUEIA TUDO
ANALYZE tabela;                         -- só estatísticas

-- Quem está inchado?
SELECT relname, n_live_tup, n_dead_tup,
       round(n_dead_tup * 100.0 / nullif(n_live_tup + n_dead_tup, 0), 1) AS pct_morto,
       last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;

-- Autovacuum mais agressivo em tabela de alta rotatividade
ALTER TABLE pedidos SET (autovacuum_vacuum_scale_factor = 0.05);
```

---

## 13. Diagnóstico e monitoramento

```sql
-- Tamanhos
SELECT pg_size_pretty(pg_database_size(current_database()));
SELECT relname AS tabela,
       pg_size_pretty(pg_total_relation_size(relid)) AS total,
       pg_size_pretty(pg_relation_size(relid))       AS dados,
       pg_size_pretty(pg_indexes_size(relid))        AS indices
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC LIMIT 20;

-- Conexões e queries em andamento
SELECT pid, usename, state, wait_event_type, now() - query_start AS duracao, left(query, 80)
FROM pg_stat_activity
WHERE state <> 'idle' AND pid <> pg_backend_pid()
ORDER BY duracao DESC;

-- Matar uma query travada
SELECT pg_cancel_backend(12345);        -- pede cancelamento (educado)
SELECT pg_terminate_backend(12345);     -- derruba a conexão

-- Bloqueios (quem trava quem)
SELECT blocked.pid AS bloqueado, blocking.pid AS bloqueador,
       left(blocked.query, 60) AS query_bloqueada
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0;

-- Cache hit ratio (saudável: > 0.99)
SELECT sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0) AS hit_ratio
FROM pg_statio_user_tables;
```

### pg_stat_statements — as queries mais caras

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- exige em postgresql.conf: shared_preload_libraries = 'pg_stat_statements' (requer restart)

SELECT round(total_exec_time::numeric, 0) AS tempo_total_ms,
       calls, round(mean_exec_time::numeric, 2) AS media_ms,
       left(query, 90) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 15;

SELECT pg_stat_statements_reset();
```

---

## 14. Configuração e tuning

```sql
SHOW ALL;
SHOW shared_buffers;
SELECT name, setting, unit, source FROM pg_settings WHERE name LIKE '%mem%';
SELECT pg_reload_conf();                -- recarrega o postgresql.conf
```

Ponto de partida para uma VPS (ajuste conforme a RAM):

| Parâmetro | Sugestão | Para que serve |
|---|---|---|
| `shared_buffers` | 25% da RAM | Cache de páginas do próprio Postgres |
| `effective_cache_size` | 50–75% da RAM | Dica ao planner sobre cache do SO |
| `work_mem` | 8–64 MB | Memória por operação de sort/hash (cuidado: é por operação) |
| `maintenance_work_mem` | 256 MB–1 GB | VACUUM, CREATE INDEX |
| `max_connections` | 50–100 + pooler | Cada conexão é um processo; use PgBouncer acima disso |
| `random_page_cost` | 1.1 | Em SSD/NVMe (o padrão 4.0 assume disco mecânico) |
| `wal_compression` | on | Reduz I/O de WAL |

> [!TIP]
> Gere uma configuração base em <https://pgtune.leopard.in.ua> informando RAM, vCPUs e tipo de carga. Aplique com cuidado e uma mudança por vez.

---

## 15. Extensões úteis

```sql
SELECT * FROM pg_available_extensions ORDER BY name;
\dx                                          -- instaladas neste banco

CREATE EXTENSION IF NOT EXISTS pg_trgm;             -- LIKE '%x%' com índice, similaridade
CREATE EXTENSION IF NOT EXISTS unaccent;            -- remove acentos ("São" → "Sao")
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- estatísticas de queries
CREATE EXTENSION IF NOT EXISTS postgis;             -- dados geográficos
CREATE EXTENSION IF NOT EXISTS vector;              -- busca vetorial → PostgreSQL-Vetorial.md
CREATE EXTENSION IF NOT EXISTS uuid-ossp;           -- só se precisar de uuid_generate_v4()

-- Busca sem acento e sem case
SELECT * FROM clientes WHERE unaccent(lower(nome)) LIKE unaccent(lower('%joao%'));
```

---

## 16. Docker Compose com healthcheck

```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: minha_db
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:5432:5432"        # só o host acessa — nunca exponha 5432 na internet
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d minha_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  api:
    build: .
    environment:
      DATABASE_URL: postgresql+psycopg://app:${POSTGRES_PASSWORD}@db:5432/minha_db
    depends_on:
      db:
        condition: service_healthy    # espera o banco ficar PRONTO, não só iniciar
    restart: unless-stopped

volumes:
  pgdata:
```

---

## 17. Vindo do MySQL — equivalências

| MySQL | PostgreSQL |
|---|---|
| `SHOW DATABASES;` | `\l` |
| `USE banco;` | `\c banco` |
| `SHOW TABLES;` | `\dt` |
| `DESCRIBE tabela;` | `\d tabela` |
| `SHOW CREATE TABLE t;` | `\d+ t` (ou `pg_dump -t t --schema-only`) |
| `AUTO_INCREMENT` | `GENERATED ALWAYS AS IDENTITY` |
| `LIMIT 10, 20` | `LIMIT 20 OFFSET 10` |
| `IFNULL(a, b)` | `COALESCE(a, b)` |
| `NOW()`, `CURDATE()` | `now()`, `current_date` |
| `DATE_ADD(d, INTERVAL 1 DAY)` | `d + interval '1 day'` |
| `DATE_FORMAT(d, '%d/%m/%Y')` | `to_char(d, 'DD/MM/YYYY')` |
| `GROUP_CONCAT(x)` | `string_agg(x, ',')` |
| `CONCAT(a, b)` | `a \|\| b` ou `concat(a, b)` |
| `ON DUPLICATE KEY UPDATE` | `ON CONFLICT (col) DO UPDATE` |
| `LIKE` case-insensitive (padrão) | `ILIKE` (o `LIKE` é sensível a maiúsculas) |
| `SHOW PROCESSLIST;` | `SELECT * FROM pg_stat_activity;` |
| `KILL 123;` | `SELECT pg_terminate_backend(123);` |
| `mysqldump` | `pg_dump` |
| Backtick `` `coluna` `` | Aspas duplas `"coluna"` |

> [!CAUTION]
> No Postgres, identificadores sem aspas são **rebaixados para minúsculas**. `CREATE TABLE Clientes` cria a tabela `clientes`; já `CREATE TABLE "Clientes"` cria uma tabela que só pode ser referenciada como `"Clientes"`, para sempre. Use `snake_case` sem aspas e evite a dor de cabeça.

---

## 18. Troubleshooting

| Erro / sintoma | Causa provável | Correção |
|---|---|---|
| `FATAL: password authentication failed` | senha ou método no `pg_hba.conf` | conferir `scram-sha-256` e `~/.pgpass` |
| `FATAL: no pg_hba.conf entry for host` | IP não liberado | adicionar linha `host` + `reload` |
| `could not connect to server` | serviço parado ou `listen_addresses` | `systemctl status postgresql`; `listen_addresses = '*'` |
| `FATAL: sorry, too many clients already` | estourou `max_connections` | fechar conexões ociosas, usar PgBouncer |
| `deadlock detected` | ordem diferente de locks entre transações | padronizar ordem de atualização; repetir a transação |
| `could not serialize access` (40001) | isolamento `SERIALIZABLE` | a aplicação deve repetir a transação |
| Query lenta que era rápida | estatísticas velhas / bloat | `ANALYZE`; checar `n_dead_tup` |
| Disco crescendo sem parar | WAL retido por slot de replicação | `SELECT * FROM pg_replication_slots;` e remover slots inativos |
| `relation "Clientes" does not exist` | maiúsculas sem aspas | usar `clientes` minúsculo |
| `permission denied for table` | falta GRANT em objeto novo | `ALTER DEFAULT PRIVILEGES` (seção 3) |

---

## Ver também

- [PostgreSQL-Vetorial.md](PostgreSQL-Vetorial.md) — pgvector, embeddings, HNSW/IVFFlat e RAG
- [SQL-Select.md](SQL-Select.md) — SELECT avançado, CTE, window functions, JOINs
- [SQL-Dicas.md](SQL-Dicas.md) — índices, EXPLAIN, transações e performance
- [MySQL.md](MySQL.md) — o equivalente para MySQL
- [../backend/VPS-Ubuntu.md](../backend/VPS-Ubuntu.md) — rodar o Postgres em produção na VPS
- [../backend/Docker.md](../backend/Docker.md) — containers, Compose e volumes
