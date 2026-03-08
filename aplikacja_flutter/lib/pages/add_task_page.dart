import 'package:flutter/material.dart';
import '../student_service.dart';

class AddTaskPage extends StatefulWidget {

  final StudentService service;

  const AddTaskPage({super.key, required this.service});

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

  @override
  void dispose() {
    trescController.dispose();
    aController.dispose();
    bController.dispose();
    cController.dispose();
    dController.dispose();
    opisController.dispose();
    filenameController.dispose();
    super.dispose();
  }

  void submitTask() {
    // tutaj później wyślemy POST /add_task
    print("Dodawanie zadania...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dodaj zadanie")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [

                    TextField(
                      controller: filenameController,
                      decoration: const InputDecoration(labelText: "Nazwa zbioru"),
                    ),

                    const SizedBox(height: 8),
                    TextField(
                      controller: trescController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Treść zadania"),
                    ),

                    const SizedBox(height: 8),
                    isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: aController,
                                  decoration: const InputDecoration(
                                    labelText: "Odp A (poprawna)",
                                    helperText: "Ta odpowiedź jest oznaczana jako poprawna.",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: bController,
                                  decoration: const InputDecoration(labelText: "Odp B"),
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: aController,
                            decoration: const InputDecoration(
                              labelText: "Odp A (poprawna)",
                              helperText: "Ta odpowiedź jest oznaczana jako poprawna.",
                            ),
                          ),

                    if (!isWide)
                      TextField(
                        controller: bController,
                        decoration: const InputDecoration(labelText: "Odp B"),
                      ),

                    const SizedBox(height: 8),
                    isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: cController,
                                  decoration: const InputDecoration(labelText: "Odp C"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: dController,
                                  decoration: const InputDecoration(labelText: "Odp D"),
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: cController,
                            decoration: const InputDecoration(labelText: "Odp C"),
                          ),

                    if (!isWide)
                      TextField(
                        controller: dController,
                        decoration: const InputDecoration(labelText: "Odp D"),
                      ),

                    const SizedBox(height: 8),
                    TextField(
                      controller: opisController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Opis rozwiązania"),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: ElevatedButton(
                          onPressed: submitTask,
                          child: const Text("Dodaj zadanie"),
                        ),
                      ),
                    )

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
