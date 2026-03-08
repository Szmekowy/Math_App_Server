import 'package:flutter/material.dart';
import '../shorts_store.dart';

class ShortsStudentPage extends StatefulWidget {
  const ShortsStudentPage({super.key});

  @override
  State<ShortsStudentPage> createState() => _ShortsStudentPageState();
}

class _ShortsStudentPageState extends State<ShortsStudentPage> {
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

  @override
  Widget build(BuildContext context) {
    final students = _store.students;
    _selectedStudent ??= students.isNotEmpty ? students.first : null;
    final videos = _selectedStudent == null ? <ShortsVideo>[] : _store.videosForStudent(_selectedStudent!);

    return Scaffold(
      appBar: AppBar(title: const Text('Shorts - podgląd ucznia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const SizedBox(height: 12),
            Expanded(
              child: videos.isEmpty
                  ? const Center(
                      child: Text(
                        'Brak przypisanych filmów dla wybranego ucznia.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final v = videos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 240,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill, size: 80),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  v.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(v.description),
                                const Spacer(),
                                Text(
                                  'Autor: ${v.teacherName} • Plik: ${v.fileLabel}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
