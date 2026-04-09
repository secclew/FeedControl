import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirestoreUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna o UID do usuário logado de forma segura
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// 🔥 SALVAR PREFERÊNCIAS
  /// Usa SetOptions(merge: false) para que, ao salvar, categorias antigas 
  /// ou repetidas sejam removidas, mantendo apenas as atuais da UI.
  Future<void> salvarPreferencias(Map<String, double> preferencias) async {
    final userUid = uid;
    if (userUid == null) {
      developer.log("Tentativa de salvar sem usuário logado", name: "FirestoreUserService");
      return;
    }

    try {
      // Salvamos na coleção raiz 'preferencias' para bater com as Rules de segurança
      await _db.collection("preferencias").doc(userUid).set(
        preferencias, 
        SetOptions(merge: false), 
      );
      developer.log("✅ Preferências salvas com sucesso!", name: "FirestoreUserService");
    } catch (e) {
      developer.log("❌ Erro ao salvar preferências", error: e, name: "FirestoreUserService");
    }
  }

  /// 🔥 CARREGAR PREFERÊNCIAS
  /// Corrigido para evitar o erro de 'JSArray': validamos se cada campo é um número.
  Future<Map<String, double>?> carregarPreferencias() async {
    final userUid = uid;
    if (userUid == null) return null;

    try {
      final doc = await _db.collection("preferencias").doc(userUid).get();

      if (!doc.exists || doc.data() == null) {
        developer.log("Documento de preferências não encontrado.", name: "FirestoreUserService");
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      Map<String, double> mapaLimpo = {};

      data.forEach((key, value) {
        // Validação crucial: o valor deve ser um número (int ou double)
        // Se o Firestore retornar uma lista [ ] ou nulo por erro, o app ignora e não crasha.
        if (value is num) {
          mapaLimpo[key] = value.toDouble();
        } else {
          developer.log("⚠️ Valor inválido ignorado para a categoria '$key': $value", name: "FirestoreUserService");
        }
      });

      return mapaLimpo;
    } catch (e) {
      developer.log("❌ Erro ao carregar preferências", error: e, name: "FirestoreUserService");
      return null;
    }
  }

  /// 🔥 RESETAR PREFERÊNCIAS
  /// Remove o documento do usuário, fazendo com que o feed volte ao estado padrão.
  Future<void> resetarPreferencias() async {
    final userUid = uid;
    if (userUid == null) return;

    try {
      await _db.collection("preferencias").doc(userUid).delete();
      developer.log("♻️ Preferências resetadas (documento excluído).", name: "FirestoreUserService");
    } catch (e) {
      developer.log("❌ Erro ao resetar preferências", error: e, name: "FirestoreUserService");
    }
  }
}