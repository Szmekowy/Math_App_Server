import 'package:flutter/material.dart';
import '../student_service.dart';

class AddTaskPage extends StatefulWidget {

  final StudentService service;

  AddTaskPage({required this.service});

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {

  final trescController = TextEditingController();
  final aController = TextEditingController();
  final bController = TextEditingController();
  final cController = TextEditingController();
  final dController = TextEditingController();
  final opisController = TextEditingController();
  final filenameController = TextEditingController();

  void submitTask() {
    // tutaj później wyślemy POST /add_task
    print("Dodawanie zadania...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dodaj zadanie")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [

            TextField(
              controller: filenameController,
              decoration: InputDecoration(labelText: "Nazwa zbioru"),
            ),

            TextField(
              controller: trescController,
              decoration: InputDecoration(labelText: "Treść zadania"),
            ),

            TextField(
              controller: aController,
              decoration: InputDecoration(labelText: "Odp A"),
            ),

            TextField(
              controller: bController,
              decoration: InputDecoration(labelText: "Odp B"),
            ),

            TextField(
              controller: cController,
              decoration: InputDecoration(labelText: "Odp C"),
            ),

            TextField(
              controller: dController,
              decoration: InputDecoration(labelText: "Odp D"),
            ),

            TextField(
              controller: opisController,
              decoration: InputDecoration(labelText: "Opis rozwiązania"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: submitTask,
              child: Text("Dodaj zadanie"),
            )

          ],
        ),
      ),
    );
  }
}