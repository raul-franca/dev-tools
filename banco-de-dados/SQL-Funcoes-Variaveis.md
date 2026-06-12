# SQL — Funções e Variáveis

Referência de funções nativas e uso de variáveis no SQL. Exemplos escritos para **MySQL**. A maioria funciona em PostgreSQL e outros bancos com pequenas adaptações.

---

## 1. Variáveis de usuário (`@variavel`)

Variáveis de sessão, definidas com `SET` ou diretamente em queries. Persistem durante a conexão.

```sql
-- Definir
SET @limite = 10;
SET @status = 'ativo';
SET @data_inicio = '2024-01-01';

-- Usar em query
SELECT id, nome FROM usuarios
WHERE status = @status
LIMIT @limite;

-- Atribuir resultado de query
SET @total = (SELECT COUNT(*) FROM pedidos WHERE criado_em >= @data_inicio);
SELECT @total AS total_pedidos;

-- Atribuir com SELECT INTO (uma linha)
SELECT COUNT(*) INTO @qtd FROM usuarios WHERE ativo = 1;
SELECT @qtd;

-- Variável incrementada (útil para row_number manual)
SET @n = 0;
SELECT @n := @n + 1 AS linha, nome FROM usuarios;
```

---

## 2. Variáveis locais em Stored Procedures (`DECLARE`)

Variáveis locais só existem dentro do bloco `BEGIN ... END`.

```sql
DELIMITER $$

CREATE PROCEDURE resumo_cliente(IN cliente_id INT)
BEGIN
    DECLARE v_nome        VARCHAR(100);
    DECLARE v_total       DECIMAL(10,2) DEFAULT 0;
    DECLARE v_qtd_pedidos INT DEFAULT 0;

    -- Atribuir valores
    SELECT nome INTO v_nome FROM clientes WHERE id = cliente_id;

    SELECT COUNT(*), SUM(valor)
    INTO v_qtd_pedidos, v_total
    FROM pedidos
    WHERE cliente_id = cliente_id;

    -- Usar variáveis no resultado
    SELECT
        v_nome            AS cliente,
        v_qtd_pedidos     AS total_pedidos,
        v_total           AS valor_total,
        v_total / v_qtd_pedidos AS ticket_medio;
END$$

DELIMITER ;

CALL resumo_cliente(42);
```

---

## 3. Funções de string

```sql
-- Comprimento
SELECT LENGTH('olá mundo');           -- bytes: 10 (UTF-8)
SELECT CHAR_LENGTH('olá mundo');      -- caracteres: 9

-- Maiúsculas / minúsculas
SELECT UPPER('joao silva');           -- JOAO SILVA
SELECT LOWER('JOAO SILVA');           -- joao silva

-- Remover espaços
SELECT TRIM('  texto  ');             -- 'texto'
SELECT LTRIM('  texto');              -- 'texto'
SELECT RTRIM('texto  ');              -- 'texto'

-- Substituir
SELECT REPLACE('foo bar foo', 'foo', 'baz');  -- 'baz bar baz'

-- Extrair parte
SELECT SUBSTRING('abcdef', 2, 3);    -- 'bcd' (posição 2, comprimento 3)
SELECT LEFT('abcdef', 3);            -- 'abc'
SELECT RIGHT('abcdef', 3);           -- 'def'

-- Concatenar
SELECT CONCAT('João', ' ', 'Silva');  -- 'João Silva'
SELECT CONCAT_WS(', ', 'SP', 'RJ', 'MG');  -- 'SP, RJ, MG' (com separador)

-- Posição
SELECT LOCATE('bar', 'foo bar baz'); -- 5 (posição inicial)
SELECT INSTR('foo bar', 'bar');      -- 5

-- Padding
SELECT LPAD('7', 3, '0');            -- '007'
SELECT RPAD('ok', 5, '.');           -- 'ok...'

-- Repetir / reverter
SELECT REPEAT('ab', 3);              -- 'ababab'
SELECT REVERSE('abc');               -- 'cba'

-- Exemplos práticos
SELECT CONCAT(UPPER(LEFT(nome, 1)), LOWER(SUBSTRING(nome, 2))) AS nome_formatado
FROM usuarios;

SELECT LPAD(id, 6, '0') AS codigo FROM pedidos;  -- 000042
```

