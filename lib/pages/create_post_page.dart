import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // necessário para kIsWeb

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController textoController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? imagemSelecionada;

  final ImagePicker _picker = ImagePicker();
  File? _imagemSelecionadaFile;
  XFile? _imagemSelecionadaXFile; // ✅ usado para Web

  String categoriaSelecionada = "tecnologia";

  final List<String> categorias = [
    "tecnologia",
    "ciencia",
    "politica",
    "programacao",
    "economia",
    "ia",
    "startups",
  ];

  bool _loading = false;

  /// 📸 SELECIONAR IMAGEM
  Future<void> selecionarImagem() async {
    final XFile? imagem = await _picker.pickImage(source: ImageSource.gallery);

    if (imagem != null) {
      setState(() {
        _imagemSelecionadaXFile = imagem;
        if (!kIsWeb) {
          _imagemSelecionadaFile = File(imagem.path);
        }
      });
    }
  }

  /// ☁️ UPLOAD FIREBASE STORAGE
  Future<String> uploadImagem() async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(DateTime.now().millisecondsSinceEpoch.toString());

    if (kIsWeb && _imagemSelecionadaXFile != null) {
      // ✅ Upload direto do XFile no Web
      await ref.putData(await _imagemSelecionadaXFile!.readAsBytes());
    } else if (_imagemSelecionadaFile != null) {
      await ref.putFile(_imagemSelecionadaFile!);
    }

    return await ref.getDownloadURL();
  }

  /// 🚀 PUBLICAR POST
  Future<void> publicarPost() async {
    if (textoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha o texto")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      String uid = _auth.currentUser!.uid;
      String? urlImagem;

      // Só faz upload se houver imagem
      if (_imagemSelecionadaFile != null || _imagemSelecionadaXFile != null) {
        urlImagem = await uploadImagem();
      }

      await _firestore.collection("posts").add({
        "autor": uid,
        "titulo": textoController.text.trim(),
        "categoria": categoriaSelecionada.toLowerCase(), // ✅ normalizado
        "imagem": urlImagem ?? "",
        "likes": 0,
        "engajamento": 0.1,
        "recencia": 1.0,
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Post publicado com sucesso 🚀"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao publicar: $e")),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// TEXTO
            TextField(
              controller: textoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "O que você quer compartilhar?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// CATEGORIA
            DropdownButtonFormField(
              initialValue: categoriaSelecionada,
              items: categorias.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  categoriaSelecionada = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Categoria",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// PREVIEW IMAGEM
            _imagemSelecionadaXFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _imagemSelecionadaXFile!.path,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _imagemSelecionadaFile!,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text("Nenhuma imagem selecionada"),
                    ),
                  ),

            const SizedBox(height: 10),

            /// BOTÃO ESCOLHER IMAGEM
            ElevatedButton.icon(
              onPressed: selecionarImagem,
              icon: const Icon(Icons.image),
              label: const Text("Selecionar imagem"),
            ),

            const SizedBox(height: 30),

            /// BOTÃO PUBLICAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : publicarPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Publicar",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

