# MySQL — Cheatsheet

Referência de comandos MySQL para desenvolvimento backend no macOS.

> **Instalação:** `brew install mysql` — gerenciar com `brew services start mysql`

---

## 1. Conexão

```bash
mysql -u root                        # Conectar como root (sem senha)
mysql -u root -p                     # Conectar como root (com senha)
mysql -u usuario -p banco_de_dados   # Conectar direto em um banco
mysql -h host -P 3306 -u usuario -p  # Conectar em host remoto
mysql -u root -p -e "SHOW DATABASES" # Executar comando sem entrar no shell
```

---

## 2. Bancos de dados

```sql
SHOW DATABASES;                      -- Listar bancos de dados
CREATE DATABASE nome_db;             -- Criar banco de dados
CREATE DATABASE nome_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP DATABASE nome_db;               -- Remover banco de dados
USE nome_db;                         -- Selecionar banco de dados
SELECT DATABASE();                   -- Ver banco de dados em uso
```

---

## 3. Usuários e permissões

```sql
-- Listar usuários
SELECT user, host FROM mysql.user;

-- Criar usuário
CREATE USER 'usuario'@'localhost' IDENTIFIED BY 'senha';
CREATE USER 'usuario'@'%' IDENTIFIED BY 'senha';  -- acesso de qualquer host

-- Conceder permissões
GRANT ALL PRIVILEGES ON nome_db.* TO 'usuario'@'localhost';
GRANT SELECT, INSERT, UPDATE ON nome_db.* TO 'usuario'@'localhost';

-- Aplicar permissões
FLUSH PRIVILEGES;

-- Revogar permissões
REVOKE ALL PRIVILEGES ON nome_db.* FROM 'usuario'@'localhost';

-- Ver permissões de um usuário
SHOW GRANTS FOR 'usuario'@'localhost';

-- Remover usuário
DROP USER 'usuario'@'localhost';

-- Alterar senha
ALTER USER 'usuario'@'localhost' IDENTIFIED BY 'nova_senha';
FLUSH PRIVILEGES;
```

---

## 4. Tabelas

```sql
-- Listar tabelas
SHOW TABLES;
SHOW TABLES FROM nome_db;

-- Ver estrutura de uma tabela
DESCRIBE nome_tabela;
SHOW CREATE TABLE nome_tabela;     -- Ver DDL completo

-- Criar tabela
CREATE TABLE usuarios (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(100)     NOT NULL,
    email      VARCHAR(150)     NOT NULL UNIQUE,
    ativo      BOOLEAN          DEFAULT TRUE,
    criado_em  TIMESTAMP        DEFAULT CURRENT_TIMESTAMP
);

-- Renomear tabela
RENAME TABLE nome_antigo TO nome_novo;

-- Remover tabela
DROP TABLE nome_tabela;
DROP TABLE IF EXISTS nome_tabela;  -- Sem erro se não existir

-- Limpar dados da tabela (mantém estrutura)
TRUNCATE TABLE nome_tabela;
```

### Alterar tabela (ALTER TABLE)

```sql
-- Adicionar coluna
ALTER TABLE nome_tabela ADD COLUMN telefone VARCHAR(20);
ALTER TABLE nome_tabela ADD COLUMN telefone VARCHAR(20) AFTER email;

-- Remover coluna
ALTER TABLE nome_tabela DROP COLUMN telefone;

-- Modificar coluna
ALTER TABLE nome_tabela MODIFY COLUMN nome VARCHAR(200) NOT NULL;

-- Renomear coluna
ALTER TABLE nome_tabela RENAME COLUMN nome_antigo TO nome_novo;

-- Adicionar índice
ALTER TABLE nome_tabela ADD INDEX idx_email (email);

-- Adicionar chave estrangeira
ALTER TABLE pedidos ADD CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id);
```

---

## 5. CRUD

### SELECT

