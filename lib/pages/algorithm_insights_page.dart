import 'package:flutter/material.dart';

class AlgorithmInsightsPage extends StatelessWidget {
  final Map<String, double> preferencias;

  const AlgorithmInsightsPage({
    super.key,
    required this.preferencias,
  });

  Color corCategoria(double valor) {
    if (valor >= 0.8) {
      return Colors.green;
    } else if (valor >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preferências do Algoritmo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Como o algoritmo está aprendendo com você:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ...preferencias.entries.map((entry) {
              double valor = entry.value;
              int porcentagem = (valor * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Nome da categoria
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// Barra do algoritmo
                    LinearProgressIndicator(
                      value: valor,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        corCategoria(valor),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// Valor numérico
                    Text(
                      "$porcentagem%  (score ${valor.toStringAsFixed(2)})",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}