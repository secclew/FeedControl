import 'package:flutter/material.dart';
import '../services/user_preferences_service.dart';
import '../services/firestore_user_service.dart'; // Importe seu serviço do Firestore

class AlgorithmControlPage extends StatefulWidget {
  const AlgorithmControlPage({super.key});

  @override
  State<AlgorithmControlPage> createState() => _AlgorithmControlPageState();
}

class _AlgorithmControlPageState extends State<AlgorithmControlPage> {
  // Instância do serviço para salvar na nuvem
  final FirestoreUserService _firestoreService = FirestoreUserService();

  double tecnologia = 50;
  double ciencia = 50;
  double economia = 50;
  double entretenimento = 50;

  @override
  void initState() {
    super.initState();
    carregarPreferencias();
  }

  Future<void> carregarPreferencias() async {
    // Tenta carregar do Firestore primeiro para manter sincronizado
    Map<String, double>? prefs = await _firestoreService.carregarPreferencias();
    
    // Se não houver no Firestore, tenta o local
    if (prefs == null || prefs.isEmpty) {
      prefs = await UserPreferencesService.carregarPreferencias();
    }

    if (!mounted) return;

    setState(() {
      // O uso do .clamp(0.0, 1.0) evita que valores negativos quebrem o Slider
      tecnologia = ((prefs?["tecnologia"] ?? 0.5).clamp(0.0, 1.0)) * 100;
      ciencia = ((prefs?["ciencia"] ?? 0.5).clamp(0.0, 1.0)) * 100;
      economia = ((prefs?["economia"] ?? 0.5).clamp(0.0, 1.0)) * 100;
      entretenimento = ((prefs?["entretenimento"] ?? 0.5).clamp(0.0, 1.0)) * 100;
    });
  }

  Future<void> salvar() async {
    final preferenciasNormalizadas = {
      "tecnologia": tecnologia / 100,
      "ciencia": ciencia / 100,
      "economia": economia / 100,
      "entretenimento": entretenimento / 100,
    };

    // 1. Salva Localmente
    await UserPreferencesService.salvarPreferencias(preferenciasNormalizadas);
    
    // 2. Salva no Firestore (CRÍTICO para o feed aplicar a mudança)
    await _firestoreService.salvarPreferencias(preferenciasNormalizadas);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preferências aplicadas ao algoritmo!")),
    );

    // Retorna para o feed. O StreamBuilder no FeedPage vai detectar a mudança no Firestore.
    Navigator.pop(context); 
  }

  Widget sliderCategoria(String titulo, double valor, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$titulo: ${valor.toInt()}%", style: const TextStyle(fontWeight: FontWeight.w500)),
        Slider(
          value: valor.clamp(0.0, 100.0), // Segurança extra para o Slider não crashar
          min: 0,
          max: 100,
          divisions: 10,
          activeColor: Colors.blueAccent,
          label: valor.toInt().toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajustar Algoritmo")),
      body: SingleChildScrollView( // Adicionado para evitar erro de overflow em telas menores
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "O que você quer ver mais no seu feed?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            
            sliderCategoria("Tecnologia", tecnologia, (v) => setState(() => tecnologia = v)),
            sliderCategoria("Ciência", ciencia, (v) => setState(() => ciencia = v)),
            sliderCategoria("Economia", economia, (v) => setState(() => economia = v)),
            sliderCategoria("Entretenimento", entretenimento, (v) => setState(() => entretenimento = v)),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: salvar,
                child: const Text("SALVAR E ATUALIZAR FEED", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
