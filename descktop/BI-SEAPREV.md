## Análise Completa do Power BI — Governo de Pernambuco

O dashboard é composto por **10 páginas** divididas em módulos temáticos. Aqui está a análise estruturada e o plano de implementação em Python.

---

### 📊 Estrutura das Páginas

| Página | Módulo | Tema |
|---|---|---|
| 1 | Mediação — Panorama Atendimentos | Atendimentos por município (gráfico de barras horizontais, verde) |
| 2 | Mediação — Visão Geral | Casos por município, tipos de conflito, status (pizza), especificação do conflito |
| 3 | JPC — Panorama Atendimentos | Atendimentos + divulgações por mês/município (barras duplas), ranking serviços |
| 4 | JPC — Atendimento por Natureza | Barras empilhadas: PRIVADO / MUNICIPAL / FEDERAL / ESTADUAL por município |
| 5 | JPC — Atendimento por Sec. Estadual | Barras empilhadas por secretaria estadual |
| 6 | JPC — Divulgação por Sec. Estadual | Mesmo layout da p.5 para divulgações |
| 7 | NEPS em Ação | Panorama geral atendimentos + divulgações, serviços NEPS |
| 8 | NEPS em Ação — Natureza | Barras empilhadas ESTADUAL/MUNICIPAL/PRIVADO/TERCEIRO SETOR |
| 9 | MVI Pernambuco | KPIs, perfil ocorrências, motivação geral (pizza), dia da semana (pizza), período |
| 10 | MVI Consumado | Municípios, mês a mês, bairros (ranking detalhado) |

---

### 🔑 KPIs Identificados

- **Total Casos**: 6.679 | **Nº Atendimentos**: 8.788 | **% Meta Cumprida**: 103,88% | **Pop. IBGE 2022**: 4.450.730 | **% Casos/Pop.**: 0,15%
- **Total Mediações**: 1.278
- **Total Atendimentos JPC**: 32.927 | **Total Divulgações**: 20.102
- **NEPS Atendimentos**: 4.112 | **NEPS Divulgações**: 3.612
- **MVI Consumado**: 4.127 | **MVI Tentado**: 2.853 | **% Tentado**: 0,03%

---

### 🎨 Paleta Visual

- **Fundo geral**: azul escuro (`#002060` / `#003087`)
- **Destaques/barras**: verde lima (`#00FF00` / `#7CFC00`), azul médio (`#1F77B4`), laranja (`#FF8C00`)
- **Títulos**: amarelo ouro (`#FFD700`)
- **Cards KPI**: azul royal com ícones brancos

---

### 🐍 Proposta de Implementação em Python

**Tecnologias recomendadas:**

