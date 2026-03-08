import 'package:flutter/material.dart';
import 'add_task_page.dart';
import 'raports_page.dart';
import 'chart_page.dart';
import '../student_service.dart';

class DashboardPage extends StatelessWidget {
  final StudentService service;

  DashboardPage({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Panel nauczyciela")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          children: [

            // Kafelek RAPORTY
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportsPage(service: service),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 50),
                    SizedBox(height: 10),
                    Text("Raporty uczniów")
                  ],
                ),
              ),
            ),

            // Kafelek DODAJ ZADANIE
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTaskPage(service: service),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, size: 50),
                    SizedBox(height: 10),
                    Text("Dodaj zadanie")
                  ],
                ),
              ),
            ),

            // Kafelek WYKRES
        GestureDetector(
        onTap: () {
            Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChartPage(service: service), // nowa strona z wykresem
            ),
            );
        },
        child: Card(
            elevation: 5,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(Icons.show_chart, size: 50),
                SizedBox(height: 10),
                Text("Wykres ucznia")
            ],
            ),
        ),
        ),

          ],
        ),
      ),
    );
  }
}