---

## 4. Funções numéricas

```sql
-- Arredondamento
SELECT ROUND(3.456, 2);     -- 3.46
SELECT ROUND(3.455, 2);     -- 3.46
SELECT CEIL(3.1);            -- 4  (teto)
SELECT FLOOR(3.9);           -- 3  (piso)
SELECT TRUNCATE(3.987, 2);   -- 3.98 (corta, não arredonda)

-- Absoluto / sinal
SELECT ABS(-42);             -- 42
SELECT SIGN(-5);             -- -1   (negativo)
SELECT SIGN(0);              -- 0
SELECT SIGN(7);              -- 1    (positivo)

-- Potência / raiz / log
SELECT POW(2, 10);           -- 1024
SELECT SQRT(144);            -- 12
SELECT LOG(100) / LOG(10);   -- 2  (log base 10)
SELECT LN(2.71828);          -- ~1 (log natural)

-- Módulo e divisão inteira
SELECT MOD(17, 5);           -- 2  (resto)
SELECT 17 DIV 5;             -- 3  (divisão inteira)

-- Aleatório
SELECT RAND();               -- 0 a 1
SELECT FLOOR(RAND() * 100);  -- inteiro 0 a 99

-- Mínimo / máximo entre valores (não agregação)
SELECT GREATEST(10, 20, 5);  -- 20
SELECT LEAST(10, 20, 5);     -- 5

-- Exemplos práticos
SELECT
    valor,
    ROUND(valor * 0.1, 2)   AS desconto_10pct,
    ROUND(valor * 1.1, 2)   AS valor_com_juros
FROM pedidos;
```

---

## 5. Funções de data e hora

```sql
-- Data e hora atuais
SELECT NOW();                -- '2024-06-04 14:30:00'  (data + hora)
SELECT CURDATE();            -- '2024-06-04'           (só data)
SELECT CURTIME();            -- '14:30:00'             (só hora)
SELECT UTC_TIMESTAMP();      -- data+hora em UTC

-- Extrair partes
SELECT YEAR(NOW());          -- 2024
SELECT MONTH(NOW());         -- 6
SELECT DAY(NOW());           -- 4
SELECT DAYOFWEEK(NOW());     -- 1=Dom ... 7=Sab
SELECT WEEK(NOW());          -- número da semana no ano
SELECT HOUR(NOW());          -- 14
SELECT MINUTE(NOW());        -- 30

-- Formatar
SELECT DATE_FORMAT(NOW(), '%d/%m/%Y');          -- '04/06/2024'
SELECT DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i');    -- '04/06/2024 14:30'
SELECT DATE_FORMAT(NOW(), '%W, %d de %M');      -- 'Tuesday, 04 de June'

-- Aritmética de datas
SELECT DATE_ADD(NOW(), INTERVAL 30 DAY);
SELECT DATE_SUB(NOW(), INTERVAL 1 MONTH);
SELECT DATE_ADD(NOW(), INTERVAL 2 HOUR);
SELECT DATE_ADD(NOW(), INTERVAL 1 YEAR);

-- Diferença entre datas
SELECT DATEDIFF('2024-12-31', '2024-01-01');    -- 365 dias
SELECT TIMESTAMPDIFF(MONTH, '2024-01-01', '2024-06-04');  -- 5 meses
SELECT TIMESTAMPDIFF(HOUR, '2024-06-04 08:00', NOW());    -- horas decorridas

-- Início/fim de períodos
SELECT LAST_DAY('2024-02-01');                  -- '2024-02-29' (último dia do mês)
SELECT DATE_FORMAT(NOW(), '%Y-%m-01')           AS primeiro_dia_mes;

-- Converter string → data
SELECT STR_TO_DATE('04/06/2024', '%d/%m/%Y');   -- '2024-06-04'
SELECT CAST('2024-06-04' AS DATE);

-- Exemplos práticos
SELECT id, criado_em,
    DATEDIFF(NOW(), criado_em)        AS dias_desde_criacao,
    DATE_FORMAT(criado_em, '%m/%Y')   AS mes_ano
FROM pedidos
WHERE criado_em >= DATE_SUB(NOW(), INTERVAL 30 DAY);
```

