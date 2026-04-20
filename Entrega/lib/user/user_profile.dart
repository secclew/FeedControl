class UserProfile {
  // Mudamos para double para representar o "peso" de interesse (0.0 a 1.0)
  Map<String, double> interacoesCategoria = {};

  /// 1. REGISTRAR CURTIDA (Peso maior: +0.10)
  void registrarCurtida(String categoria) {
    final cat = categoria.toLowerCase();
    double pesoAtual = interacoesCategoria[cat] ?? 0.5; // Começa no neutro (0.5)
    
    // Incrementa e garante que não passe de 1.0
    interacoesCategoria[cat] = (pesoAtual + 0.10).clamp(0.0, 1.0);
  }

  /// 2. REGISTRAR VISUALIZAÇÃO/COMENTÁRIO (Peso menor: +0.05)
  /// Este é o método que estava faltando e dando erro no seu FeedPage!
  void registrarVisualizacao(String categoria) {
    final cat = categoria.toLowerCase();
    double pesoAtual = interacoesCategoria[cat] ?? 0.5;
    
    // O comentário demonstra interesse, mas um pouco menos que a curtida direta
    interacoesCategoria[cat] = (pesoAtual + 0.05).clamp(0.0, 1.0);
  }

  /// 3. CALCULAR PREFERÊNCIA
  double calcularPreferencia(String categoria) {
    final cat = categoria.toLowerCase();
    // Se não existe interação, retorna o valor neutro 0.5
    return interacoesCategoria[cat] ?? 0.5;
  }

  /// 4. BLOQUEAR CATEGORIA
  void bloquearCategoria(String categoria) {
    final cat = categoria.toLowerCase();
    // Em vez de -10 (que quebra o Slider), usamos 0.0 (interesse zero)
    interacoesCategoria[cat] = 0.0;
  }

  /// 5. RESETAR PREFERÊNCIAS (Útil para o botão de limpeza)
  void resetar() {
    interacoesCategoria.clear();
  }
}
  
