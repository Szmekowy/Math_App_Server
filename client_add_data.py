import requests

# Adres naszego serwera
SERVER_URL = "http://localhost:5000/add_task"

# Nazwa nowego zbioru zadań
NAZWA_ZBIORU = "matma_poziom_2"

# Nasza paczka nowych zadań z matematyki
nowe_zadania = [
    {
        "tresc": "Rozwiąż równanie wykładnicze: 2^x = 16.",
        "odp_a": "4",
        "odp_b": "2",
        "odp_c": "8",
        "odp_d": "16",
        "opis": "Zapisujemy obie strony równania za pomocą tej samej podstawy. 16 to inaczej 2^4. Otrzymujemy 2^x = 2^4, więc x = 4."
    },
    {
        "tresc": "W ciągu geometrycznym pierwszy wyraz a_1 = 2, a iloraz q = 3. Oblicz trzeci wyraz tego ciągu (a_3).",
        "odp_a": "18",
        "odp_b": "12",
        "odp_c": "9",
        "odp_d": "6",
        "opis": "Wzór na n-ty wyraz ciągu geometrycznego to a_n = a_1 * q^(n-1). Podstawiając dane dla n=3: a_3 = 2 * 3^(3-1) = 2 * 3^2 = 2 * 9 = 18."
    },
    {
        "tresc": "Z urny, w której jest 5 kul białych i 3 czarne, losujemy jedną. Jakie jest prawdopodobieństwo wylosowania kuli czarnej?",
        "odp_a": "3/8",
        "odp_b": "5/8",
        "odp_c": "3/5",
        "odp_d": "1/8",
        "opis": "Zliczamy wszystkie kule (moc Omegi): 5 + 3 = 8. Kul czarnych jest 3 (zdarzenia sprzyjające). Z definicji prawdopodobieństwa dzielimy zdarzenia sprzyjające przez wszystkie możliwe: 3/8."
    },
    {
        "tresc": "Oblicz pochodną funkcji wielomianowej f(x) = 3x^2 - 5x + 2.",
        "odp_a": "6x - 5",
        "odp_b": "3x - 5",
        "odp_c": "6x",
        "odp_d": "x - 5",
        "opis": "Korzystamy ze wzoru na pochodną potęgi: (x^n)' = n*x^(n-1). Pochodna z 3x^2 to 2*3x^1 = 6x. Pochodna z -5x to -5. Pochodna ze stałej (2) to 0. Łącząc to, otrzymujemy 6x - 5."
    },
    {
        "tresc": "Kąt wpisany w okrąg jest oparty na tym samym łuku, co kąt środkowy o mierze 100 stopni. Jaką miarę ma kąt wpisany?",
        "odp_a": "50 stopni",
        "odp_b": "100 stopni",
        "odp_c": "200 stopni",
        "odp_d": "25 stopni",
        "opis": "Zgodnie z twierdzeniem o kątach w okręgu, miara kąta wpisanego jest zawsze równa połowie miary kąta środkowego opartego na tym samym łuku. Zatem 100 / 2 = 50 stopni."
    }
]

# Wysyłamy zadania jedno po drugim do serwera
print(f"Rozpoczynam wysyłanie zbioru '{NAZWA_ZBIORU}' do serwera...\n")

for i, zadanie in enumerate(nowe_zadania, 1):
    payload = {
        "filename": NAZWA_ZBIORU,
        "tresc": zadanie["tresc"],
        "odp_a": zadanie["odp_a"],
        "odp_b": zadanie["odp_b"],
        "odp_c": zadanie["odp_c"],
        "odp_d": zadanie["odp_d"],
        "opis": zadanie["opis"]
    }
    
    try:
        response = requests.post(SERVER_URL, json=payload)
        if response.status_code == 200:
            print(f"[{i}/{len(nowe_zadania)}] Dodano zadanie: {zadanie['tresc'][:30]}...")
        else:
            print(f"[{i}/{len(nowe_zadania)}] Błąd serwera: {response.json()}")
    except requests.exceptions.ConnectionError:
        print("Błąd: Nie można połączyć się z serwerem. Upewnij się, że app.py jest odpalony!")
        break

print("\nGotowe! Plik ze zbiorem został utworzony na serwerze.")