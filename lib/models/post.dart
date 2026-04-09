import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String titulo;
  final String descricao; // ✅ Novo campo adicionado
  final String categoria;
  final String imagem;
  final String autor;
  final String avatar;
  final String tempo;

  double engajamento;
  int comentariosCount;
  final double recencia;
  final DateTime timestamp;
  int likes;

  // 🔥 ATRIBUTO VOLÁTIL: Essencial para o controle do algoritmo
  double score; 

  Post({
    required this.id,
    required this.titulo,
    required this.descricao, // ✅ Requerido no construtor
    required this.categoria,
    required this.imagem,
    required this.autor,
    required this.avatar,
    required this.tempo,
    required this.engajamento,
    required this.recencia,
    required this.timestamp,
    this.likes = 0,
    this.comentariosCount = 0,
    this.score = 0.0, 
  });

  /// 🔥 FIRESTORE → MODEL
  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '', // ✅ Lendo do Firebase
      categoria: data['categoria'] ?? '',
      imagem: data['imagem'] ?? '',
      autor: data['autor'] ?? '',
      avatar: data['avatar'] ?? '',
      tempo: data['tempo'] ?? '',
      
      engajamento: _toDouble(data['engajamento']),
      recencia: _toDouble(data['recencia'], defaultValue: 1.0),
      
      likes: data['likes'] is int ? data['likes'] : 0,
      comentariosCount: data['comentariosCount'] is int ? data['comentariosCount'] : 0,
      
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
          
      score: 0.0, 
    );
  }

  /// 🔥 MODEL → FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao, // ✅ Salvando no Firebase
      'categoria': categoria,
      'imagem': imagem,
      'autor': autor,
      'avatar': avatar,
      'tempo': tempo,
      'engajamento': engajamento,
      'recencia': recencia,
      'likes': likes,
      'comentariosCount': comentariosCount,
      'timestamp': timestamp,
    };
  }

  static double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}