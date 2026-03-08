import os
import re
import json
from datetime import datetime
from flask import Flask, request, jsonify

# Importujemy Twój gotowy moduł AI
from Answer_model import rag_query

app = Flask(__name__)

TASKS_DIR = "baza/zadania"
STATS_DIR = "baza/statystyki"
REPORTS_DIR = "baza/raporty"
GRAPHICS_DIR = "baza/grafiki"
# Upewniamy się, że struktura katalogów istnieje
os.makedirs(REPORTS_DIR,exist_ok=True)
os.makedirs(TASKS_DIR, exist_ok=True)
os.makedirs(STATS_DIR, exist_ok=True)
os.makedirs(GRAPHICS_DIR, exist_ok=True)

@app.route('/get_students', methods=['GET'])
def get_students():
    students = []
    for filename in os.listdir(STATS_DIR):
        if filename.endswith('_stats.txt'):
            students.append(filename[:-10])  # remove "_stats.txt"
        elif filename.endswith('_stat.txt'):
            students.append(filename[:-9])   # remove "_stat.txt"
    students = sorted(set(students), key=str.lower)
    return jsonify({"students": students})


def _stats_file_for_user(username):
    primary = os.path.join(STATS_DIR, f"{username}_stats.txt")
    legacy = os.path.join(STATS_DIR, f"{username}_stat.txt")
    if os.path.exists(primary):
        return primary
    if os.path.exists(legacy):
        return legacy
    return primary


def _notes_file_for_user(username):
    return os.path.join(REPORTS_DIR, f"{username}_notes.txt")


def _notes_log_file_for_user(username):
    return os.path.join(REPORTS_DIR, f"{username}_notes_log.jsonl")


def _report_json_file_for_user(username):
    return os.path.join(REPORTS_DIR, f"{username}_report.json")


def _reports_log_file_for_user(username):
    return os.path.join(REPORTS_DIR, f"{username}_reports_log.jsonl")


def _teacher_file(teacher_name):
    return os.path.join(GRAPHICS_DIR, f"{teacher_name}.txt")


def _read_schedule_entries(teacher_name):
    filepath = _teacher_file(teacher_name)
    if not os.path.exists(filepath):
        return None, filepath

    entries = []
    pattern = re.compile(r"^\[(\d{4}-\d{2}-\d{2})\]\s+\[(\d{1,2}:\d{2})\]\s+(.+)$")
    with open(filepath, "r", encoding="utf-8") as f:
        for idx, raw_line in enumerate(f.readlines()):
            line = raw_line.strip()
            if not line:
                continue
            match = pattern.match(line)
            if match:
                date, time, students = match.groups()
                entries.append({
                    "index": idx,
                    "date": date,
                    "time": time,
                    "students": students,
                    "line": line
                })
            else:
                entries.append({
                    "index": idx,
                    "date": "",
                    "time": "",
                    "students": "",
                    "line": line
                })
    return entries, filepath


def _write_schedule_entries(filepath, entries):
    lines = []
    for entry in entries:
        if entry.get("date") and entry.get("time"):
            lines.append(f"[{entry['date']}] [{entry['time']}] {entry['students']}")
        else:
            lines.append(entry.get("line", "").strip())
    with open(filepath, "w", encoding="utf-8") as f:
        for line in lines:
            if line:
                f.write(f"{line}\n")


def _load_notes_timeline(username):
    timeline = []
    log_path = _notes_log_file_for_user(username)
    if os.path.exists(log_path):
        with open(log_path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f.readlines()):
                line = line.strip()
                if not line:
                    continue
                try:
                    parsed = json.loads(line)
                    note_text = parsed.get("note", "").strip()
                    created_at = parsed.get("created_at", "")
                    if note_text:
                        timeline.append({
                            "type": "note",
                            "note_id": idx,
                            "created_at": created_at,
                            "content": note_text
                        })
                except json.JSONDecodeError:
                    continue
        return timeline

    # Fallback dla starego formatu notatki (jeden plik txt bez historii)
    legacy_path = _notes_file_for_user(username)
    if os.path.exists(legacy_path):
        with open(legacy_path, "r", encoding="utf-8") as f:
            note_text = f.read().strip()
        if note_text:
            created_at = datetime.fromtimestamp(os.path.getmtime(legacy_path)).isoformat(timespec="seconds")
            timeline.append({
                "type": "note",
                "created_at": created_at,
                "content": note_text
            })
    return timeline


