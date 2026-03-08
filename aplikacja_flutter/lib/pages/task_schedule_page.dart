import 'package:flutter/material.dart';

class TaskSchedulePage extends StatefulWidget {
  const TaskSchedulePage({super.key});

  @override
  State<TaskSchedulePage> createState() => _TaskSchedulePageState();
}

class _TaskScheduleItem {
  final String student;
  final String taskTitle;
  final DateTime deadline;
  final bool done;

  const _TaskScheduleItem({
    required this.student,
    required this.taskTitle,
    required this.deadline,
    this.done = false,
  });

  _TaskScheduleItem copyWith({
    String? student,
    String? taskTitle,
    DateTime? deadline,
    bool? done,
  }) {
    return _TaskScheduleItem(
      student: student ?? this.student,
      taskTitle: taskTitle ?? this.taskTitle,
      deadline: deadline ?? this.deadline,
      done: done ?? this.done,
    );
  }
}

class _TaskSchedulePageState extends State<TaskSchedulePage> {
  final List<_TaskScheduleItem> _items = [
    _TaskScheduleItem(
      student: 'Szymon',
      taskTitle: 'Równania kwadratowe - zestaw 1',
      deadline: DateTime.now().add(const Duration(days: 1)),
    ),
    _TaskScheduleItem(
      student: 'Wiktor',
      taskTitle: 'Trygonometria - karta pracy',
      deadline: DateTime.now().add(const Duration(days: 2)),
      done: true,
    ),
    _TaskScheduleItem(
      student: 'Jan',
      taskTitle: 'Funkcja liniowa - powtórka',
      deadline: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  String _studentFilter = 'Wszyscy';
  DateTime? _dateFilter;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  List<String> _students() {
    final set = _items.map((e) => e.student).toSet().toList()..sort();
    return ['Wszyscy', ...set];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_TaskScheduleItem> _filteredItems() {
    return _items.where((item) {
      final passStudent = _studentFilter == 'Wszyscy' || item.student == _studentFilter;
      final passDate = _dateFilter == null || _isSameDay(item.deadline, _dateFilter!);
      return passStudent && passDate;
    }).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Future<void> _openEditor({int? index}) async {
    final editing = index != null ? _items[index] : null;
    final studentCtrl = TextEditingController(text: editing?.student ?? '');
    final taskCtrl = TextEditingController(text: editing?.taskTitle ?? '');
    DateTime selectedDate = editing?.deadline ?? DateTime.now();
    bool done = editing?.done ?? false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            title: Text(index == null ? 'Nowe zadanie' : 'Edytuj zadanie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: studentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Uczeń',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: taskCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Zadanie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text('Termin: ${_formatDate(selectedDate)}')),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Zmień'),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: done,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wykonane'),
                    onChanged: (value) {
                      setDialog(() {
                        done = value ?? false;
                      });
                    },
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
                  final student = studentCtrl.text.trim();
                  final task = taskCtrl.text.trim();
                  if (student.isEmpty || task.isEmpty) return;

                  final item = _TaskScheduleItem(
                    student: student,
                    taskTitle: task,
                    deadline: selectedDate,
                    done: done,
                  );

                  setState(() {
                    if (index == null) {
                      _items.add(item);
                    } else {
                      _items[index] = item;
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();
    final students = _students();

    return Scaffold(
      appBar: AppBar(title: const Text('Harmonogram zadań uczniów')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final filters = Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: students.contains(_studentFilter) ? _studentFilter : 'Wszyscy',
                    decoration: const InputDecoration(
                      labelText: 'Filtr ucznia',
                      border: OutlineInputBorder(),
                    ),
                    items: students
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _studentFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateFilter == null
                              ? 'Filtr daty: brak'
                              : 'Filtr daty: ${_formatDate(_dateFilter!)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateFilter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateFilter = picked;
                            });
                          }
                        },
                        child: const Text('Ustaw'),
                      ),
                      if (_dateFilter != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _dateFilter = null;
                            });
                          },
                          child: const Text('Wyczyść'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );

          final list = filtered.isEmpty
              ? const Center(child: Text('Brak zadań dla wybranych filtrów.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final originalIndex = _items.indexOf(item);
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: item.done,
                          onChanged: (value) {
                            setState(() {
                              _items[originalIndex] = item.copyWith(done: value ?? false);
                            });
                          },
                        ),
                        title: Text(item.taskTitle),
                        subtitle: Text('${item.student} • termin ${_formatDate(item.deadline)}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edytuj',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditor(index: originalIndex),
                            ),
                            IconButton(
                              tooltip: 'Usuń',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() {
                                  _items.removeAt(originalIndex);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    children: [
                      SizedBox(width: 340, child: filters),
                      const SizedBox(width: 16),
                      Expanded(child: list),
                    ],
                  )
                : Column(
                    children: [
                      filters,
                      const SizedBox(height: 10),
                      Expanded(child: list),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
