import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/firestore_user_service.dart';
import '../services/user_preferences_service.dart';
import '../user/user_profile.dart';
import 'algorithm_insights_page.dart';
import '../algorithm_control_page.dart';
import 'create_post_page.dart';
import 'comments_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final UserProfile userProfile = UserProfile();
  final FirestoreUserService firestoreService = FirestoreUserService();
  final PostService postService = PostService();

  Set<String> categoriasBloqueadas = {};
  Map<String, double> preferenciasUsuario = {};

  @override
  void initState() {
    super.initState();
    carregarPreferencias();
  }

  Future<void> carregarPreferencias() async {
    Map<String, double>? prefs = await firestoreService.carregarPreferencias();
    if (prefs == null || prefs.isEmpty) {
      prefs = await UserPreferencesService.carregarPreferencias();
    }

    if (mounted && prefs != null) {
      setState(() {
        preferenciasUsuario = prefs!.map(
            (k, v) => MapEntry(k.toLowerCase().trim(), v.toDouble()));
      });
    }
  }

  void registrarInteresse(String categoria, String acao) {
    final cat = categoria.toLowerCase().trim();
    setState(() {
      if (acao == "curtida") userProfile.registrarCurtida(cat);
      if (acao == "comentario") userProfile.registrarVisualizacao(cat);
      preferenciasUsuario[cat] = userProfile.calcularPreferencia(cat).clamp(0.0, 1.0);
    });
    UserPreferencesService.salvarPreferencias(preferenciasUsuario);
    firestoreService.salvarPreferencias(preferenciasUsuario);
  }

  Widget buildImage(String url) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[300],
      child: url.isEmpty || !url.startsWith('http')
          ? const Icon(Icons.image_not_supported, color: Colors.grey, size: 50)
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
              ),
            ),
    );
  }

  void curtirPost(Post post) async {
    await postService.curtirPost(post.id, post.categoria);
    registrarInteresse(post.categoria, "curtida");
    setState(() {
      post.likes = post.likes + 1;
    });
  }

  void bloquearCategoria(String categoria) {
    final cat = categoria.toLowerCase().trim();
    setState(() => categoriasBloqueadas.add(cat));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Categoria $cat ocultada."),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "Desfazer",
          onPressed: () {
            setState(() => categoriasBloqueadas.remove(cat));
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FeedControl", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: () async {
              await carregarPreferencias();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Algoritmo atualizado!"), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlgorithmInsightsPage(preferencias: preferenciasUsuario))),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AlgorithmControlPage()));
              carregarPreferencias();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => carregarPreferencias(),
        child: StreamBuilder<List<Post>>(
          stream: postService.getPosts(preferencias: preferenciasUsuario),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Nenhum post disponível."));

            final posts = snapshot.data!
                .where((p) => !categoriasBloqueadas.contains(p.categoria.toLowerCase().trim()))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO DO CARD (APENAS LÁPIS E LIXEIRA) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ✏️ LÁPIS
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreatePostPage(postParaEditar: post)),
                              ),
                            ),
                            // 🗑️ LIXEIRA
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                              onPressed: () => postService.excluirPost(post.id),
                            ),
                          ],
                        ),
                      ),
                      
                      buildImage(post.imagem),
                      
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.descricao, 
                              style: TextStyle(color: Colors.grey[800], fontSize: 14),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  post.categoria.toUpperCase(),
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                                Text(
                                  "Score: ${post.score.toStringAsFixed(1)}",
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => curtirPost(post)),
                            Text("${post.likes}"),
                            const SizedBox(width: 15),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () {
                                registrarInteresse(post.categoria, "comentario");
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsPage(postId: post.id, categoria: post.categoria))).then((_) => carregarPreferencias());
                              },
                            ),
                            Text("${post.comentariosCount}"),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.block, size: 20, color: Colors.grey),
                              onPressed: () => bloquearCategoria(post.categoria),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}