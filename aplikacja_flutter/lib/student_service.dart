import 'dart:convert';
import 'package:http/http.dart' as http;

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
}