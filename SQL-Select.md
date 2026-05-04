# SQL — SELECT Avançado

Referência de consultas SQL com foco em casos práticos: conversões, subselects, concatenação, UUID, contagem, duplicados e muito mais.

> Exemplos escritos para **MySQL**. A maioria funciona em PostgreSQL e outros bancos com pequenas adaptações.

---

## 1. SELECT básico

```sql
SELECT *                        FROM usuarios;
SELECT id, nome, email          FROM usuarios;
SELECT id, nome AS usuario      FROM usuarios;   -- alias de coluna
SELECT u.id, u.nome             FROM usuarios u; -- alias de tabela

-- Valor literal / constante
SELECT id, nome, 'ativo' AS status FROM usuarios;
SELECT id, nome, 1 AS versao       FROM usuarios;

-- Sem tabela
SELECT 1 + 1;
SELECT NOW();
SELECT UUID();
```

---

## 2. Filtros (WHERE)

```sql
-- Igualdade e comparação
WHERE status = 'ativo'
WHERE idade > 18
WHERE salario BETWEEN 3000 AND 8000
WHERE data BETWEEN '2024-01-01' AND '2024-12-31'

-- Nulos
WHERE telefone IS NULL
WHERE telefone IS NOT NULL

-- Listas
WHERE estado IN ('SP', 'RJ', 'MG')
WHERE id NOT IN (1, 2, 3)

-- Texto
WHERE nome LIKE 'Maria%'        -- começa com Maria
WHERE nome LIKE '%Silva%'       -- contém Silva
WHERE nome LIKE '%o'            -- termina com o
WHERE nome NOT LIKE '%teste%'

-- Regex (MySQL)
WHERE email REGEXP '^[a-z]'
WHERE telefone REGEXP '^\\(11\\)'

-- Múltiplas condições
WHERE idade > 18 AND ativo = TRUE
WHERE cidade = 'SP' OR cidade = 'RJ'
WHERE NOT (status = 'cancelado')
WHERE (categoria = 'A' OR categoria = 'B') AND ativo = TRUE
```

---

## 3. Ordenar e paginar

```sql
ORDER BY nome ASC
ORDER BY criado_em DESC
ORDER BY categoria ASC, valor DESC     -- múltiplos critérios

-- Paginação
LIMIT 10                               -- primeiros 10
LIMIT 10 OFFSET 20                     -- página 3 (itens 21–30)
LIMIT 20 OFFSET 40                     -- página 3 com 20 por página

-- Fórmula: OFFSET = (pagina - 1) * tamanho
```

---

## 4. Concatenação

```sql
-- CONCAT
SELECT CONCAT(nome, ' ', sobrenome)              AS nome_completo FROM usuarios;
SELECT CONCAT(ddd, ' ', telefone)                AS fone FROM contatos;
SELECT CONCAT('Cód: ', id, ' — ', nome)          AS descricao FROM produtos;

-- CONCAT_WS (With Separator) — ignora NULLs automaticamente
SELECT CONCAT_WS(' ', nome, sobrenome)           AS nome_completo FROM usuarios;
SELECT CONCAT_WS(', ', rua, numero, bairro, cidade) AS endereco FROM enderecos;

-- Concatenar com valor condicional
SELECT CONCAT(nome, IF(vip = 1, ' ⭐', ''))      AS nome_display FROM clientes;
```

---

## 5. Funções de texto

