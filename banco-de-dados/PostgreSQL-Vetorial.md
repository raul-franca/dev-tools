# PostgreSQL Vetorial — pgvector

Referência de busca vetorial no PostgreSQL com a extensão **pgvector**: embeddings, operadores de distância, índices HNSW e IVFFlat, busca híbrida e pipeline de RAG.

> **Versões:** pgvector **0.8.1** (última estável, compatível com PostgreSQL 13–18). O básico de Postgres está em [PostgreSQL.md](PostgreSQL.md).

---

## 1. Conceitos em 2 minutos

**Embedding** é um vetor de números que representa o *significado* de um texto (ou imagem, ou áudio). Textos com sentido parecido geram vetores próximos no espaço.

```
"cadastro de beneficiário"  → [0.021, -0.310, 0.884, ...]   (1536 números)
"registro de assistido"     → [0.019, -0.298, 0.871, ...]   ← muito próximo
"configuração de firewall"  → [-0.554, 0.102, -0.223, ...]  ← distante
```

Buscar semanticamente = calcular a distância entre o vetor da pergunta e os vetores guardados, e devolver os mais próximos. O pgvector faz isso **dentro do Postgres**, então você usa `JOIN`, `WHERE`, permissões e backup exatamente como no resto do banco — sem subir um banco vetorial separado.

**Quando pgvector é suficiente:** até alguns milhões de vetores, dados já no Postgres, equipe pequena. **Quando avaliar um banco dedicado (Qdrant, Milvus):** dezenas de milhões de vetores com QPS alto e filtros complexos.

| Termo | O que é |
|---|---|
| Dimensão | Tamanho do vetor. Depende do modelo: 384 (MiniLM), 768 (BERT), 1536 (OpenAI `text-embedding-3-small`), 3072 (`-3-large`) |
| Distância | Métrica de proximidade: cosseno, L2 (euclidiana), inner product |
| KNN | *k-nearest neighbors* — os k vizinhos mais próximos |
| ANN | *approximate* KNN — troca um pouco de precisão por muita velocidade (é o que os índices fazem) |
| Recall | % dos vizinhos realmente corretos que a busca aproximada retornou |
| RAG | *Retrieval-Augmented Generation* — buscar trechos relevantes e mandar para o LLM responder |

---

## 2. Instalação

### Docker (mais simples)

```yaml
services:
  db:
    image: pgvector/pgvector:pg17        # Postgres 17 já com a extensão compilada
    environment:
      POSTGRES_DB: rag
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d rag"]
      interval: 10s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
```

### Ubuntu / VPS

```bash
# Verifique a versão ANTES de instalar
apt-cache policy postgresql-17-pgvector

sudo apt install -y postgresql-17-pgvector
```

> [!WARNING]
> O pacote do repositório padrão do **Ubuntu 24.04** é o **pgvector 0.6.0** — sem `halfvec`, `binary_quantize`, `subvector` nem *iterative scans*. Para ter a 0.8.x, use o repositório **PGDG** (`/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh`, ver [PostgreSQL.md](PostgreSQL.md)), a imagem Docker `pgvector/pgvector`, ou compile do fonte. Confirme sempre com `SELECT extversion FROM pg_extension WHERE extname = 'vector';`.

### macOS (Homebrew)

```bash
brew install pgvector
```

### Compilar do fonte (quando não há pacote)

```bash
sudo apt install -y build-essential postgresql-server-dev-17 git
git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git
cd pgvector && make && sudo make install
```

### Habilitar no banco

```sql
CREATE EXTENSION IF NOT EXISTS vector;
SELECT extversion FROM pg_extension WHERE extname = 'vector';   -- 0.8.1
\dx
```

> [!NOTE]
> A extensão é habilitada **por banco de dados**, não por cluster. Criou um banco novo? Rode `CREATE EXTENSION vector;` nele também.

---

## 3. Tipos de vetor

| Tipo | Bytes por dimensão | Máx. p/ armazenar | Máx. p/ indexar | Uso |
|---|---|---|---|---|
| `vector` | 4 (float32) | 16.000 | 2.000 | Padrão, precisão máxima |
| `halfvec` | 2 (float16) | 16.000 | 4.000 | Metade do espaço, recall quase igual |
| `bit` | 1/8 | — | 64.000 | Quantização binária, distância Hamming |
| `sparsevec` | — | 16.000 não-zeros | 1.000 | Vetores esparsos (SPLADE, BM25 vetorial) |