def _append_report_log(username, created_at, summary):
    log_path = _reports_log_file_for_user(username)
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"created_at": created_at, "summary": summary}, ensure_ascii=False) + "\n")


def _load_reports_timeline(username):
    timeline = []
    reports_log_path = _reports_log_file_for_user(username)
    if os.path.exists(reports_log_path):
        with open(reports_log_path, "r", encoding="utf-8") as f:
            for line in f.readlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    parsed = json.loads(line)
                except json.JSONDecodeError:
                    continue
                summary = str(parsed.get("summary", "")).strip()
                created_at = str(parsed.get("created_at", "")).strip()
                if summary and created_at:
                    timeline.append({
                        "type": "report",
                        "created_at": created_at,
                        "content": summary
                    })
        return timeline

    # Fallback: pojedynczy raport (stary format), migrowany do logu.
    report_json_path = _report_json_file_for_user(username)
    report_txt_path = os.path.join(REPORTS_DIR, f"{username}_report.txt")
    summary = ""
    created_at = ""
    if os.path.exists(report_json_path):
        with open(report_json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        summary = str(data.get("summary", "")).strip()
        created_at = str(data.get("created_at", "")).strip()
    elif os.path.exists(report_txt_path):
        with open(report_txt_path, "r", encoding="utf-8") as f:
            summary = f.read().strip()
        created_at = datetime.fromtimestamp(os.path.getmtime(report_txt_path)).isoformat(timespec="seconds")

    if summary:
        if not created_at:
            created_at = datetime.now().isoformat(timespec="seconds")
        _append_report_log(username, created_at, summary)
        timeline.append({
            "type": "report",
            "created_at": created_at,
            "content": summary
        })
    return timeline


def _generate_report(username):
    filepath = _stats_file_for_user(username)
    if not os.path.exists(filepath):
        return None

    with open(filepath, "r", encoding="utf-8") as f:
        user_stats = f.read()

    prompt = """Napisz raport na temat progresu ucznia. Wypisz jakie rodzaje zadań wykonuje poprawnie a jakie błędnie. Nie zmyślaj faktów. Napisz sekcje Podsumowanie, Progres s, Mocne Strony, Miejsca do poprawy, Sugerowane zadania na przyszłość. Rozpisz się w każdej z sekcji"""
    summary = rag_query(prompt, user_stats)
    created_at = datetime.now().isoformat(timespec="seconds")

    # latest snapshot for compatibility
    report_path = os.path.join(REPORTS_DIR, f"{username}_report.txt")
    report_json_path = _report_json_file_for_user(username)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(summary)
    with open(report_json_path, "w", encoding="utf-8") as f:
        json.dump({"summary": summary, "created_at": created_at}, f, ensure_ascii=False, indent=2)

    _append_report_log(username, created_at, summary)
    return {"status": "success", "summary": summary, "created_at": created_at}


def _load_or_create_report(username):
    reports = _load_reports_timeline(username)
    if reports:
        latest = reports[-1]
        return {
            "status": "cached",
            "summary": latest.get("content", ""),
            "created_at": latest.get("created_at", "")
        }
    return None


@app.route('/get_teachers', methods=['GET'])
def get_teachers():
    teachers = [
        filename[:-4]
        for filename in os.listdir(GRAPHICS_DIR)
        if filename.endswith('.txt')
    ]
    teachers = sorted(set(teachers), key=str.lower)
    return jsonify({"teachers": teachers})


@app.route('/get_schedule/<teacher_name>', methods=['GET'])
def get_schedule(teacher_name):
    entries, _ = _read_schedule_entries(teacher_name)
    if entries is None:
        return jsonify({"error": "Brak harmonogramu dla nauczyciela."}), 404
    entries = sorted(entries, key=lambda x: (x["date"], x["time"], x["index"]))
    return jsonify({"teacher": teacher_name, "schedule": entries})


@app.route('/add_schedule_entry', methods=['POST'])
def add_schedule_entry():
    data = request.json or {}
    teacher_name = data.get("teacher_name")
    date = data.get("date")
    time = data.get("time")
    students = data.get("students")

    if not all([teacher_name, date, time, students]):
        return jsonify({"error": "Brak danych: teacher_name, date, time, students są wymagane."}), 400

    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        return jsonify({"error": "Niepoprawny format daty. Użyj YYYY-MM-DD."}), 400
    if not re.match(r"^\d{1,2}:\d{2}$", time):
        return jsonify({"error": "Niepoprawny format godziny. Użyj H:MM lub HH:MM."}), 400

    filepath = _teacher_file(teacher_name)
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"[{date}] [{time}] {students}\n")

    return jsonify({"status": "success", "message": "Dodano wpis do harmonogramu."})


