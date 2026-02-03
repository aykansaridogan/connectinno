class Note {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool pinned;

  Note({required this.id, required this.title, required this.content, DateTime? updatedAt, this.pinned = false})
      : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'pinned': pinned,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        title: m['title'] as String,
        content: m['content'] as String,
      updatedAt: DateTime.parse(m['updatedAt'] as String),
      pinned: m['pinned'] as bool? ?? false,
      );
}
