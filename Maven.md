# Maven — Cheatsheet

Referência de comandos e configuração do Maven para projetos Java.

> **Instalação (macOS):** `brew install maven`

---

## 1. Comandos essenciais

```bash
mvn --version                    # Ver versão do Maven e Java em uso
mvn help:effective-pom           # Ver o POM completo com herança resolvida
mvn help:effective-settings      # Ver configurações ativas
```

---

## 2. Ciclo de vida (lifecycle)

O Maven possui três ciclos de vida. O mais usado é o `default`:

```
validate → compile → test → package → verify → install → deploy
```

```bash
mvn validate                     # Valida se o projeto está correto
mvn compile                      # Compila o código-fonte
mvn test                         # Executa os testes unitários
mvn package                      # Empacota (gera .jar ou .war)
mvn verify                       # Executa testes de integração e verifica pacote
mvn install                      # Instala o pacote no repositório local (~/.m2)
mvn deploy                       # Envia para repositório remoto (CI/CD)
```

> Cada fase executa todas as anteriores. `mvn package` também compila e testa.

---

## 3. Flags mais usadas

```bash
mvn package -DskipTests          # Empacotar sem rodar testes
mvn package -DskipTests=true     # Mesmo efeito
mvn test -Dtest=MinhaClasseTest  # Rodar apenas uma classe de teste
mvn test -Dtest=MinhaClasseTest#meuMetodo  # Rodar apenas um método

mvn install -U                   # Forçar atualização de dependências do remote
mvn dependency:resolve           # Baixar todas as dependências

mvn -pl modulo-a,modulo-b install    # Executar em módulos específicos (multi-módulo)
mvn -pl modulo-a -am install         # Incluir módulos dos quais depende (-am)

mvn -T 4 install                 # Build paralelo com 4 threads
mvn -T 1C install                # Build paralelo com 1 thread por CPU

mvn -q package                   # Modo silencioso (só erros)
mvn -X package                   # Modo debug (output completo)
mvn -e package                   # Mostrar stack trace de erros
```

---

## 4. Limpeza

```bash
mvn clean                        # Remove o diretório target/
mvn clean package                # Limpa e empacota (build fresh)
mvn clean install                # Limpa, empacota e instala no repositório local
mvn clean verify                 # Limpa e executa testes de integração
```

---

## 5. Dependências

```bash
mvn dependency:tree              # Exibir árvore de dependências
mvn dependency:tree -Dincludes=grupo:artefato  # Filtrar por dependência
mvn dependency:analyze           # Detectar dependências não usadas ou faltantes
mvn dependency:resolve           # Baixar dependências sem compilar
mvn dependency:resolve-sources   # Baixar fontes das dependências
mvn dependency:purge-local-repository  # Limpar cache local e re-baixar
```

---

## 6. Plugins úteis

```bash
# Spring Boot
mvn spring-boot:run              # Rodar aplicação Spring Boot
mvn spring-boot:build-image      # Gerar imagem Docker com Buildpacks

# Quarkus
mvn quarkus:dev                  # Modo dev com live reload

# Informações do projeto
mvn help:describe -Dplugin=compiler   # Ver detalhes de um plugin
mvn versions:display-dependency-updates  # Ver dependências com novas versões
mvn versions:display-plugin-updates     # Ver plugins com novas versões

# Geração de código
mvn generate-sources             # Executar geradores de código (JOOQ, Swagger, etc.)
```

---

## 7. Profiles

```bash
mvn package -Pprod               # Ativar profile "prod"
mvn package -Pprod,metrics       # Ativar múltiplos profiles
mvn package -P!dev               # Desativar profile "dev"
mvn help:active-profiles         # Ver profiles ativos
```

Definir profile no `pom.xml`:

```xml
<profiles>
    <profile>
        <id>prod</id>
        <properties>
            <spring.profiles.active>prod</spring.profiles.active>
        </properties>
        <activation>
            <activeByDefault>false</activeByDefault>
        </activation>
    </profile>
</profiles>
```

---

## 8. Wrapper (mvnw)

O Maven Wrapper (`mvnw`) garante que todos usem a mesma versão do Maven, sem precisar instalar.

```bash
./mvnw --version                 # Ver versão do wrapper
./mvnw clean install             # Usar wrapper no lugar do mvn global

# Gerar wrapper no projeto
mvn wrapper:wrapper
mvn wrapper:wrapper -Dmaven=3.9.6  # Versão específica
```

