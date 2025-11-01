# ⚙️ Cloud Build Trigger - Guia Prático

Este documento fornece um guia **passo a passo** para configurar um Cloud Build Trigger automático que faz rebuild e redeploy toda vez que você faz `git push` para `main`.

---

## 🎯 O que Vamos Fazer

```
GitHub (git push main)
    ↓
Cloud Build Trigger (detecta push)
    ↓
Cloud Build (executa cloudbuild.yaml)
    ├→ Build Docker image
    ├→ Push para gcr.io
    └→ Deploy automático no Cloud Run
    ↓
✅ Novo serviço online (sem comando manual)
```

---

## 📋 Pré-requisitos

- ✅ Repositório GitHub com este projeto (`langflow-gcp-deploy`)
- ✅ Google Cloud Project configurado (`clean-art-334716`)
- ✅ gcloud CLI instalado e autenticado
- ✅ Cloud Build API habilitada:
  ```bash
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable run.googleapis.com
  ```

---

## 🔧 Passo 1: Conectar GitHub ao Google Cloud

### Via Console GCP

1. Acesse: https://console.cloud.google.com/cloud-build/triggers
2. Se for a primeira vez, clique em **"Conectar repositório"** (Connect Repository)
3. Selecione **GitHub** como provedor
4. Clique em **"Autorizar Google Cloud Build"**
5. Você será redirecionado para GitHub — autorize a integração
6. Selecione seu repositório (`russo11211/langflow-gcp-deploy`)
7. Clique em **"Conectar"**

### ✅ Resultado

Você verá seu repositório listado em "Repositórios conectados".

---

## 🏗️ Passo 2: Criar o Cloud Build Trigger

### Via Console GCP (Recomendado)

1. Em https://console.cloud.google.com/cloud-build/triggers, clique em **"Criar acionador"** (Create Trigger)

2. Preencha os seguintes campos:

| Campo | Valor |
|-------|-------|
| **Nome** | `langflow-main-trigger` |
| **Descrição** | Rebuild e deploy automático ao fazer push em main |
| **Evento** | Push em um branch |
| **Repositório** | `russo11211/langflow-gcp-deploy` |
| **Branch** | `^main$` (regex exata para main) |
| **Arquivo de build** | `cloudbuild.yaml` |

3. **(Opcional) Substitutions** — adicione valores padrão:

```
_IMAGE_TAG = latest
_SERVICE = langflow
_REGION = southamerica-east1
_PORT = 7860
_MEMORY = 2Gi
```

4. Clique em **"Criar"**

### ✅ Resultado

Trigger criado! Agora cada push para `main` dispara um build automático.

---

## 🌐 Passo 3: Configurar Permissões (Importante!)

Para que o Cloud Build consiga fazer deploy no Cloud Run, a conta de serviço precisa de permissões:

### 1. Criar a conta de serviço (se não existir)

```bash
PROJECT_ID="clean-art-334716"

gcloud iam service-accounts create cloud-builds \
  --project=$PROJECT_ID \
  --display-name="Cloud Build Service Account"
```

**Nota:** Se a conta já existe, você verá um erro — é normal, apenas pule para o passo 2.

### 2. Adicionar permissões à conta de serviço

```bash
PROJECT_ID="clean-art-334716"

# Role para fazer deploy no Cloud Run
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:cloud-builds@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/run.admin

# Role para acessar/enviar para Container Registry (GCR)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:cloud-builds@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/storage.admin
```

### 3. Verificar se foi aplicado

```bash
PROJECT_ID="clean-art-334716"

# Listar a conta de serviço
gcloud iam service-accounts list --filter="email:cloud-builds@*"

# Listar as roles aplicadas
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:cloud-builds@*"
```

### ✅ Resultado Esperado

```
DISPLAY NAME                 EMAIL                                                  DISABLED
Cloud Build Service Account  cloud-builds@clean-art-334716.iam.gserviceaccount.com  False

---

- members:
  - serviceAccount:cloud-builds@clean-art-334716.iam.gserviceaccount.com
  role: roles/run.admin

- members:
  - serviceAccount:cloud-builds@clean-art-334716.iam.gserviceaccount.com
  role: roles/storage.admin
```

---

## 🚀 Passo 4: Testar o Trigger

Agora vamos forçar um trigger manualmente para verificar que tudo funciona:

### Teste 1: Disparo Manual (via Console)

1. Em https://console.cloud.google.com/cloud-build/triggers
2. Clique no seu trigger `langflow-main-trigger`
3. Clique em **"Executar"** (Run)
4. Selecione `main` como branch
5. Clique em **"Executar compilação"** (Run build)

### Teste 2: Monitorar o Build

```bash
# Ver builds recentes
gcloud builds list --limit=5

# Ver logs em tempo real
gcloud builds log <BUILD_ID> --stream
```

### ✅ Resultado Esperado

- Status: `SUCCESS` (ou `QUEUED` → `RUNNING` → `SUCCESS`)
- Imagem: `gcr.io/clean-art-334716/langflow:latest` enviada
- Serviço: `langflow` no Cloud Run atualizado

---

