import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)


TASKS_DIR = "baza/zadania"
STATS_DIR = "baza/statystyki"

os.makedirs(TASKS_DIR, exist_ok=True)
os.makedirs(STATS_DIR, exist_ok=True)
# Konfiguracja lokalnego LLM (np. LM Studio na porcie 1234)
LLM_API_URL = "http://localhost:1234/v1/chat/completions"

def ask_local_llm(system_prompt, user_prompt):
    """Funkcja do gadania z lokalnym modelem na porcie 1234."""
    payload = {
        # W LM Studio nazwa modelu często nie ma znaczenia, ale można podać np. "local-model"
        "model": "local-model", 
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.7, # Możesz regulować "kreatywność" modelu (0.0 - 1.0)
        "stream": False
    }
    
    try:
        response = requests.post(LLM_API_URL, json=payload)
        response.raise_for_status()
        data = response.json()
        # Wyciągamy odpowiedź zgodnie ze standardem OpenAI
        return data["choices"][0]["message"]["content"]
    except requests.exceptions.RequestException as e:
        return f"Błąd komunikacji z lokalnym modelem (port 1234): {e}"

# 1. Pobieranie zbioru zadań przez klienta
@app.route('/get_tasks/<filename>', methods=['GET'])
def get_tasks(filename):
    filepath = os.path.join(TASKS_DIR, f"{filename}.txt")
    if not os.path.exists(filepath):
        return jsonify({"error": "Nie znaleziono takiego zbioru zadań."}), 404
        
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    return jsonify({"status": "success", "data": content})

# 2. Zapisywanie statystyk po rozwiązaniu zadań
@app.route('/save_stats', methods=['POST'])
def save_stats():
    data = request.json
    username = data.get("username", "nieznajomy")
    stats = data.get("stats") 
    
    filepath = os.path.join(STATS_DIR, f"{username}_stats.txt")
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"{stats}\n")
        
    return jsonify({"status": "success", "message": "Statystyki zapisane!"})

# 3. Podsumowanie postępów przez lokalny LLM
@app.route('/get_summary/<username>', methods=['GET'])
def get_summary(username):
    filepath = os.path.join(STATS_DIR, f"{username}_stats.txt")
    if not os.path.exists(filepath):
        return jsonify({"error": "Brak statystyk dla tego użytkownika."}), 404
        
    with open(filepath, "r", encoding="utf-8") as f:
        user_stats = f.read()
        
    system_prompt = "Jesteś wyrozumiałym nauczycielem matematyki. Zwracaj się bezpośrednio do ucznia w języku polskim."
    user_prompt = f"Oto historia wyników ucznia:\n{user_stats}\nNapisz krótkie, motywujące podsumowanie jego postępów. Wskaż mocne strony i to, nad czym musi popracować."
    
    summary = ask_local_llm(system_prompt, user_prompt)
    
    if summary.startswith("Błąd komunikacji"):
        return jsonify({"error": summary}), 500
        
    return jsonify({"status": "success", "summary": summary})

# 4. Tworzenie własnych plików z zadaniami
@app.route('/add_task', methods=['POST'])
def add_task():
    data = request.json
    
    # Pobieramy surowe dane od klienta
    filename = data.get("filename")
    tresc = data.get("tresc")
    odp_a = data.get("odp_a") # Z założenia to jest poprawna odpowiedź
    odp_b = data.get("odp_b")
    odp_c = data.get("odp_c")
    odp_d = data.get("odp_d")
    opis = data.get("opis")
    
    # Sprawdzamy, czy klient podał wszystko co trzeba
    if not all([filename, tresc, odp_a, odp_b, odp_c, odp_d, opis]):
        return jsonify({"error": "Brakuje danych! Musisz podać treść, 4 odpowiedzi i opis."}), 400
        
    # Serwer sam buduje blok tekstu w naszym sztywnym formacie
    nowe_zadanie = (
        "[ZADANIE]\n"
        f"TRESC: {tresc}\n"
        f"A: {odp_a}\n"
        f"B: {odp_b}\n"
        f"C: {odp_c}\n"
        f"D: {odp_d}\n"
        "POPRAWNA: A\n"
        f"OPIS: {opis}\n"
        "===\n"
    )
    
    # Dopisujemy to na koniec pliku (tryb 'a' - append)
    filepath = os.path.join(TASKS_DIR, f"{filename}.txt")
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(nowe_zadanie)
        
    return jsonify({"status": "success", "message": f"Dodano nowe zadanie do pliku {filename}.txt!"})
# 5. Prośba o pomoc w konkretnym zadaniu (tłumaczenie przez lokalny LLM)
@app.route('/ask_help', methods=['POST'])
def ask_help():
    data = request.json
    filename = data.get("filename")
    task_number = data.get("task_number")
    user_question = data.get("user_question")
    
    # Sprawdzamy, czy mamy wszystkie potrzebne dane
    if not filename or task_number is None or not user_question:
        return jsonify({"error": "Brakuje nazwy pliku, numeru zadania lub pytania."}), 400
        
    filepath = os.path.join(TASKS_DIR, f"{filename}.txt")
    
    # Sprawdzamy, czy plik istnieje
    if not os.path.exists(filepath):
        return jsonify({"error": "Nie znaleziono zbioru zadań o podanej nazwie."}), 404
        
    # Czytamy plik z zadaniami
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Dzielimy plik na poszczególne zadania za pomocą naszego separatora '==='
    # if t.strip() usuwa ewentualne puste bloki (np. po ostatnim '===')
    tasks = [t.strip() for t in content.split('===') if t.strip()]
    
    try:
        # Zakładamy, że klient numeruje zadania od 1 (1, 2, 3...)
        task_index = int(task_number) - 1
        
        # Sprawdzamy, czy numer zadania nie wykracza poza listę
        if task_index < 0 or task_index >= len(tasks):
            return jsonify({"error": f"Zadanie o numerze {task_number} nie istnieje w tym zbiorze."}), 400
            
        task_content = tasks[task_index]
        
    except ValueError:
        return jsonify({"error": "Numer zadania musi być liczbą całkowitą."}), 400
        
    # Budujemy prompty dla LLM
    system_prompt = "Jesteś cierpliwym korepetytorem. Odpowiadaj krótko i w języku polskim. Skup się tylko na pytaniu ucznia, nie rozwiązuj za niego całego zadania, naprowadzaj go."
    user_prompt = f"Zadanie i rozwiązanie:\n---\n{task_content}\n---\nUczeń nie rozumie i pyta: '{user_question}'. Odpowiedz tylko na to pytanie na poziomie liceum."
    
    # Pytamy lokalny model
    answer = ask_local_llm(system_prompt, user_prompt)
    
    if answer.startswith("Błąd komunikacji"):
        return jsonify({"error": answer}), 500
        
    return jsonify({
        "status": "success", 
        "task_number": task_number,
        "answer": answer
    })

if __name__ == '__main__':
    app.run(debug=True, port=5000)