---

## 9. Estrutura do pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
             http://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <!-- Identidade do projeto -->
    <groupId>com.empresa</groupId>
    <artifactId>meu-projeto</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>   <!-- jar | war | pom -->

    <!-- Herdar configurações de um parent (ex: Spring Boot) -->
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.0</version>
    </parent>

    <!-- Propriedades -->
    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <!-- Dependências -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Apenas em testes -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <!-- Build -->
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```

---

## 10. Escopos de dependência

| Escopo | Compilação | Testes | Runtime | Empacotado |
|---|---|---|---|---|
| `compile` (padrão) | Sim | Sim | Sim | Sim |
| `provided` | Sim | Sim | Não | Não |
| `runtime` | Não | Sim | Sim | Sim |
| `test` | Não | Sim | Não | Não |
| `system` | Sim | Sim | Não | Não |

```xml
<!-- Exemplos de escopo -->
<dependency>
    <groupId>javax.servlet</groupId>
    <artifactId>javax.servlet-api</artifactId>
    <version>4.0.1</version>
    <scope>provided</scope>         <!-- Servidor provê em runtime -->
</dependency>

<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>          <!-- Não precisa em compilação -->
</dependency>
```

---

## 11. Repositório local e settings.xml

```bash
~/.m2/repository/                # Repositório local de dependências
~/.m2/settings.xml               # Configurações globais do Maven
```

Exemplo de `~/.m2/settings.xml` com repositório privado:

```xml
<settings>
    <servers>
        <server>
            <id>meu-nexus</id>
            <username>usuario</username>
            <password>senha</password>
        </server>
    </servers>

    <mirrors>
        <mirror>
            <id>meu-nexus</id>
            <mirrorOf>*</mirrorOf>
            <url>https://nexus.empresa.com/repository/maven-public/</url>
        </mirror>
    </mirrors>
</settings>
```

---

## 12. Projeto multi-módulo

```
meu-projeto/
├── pom.xml                  ← POM pai (packaging: pom)
├── core/
│   └── pom.xml
├── api/
│   └── pom.xml
└── web/
    └── pom.xml
```

POM pai:

```xml
<packaging>pom</packaging>

<modules>
    <module>core</module>
    <module>api</module>
    <module>web</module>
</modules>

<!-- Gerenciar versões centralmente -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.empresa</groupId>
            <artifactId>core</artifactId>
            <version>${project.version}</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

```bash
# Rodar em módulo específico
mvn -pl api clean package

# Rodar em módulo e suas dependências
mvn -pl web -am clean package

# Rodar em todos exceto um
mvn -pl '!web' clean install
```

---

## 13. Versionamento

```bash
# Ver versão atual
mvn help:evaluate -Dexpression=project.version -q -DforceStdout

# Atualizar versão
mvn versions:set -DnewVersion=2.0.0
mvn versions:set -DnewVersion=2.0.0-SNAPSHOT
mvn versions:commit                  # Confirmar mudança (remove backup)
mvn versions:revert                  # Reverter mudança

# Remover -SNAPSHOT para release
mvn versions:set -DremoveSnapshot=true
```

---

## 14. Troubleshooting

```bash
# Forçar re-download de dependências corrompidas
mvn clean install -U

# Limpar cache local completamente
rm -rf ~/.m2/repository

# Ver classpath de compilação
mvn dependency:build-classpath

# Resolver conflito de versões — ver qual versão está sendo usada
mvn dependency:tree -Dverbose -Dincludes=grupo:artefato

# Build ignorando falhas em módulos (multi-módulo)
mvn install --fail-at-end
```

### Erros comuns

| Erro | Causa provável | Solução |
|---|---|---|
| `Could not resolve dependencies` | Dependência não encontrada | Verificar `groupId`, `artifactId`, versão e repositório |
| `Compilation failure` | Erro no código | Verificar versão do Java (`java.version` no pom) |
| `Tests run: X, Failures: Y` | Teste falhando | Rodar `mvn test -Dtest=ClasseTest` para isolar |
| `BUILD FAILURE` sem mensagem clara | Erro silencioso | Adicionar `-e` ou `-X` para ver detalhes |
| `Artifact ... not found` no CI | Cache desatualizado | Rodar com `-U` para forçar atualização |
