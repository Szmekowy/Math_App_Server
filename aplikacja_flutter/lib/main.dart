import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'student_service.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  static String _resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    if (kIsWeb) {
      final uri = Uri.base;
      return '${uri.scheme}://${uri.host}:5000';
    }

    return 'http://10.223.189.121:5000';
  }

  final StudentService service = StudentService(baseUrl: _resolveBaseUrl());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raport Ucznia',
      home: DashboardPage(service: service),
    );
  }
}
