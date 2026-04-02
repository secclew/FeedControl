import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/firestore_user_service.dart';
import '../services/user_preferences_service.dart';
import '../user/user_profile.dart';
import '../data/mock_posts.dart';
import 'algorithm_insights_page.dart';
import '../algorithm_control_page.dart';
import 'create_post_page.dart';

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

  // --- 1. ALGORITMO: APRENDIZADO ATIVO ---
  void registrarInteresse(String categoria, String acao) {
    final cat = categoria.toLowerCase();
    setState(() {
      if (acao == "curtida") userProfile.registrarCurtida(cat);
      if (acao == "comentario") userProfile.registrarVisualizacao(cat); 
      
      preferenciasUsuario[cat] = userProfile.calcularPreferencia(cat).clamp(0.0, 1.0);
    });
    UserPreferencesService.salvarPreferencias(preferenciasUsuario);
    firestoreService.salvarPreferencias(preferenciasUsuario);
  }

  // --- 2. COMENTÁRIOS: PERSISTÊNCIA REAL NO FIRESTORE ---
  void abrirModalComentario(Post post) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, 
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Comentar em: ${post.titulo}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: controller, 
              decoration: const InputDecoration(
                hintText: "Escreva algo...",
                border: OutlineInputBorder(),
              ), 
              autofocus: true
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    // MODIFICAÇÃO: Agora chama o serviço que salva no banco
                    await postService.adicionarComentario(post.id, controller.text);
                    
                    setState(() {
                      post.comentariosCount = (post.comentariosCount ?? 0) + 1;
                      registrarInteresse(post.categoria, "comentario");
                    });
                    
                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comentário salvo!")));
                  }
                },
                child: const Text("Enviar Comentário"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 3. CURTIDAS E BLOQUEIOS ---
  void curtirPost(Post post) async {
    await postService.curtirPost(post.id);
    registrarInteresse(post.categoria, "curtida");
    setState(() {
      post.likes = (post.likes ?? 0) + 1;
    });
  }

  void bloquearCategoria(String categoria) async {
    final cat = categoria.toLowerCase();
    setState(() {
      categoriasBloqueadas.add(cat);
      userProfile.bloquearCategoria(cat);
      preferenciasUsuario[cat] = userProfile.calcularPreferencia(cat).clamp(0.0, 1.0);
    });
    await UserPreferencesService.salvarPreferencias(preferenciasUsuario);
    try { await firestoreService.salvarPreferencias(preferenciasUsuario); } catch (_) {}
  }

  void excluirPost(String id) async {
    await postService.excluirPost(id);
    setState(() {}); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post removido.")));
  }

  Future<void> carregarPreferencias() async {
    Map<String, double>? prefs = await firestoreService.carregarPreferencias();
    if (prefs == null || prefs.isEmpty) prefs = await UserPreferencesService.carregarPreferencias();
    if (mounted) {
      setState(() => preferenciasUsuario = prefs!.map((k, v) => MapEntry(k.toLowerCase(), v.toDouble())));
    }
  }

  // --- 4. PROTEÇÃO DE IMAGENS QUEBRADAS ---
  Widget buildImage(String url) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[200],
      child: url.isEmpty 
        ? const Icon(Icons.image, color: Colors.grey, size: 50)
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.broken_image, color: Colors.grey, size: 40), Text("Imagem indisponível")],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FeedControl", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await carregarPreferencias();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<Post>>(
          stream: postService.getPosts(preferencias: preferenciasUsuario),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            List<Post> posts = [...snapshot.data!, ...mockPosts];

            // Filtros de Bloqueio
            posts = posts.where((p) => !categoriasBloqueadas.contains(p.categoria.toLowerCase())).toList();

            // --- 5. ORDENAÇÃO POR POPULARIDADE ---
            posts.sort((a, b) => (b.likes ?? 0).compareTo(a.likes ?? 0));

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(), 
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final bool meuPost = post.id.length > 10; 

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildImage(post.imagem),
                      ListTile(
                        title: Text(post.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: Text("Categoria: ${post.categoria.toUpperCase()}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 12)),
                        trailing: meuPost 
                          ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => excluirPost(post.id)) 
                          : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                        child: Row(
                          children: [
                            IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () => curtirPost(post)),
                            Text("${post.likes ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 20),
                            IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => abrirModalComentario(post)),
                            Text("${post.comentariosCount ?? 0}"),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.block, color: Colors.grey, size: 20), 
                              onPressed: () => bloquearCategoria(post.categoria),
                              tooltip: "Bloquear categoria",
                            ),
                            const SizedBox(width: 10),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())),
        label: const Text("Novo Post"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
