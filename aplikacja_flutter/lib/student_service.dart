import 'dart:convert';
import 'package:http/http.dart' as http;

class ProgressPoint {
  final DateTime date;
  final int score;
  final int delta;
  final String log;

  ProgressPoint({
    required this.date,
    required this.score,
    required this.delta,
    required this.log,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      date: DateTime.parse(json['date'] as String),
      score: (json['score'] as num).toInt(),
      delta: (json['delta'] as num).toInt(),
      log: (json['log'] as String?) ?? '',
    );
  }
}

class ScheduleEntry {
  final int index;
  final DateTime date;
  final String time;
  final String students;

  ScheduleEntry({
    required this.index,
    required this.date,
    required this.time,
    required this.students,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      index: (json['index'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      time: (json['time'] as String?) ?? '',
      students: (json['students'] as String?) ?? '',
    );
  }
}

class StudentService {
  final String baseUrl;

  StudentService({required this.baseUrl});

  // Pobieramy listę uczniów (na razie z folderu statystyk)
  Future<List<String>> getStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/get_students'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['students'];
      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Błąd pobierania uczniów');
    }
  }

  // Pobieramy raport dla wybranego ucznia
  Future<String> getSummary(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/get_summary/$username'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['summary'];
    } else {
      throw Exception('Błąd pobierania raportu');
    }
  }

  Future<List<ProgressPoint>> getProgress(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/get_progress/$username'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['progress'] as List<dynamic>? ?? []);
      return items
          .map((e) => ProgressPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Błąd pobierania postępu');
    }
  }

  Future<List<String>> getTeachers() async {
    final response = await http.get(Uri.parse('$baseUrl/get_teachers'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final teachers = (data['teachers'] as List<dynamic>? ?? []);
      return teachers.map((e) => e.toString()).toList();
    } else {
      throw Exception('Błąd pobierania nauczycieli');
    }
  }

  Future<List<ScheduleEntry>> getSchedule(String teacherName) async {
    final response = await http.get(Uri.parse('$baseUrl/get_schedule/$teacherName'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['schedule'] as List<dynamic>? ?? []);
      return items
          .where((e) =>
              (e as Map<String, dynamic>)['date'] != null &&
              (e['date'] as String).isNotEmpty &&
              (e['time'] as String).isNotEmpty)
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Błąd pobierania harmonogramu');
    }
  }

  Future<void> addScheduleEntry({
    required String teacherName,
    required String date,
    required String time,
    required String students,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_schedule_entry'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'teacher_name': teacherName,
        'date': date,
        'time': time,
        'students': students,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Błąd dodawania wpisu harmonogramu');
    }
  }

  Future<void> updateScheduleEntry({
    required String teacherName,
    required int entryIndex,
    required String date,
    required String time,
    required String students,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_schedule_entry'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'teacher_name': teacherName,
        'entry_index': entryIndex,
        'date': date,
        'time': time,
        'students': students,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Błąd edycji wpisu harmonogramu');
    }
  }
}
