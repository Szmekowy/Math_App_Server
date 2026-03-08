
from langchain_community.vectorstores.faiss import FAISS
from langchain_community.embeddings import SentenceTransformerEmbeddings
from llama_cpp import Llama

llm = Llama(model_path="models/Bielik-11B-v3.0-Instruct.Q4_K_M.gguf",n_ctx=2048,verbose=False)


embedder = SentenceTransformerEmbeddings(model_name="paraphrase-multilingual-MiniLM-L12-v2")


docs =[]

with open("Dane/context.txt", "r") as f:
    for line in f:
        docs.append(line)



vector_store = FAISS.from_texts(docs, embedder)


def rag_query(prompt,query):

    print("Debug")
    results = vector_store.similarity_search(query, k=2)
    context = " ".join([doc.page_content for doc in results])
    
    prompt = f"{prompt}\n{context}\n{query}\nPodsumowanie:"
    resp = llm(prompt,
               max_tokens=500,
               temperature=0.7,
               stop=None,
               echo=False)
    return resp["choices"][0]["text"].strip()

