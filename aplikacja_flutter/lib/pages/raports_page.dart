import 'package:flutter/material.dart';
import '../student_service.dart';

class ReportsPage extends StatelessWidget {
  final StudentService service;

  const ReportsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raporty uczniów")),
      body: FutureBuilder<List<String>>(
        future: service.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Błąd: ${snapshot.error}"));
          }
          final students = snapshot.data ?? [];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final username = students[index];
                  return ListTile(
                    title: Text(username),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportTimelinePage(
                            service: service,
                            username: username,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReportTimelinePage extends StatefulWidget {
  final StudentService service;
  final String username;

  const ReportTimelinePage({
    super.key,
    required this.service,
    required this.username,
  });

  @override
  State<ReportTimelinePage> createState() => _ReportTimelinePageState();
}

class _ReportTimelinePageState extends State<ReportTimelinePage> {
  final TextEditingController _noteController = TextEditingController();
  late Future<List<ReportTimelineItem>> _timelineFuture;
  bool _isSaving = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _timelineFuture = widget.service.getReportTimeline(widget.username);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _reloadTimeline() {
    setState(() {
      _timelineFuture = widget.service.getReportTimeline(widget.username);
    });
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d.$m.${date.year} $h:$min';
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSaving = true;
    });
    try {
      await widget.service.saveNote(
        username: widget.username,
        note: text,
      );
      if (!mounted) return;
      _noteController.clear();
      _reloadTimeline();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodano notatkę do timeline')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd zapisu notatki: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editNote(ReportTimelineItem item) async {
    if (item.noteId == null) return;
    final controller = TextEditingController(text: item.content);
    bool isUpdating = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edytuj notatkę'),
            content: TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Treść notatki...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final updatedText = controller.text.trim();
                        if (updatedText.isEmpty) return;
                        setDialogState(() {
                          isUpdating = true;
                        });
                        try {
                          await widget.service.updateNote(
                            username: widget.username,
                            noteId: item.noteId!,
                            note: updatedText,
                          );
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          _reloadTimeline();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notatka zaktualizowana')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Błąd edycji notatki: $e')),
                          );
                        } finally {
                          if (context.mounted) {
                            setDialogState(() {
                              isUpdating = false;
                            });
                          }
                        }
                      },
                child: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });
    try {
      await widget.service.generateReport(widget.username);
      if (!mounted) return;
      _reloadTimeline();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wygenerowano nowy raport')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd generowania raportu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline: ${widget.username}'),
        actions: [
          if (isWide)
            TextButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generuj raport'),
            )
          else
            IconButton(
              tooltip: 'Generuj raport',
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _noteController,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Nowa notatka nauczyciela',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveNote,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Dodaj'),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            TextField(
                              controller: _noteController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Nowa notatka nauczyciela',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveNote,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Dodaj'),
                              ),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: FutureBuilder<List<ReportTimelineItem>>(
                    future: _timelineFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Błąd: ${snapshot.error}'));
                      }
                      final timeline = snapshot.data ?? [];
                      if (timeline.isEmpty) {
                        return const Center(child: Text('Brak danych timeline.'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: timeline.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = timeline[index];
                          final isReport = item.type == 'report';

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isReport ? Colors.blue.shade50 : Colors.orange.shade50,
                              border: Border.all(
                                color: isReport ? Colors.blue.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isReport ? Icons.description : Icons.sticky_note_2,
                                  color: isReport ? Colors.blue.shade700 : Colors.orange.shade800,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isReport ? 'Raport wygenerowany' : 'Notatka nauczyciela',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _formatDate(item.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item.content),
                                    ],
                                  ),
                                ),
                                if (!isReport && item.noteId != null)
                                  IconButton(
                                    tooltip: 'Edytuj notatkę',
                                    onPressed: () => _editNote(item),
                                    icon: const Icon(Icons.edit),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
