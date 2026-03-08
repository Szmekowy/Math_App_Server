import 'package:flutter/material.dart';

class ShortsVideo {
  final String id;
  final String title;
  final String description;
  final String teacherName;
  final String fileLabel;
  final DateTime createdAt;

  const ShortsVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.fileLabel,
    required this.createdAt,
  });
}

class ShortsStore extends ChangeNotifier {
  ShortsStore._();
  static final ShortsStore instance = ShortsStore._();

  final List<String> _students = ['Jan', 'Szymon', 'Wiktor'];
  final List<ShortsVideo> _videos = [];
  final Map<String, Set<String>> _assignedVideoIds = {};
  int _idCounter = 0;

  List<String> get students => List.unmodifiable(_students);
  List<ShortsVideo> get videos => List.unmodifiable(_videos);

  List<ShortsVideo> videosForStudent(String student) {
    final assigned = _assignedVideoIds[student] ?? <String>{};
    return _videos.where((v) => assigned.contains(v.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool isAssigned(String student, String videoId) {
    return _assignedVideoIds[student]?.contains(videoId) ?? false;
  }

  void addStudent(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    if (_students.contains(cleaned)) return;
    _students.add(cleaned);
    _students.sort();
    notifyListeners();
  }

  void addVideo({
    required String title,
    required String description,
    required String teacherName,
    required String fileLabel,
  }) {
    final t = title.trim();
    final teacher = teacherName.trim();
    if (t.isEmpty || teacher.isEmpty) return;

    _idCounter += 1;
    _videos.add(
      ShortsVideo(
        id: 'vid_$_idCounter',
        title: t,
        description: description.trim(),
        teacherName: teacher,
        fileLabel: fileLabel.trim().isEmpty ? 'bez_pliku.mp4' : fileLabel.trim(),
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void toggleAssign(String student, String videoId, bool assigned) {
    final bucket = _assignedVideoIds.putIfAbsent(student, () => <String>{});
    if (assigned) {
      bucket.add(videoId);
    } else {
      bucket.remove(videoId);
    }
    notifyListeners();
  }
}