```sql
SELECT UPPER(nome)                      -- MARIA SILVA
SELECT LOWER(email)                     -- joao@email.com
SELECT TRIM(nome)                       -- remove espaços nas bordas
SELECT LTRIM(nome)                      -- remove espaços à esquerda
SELECT RTRIM(nome)                      -- remove espaços à direita

SELECT LENGTH(nome)                     -- tamanho em bytes
SELECT CHAR_LENGTH(nome)               -- tamanho em caracteres (use para UTF-8)

SELECT SUBSTRING(nome, 1, 3)           -- 3 primeiros caracteres
SELECT LEFT(nome, 5)                   -- 5 primeiros
SELECT RIGHT(cpf, 4)                   -- 4 últimos

SELECT REPLACE(telefone, '-', '')      -- remove traços
SELECT REPLACE(cpf, '.', '')           -- remove pontos

SELECT LPAD(id, 6, '0')               -- 000042 (preenche com zeros à esquerda)
SELECT RPAD(cod, 10, '-')             -- cod-------

SELECT LOCATE('silva', LOWER(nome))   -- posição de 'silva' na string (0 = não encontrado)
SELECT INSTR(nome, 'a')               -- posição do primeiro 'a'

SELECT REVERSE(nome)                   -- inverte a string

-- Formatar CPF armazenado sem pontuação
SELECT CONCAT(
    SUBSTRING(cpf, 1, 3), '.',
    SUBSTRING(cpf, 4, 3), '.',
    SUBSTRING(cpf, 7, 3), '-',
    SUBSTRING(cpf, 10, 2)
) AS cpf_formatado FROM clientes;

-- Formatar CNPJ
SELECT CONCAT(
    SUBSTRING(cnpj, 1, 2),  '.',
    SUBSTRING(cnpj, 3, 3),  '.',
    SUBSTRING(cnpj, 6, 3),  '/',
    SUBSTRING(cnpj, 9, 4),  '-',
    SUBSTRING(cnpj, 13, 2)
) AS cnpj_formatado FROM empresas;
```

---

## 6. Funções numéricas

```sql
SELECT ROUND(preco, 2)          -- 19.99  (2 casas decimais)
SELECT ROUND(3.5)               -- 4
SELECT CEIL(4.1)                -- 5  (arredonda para cima)
SELECT FLOOR(4.9)               -- 4  (arredonda para baixo)
SELECT ABS(-150)                -- 150
SELECT MOD(10, 3)               -- 1  (resto da divisão)
SELECT TRUNCATE(19.999, 2)      -- 19.99 (sem arredondar)

-- Porcentagem
SELECT valor, ROUND(valor / total * 100, 1) AS pct FROM vendas;

-- Faixa de valor com CASE
SELECT valor,
    CASE
        WHEN valor < 100    THEN 'baixo'
        WHEN valor < 1000   THEN 'médio'
        ELSE                     'alto'
    END AS faixa
FROM pedidos;
```

---

## 7. Funções de data

```sql
SELECT NOW()                            -- 2024-05-10 14:32:00
SELECT CURDATE()                        -- 2024-05-10
SELECT CURTIME()                        -- 14:32:00

SELECT YEAR(data)                       -- 2024
SELECT MONTH(data)                      -- 5
SELECT DAY(data)                        -- 10
SELECT DAYNAME(data)                    -- Saturday
SELECT MONTHNAME(data)                  -- May
SELECT WEEKDAY(data)                    -- 0=seg … 6=dom
SELECT QUARTER(data)                    -- 1 a 4

SELECT DATE(criado_em)                  -- extrai só a data de um DATETIME

SELECT DATEDIFF(NOW(), data_nascimento)              -- diferença em dias
SELECT TIMESTAMPDIFF(YEAR, data_nascimento, NOW())   -- diferença em anos (idade)
SELECT TIMESTAMPDIFF(MONTH, inicio, fim)             -- diferença em meses

SELECT DATE_ADD(NOW(), INTERVAL 30 DAY)
SELECT DATE_ADD(NOW(), INTERVAL 3 MONTH)
SELECT DATE_SUB(NOW(), INTERVAL 1 YEAR)

SELECT DATE_FORMAT(data, '%d/%m/%Y')                 -- 10/05/2024
SELECT DATE_FORMAT(data, '%d/%m/%Y %H:%i')           -- 10/05/2024 14:32
SELECT DATE_FORMAT(data, '%Y-%m')                    -- 2024-05 (para agrupar por mês)

-- Primeiro e último dia do mês
SELECT DATE_FORMAT(NOW(), '%Y-%m-01')                 -- primeiro dia do mês atual
SELECT LAST_DAY(NOW())                               -- último dia do mês atual

-- Filtrar por período
WHERE data >= DATE_SUB(NOW(), INTERVAL 7 DAY)        -- últimos 7 dias
WHERE YEAR(data) = 2024 AND MONTH(data) = 3          -- março de 2024
WHERE DATE_FORMAT(data, '%Y-%m') = '2024-03'         -- mesmo resultado
```

