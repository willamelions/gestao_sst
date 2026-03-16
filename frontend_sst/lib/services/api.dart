import 'package:http/http.dart' as http;
import 'dart:convert';

class Api {

  // ==============================
  // URL BASE DO BACKEND (RENDER)
  // ==============================

  static const String baseUrl = "https://gestao-sst.onrender.com/api";


  // ==============================
  // FUNÇÃO GET
  // ==============================

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return _processarResposta(response);

    } catch (e) {
      throw Exception("Erro ao conectar com o servidor.");
    }
  }


  // ==============================
  // FUNÇÃO POST
  // ==============================

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      return _processarResposta(response);

    } catch (e) {
      throw Exception("Erro ao conectar com o servidor.");
    }
  }


  // ==============================
  // FUNÇÃO PUT
  // ==============================

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(data),
      );

      return _processarResposta(response);

    } catch (e) {
      throw Exception("Erro ao conectar com o servidor.");
    }
  }


  // ==============================
  // FUNÇÃO DELETE
  // ==============================

  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      return _processarResposta(response);

    } catch (e) {
      throw Exception("Erro ao conectar com o servidor.");
    }
  }


  // ==============================
  // TRATAMENTO DE RESPOSTA
  // ==============================

  static dynamic _processarResposta(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Erro ${response.statusCode}: ${response.body}"
      );
    }
  }
}