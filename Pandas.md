# Pandas — Python para Análise de Dados

Referência passo a passo com exemplos práticos de análise de dados usando a biblioteca Pandas.

---

## Instalação

```bash
pip install pandas
pip install pandas openpyxl xlrd  # suporte a Excel
```

---

## 1. Importação e estruturas básicas

```python
import pandas as pd
import numpy as np
```

### Series — array unidimensional com índice

```python
s = pd.Series([10, 20, 30, 40], index=["a", "b", "c", "d"])
print(s["b"])   # 20
print(s[1:3])   # b=20, c=30
```

### DataFrame — tabela bidimensional

```python
df = pd.DataFrame({
    "nome":  ["Ana", "Bruno", "Carla"],
    "idade": [25, 30, 22],
    "salario": [4500.0, 7200.0, 3800.0]
})
```

---

## 2. Carregar e salvar dados

### CSV

```python
df = pd.read_csv("dados.csv")
df = pd.read_csv("dados.csv", sep=";", encoding="utf-8")
df = pd.read_csv("dados.csv", usecols=["nome", "salario"])  # só essas colunas
df = pd.read_csv("dados.csv", nrows=100)                    # primeiras 100 linhas

df.to_csv("saida.csv", index=False)
df.to_csv("saida.csv", index=False, sep=";", encoding="utf-8")
```

### Excel

```python
df = pd.read_excel("planilha.xlsx", sheet_name="Plan1")
df.to_excel("saida.xlsx", sheet_name="Resultado", index=False)
```

### JSON

```python
df = pd.read_json("dados.json")
df.to_json("saida.json", orient="records", force_ascii=False)
```

### Google Sheets / URL pública (CSV exportado)

```python
url = "https://docs.google.com/spreadsheets/d/ID/export?format=csv"
df = pd.read_csv(url)
```

---

## 3. Explorar o DataFrame

```python
df.shape          # (linhas, colunas)
df.dtypes         # tipo de cada coluna
df.info()         # resumo: tipos, nulos, memória
df.describe()     # estatísticas: count, mean, std, min, max...
df.head(5)        # primeiras 5 linhas
df.tail(5)        # últimas 5 linhas
df.sample(3)      # 3 linhas aleatórias
df.columns        # nomes das colunas
df.index          # índices
```

---

## 4. Selecionar dados

### Coluna(s)

```python
df["nome"]                  # Series
df[["nome", "salario"]]     # DataFrame
```

### Linhas por posição — `.iloc`

```python
df.iloc[0]        # primeira linha
df.iloc[0:3]      # linhas 0, 1, 2
df.iloc[1, 2]     # linha 1, coluna 2
df.iloc[:, 0]     # toda a coluna 0
```

### Linhas por rótulo — `.loc`

```python
df.loc[0]                   # linha com índice 0
df.loc[0:2, "nome"]         # linhas 0-2, coluna "nome"
df.loc[:, ["nome", "idade"]]
```

### Filtros (condições)

```python
df[df["idade"] > 25]
df[df["nome"] == "Ana"]
df[(df["idade"] > 22) & (df["salario"] >= 4000)]   # AND
df[(df["nome"] == "Ana") | (df["nome"] == "Bruno")] # OR
df[~(df["salario"] < 4000)]                         # NOT
df[df["nome"].isin(["Ana", "Carla"])]               # está na lista
df[df["nome"].str.contains("an", case=False)]       # texto
```

---

## 5. Criar e transformar colunas

```python
df["bonus"] = df["salario"] * 0.10
df["nome_upper"] = df["nome"].str.upper()
df["faixa"] = df["salario"].apply(lambda x: "alto" if x > 5000 else "baixo")
```

### `apply` com função própria

```python
def classificar(row):
    if row["idade"] < 25:
        return "júnior"
    elif row["idade"] < 35:
        return "pleno"
    return "sênior"

df["nível"] = df.apply(classificar, axis=1)
```

### `map` para substituição de valores

```python
mapa = {"Ana": "A", "Bruno": "B", "Carla": "C"}
df["sigla"] = df["nome"].map(mapa)
```

### `assign` — encadeável

```python
df = (
    df
    .assign(bonus=df["salario"] * 0.1)
    .assign(total=lambda d: d["salario"] + d["bonus"])
)
```

---

## 6. Limpeza de dados

### Valores nulos

```python
df.isnull().sum()              # conta nulos por coluna
df.dropna()                    # remove linhas com qualquer nulo
df.dropna(subset=["salario"])  # remove só onde salario é nulo
df.fillna(0)                   # preenche nulos com 0
df["salario"].fillna(df["salario"].mean(), inplace=True)  # preenche com média
```

### Duplicatas

```python
df.duplicated().sum()
df.drop_duplicates()
df.drop_duplicates(subset=["nome"], keep="first")
```

### Tipos de dados

```python
df["idade"] = df["idade"].astype(int)
df["salario"] = df["salario"].astype(float)
df["data"] = pd.to_datetime(df["data"])
df["data"] = pd.to_datetime(df["data"], format="%d/%m/%Y")
```

### Renomear e remover colunas

```python
df.rename(columns={"nome": "name", "idade": "age"}, inplace=True)
df.drop(columns=["bonus", "sigla"], inplace=True)
```

### Resetar índice

```python
df.reset_index(drop=True, inplace=True)
```

---

## 7. Ordenar

