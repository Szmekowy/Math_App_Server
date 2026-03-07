import requests

# Adres Twojego lokalnego serwera Flask
BASE_URL = "http://127.0.0.1:5000"

# --- 1️⃣ Wysyłamy przykładowe statystyki ---
username = "jan_kowalski"
zadania = [
    {"task_content": "Zadanie 1: Oblicz 2+2", "is_correct": True},
    {"task_content": "Zadanie 2: Rozwiąż równanie x^2=4", "is_correct": False},
    {"task_content": "Zadanie 3: Oblicz pole prostokąta 5x3", "is_correct": True}
]

for stat in zadania:
    response = requests.post(f"{BASE_URL}/save_stats", json={
        "username": username,
        "task_content": stat["task_content"],
        "is_correct": stat["is_correct"]
    })
    if response.ok:
        print(f"Zapisano statystyki: {stat['task_content']}")
    else:
        print(f"Błąd zapisu: {response.json()}")

# --- 2️⃣ Pobranie podsumowania od modelu RAG ---
response = requests.get(f"{BASE_URL}/get_summary/{username}")

if response.ok:
    summary = response.json()["summary"]
    print("\n=== Podsumowanie postępów ucznia ===")
    print(summary)
else:
    print(f"Błąd pobrania podsumowania: {response.json()}")