```sql
CREATE TABLE documentos (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo     text NOT NULL,
    conteudo   text NOT NULL,
    categoria  text,
    embedding  vector(1536),                    -- dimensão FIXA, igual à do modelo
    criado_em  timestamptz NOT NULL DEFAULT now()
);
```

> [!WARNING]
> A dimensão precisa bater com a do modelo que gerou o embedding. Trocar de modelo (ex.: OpenAI 1536 → MiniLM 384) exige `ALTER TABLE ... TYPE vector(384)` e **regerar todos os embeddings** — vetores de modelos diferentes não são comparáveis entre si.

---

## 4. Inserir e ler vetores

```sql
-- Literal: string com colchetes
INSERT INTO documentos (titulo, conteudo, embedding)
VALUES ('Manual CIPTEA', 'Texto...', '[0.021,-0.310,0.884]');

-- Conversão explícita
INSERT INTO documentos (titulo, embedding) VALUES ('X', ARRAY[0.1,0.2,0.3]::vector);

-- Atualizar
UPDATE documentos SET embedding = $1 WHERE id = $2;

-- Funções úteis
SELECT vector_dims(embedding), vector_norm(embedding) FROM documentos LIMIT 1;
SELECT subvector(embedding, 1, 768) FROM documentos LIMIT 1;   -- fatiar (Matryoshka)
SELECT l2_normalize(embedding) FROM documentos LIMIT 1;
SELECT binary_quantize(embedding) FROM documentos LIMIT 1;     -- vector → bit
SELECT avg(embedding) FROM documentos WHERE categoria = 'juridico';  -- centroide
```

---

## 5. Operadores de distância

| Operador | Distância | Função | Quando usar |
|---|---|---|---|
| `<=>` | Cosseno | `cosine_distance` | **Padrão para texto** — ignora o tamanho do vetor |
| `<->` | L2 / euclidiana | `l2_distance` | Embeddings de imagem, vetores normalizados |
| `<#>` | Inner product negativo | `inner_product` | Modelos que recomendam dot product (mais rápido) |
| `<+>` | L1 / Manhattan | `l1_distance` | Casos específicos |
| `<~>` | Hamming (`bit`) | `hamming_distance` | Vetores binários |
| `<%>` | Jaccard (`bit`) | `jaccard_distance` | Conjuntos binários |

```sql
-- Os 5 documentos mais parecidos com a pergunta
SELECT id, titulo, embedding <=> $1 AS distancia
FROM documentos
ORDER BY embedding <=> $1
LIMIT 5;

-- Similaridade em % (cosseno: distância 0 = idêntico, 2 = oposto)
SELECT titulo, round((1 - (embedding <=> $1))::numeric, 4) AS similaridade
FROM documentos
ORDER BY embedding <=> $1
LIMIT 5;

-- Cortar por limiar de relevância (evita devolver lixo quando nada casa)
SELECT titulo, 1 - (embedding <=> $1) AS score
FROM documentos
WHERE embedding <=> $1 < 0.35              -- ~0.65 de similaridade
ORDER BY embedding <=> $1
LIMIT 10;

-- Documentos parecidos com um documento existente
SELECT d2.titulo, d1.embedding <=> d2.embedding AS dist
FROM documentos d1, documentos d2
WHERE d1.id = 42 AND d2.id <> 42
ORDER BY d1.embedding <=> d2.embedding
LIMIT 5;
```

> [!CAUTION]
> O índice só é usado quando o `ORDER BY` usa **o mesmo operador** da classe do índice. Um índice criado com `vector_cosine_ops` não acelera `ORDER BY embedding <-> $1`. Escolha a métrica uma vez e mantenha.

---

## 6. Índices: HNSW e IVFFlat

Sem índice, a busca é exata mas faz varredura completa — aceitável até uns poucos milhares de vetores. Acima disso, indexe.

### HNSW (padrão recomendado)

Grafo hierárquico navegável. Melhor recall/velocidade, aceita ser criado com a tabela vazia, mas consome mais memória e demora mais para construir.

```sql
CREATE INDEX ON documentos USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON documentos USING hnsw (embedding vector_l2_ops);
CREATE INDEX ON documentos USING hnsw (embedding vector_ip_ops);

-- Com parâmetros
CREATE INDEX idx_doc_emb ON documentos
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
```

