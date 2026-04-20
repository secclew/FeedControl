import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String titulo;
  final String descricao; 
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

  // Atributo calculado pelo PostService, não salvo diretamente no banco
  double score; 

  Post({
    required this.id,
    required this.titulo,
    required this.descricao,
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
  /// Esta factory é o "tradutor" que garante que o app não quebre se faltar um campo.
  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      titulo: data['titulo'] ?? 'Sem título',
      descricao: data['descricao'] ?? '', 
      categoria: data['categoria'] ?? 'geral',
      imagem: data['imagem'] ?? '',
      autor: data['autor'] ?? 'Eduardo',
      avatar: data['avatar'] ?? 'https://i.pravatar.cc/150?u=edu',
      tempo: data['tempo'] ?? 'Agora',
      
      // Uso do método auxiliar para garantir que números sejam doubles
      engajamento: _toDouble(data['engajamento']),
      recencia: _toDouble(data['recencia'], defaultValue: 1.0),
      
      // Garantindo que inteiros não venham nulos
      likes: data['likes'] is int ? data['likes'] : 0,
      comentariosCount: data['comentariosCount'] is int ? data['comentariosCount'] : 0,
      
      // Tratamento especial para o Timestamp do Firebase
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
          
      score: 0.0, 
    );
  }

  /// 🔥 MODEL → FIRESTORE
  /// Útil para quando você precisar atualizar o objeto inteiro
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'imagem': imagem,
      'autor': autor,
      'avatar': avatar,
      'tempo': tempo,
      'engajamento': engajamento,
      'recencia': recencia,
      'likes': likes,
      'comentariosCount': comentariosCount,
      'timestamp': Timestamp.fromDate(timestamp), // Converte de volta para Firebase
    };
  }

  /// Método auxiliar para evitar erros de tipo (num, int, double, String)
  static double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}