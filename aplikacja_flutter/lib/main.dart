import 'package:flutter/material.dart';
import 'student_service.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  final StudentService service =
      StudentService(baseUrl: 'http://10.223.189.121:5000');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raport Ucznia',
      home: DashboardPage(service: service),
    );
  }
}
