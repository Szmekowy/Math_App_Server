import 'package:flutter/material.dart';
import '../shorts_store.dart';

class ShortsTeacherPage extends StatefulWidget {
  const ShortsTeacherPage({super.key});

  @override
  State<ShortsTeacherPage> createState() => _ShortsTeacherPageState();
}

class _ShortsTeacherPageState extends State<ShortsTeacherPage> {
  final ShortsStore _store = ShortsStore.instance;
  String? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    if (_store.students.isNotEmpty) {
      _selectedStudent = _store.students.first;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      _selectedStudent ??= _store.students.isNotEmpty ? _store.students.first : null;
    });
  }

  Future<void> _openAddVideoDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final teacherCtrl = TextEditingController(text: 'Nauczyciel');
    final fileCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wgraj film (frontend)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tytuł filmu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: teacherCtrl,
                decoration: const InputDecoration(
                  labelText: 'Autor (nauczyciel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fileCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nazwa pliku (np. granice_1.mp4)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              _store.addVideo(
                title: titleCtrl.text,
                description: descCtrl.text,
                teacherName: teacherCtrl.text,
                fileLabel: fileCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddStudentDialog() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj ucznia'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Imię / login ucznia',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              _store.addStudent(ctrl.text);
              if (_selectedStudent == null && _store.students.isNotEmpty) {
                _selectedStudent = _store.students.first;
              }
              Navigator.pop(context);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final videos = _store.videos;
    final students = _store.students;
    _selectedStudent ??= students.isNotEmpty ? students.first : null;

    final libraryPanel = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Biblioteka filmów',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddVideoDialog,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Wgraj film'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (videos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Brak filmów. Dodaj pierwszy materiał.'),
              )
            else
              ...videos.map(
                (video) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(video.title),
                    subtitle: Text('${video.teacherName} • ${video.fileLabel}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final assignPanel = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Przypisanie do ucznia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddStudentDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Dodaj ucznia'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedStudent,
              decoration: const InputDecoration(
                labelText: 'Uczeń',
                border: OutlineInputBorder(),
              ),
              items: students
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudent = value;
                });
              },
            ),
            const SizedBox(height: 10),
            if (_selectedStudent == null)
              const Text('Dodaj ucznia, aby przypisać filmy.')
            else if (videos.isEmpty)
              const Text('Najpierw dodaj filmy do biblioteki.')
            else
              ...videos.map(
                (video) => CheckboxListTile(
                  value: _store.isAssigned(_selectedStudent!, video.id),
                  onChanged: (checked) {
                    _store.toggleAssign(
                      _selectedStudent!,
                      video.id,
                      checked ?? false,
                    );
                  },
                  title: Text(video.title),
                  subtitle: Text(video.fileLabel),
                ),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Shorts - panel nauczyciela')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SingleChildScrollView(child: libraryPanel)),
                  const SizedBox(width: 16),
                  Expanded(child: SingleChildScrollView(child: assignPanel)),
                ],
              )
            : ListView(
                children: [
                  libraryPanel,
                  const SizedBox(height: 12),
                  assignPanel,
                ],
              ),
      ),
    );
  }
}
