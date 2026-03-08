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
}