```sql
SELECT * FROM usuarios;
SELECT id, nome, email FROM usuarios;
SELECT * FROM usuarios WHERE ativo = TRUE;
SELECT * FROM usuarios WHERE nome LIKE '%silva%';
SELECT * FROM usuarios ORDER BY nome ASC;
SELECT * FROM usuarios LIMIT 10 OFFSET 20;
SELECT COUNT(*) FROM usuarios;
SELECT COUNT(*), ativo FROM usuarios GROUP BY ativo;

-- JOIN
SELECT u.nome, p.total
FROM usuarios u
INNER JOIN pedidos p ON p.usuario_id = u.id;

LEFT JOIN pedidos p ON p.usuario_id = u.id;   -- inclui usuários sem pedidos
```

### INSERT

```sql
INSERT INTO usuarios (nome, email) VALUES ('João Silva', 'joao@email.com');

-- Múltiplos registros
INSERT INTO usuarios (nome, email) VALUES
    ('Maria', 'maria@email.com'),
    ('Pedro', 'pedro@email.com');

-- Inserir ou atualizar se já existir (upsert)
INSERT INTO usuarios (id, nome, email)
VALUES (1, 'João', 'joao@email.com')
ON DUPLICATE KEY UPDATE nome = VALUES(nome), email = VALUES(email);
```

### UPDATE

```sql
UPDATE usuarios SET ativo = FALSE WHERE id = 1;
UPDATE usuarios SET nome = 'João S.', email = 'joaos@email.com' WHERE id = 1;

-- Cuidado: sem WHERE atualiza todos os registros
```

### DELETE

```sql
DELETE FROM usuarios WHERE id = 1;
DELETE FROM usuarios WHERE ativo = FALSE;

-- Cuidado: sem WHERE deleta todos os registros
```

---

## 6. Índices

```sql
-- Criar índice
CREATE INDEX idx_nome ON usuarios(nome);
CREATE UNIQUE INDEX idx_email ON usuarios(email);

-- Listar índices de uma tabela
SHOW INDEX FROM usuarios;

-- Remover índice
DROP INDEX idx_nome ON usuarios;

-- Ver plano de execução de uma query
EXPLAIN SELECT * FROM usuarios WHERE email = 'joao@email.com';
```

---

## 7. Transações

```sql
START TRANSACTION;

INSERT INTO pedidos (usuario_id, total) VALUES (1, 150.00);
UPDATE estoque SET quantidade = quantidade - 1 WHERE produto_id = 5;

COMMIT;    -- Confirmar transação
ROLLBACK;  -- Desfazer transação em caso de erro
```

---

## 8. Backup e restauração

```bash
# Exportar banco de dados
mysqldump -u root -p nome_db > backup.sql

# Exportar todos os bancos
mysqldump -u root -p --all-databases > backup_all.sql

# Exportar apenas estrutura (sem dados)
mysqldump -u root -p --no-data nome_db > estrutura.sql

# Restaurar backup
mysql -u root -p nome_db < backup.sql

# Criar banco e restaurar em um comando
mysql -u root -p -e "CREATE DATABASE nome_db"
mysql -u root -p nome_db < backup.sql
```

---

## 9. Informações e diagnóstico

```sql
-- Versão do MySQL
SELECT VERSION();

-- Status do servidor
SHOW STATUS;
SHOW STATUS LIKE 'Threads%';

-- Variáveis de configuração
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE '%timeout%';

-- Processos em execução
SHOW PROCESSLIST;

-- Matar processo específico
KILL id_do_processo;
```

---

## 10. Tipos de dados mais usados

| Tipo | Uso |
|---|---|
| `INT` / `BIGINT` | Números inteiros |
| `DECIMAL(10,2)` | Valores monetários |
| `FLOAT` / `DOUBLE` | Números com ponto flutuante |
| `VARCHAR(n)` | Texto variável até n caracteres |
| `TEXT` / `LONGTEXT` | Textos longos |
| `BOOLEAN` / `TINYINT(1)` | Verdadeiro/Falso |
| `DATE` | Data (YYYY-MM-DD) |
| `DATETIME` | Data e hora (YYYY-MM-DD HH:MM:SS) |
| `TIMESTAMP` | Data e hora com fuso automático |
| `JSON` | Objetos JSON (MySQL 5.7+) |
| `ENUM('a','b')` | Valor de uma lista fixa |
