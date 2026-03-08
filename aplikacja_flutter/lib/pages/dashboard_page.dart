import 'package:flutter/material.dart';
import 'add_task_page.dart';
import 'raports_page.dart';
import 'chart_page.dart';
import 'schedule_page.dart';
import 'task_schedule_page.dart';
import '../student_service.dart';

class DashboardPage extends StatelessWidget {
  final StudentService service;

  const DashboardPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(title: const Text("Panel nauczyciela")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = 2;
          if (width >= 1200) {
            crossAxisCount = 4;
          } else if (width >= 800) {
            crossAxisCount = 3;
          } else if (orientation == Orientation.landscape) {
            crossAxisCount = 3;
          }
          final cardRatio = orientation == Orientation.landscape ? 1.6 : 1.1;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: cardRatio,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
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
                    const Icon(Icons.analytics, size: 50),
                    const SizedBox(height: 10),
                    const Text("Raporty uczniów")
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
                    const Icon(Icons.add_circle, size: 50),
                    const SizedBox(height: 10),
                    const Text("Dodaj zadanie")
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
                    builder: (_) => ChartPage(service: service),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.show_chart, size: 50),
                    const SizedBox(height: 10),
                    const Text("Wykres ucznia")
                  ],
                ),
              ),
            ),

            // Kafelek HARMONOGRAM
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchedulePage(service: service),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 50),
                    const SizedBox(height: 10),
                    const Text("Harmonogram")
                  ],
                ),
              ),
            ),

            // Kafelek HARMONOGRAM ZADAŃ
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TaskSchedulePage(),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt, size: 50),
                    const SizedBox(height: 10),
                    const Text("Plan zadań"),
                  ],
                ),
              ),
            ),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