- **[Streamlit](https://streamlit.io/)** — interface web interativa, simples de deployar
- **Plotly Express / Plotly Graph Objects** — todos os tipos de gráfico necessários
- **Pandas** — manipulação dos dados
- **openpyxl / SQLAlchemy** — ingestão dos dados reais

---

### Código base completo (Streamlit)

```python
# dashboard_pernambuco.py
# pip install streamlit plotly pandas

import streamlit as st
import plotly.express as px
import plotly.graph_objects as go
import pandas as pd

# ── Configuração da página ─────────────────────────────────────────────────────
st.set_page_config(
    page_title="Mediação de Conflitos — Pernambuco",
    page_icon="⚖️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── Estilo CSS (aproxima o visual do Power BI original) ───────────────────────
st.markdown("""
<style>
    .stApp { background-color: #001f4d; color: white; }
    .metric-card {
        background: #003087; border-radius: 10px;
        padding: 15px; text-align: center; margin: 5px;
    }
    .metric-value { font-size: 2rem; font-weight: bold; color: #FFD700; }
    .metric-label { font-size: 0.8rem; color: #ADD8E6; text-transform: uppercase; }
    h1, h2, h3 { color: #FFD700 !important; }
    .section-title {
        background: #003087; color: white;
        padding: 8px 15px; border-radius: 5px;
        font-weight: bold; text-align: center;
        margin-bottom: 10px;
    }
</style>
""", unsafe_allow_html=True)

# ── Dados de exemplo (substituir pela fonte real) ─────────────────────────────
@st.cache_data
def load_mediacao_data():
    municipios = [
        "CARUARU", "ARARIPINA", "RECIFE", "PALMARES",
        "VITORIA DE SANTO ANTAO", "TRINDADE", "OURICURI",
        "PETROLINA", "IPUBI", "SAO LOURENCO DA MATA",
        "JABOATAO DOS GUARARAPES", "CAMARAGIBE",
        "PAULISTA", "OLINDA", "CABO DE SANTO AGOSTINHO"
    ]
    atendimentos = [2046,1154,698,652,522,316,302,282,206,179,127,70,62,48,15]
    return pd.DataFrame({"municipio": municipios, "atendimentos": atendimentos})

@st.cache_data
def load_conflitos_data():
    return pd.DataFrame({
        "tipo": ["FAMILIAR","ESCOLAR","RELACAO DE CONSUMO","VIZINHANCA","NO TRABALHO"],
        "quantidade": [442, 328, 256, 238, 14]
    })

@st.cache_data
def load_status_data():
    return pd.DataFrame({
        "status": ["SOLUCIONADO","NAO SOLUCIONADO","EM ABERTO","ENCAMINHADO"],
        "quantidade": [682, 321, 240, 35],
        "percentual": [53.36, 25.12, 18.78, 2.74]
    })

@st.cache_data
def load_visao_geral():
    municipios = [
        "RECIFE","CARUARU","PALMARES","SAO LOURENCO DA MATA",
        "JABOATAO DOS GUARARAPES","VITORIA DE SANTO ANTAO","IPUBI",
        "CAMARAGIBE","ARARIPINA","OURICURI","PAULISTA","TRINDADE",
        "OLINDA","PETROLINA","CABO DE SANTO AGOSTINHO"
    ]
    casos = [303,231,172,101,95,80,54,49,47,38,37,28,27,11,5]
    return pd.DataFrame({"municipio": municipios, "casos": casos})

@st.cache_data
def load_jpc_timeline():
    """Série temporal JPC — atendimentos e divulgações por mês/município."""
    data = {
        "municipio": ["CABO DE SANTO AGOSTINHO","JABOATAO DOS GUARARAPES",
                      "PAULISTA","PETROLINA","VICENCIA","CARUARU",
                      "SAO LOURENCO DA MATA","BONITO","RECIFE","CARUARU",
                      "RECIFE","CARUARU","SAO VICENTE FE.","IPUBI","OURICURI"],
        "mes": ["ago/24","nov/24","nov/24","jan/25","jan/25","abr/25",
                "mai/25","jun/25","ago/25","set/25","out/25","nov/25",
                "dez/25","abr/26","abr/26"],
        "atendimentos": [286,841,3473,2772,1683,2146,1472,1530,886,1162,1311,1277,1148,549,906],
        "divulgacoes": [0,0,0,0,1824,2299,4379,4004,2039,1956,1806,1459,1508,265,443]
    }
    return pd.DataFrame(data)

@st.cache_data
def load_mvi_data():
    return {
        "consumado": 4127,
        "tentado": 2853,
        "perc_tentado": 0.03,
        "populacao": 9032351,
        "motivacao_consumado": {
            "ATIVIDADES CRIMINAIS": 2765,
            "VIOLENCIA INTERPESSOAL": 199,
            "OUTRAS MOTIVACOES": 160,
            "EXCLUDENTE DE LICITUDE": 89,
            "FEMINICIDIO": 0,
            "A DEFINIR": 778,
        },
        "dia_semana_consumado": {
            "DOM":771,"SAB":558,"SEX":555,"QUI":540,"QUA":501,"TER":493,"SEG":709
        }
    }

# ── Sidebar — Filtros globais ─────────────────────────────────────────────────
st.sidebar.markdown("## 🔍 Filtros")
regioes = ["Todos", "Agreste", "Sertão", "Zona da Mata", "Grande Recife"]
regiao = st.sidebar.selectbox("Região", regioes)

municipios_lista = ["Todos","Recife","Caruaru","Araripina","Palmares",
                    "Petrolina","Olinda","Paulista"]
municipio = st.sidebar.selectbox("Município", municipios_lista)

col_d1, col_d2 = st.sidebar.columns(2)
data_inicio = col_d1.date_input("De", value=pd.Timestamp("2026-01-05"))
data_fim = col_d2.date_input("Até", value=pd.Timestamp("2026-04-30"))

# ── Navegação por abas (equivale às páginas do Power BI) ─────────────────────
tabs = st.tabs([
    "📊 Panorama Atendimentos",
    "🔎 Visão Geral Mediação",
    "🏛️ JPC Panorama",
    "🌿 JPC Natureza",
    "🏢 JPC Sec. Estadual",
    "📣 NEPS em Ação",
    "🚨 MVI Pernambuco",
    "📍 MVI Detalhamento",
])

# ─────────────────────────────────────────────────────────────────────────────
# ABA 1 — PANORAMA ATENDIMENTOS (Mediação de Conflitos)
# ─────────────────────────────────────────────────────────────────────────────
with tabs[0]:
    st.markdown("# ⚖️ MEDIAÇÃO DE CONFLITOS")
    st.caption(f"Data Movimentação: {data_inicio.strftime('%d/%m/%Y')} a {data_fim.strftime('%d/%m/%Y')}")

    # KPI cards
    k1, k2, k3, k4, k5 = st.columns(5)
    kpis = [
        ("TOTAL CASOS", "6.679"),
        ("Nº DE ATENDIMENTOS", "8.788"),
        ("% META CUMPRIDA", "103,88%"),
        ("POPULAÇÃO IBGE 2022", "4.450.730"),
        ("% CASOS POR POPULAÇÃO", "0,15%"),
    ]
    for col, (label, valor) in zip([k1,k2,k3,k4,k5], kpis):
        col.markdown(f"""
        <div class="metric-card">
            <div class="metric-value">{valor}</div>
            <div class="metric-label">{label}</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("---")

    # Gráfico de barras horizontais — atendimentos por município
    df_med = load_mediacao_data()
    fig = px.bar(
        df_med.sort_values("atendimentos"),
        x="atendimentos", y="municipio",
        orientation="h",
        text="atendimentos",
        color_discrete_sequence=["#7CFC00"],
        title="PANORAMA ATENDIMENTOS POR MUNICÍPIOS",
    )
    fig.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700",
        xaxis=dict(showgrid=False, color="white"),
        yaxis=dict(color="white"),
        height=500,
    )
    fig.update_traces(textposition="outside", textfont_color="white")
    st.plotly_chart(fig, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 2 — VISÃO GERAL MEDIAÇÃO
# ─────────────────────────────────────────────────────────────────────────────
with tabs[1]:
    st.markdown("# MEDIAÇÃO — VISÃO GERAL")

    col_kpi1, _ = st.columns([1, 4])
    col_kpi1.markdown("""
    <div class="metric-card">
        <div class="metric-value">1.278</div>
        <div class="metric-label">Total Mediações</div>
    </div>""", unsafe_allow_html=True)

    st.markdown("### VISÃO GERAL CASOS DE MEDIAÇÃO")
    df_vg = load_visao_geral()

    c1, c2 = st.columns([2, 1])
    with c1:
        fig_vg = px.bar(
            df_vg.sort_values("casos"),
            x="casos", y="municipio", orientation="h",
            text="casos", color_discrete_sequence=["#1F77B4"],
            title="Casos por Município"
        )
        fig_vg.update_layout(
            plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
            font_color="white", title_font_color="#FFD700", height=450
        )
        st.plotly_chart(fig_vg, use_container_width=True)

    with c2:
        df_status = load_status_data()
        fig_pizza = px.pie(
            df_status, values="quantidade", names="status",
            title="STATUS",
            color_discrete_sequence=["#2196F3","#F44336","#FFEB3B","#4CAF50"]
        )
        fig_pizza.update_layout(
            plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
            font_color="white", title_font_color="#FFD700"
        )
        st.plotly_chart(fig_pizza, use_container_width=True)

    # Tipos de conflito
    df_conf = load_conflitos_data()
    fig_conf = px.bar(
        df_conf.sort_values("quantidade"),
        x="quantidade", y="tipo", orientation="h",
        text="quantidade", color_discrete_sequence=["#1F77B4"],
        title="TIPOS DE CONFLITOS"
    )
    fig_conf.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700"
    )
    st.plotly_chart(fig_conf, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 3 — JPC PANORAMA ATENDIMENTOS
# ─────────────────────────────────────────────────────────────────────────────
with tabs[2]:
    st.markdown("# JUNTOS PELA CIDADANIA — Panorama")
    st.caption("31 de Agosto 2024 a 12 de Março 2026")

    j1, j2 = st.columns(2)
    j1.markdown("""<div class="metric-card">
        <div class="metric-value">32.927</div>
        <div class="metric-label">Total Atendimentos</div>
    </div>""", unsafe_allow_html=True)
    j2.markdown("""<div class="metric-card">
        <div class="metric-value">20.102</div>
        <div class="metric-label">Total Divulgações</div>
    </div>""", unsafe_allow_html=True)

    df_jpc = load_jpc_timeline()
    fig_jpc = go.Figure()
    fig_jpc.add_trace(go.Bar(
        name="Atendimentos", x=df_jpc["municipio"],
        y=df_jpc["atendimentos"], marker_color="#4CAF50"
    ))
    fig_jpc.add_trace(go.Bar(
        name="Divulgações", x=df_jpc["municipio"],
        y=df_jpc["divulgacoes"], marker_color="#2196F3"
    ))
    fig_jpc.update_layout(
        barmode="group", title="PANORAMA GERAL DE ATENDIMENTOS",
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700",
        legend=dict(bgcolor="#001f4d", font_color="white")
    )
    st.plotly_chart(fig_jpc, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 4 — JPC POR NATUREZA (barras empilhadas)
# ─────────────────────────────────────────────────────────────────────────────
with tabs[3]:
    st.markdown("# JPC — ATENDIMENTOS POR NATUREZA")
    natureza_data = pd.DataFrame({
        "municipio": ["RECIFE","SAO LOURENCO DA MATA","PETROLINA",
                      "JABOATAO DOS GUARARAPES","CARUARU","PAULISTA",
                      "CABO DE SANTO AGOSTINHO","VICENCIA","OURICURI","BONITO"],
        "ESTADUAL":  [443,265,311,461,675,681,289,340,174,180],
        "MUNICIPAL": [3739,1459,1508,1965,2172,1996,1607,1670,1298,1097],
        "FEDERAL":   [0,0,0,0,0,0,0,0,0,0],
        "PRIVADO":   [667,13,238,0,0,0,0,0,0,0],
    })
    fig_nat = go.Figure()
    cores = {"ESTADUAL":"#4CAF50","MUNICIPAL":"#2196F3","FEDERAL":"#FF9800","PRIVADO":"#FFEB3B"}
    for col, cor in cores.items():
        fig_nat.add_trace(go.Bar(name=col, x=natureza_data["municipio"],
                                  y=natureza_data[col], marker_color=cor))
    fig_nat.update_layout(
        barmode="stack", title="ATENDIMENTOS POR NATUREZA",
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700",
        legend=dict(bgcolor="#001f4d", font_color="white")
    )
    st.plotly_chart(fig_nat, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 5 — JPC POR SECRETARIA ESTADUAL
# ─────────────────────────────────────────────────────────────────────────────
with tabs[4]:
    st.markdown("# JPC — ATENDIMENTO POR SECRETARIA ESTADUAL")
    st.info("Dados por secretaria estadual: SAD, SAS, SCJ, SDAPP, SDS, SEC. DA CRIANÇA E JUVENTUDE, etc.")
    sec_data = pd.DataFrame({
        "secretaria": ["SAD","SDS","SCJ","SDAPP","SAS"],
        "atendimentos": [675, 688, 457, 434, 300],
        "divulgacoes": [1000, 1500, 1400, 900, 656]
    })
    fig_sec = px.bar(sec_data, x="secretaria", y=["atendimentos","divulgacoes"],
                     barmode="stack", title="Por Secretaria Estadual",
                     color_discrete_sequence=["#4CAF50","#FF69B4"])
    fig_sec.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700"
    )
    st.plotly_chart(fig_sec, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 6 — NEPS EM AÇÃO
# ─────────────────────────────────────────────────────────────────────────────
with tabs[5]:
    st.markdown("# NEPS EM AÇÃO")
    st.caption("19 de Março 2025 a 15 de Abril 2026")

    n1, n2 = st.columns(2)
    n1.markdown("""<div class="metric-card">
        <div class="metric-value">4.112</div>
        <div class="metric-label">Total Atendimentos</div>
    </div>""", unsafe_allow_html=True)
    n2.markdown("""<div class="metric-card">
        <div class="metric-value">3.612</div>
        <div class="metric-label">Total Divulgações</div>
    </div>""", unsafe_allow_html=True)

    neps_serv = pd.DataFrame({
        "servico": ["CERTIDAO DE NASCIMENTO","DISTRIBUICAO DE PRESERVATIVOS",
                    "AFERICAO DE PRESSAO","TESTE DE GLICEMIA",
                    "AGENDAMENTO EMISSAO DE RG","VACINA ANTIRRABICA"],
        "qtd": [475, 415, 312, 205, 200, 176]
    })
    fig_neps = px.bar(
        neps_serv.sort_values("qtd"), x="qtd", y="servico",
        orientation="h", text="qtd",
        color_discrete_sequence=["#FF4500"],
        title="ATENDIMENTO SERVIÇOS NEPS"
    )
    fig_neps.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700"
    )
    st.plotly_chart(fig_neps, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 7 — MVI PERNAMBUCO
# ─────────────────────────────────────────────────────────────────────────────
with tabs[6]:
    st.markdown("# MVI PERNAMBUCO")
    st.caption("01 de Janeiro 2025 a 06 de Maio de 2026")

    m1, m2, m3, m4, m5 = st.columns(5)
    mvi_kpis = [
        ("MVI CONSUMADO","4.127","#006400"),
        ("% TENTADO","0,05%","#228B22"),
        ("POPULAÇÃO IBGE 2022","9.032.351","#1F77B4"),
        ("MVI TENTADO %","0,03%","#8B0000"),
        ("MVI TENTADO","2.853","#8B0000"),
    ]
    for col, (lab, val, cor) in zip([m1,m2,m3,m4,m5], mvi_kpis):
        col.markdown(f"""<div style="background:{cor};border-radius:8px;
            padding:12px;text-align:center;">
            <div style="font-size:1.6rem;font-weight:bold;color:#FFD700">{val}</div>
            <div style="font-size:0.75rem;color:white">{lab}</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("### PERFIL OCORRÊNCIAS")
    pc1, pc2 = st.columns(2)
    mvi = load_mvi_data()

    with pc1:
        df_mot = pd.DataFrame({
            "motivacao": list(mvi["motivacao_consumado"].keys()),
            "qtd": list(mvi["motivacao_consumado"].values())
        })
        fig_mot = px.pie(df_mot, values="qtd", names="motivacao",
                         title="Motivação Geral — Consumado",
                         color_discrete_sequence=px.colors.qualitative.Set3)
        fig_mot.update_layout(
            plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
            font_color="white", title_font_color="#FFD700"
        )
        st.plotly_chart(fig_mot, use_container_width=True)

    with pc2:
        df_dia = pd.DataFrame({
            "dia": list(mvi["dia_semana_consumado"].keys()),
            "qtd": list(mvi["dia_semana_consumado"].values())
        })
        fig_dia = px.pie(df_dia, values="qtd", names="dia",
                         title="Dia da Semana — Consumado",
                         color_discrete_sequence=px.colors.qualitative.Pastel)
        fig_dia.update_layout(
            plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
            font_color="white", title_font_color="#FFD700"
        )
        st.plotly_chart(fig_dia, use_container_width=True)

# ─────────────────────────────────────────────────────────────────────────────
# ABA 8 — MVI DETALHAMENTO
# ─────────────────────────────────────────────────────────────────────────────
with tabs[7]:
    st.markdown("# MVI — CONSUMADO DETALHAMENTO")

    mvi_mun = pd.DataFrame({
        "municipio": ["RECIFE","JABOATAO DOS GUARARAPES","PETROLINA",
                      "CABO DE SANTO AGOSTINHO","OLINDA","CARUARU",
                      "CAMARAGIBE","VITORIA DE SANTO ANTAO","BONITO"],
        "consumado": [736, 326, 258, 183, 160, 141, 78, 61, 38]
    })
    fig_mvi = px.bar(
        mvi_mun.sort_values("consumado"),
        x="consumado", y="municipio", orientation="h",
        text="consumado", color_discrete_sequence=["#4CAF50"],
        title="MVI Consumado por Município"
    )
    fig_mvi.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700", height=450
    )
    st.plotly_chart(fig_mvi, use_container_width=True)

    st.markdown("### Município por Mês")
    mvi_mes = pd.DataFrame({
        "mes": ["jan/25","fev/25","mar/25","abr/25","mai/25",
                "jun/25","jul/25","ago/25","set/25","out/25","nov/25","dez/25"],
        "consumado": [4,10,3,2,1,1,3,1,2,2,1,2]
    })
    fig_mes = px.bar(mvi_mes, x="mes", y="consumado",
                     color_discrete_sequence=["#1F77B4"],
                     title="Município Por Mês")
    fig_mes.update_layout(
        plot_bgcolor="#001f4d", paper_bgcolor="#001f4d",
        font_color="white", title_font_color="#FFD700"
    )
    st.plotly_chart(fig_mes, use_container_width=True)
```

---

### ▶️ Como executar

```bash
pip install streamlit plotly pandas openpyxl
streamlit run dashboard_pernambuco.py
```

---

### 📌 Próximos passos recomendados

1. **Conectar à fonte de dados real** — substituir os `@st.cache_data` por consultas ao banco de dados ou arquivos Excel/CSV do TJPE/SEDS-PE.
2. **Filtros dinâmicos funcionais** — os selects de Região/Município já estão no sidebar, basta filtrar os DataFrames com base neles.
3. **Filtro de datas** — aplicar `df[df['data'].between(data_inicio, data_fim)]` nos carregamentos.
4. **Exportar para PDF/Excel** — adicionar botão `st.download_button` com os DataFrames.
5. **Deploy** — hospedar no **Streamlit Community Cloud** (gratuito) ou **Azure/AWS** para acesso público, mantendo o padrão do Governo de Pernambuco.