| Parâmetro | Padrão | Efeito |
|---|---|---|
| `m` | 16 | Conexões por nó. ↑ = melhor recall, índice maior e build mais lento (16–48) |
| `ef_construction` | 64 | Candidatos avaliados no build. ↑ = melhor qualidade, build mais lento (64–200) |
| `hnsw.ef_search` | 40 | **Em tempo de consulta**: candidatos examinados. ↑ = mais recall, mais lento |

```sql
SET hnsw.ef_search = 100;                  -- na sessão
SET LOCAL hnsw.ef_search = 200;            -- só nesta transação
```

### IVFFlat

Divide o espaço em listas e busca só nas mais próximas. Build muito mais rápido e índice menor, porém recall inferior — e **exige dados já carregados** para calcular os centroides.

```sql
-- Regra prática: lists = linhas/1000 (até 1M linhas); acima disso, sqrt(linhas)
CREATE INDEX ON documentos
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

SET ivfflat.probes = 10;                   -- listas visitadas na busca (padrão 1)
```

### Qual escolher

| Critério | HNSW | IVFFlat |
|---|---|---|
| Recall | Melhor | Bom, depende de `probes` |
| Velocidade de busca | Mais rápida | Boa |
| Tempo de build | Lento | Rápido |
| Memória no build | Alta | Baixa |
| Tamanho do índice | Maior | Menor |
| Precisa de dados antes | Não | **Sim** |
| Inserções contínuas | Ótimo | Degrada — exige `REINDEX` periódico |

**Na dúvida: HNSW.** IVFFlat só quando o build do HNSW não couber na janela de manutenção ou na memória.

### Build mais rápido

```sql
SET maintenance_work_mem = '2GB';          -- índice deve caber aqui, senão vai para disco
SET max_parallel_maintenance_workers = 4;  -- paralelismo no build
CREATE INDEX CONCURRENTLY ...              -- em produção, para não travar a tabela

-- Acompanhar o progresso
SELECT phase, round(100.0 * blocks_done / nullif(blocks_total,0), 1) AS pct
FROM pg_stat_progress_create_index;
```

---

## 7. Filtrar e buscar ao mesmo tempo

O ponto fraco clássico do ANN: `WHERE categoria = 'juridico'` combinado com `ORDER BY embedding <=> $1` pode devolver **menos linhas que o LIMIT**, porque o índice retorna os k mais próximos *antes* de aplicar o filtro.

```sql
-- 1. Iterative scan (pgvector 0.8+): o índice continua buscando até completar o LIMIT
SET hnsw.iterative_scan = strict_order;     -- mantém a ordenação exata
SET hnsw.iterative_scan = relaxed_order;    -- mais rápido, ordem levemente relaxada
SET hnsw.max_scan_tuples = 20000;           -- teto de segurança
SET ivfflat.iterative_scan = relaxed_order;

SELECT titulo FROM documentos
WHERE categoria = 'juridico'
ORDER BY embedding <=> $1 LIMIT 5;

-- 2. Índice parcial: quando o filtro é fixo e recorrente
CREATE INDEX ON documentos USING hnsw (embedding vector_cosine_ops)
WHERE categoria = 'juridico';

-- 3. Índice por partição: uma coluna de tenant/órgão
CREATE INDEX ON documentos USING hnsw ((embedding) vector_cosine_ops);
-- + particionar a tabela por tenant_id

-- 4. Overfetch + filtro externo (funciona em qualquer versão)
WITH candidatos AS (
    SELECT id, titulo, categoria, embedding <=> $1 AS dist
    FROM documentos
    ORDER BY embedding <=> $1
    LIMIT 100                                -- pega mais do que precisa
)
SELECT * FROM candidatos WHERE categoria = 'juridico' ORDER BY dist LIMIT 5;
```

Confira se o índice está realmente sendo usado:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM documentos ORDER BY embedding <=> '[...]' LIMIT 5;
-- Bom:  Index Scan using idx_doc_emb
-- Ruim: Seq Scan  → operador diferente do índice, ou tabela pequena demais
```

---

## 8. Busca híbrida (vetorial + full-text)

Busca vetorial entende sentido, mas erra em siglas, números de processo e nomes próprios. Busca textual acerta o literal e ignora sinônimos. Combinar as duas é quase sempre melhor que qualquer uma sozinha.

```sql
-- Coluna e índice de full-text em português
ALTER TABLE documentos ADD COLUMN busca tsvector
  GENERATED ALWAYS AS (to_tsvector('portuguese', titulo || ' ' || conteudo)) STORED;

