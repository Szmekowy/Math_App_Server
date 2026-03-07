import requests

SERVER_URL = "http://localhost:5000"

def zapisz_wynik(username, temat, punkty, max_punkty):
    """Wysyła statystyki z konkretnej sesji do serwera."""
    print(f"Wysyłam statystyki dla gracza: {username}...")
    
    stats_text = f"Temat: {temat} | Wynik: {punkty}/{max_punkty} poprawnych odpowiedzi."
    
    payload = {
        "username": username,
        "stats": stats_text
    }
    
    response = requests.post(f"{SERVER_URL}/save_stats", json=payload)
    if response.status_code == 200:
        print("✅", response.json()["message"])
    else:
        print("❌ Błąd zapisu:", response.json())

def popros_llm_o_podsumowanie(username):
    """Pobiera od serwera (i LLM) podsumowanie postępów."""
    print(f"\nProszę LLM o analizę wyników dla: {username}...")
    
    response = requests.get(f"{SERVER_URL}/get_summary/{username}")
    
    if response.status_code == 200:
        dane = response.json()
        print("\n=== PODSUMOWANIE OD NAUCZYCIELA ===")
        print(dane["summary"])
        print("===================================")
    else:
        # Tu łapiemy błąd, jeśli użytkownika nie ma w bazie!
        print("❌ Błąd:", response.json().get("error", "Nieznany błąd"))

if __name__ == "__main__":
    # Symulujemy użytkownika. Zmień nick, żeby przetestować tworzenie nowego pliku!
    NICK = "Piotrek"
    
    # 1. Piotrek rozwiązuje test z matmy i wysyłamy jego wynik
    zapisz_wynik(NICK, "Matematyka - Równania i Ciągi", 4, 5)
    
    # 2. Piotrek rozwiązuje kolejny test za jakiś czas
    zapisz_wynik(NICK, "Matematyka - Prawdopodobieństwo", 2, 5)
    
    # 3. Pytamy LLM o podsumowanie postępów Piotrka
    #popros_llm_o_podsumowanie(NICK)
    
    # 4. A co jeśli zapytamy o kogoś, kogo nie ma?
    print("\n--- Testujemy brakującego użytkownika ---")
    popros_llm_o_podsumowanie("Widmo")