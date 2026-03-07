
from langchain_community.vectorstores.faiss import FAISS
from langchain_community.embeddings import SentenceTransformerEmbeddings
from llama_cpp import Llama

llm = Llama(model_path="models/Bielik-11B-v3.0-Instruct.Q4_K_M.gguf")


embedder = SentenceTransformerEmbeddings(model_name="paraphrase-multilingual-MiniLM-L12-v2")


docs = [
    "RAG (Retrieval-Augmented Generation) łączy wyszukiwanie dokumentów z generowaniem tekstu.",
    "Bielik to polski model językowy oparty na architekturze LLaMA.",
    "FAISS to biblioteka do wyszukiwania podobnych wektorów."
]


vector_store = FAISS.from_texts(docs, embedder)


def rag_query(query):

    results = vector_store.similarity_search(query, k=2)
    context = " ".join([doc.page_content for doc in results])
    
    prompt = f"Na podstawie poniższego kontekstu odpowiedz po polsku:\n{context}\nPytanie: {query}\nOdpowiedź:"
    resp = llm(prompt, max_tokens=200)
    return resp["choices"][0]["text"]

question = "Jak się nazywasz?"
answer = rag_query(question)
print(answer)