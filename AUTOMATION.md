# Automação: build e deploy

Este arquivo descreve os artefatos de automação adicionados ao repositório e como usá-los.

1) scripts/setup_gcloud.sh
  - Instala (se necessário) o Google Cloud SDK, inicia o fluxo de autenticação e define projeto/region.
  - Uso:

```bash
bash scripts/setup_gcloud.sh -p clean-art-334716 -r us-central1
```

2) scripts/build_and_deploy.sh
  - Automatiza o `gcloud builds submit` e o `gcloud run deploy` com argumentos.
  - Exemplo (tag 1.6.9):

```bash
bash scripts/build_and_deploy.sh -p clean-art-334716 -t 1.6.9 -r southamerica-east1 -s langflow
```

3) cloudbuild.yaml
  - Permite que você use o Cloud Build para executar build + push + deploy automaticamente.
  - Ao submeter com `gcloud builds submit --config cloudbuild.yaml --substitutions=_IMAGE_TAG=1.6.9`, o Cloud Build fará o deploy para a região e serviço definidos por substituições.

Exemplo de uso do cloudbuild.yaml:

```bash
# usando Cloud Build e substituições
gcloud builds submit --config cloudbuild.yaml --substitutions=_IMAGE_TAG=1.6.9
```

4) **Opção A: Cloud Build Trigger Automático (Recomendado para CI/CD contínuo)**

Este é o setup que permite que cada `git push` para `main` dispare automaticamente um novo build e deploy no Cloud Run.

#### 📋 Pré-requisitos

- Repositório GitHub conectado ao Google Cloud (ou GitLab, Bitbucket)
- Cloud Build API habilitada
- Conta de serviço do Cloud Build com permissões em Cloud Run

#### 🔧 Passos para Criar o Trigger

**Via Google Cloud Console (recomendado para primeira vez):**

1. Acesse: https://console.cloud.google.com/cloud-build/triggers
2. Clique em **"Criar acionador"** (Create Trigger)
3. Preencha:
   - **Nome**: `langflow-main-trigger`
   - **Evento**: Push em um branch
   - **Repositório**: Selecione seu repositório GitHub (ex: `russo11211/langflow-gcp-deploy`)
   - **Branch**: `^main$` (regex para branch main)
   - **Arquivo de build**: `cloudbuild.yaml`
   - **Substitutions** (opcional - pode deixar como padrão):
     - `_IMAGE_TAG`: `latest`
     - `_SERVICE`: `langflow`
     - `_REGION`: `southamerica-east1` (ou sua região)
     - `_PORT`: `7860`
     - `_MEMORY`: `2Gi`
4. Clique em **"Criar"**

**Via CLI (`gcloud` commands):**

```bash
# Certifique-se de estar no projeto correto
gcloud config set project clean-art-334716

# Crie o trigger (substitua com seu repositório)
gcloud builds triggers create github \
  --name langflow-main-trigger \
  --repo-name langflow-gcp-deploy \
  --repo-owner russo11211 \
  --branch-pattern "^main$" \
  --build-config cloudbuild.yaml \
  --substitutions=_IMAGE_TAG=latest,_SERVICE=langflow,_REGION=southamerica-east1,_PORT=7860,_MEMORY=2Gi
```

#### ✅ O que Acontece Agora

Toda vez que você executar:
```bash
git push origin main
```

Automaticamente:
1. ✅ GitHub notifica o Cloud Build Trigger
2. ✅ Cloud Build clona seu repositório
3. ✅ Cloud Build executa as etapas do `cloudbuild.yaml`:
   - Extrai commit ID (para versionamento)
   - Constrói imagem Docker
   - Envia para Container Registry
   - Faz deploy automático no Cloud Run
4. ✅ Seu serviço é atualizado com a nova versão

#### 📊 Monitorar Builds

```bash
# Ver histórico de builds
gcloud builds list --limit=10

# Ver logs de um build específico
gcloud builds log <BUILD_ID> --stream

# Ver triggers criados
gcloud builds triggers list
```

#### 🔄 Fluxo Completo (Exemplo)

```bash
# 1. Faça alterações no código/Dockerfile
echo "# Nova feature" >> README.md

# 2. Commit local
git add .
git commit -m "feat: new feature for langflow"

# 3. Push para GitHub
git push origin main

# 4. Cloud Build Trigger é disparado automaticamente
# (você verá no console ou por email se configurado)

# 5. Acompanhe o build
gcloud builds list --limit=5  # Ver builds recentes
gcloud builds log <BUILD_ID> --stream  # Ver logs em tempo real

# 6. Deploy está completo quando o build termina (status SUCCESS)
# Acesse: https://langflow-xv7bzkpaiq-rj.a.run.app (URL do seu serviço)
```

---

#### 🆘 Troubleshooting

- **Build falha com "Cloud Run API not enabled"**: 
  ```bash
  gcloud services enable run.googleapis.com
  ```

- **Deploy falha com permissão insuficiente**: 
  Verifique que a conta de serviço `cloud-builds@YOUR_PROJECT.iam.gserviceaccount.com` tem a role `roles/run.admin`:
  ```bash
  gcloud projects add-iam-policy-binding clean-art-334716 \
    --member=serviceAccount:cloud-builds@clean-art-334716.iam.gserviceaccount.com \
    --role=roles/run.admin
  ```

---

5) **Opção B: GitHub Actions (Alternativa lightweight)**

Se preferir CI/CD hospedado no GitHub sem depender de Cloud Build:

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy to Cloud Run

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
      
      - name: Build and deploy
        run: |
          gcloud builds submit --tag gcr.io/${{ secrets.GCP_PROJECT }}/langflow:${{ github.sha }} \
            --timeout=2400s \
            --substitutions=_IMAGE_TAG=${{ github.sha }}
```

Para usar isso, você precisa:
1. Criar uma chave de conta de serviço no GCP
2. Adicionar a chave como `GCP_SA_KEY` nos GitHub Secrets do repositório
3. Fazer push de `.github/workflows/deploy.yml` para seu repositório

---

#### 🎯 Recomendação

- **Para demo/dev rápido**: Use Option B (GitHub Actions) — menos setup
- **Para produção**: Use Option A (Cloud Build Trigger) — integração nativa, melhor auditoria

---

4) Próximos passos de automação possíveis (opcionais e recomendados):
  - Automatizar testes (lint, unit tests) antes do build da imagem.
  - Gerenciar segredos com Secret Manager e montar variáveis de ambiente no Cloud Run.
  - Configurar webhooks para notificações (Slack, email) ao final do build.
  - Usar Artifact Registry em vez de `gcr.io` para políticas de repositório mais modernas.
