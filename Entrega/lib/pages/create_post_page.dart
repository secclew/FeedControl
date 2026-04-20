import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../services/post_service.dart';
import '../models/post.dart';

class CreatePostPage extends StatefulWidget {
  final Post? postParaEditar; 
  const CreatePostPage({super.key, this.postParaEditar});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController urlController = TextEditingController(); 

  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();
  
  File? _imagemSelecionadaFile;
  XFile? _imagemSelecionadaXFile;

  // ✅ "geral" agora é o padrão inicial
  String categoriaSelecionada = "geral";
  
  // ✅ Lista atualizada com "geral" e "entretenimento"
  final List<String> categorias = [
    "geral", 
    "tecnologia", 
    "entretenimento",
    "ciencia", 
    "politica", 
    "programacao", 
    "economia", 
    "ia", 
    "startups"
  ];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.postParaEditar != null) {
      tituloController.text = widget.postParaEditar!.titulo;
      descricaoController.text = widget.postParaEditar!.descricao;
      urlController.text = widget.postParaEditar!.imagem;
      
      String catOriginal = widget.postParaEditar!.categoria.toLowerCase().trim();
      if (categorias.contains(catOriginal)) {
        categoriaSelecionada = catOriginal;
      } else {
        categoriaSelecionada = "geral"; 
      }
    }
  }

  Future<void> selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() {
        _imagemSelecionadaXFile = imagem;
        urlController.clear(); 
        if (!kIsWeb) _imagemSelecionadaFile = File(imagem.path);
      });
    }
  }

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
      return null; 
    }
  }

  Future<void> publicarPost() async {
    if (_loading) return; 

    if (tituloController.text.trim().isEmpty || descricaoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha título e descrição!"))
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? urlFinal;

      if (urlController.text.trim().isNotEmpty) {
        urlFinal = urlController.text.trim();
      } else if (_imagemSelecionadaXFile != null || _imagemSelecionadaFile != null) {
        urlFinal = await uploadImagem();
      }

      if (widget.postParaEditar != null) {
        await _postService.editarPost(
          widget.postParaEditar!.id,
          tituloController.text.trim(),
          descricaoController.text.trim(),
          categoriaSelecionada,
          urlFinal ?? widget.postParaEditar!.imagem,
        );
      } else {
        await _postService.criarPost(
          tituloController.text.trim(),
          descricaoController.text.trim(),
          categoriaSelecionada,
          urlFinal ?? "", 
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.postParaEditar != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar Publicação" : "Nova Publicação")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: "Título", 
                border: OutlineInputBorder(),
                hintText: "Dê um nome ao seu post aleatório..."
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descricaoController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Conteúdo", 
                border: OutlineInputBorder(), 
                alignLabelWithHint: true,
                hintText: "O que você está pensando agora?"
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: categoriaSelecionada,
              items: categorias.map((cat) => DropdownMenuItem(
                value: cat, 
                child: Text(cat.toUpperCase())
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => categoriaSelecionada = val);
              },
              decoration: const InputDecoration(
                labelText: "Categoria", 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: "Link da Imagem (Opcional)", 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.link)
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: selecionarImagem,
              icon: const Icon(Icons.add_a_photo),
              label: Text(isEditing ? "Mudar Imagem" : "Selecionar da Galeria"),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : publicarPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(
                      isEditing ? "SALVAR ALTERAÇÕES" : "PUBLICAR AGORA", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
