# Etapa 1: Use uma imagem base oficial do Python.
# A versão 'slim' é menor e ideal para produção.
FROM python:3.11-slim

# Etapa 2: Defina o diretório de trabalho dentro do contêiner.
WORKDIR /app

# Etapa 3: Defina variáveis de ambiente para otimizar a execução do Python.
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Etapa 4: Copie o arquivo de dependências primeiro.
# Isso permite que o Docker cacheie a camada de instalação.
COPY requirements.txt .

# Etapa 5: Instale as dependências.
# Esta camada será reutilizada em builds futuros se o requirements.txt não mudar.
RUN pip install --no-cache-dir -r requirements.txt

# Etapa 6: Copie o script de inicialização e o torne executável.
COPY startup.sh .
# Garante que o script tenha permissões de execução e corrige os finais de linha (CRLF do Windows para LF do Linux).
RUN apt-get update && apt-get install -y sed && sed -i 's/\r$//' startup.sh && chmod +x startup.sh

# Etapa 6b: Copie os flows e custom components para os diretórios padrão do Langflow
# O Langflow espera encontrá-los em ~/.langflow/flows e ~/.langflow/custom_components
# Como estamos rodando como root, ~ = /root
COPY flows /root/.langflow/flows
COPY custom_components /root/.langflow/custom_components

# Etapa 7: Exponha a porta que o Langflow usa.
EXPOSE 7860

# Etapa 8: Defina o comando para iniciar a aplicação usando o script.
CMD ["./startup.sh"]