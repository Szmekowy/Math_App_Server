import requests

BASE_URL = "http://127.0.0.1:5000"

username = "jan_kowalski"

zadania = [
    {"task_content": "Zadanie 1: Oblicz 2+2", "is_correct": True},
    {"task_content": "Zadanie 2: Rozwiąż równanie x^2=4", "is_correct": False},
    {"task_content": "Zadanie 3: Oblicz pole prostokąta 5x3", "is_correct": True}
]

# --- 1️⃣ Wysyłanie statystyk ---
for stat in zadania:

    # Tworzymy tekst statystyki zgodny z serwerem
    wynik = "poprawnie" if stat["is_correct"] else "błędnie"

    stats_text = f"{stat['task_content']} - rozwiązane {wynik}"

    response = requests.post(
        f"{BASE_URL}/save_stats",
        json={
            "username": username,
            "stats_text": stats_text
        }
    )

    if response.ok:
        print(f"Zapisano statystyki: {stats_text}")
    else:
        print("Błąd zapisu:", response.text)


# --- 2️⃣ Pobranie podsumowania od modelu RAG ---
response = requests.get(f"{BASE_URL}/get_summary/{username}")

if response.ok:
    summary = response.json()["summary"]

    print("\n=== Podsumowanie postępów ucznia ===")
    print(summary)

else:
    print("Błąd pobrania podsumowania:", response.text)