CREATE INDEX idx_doc_busca ON documentos USING gin (busca);
```

### Reciprocal Rank Fusion (RRF)

Junta os dois rankings pela **posição** em cada lista, sem precisar normalizar scores de escalas diferentes:

```sql
WITH semantica AS (
    SELECT id, row_number() OVER (ORDER BY embedding <=> $1) AS pos
    FROM documentos
    ORDER BY embedding <=> $1
    LIMIT 30
),
textual AS (
    SELECT id, row_number() OVER (
        ORDER BY ts_rank_cd(busca, plainto_tsquery('portuguese', $2)) DESC
    ) AS pos
    FROM documentos
    WHERE busca @@ plainto_tsquery('portuguese', $2)
    LIMIT 30
)
SELECT d.id, d.titulo,
       coalesce(1.0 / (60 + s.pos), 0) + coalesce(1.0 / (60 + t.pos), 0) AS score
FROM documentos d
LEFT JOIN semantica s ON s.id = d.id
LEFT JOIN textual   t ON t.id = d.id
WHERE s.id IS NOT NULL OR t.id IS NOT NULL
ORDER BY score DESC
LIMIT 10;
```

`$1` = embedding da pergunta · `$2` = texto da pergunta · `60` = constante de amortecimento do RRF (valor usual).

---

## 9. Economizar espaço: halfvec e quantização binária

Um índice HNSW de 1M de vetores `vector(1536)` passa de 6 GB. Duas saídas:

```sql
-- halfvec: metade do espaço, recall praticamente igual
ALTER TABLE documentos ADD COLUMN embedding_half halfvec(1536);
UPDATE documentos SET embedding_half = embedding::halfvec;
CREATE INDEX ON documentos USING hnsw (embedding_half halfvec_cosine_ops);

-- Índice em halfvec mantendo a coluna original em vector (expressão)
CREATE INDEX ON documentos USING hnsw ((embedding::halfvec(1536)) halfvec_cosine_ops);
SELECT * FROM documentos ORDER BY embedding::halfvec(1536) <=> $1::halfvec(1536) LIMIT 5;

-- Matryoshka: modelos como text-embedding-3-* permitem truncar dimensões
CREATE INDEX ON documentos USING hnsw ((subvector(embedding, 1, 512)::vector(512)) vector_cosine_ops);
```

### Rerank em duas etapas (binário → exato)

Busca ampla e barata no vetor binário, depois reordena com o vetor completo:

```sql
ALTER TABLE documentos ADD COLUMN emb_bin bit(1536)
  GENERATED ALWAYS AS (binary_quantize(embedding)) STORED;
CREATE INDEX ON documentos USING hnsw (emb_bin bit_hamming_ops);

WITH grosso AS (
    SELECT id FROM documentos
    ORDER BY emb_bin <~> binary_quantize($1)
    LIMIT 200
)
SELECT d.id, d.titulo, d.embedding <=> $1 AS dist
FROM documentos d JOIN grosso g ON g.id = d.id
ORDER BY dist
LIMIT 10;
```

---

## 10. Python — psycopg e SQLAlchemy

```bash
pip install "psycopg[binary]" pgvector sqlalchemy openai
# ou, para embeddings locais e offline:
pip install sentence-transformers
```

### psycopg 3 direto

```python
import psycopg
from pgvector.psycopg import register_vector

conn = psycopg.connect("postgresql://app:senha@localhost:5432/rag")
register_vector(conn)                      # ensina o driver a converter vector ↔ numpy

with conn.cursor() as cur:
    cur.execute(
        "INSERT INTO documentos (titulo, conteudo, embedding) VALUES (%s, %s, %s)",
        ("Manual CIPTEA", texto, embedding),      # embedding = list[float] ou np.array
    )

    cur.execute(
        """
        SELECT id, titulo, 1 - (embedding <=> %s) AS score
        FROM documentos
        ORDER BY embedding <=> %s
        LIMIT %s
        """,
        (consulta_emb, consulta_emb, 5),
    )
    for id_, titulo, score in cur.fetchall():
        print(f"{score:.3f}  {titulo}")

conn.commit()
```

### SQLAlchemy (stack FastAPI + SQLAlchemy)

```python
from sqlalchemy import create_engine, select, text, Text, BigInteger
from sqlalchemy.orm import DeclarativeBase, Session, mapped_column, Mapped
from pgvector.sqlalchemy import Vector

class Base(DeclarativeBase): ...

class Documento(Base):
    __tablename__ = "documentos"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    titulo: Mapped[str] = mapped_column(Text)
    conteudo: Mapped[str] = mapped_column(Text)
    embedding: Mapped[list[float]] = mapped_column(Vector(1536))

