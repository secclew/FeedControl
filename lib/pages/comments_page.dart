import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Adicionado para o StreamBuilder direto
import '../models/comment.dart';
import '../services/post_service.dart'; // ✅ Usaremos o PostService que já ajustamos

class CommentsPage extends StatefulWidget {
  final String postId;
  final String categoria; // ✅ Adicionado para alimentar o algoritmo de interesse

  const CommentsPage({super.key, required this.postId, required this.categoria});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController controller = TextEditingController();
  final PostService postService = PostService(); // ✅ Usando o serviço unificado
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _enviando = false;

  Future<void> enviarComentario() async {
    final texto = controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);

    try {
      // Chamando o método que criamos no PostService
      // Ele já salva na subcoleção, aumenta o contador e atualiza o interesse!
      await postService.adicionarComentario(
        widget.postId,
        texto,
        widget.categoria,
      );

      controller.clear();
      FocusScope.of(context).unfocus(); // Fecha o teclado
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar: $e")),
      );
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comentários")),
      body: Column(
        children: [
          /// 🔥 LISTA DE COMENTÁRIOS (Lendo da Subcoleção)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Buscamos direto na subcoleção dentro do post para garantir sincronia
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Nenhum comentário ainda. Seja o primeiro!"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // Tratamento de data simples
                    final DateTime? dataHora = (data['timestamp'] as Timestamp?)?.toDate();
                    final String dataFormatada = dataHora != null 
                        ? "${dataHora.day}/${dataHora.month} ${dataHora.hour}:${dataHora.minute}"
                        : "Agora";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(data['texto'] ?? ""),
                      subtitle: Text(
                        "${data['autor']} • $dataFormatada",
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT DE COMENTÁRIO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Escreva algo...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => enviarComentario(),
                  ),
                ),
                _enviando 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
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
