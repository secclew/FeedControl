class Comment {
  final String id;
  final String postId;
  final String userId;
  final String texto;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.texto,
    required this.timestamp,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      postId: data['postId'],
      userId: data['userId'],
      texto: data['texto'],
      timestamp: (data['timestamp'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'texto': texto,
      'timestamp': timestamp,
    };
  }
}