```python
df.sort_values("salario")                          # crescente
df.sort_values("salario", ascending=False)         # decrescente
df.sort_values(["faixa", "salario"], ascending=[True, False])
```

---

## 8. Agrupamento — `groupby`

```python
df.groupby("faixa")["salario"].mean()
df.groupby("faixa")["salario"].agg(["mean", "sum", "count"])
```

### Agregações múltiplas

```python
resumo = df.groupby("faixa").agg(
    media_salario=("salario", "mean"),
    total_pessoas=("nome", "count"),
    maior_salario=("salario", "max")
).reset_index()
```

### `value_counts`

```python
df["faixa"].value_counts()
df["faixa"].value_counts(normalize=True)  # proporção
```

---

## 9. Juntar DataFrames

### `merge` — equivalente ao SQL JOIN

```python
# INNER JOIN
resultado = pd.merge(df_pedidos, df_clientes, on="cliente_id")

# LEFT JOIN
resultado = pd.merge(df_pedidos, df_clientes, on="cliente_id", how="left")

# JOIN com colunas de nomes diferentes
resultado = pd.merge(df_pedidos, df_clientes,
                     left_on="id_cliente", right_on="cliente_id")
```

### `concat` — empilhar DataFrames

```python
df_total = pd.concat([df_jan, df_fev, df_mar], ignore_index=True)
df_lado = pd.concat([df1, df2], axis=1)
```

---

## 10. Datas e tempo

```python
df["data"] = pd.to_datetime(df["data"])

df["ano"]  = df["data"].dt.year
df["mes"]  = df["data"].dt.month
df["dia"]  = df["data"].dt.day
df["dia_semana"] = df["data"].dt.day_name()

# Diferença entre datas
df["dias_desde"] = (pd.Timestamp.today() - df["data"]).dt.days

# Filtrar por período
df[df["data"] >= "2024-01-01"]
df[(df["data"] >= "2024-01-01") & (df["data"] <= "2024-06-30")]
```

---

## 11. Strings

```python
df["nome"].str.lower()
df["nome"].str.upper()
df["nome"].str.strip()                    # remove espaços extras
df["nome"].str.replace("  ", " ")
df["nome"].str.contains("silva", case=False)
df["nome"].str.startswith("A")
df["email"].str.split("@").str[1]        # domínio do e-mail
df["cep"].str.replace("-", "").str.zfill(8)
```

---

## 12. Pivot e reshape

### Pivot table

```python
tabela = df.pivot_table(
    values="salario",
    index="departamento",
    columns="nivel",
    aggfunc="mean",
    fill_value=0
)
```

### `melt` — largo para longo (unpivot)

```python
df_longo = df.melt(
    id_vars=["nome"],
    value_vars=["jan", "fev", "mar"],
    var_name="mes",
    value_name="vendas"
)
```

---

## 13. Exemplo completo — análise de vendas

```python
import pandas as pd

# Carregar dados
df = pd.read_csv("vendas.csv", sep=";", encoding="utf-8")
df["data"] = pd.to_datetime(df["data"], format="%d/%m/%Y")

# Explorar
print(df.shape)
print(df.isnull().sum())

# Limpeza
df.drop_duplicates(inplace=True)
df["valor"].fillna(df["valor"].median(), inplace=True)
df["produto"] = df["produto"].str.strip().str.upper()

# Colunas derivadas
df["mes"] = df["data"].dt.to_period("M").astype(str)
df["receita"] = df["quantidade"] * df["valor"]

# Resumo por mês
resumo_mes = df.groupby("mes").agg(
    total_vendas=("receita", "sum"),
    num_pedidos=("receita", "count"),
    ticket_medio=("receita", "mean")
).reset_index()

# Top 5 produtos
top5 = (
    df.groupby("produto")["receita"]
    .sum()
    .sort_values(ascending=False)
    .head(5)
    .reset_index()
    .rename(columns={"receita": "total_receita"})
)

# Exportar
resumo_mes.to_csv("resumo_mensal.csv", index=False)
top5.to_excel("top5_produtos.xlsx", index=False)

print(resumo_mes)
print(top5)
```

---

## 14. Performance com grandes volumes

```python
# Ler em chunks
for chunk in pd.read_csv("grande.csv", chunksize=10_000):
    processar(chunk)

# Reduzir memória ao carregar
df = pd.read_csv("dados.csv", dtype={
    "id": "int32",
    "valor": "float32",
    "status": "category"
})

# Verificar uso de memória
df.memory_usage(deep=True).sum() / 1024**2  # em MB
```

---

## Referência rápida — métodos mais usados

| Operação | Método |
|---|---|
| Carregar CSV | `pd.read_csv()` |
| Salvar CSV | `df.to_csv()` |
| Ver dimensões | `df.shape` |
| Resumo estatístico | `df.describe()` |
| Filtrar linhas | `df[df["col"] > x]` |
| Selecionar colunas | `df[["a", "b"]]` |
| Criar coluna | `df["nova"] = ...` |
| Agrupar | `df.groupby("col").agg(...)` |
| Ordenar | `df.sort_values("col")` |
| Remover nulos | `df.dropna()` |
| Preencher nulos | `df.fillna(valor)` |
| Remover duplicatas | `df.drop_duplicates()` |
| Juntar tabelas | `pd.merge(df1, df2, on="col")` |
| Empilhar tabelas | `pd.concat([df1, df2])` |
| Converter tipo | `df["col"].astype(tipo)` |
| Converter data | `pd.to_datetime(df["col"])` |