@app.route('/update_schedule_entry', methods=['POST'])
def update_schedule_entry():
    data = request.json or {}
    teacher_name = data.get("teacher_name")
    entry_index = data.get("entry_index")
    date = data.get("date")
    time = data.get("time")
    students = data.get("students")

    if teacher_name is None or entry_index is None or not all([date, time, students]):
        return jsonify({"error": "Brak danych: teacher_name, entry_index, date, time, students są wymagane."}), 400

    try:
        entry_index = int(entry_index)
    except ValueError:
        return jsonify({"error": "entry_index musi być liczbą całkowitą."}), 400

    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        return jsonify({"error": "Niepoprawny format daty. Użyj YYYY-MM-DD."}), 400
    if not re.match(r"^\d{1,2}:\d{2}$", time):
        return jsonify({"error": "Niepoprawny format godziny. Użyj H:MM lub HH:MM."}), 400

    entries, filepath = _read_schedule_entries(teacher_name)
    if entries is None:
        return jsonify({"error": "Brak harmonogramu dla nauczyciela."}), 404

    target = None
    for i, entry in enumerate(entries):
        if entry["index"] == entry_index:
            target = i
            break
    if target is None:
        return jsonify({"error": "Nie znaleziono wpisu o podanym indexie."}), 404

    entries[target]["date"] = date
    entries[target]["time"] = time
    entries[target]["students"] = students
    entries[target]["line"] = f"[{date}] [{time}] {students}"
    _write_schedule_entries(filepath, entries)

    return jsonify({"status": "success", "message": "Zaktualizowano wpis harmonogramu."})


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
    timestamp = datetime.now().strftime("%Y-%m-%d")
    line_to_save = f"[{timestamp}] {stats_text}"
    # Nie dublujemy daty, jeżeli klient już wysłał log z prefiksem [YYYY-MM-DD]
    if re.match(r"^\[\d{4}-\d{2}-\d{2}\]\s", stats_text):
        line_to_save = stats_text
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"{line_to_save}\n")
        
    return jsonify({"status": "success", "message": "Statystyki zapisane!"})

# 3. Podsumowanie postępów przez Twój model RAG
@app.route('/get_summary/<username>', methods=['GET'])
def get_summary(username):
    report_data = _load_or_create_report(username)
    if report_data is None:
        return jsonify({"error": "Brak wygenerowanego raportu dla tego użytkownika."}), 404
    try:
        return jsonify(report_data)
    except Exception as e:
        return jsonify({"error": f"Błąd modelu RAG: {str(e)}"}), 500


@app.route('/get_note/<username>', methods=['GET'])
def get_note(username):
    notes = _load_notes_timeline(username)
    if not notes:
        return jsonify({"status": "success", "note": ""})
    latest = notes[-1]
    return jsonify({"status": "success", "note": latest["content"], "created_at": latest["created_at"]})


@app.route('/save_note', methods=['POST'])
def save_note():
    data = request.json or {}
    username = data.get("username")
    note = data.get("note", "")

    if not username:
        return jsonify({"error": "Brakuje username."}), 400

    note = str(note).strip()
    if not note:
        return jsonify({"error": "Notatka nie może być pusta."}), 400

    created_at = datetime.now().isoformat(timespec="seconds")
    log_path = _notes_log_file_for_user(username)
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"created_at": created_at, "note": note}, ensure_ascii=False) + "\n")

    # Kompatybilność wsteczna: ostatnia notatka nadal pod legacy endpoint/file
    note_path = _notes_file_for_user(username)
    with open(note_path, "w", encoding="utf-8") as f:
        f.write(note)

    return jsonify({"status": "success", "message": "Notatka zapisana."})


