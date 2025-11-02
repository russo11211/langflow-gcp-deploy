# Guia: Flows e Custom Components no Langflow

## 📁 Estrutura de Pastas

```
langflow-gcp-deploy/
├── flows/                          # Flows exportados em formato JSON
│   ├── Dynamic Agent.json
│   ├── Hackathon_Master (1).json
│   ├── Hierarchical Tasks Agent.json
│   ├── LF Component Agent v0.4.json
│   ├── MAG_v0.1.json
│   └── SCL + Feauture concatenation.json
├── custom_components/              # Componentes customizados
│   ├── Component Maker Agent 2.0 v0.1.json
│   └── embeddings/
│       ├── __init__.py
│       ├── errors.py
│       └── openai_embeddings_component.py
├── Dockerfile
├── startup.sh
├── requirements.txt
└── ... outros arquivos
```

## 🔄 Como Funciona o Carregamento

### 1. **Dockerfile**
O `Dockerfile` foi atualizado para copiar os diretórios `flows/` e `custom_components/` para dentro do container:
```dockerfile
# Copiamos os diretórios diretamente para ~/.langflow
COPY flows /root/.langflow/flows
COPY custom_components /root/.langflow/custom_components
```

### 2. **startup.sh**
O script de inicialização configura variáveis de ambiente que o Langflow reconhece:
```bash
export LANGFLOW_CONFIG_DIR=/root/.langflow
export LANGFLOW_LOAD_FLOWS_PATH=/root/.langflow/flows
export LANGFLOW_COMPONENTS_PATH=/root/.langflow/custom_components
export LANGFLOW_SAVE_DB_IN_CONFIG_DIR=true
```

### 3. **Langflow Initialization**
Quando o Langflow inicia:
- ✅ Carrega todos os flows (`.json`) do diretório `/root/.langflow/flows`
- ✅ Carrega todos os custom components do diretório `/root/.langflow/custom_components`
- ✅ Os flows aparecem na UI, disponíveis para importação/execução
- ✅ Os componentes customizados aparecem na paleta de componentes

## 📝 Como Adicionar Flows

### Opção A: Localmente (antes do deploy)
1. Exporte seu flow do Langflow em formato JSON
2. Coloque o arquivo na pasta `flows/`
3. Faça commit e push
4. Rejeite a imagem Docker (Cloud Build) — a nova imagem conterá seus flows

### Opção B: Diretamente na UI (após deploy)
1. Acesse a URL do Langflow em Cloud Run
2. Crie ou importe flows na UI normalmente
3. **Nota:** Esses flows ficarão armazenados **dentro do container** e **serão perdidos** quando a instância reiniciar ou for redeployed
4. Para persistir, exporte-os como JSON e adicione à pasta `flows/` no repositório

## 📦 Como Adicionar Custom Components

### Python Modules (Recomendado)
Para componentes Python (como `embeddings/`):
1. Crie a estrutura: `custom_components/seu_modulo/__init__.py` + código
2. Certifique-se de que `__init__.py` importa as classes de componentes
3. Adicione qualquer dependência ao `requirements.txt` se necessário
4. Faça commit, push, e rejeite a imagem

### JSON Components
Você também pode ter componentes exportados como JSON (como `Component Maker Agent 2.0 v0.1.json`):
1. Coloque-os diretamente em `custom_components/`
2. O Langflow os reconhecerá durante a inicialização

## 🚀 Fluxo Completo de Atualização

```bash
# 1. Adicione seus flows/components localmente
cp seu_novo_flow.json flows/
cp -r seu_novo_componente custom_components/

# 2. Commit e push
git add flows/ custom_components/
git commit -m "Add new flows and custom components"
git push origin main

# 3. Cloud Build é automaticamente acionado (se configurado com trigger)
# - Constrói a imagem com os novos flows/components
# - Faz push para gcr.io
# - Deploy automático em Cloud Run (se configurado)

# 4. Acesse o Langflow em Cloud Run — seus flows/components estarão disponíveis
```

## ⚠️ Armazenamento Persistente

**Importante:** Por padrão, o Langflow em Cloud Run armazena dados (banco de dados, novos flows criados via UI) **dentro do container**. Isso significa:

- ✅ Flows importados durante o boot estão sempre disponíveis
- ❌ Flows criados via UI são perdidos quando a instância reinicia
- ❌ Alterações não são sincronizadas com o repositório Git

### Solução para Persistência:
Opções avançadas (fora do escopo atual):
1. **Usar Cloud Firestore** para armazenar estados e flows
2. **Usar Cloud Storage** + volume mounting
3. **Usar Cloud SQL** para banco de dados persistente do Langflow
4. **Git auto-commit** (se `GIT_TOKEN` estiver disponível, o `startup.sh` pode fazer pull automático)

Para o escopo atual, **recomenda-se atualizar flows via repositório Git** (adicionar JSON à pasta `flows/`, fazer push, redeployed).

## 📋 Checklist

- [x] Arquivos JSON em `flows/`
- [x] Custom components em `custom_components/`
- [x] Dockerfile copia ambas as pastas
- [x] `startup.sh` exporta variáveis `LANGFLOW_LOAD_FLOWS_PATH` e `LANGFLOW_COMPONENTS_PATH`
- [x] Cloud Build rejeita a imagem com as novas estruturas
- [ ] Acesse o Langflow e verifique se flows/components aparecem

## 🔗 Referências

- [Langflow GitHub](https://github.com/langflow-ai/langflow)
- [Documentação de Custom Components do Langflow](https://docs.langflow.org/)
- [Google Cloud Run Best Practices](https://cloud.google.com/run/docs/configuring/containers)