---

## 8. Conversões (CAST e CONVERT)

```sql
-- CAST(valor AS tipo)
SELECT CAST('42' AS UNSIGNED)           -- string → inteiro
SELECT CAST('3.14' AS DECIMAL(10, 2))  -- string → decimal
SELECT CAST(preco AS CHAR)             -- número → string
SELECT CAST('2024-05-10' AS DATE)      -- string → data
SELECT CAST(criado_em AS DATE)         -- datetime → date (descarta hora)
SELECT CAST(valor AS SIGNED)           -- permite negativos

-- CONVERT(valor, tipo) — sintaxe alternativa MySQL
SELECT CONVERT('42', UNSIGNED)
SELECT CONVERT(preco, CHAR)

-- CONVERT com encoding (para texto)
SELECT CONVERT(nome USING utf8mb4)

-- String para número (remove formatação antes)
SELECT CAST(REPLACE(REPLACE(valor_str, '.', ''), ',', '.') AS DECIMAL(15, 2));
-- ex: '1.234,56' → 1234.56

-- Número para string formatada com zeros
SELECT LPAD(CAST(id AS CHAR), 8, '0')  -- 00000042

-- Converter status numérico para texto
SELECT id, nome,
    CAST(ativo AS CHAR) AS ativo_str,  -- 1 → '1'
    IF(ativo = 1, 'Sim', 'Não') AS ativo_label
FROM usuarios;

-- COALESCE com conversão de tipo
SELECT id, COALESCE(CAST(desconto AS CHAR), 'sem desconto') AS desconto FROM pedidos;

-- Converter timestamp Unix para datetime
SELECT FROM_UNIXTIME(1714900000)                -- 2024-05-05 ...
SELECT FROM_UNIXTIME(ts, '%d/%m/%Y %H:%i')     -- formatado

-- Converter datetime para timestamp Unix
SELECT UNIX_TIMESTAMP(NOW())
SELECT UNIX_TIMESTAMP(criado_em) FROM pedidos;
```

---

## 9. UUID

```sql
-- Gerar UUID v4
SELECT UUID();                          -- 'a2b3c4d5-...' (formato string com hífens)

-- Inserir com UUID gerado
INSERT INTO tokens (id, usuario_id, valor)
VALUES (UUID(), 1, 'abc123');

-- UUID binário (mais eficiente para armazenar e indexar)
-- Converte string UUID para BINARY(16)
SELECT UUID_TO_BIN(UUID());

-- Com swap_flag=1 (melhora performance de índice B-tree — recomendado)
SELECT UUID_TO_BIN(UUID(), 1);

-- Converter BINARY(16) de volta para string legível
SELECT BIN_TO_UUID(id)          FROM tokens;
SELECT BIN_TO_UUID(id, 1)       FROM tokens;  -- com swap_flag

-- Tabela com UUID binário (padrão recomendado para produção)
CREATE TABLE pedidos (
    id          BINARY(16)   PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID(), 1)),
    usuario_id  INT          NOT NULL,
    total       DECIMAL(10,2),
    criado_em   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- SELECT com conversão legível
SELECT BIN_TO_UUID(id, 1) AS id, usuario_id, total FROM pedidos;

-- Buscar por UUID (string → bin na query)
SELECT * FROM pedidos WHERE id = UUID_TO_BIN('a2b3c4d5-e6f7-...', 1);

-- UUID como VARCHAR(36) — mais simples, menos performático
CREATE TABLE logs (
    id  VARCHAR(36) PRIMARY KEY DEFAULT (UUID())
);
```

---

## 10. Nulos (NULL)

