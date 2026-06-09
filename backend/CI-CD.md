# CI/CD — GitLab CI e Jenkins

---

## Conceitos Gerais

| Termo | Descrição |
|---|---|
| **Pipeline** | Sequência automatizada de etapas (stages) |
| **Stage** | Fase do pipeline (build, test, deploy) |
| **Job** | Tarefa individual dentro de um stage |
| **Runner / Agent** | Máquina que executa os jobs |
| **Artifact** | Arquivo gerado por um job (jar, imagem, relatório) |
| **Trigger** | Evento que dispara o pipeline (push, merge request, tag) |

---

## GitLab CI

### Arquivo de configuração

```
.gitlab-ci.yml   # raiz do repositório
```

### Estrutura básica

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  script:
    - mvn package -DskipTests

test-job:
  stage: test
  script:
    - mvn test

deploy-job:
  stage: deploy
  script:
    - echo "Deploy em produção"
  only:
    - main
```

### Palavras-chave principais

| Chave | Descrição |
|---|---|
| `stages` | Define a ordem dos stages |
| `stage` | Stage ao qual o job pertence |
| `script` | Comandos executados pelo job |
| `image` | Imagem Docker usada no job |
| `before_script` | Comandos executados antes do `script` |
| `after_script` | Comandos executados após o `script` (mesmo com falha) |
| `only` / `except` | Controla quando o job executa (branches, tags) |
| `rules` | Condições avançadas para execução |
| `artifacts` | Arquivos preservados após o job |
| `cache` | Arquivos reutilizados entre jobs (ex: `.m2`, `node_modules`) |
| `needs` | Dependência direta entre jobs (DAG) |
| `environment` | Ambiente de deploy (staging, production) |
| `allow_failure` | Job pode falhar sem parar o pipeline |
| `when` | Quando executar: `on_success`, `on_failure`, `always`, `manual` |
| `variables` | Variáveis de ambiente do job |
| `extends` | Herda configuração de outro job |
| `parallel` | Executa N instâncias do job em paralelo |

### Imagens Docker por stack

```yaml
# Java
image: maven:3.9-eclipse-temurin-21

# Node.js
image: node:20-alpine

# Python
image: python:3.12-slim

# Docker-in-Docker
image: docker:24
services:
  - docker:24-dind
```

### Cache e Artifacts

```yaml
# Cache — reutilizar entre pipelines
cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .m2/repository
    - node_modules/

