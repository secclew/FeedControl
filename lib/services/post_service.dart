import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importação necessária para o autor do comentário
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 CRIAR POST (Ajustado para receber os campos da CreatePostPage)
  Future<void> criarPost(String titulo, String categoria, String imagem) async {
    try {
      await _firestore.collection('posts').add({
        'titulo': titulo,
        'categoria': categoria,
        'imagem': imagem,
        'likes': 0,
        'comentariosCount': 0,
        'engajamento': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erro ao criar post: $e");
    }
  }

  /// 💬 ADICIONAR COMENTÁRIO (Persistência no Firestore)
  Future<void> adicionarComentario(String postId, String texto) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('posts').doc(postId);
      final doc = await docRef.get();

      // Verifica se o post existe no banco (Evita erro com Mocks)
      if (!doc.exists) {
        print("Aviso: Tentando comentar em um post Mock/Inexistente.");
        return;
      }

      // 1. Adiciona na subcoleção 'comments'
      await docRef.collection('comments').add({
        'texto': texto,
        'autor': user.email ?? "Usuário",
        'data': FieldValue.serverTimestamp(),
      });

      // 2. Incrementa o contador no documento principal
      await docRef.update({
        'comentariosCount': FieldValue.increment(1),
        'engajamento': FieldValue.increment(0.1), // Comentário gera mais engajamento que like
      });
    } catch (e) {
      print("Erro ao adicionar comentário: $e");
    }
  }

  /// 🔥 STREAM DE POSTS (tempo real)
  Stream<List<Post>> getPosts({Map<String, double>? preferencias}) {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Post> todosPosts = snapshot.docs.map((doc) {
        return Post.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (preferencias == null || preferencias.isEmpty) {
        return todosPosts;
      }

      // Lógica de mixagem baseada em pesos
      Map<String, List<Post>> postsPorCategoria = {};
      for (var post in todosPosts) {
        final cat = post.categoria.toLowerCase();
        postsPorCategoria.putIfAbsent(cat, () => []);
        postsPorCategoria[cat]!.add(post);
      }

      double somaPesos = preferencias.values.fold(0, (a, b) => a + b);
      if (somaPesos == 0) return todosPosts;

      Map<String, double> proporcoes = preferencias.map(
        (cat, peso) => MapEntry(cat, peso / somaPesos),
      );

      List<Post> feedFinal = [];
      for (var entry in proporcoes.entries) {
        final cat = entry.key;
        final proporcao = entry.value;
        final lista = postsPorCategoria[cat] ?? [];

        int quantidade = (todosPosts.length * proporcao).round();
        feedFinal.addAll(lista.take(quantidade));
      }

      if (feedFinal.length < todosPosts.length) {
        final restantes = todosPosts.where((p) => !feedFinal.contains(p));
        feedFinal.addAll(restantes);
      }

      return feedFinal;
    });
  }

  /// 👍 CURTIR POST
  Future<void> curtirPost(String postId) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      final doc = await docRef.get();

      if (!doc.exists) return; 

      await docRef.update({
        'likes': FieldValue.increment(1),
        'engajamento': FieldValue.increment(0.05),
      });
    } catch (e) {
      print("Erro ao curtir post: $e");
    }
  }

  /// 🗑️ EXCLUIR POST
  Future<void> excluirPost(String id) async {
    try {
      final docRef = _firestore.collection('posts').doc(id);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      }
    } catch (e) {
      print("Erro ao excluir post: $e");
    }
  }
}

