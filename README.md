# Math App - Project

The project consists of two main parts:
1. **Application layer (Flutter)** - teacher panel and frontend views.
2. **Model-server layer (Python/Flask + RAG)** - API, report generation, and data handling.

## Repository Structure

```text
.
├── aplikacja_flutter/          # Flutter frontend
├── Model_Server/               # Flask backend + RAG model
└── README.md
```

## 1. Application Layer (Flutter)

Lokalizacja: `aplikacja_flutter/`
Location: `aplikacja_flutter/`

### Main Features
1. **Teacher dashboard** - module tiles:
   - student reports (report and note timeline),
   - adding tasks,
   - student progress chart,
   - teacher schedule (calendar),
   - student task planner (frontend-only),
   - shorts (teacher panel + student preview, frontend-only).
2. **Reports**:
   - report generation,
   - report/note timeline,
   - adding and editing teacher notes.
3. **Progress chart**:
   - student selection,
   - cumulative score chart (+1 correct, -1 incorrect).
4. **Teacher schedule**:
   - monthly calendar view,
   - add/edit entries.
5. **Frontend-only modules**:
   - student task planner (local data),
   - shorts library + per-student assignment + student preview.

### Key Files
1. `aplikacja_flutter/lib/main.dart` - app setup and API `baseUrl`.
2. `aplikacja_flutter/lib/student_service.dart` - HTTP client for backend communication.
3. `aplikacja_flutter/lib/pages/` - module views.
4. `aplikacja_flutter/lib/shorts_store.dart` - local store for the shorts module.

### Running Flutter
Inside `aplikacja_flutter/`:

```bash
flutter pub get
flutter run
```

Example of running Web with explicit API URL:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## 2. Model-Server Layer (Python + Flask + RAG)

Location: `Model_Server/`

### Main Components
1. **Flask API** (`server.py`):
   - students and statistics,
   - reports and notes,
   - report/note timeline,
   - teacher schedules,
   - tasks and AI help.
2. **RAG model** (`Answer_model.py`):
   - local LLM via `llama_cpp`,
   - embeddings + FAISS.
3. **Project data** (`baza/`):
   - `statystyki/` - student logs,
   - `raporty/` - reports and notes,
   - `grafiki/` - teacher schedules,
   - `zadania/` - task sets.

### Main Endpoints (Summary)
1. **Students and statistics**
   - `GET /get_students`
   - `POST /save_stats`
   - `GET /get_progress/<username>`
2. **Reports and notes**
   - `GET /get_summary/<username>`
   - `POST /generate_report`
   - `GET /get_report_timeline/<username>`
   - `POST /save_note`
   - `POST /update_note`
3. **Teacher schedules**
   - `GET /get_teachers`
   - `GET /get_schedule/<teacher_name>`
   - `POST /add_schedule_entry`
   - `POST /update_schedule_entry`
4. **Tasks and help**
   - `POST /add_task`
   - `GET /get_tasks/<filename>`
   - `POST /ask_help`

### Running Backend
Inside `Model_Server/`:

```bash
pip install -r requirements.txt
python server.py
```

By default, the server starts at:

```text
http://0.0.0.0:5000
```

## Project Notes

1. The `shorts` and `student task planner` modules are currently **frontend-only** (no backend persistence).
2. Reports and notes keep history (timeline) in `*.jsonl` files.
3. The API includes CORS headers for Flutter Web compatibility.