## 🔄 Passo 5: Testar com Git Push

Agora vamos testar o fluxo completo (git push → auto build/deploy):

```bash
# 1. Faça uma pequena mudança
echo "# Trigger test" >> README.md

# 2. Commit e push
git add README.md
git commit -m "test: trigger cloud build automatically"
git push origin main

# 3. Observe o build no console
# (A página https://console.cloud.google.com/cloud-build/builds atualiza automaticamente)

# Ou via CLI:
sleep 5  # Aguarde 5s para o trigger processar
gcloud builds list --limit=1 --format="table(id, status, startTime)"

# Acompanhe os logs
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)") --stream
```

### ✅ Resultado

Ao terminar o build (status `SUCCESS`):
- Sua URL do Cloud Run está atualizada
- Acesse: https://langflow-xv7bzkpaiq-rj.a.run.app

---

## 📊 Monitoramento Contínuo

### Ver todos os builds

```bash
gcloud builds list --limit=20 --format="table(id, status, startTime, duration)"
```

### Ver logs de um build específico

```bash
gcloud builds log <BUILD_ID> --stream
```

### Filtrar por status

```bash
# Apenas builds com sucesso
gcloud builds list --filter="status=SUCCESS" --limit=10

# Apenas builds com falha
gcloud builds list --filter="status=FAILURE" --limit=10
```

### Webhook de Notificação (Opcional)

Configure notificações via Pub/Sub para Slack, email, etc.:

```bash
# Criar tópico Pub/Sub (um só)
gcloud pubsub topics create cloud-builds

# Criar subscription para enviar para Slack (usando Cloud Function)
# Ou integrar com ferramentas como:
# - Slack: Cloud Logging → Notification Channel → Slack
# - Email: Similar via Notification Channels
```

---

## 🆘 Troubleshooting

### Problema: Build falha com "Cloud Run API not enabled"

**Solução:**
```bash
gcloud services enable run.googleapis.com
```

### Problema: Deploy falha com "Permission denied"

**Causa**: Cloud Build Service Account não tem permissões.

**Solução:**
```bash
gcloud projects add-iam-policy-binding clean-art-334716 \
  --member=serviceAccount:cloud-builds@clean-art-334716.iam.gserviceaccount.com \
  --role=roles/run.admin
```

### Problema: Trigger não dispara ao fazer git push

**Verificações:**
1. Verifique que o branch está correto: `git branch -v` deve mostrar `* main`
2. Verifique que o repositório está conectado no Console
3. Verifique que o arquivo `cloudbuild.yaml` existe na raiz do repositório
4. Espere alguns minutos — às vezes há delay

**Debug:**
```bash
# Verificar que o webhook GitHub está registrado
# (No GitHub: Settings → Webhooks — deve ter entry para Cloud Build)

# Forçar um trigger manual para testar
gcloud builds triggers run langflow-main-trigger --branch=main
```

### Problema: Build constrói, mas deploy falha

**Verifique logs:**
```bash
gcloud builds log <BUILD_ID> --stream
```

**Comuns:**
- Porta incorreta no Cloud Run (`--port 7860` é o padrão, mas Dockerfile deve expor a mesma)
- Memória insuficiente (aumentar `_MEMORY` para `4Gi`)
- Timeout do Cloud Run muito curto (padrão 900s está ok)

---

## 🎯 Próximos Passos (Opcional)

### 1. Adicionar Testes Antes do Build

Editar `cloudbuild.yaml` para adicionar etapa de testes:

```yaml
# Etapa de testes (adicionar ANTES de "Build Docker image")
- name: 'python:3.11'
  id: 'Run tests'
  entrypoint: 'bash'
  args:
    - -c
    - |
      pip install -r requirements.txt
      # pytest tests/  (se houver testes)
```

### 2. Usar Artifact Registry em Vez de GCR

```yaml
# Em cloudbuild.yaml, substituir:
# gcr.io/$PROJECT_ID → us-docker.pkg.dev/$PROJECT_ID/langflow/langflow
```

### 3. Configurar Secrets Manager

Para variáveis sensíveis (API keys, etc.):

```bash
# Criar secret
echo -n "my-api-key-value" | gcloud secrets create LANGFLOW_API_KEY --data-file=-

# Usar no Cloud Run (via AUTOMATION.md ou cloudbuild.yaml)
gcloud run deploy langflow --update-secrets=LANGFLOW_API_KEY=LANGFLOW_API_KEY:latest
```

---

## 📌 Resumo

| Ação | Comando |
|------|---------|
| Ver triggers | `gcloud builds triggers list` |
| Executar trigger manual | `gcloud builds triggers run langflow-main-trigger --branch=main` |
| Ver builds recentes | `gcloud builds list --limit=10` |
| Ver logs de um build | `gcloud builds log <BUILD_ID> --stream` |
| Deletar trigger | `gcloud builds triggers delete langflow-main-trigger` |

---

**Pronto!** 🎉 Agora seu repositório está conectado e cada `git push` dispara um rebuild e redeploy automático.

Para mais detalhes, consulte:
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [AUTOMATION.md](./AUTOMATION.md) — visão geral de automação