```sql
-- Verificar
WHERE coluna IS NULL
WHERE coluna IS NOT NULL

-- IFNULL — substitui NULL por um valor padrão
SELECT IFNULL(desconto, 0)              AS desconto FROM pedidos;
SELECT IFNULL(telefone, 'não informado') AS fone    FROM clientes;

-- COALESCE — retorna o primeiro valor não-nulo (funciona em todos os bancos SQL)
SELECT COALESCE(celular, telefone, 'não informado') AS contato FROM clientes;
SELECT COALESCE(desconto, 0) + preco                AS total   FROM pedidos;

-- NULLIF — retorna NULL se os dois valores forem iguais (evita divisão por zero)
SELECT total / NULLIF(quantidade, 0) AS media FROM vendas;
SELECT NULLIF(status, '')            AS status FROM logs;  -- '' vira NULL
```

---

## 11. CASE WHEN

```sql
-- Simples
SELECT nome,
    CASE status
        WHEN 'A' THEN 'Ativo'
        WHEN 'I' THEN 'Inativo'
        WHEN 'P' THEN 'Pendente'
        ELSE 'Desconhecido'
    END AS status_label
FROM usuarios;

-- Com condições
SELECT nome, nota,
    CASE
        WHEN nota >= 7 THEN 'Aprovado'
        WHEN nota >= 5 THEN 'Recuperação'
        ELSE               'Reprovado'
    END AS situacao
FROM alunos;

-- CASE dentro de ORDER BY
ORDER BY CASE status WHEN 'urgente' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END;

-- CASE dentro de COUNT (contar condicionalmente)
SELECT
    COUNT(*)                                        AS total,
    COUNT(CASE WHEN status = 'ativo'   THEN 1 END) AS ativos,
    COUNT(CASE WHEN status = 'inativo' THEN 1 END) AS inativos,
    SUM(CASE WHEN vip = 1              THEN 1 ELSE 0 END) AS vips
FROM usuarios;

-- CASE com SUM (somar condicionalmente)
SELECT
    categoria,
    SUM(CASE WHEN mes = 1 THEN valor ELSE 0 END) AS jan,
    SUM(CASE WHEN mes = 2 THEN valor ELSE 0 END) AS fev,
    SUM(CASE WHEN mes = 3 THEN valor ELSE 0 END) AS mar
FROM vendas
GROUP BY categoria;
```

---

## 12. Contagem e agregação

```sql
COUNT(*)                   -- total de linhas (inclui NULLs)
COUNT(coluna)              -- linhas onde coluna não é NULL
COUNT(DISTINCT coluna)     -- valores únicos
SUM(valor)
AVG(valor)
MIN(valor)
MAX(valor)
GROUP_CONCAT(nome)                          -- 'Ana,Bia,Carlos' (MySQL)
GROUP_CONCAT(nome ORDER BY nome SEPARATOR ' | ')

-- Exemplos
SELECT COUNT(*) FROM pedidos;
SELECT COUNT(DISTINCT usuario_id) FROM pedidos;   -- quantos usuários fizeram pedidos

SELECT categoria,
    COUNT(*)             AS qtd,
    SUM(valor)           AS total,
    ROUND(AVG(valor), 2) AS media,
    MIN(valor)           AS minimo,
    MAX(valor)           AS maximo
FROM pedidos
GROUP BY categoria;

-- HAVING — filtrar depois do GROUP BY
SELECT categoria, COUNT(*) AS qtd
FROM pedidos
GROUP BY categoria
HAVING qtd > 10;

SELECT usuario_id, SUM(valor) AS total_gasto
FROM pedidos
GROUP BY usuario_id
HAVING total_gasto > 500
ORDER BY total_gasto DESC;

-- Porcentagem do total
SELECT categoria,
    COUNT(*) AS qtd,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM pedidos
GROUP BY categoria;
```

---

## 13. Encontrar e tratar duplicados

