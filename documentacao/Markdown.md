# Markdown — Cheatsheet

Referência de sintaxe Markdown para documentação, README, wikis e anotações.

> **Variantes:** Esta cheatsheet cobre o CommonMark + extensões do GitHub Flavored Markdown (GFM).

---

## 1. Títulos

```markdown
# H1 — Título principal
## H2 — Seção
### H3 — Subseção
#### H4
##### H5
###### H6
```

> Sempre deixe um espaço após o `#`. Deixe uma linha em branco antes e depois do título.

---

## 2. Formatação de texto

```markdown
**negrito**
__negrito__

*itálico*
_itálico_

***negrito e itálico***

~~tachado~~

`código inline`

> Citação (blockquote)

> Citação com
> múltiplas linhas
>
> E parágrafos separados
```

---

## 3. Listas

### Não ordenada

```markdown
- Item A
- Item B
  - Sub-item B1
  - Sub-item B2
- Item C
```

### Ordenada

```markdown
1. Primeiro
2. Segundo
3. Terceiro
   1. Sub-item
   2. Sub-item
```

### Lista de tarefas (GFM)

```markdown
- [x] Tarefa concluída
- [ ] Tarefa pendente
- [ ] Outra tarefa
```

---

## 4. Links

```markdown
[Texto do link](https://exemplo.com)

[Texto com título](https://exemplo.com "Título ao passar o mouse")

[Link por referência][id]

[id]: https://exemplo.com

<https://url-automatica.com>

[Link relativo](./outro-arquivo.md)

[Link para seção](#nome-da-seção)
```

---

## 5. Imagens

```markdown
![Texto alternativo](caminho/para/imagem.png)

![Alt com título](imagem.png "Título da imagem")

![Por referência][logo]

[logo]: https://exemplo.com/logo.png
```

> Para controlar tamanho, use HTML: `<img src="img.png" width="300" />`

---

## 6. Código

### Inline

```markdown
Use `npm install` para instalar dependências.
```

### Bloco com destaque de sintaxe

````markdown
```bash
npm install
npm run dev
```

```javascript
const soma = (a, b) => a + b;
```

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Olá");
    }
}
```
````

Linguagens comuns: `bash`, `javascript`, `typescript`, `python`, `java`, `go`, `sql`, `yaml`, `json`, `html`, `css`, `xml`, `markdown`

---

## 7. Tabelas (GFM)

```markdown
| Coluna A | Coluna B | Coluna C |
|---|---|---|
| Valor 1  | Valor 2  | Valor 3  |
| Valor 4  | Valor 5  | Valor 6  |
```

### Alinhamento

```markdown
| Esquerda | Centro | Direita |
|:---|:---:|---:|
| texto    | texto  |   texto |
```

---

## 8. Linha horizontal

```markdown
---

***

___
```

---

## 9. Quebra de linha e parágrafo

```markdown
Parágrafo 1.

Parágrafo 2. (linha em branco entre os dois)

Linha com quebra forçada
próxima linha (dois espaços no final da linha anterior)
```

---

## 10. HTML inline

```markdown
<br> — quebra de linha

<details>
  <summary>Clique para expandir</summary>

  Conteúdo oculto aqui.
</details>

<kbd>Ctrl</kbd> + <kbd>C</kbd>

<mark>texto destacado</mark>

<sub>subscrito</sub> e <sup>sobrescrito</sup>
```

---

## 11. Escape de caracteres

```markdown
\*sem itálico\*
\`sem código\`
\# sem título
\[sem link\]
\\ barra invertida literal
```

Caracteres que precisam de escape: `\ * _ [] () # + - . ! | { } ~`

---

## 12. Notas de rodapé (GFM)

```markdown
Texto com nota de rodapé.[^1]

Outra nota.[^nota-longa]

[^1]: Conteúdo da nota de rodapé.
[^nota-longa]: Nota com mais texto explicativo.
```

---

## 13. Alertas / Callouts (GitHub)

```markdown
> [!NOTE]
> Informação útil que o leitor deve saber.

> [!TIP]
> Dica opcional para facilitar o trabalho.

> [!IMPORTANT]
> Informação essencial para o sucesso.

> [!WARNING]
> Conteúdo crítico que exige atenção.

> [!CAUTION]
> Consequências negativas de uma ação.
```

---

## 14. Emojis (GFM)

```markdown
:rocket: :white_check_mark: :warning: :bulb: :fire: :hammer:
```

> Lista completa: [github.com/ikatyang/emoji-cheat-sheet](https://github.com/ikatyang/emoji-cheat-sheet)

---

## 15. Boas práticas

| Prática | Recomendação |
|---|---|
| Títulos | Um único `# H1` por arquivo |
| Linhas em branco | Sempre antes e depois de blocos (títulos, listas, código) |
| Comprimento de linha | Máximo 120 caracteres para legibilidade em diff |
| Links | Prefira referências nomeadas para URLs longas |
| Código | Sempre especifique a linguagem no bloco de código |
| Alt em imagens | Sempre preencha para acessibilidade |
