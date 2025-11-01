# Deploy do Langflow no Google Cloud Platform (GCP)

Este guia documenta o processo completo para fazer o deploy da aplicação [Langflow](https://github.com/langflow-ai/langflow) no Google Cloud Run, utilizando o Google Cloud Build para a construção da imagem Docker.

## Visão Geral

O objetivo deste projeto é encapsular o Langflow em uma imagem Docker e executá-lo como um serviço gerenciado e escalável no Google Cloud. O processo foi otimizado para superar desafios comuns de build, como timeouts e erros de inicialização no Cloud Run.

---

## Como Foi Feito: A Jornada do Deploy

Durante a implantação, enfrentamos e resolvemos três desafios principais:

1.  **Timeout no Build**: O `pip` gastava muito tempo tentando resolver o "inferno de dependências" do Langflow. A solução foi "travar" a versão exata de todas as dependências e sub-dependências em um arquivo `requirements.txt`, tornando a instalação muito mais rápida.

2.  **Falha na Inicialização do Contêiner**: Após o deploy, o Cloud Run não conseguia confirmar se a aplicação havia iniciado. A causa raiz era uma incompatibilidade entre o `nest_asyncio` (usado pelo Langflow) e o `uvloop` (padrão do servidor `uvicorn`).

3.  **Comando de Inicialização**: O `uvicorn` precisava ser chamado de uma maneira específica para encontrar a aplicação Langflow (padrão "application factory").

A solução definitiva foi usar um script `startup.sh` para forçar o `uvicorn` a usar o loop `asyncio` padrão do Python e chamar a função `setup_app` corretamente.

---

## Pré-requisitos

1.  **Google Cloud SDK**: A ferramenta de linha de comando `gcloud` deve estar instalada e configurada.
2.  **Projeto no GCP**: Um projeto ativo no Google Cloud com o faturamento habilitado.
3.  **APIs Habilitadas**: As APIs do Cloud Build, Artifact Registry e Cloud Run devem estar ativadas.
    ```bash
    gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com
    ```

---

## Estrutura do Projeto

A pasta de deploy (`GCP_langflow`) contém os seguintes arquivos essenciais:

- **`Dockerfile`**: Define as instruções para construir a imagem. Foi otimizado para copiar e instalar as dependências em uma camada separada, aproveitando o cache do Docker para builds futuros.
- **`requirements.txt`**: Lista completa e "travada" de todas as dependências, garantindo builds rápidos e reproduzíveis.
- **`startup.sh`**: Script de inicialização que executa o servidor `uvicorn` da maneira correta para o ambiente do Cloud Run.
- **`README.md`**: Este arquivo de documentação.

---

## Passos para o Deploy

Execute os comandos a seguir no seu terminal, a partir da raiz desta pasta do projeto.

### Passo 1: Configurar o Projeto

Defina o seu ID de projeto no `gcloud` para garantir que os comandos sejam executados no contexto correto.

```bash
# Substitua 'SEU_PROJECT_ID' pelo ID do seu projeto no GCP
gcloud config set project SEU_PROJECT_ID
```

### Passo 2: Construir a Imagem Docker com o Cloud Build

Este comando envia o código-fonte para o Cloud Build, que constrói a imagem e a armazena no Artifact Registry (`gcr.io`). Lembre-se de usar uma nova tag (ex: `1.0.1`) a cada novo build.

```bash
# Substitua 'SEU_PROJECT_ID' e use uma tag para a imagem (ex: 1.0.0)
# O comando deve ser executado a partir da pasta que contém este projeto.
gcloud builds submit --tag gcr.io/SEU_PROJECT_ID/langflow:1.0.0 --timeout=2400s .
```

**Análise dos parâmetros:**
- `--tag gcr.io/SEU_PROJECT_ID/langflow:1.0.0`: Nomeia a imagem. O formato `gcr.io/PROJECT_ID/NOME:TAG` é essencial.
- `--timeout=2400s`: **Parâmetro crucial**. Aumenta o tempo limite do build para 40 minutos. É necessário para o primeiro build, que instala todas as dependências. Builds subsequentes serão muito mais rápidos.
- `.`: O diretório atual que contém o `Dockerfile` e os outros arquivos.

### Passo 3: Fazer o Deploy no Cloud Run

Com a imagem construída, este comando a implanta como um serviço no Cloud Run. Use a mesma tag de imagem que você usou no passo anterior.
```bash
# Substitua 'SEU_PROJECT_ID' e 'SUA_REGIAO' (ex: us-central1).
# Use a mesma tag de imagem que você usou no passo anterior (ex: 1.0.0).
# O comando está em uma única linha para evitar erros de sintaxe no PowerShell.
gcloud run deploy langflow --image gcr.io/SEU_PROJECT_ID/langflow:1.0.0 --platform managed --region SUA_REGIAO --allow-unauthenticated --port 7860 --memory 2Gi --cpu-boost
```

**Análise dos parâmetros:**
- `langflow`: O nome do seu serviço no Cloud Run.
- `--image`: A imagem exata que você construiu no passo anterior.
- `--region`: A região do GCP para o deploy (ex: `us-central1`, `southamerica-east1`).
- `--allow-unauthenticated`: Permite acesso público. Para produção, considere uma opção mais segura.
- `--port 7860`: **Essencial**. Informa ao Cloud Run a porta que a aplicação expõe, conforme definido no `Dockerfile`.
- `--memory 2Gi`: **Recomendado**. Aloca 2 GiB de memória. O Langflow pode ser intensivo em memória; este é um bom ponto de partida.

---

## Primeiro Teste

1.  **Acesse a URL**: Após o deploy, o Cloud Run fornecerá uma URL pública (ex: `https://langflow-xxxx-uc.a.run.app`).
2.  **Verifique a Interface**: Abra a URL em seu navegador. A interface de login do Langflow deve ser exibida.
3.  **Crie uma conta e explore**: Crie sua primeira conta de administrador e comece a criar seus fluxos de IA.

Se a interface carregar, seu deploy foi um sucesso!

Próximos Passos: Como Organizar e Subir para o Git

1.  **Crie a nova pasta do projeto:**
    ```bash
    mkdir langflow-gcp-deploy
    cd langflow-gcp-deploy
    ```

2.  **Mova os arquivos essenciais:**
    Copie os arquivos `Dockerfile`, `README.md` (a versão que você criou e que agora está mais limpa), `requirements.txt` e `startup.sh` da sua pasta `GCP_langflow` para a nova pasta `langflow-gcp-deploy`.

3.  **Inicie o repositório Git:**
    Dentro da pasta `langflow-gcp-deploy`, execute os seguintes comandos:
    ```bash
    # Inicia o repositório local
    git init -b main
    
    # Adiciona todos os arquivos para o stage
    git add .
    
    # Cria o primeiro commit
    git commit -m "Initial commit: Langflow deployment files for GCP Cloud Run"
    ```

4.  **Envie para o GitHub (ou outro serviço Git):**
    a. Crie um novo repositório vazio no GitHub (ex: `langflow-gcp-deploy`).
    b. O GitHub fornecerá os comandos para conectar seu repositório local ao remoto. Eles serão parecidos com estes:
    ```bash
    # Substitua com a URL do seu repositório
    git remote add origin https://github.com/SEU_USUARIO/langflow-gcp-deploy.git
    
    # Envia os arquivos para o GitHub
    git push -u origin main
    ```

Pronto! Agora você tem um repositório limpo e focado, contendo apenas o necessário para replicar seu deploy de forma rápida e consistente.

    ## Documentação adicional

    Durante o processo de build e deploy criamos dois artefatos de suporte que documentam as decisões e o estado do deploy:

    - `VERSIONING_ANALYSIS.md` — análise detalhada de compatibilidade de versões e as decisões tomadas para resolver conflitos de dependências.
    - `DEPLOYMENT_COMPLETE.md` — resumo final do deploy, incluindo ID do build, imagem gerada e URL do serviço.

    Consulte esses arquivos para entender o raciocínio por trás do pin das dependências e para recuperar informações do deploy.

<!--
[PROMPT_SUGGESTION]Como posso automatizar o build e deploy com um arquivo `cloudbuild.yaml`?[/PROMPT_SUGGESTION]
[PROMPT_SUGGESTION]Quais são as melhores práticas de segurança para este serviço no Cloud Run?[/PROMPT_SUGGESTION]
-->
# Fixed E2 machine type
# Testing with correct permissions