# Artifacts — passar arquivos entre stages
artifacts:
  paths:
    - target/*.jar
    - build/reports/
  expire_in: 1 week
  reports:
    junit: target/surefire-reports/*.xml
```

### Rules (substituição moderna de only/except)

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "main"'
    when: always
  - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    when: always
  - when: never
```

### Variáveis

```yaml
variables:
  APP_ENV: production
  MAVEN_OPTS: "-Xmx512m"

# Variáveis protegidas/secretas: Settings > CI/CD > Variables
# Acesso: $VARIABLE_NAME ou ${VARIABLE_NAME}
```

### Variáveis predefinidas úteis

| Variável | Valor |
|---|---|
| `$CI_COMMIT_BRANCH` | Branch atual |
| `$CI_COMMIT_SHA` | Hash do commit |
| `$CI_COMMIT_TAG` | Tag do commit (se houver) |
| `$CI_PROJECT_NAME` | Nome do projeto |
| `$CI_REGISTRY_IMAGE` | URL da imagem no GitLab Registry |
| `$CI_PIPELINE_SOURCE` | Origem: push, merge_request_event, schedule |
| `$CI_ENVIRONMENT_NAME` | Nome do ambiente de deploy |

### Build e push de imagem Docker

```yaml
build-image:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

### Deploy manual

```yaml
deploy-prod:
  stage: deploy
  script:
    - ./deploy.sh
  when: manual
  environment:
    name: production
    url: https://app.example.com
```

### Pipeline completo — Java/Maven

```yaml
stages:
  - build
  - test
  - package
  - deploy

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository"

cache:
  paths:
    - .m2/repository/

build:
  stage: build
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn compile

test:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn test
  artifacts:
    reports:
      junit: target/surefire-reports/*.xml

package:
  stage: package
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn package -DskipTests
  artifacts:
    paths:
      - target/*.jar
    expire_in: 1 day

deploy-staging:
  stage: deploy
  script:
    - scp target/*.jar user@staging:/opt/app/
    - ssh user@staging "systemctl restart app"
  environment:
    name: staging
  only:
    - develop

deploy-prod:
  stage: deploy
  script:
    - scp target/*.jar user@prod:/opt/app/
    - ssh user@prod "systemctl restart app"
  environment:
    name: production
  when: manual
  only:
    - main
```

### Runners

```bash
# Registrar runner
gitlab-runner register

# Listar runners registrados
gitlab-runner list

# Iniciar runner
gitlab-runner start

# Verificar status
gitlab-runner status

# Runner específico por tag no job
deploy-job:
  tags:
    - docker
    - production
```

---

## Jenkins

### Conceitos

| Termo | Descrição |
|---|---|
| **Jenkinsfile** | Arquivo de pipeline como código (Groovy) |
| **Stage** | Fase do pipeline |
| **Step** | Comando individual dentro de um stage |
| **Node / Agent** | Máquina que executa o pipeline |
| **Declarative** | Sintaxe estruturada (recomendada) |
| **Scripted** | Sintaxe Groovy pura (mais flexível) |

### Estrutura básica (Declarative)

```groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Deploy') {
            steps {
                sh './deploy.sh'
            }
        }
    }
}
```

### Diretivas principais

| Diretiva | Descrição |
|---|---|
| `agent` | Onde executar: `any`, `none`, `label`, `docker` |
| `stages` | Bloco que agrupa os stages |
| `stage('nome')` | Define uma etapa nomeada |
| `steps` | Comandos do stage |
| `environment` | Variáveis de ambiente |
| `options` | Configurações do pipeline (timeout, retry, etc.) |
| `parameters` | Parâmetros de entrada do build |
| `triggers` | Disparo automático (cron, upstream) |
| `post` | Ações após o pipeline (always, success, failure) |
| `when` | Condição para executar o stage |
| `parallel` | Stages em paralelo |
| `tools` | Ferramentas instaladas (maven, jdk) |

### Agent

```groovy
// Qualquer agente disponível
agent any

// Agente por label
agent { label 'linux' }

// Container Docker
agent {
    docker {
        image 'maven:3.9-eclipse-temurin-21'
        args '-v $HOME/.m2:/root/.m2'
    }
}

// Sem agente global (define por stage)
agent none
```

### Variáveis de ambiente

```groovy
environment {
    APP_NAME = 'minha-api'
    DEPLOY_ENV = 'staging'
    // Segredos via Credentials do Jenkins
    DB_PASSWORD = credentials('db-password-id')
}
```

### Variáveis predefinidas úteis

| Variável | Valor |
|---|---|
| `env.BUILD_NUMBER` | Número do build |
| `env.BUILD_ID` | ID do build |
| `env.JOB_NAME` | Nome do job |
| `env.GIT_BRANCH` | Branch atual |
| `env.GIT_COMMIT` | Hash do commit |
| `env.WORKSPACE` | Diretório de trabalho |
| `env.JENKINS_URL` | URL do Jenkins |

### Post (ações pós-pipeline)

```groovy
post {
    always {
        junit 'target/surefire-reports/*.xml'
        archiveArtifacts artifacts: 'target/*.jar'
    }
    success {
        echo 'Build concluído com sucesso!'
    }
    failure {
        mail to: 'team@empresa.com',
             subject: "FALHA: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
             body: "Veja: ${env.BUILD_URL}"
    }
    unstable {
        echo 'Testes com falha — build instável'
    }
}
```

### When (condições)

```groovy
stage('Deploy Prod') {
    when {
        branch 'main'
    }
    steps { ... }
}

stage('Deploy Staging') {
    when {
        anyOf {
            branch 'develop'
            branch 'release/*'
        }
    }
    steps { ... }
}

// Executar apenas se variável definida
when {
    expression { return params.DEPLOY == 'true' }
}
```

### Paralelo

```groovy
stage('Testes') {
    parallel {
        stage('Unit') {
            steps { sh 'mvn test -Dtest=Unit*' }
        }
        stage('Integration') {
            steps { sh 'mvn test -Dtest=Integration*' }
        }
    }
}
```

### Parâmetros de build

```groovy
parameters {
    string(name: 'VERSION', defaultValue: '1.0.0', description: 'Versão do artefato')
    booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Pular testes')
    choice(name: 'ENV', choices: ['staging', 'production'], description: 'Ambiente de deploy')
}

// Uso
sh "mvn package -Dversion=${params.VERSION}"
```

### Timeout e Retry

```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
    retry(2)
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
}

// Por step
steps {
    timeout(time: 5, unit: 'MINUTES') {
        sh './deploy.sh'
    }
    retry(3) {
        sh 'curl -f http://app/health'
    }
}
```

### Triggers

```groovy
triggers {
    // Cron
    cron('H 2 * * 1-5')

    // Poll SCM (verifica mudanças no repo)
    pollSCM('H/5 * * * *')

    // Upstream (dispara quando outro job termina)
    upstream(upstreamProjects: 'build-job', threshold: hudson.model.Result.SUCCESS)
}
```

### Pipeline completo — Java/Maven

```groovy
pipeline {
    agent {
        docker {
            image 'maven:3.9-eclipse-temurin-21'
            args '-v $HOME/.m2:/root/.m2'
        }
    }

    environment {
        APP_NAME = 'minha-api'
        ARTIFACT = "target/${APP_NAME}.jar"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar'
            }
        }

        stage('Deploy Staging') {
            when { branch 'develop' }
            steps {
                sh "scp ${ARTIFACT} user@staging:/opt/app/"
                sh 'ssh user@staging "systemctl restart app"'
            }
        }

        stage('Deploy Prod') {
            when { branch 'main' }
            input {
                message 'Fazer deploy em produção?'
                ok 'Confirmar'
            }
            steps {
                sh "scp ${ARTIFACT} user@prod:/opt/app/"
                sh 'ssh user@prod "systemctl restart app"'
            }
        }
    }

    post {
        success {
            echo "Deploy concluído: ${env.BUILD_URL}"
        }
        failure {
            echo "Falha no build #${env.BUILD_NUMBER}"
        }
    }
}
```

### Comandos úteis (CLI Jenkins)

```bash
# Baixar Jenkins CLI
curl -O http://localhost:8080/jnlpJars/jenkins-cli.jar

# Listar jobs
java -jar jenkins-cli.jar -s http://localhost:8080 list-jobs

# Disparar build
java -jar jenkins-cli.jar -s http://localhost:8080 build meu-job

# Disparar com parâmetro
java -jar jenkins-cli.jar -s http://localhost:8080 build meu-job -p ENV=staging

# Ver log do último build
java -jar jenkins-cli.jar -s http://localhost:8080 console meu-job

# Reiniciar Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart
```

---

## Passo a Passo — GitLab CI

### 1. Criar o projeto no GitLab

Crie ou use um repositório existente em `gitlab.com` ou na sua instância self-hosted.

### 2. Instalar e registrar um Runner

```bash
# macOS (Homebrew)
brew install gitlab-runner
brew services start gitlab-runner

# Linux
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt install gitlab-runner
```

Registrar o runner no projeto:

```bash
gitlab-runner register
```

O comando vai pedir interativamente:

```
URL do GitLab:      https://gitlab.com/
Token de registro:  (Settings > CI/CD > Runners > New project runner)
Descrição:          meu-runner
Tags:               docker,linux
Executor:           docker
Imagem padrão:      alpine:latest
```

Verificar se está ativo:

```bash
gitlab-runner list
gitlab-runner verify
```

> Para projetos no GitLab.com, runners compartilhados já estão disponíveis — não precisa instalar um runner próprio para começar.

### 3. Criar o arquivo `.gitlab-ci.yml`

Na raiz do repositório, crie o arquivo:

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn compile

test:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  script:
    - mvn test

deploy:
  stage: deploy
  script:
    - echo "Deploy para $CI_ENVIRONMENT_NAME"
  environment:
    name: staging
  only:
    - main
```

### 4. Configurar variáveis secretas

Vá em **Settings > CI/CD > Variables** e adicione:

| Key | Valor | Flags |
|---|---|---|
| `SSH_PRIVATE_KEY` | chave privada | Protected, Masked |
| `DB_PASSWORD` | senha do banco | Masked |
| `DEPLOY_HOST` | IP do servidor | — |

Usar no pipeline:

```yaml
script:
  - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
  - ssh user@$DEPLOY_HOST "systemctl restart app"
```

### 5. Fazer push e acompanhar o pipeline

```bash
git add .gitlab-ci.yml
git commit -m "ci: adicionar pipeline GitLab CI"
git push origin main
```

Acompanhe em **CI/CD > Pipelines** no GitLab. Cada push dispara automaticamente.

### 6. Configurar deploy por ambiente

```yaml
# Settings > Environments (criados automaticamente pelo campo environment:)

deploy-staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.app.com
  only:
    - develop

deploy-prod:
  stage: deploy
  environment:
    name: production
    url: https://app.com
  when: manual        # requer clique manual na UI
  only:
    - main
```

### 7. Adicionar badge de status ao README

```markdown
[![pipeline status](https://gitlab.com/usuario/projeto/badges/main/pipeline.svg)](https://gitlab.com/usuario/projeto/-/pipelines)
```

---

## Passo a Passo — Jenkins

### 1. Instalar o Jenkins

**Via Docker (recomendado para dev):**

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk21
```

**Via Homebrew (macOS):**

```bash
brew install jenkins-lts
brew services start jenkins-lts
# Acesse: http://localhost:8080
```

**Via apt (Ubuntu/Debian):**

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install jenkins
sudo systemctl start jenkins
```

### 2. Configuração inicial (Setup Wizard)

```bash
# Pegar a senha inicial
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# ou
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

1. Acesse `http://localhost:8080`
2. Cole a senha inicial
3. Escolha **"Install suggested plugins"**
4. Crie o usuário admin
5. Confirme a URL do Jenkins

### 3. Instalar plugins essenciais

Vá em **Manage Jenkins > Plugins > Available plugins** e instale:

| Plugin | Para que serve |
|---|---|
| **Git** | Integração com repositórios Git |
| **Pipeline** | Suporte a Jenkinsfile (já incluso) |
| **Maven Integration** | Build com Maven |
| **Docker Pipeline** | Usar Docker no pipeline |
| **Blue Ocean** | Interface visual de pipelines |
| **SSH Agent** | Usar chaves SSH nos steps |
| **Credentials Binding** | Injetar secrets nos pipelines |

### 4. Configurar ferramentas (JDK e Maven)

Vá em **Manage Jenkins > Tools**:

**JDK:**
- Add JDK → Nome: `JDK21` → Install automatically → `temurin-21`

**Maven:**
- Add Maven → Nome: `Maven3` → Install automatically → versão `3.9.x`

Usar no Jenkinsfile:

```groovy
tools {
    jdk 'JDK21'
    maven 'Maven3'
}
```

### 5. Adicionar credenciais

Vá em **Manage Jenkins > Credentials > System > Global credentials > Add**:

| Tipo | Uso |
|---|---|
| **Username with password** | DockerHub, servidor SSH |
| **SSH Username with private key** | Deploy via SSH |
| **Secret text** | Tokens de API, senhas |
| **Secret file** | Arquivos de config (.env, keystore) |

Referenciar no Jenkinsfile:

```groovy
environment {
    DOCKER_CREDS = credentials('dockerhub-creds')   // user + pass
    SSH_KEY      = credentials('deploy-ssh-key')    // chave SSH
    API_TOKEN    = credentials('api-token')         // secret text
}
```

### 6. Criar o job Pipeline

1. **New Item** → nome do job → selecione **Pipeline** → OK
2. Em **Build Triggers**: marque **"Poll SCM"** com `H/5 * * * *` ou configure webhook
3. Em **Pipeline**: selecione **"Pipeline script from SCM"**
   - SCM: Git
   - Repository URL: `https://gitlab.com/usuario/repo.git`
   - Credentials: selecione as credenciais cadastradas
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Salve

### 7. Criar o Jenkinsfile no repositório

```groovy
// Jenkinsfile (raiz do repositório)
pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven3'
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Deploy') {
            when { branch 'main' }
            steps {
                sshagent(['deploy-ssh-key']) {
                    sh 'scp target/*.jar user@servidor:/opt/app/'
                    sh 'ssh user@servidor "systemctl restart app"'
                }
            }
        }
    }

    post {
        success { echo "Build #${env.BUILD_NUMBER} concluído" }
        failure { echo "Falha no build #${env.BUILD_NUMBER}" }
    }
}
```

```bash
git add Jenkinsfile
git commit -m "ci: adicionar Jenkinsfile"
git push origin main
```

### 8. Configurar Webhook (disparo automático)

No GitLab/GitHub, vá em **Settings > Webhooks > Add webhook**:

```
URL:     http://SEU_JENKINS:8080/github-webhook/
         http://SEU_JENKINS:8080/project/NOME_DO_JOB   (GitLab)
Trigger: Push events
```

No Jenkins, em **Build Triggers**, marque:
- GitLab: **"Build when a change is pushed to GitLab"**
- GitHub: **"GitHub hook trigger for GITScm polling"**

### 9. Disparar o primeiro build

Manualmente:

1. Acesse o job no Jenkins
2. Clique em **"Build Now"**
3. Clique no build `#1` → **Console Output** para ver os logs

Via CLI:

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:TOKEN build NOME_DO_JOB -s -v
```

---

## Comparativo GitLab CI vs Jenkins

| | GitLab CI | Jenkins |
|---|---|---|
| **Configuração** | `.gitlab-ci.yml` no repo | `Jenkinsfile` no repo ou UI |
| **Runners** | GitLab Runners (Docker, Shell, K8s) | Nodes/Agents |
| **Interface** | Integrada ao GitLab | Separada (porta 8080) |
| **Plugins** | Poucos, funcionalidade nativa | +1800 plugins disponíveis |
| **Curva de aprendizado** | Baixa | Média/Alta |
| **Self-hosted** | Sim (ou GitLab.com SaaS) | Sempre self-hosted |
| **Pipelines visuais** | Nativo | Requer plugin (Blue Ocean) |
| **Secrets** | CI/CD Variables (por projeto/grupo) | Credentials (Jenkins) |
| **Melhor para** | Projetos no GitLab, simplicidade | Flexibilidade máxima, legado |