```sql
-- Contar quantas vezes cada valor aparece
SELECT email, COUNT(*) AS qtd
FROM usuarios
GROUP BY email
ORDER BY qtd DESC;

-- Mostrar apenas os duplicados
SELECT email, COUNT(*) AS qtd
FROM usuarios
GROUP BY email
HAVING qtd > 1;

-- Ver as linhas completas dos duplicados
SELECT u.*
FROM usuarios u
INNER JOIN (
    SELECT email
    FROM usuarios
    GROUP BY email
    HAVING COUNT(*) > 1
) dup ON u.email = dup.email
ORDER BY u.email;

-- Encontrar duplicatas em múltiplas colunas
SELECT nome, cpf, COUNT(*) AS qtd
FROM clientes
GROUP BY nome, cpf
HAVING qtd > 1;

-- Manter só o registro mais recente de cada duplicata (DELETE)
DELETE FROM usuarios
WHERE id NOT IN (
    SELECT max_id FROM (
        SELECT MAX(id) AS max_id
        FROM usuarios
        GROUP BY email
    ) t
);

-- Numerar duplicatas para identificar quais remover
SELECT id, email,
    ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
FROM usuarios;
-- rn > 1 são as duplicatas

-- Ver duplicatas com ROW_NUMBER
SELECT * FROM (
    SELECT id, email,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn
    FROM usuarios
) t
WHERE rn > 1;
```

---

## 14. Subselects (Subqueries)

### No WHERE

```sql
-- IN / NOT IN
SELECT * FROM pedidos
WHERE usuario_id IN (
    SELECT id FROM usuarios WHERE estado = 'SP'
);

SELECT * FROM produtos
WHERE id NOT IN (
    SELECT produto_id FROM pedidos WHERE status = 'cancelado'
);

-- Comparação com valor escalar
SELECT * FROM produtos
WHERE preco > (SELECT AVG(preco) FROM produtos);

SELECT * FROM pedidos
WHERE valor = (SELECT MAX(valor) FROM pedidos);
```

### No FROM (tabela derivada)

```sql
-- Usar resultado de uma query como tabela
SELECT categoria, total
FROM (
    SELECT categoria, SUM(valor) AS total
    FROM pedidos
    GROUP BY categoria
) AS resumo
WHERE total > 1000
ORDER BY total DESC;

-- Top N por grupo
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY valor DESC) AS rn
    FROM produtos
) t
WHERE rn <= 3;  -- top 3 mais caros por categoria
```

### EXISTS / NOT EXISTS

```sql
-- Clientes que fizeram pelo menos um pedido
SELECT c.nome, c.email
FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id
);

-- Clientes que nunca compraram
SELECT c.nome, c.email
FROM clientes c
WHERE NOT EXISTS (
    SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id
);
```

### No SELECT (subquery escalar)

```sql
-- Total de pedidos de cada usuário como coluna
SELECT
    u.id,
    u.nome,
    (SELECT COUNT(*) FROM pedidos p WHERE p.usuario_id = u.id) AS total_pedidos,
    (SELECT MAX(valor) FROM pedidos p WHERE p.usuario_id = u.id) AS maior_pedido
FROM usuarios u;

-- Diferença para a média geral
SELECT
    nome,
    salario,
    (SELECT AVG(salario) FROM funcionarios) AS media_geral,
    salario - (SELECT AVG(salario) FROM funcionarios) AS diff_media
FROM funcionarios;
```

---

## 15. CTE (WITH — Common Table Expressions)

```sql
-- CTE básica
WITH clientes_sp AS (
    SELECT id, nome, email
    FROM clientes
    WHERE estado = 'SP'
)
SELECT c.nome, COUNT(p.id) AS total_pedidos
FROM clientes_sp c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nome;

-- Múltiplas CTEs
WITH
vendas_mes AS (
    SELECT DATE_FORMAT(criado_em, '%Y-%m') AS mes, SUM(valor) AS total
    FROM pedidos
    WHERE status = 'pago'
    GROUP BY mes
),
media_geral AS (
    SELECT AVG(total) AS media FROM vendas_mes
)
SELECT v.mes, v.total,
    ROUND(v.total - m.media, 2) AS diff_media
FROM vendas_mes v
CROSS JOIN media_geral m
ORDER BY v.mes;

-- CTE recursiva (hierarquia / árvore)
WITH RECURSIVE hierarquia AS (
    -- âncora: ponto de partida
    SELECT id, nome, gerente_id, 0 AS nivel
    FROM funcionarios
    WHERE gerente_id IS NULL

    UNION ALL

    -- parte recursiva
    SELECT f.id, f.nome, f.gerente_id, h.nivel + 1
    FROM funcionarios f
    INNER JOIN hierarquia h ON f.gerente_id = h.id
)
SELECT REPEAT('  ', nivel), nome, nivel
FROM hierarquia
ORDER BY nivel, nome;
```

