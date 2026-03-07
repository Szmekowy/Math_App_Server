import os
from flask import Flask, request, jsonify

# Importujemy Twój gotowy moduł AI
from Answer_model import rag_query

app = Flask(__name__)

TASKS_DIR = "baza/zadania"
STATS_DIR = "baza/statystyki"

# Upewniamy się, że struktura katalogów istnieje
os.makedirs(TASKS_DIR, exist_ok=True)
os.makedirs(STATS_DIR, exist_ok=True)

# 1. Pobieranie zbioru zadań przez klienta
@app.route('/get_tasks/<filename>', methods=['GET'])
def get_tasks(filename):
    filepath = os.path.join(TASKS_DIR, f"{filename}.txt")
    if not os.path.exists(filepath):
        return jsonify({"error": "Nie znaleziono takiego zbioru zadań."}), 404
        
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    return jsonify({"status": "success", "data": content})

# 2. Zapisywanie statystyk po rozwiązaniu zadań (Uproszczone)
@app.route('/save_stats', methods=['POST'])
def save_stats():
    data = request.json
    username = data.get("username", "nieznajomy")
    stats_text = data.get("stats_text") # Klient przesyła tu gotowy tekst/zdanie ze statystykami
    
    # Zabezpieczenie, żeby klient nie przysłał pustych danych
    if not stats_text:
        return jsonify({"error": "Brakuje danych do zapisania (stats_text)."}), 400
        
    # Zapisujemy otrzymany tekst prosto do pliku użytkownika (dodajemy \n na końcu)
    filepath = os.path.join(STATS_DIR, f"{username}_stats.txt")
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"{stats_text}\n")
        
    return jsonify({"status": "success", "message": "Statystyki zapisane!"})

# 3. Podsumowanie postępów przez Twój model RAG
@app.route('/get_summary/<username>', methods=['GET'])
def get_summary(username):
    filepath = os.path.join(STATS_DIR, f"{username}_stats.txt")
    if not os.path.exists(filepath):
        return jsonify({"error": "Brak statystyk dla tego użytkownika."}), 404
        
    with open(filepath, "r", encoding="utf-8") as f:
        user_stats = f.read()
        
    # Składamy jeden mocny prompt dla Twojej funkcji rag_query
    prompt = """Jesteś wyrozumiałym nauczycielem matematyki. Pisz języku polskim.
Nie wymyślaj faktów,
Napisz krótkie, motywujące podsumowanie postępów ucznia. Wskaż mocne strony i to, nad czym musi popracować oraz jak to osiągnąć."""
    
    try:
        # Odpalamy Twoją funkcję z Answer_model.py (podałeś prompt i user_stats)
        summary = rag_query(prompt, user_stats)
        print(summary)
        return jsonify({"status": "success", "summary": summary})
    except Exception as e:
        return jsonify({"error": f"Błąd modelu RAG: {str(e)}"}), 500

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

# 5. Prośba o pomoc w konkretnym zadaniu przez Twój model RAG
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
        
    # Składamy kontekst w jeden prompt dla rag_query (możesz dopasować format, jeśli rag_query przyjmuje 2 argumenty jak wyżej)
    prompt = f"""Jesteś cierpliwym korepetytorem. Odpowiadaj krótko i w języku polskim. Skup się tylko na pytaniu ucznia, nie rozwiązuj za niego całego zadania, naprowadzaj go.
Zadanie i rozwiązanie:
---
{task_content}
---
Uczeń nie rozumie i pyta: '{user_question}'. Odpowiedz tylko na to pytanie na poziomie liceum."""
    
    try:
        # Odpalamy Twoją funkcję z Answer_model.py
        answer = rag_query(prompt)
        return jsonify({
            "status": "success", 
            "task_number": task_number,
            "answer": answer
        })
    except Exception as e:
        return jsonify({"error": f"Błąd modelu RAG: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)