engine = create_engine("postgresql+psycopg://app:senha@localhost:5432/rag")

with Session(engine) as s:
    s.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
    Base.metadata.create_all(engine)

    # Inserir
    s.add(Documento(titulo="Manual", conteudo=texto, embedding=emb))
    s.commit()

    # Buscar os 5 mais próximos (cosseno)
    stmt = (
        select(Documento, Documento.embedding.cosine_distance(emb).label("dist"))
        .order_by(Documento.embedding.cosine_distance(emb))
        .limit(5)
    )
    for doc, dist in s.execute(stmt):
        print(round(1 - dist, 3), doc.titulo)

    # Outras métricas: .l2_distance(v) · .max_inner_product(v) · .l1_distance(v)
```

> [!TIP]
> Índices de vetor **não** devem ser criados pelo `create_all()`. Crie-os em uma migration (Flyway/Alembic) com `CREATE INDEX CONCURRENTLY`, para controlar parâmetros e não travar a tabela.

### Gerar embeddings

```python
# OpenAI (API paga, 1536 dimensões)
from openai import OpenAI
client = OpenAI()

def embed(textos: list[str]) -> list[list[float]]:
    resp = client.embeddings.create(model="text-embedding-3-small", input=textos)
    return [d.embedding for d in resp.data]      # envie em lotes: mais barato e rápido

# Local, offline e gratuito (384 dimensões, roda em CPU)
from sentence_transformers import SentenceTransformer
modelo = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")   # bom em português
vetores = modelo.encode(textos, normalize_embeddings=True).tolist()
```

---

## 11. Pipeline de RAG completo

```
Documento → chunking → embeddings → INSERT no Postgres
                                          ↓
Pergunta → embedding → busca híbrida → top-k trechos → prompt do LLM → resposta com fontes
```

### Esquema com chunks

```sql
CREATE TABLE arquivos (
    id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome      text NOT NULL,
    origem    text,
    criado_em timestamptz DEFAULT now()
);

CREATE TABLE chunks (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    arquivo_id bigint NOT NULL REFERENCES arquivos(id) ON DELETE CASCADE,
    ordem      int NOT NULL,
    conteudo   text NOT NULL,
    tokens     int,
    embedding  vector(1536) NOT NULL,
    metadados  jsonb NOT NULL DEFAULT '{}',
    UNIQUE (arquivo_id, ordem)
);

CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
CREATE INDEX ON chunks USING gin (metadados jsonb_path_ops);
CREATE INDEX ON chunks (arquivo_id);
```

### Ingestão

```python
def chunk_texto(texto: str, tamanho: int = 800, overlap: int = 100) -> list[str]:
    """Divide por caracteres com sobreposição. Para PDFs, prefira dividir por
    parágrafo/seção — chunk cortado no meio da frase piora muito a recuperação."""
    passo = tamanho - overlap
    return [texto[i:i + tamanho] for i in range(0, len(texto), passo) if texto[i:i + tamanho].strip()]

def ingerir(conn, nome: str, texto: str):
    partes = chunk_texto(texto)
    vetores = embed(partes)                            # em lote
    with conn.cursor() as cur:
        cur.execute("INSERT INTO arquivos (nome) VALUES (%s) RETURNING id", (nome,))
        arquivo_id = cur.fetchone()[0]
        cur.executemany(
            "INSERT INTO chunks (arquivo_id, ordem, conteudo, embedding) VALUES (%s,%s,%s,%s)",
            [(arquivo_id, i, p, v) for i, (p, v) in enumerate(zip(partes, vetores))],
        )
    conn.commit()
```

### Recuperação e resposta

```python
BUSCA = """
SELECT c.conteudo, a.nome, 1 - (c.embedding <=> %s) AS score
FROM chunks c JOIN arquivos a ON a.id = c.arquivo_id
WHERE 1 - (c.embedding <=> %s) > 0.25
ORDER BY c.embedding <=> %s
LIMIT %s
"""

def responder(conn, pergunta: str, k: int = 5) -> str:
    q = embed([pergunta])[0]
    with conn.cursor() as cur:
        cur.execute("SET LOCAL hnsw.ef_search = 100")
        cur.execute(BUSCA, (q, q, q, k))
        trechos = cur.fetchall()

    if not trechos:
        return "Não encontrei nada relevante na base."

    contexto = "\n\n".join(f"[{nome}] {conteudo}" for conteudo, nome, _ in trechos)
    prompt = (
        "Responda usando SOMENTE o contexto abaixo. "
        "Se a resposta não estiver nele, diga que não sabe. Cite as fontes entre colchetes.\n\n"
        f"CONTEXTO:\n{contexto}\n\nPERGUNTA: {pergunta}"
    )
    return client.chat.completions.create(
        model="gpt-4o-mini", messages=[{"role": "user", "content": prompt}]
    ).choices[0].message.content
