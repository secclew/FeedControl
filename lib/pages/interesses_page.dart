import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // importa para pegar o usuário logado

class InteressesPage extends StatefulWidget {
  const InteressesPage({super.key});

  @override
  State<InteressesPage> createState() => _InteressesPageState();
}

class _InteressesPageState extends State<InteressesPage> {
  final Set<String> _selecionados = {};

  void _toggleCategoria(String categoria) {
    setState(() {
      if (_selecionados.contains(categoria)) {
        _selecionados.remove(categoria);
      } else {
        _selecionados.add(categoria);
      }
    });
  }

  Future<void> _salvarPreferencias() async {
    if (_selecionados.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser; // pega usuário logado
    if (user == null) {
      // se não houver login, não salva
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('preferencias')
        .doc(user.uid) // usa o UID como ID do documento
        .set({
      'categorias': _selecionados.toList(),
    });

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/feed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha seus interesses'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma categoria encontrada'),
                  );
                }

                final categorias = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final categoria = data['categoria'] ?? '';
                  final label = data['label'] ?? categoria;

                  return {
                    'categoria': categoria.toString(),
                    'label': label.toString(),
                  };
                }).where((item) => item['categoria'] != '').toList();

                return ListView.builder(
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final item = categorias[index];
                    final categoria = item['categoria']!;
                    final label = item['label']!;

                    final selecionado =
                        _selecionados.contains(categoria);

                    return CheckboxListTile(
                      title: Text(label),
                      value: selecionado,
                      onChanged: (_) => _toggleCategoria(categoria),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _salvarPreferencias,
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}



