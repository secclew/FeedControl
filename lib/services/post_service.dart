import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 CRIAR POST
  /// Agora recebe [titulo] e [descricao] separadamente.
  Future<void> criarPost(String titulo, String descricao, String categoria, String imagem) async {
    try {
      String urlTratada = imagem.trim();
      String imagemFinal;

      // Se a imagem estiver vazia, gera uma URL automática via Picsum
      if (urlTratada.isEmpty) {
        imagemFinal = "https://picsum.photos/600/400?random=${DateTime.now().millisecondsSinceEpoch}";
        developer.log("🤖 Imagem vazia. Gerando automática: $imagemFinal");
      } else {
        imagemFinal = urlTratada;
      }

      await _firestore.collection('posts').add({
        'titulo': titulo.trim(),
        'descricao': descricao.trim(), // ✅ Novo campo salvo no banco
        'categoria': categoria.trim().toLowerCase(), 
        'imagem': imagemFinal,
        'likes': 0,
        'comentariosCount': 0,
        'engajamento': 0.0,
        'timestamp': FieldValue.serverTimestamp(),
        'autor': "Eduardo", // Aqui você pode trocar pelo nome do user logado futuramente
        'avatar': "https://i.pravatar.cc/150?u=edu",
        'tempo': "Agora",
        'recencia': 1.0,
      });
      
      developer.log("✅ Post criado com sucesso!");
    } catch (e) {
      developer.log("Erro ao criar post", error: e, name: 'PostService');
      rethrow;
    }
  }

  /// 💬 ADICIONAR COMENTÁRIO
  Future<void> adicionarComentario(String postId, String texto, String categoria) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('posts').doc(postId);

      await docRef.collection('comments').add({
        'texto': texto.trim(),
        'autor': user.email ?? "Usuário",
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'postId': postId,
      });

      await docRef.update({
        'comentariosCount': FieldValue.increment(1),
        'engajamento': FieldValue.increment(0.15),
      });

      await _atualizarInteresseUsuario(categoria, 0.10);
      developer.log("✅ Comentário vinculado ao post $postId");
    } catch (e) {
      developer.log("❌ Erro ao comentar", error: e, name: 'PostService');
      rethrow;
    }
  }

  /// 👍 CURTIR POST
  Future<void> curtirPost(String postId, String categoria) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);

      await docRef.update({
        'likes': FieldValue.increment(1),
        'engajamento': FieldValue.increment(0.05),
      });

      await _atualizarInteresseUsuario(categoria, 0.05);
      developer.log("✅ Like registrado no post $postId");
    } catch (e) {
      developer.log("Erro ao curtir", error: e, name: 'PostService');
    }
  }

  /// 🧠 MOTOR DE APRENDIZADO
  Future<void> _atualizarInteresseUsuario(String categoria, double incremento) async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid == null) return;

    String categoriaChave = _removerAcentos(categoria.trim().toLowerCase());

    try {
      await _firestore.collection('preferencias').doc(userUid).set({
        categoriaChave: FieldValue.increment(incremento),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log("Erro ao atualizar interesse", error: e);
    }
  }

  /// 🔥 MOTOR DE RANKING (Feed Inteligente)
  Stream<List<Post>> getPosts({Map<String, double>? preferencias}) {
    return _firestore.collection('posts').snapshots().map((snapshot) {
      List<Post> todosPosts = snapshot.docs.map((doc) {
        return Post.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (preferencias == null || preferencias.isEmpty) {
        todosPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return todosPosts;
      }

      for (var post in todosPosts) {
        String catDoPost = _removerAcentos(post.categoria.trim().toLowerCase());
        double pesoInteresse = preferencias[catDoPost] ?? 0.0;

        // FÓRMULA FEEDCONTROL
        double baseScore = (pesoInteresse * 1000.0);
        double socialScore = (post.engajamento * 5.0) + (post.likes * 0.1);

        post.score = baseScore + socialScore;
      }

      todosPosts.sort((a, b) {
        int cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return b.timestamp.compareTo(a.timestamp);
      });

      return todosPosts;
    });
  }

  /// 🗑️ EXCLUIR POST
  Future<void> excluirPost(String id) async {
    try {
      await _firestore.collection('posts').doc(id).delete();
    } catch (e) {
      developer.log("Erro ao excluir", error: e, name: 'PostService');
    }
  }

  String _removerAcentos(String texto) {
    var comAcento = 'àáâãäåèéêëìíîïòóôõöùúûüçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇ';
    var semAcento = 'aaaaaaeeeeiiiiooooouuuucAAAAAAEEEEIIIIOOOOOUUUUC';
    for (var i = 0; i < comAcento.length; i++) {
      texto = texto.replaceAll(comAcento[i], semAcento[i]);
    }
    return texto;
  }
}