```

---

## 12. Manutenção e monitoramento

```sql
-- Tamanho do índice vetorial
SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho, idx_scan
FROM pg_stat_user_indexes WHERE relname = 'chunks';

-- Quantos vetores por tabela
SELECT count(*), pg_size_pretty(pg_total_relation_size('chunks')) FROM chunks;

-- Medir recall: comparar a busca aproximada com a exata
SET enable_indexscan = off;                     -- força busca exata
-- rode a mesma query e compare os ids retornados
RESET enable_indexscan;

-- Reconstruir índice (IVFFlat degrada com muitas inserções)
REINDEX INDEX CONCURRENTLY idx_chunks_embedding;

-- Depois de carga em massa
VACUUM ANALYZE chunks;
```

Checklist de tuning quando a busca está lenta ou imprecisa:

1. O `EXPLAIN` mostra `Index Scan`? Se for `Seq Scan`, o operador do `ORDER BY` não bate com a classe do índice.
2. Recall baixo → aumente `hnsw.ef_search` (40 → 100 → 200) e meça de novo.
3. Ainda baixo → recrie o índice com `m = 32, ef_construction = 128`.
4. Build estourando a RAM → `maintenance_work_mem`, ou troque `vector` por `halfvec`.
5. Retornando menos linhas que o `LIMIT` com filtro → `hnsw.iterative_scan` (seção 7).
6. `shared_buffers` pequeno → o índice não cabe em cache e cada busca vira I/O de disco.

---

## 13. Armadilhas comuns

| Problema | Causa | Correção |
|---|---|---|
| `expected 1536 dimensions, not 384` | modelo diferente do usado na criação | padronize o modelo; regere os embeddings |
| `Seq Scan` mesmo com índice | operador ≠ classe do índice (`<->` vs `<=>`) | use o mesmo operador do `vector_*_ops` |
| Resultados ruins e genéricos | chunks grandes demais ou cortados no meio | 300–800 tokens, com overlap, quebrando por seção |
| Busca boa em conceito, péssima em sigla/número | limitação do embedding | busca híbrida com full-text (seção 8) |
| `LIMIT 5` com `WHERE` devolve 2 linhas | filtro aplicado após o ANN | `iterative_scan` ou índice parcial |
| Índice gigante | `vector(1536)` em milhões de linhas | `halfvec`, `subvector` ou quantização binária |
| Inserção lenta após criar HNSW | cada `INSERT` atualiza o grafo | carregue os dados primeiro, indexe depois |
| Similaridade sempre alta (0.8+) | cosseno em textos do mesmo domínio | calibre o limiar pelos seus dados, não use 0.8 por padrão |
| `CREATE EXTENSION` falha | extensão não instalada no servidor | instale `postgresql-17-pgvector` (seção 2) |

> [!TIP]
> Antes de otimizar o índice, otimize o **chunking**. Na prática, a maior parte dos resultados ruins de RAG vem de trechos mal divididos, não de parâmetro de índice.

---

## Ver também

- [PostgreSQL.md](PostgreSQL.md) — psql, DDL, JSONB, índices, backup e tuning
- [SQL-Select.md](SQL-Select.md) — CTE e window functions usadas nas queries híbridas
- [../dados/Pandas.md](../dados/Pandas.md) — preparar os dados antes de gerar embeddings
- [../backend/Docker.md](../backend/Docker.md) — subir o `pgvector/pgvector` no Compose
- [../backend/VPS-Ubuntu.md](../backend/VPS-Ubuntu.md) — rodar em produção na VPS

**Fontes:** [pgvector — CHANGELOG 0.8.1](https://api.pgxn.org/src/vector/vector-0.8.1/CHANGELOG.md) · [pgvector 0.8.0 (postgresql.org)](https://www.postgresql.org/about/news/pgvector-080-released-2952) · [Iterative index scans](https://docs.pgedge.com/pgvector/v0-8-0/iterative-index-scans/) · [Hybrid search com Postgres (Crunchy Data)](https://www.crunchydata.com/blog/hybrid-vector-search)
