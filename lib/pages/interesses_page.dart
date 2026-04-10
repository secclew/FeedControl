
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// ✅ CORREÇÃO: Salva como Mapa de Pesos para o Algoritmo funcionar
  Future<void> _salvarPreferencias() async {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um interesse!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar.')),
      );
      return;
    }

    try {
      // 1. Criamos um Mapa onde cada categoria selecionada vira um campo numérico
      // Isso permite que o PostService faça o cálculo de score corretamente.
      Map<String, double> pesosIniciais = {};
      
      for (String cat in _selecionados) {
        // Atribuímos um peso alto (100.0) para que esses posts vençam o ranking inicial
        pesosIniciais[cat.toLowerCase().trim()] = 100.0;
      }

      // 2. Salva no Firestore usando o UID do usuário
      // O .set() com esses campos garante que o motor de ranking encontre os valores
      await FirebaseFirestore.instance
          .collection('preferencias')
          .doc(user.uid)
          .set(pesosIniciais);

      if (!mounted) return;

      // 3. Navega para o feed já com o ranking calibrado
      Navigator.pushReplacementNamed(context, '/feed');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar preferências: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha seus interesses'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Selecione os temas que você deseja ver no topo do seu feed:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
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
                    child: Text('Nenhuma categoria encontrada no banco.'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final item = categorias[index];
                    final categoria = item['categoria']!;
                    final label = item['label']!;

                    final selecionado = _selecionados.contains(categoria);

                    return Card(
                      elevation: selecionado ? 4 : 1,
                      color: selecionado ? Colors.blue.shade50 : Colors.white,
                      child: CheckboxListTile(
                        title: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                            color: selecionado ? Colors.blue.shade900 : Colors.black87,
                          ),
                        ),
                        value: selecionado,
                        activeColor: Colors.blueAccent,
                        onChanged: (_) => _toggleCategoria(categoria),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _salvarPreferencias,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'CONTINUAR PARA O FEED',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}