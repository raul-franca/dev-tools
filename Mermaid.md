# Mermaid — Cheatsheet

Referência de diagramas Mermaid: sintaxe para criar fluxogramas, sequências, entidades e mais em Markdown.

> **Uso:** Cole o código em qualquer ferramenta que suporte Mermaid (GitHub, Notion, GitLab, MkDocs, etc.) dentro de um bloco de código com a linguagem `mermaid`.

---

## 1. Fluxograma (Flowchart)

```mermaid
flowchart TD
    A[Início] --> B{Condição?}
    B -- Sim --> C[Processo A]
    B -- Não --> D[Processo B]
    C --> E[Fim]
    D --> E
```

### Direções

```
TB  → de cima para baixo (padrão)
TD  → igual a TB
BT  → de baixo para cima
LR  → da esquerda para a direita
RL  → da direita para a esquerda
```

### Formas de nó

```
A[Retângulo]
B(Retângulo arredondado)
C([Estádio / pílula])
D[[Subrotina]]
E[(Banco de dados)]
F((Círculo))
G{Losango — decisão}
H{{Hexágono}}
I[/Paralelogramo/]
J[\Paralelogramo invertido\]
```

### Tipos de seta

```
A --> B        # Seta simples
A --- B        # Linha sem seta
A --texto--> B # Seta com rótulo
A -.-> B       # Seta pontilhada
A ==> B        # Seta grossa
A --o B        # Seta com círculo
A --x B        # Seta com X
```

### Subgrafos

```mermaid
flowchart LR
    subgraph Backend
        A[API] --> B[(DB)]
    end
    subgraph Frontend
        C[React] --> A
    end
```

---

## 2. Diagrama de Sequência

```mermaid
sequenceDiagram
    participant C as Cliente
    participant S as Servidor
    participant DB as Banco

    C->>S: POST /login
    S->>DB: SELECT usuário
    DB-->>S: dados
    S-->>C: 200 OK + token
```

### Tipos de seta

```
->    # Linha sólida sem seta
-->   # Linha pontilhada sem seta
->>   # Linha sólida com seta
-->>  # Linha pontilhada com seta
-x    # Linha sólida com X (assíncrono)
--x   # Linha pontilhada com X
```

### Recursos

```mermaid
sequenceDiagram
    A->>B: Mensagem
    activate B
    Note over A,B: Nota nos dois
    B-->>A: Resposta
    deactivate B

    loop A cada 5s
        A->>B: Ping
    end

    alt Sucesso
        B-->>A: 200 OK
    else Erro
        B-->>A: 500 Error
    end
```

---

## 3. Diagrama de Classes (UML)

```mermaid
classDiagram
    class Animal {
        +String nome
        +int idade
        +fazerSom() String
    }

    class Cachorro {
        +String raca
        +latir() void
    }

    Animal <|-- Cachorro
```

### Relacionamentos

```
A <|-- B      # Herança (B extends A)
A *-- B       # Composição
A o-- B       # Agregação
A --> B       # Associação
A -- B        # Linha simples
A ..> B       # Dependência
A ..|> B      # Realização / implementação de interface
```

### Modificadores de visibilidade

```
+   público
-   privado
#   protegido
~   pacote
```

---

## 4. Diagrama de Entidade-Relacionamento (ER)

```mermaid
erDiagram
    USUARIO {
        int id PK
        string nome
        string email
    }
    PEDIDO {
        int id PK
        date criado_em
        int usuario_id FK
    }
    ITEM {
        int id PK
        string descricao
        decimal preco
        int pedido_id FK
    }

    USUARIO ||--o{ PEDIDO : "faz"
    PEDIDO ||--|{ ITEM : "contém"
```

### Cardinalidades

```
|o    # Zero ou um
||    # Exatamente um
}o    # Zero ou muitos
}|    # Um ou muitos
```

---

## 5. Diagrama de Estado

```mermaid
stateDiagram-v2
    [*] --> Inativo
    Inativo --> Ativo : login
    Ativo --> Processando : iniciar tarefa
    Processando --> Ativo : concluir
    Ativo --> Inativo : logout
    Processando --> Erro : falha
    Erro --> Ativo : recuperar
    Inativo --> [*]
```

---

## 6. Gráfico de Gantt

```mermaid
gantt
    title Cronograma do Projeto
    dateFormat YYYY-MM-DD

    section Backend
    API REST       :a1, 2024-01-01, 14d
    Banco de dados :a2, after a1, 7d

    section Frontend
    Telas          :b1, 2024-01-08, 10d
    Integração     :b2, after a2, 5d
```

---

## 7. Gráfico de Pizza

```mermaid
pie title Distribuição de bugs
    "Frontend" : 40
    "Backend"  : 35
    "Infra"    : 15
    "Outros"   : 10
```

---

## 8. Diagrama de Jornada do Usuário

```mermaid
journey
    title Compra no e-commerce
    section Descoberta
        Ver anúncio    : 3: Usuário
        Acessar site   : 4: Usuário
    section Compra
        Adicionar ao carrinho : 5: Usuário
        Finalizar pedido      : 3: Usuário, Sistema
    section Pós-compra
        Receber confirmação   : 5: Usuário, Sistema
```

---

## 9. Mindmap

```mermaid
mindmap
  root((Sistema))
    Backend
      API REST
      Banco de dados
      Cache
    Frontend
      React
      CSS
    Infraestrutura
      Docker
      CI/CD
```

---

## 10. Timeline

```mermaid
timeline
    title Histórico do projeto
    2022 : Início do desenvolvimento
         : Versão alfa
    2023 : Lançamento v1.0
         : Integração com parceiros
    2024 : Versão 2.0
         : App mobile
```

---

## 11. Estilos e temas

### Tema global

```
%%{init: {'theme': 'default'}}%%
```

Temas disponíveis: `default`, `dark`, `forest`, `neutral`, `base`

### Estilo de nó individual

```mermaid
flowchart LR
    A[Normal]
    B[Destaque]:::alerta

    classDef alerta fill:#f96,stroke:#333,color:#fff
```

### Estilo inline

```
style A fill:#bbf,stroke:#33f
```

---

## 12. Dicas de uso

| Dica | Detalhe |
|---|---|
| GitHub | Suportado nativamente em `.md` com bloco ` ```mermaid ` |
| VS Code | Extensão **Mermaid Preview** para visualizar em tempo real |
| CLI | `npm install -g @mermaid-js/mermaid-cli` → `mmdc -i diagrama.mmd -o saida.svg` |
| Playground | [mermaid.live](https://mermaid.live) para testar online |
| Comentários | Use `%%` para comentários no diagrama |
