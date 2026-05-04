# Google Colab + Pandas — Cheatsheet

Referência de análise de dados com Python, Pandas e gráficos no Google Colab.

> **Acesso:** [colab.research.google.com](https://colab.research.google.com) — execute Python no navegador sem instalar nada.

---

## 1. Carregar arquivo CSV

### Upload manual (do seu computador)

```python
from google.colab import files

uploaded = files.upload()  # abre seletor de arquivo
```

```python
import pandas as pd

df = pd.read_csv('nome-do-arquivo.csv')
```

### Do Google Drive

```python
from google.colab import drive

drive.mount('/content/drive')

df = pd.read_csv('/content/drive/MyDrive/pasta/arquivo.csv')
```

### Da internet (URL pública)

```python
url = 'https://exemplo.com/dados.csv'
df = pd.read_csv(url)
```

### Opções comuns do read_csv

```python
df = pd.read_csv(
    'arquivo.csv',
    sep=';',                  # separador (padrão é vírgula)
    encoding='utf-8',         # codificação (use 'latin1' se der erro)
    decimal=',',              # separador decimal (padrão é ponto)
    thousands='.',            # separador de milhar
    header=0,                 # linha do cabeçalho (0 = primeira linha)
    skiprows=2,               # pular N linhas no início
    nrows=1000,               # ler apenas N linhas
    usecols=['col1', 'col2'], # ler apenas colunas específicas
    parse_dates=['data'],     # converter coluna para datetime
)
```

---

## 2. Exploração inicial

```python
df.head()           # primeiras 5 linhas
df.head(10)         # primeiras 10 linhas
df.tail()           # últimas 5 linhas
df.sample(5)        # 5 linhas aleatórias

df.shape            # (linhas, colunas)
df.columns          # nomes das colunas
df.dtypes           # tipo de dado de cada coluna
df.info()           # resumo: tipos e valores nulos
df.describe()       # estatísticas: média, std, min, max, quartis
df.describe(include='all')  # inclui colunas não numéricas
```

---

## 3. Seleção de dados

### Colunas

```python
df['nome']              # uma coluna → Series
df[['nome', 'idade']]   # várias colunas → DataFrame
```

### Linhas por posição

```python
df.iloc[0]          # primeira linha
df.iloc[0:5]        # linhas 0 a 4
df.iloc[-1]         # última linha
df.iloc[0:5, 1:3]   # linhas 0-4, colunas 1-2
```

### Linhas por índice/label

```python
df.loc[0]                        # linha com índice 0
df.loc[0:5, ['nome', 'idade']]   # linhas e colunas por nome
```

### Filtros (where)

```python
df[df['idade'] > 30]
df[df['cidade'] == 'São Paulo']
df[df['salario'].between(3000, 8000)]
df[df['nome'].str.contains('Silva')]

# Múltiplas condições
df[(df['idade'] > 30) & (df['cidade'] == 'São Paulo')]
df[(df['idade'] < 20) | (df['idade'] > 60)]

# Valores em uma lista
df[df['estado'].isin(['SP', 'RJ', 'MG'])]

# Negação
df[~df['cidade'].isin(['Recife', 'Fortaleza'])]
```

---

## 4. Dados nulos

```python
df.isnull().sum()               # contar nulos por coluna
df.isnull().sum() / len(df)     # percentual de nulos

df.dropna()                     # remover linhas com qualquer nulo
df.dropna(subset=['coluna'])    # remover só se nulo em coluna específica
df.dropna(thresh=5)             # manter linhas com pelo menos 5 valores

df.fillna(0)                            # substituir nulos por 0
df.fillna({'col1': 0, 'col2': 'N/A'})  # por coluna
df['col'].fillna(df['col'].mean())      # pela média
df['col'].fillna(method='ffill')        # pelo valor anterior (forward fill)
df['col'].fillna(method='bfill')        # pelo próximo valor (backward fill)
```

---

## 5. Limpeza e transformações

### Tipos de dados

```python
df['col'].astype(int)
df['col'].astype(float)
df['col'].astype(str)

# Converter para datetime
df['data'] = pd.to_datetime(df['data'])
df['data'] = pd.to_datetime(df['data'], format='%d/%m/%Y')

# Converter para numérico (com coerção de erros)
df['valor'] = pd.to_numeric(df['valor'], errors='coerce')
```

### Strings

```python
df['nome'].str.upper()
df['nome'].str.lower()
df['nome'].str.strip()                  # remover espaços nas bordas
df['nome'].str.replace(',', '.')        # substituir
df['nome'].str.split(' ', expand=True)  # dividir em colunas
df['nome'].str.len()                    # tamanho da string
```

### Duplicatas

```python
df.duplicated().sum()               # contar linhas duplicadas
df.drop_duplicates()                # remover duplicatas
df.drop_duplicates(subset=['col'])  # duplicatas por coluna específica
```

### Renomear e remover colunas

```python
df.rename(columns={'old': 'new', 'old2': 'new2'})

df.drop(columns=['coluna1', 'coluna2'])
df.drop(columns=['coluna'], inplace=True)  # altera o df original
```

### Criar colunas novas

```python
df['total'] = df['preco'] * df['quantidade']
df['nome_completo'] = df['nome'] + ' ' + df['sobrenome']

# Com condição
df['faixa'] = df['idade'].apply(lambda x: 'jovem' if x < 30 else 'adulto')

import numpy as np
df['categoria'] = np.where(df['valor'] > 1000, 'alto', 'baixo')

# Múltiplas condições
condicoes = [
    df['nota'] >= 7,
    df['nota'] >= 5,
    df['nota'] < 5,
]
resultados = ['aprovado', 'recuperação', 'reprovado']
df['situacao'] = np.select(condicoes, resultados)
```

---

## 6. Ordenar e agrupar

### Ordenar

```python
df.sort_values('coluna')
df.sort_values('coluna', ascending=False)
df.sort_values(['col1', 'col2'], ascending=[True, False])
```

### Agrupar (groupby)

```python
df.groupby('categoria')['valor'].sum()
df.groupby('categoria')['valor'].mean()
df.groupby('categoria')['valor'].count()

# Múltiplas agregações
df.groupby('categoria').agg(
    total=('valor', 'sum'),
    media=('valor', 'mean'),
    qtd=('valor', 'count'),
    maximo=('valor', 'max'),
)

# Agrupar por múltiplas colunas
df.groupby(['estado', 'categoria'])['valor'].sum().reset_index()
```

### Tabela dinâmica (pivot table)

```python
pd.pivot_table(
    df,
    values='valor',
    index='estado',
    columns='categoria',
    aggfunc='sum',
    fill_value=0,
)
```

---

## 7. Datas

```python
df['data'] = pd.to_datetime(df['data'])

df['ano']        = df['data'].dt.year
df['mes']        = df['data'].dt.month
df['dia']        = df['data'].dt.day
df['dia_semana'] = df['data'].dt.day_name()
df['trimestre']  = df['data'].dt.quarter

# Filtrar por período
df[df['data'] >= '2024-01-01']
df[(df['data'] >= '2024-01-01') & (df['data'] <= '2024-06-30')]

# Agrupar por período
df.groupby(df['data'].dt.to_period('M'))['valor'].sum()  # por mês
df.groupby(df['data'].dt.to_period('Y'))['valor'].sum()  # por ano
```

---

## 8. Gráficos com Matplotlib

```python
import matplotlib.pyplot as plt
```

### Gráfico de barras

```python
categorias = df['categoria'].value_counts()

plt.figure(figsize=(10, 5))
plt.bar(categorias.index, categorias.values, color='steelblue')
plt.title('Quantidade por Categoria')
plt.xlabel('Categoria')
plt.ylabel('Quantidade')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Histograma (distribuição)

```python
plt.figure(figsize=(8, 5))
plt.hist(df['valor'], bins=20, color='coral', edgecolor='white')
plt.title('Distribuição de Valores')
plt.xlabel('Valor')
plt.ylabel('Frequência')
plt.tight_layout()
plt.show()
```

### Gráfico de linha (série temporal)

```python
vendas_mes = df.groupby(df['data'].dt.to_period('M'))['valor'].sum()

plt.figure(figsize=(12, 5))
plt.plot(vendas_mes.index.astype(str), vendas_mes.values, marker='o', color='steelblue')
plt.title('Vendas por Mês')
plt.xlabel('Mês')
plt.ylabel('Total (R$)')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Gráfico de pizza

```python
categorias = df['categoria'].value_counts()

plt.figure(figsize=(7, 7))
plt.pie(
    categorias.values,
    labels=categorias.index,
    autopct='%1.1f%%',
    startangle=90,
)
plt.title('Distribuição por Categoria')
plt.tight_layout()
plt.show()
```

### Gráfico de dispersão (scatter)

```python
plt.figure(figsize=(8, 5))
plt.scatter(df['idade'], df['salario'], alpha=0.5, color='steelblue')
plt.title('Idade vs Salário')
plt.xlabel('Idade')
plt.ylabel('Salário')
plt.tight_layout()
plt.show()
```

### Múltiplos gráficos (subplots)

```python
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].bar(df['categoria'].value_counts().index, df['categoria'].value_counts().values)
axes[0].set_title('Quantidade por Categoria')
axes[0].tick_params(axis='x', rotation=45)

axes[1].hist(df['valor'], bins=20, color='coral')
axes[1].set_title('Distribuição de Valores')

plt.tight_layout()
plt.show()
```

---

## 9. Gráficos com Seaborn

```python
import seaborn as sns
import matplotlib.pyplot as plt

sns.set_theme(style='whitegrid')  # tema padrão
```

### Barras com médias automáticas

```python
plt.figure(figsize=(10, 5))
sns.barplot(data=df, x='categoria', y='valor', estimator='mean')
plt.title('Média de Valor por Categoria')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Boxplot (distribuição por grupo)

```python
plt.figure(figsize=(10, 5))
sns.boxplot(data=df, x='categoria', y='valor')
plt.title('Distribuição de Valor por Categoria')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Heatmap de correlação

```python
plt.figure(figsize=(10, 8))
correlacao = df.select_dtypes(include='number').corr()
sns.heatmap(correlacao, annot=True, fmt='.2f', cmap='coolwarm', center=0)
plt.title('Mapa de Correlação')
plt.tight_layout()
plt.show()
```

### Countplot (contagem por categoria)

```python
plt.figure(figsize=(10, 5))
sns.countplot(data=df, x='categoria', order=df['categoria'].value_counts().index)
plt.title('Contagem por Categoria')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

### Lineplot com intervalo de confiança

```python
plt.figure(figsize=(12, 5))
sns.lineplot(data=df, x='mes', y='valor', hue='categoria')
plt.title('Valor por Mês e Categoria')
plt.tight_layout()
plt.show()
```

### Scatterplot com cores por categoria

```python
plt.figure(figsize=(8, 5))
sns.scatterplot(data=df, x='idade', y='salario', hue='categoria', alpha=0.7)
plt.title('Idade vs Salário por Categoria')
plt.tight_layout()
plt.show()
```

---

## 10. Exportar resultados

### Salvar CSV

```python
df.to_csv('resultado.csv', index=False)
df.to_csv('resultado.csv', index=False, sep=';', encoding='utf-8-sig')  # utf-8-sig abre bem no Excel
```

### Baixar arquivo no Colab

```python
from google.colab import files

df.to_csv('resultado.csv', index=False)
files.download('resultado.csv')
```

### Salvar no Google Drive

```python
df.to_csv('/content/drive/MyDrive/pasta/resultado.csv', index=False)
```

### Salvar gráfico como imagem

```python
plt.savefig('grafico.png', dpi=150, bbox_inches='tight')
files.download('grafico.png')
```

---

## 11. Passo a passo — análise completa

```python
# 1. Imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from google.colab import files, drive

sns.set_theme(style='whitegrid')

# 2. Carregar dados
drive.mount('/content/drive')
df = pd.read_csv('/content/drive/MyDrive/dados.csv', sep=';', encoding='utf-8')

# 3. Exploração inicial
print(df.shape)
print(df.dtypes)
df.head()

# 4. Verificar nulos
print(df.isnull().sum())

# 5. Limpeza
df['data'] = pd.to_datetime(df['data'], format='%d/%m/%Y')
df['valor'] = pd.to_numeric(df['valor'], errors='coerce')
df.dropna(subset=['valor'], inplace=True)
df.drop_duplicates(inplace=True)

# 6. Criar colunas derivadas
df['mes'] = df['data'].dt.to_period('M').astype(str)
df['ano'] = df['data'].dt.year

# 7. Análise por categoria
resumo = df.groupby('categoria').agg(
    total=('valor', 'sum'),
    media=('valor', 'mean'),
    qtd=('valor', 'count'),
).reset_index().sort_values('total', ascending=False)
print(resumo)

# 8. Visualizar
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

sns.barplot(data=resumo, x='categoria', y='total', ax=axes[0])
axes[0].set_title('Total por Categoria')
axes[0].tick_params(axis='x', rotation=45)

df.groupby('mes')['valor'].sum().plot(ax=axes[1], marker='o')
axes[1].set_title('Evolução Mensal')
axes[1].tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('analise.png', dpi=150, bbox_inches='tight')
plt.show()

# 9. Exportar
df.to_csv('dados_limpos.csv', index=False)
files.download('dados_limpos.csv')
files.download('analise.png')
```

---

## 12. Dicas do Google Colab

| Atalho | Ação |
|---|---|
| `Ctrl + Enter` | Executar célula atual |
| `Shift + Enter` | Executar e avançar para próxima |
| `Alt + Enter` | Executar e criar nova célula abaixo |
| `Ctrl + M B` | Inserir célula abaixo |
| `Ctrl + M A` | Inserir célula acima |
| `Ctrl + M D` | Deletar célula |
| `Ctrl + M Z` | Desfazer |
| `Ctrl + /` | Comentar linha |

```python
# Ver uso de memória RAM
!free -h

# Ver arquivos no ambiente
!ls

# Instalar pacotes extras
!pip install openpyxl xlrd plotly

# Ler Excel
df = pd.read_excel('arquivo.xlsx', sheet_name='Planilha1')

# Ver versão das libs
import pandas as pd
print(pd.__version__)
```