@app.route('/update_note', methods=['POST'])
def update_note():
    data = request.json or {}
    username = data.get("username")
    note_id = data.get("note_id")
    note = data.get("note", "")

    if not username:
        return jsonify({"error": "Brakuje username."}), 400
    if note_id is None:
        return jsonify({"error": "Brakuje note_id."}), 400

    note = str(note).strip()
    if not note:
        return jsonify({"error": "Notatka nie może być pusta."}), 400

    try:
        note_id = int(note_id)
    except ValueError:
        return jsonify({"error": "note_id musi być liczbą całkowitą."}), 400

    log_path = _notes_log_file_for_user(username)
    if not os.path.exists(log_path):
        return jsonify({"error": "Brak historii notatek dla tego użytkownika."}), 404

    with open(log_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if note_id < 0 or note_id >= len(lines):
        return jsonify({"error": "Niepoprawny note_id."}), 404

    raw_line = lines[note_id].strip()
    if not raw_line:
        return jsonify({"error": "Wybrana notatka jest pusta i nie może być edytowana."}), 400

    try:
        parsed = json.loads(raw_line)
    except json.JSONDecodeError:
        return jsonify({"error": "Wybrany wpis notatki ma niepoprawny format."}), 400

    original_created_at = parsed.get("created_at") or datetime.now().isoformat(timespec="seconds")
    parsed["note"] = note
    parsed["created_at"] = original_created_at
    parsed["updated_at"] = datetime.now().isoformat(timespec="seconds")
    lines[note_id] = json.dumps(parsed, ensure_ascii=False) + "\n"

    with open(log_path, "w", encoding="utf-8") as f:
        f.writelines(lines)

    # Aktualizujemy też legacy plik z ostatnią notatką.
    note_path = _notes_file_for_user(username)
    with open(note_path, "w", encoding="utf-8") as f:
        f.write(note)

    return jsonify({"status": "success", "message": "Notatka zaktualizowana."})


@app.route('/generate_report', methods=['POST'])
def generate_report():
    data = request.json or {}
    username = data.get("username")
    if not username:
        return jsonify({"error": "Brakuje username."}), 400

    try:
        report_data = _generate_report(username)
        if report_data is None:
            return jsonify({"error": "Brak statystyk dla tego użytkownika."}), 404
        return jsonify(report_data)
    except Exception as e:
        return jsonify({"error": f"Błąd generowania raportu: {str(e)}"}), 500


@app.route('/get_report_timeline/<username>', methods=['GET'])
def get_report_timeline(username):
    reports = _load_reports_timeline(username)
    notes = _load_notes_timeline(username)

    timeline = list(reports)
    timeline.extend(notes)

    timeline.sort(key=lambda x: x.get("created_at", ""))
    return jsonify({
        "status": "success",
        "username": username,
        "timeline": timeline
    })


@app.route('/get_progress/<username>', methods=['GET'])
def get_progress(username):
    filepath = _stats_file_for_user(username)
    if not os.path.exists(filepath):
        return jsonify({"error": "Brak statystyk dla tego użytkownika."}), 404

    with open(filepath, "r", encoding="utf-8") as f:
        raw_lines = [line.strip() for line in f.readlines() if line.strip()]

    parsed_entries = []

    for idx, line in enumerate(raw_lines):
        date_match = re.search(r"\[(\d{4}-\d{2}-\d{2})\]", line)
        if date_match:
            try:
                parsed_date = datetime.strptime(date_match.group(1), "%Y-%m-%d").date()
            except ValueError:
                parsed_date = datetime.fromtimestamp(os.path.getmtime(filepath)).date()
        else:
            parsed_date = datetime.fromtimestamp(os.path.getmtime(filepath)).date()

        lowered = line.lower()
        delta = 0
        if "poprawnie" in lowered:
            delta = 1
        elif "błędnie" in lowered or "blednie" in lowered:
            delta = -1

        parsed_entries.append({
            "date": parsed_date.isoformat(),
            "delta": delta,
            "log": line,
            "index": idx
        })

    parsed_entries.sort(key=lambda x: (x["date"], x["index"]))
    running_score = 0
    for entry in parsed_entries:
        running_score += entry["delta"]
        entry["score"] = running_score

    return jsonify({
        "status": "success",
        "username": username,
        "progress": [{"date": e["date"], "score": e["score"], "delta": e["delta"], "log": e["log"]} for e in parsed_entries]
    })

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
    app.run(debug=True,host="0.0.0.0", port=5000)
