class Post {
  final String id;

  final String titulo;
  final String categoria;
  final String imagem;

  final String autor;
  final String avatar;
  final String tempo;

  double engajamento;
  int? comentariosCount;
  final double recencia;

  final DateTime timestamp;

  int likes;

  Post({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.imagem,
    required this.autor,
    required this.avatar,
    required this.tempo,
    required this.engajamento,
    required this.recencia,
    required this.timestamp,
    this.likes = 0, // ✅ valor padrão
  });

  /// 🔥 FIRESTORE → MODEL
  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      titulo: data['titulo'] ?? '',
      categoria: data['categoria'] ?? '',
      imagem: data['imagem'] ?? '',
      autor: data['autor'] ?? '',
      avatar: data['avatar'] ?? '',
      tempo: data['tempo'] ?? '',
      engajamento: (data['engajamento'] is num)
          ? (data['engajamento'] as num).toDouble()
          : double.tryParse(data['engajamento']?.toString() ?? '') ?? 0.5,
      recencia: (data['recencia'] is num)
          ? (data['recencia'] as num).toDouble()
          : double.tryParse(data['recencia']?.toString() ?? '') ?? 1.0,
      likes: (data['likes'] is int)
          ? data['likes'] as int
          : int.tryParse(data['likes']?.toString() ?? '') ?? 0,
      timestamp: (data['timestamp'] != null)
          ? data['timestamp'].toDate()
          : DateTime.now(), // ✅ fallback seguro
    );
  }

  /// 🔥 MODEL → FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'categoria': categoria,
      'imagem': imagem,
      'autor': autor,
      'avatar': avatar,
      'tempo': tempo,
      'engajamento': engajamento,
      'recencia': recencia,
      'likes': likes,
      'timestamp': timestamp,
    };
  }
}