---

## 16. Window Functions (Funções de janela)

```sql
-- ROW_NUMBER — número de linha único por partição
SELECT id, nome, categoria,
    ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY valor DESC) AS posicao
FROM produtos;

-- RANK — com empates (pula números)
SELECT nome, pontuacao,
    RANK() OVER (ORDER BY pontuacao DESC) AS ranking
FROM jogadores;

-- DENSE_RANK — com empates (sem pular números)
SELECT nome, pontuacao,
    DENSE_RANK() OVER (ORDER BY pontuacao DESC) AS ranking
FROM jogadores;

-- SUM acumulado (running total)
SELECT data, valor,
    SUM(valor) OVER (ORDER BY data) AS total_acumulado
FROM vendas;

-- Média móvel (últimos 3 registros)
SELECT data, valor,
    AVG(valor) OVER (ORDER BY data ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel
FROM vendas;

-- LAG / LEAD — valor da linha anterior / próxima
SELECT mes, valor,
    LAG(valor)  OVER (ORDER BY mes) AS valor_mes_anterior,
    LEAD(valor) OVER (ORDER BY mes) AS valor_proximo_mes,
    valor - LAG(valor) OVER (ORDER BY mes) AS variacao
FROM vendas_mensais;

-- FIRST_VALUE / LAST_VALUE
SELECT nome, salario,
    FIRST_VALUE(salario) OVER (PARTITION BY depto ORDER BY salario DESC) AS maior_salario_depto
FROM funcionarios;

-- NTILE — dividir em N grupos (quartis, decis, etc.)
SELECT nome, valor,
    NTILE(4) OVER (ORDER BY valor) AS quartil
FROM vendas;
```

---

## 17. JOINs

```sql
-- INNER JOIN — somente onde há match dos dois lados
SELECT u.nome, p.valor, p.status
FROM usuarios u
INNER JOIN pedidos p ON p.usuario_id = u.id;

-- LEFT JOIN — todos da esquerda, match ou NULL da direita
SELECT u.nome, COUNT(p.id) AS total_pedidos
FROM usuarios u
LEFT JOIN pedidos p ON p.usuario_id = u.id
GROUP BY u.id, u.nome;

-- Somente quem NÃO tem match (anti-join)
SELECT u.nome
FROM usuarios u
LEFT JOIN pedidos p ON p.usuario_id = u.id
WHERE p.id IS NULL;

-- Múltiplos JOINs
SELECT p.id, u.nome, pr.descricao, p.valor
FROM pedidos p
INNER JOIN usuarios u  ON u.id  = p.usuario_id
INNER JOIN produtos pr ON pr.id = p.produto_id;

-- SELF JOIN — tabela com ela mesma (hierarquia)
SELECT f.nome AS funcionario, g.nome AS gerente
FROM funcionarios f
LEFT JOIN funcionarios g ON g.id = f.gerente_id;

-- CROSS JOIN — produto cartesiano
SELECT m.mes, c.categoria
FROM meses m
CROSS JOIN categorias c;
```

---

## 18. UNION

```sql
-- UNION — remove duplicatas
SELECT nome, email FROM clientes
UNION
SELECT nome, email FROM leads;

-- UNION ALL — mantém duplicatas (mais rápido)
SELECT 'pedido' AS tipo, id, valor, criado_em FROM pedidos
UNION ALL
SELECT 'orcamento',      id, valor, criado_em FROM orcamentos
ORDER BY criado_em DESC;

-- Combinar resultados de períodos diferentes
SELECT 'atual' AS periodo, SUM(valor) AS total
FROM pedidos WHERE YEAR(criado_em) = YEAR(NOW())
UNION ALL
SELECT 'anterior', SUM(valor)
FROM pedidos WHERE YEAR(criado_em) = YEAR(NOW()) - 1;
```

