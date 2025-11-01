"""
Custom Embeddings Component for LangFlow
Compatible with: LangChain 0.2.x + LangFlow-base 0.0.74 + Google GenAI 1.0.x
"""

from langflow.custom import CustomComponent
from langchain.embeddings import SentenceTransformerEmbeddings
from typing import Any, Dict

# importa a exceção de outro módulo
from .errors import EmbeddingsProviderError


class OpenAIEmbeddingsComponent(CustomComponent):
    """Componente de embeddings customizado com fallback local."""

    def build_config(self) -> Dict[str, Any]:
        """Define os campos configuráveis do componente."""
        return {
            "model_name": {
                "type": "str",
                "value": "all-MiniLM-L6-v2",
                "description": "Modelo de embeddings a ser usado.",
            },
            "provider": {
                "type": "str",
                "value": "sentence-transformers",
                "description": "Provedor do embedding (ex: sentence-transformers).",
            },
        }

    def build(self, model_name: str, provider: str = "sentence-transformers"):
        """Cria o objeto de embeddings com o provedor especificado."""
        try:
            if provider == "sentence-transformers":
                if SentenceTransformerEmbeddings is None:
                    raise EmbeddingsProviderError(
                        "SentenceTransformerEmbeddings não encontrado. "
                        "Instale 'sentence-transformers' e 'langchain'."
                    )
                return SentenceTransformerEmbeddings(model_name=model_name)
            else:
                raise EmbeddingsProviderError(
                    f"Provedor '{provider}' não suportado neste componente."
                )
        except Exception as e:
            raise EmbeddingsProviderError(f"Erro ao inicializar embeddings: {e}")
