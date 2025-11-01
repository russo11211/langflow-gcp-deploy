# 🔧 Troubleshooting - Cloud Build Trigger

Este documento lista os problemas comuns encontrados durante a configuração e como resolvê-los.

---

## ❌ Erro: Service Account Cannot Write Logs

**Mensagem de erro:**
```
The service account [...] does not have permission to write logs to Cloud Logging. 
To fix this, grant the Logs Writer (roles/logging.logWriter) role to the service account.
```

**Causa:** A conta de serviço usada pelo Cloud Build não tem permissão para escrever logs.

**Solução:**

Identifique qual conta de serviço está sendo usada (aparece no erro). Pode ser:
- `cloud-builds@PROJECT_ID.iam.gserviceaccount.com` (padrão)
- `replit@PROJECT_ID.iam.gserviceaccount.com` (ambiente replit)
- Outra conta customizada

Depois execute:

```bash
PROJECT_ID="clean-art-334716"
SERVICE_ACCOUNT="replit@${PROJECT_ID}.iam.gserviceaccount.com"  # Substitua conforme necessário

# Adicionar role de logging
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT} \
  --role=roles/logging.logWriter

# Adicionar roles necessárias para deploy
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT} \
  --role=roles/run.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT} \
  --role=roles/storage.admin
```

---

## ❌ Erro: Machine Type Not Available in Region

**Mensagem de erro:**
```
region does not allow N1 machine types: please use E2 variants
```

**Causa:** A região do Cloud Build não suporta máquinas `N1`. Diferentes regiões têm diferentes tipos disponíveis.

**Solução:**

Editar `cloudbuild.yaml` e alterar:

```yaml
# ❌ Errado
options:
  machineType: 'N1_HIGHCPU_8'

# ✅ Correto (para southamerica-east1)
options:
  machineType: 'E2_HIGHCPU_8'
```

**Tipos disponíveis por região:**
- `southamerica-east1`: E2 (E2_HIGHCPU_8, E2_STANDARD_8, etc.)
- `us-central1`: N1 ou E2
- `europe-west1`: N1 ou E2

Para verificar quais estão disponíveis em sua região:
```bash
gcloud builds list --format="value(substitutions._REGION)" | sort | uniq
```

---

## ❌ Erro: Invalid Substitution Variable

**Mensagem de erro:**
```
invalid value for 'build.substitutions': key in the template "CUSTOM_VAR" is not a valid built-in substitution
```

**Causa:** Você tentou usar uma variável customizada que não é reconhecida pelo Cloud Build.

**Solução:**

Cloud Build aceita apenas as seguintes substituições built-in (sem `_` prefixo):
- `$PROJECT_ID`
- `$BUILD_ID`
- `$COMMIT_SHA`
- `$BRANCH_NAME`
- `$BUILD_TIME`

Para variáveis customizadas, use o prefixo `_`:
```yaml
substitutions:
  _MY_VAR: 'my_value'

# Depois use como: ${_MY_VAR}
```

---

## ❌ Erro: Permission Denied on Cloud Run Deploy

**Mensagem de erro:**
```
ERROR: (gcloud.run.deploy) User [...] is not authorized to perform [...] on resource.
```

**Causa:** A conta de serviço do Cloud Build não tem `roles/run.admin`.

**Solução:**

```bash
PROJECT_ID="clean-art-334716"
SERVICE_ACCOUNT="replit@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:${SERVICE_ACCOUNT} \
  --role=roles/run.admin
```

---

## ❌ Erro: No Logs Found

**Mensagem:** "Nenhum registro foi encontrado para este build ou etapa."

**Causa:** Pode ser:
1. Permissão insuficiente para ver logs
2. Logs expiraram (Cloud Logging retém por 30 dias por padrão)
3. Build falhou antes de gerar logs

**Solução:**

1. Adicionar role `roles/logging.logWriter` (veja erro anterior)
2. Aumentar retenção de logs (se necessário):
   ```bash
   gcloud logging buckets update _Default \
     --retention-days=90
   ```
3. Verificar status do build:
   ```bash
   gcloud builds describe <BUILD_ID> --format="value(failureMessage)"
   ```

---

## ❌ Erro: Trigger Not Firing on Git Push

**Sintoma:** Você faz `git push`, mas o trigger não é acionado.

**Causa:**

1. Webhook GitHub não está registrado
2. Branch não corresponde ao padrão esperado
3. Arquivo `cloudbuild.yaml` não existe na raiz
4. Repositório não está conectado ao Cloud Build

**Solução:**

1. **Verificar webhook no GitHub:**
   - Settings → Webhooks → Procure por `cloud-build.googleapis.com`
   - Deve ter status verde (recentemente entregue)

2. **Verificar trigger no Cloud Build Console:**
   ```bash
   gcloud builds triggers list --format="table(name, filename, includedFiles)"
   ```

3. **Forçar trigger manual:**
   ```bash
   gcloud builds triggers run langflow-main-trigger --branch=main
   ```

4. **Reconectar repositório:**
   - Acesse: https://console.cloud.google.com/cloud-build/triggers
   - Clique em "Desconectar" e "Conectar repositório" novamente

---

## ❌ Erro: Build Timeout

**Mensagem:**
```
Timeout on step [X], timeout duration of 2400s exceeded
```

**Causa:** Build levou mais de 40 minutos (timeout padrão).

**Solução:**

Aumentar timeout em `cloudbuild.yaml`:

```yaml
# ❌ Padrão
timeout: '2400s'  # 40 minutos

# ✅ Aumentado
timeout: '3600s'  # 60 minutos
```

Ou otimizar o Dockerfile (cachear camadas melhor, instalar dependências mais rápido).

---

## ✅ Verificação de Saúde

Execute este script para diagnosticar o setup:

```bash
PROJECT_ID="clean-art-334716"
SERVICE_ACCOUNT="replit@${PROJECT_ID}.iam.gserviceaccount.com"

echo "=== Verificação de Setup ==="
echo ""

echo "1. Conta de Serviço Existe?"
gcloud iam service-accounts describe $SERVICE_ACCOUNT --project=$PROJECT_ID 2>&1 | grep "email:" || echo "❌ FALHA"

echo ""
echo "2. Roles Aplicadas:"
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT" \
  --format="table(bindings.role)"

echo ""
echo "3. Cloud Build API Habilitada?"
gcloud services list --enabled --filter="name:cloudbuild" --format="value(name)" | grep -q cloudbuild && echo "✅ SIM" || echo "❌ NÃO"

echo ""
echo "4. Cloud Run API Habilitada?"
gcloud services list --enabled --filter="name:run.googleapis.com" --format="value(name)" | grep -q run && echo "✅ SIM" || echo "❌ NÃO"

echo ""
echo "5. Cloud Build Triggers:"
gcloud builds triggers list --format="table(name, filename, includedFiles)"

echo ""
echo "6. Últimos Builds:"
gcloud builds list --limit=5 --format="table(id, status, startTime)"
```

---

## 📞 Recursos Adicionais

- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Cloud Build Troubleshooting](https://cloud.google.com/build/docs/troubleshooting)
- [Cloud Run Troubleshooting](https://cloud.google.com/run/docs/troubleshooting)
- [IAM Roles Reference](https://cloud.google.com/iam/docs/understanding-roles)

---

**Última atualização**: 2025-11-01
