import 'package:flutter/material.dart';
import 'student_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final StudentService service = StudentService(baseUrl: 'http://10.223.189.121:5000');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raport Ucznia',
      home: StudentListPage(service: service),
    );
  }
}

class StudentListPage extends StatefulWidget {
  final StudentService service;

  StudentListPage({required this.service});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<String> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void fetchStudents() async {
    try {
      final data = await widget.service.getStudents();
      setState(() {
        students = data;
        loading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void showSummary(String username) async {
    try {
      final summary = await widget.service.getSummary(username);
      print("Raport dla $username:\n$summary"); 
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Raport ucznia: $username'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Zamknij'),
            ),
          ],
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista uczniów')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  title: Text(student),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () => showSummary(student),
                );
              },
            ),
    );
  }
}