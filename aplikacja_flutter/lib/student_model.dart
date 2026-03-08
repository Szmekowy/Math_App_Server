class Student {
  final String username;

  Student({required this.username});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(username: json['username']);
  }
}