import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController controller = TextEditingController();
  final CommentService service = CommentService();
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> enviarComentario() async {
    if (controller.text.trim().isEmpty) return;

    final user = auth.currentUser;

    await service.adicionarComentario(
      Comment(
        id: '',
        postId: widget.postId,
        userId: user!.uid,
        texto: controller.text.trim(),
        timestamp: DateTime.now(),
      ),
    );

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comentários")),
      body: Column(
        children: [
          /// 🔥 LISTA DE COMENTÁRIOS
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: service.getComentarios(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Nenhum comentário ainda"));
                }

                final comentarios = snapshot.data!;

                return ListView.builder(
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final c = comentarios[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(c.texto),
                      subtitle: Text(
                        c.timestamp.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT DE COMENTÁRIO
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Digite um comentário...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: enviarComentario,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
