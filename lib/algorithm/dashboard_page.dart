import 'package:flutter/material.dart';

class AlgorithmDashboardPage extends StatelessWidget {
  const AlgorithmDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard do Algoritmo"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Como o algoritmo vê você",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Card(
              child: ListTile(
                title: Text("Categoria favorita"),
                subtitle: Text("Tecnologia"),
              ),
            ),

            const Card(
              child: ListTile(
                title: Text("Tempo médio de leitura"),
                subtitle: Text("2.5 minutos"),
              ),
            ),

            const Card(
              child: ListTile(
                title: Text("Posts curtidos"),
                subtitle: Text("14"),
              ),
            ),

            const Card(
              child: ListTile(
                title: Text("Categorias bloqueadas"),
                subtitle: Text("Política"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}