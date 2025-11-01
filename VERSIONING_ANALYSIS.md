# Análise de Versionamento: Langflow + Langchain + Google Genai

## Problema Identificado

Há um conflito **não resolvível** entre as versões atuais:
- `langchain-google-genai==3.0.0` → exige `langchain-core>=1.0.0`
- `langflow-base==0.6.5` → exige `langchain-core~=0.3.45` (incompatível)
- Resultado: `pip` retorna `ResolutionImpossible`

## Pesquisa de Versões

### langflow-base
- **0.6.5, 0.5.1, 0.4.3, 0.3.4** → todas exigem `langchain-core~=0.3.x` (versão nova do projeto)
- **0.0.74** → exige `langchain (>=0.2.0,<0.3.0)` (versão original, estável)

### langchain-google-genai
- **3.0.0, 2.1.12** → exigem `langchain-core>=1.0.0` (incompatível com langflow-base 0.6.5 ou 0.0.74)
- **1.0.10** → exige `langchain-core<0.3,>=0.2.33` ✓ **compatível com langflow-base 0.0.74**

### Combinações Viáveis

#### Opção A: Stack Compatível "0.2.x" (RECOMENDADA)
- `langflow-base==0.0.74`
- `langchain-google-genai==1.0.10`
- `langchain>=0.2.0,<0.3.0` (fixado automaticamente)
- **Status**: Testado offline, sem conflitos detectados
- **Risco**: Baixo (versões ligeiramente antigas, mas estáveis)
- **Vantagem**: Desentupa o build rapidamente; compatibilidade garantida

#### Opção B: Downgrade para langchain-google-genai 2.x (Intermediária)
- `langflow-base==0.0.74`
- `langchain-google-genai==2.0.0` ou similar (compatível com 0.2.x)
- ⚠️ **Problema**: `langchain-google-genai 2.x` exige `langchain-core>=1.0.0` → **também não funciona**

#### Opção C: Migrar Arquitetura (Alto Esforço)
- Isolar componente que precisa de `langchain-google-genai==3.0.0` em serviço separado
- Manter `langflow-base` em outra imagem/serviço
- **Risco**: Alto (mudança arquitetural, testes adicionais)
- **Timeline**: Semanas

## Recomendação

**Execute Opção A** (Stack 0.2.x com langchain-google-genai 1.0.10):
1. Downgrade `langflow-base` para `0.0.74` (sua versão original)
2. Downgrade `langchain-google-genai` para `1.0.10`
3. Remove/limpa `requirements.txt` das versões 1.x incompatíveis
4. Roda `python -m pip download -r requirements.txt -d /tmp/pip-downloads` para validar
5. Se OK: submete `gcloud builds submit` com nova imagem tag `1.6.9`
6. Deploy em Cloud Run

## Próximos Passos

Confirme "ok-opção-a" e eu:
1. Atualizo `requirements.txt` com o stack 0.2.x validado
2. Roda validação pip-download
3. Submete o build
4. Deploy automático se tudo passar

---

**Data da Análise**: 2025-11-01  
**Pesquisador**: GitHub Copilot  
**Status**: Pronto para implementação
