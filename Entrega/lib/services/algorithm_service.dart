import '../models/post.dart';

class AlgorithmService {

  /// CALCULAR SCORE PRINCIPAL
  static double calcularScore(Post post, Map<String, double> preferencias) {

    double pesoPreferencia = (preferencias[post.categoria] ?? 50) /100;

    double penalidadeTempo = calcularPenalidadeTempo(post);

    double score =
        (pesoPreferencia * 0.4) +
        (post.engajamento * 0.3) +
        (post.recencia * 0.3) -
        penalidadeTempo;

    /// bônus de trending
    if (post.likes >= 5) {
      score += 0.5;
    }

    return score;
  }

  /// PENALIDADE DE TEMPO (decaimento)
  static double calcularPenalidadeTempo(Post post) {

    DateTime agora = DateTime.now();

    Duration diferenca = agora.difference(post.timestamp);

    double horas = diferenca.inHours.toDouble();

    /// cada 24h perde 0.1 de score
    return horas / 240;
  }

  /// EXPLICAR SCORE DO ALGORITMO
  static List<String> explicarScore(
    Post post,
    Map<String, double> preferencias,
  ) {

    List<String> motivos = [];

    double pesoPreferencia = (preferencias[post.categoria] ?? 50) /100;

    if (pesoPreferencia > 0.8) {
      motivos.add("Alta preferência do usuário");
    }

    if (post.engajamento > 0.7) {
      motivos.add("Post com alto engajamento");
    }

    if (post.recencia > 0.7) {
      motivos.add("Post recente");
    }

    if (post.likes >= 5) {
      motivos.add("🔥 Post em alta");
    }

    /// explicar decaimento
    DateTime agora = DateTime.now();
    Duration diferenca = agora.difference(post.timestamp);

    if (diferenca.inHours > 24) {
      motivos.add("Post perdeu prioridade por ser antigo");
    }

    return motivos;
  }

  /// ORDENAR FEED
  static List<Post> ordenarFeed(
    List<Post> posts,
    Map<String, double> preferencias,
  ) {

    List<Post> lista = List.from(posts);

    /// ordena pelo score
    lista.sort(
      (a, b) => calcularScore(
        b,
        preferencias,
      ).compareTo(
        calcularScore(
          a,
          preferencias,
        ),
      ),
    );

    /// diversidade de categorias
    List<Post> feedFinal = [];
    Set<String> ultimasCategorias = {};

    for (var post in lista) {

      if (!ultimasCategorias.contains(post.categoria)) {

        feedFinal.add(post);
        ultimasCategorias.add(post.categoria);

      } else {

        feedFinal.insert(0, post);

      }

      if (ultimasCategorias.length > 3) {
        ultimasCategorias.clear();
      }

    }

    return feedFinal;
  }
}
