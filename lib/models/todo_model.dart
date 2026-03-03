class TodoModel {
  final int? id;
  final String title;
  final String encryptedSecretNotes;
  final DateTime createdAt;
  bool isCompleted;

  TodoModel({
    this.id,
    required this.title,
    required this.encryptedSecretNotes,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'encryptedSecretNotes': encryptedSecretNotes,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'],
      title: map['title'],
      encryptedSecretNotes: map['encryptedSecretNotes'],
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
