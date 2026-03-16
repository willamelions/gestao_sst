import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/sessao.dart';
import '../layout/layout_base.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailCtrl = TextEditingController(text: "enfermeira@sst.com");
  TextEditingController senhaCtrl = TextEditingController(text: "123");
  bool carregando = false;

  Future<void> fazerLogin() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/auth/login");
      var resposta = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text, "senha": senhaCtrl.text}),
      );

      if (resposta.statusCode == 200) {
        var dados = jsonDecode(resposta.body);
        Sessao.nome = dados['nome'];
        Sessao.perfilNome = dados['perfil_nome'];
        Sessao.isAdmin = dados['is_admin'] == 1;
        Sessao.fapEditar = dados['fap_editar'] == 1;
        Sessao.absenteismoEditar = dados['absenteismo_editar'] == 1;

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LayoutBase()));
      } else {
        var erro = jsonDecode(resposta.body)['erro'] ?? "Falha no login";
        _mostrarAviso(erro, Colors.red);
      }
    } catch (e) {
      _mostrarAviso("Erro de conexão com o servidor.", Colors.red);
    }
    setState(() => carregando = false);
  }

  void _mostrarAviso(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo escuro conforme a logo
      backgroundColor: Color(0xFF1A1A1A), 
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === LOGO SEGURO ===
                // Se você tiver a imagem local use Image.asset('assets/logo.png')
                // Usei um Placeholder que simula sua logo amarela e preta
                Container(
                  height: 120,
                  child: Image.network(
                    "https://i.ibb.co/3ykM6vN/logo-seguro.png", // Substitua pelo link real ou asset
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.shield, size: 80, color: Colors.amber),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "GESTÃO SST",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.black, color: Color(0xFF1A1A1A)),
                ),
                Divider(height: 40, thickness: 1.2),

                // === CAMPOS DE LOGIN ===
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: "E-mail de Acesso",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: senhaCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                
                // === RESETAR ACESSO ===
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () { /* Lógica para recuperar senha */ },
                    child: Text("Esqueceu a senha?", style: TextStyle(color: Colors.blueGrey)),
                  ),
                ),

                SizedBox(height: 10),

                // === BOTÃO ENTRAR ===
                carregando
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFACC15), // Amarelo da logo
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: fazerLogin,
                          child: Text("ENTRAR NO SISTEMA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                
                SizedBox(height: 20),
                
                // === CRIAR CONTA ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Ainda não tem acesso?"),
                    TextButton(
                      onPressed: () { /* Lógica para criar conta */ },
                      child: Text("Criar Conta", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}