import 'package:flutter/material.dart';
import '../student_service.dart';

class ReportsPage extends StatelessWidget {
  final StudentService service;

  ReportsPage({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Raporty uczniów")),
      body: FutureBuilder<List<String>>(
        future: service.getStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Błąd: ${snapshot.error}"));
          } else {
            final students = snapshot.data ?? [];
            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final username = students[index];
                return ListTile(
                  title: Text(username),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () async {
                    try {
                      final summary = await service.getSummary(username);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Raport: $username"),
                          content: Container(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: Text(summary),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Zamknij"),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Błąd pobierania raportu: $e")),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}