---

## 6. Funções condicionais

```sql
-- IF(condicao, valor_se_verdadeiro, valor_se_falso)
SELECT nome, IF(ativo = 1, 'Ativo', 'Inativo') AS situacao FROM usuarios;
SELECT IF(COUNT(*) > 0, 'tem dados', 'vazio') FROM pedidos;

-- IFNULL(valor, substituto_se_null)
SELECT nome, IFNULL(telefone, 'Não informado') AS telefone FROM clientes;

-- NULLIF(a, b) → retorna NULL se a = b, senão retorna a (evita divisão por zero)
SELECT total / NULLIF(qtd, 0) AS media FROM relatorio;

-- COALESCE — retorna o primeiro valor não-NULL
SELECT COALESCE(celular, telefone, email, 'sem contato') AS contato FROM clientes;

-- CASE simples (compara valor)
SELECT nome,
    CASE status
        WHEN 'A' THEN 'Ativo'
        WHEN 'I' THEN 'Inativo'
        WHEN 'B' THEN 'Bloqueado'
        ELSE 'Desconhecido'
    END AS descricao_status
FROM usuarios;

-- CASE pesquisado (condições booleanas)
SELECT nome, salario,
    CASE
        WHEN salario < 2000              THEN 'Faixa 1'
        WHEN salario BETWEEN 2000 AND 5000 THEN 'Faixa 2'
        WHEN salario > 5000              THEN 'Faixa 3'
        ELSE 'Não informado'
    END AS faixa_salarial
FROM funcionarios;

-- CASE dentro de SUM (pivot manual)
SELECT
    DATE_FORMAT(criado_em, '%Y-%m')                   AS mes,
    SUM(CASE WHEN status = 'pago'     THEN valor END) AS pago,
    SUM(CASE WHEN status = 'pendente' THEN valor END) AS pendente,
    SUM(CASE WHEN status = 'cancelado'THEN valor END) AS cancelado
FROM pedidos
GROUP BY mes
ORDER BY mes;
```

---

## 7. Funções de agregação

```sql
-- Básicas
SELECT COUNT(*)                FROM pedidos;              -- todas as linhas
SELECT COUNT(telefone)         FROM clientes;             -- ignora NULLs
SELECT COUNT(DISTINCT cidade)  FROM clientes;             -- valores únicos
SELECT SUM(valor)              FROM pedidos;
SELECT AVG(valor)              FROM pedidos;
SELECT MIN(criado_em)          FROM pedidos;
SELECT MAX(criado_em)          FROM pedidos;

-- GROUP_CONCAT — concatena valores de um grupo
SELECT usuario_id,
    GROUP_CONCAT(produto_nome ORDER BY produto_nome SEPARATOR ', ') AS produtos
FROM itens_pedido
GROUP BY usuario_id;

-- Com DISTINCT e limite de caracteres
SELECT GROUP_CONCAT(DISTINCT cidade ORDER BY cidade SEPARATOR ' | ')
FROM clientes;

-- Agrupamento com filtro de grupo (HAVING)
SELECT departamento, AVG(salario) AS media
FROM funcionarios
GROUP BY departamento
HAVING media > 5000
ORDER BY media DESC;

-- Exemplos práticos: relatório mensal
SELECT
    DATE_FORMAT(criado_em, '%Y-%m')  AS mes,
    COUNT(*)                          AS total_pedidos,
    SUM(valor)                        AS faturamento,
    ROUND(AVG(valor), 2)              AS ticket_medio,
    MIN(valor)                        AS menor_pedido,
    MAX(valor)                        AS maior_pedido
FROM pedidos
WHERE status = 'pago'
GROUP BY mes
ORDER BY mes DESC;
```

---

## 8. Stored Function (função criada pelo usuário)

Retorna um único valor; pode ser chamada em qualquer expressão SQL.

