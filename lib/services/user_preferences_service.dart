import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {

  static Future<void> salvarPreferencias(
      Map<String, double> preferencias) async {

    final prefs = await SharedPreferences.getInstance();

    preferencias.forEach((categoria, valor) {
      prefs.setDouble(categoria, valor);
    });

  }

  static Future<Map<String, double>> carregarPreferencias() async {

    final prefs = await SharedPreferences.getInstance();

    Map<String, double> preferencias = {};

    for (String key in prefs.getKeys()) {

      double? valor = prefs.getDouble(key);

      if (valor != null) {
        preferencias[key] = valor;
      }

    }

    return preferencias;

  }
}