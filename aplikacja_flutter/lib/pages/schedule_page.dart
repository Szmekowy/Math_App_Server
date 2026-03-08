import 'package:flutter/material.dart';
import '../student_service.dart';

class SchedulePage extends StatefulWidget {
  final StudentService service;

  const SchedulePage({super.key, required this.service});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<String> _teachers = [];
  String? _selectedTeacher;
  List<ScheduleEntry> _entries = [];
  bool _loadingTeachers = true;
  bool _loadingEntries = false;
  String? _error;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  static const List<String> _weekDays = ['Pn', 'Wt', 'Sr', 'Cz', 'Pt', 'Sb', 'Nd'];
  static const List<String> _monthNames = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _loadingTeachers = true;
      _error = null;
    });
    try {
      final teachers = await widget.service.getTeachers();
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
        _selectedTeacher = teachers.isNotEmpty ? teachers.first : null;
      });
      if (_selectedTeacher != null) {
        await _loadSchedule(_selectedTeacher!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać listy nauczycieli.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingTeachers = false;
      });
    }
  }

  Future<void> _loadSchedule(String teacherName) async {
    setState(() {
      _loadingEntries = true;
      _error = null;
    });
    try {
      final entries = await widget.service.getSchedule(teacherName);
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać harmonogramu.';
        _entries = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingEntries = false;
      });
    }
  }

  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _uiDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  String _uiTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, int> _countByDay() {
    final map = <String, int>{};
    for (final e in _entries) {
      final key = _isoDate(e.date);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  List<ScheduleEntry> _entriesForSelectedDay() {
    final list = _entries.where((e) => _isSameDate(e.date, _selectedDate)).toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  List<DateTime?> _buildMonthCells() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;

    final cells = <DateTime?>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(null);
    }
    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Future<void> _showAddDialog() async {
    if (_selectedTeacher == null) return;
    final studentsController = TextEditingController();
    DateTime selectedDate = _selectedDate;
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Dodaj wpis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Data: ${_uiDate(selectedDate)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Zmień'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('Godzina: ${_uiTime(selectedTime)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: const Text('Zmień'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: studentsController,
                  decoration: const InputDecoration(
                    labelText: 'Uczeń/uczniowie',
                    hintText: 'np. Zuzia, Jan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final students = studentsController.text.trim();
                  if (students.isEmpty) return;
                  await widget.service.addScheduleEntry(
                    teacherName: _selectedTeacher!,
                    date: _isoDate(selectedDate),
                    time: _uiTime(selectedTime),
                    students: students,
                  );
                  if (!mounted) return;
                  setState(() => _selectedDate = selectedDate);
                  Navigator.pop(context);
                  await _loadSchedule(_selectedTeacher!);
                },
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(ScheduleEntry entry) async {
    if (_selectedTeacher == null) return;
    final studentsController = TextEditingController(text: entry.students);
    DateTime selectedDate = entry.date;
    final parts = entry.time.split(':');
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 12,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edytuj wpis'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Data: ${_uiDate(selectedDate)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Zmień'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('Godzina: ${_uiTime(selectedTime)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: const Text('Zmień'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: studentsController,
                  decoration: const InputDecoration(
                    labelText: 'Uczeń/uczniowie',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final students = studentsController.text.trim();
                  if (students.isEmpty) return;
                  await widget.service.updateScheduleEntry(
                    teacherName: _selectedTeacher!,
                    entryIndex: entry.index,
                    date: _isoDate(selectedDate),
                    time: _uiTime(selectedTime),
                    students: students,
                  );
                  if (!mounted) return;
                  setState(() => _selectedDate = selectedDate);
                  Navigator.pop(context);
                  await _loadSchedule(_selectedTeacher!);
                },
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final cells = _buildMonthCells();
    final countMap = _countByDay();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              final key = _isoDate(day);
              final lessonsCount = countMap[key] ?? 0;
              final isSelected = _isSameDate(day, _selectedDate);
              final isToday = _isSameDate(day, DateTime.now());

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade50,
                    border: Border.all(
                      color: isToday ? Colors.blue : Colors.black12,
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${day.day}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      if (lessonsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$lessonsCount',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesSection(List<ScheduleEntry> selectedDayEntries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Zajęcia: ${_uiDate(_selectedDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        if (selectedDayEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Brak zajęć w wybranym dniu.')),
          )
        else
          ...selectedDayEntries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.time),
                subtitle: Text(entry.students),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(entry),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEntries = _entriesForSelectedDay();

    return Scaffold(
      appBar: AppBar(title: const Text('Harmonogram nauczyciela')),
      floatingActionButton: _selectedTeacher == null
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      if (_loadingTeachers)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedTeacher,
                          decoration: const InputDecoration(
                            labelText: 'Nauczyciel',
                            border: OutlineInputBorder(),
                          ),
                          items: _teachers
                              .map(
                                (teacher) => DropdownMenuItem<String>(
                                  value: teacher,
                                  child: Text(teacher),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedTeacher = value;
                            });
                            _loadSchedule(value);
                          },
                        ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (_loadingEntries) const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCalendar()),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildEntriesSection(selectedDayEntries),
                            ),
                          ],
                        )
                      else ...[
                        _buildCalendar(),
                        const SizedBox(height: 12),
                        _buildEntriesSection(selectedDayEntries),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
