import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 adicionar comentário
  Future<void> adicionarComentario(Comment comment) async {
    await _firestore.collection('comments').add(comment.toMap());
  }

  /// 🔹 stream de comentários por post
  Stream<List<Comment>> getComentarios(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
}