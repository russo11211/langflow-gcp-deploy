class EmbeddingsProviderError(Exception):
    '''Erro lançado quando o provedor de embeddings não está disponível.'''
    def __init__(self, message: str = '', *args, **kwargs):
        super().__init__(message)
