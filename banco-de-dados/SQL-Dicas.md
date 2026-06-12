# SQL — Dicas práticas e boas práticas

Este é um cheatsheet com dicas, recomendações e exemplos práticos para escrever consultas SQL mais seguras e performáticas. Exemplos voltados para MySQL, mas aplicáveis a outros bancos com pequenas adaptações.

---

## 1. Boas práticas gerais
- Prefira listar colunas explicitamente em vez de `SELECT *` (evita tráfego desnecessário e quebra mudanças de schema).
- Use aliases claros para tabelas (`u`, `p`, `c`) e colunas (`total_gasto`, `created_at`).
- Padronize nomes: snake_case ou camelCase (escolha um e seja consistente).
- Documente colunas importantes com comentários no schema (quando possível).

Exemplo:
SELECT id, nome, email FROM usuarios WHERE ativo = 1;

---

## 2. Índices
- Índice em colunas usadas em WHERE, JOIN e ORDER BY.
- Evite índices em colunas com baixa cardinalidade (ex: booleanos).
- Índices compostos: ordem importa — coloque as colunas com filtros mais seletivos primeiro.

Criar índice:
CREATE INDEX idx_pedidos_usuario_criado ON pedidos(usuario_id, criado_em);

Remover índice:
DROP INDEX idx_pedidos_usuario_criado ON pedidos;

Dica: sempre testar com e sem índice usando EXPLAIN.

---

## 3. EXPLAIN e análise de planos
- Use `EXPLAIN` para ver como a query é executada e identificar full table scans.
- Em MySQL use `EXPLAIN FORMAT=JSON <query>` para saída detalhada.

Exemplo:
EXPLAIN SELECT u.nome, p.valor FROM usuarios u JOIN pedidos p ON u.id = p.usuario_id WHERE p.criado_em >= '2024-01-01';

Busque:
- tipo = ref/const: bom
- tipo = ALL: full table scan (pode precisar de índice)
- filas de leitura (rows) muito altas → otimize filtros/índices

---

## 4. JOINs e ordem de operações
- Prefira `JOIN` explícito em vez de vírgula no FROM.
- Aplique filtros antes de agregações (WHERE antes do GROUP BY).
- Para anti-joins, `LEFT JOIN ... WHERE right.id IS NULL` costuma ser mais eficiente que `NOT IN` (evitar issues com NULLs).

Exemplo anti-join:
SELECT u.id FROM usuarios u LEFT JOIN enderecos e ON e.usuario_id = u.id WHERE e.id IS NULL;

---

## 5. Agregação e GROUP BY
- Sempre agrupar por todas as colunas não agregadas (em MySQL antigo havia comportamentos tolerantes).
- Use `HAVING` para filtrar resultados agregados (após GROUP BY).

Exemplo:
SELECT usuario_id, SUM(valor) total FROM pedidos GROUP BY usuario_id HAVING total > 1000;

---

## 6. Transações
- Use transações para operações que alteram múltiplas tabelas: BEGIN / COMMIT / ROLLBACK.
- Em MySQL/InnoDB, lembre-se de usar `SELECT ... FOR UPDATE` se for ler e atualizar depois (evita race).

Exemplo:
START TRANSACTION;
UPDATE contas SET saldo = saldo - 100 WHERE id = 1;
UPDATE contas SET saldo = saldo + 100 WHERE id = 2;
COMMIT;

---

## 7. Parametrização e segurança
- Nunca concatene entradas do usuário em SQL — use prepared statements / parâmetros.
- Valide tipos e comprimentos no aplicativo antes de enviar ao banco.
- Evite dar permissões desnecessárias ao usuário do banco (princípio do menor privilégio).

Exemplo (pseudocódigo):
-- Em app: SELECT * FROM usuarios WHERE email = ?  (bind do parâmetro)

---

## 8. Performance: dicas rápidas
- Evite funções sobre colunas no WHERE (ex: WHERE DATE(created_at) = '2024-05-10') — isso impede uso de índices. Prefira intervalos:
  WHERE created_at >= '2024-05-10 00:00:00' AND created_at < '2024-05-11 00:00:00'
- Prefira `EXISTS` a `IN` com subquery grande.
- Use `LIMIT` para consultas paginadas e evite OFFSET grande; prefira paginação baseada em cursor (seek method).

Exemplo de seek:
SELECT * FROM pedidos WHERE (criado_em, id) < ('2024-05-01', 1000) ORDER BY criado_em DESC, id DESC LIMIT 50;

---

## 9. Manutenção e custo de índices
- Índices aceleram leitura, mas degradam escrita (INSERT/UPDATE/DELETE). Planeje índices conforme perfil de leitura/escrita.
- Rebuild de índices e `ANALYZE TABLE` periódicos ajudam o otimizador.

ANALYZE TABLE pedidos;
OPTIMIZE TABLE pedidos;

---

## 10. Particionamento
- Em tabelas muito grandes (100M+ linhas), considere particionar por RANGE (data) ou LIST.
- Particionamento facilita manutenção (prune de partições antigas).

Exemplo (MySQL):
CREATE TABLE logs (
  id BIGINT,
  criado_at DATETIME,
  mensagem TEXT
) PARTITION BY RANGE (YEAR(criado_at)) (PARTITION p2023 VALUES LESS THAN (2024), PARTITION p2024 VALUES LESS THAN (2025));

---

## 11. Backup e restore
- Use ferramentas nativas (mysqldump, pg_dump, xtrabackup).
- Teste restore regularmente.
- Para grandes bases, prefira backups consistentes e com ponto-in-time recovery (binlogs / WAL).

Exemplo rápido:
mysqldump -u root -p --single-transaction --quick nome_db > backup.sql

---

## 12. Logs e monitoramento
- Monitore queries lentas (`slow_query_log`) e optimize as top-N.
- Ferramentas: pt-query-digest, Percona Toolkit, pg_stat_statements (Postgres).

---

## 13. Erros comuns
- Usar `NOT IN` com subquery que pode retornar NULL → resultados inesperados.
- Esquecer transações em múltiplas operações.
- SELECT * em produção ou em joins com muitas colunas.

---

## 14. Checklist antes de deploy
- Testar queries com EXPLAIN.
- Verificar índices e cardinalidade.
- Garantir permissões mínimas para o usuário do app.
- Plano de rollback/migration testado.

---

## Recursos e leitura
- Documentação oficial do MySQL / PostgreSQL
- Artigos sobre EXPLAIN e otimização de queries
- Ferramentas: pt-query-digest, pgBadger, Percona Toolkit