---

## 19. Casos práticos completos

### Ranking de clientes por gasto

```sql
SELECT
    u.id,
    u.nome,
    COUNT(p.id)          AS total_pedidos,
    SUM(p.valor)         AS total_gasto,
    ROUND(AVG(p.valor), 2) AS ticket_medio,
    MAX(p.criado_em)     AS ultimo_pedido,
    RANK() OVER (ORDER BY SUM(p.valor) DESC) AS ranking
FROM usuarios u
INNER JOIN pedidos p ON p.usuario_id = u.id
WHERE p.status = 'pago'
GROUP BY u.id, u.nome
ORDER BY total_gasto DESC
LIMIT 10;
```

### Relatório mensal com variação

```sql
WITH vendas AS (
    SELECT
        DATE_FORMAT(criado_em, '%Y-%m') AS mes,
        SUM(valor)                      AS total
    FROM pedidos
    WHERE status = 'pago'
    GROUP BY mes
)
SELECT
    mes,
    total,
    LAG(total) OVER (ORDER BY mes)                               AS total_anterior,
    ROUND(total - LAG(total) OVER (ORDER BY mes), 2)            AS variacao,
    ROUND(
        (total - LAG(total) OVER (ORDER BY mes))
        / NULLIF(LAG(total) OVER (ORDER BY mes), 0) * 100, 1
    )                                                            AS variacao_pct
FROM vendas
ORDER BY mes;
```

### Produtos sem movimento (sem pedidos nos últimos 90 dias)

```sql
SELECT p.id, p.nome, p.categoria,
    MAX(pe.criado_em) AS ultimo_pedido
FROM produtos p
LEFT JOIN itens_pedido ip ON ip.produto_id = p.id
LEFT JOIN pedidos pe      ON pe.id = ip.pedido_id AND pe.status = 'pago'
GROUP BY p.id, p.nome, p.categoria
HAVING ultimo_pedido IS NULL
    OR ultimo_pedido < DATE_SUB(NOW(), INTERVAL 90 DAY)
ORDER BY ultimo_pedido ASC;
```

### Clientes duplicados por CPF (com o mais antigo para manter)

```sql
SELECT
    cpf,
    COUNT(*)        AS duplicatas,
    MIN(id)         AS id_manter,
    GROUP_CONCAT(id ORDER BY id) AS todos_ids,
    MIN(criado_em)  AS primeiro_cadastro
FROM clientes
GROUP BY cpf
HAVING COUNT(*) > 1
ORDER BY duplicatas DESC;
```

### Busca full com múltiplos filtros opcionais (IN com CASE)

```sql
-- Simula filtros dinâmicos via SQL puro
SELECT *
FROM pedidos
WHERE
    (status = 'pago' OR 'pago' IS NULL)               -- se o filtro for NULL, ignora
    AND valor BETWEEN 100 AND 5000
    AND DATE(criado_em) >= '2024-01-01'
ORDER BY criado_em DESC;
```

### Pivot manual — vendas por mês e categoria

```sql
SELECT
    DATE_FORMAT(criado_em, '%Y-%m')                              AS mes,
    SUM(CASE WHEN categoria = 'A' THEN valor ELSE 0 END)        AS cat_a,
    SUM(CASE WHEN categoria = 'B' THEN valor ELSE 0 END)        AS cat_b,
    SUM(CASE WHEN categoria = 'C' THEN valor ELSE 0 END)        AS cat_c,
    SUM(valor)                                                   AS total
FROM pedidos
WHERE status = 'pago'
GROUP BY mes
ORDER BY mes;
```

### IDs de registros sem par em outra tabela

```sql
-- Usuários sem endereço cadastrado
SELECT u.id, u.nome
FROM usuarios u
WHERE NOT EXISTS (
    SELECT 1 FROM enderecos e WHERE e.usuario_id = u.id
);

-- Alternativa com LEFT JOIN
SELECT u.id, u.nome
FROM usuarios u
LEFT JOIN enderecos e ON e.usuario_id = u.id
WHERE e.id IS NULL;
```
