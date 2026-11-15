import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conferencia_model.dart';

class DatabaseHelper {
  static const String _chaveConferencias = 'strata_conferencias';

  static Future<List<Conferencia>> carregarConferencias() async {
    final preferences = await SharedPreferences.getInstance();

    final textoSalvo = preferences.getString(_chaveConferencias);

    if (textoSalvo == null || textoSalvo.isEmpty) {
      return [];
    }

    try {
      final listaJson = jsonDecode(textoSalvo) as List<dynamic>;

      return listaJson
          .map(
            (item) => Conferencia.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> salvarConferencias(
    List<Conferencia> conferencias,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    final texto = jsonEncode(
      conferencias.map((conferencia) => conferencia.toJson()).toList(),
    );

    await preferences.setString(_chaveConferencias, texto);
  }
}