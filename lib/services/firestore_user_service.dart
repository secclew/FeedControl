import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna o UID de forma segura. 
  /// Usamos '?' para não quebrar o app caso o Firebase ainda esteja carregando o usuário.
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// 🔥 SALVAR PREFERÊNCIAS DO ALGORITMO
  Future<void> salvarPreferencias(Map<String, double> preferencias) async {
    final userUid = uid;
    
    // Se o usuário não estiver logado, interrompemos a função silenciosamente
    if (userUid == null) {
      print("Aviso: Tentativa de salvar preferências sem usuário logado.");
      return;
    }

    try {
      await _db.collection("users").doc(userUid).set({
        "preferencias": preferencias,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Erro ao salvar preferências no Firestore: $e");
    }
  }

  /// 🔥 CARREGAR PREFERÊNCIAS
  Future<Map<String, double>?> carregarPreferencias() async {
    final userUid = uid;
    
    // Se não houver usuário, retornamos null imediatamente para evitar o crash
    if (userUid == null) return null;

    try {
      final doc = await _db.collection("users").doc(userUid).get();

      if (!doc.exists) return null;

      final data = doc.data();

      // Verifica se o documento tem o campo 'preferencias'
      if (data == null || !data.containsKey("preferencias") || data["preferencias"] == null) {
        return null;
      }

      final prefs = Map<String, dynamic>.from(data["preferencias"]);

      // Garante que todos os valores sejam convertidos para double com segurança
      return prefs.map((key, value) {
        return MapEntry(key, (value as num).toDouble());
      });
    } catch (e) {
      print("Erro ao carregar preferências do Firestore: $e");
      return null;
    }
  }

  /// 🔥 RESETAR PREFERÊNCIAS (Útil para o seu botão de Reset Total)
  Future<void> resetarPreferencias() async {
    final userUid = uid;
    if (userUid == null) return;

    try {
      await _db.collection("users").doc(userUid).update({
        "preferencias": {},
      });
    } catch (e) {
      print("Erro ao resetar preferências: $e");
    }
  }
}