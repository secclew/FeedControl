import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../services/post_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController tituloController = TextEditingController(); // ✅ Renomeado para clareza
  final TextEditingController descricaoController = TextEditingController(); // ✅ Novo: Campo de Descrição
  final TextEditingController urlController = TextEditingController(); 

  final PostService _postService = PostService();

  final ImagePicker _picker = ImagePicker();
  File? _imagemSelecionadaFile;
  XFile? _imagemSelecionadaXFile;

  String categoriaSelecionada = "tecnologia";
  final List<String> categorias = [
    "tecnologia", "ciencia", "politica", "programacao", "economia", "ia", "startups",
  ];

  bool _loading = false;

  /// 📸 SELECIONAR IMAGEM
  Future<void> selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionadaXFile = imagem;
        urlController.clear(); 
        if (!kIsWeb) {
          _imagemSelecionadaFile = File(imagem.path);
        }
      });
    }
  }

  /// ☁️ UPLOAD FIREBASE STORAGE
  Future<String?> uploadImagem() async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb && _imagemSelecionadaXFile != null) {
        await ref.putData(await _imagemSelecionadaXFile!.readAsBytes());
      } else if (_imagemSelecionadaFile != null) {
        await ref.putFile(_imagemSelecionadaFile!);
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("❌ Erro no Storage: $e");
      return null; 
    }
  }

  /// 🚀 PUBLICAR POST
  Future<void> publicarPost() async {
    if (tituloController.text.trim().isEmpty || descricaoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o título e a descrição!")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? urlFinal;

      if (urlController.text.trim().isNotEmpty) {
        urlFinal = urlController.text.trim();
      } 
      else if (_imagemSelecionadaXFile != null || _imagemSelecionadaFile != null) {
        urlFinal = await uploadImagem();
      }

      // ✅ Enviando Título E Descrição para o Service
      await _postService.criarPost(
        tituloController.text.trim(),
        descricaoController.text.trim(), // ✅ Novo parâmetro
        categoriaSelecionada,
        urlFinal ?? "", 
      );

      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao publicar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Publicação")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1️⃣ TÍTULO
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: "Título Chamativo",
                hintText: "Ex: O avanço da IA em 2026",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 2️⃣ DESCRIÇÃO (TEXTO DO POST)
            TextField(
              controller: descricaoController,
              maxLines: 5, // ✅ Mais espaço para o texto real
              decoration: const InputDecoration(
                labelText: "O que você está pensando?",
                hintText: "Escreva aqui o conteúdo do seu post...",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 15),

            // 3️⃣ CATEGORIA
            DropdownButtonFormField(
              value: categoriaSelecionada,
              items: categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => categoriaSelecionada = val.toString()),
              decoration: const InputDecoration(labelText: "Categoria", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            // 4️⃣ LINK DA IMAGEM
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "Link da Imagem (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (val) {
                if (val.isNotEmpty) setState(() => _imagemSelecionadaXFile = null);
              },
            ),
            const SizedBox(height: 20),

            /// PREVIEW DA IMAGEM
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: _imagemSelecionadaXFile != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb 
                      ? Image.network(_imagemSelecionadaXFile!.path, fit: BoxFit.cover)
                      : Image.file(_imagemSelecionadaFile!, fit: BoxFit.cover),
                  )
                : const Center(child: Text("Nenhuma imagem selecionada")),
            ),

            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: selecionarImagem,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Escolher Arquivo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200], 
                foregroundColor: Colors.black87
              ),
            ),
            
            const SizedBox(height: 30),

            // BOTÃO PUBLICAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : publicarPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("PUBLICAR NO FEED", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