```sql
DELIMITER $$

-- Função: formata CPF (00000000000 → 000.000.000-00)
CREATE FUNCTION fmt_cpf(cpf VARCHAR(11))
RETURNS VARCHAR(14)
DETERMINISTIC
BEGIN
    RETURN CONCAT(
        SUBSTRING(cpf, 1, 3), '.',
        SUBSTRING(cpf, 4, 3), '.',
        SUBSTRING(cpf, 7, 3), '-',
        SUBSTRING(cpf, 10, 2)
    );
END$$

DELIMITER ;

SELECT nome, fmt_cpf(cpf) AS cpf_formatado FROM clientes;

-- ----------------------------------------

DELIMITER $$

-- Função: calcula idade a partir da data de nascimento
CREATE FUNCTION calcular_idade(data_nasc DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, data_nasc, CURDATE());
END$$

DELIMITER ;

SELECT nome, data_nascimento, calcular_idade(data_nascimento) AS idade
FROM clientes
WHERE calcular_idade(data_nascimento) >= 18;

-- ----------------------------------------

DELIMITER $$

-- Função: aplica desconto progressivo por valor
CREATE FUNCTION desconto(valor DECIMAL(10,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE pct DECIMAL(5,2);
    SET pct = CASE
        WHEN valor < 100    THEN 0
        WHEN valor < 500    THEN 0.05
        WHEN valor < 1000   THEN 0.10
        ELSE                     0.15
    END;
    RETURN ROUND(valor * (1 - pct), 2);
END$$

DELIMITER ;

SELECT valor, desconto(valor) AS valor_com_desconto FROM pedidos;
```

---

## 9. Stored Procedure com parâmetros e variáveis

```sql
DELIMITER $$

-- IN: entrada | OUT: saída | INOUT: entrada e saída
CREATE PROCEDURE transferir_saldo(
    IN  p_origem  INT,
    IN  p_destino INT,
    IN  p_valor   DECIMAL(10,2),
    OUT p_status  VARCHAR(50)
)
BEGIN
    DECLARE v_saldo_origem DECIMAL(10,2);

    START TRANSACTION;

    SELECT saldo INTO v_saldo_origem FROM contas WHERE id = p_origem FOR UPDATE;

    IF v_saldo_origem < p_valor THEN
        SET p_status = 'ERRO: saldo insuficiente';
        ROLLBACK;
    ELSE
        UPDATE contas SET saldo = saldo - p_valor WHERE id = p_origem;
        UPDATE contas SET saldo = saldo + p_valor WHERE id = p_destino;
        COMMIT;
        SET p_status = 'OK';
    END IF;
END$$

DELIMITER ;

-- Chamar e ler o parâmetro de saída
CALL transferir_saldo(1, 2, 500.00, @resultado);
SELECT @resultado;
```

---

## 10. Referência rápida — funções mais usadas

| Categoria   | Função                        | O que faz                          |
|-------------|-------------------------------|------------------------------------|
| String      | `CONCAT(a, b)`                | Concatena strings                  |
| String      | `TRIM(s)` / `UPPER` / `LOWER` | Remove espaços / muda caixa        |
| String      | `SUBSTRING(s, pos, len)`      | Extrai trecho                      |
| String      | `REPLACE(s, de, para)`        | Substitui ocorrências              |
| Número      | `ROUND(n, d)`                 | Arredonda                          |
| Número      | `ABS(n)`                      | Valor absoluto                     |
| Número      | `MOD(n, d)`                   | Resto da divisão                   |
| Data        | `NOW()` / `CURDATE()`         | Data e hora atual                  |
| Data        | `DATE_FORMAT(d, fmt)`         | Formata data                       |
| Data        | `DATEDIFF(a, b)`              | Diferença em dias                  |
| Data        | `DATE_ADD(d, INTERVAL n u)`   | Soma período à data                |
| Condicional | `COALESCE(a, b, ...)`         | Primeiro não-NULL                  |
| Condicional | `IFNULL(a, b)`                | Substitui NULL                     |
| Condicional | `CASE WHEN ... END`           | If/else em SQL                     |
| Agregação   | `COUNT` / `SUM` / `AVG`       | Contagem, soma, média              |
| Agregação   | `GROUP_CONCAT(...)`           | Concatena valores do grupo         |
