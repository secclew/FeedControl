import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

    await FirebaseFirestore.instance
        .collection('preferencias')
        .doc('usuario_teste')
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


