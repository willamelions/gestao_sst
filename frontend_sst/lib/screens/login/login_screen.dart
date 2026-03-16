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
  TextEditingController emailCtrl = TextEditingController(text: "enfermeira@sst.com"); // Já preenchido pra facilitar o teste
  TextEditingController senhaCtrl = TextEditingController(text: "123");
  bool carregando = false;

  Future<void> fazerLogin() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/auth/login");
      var resposta = await http.post(
        url, headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text, "senha": senhaCtrl.text}),
      );

      if (resposta.statusCode == 200) {
        var dados = jsonDecode(resposta.body);
        // Guarda na memória do aplicativo quem está logado!
        Sessao.nome = dados['nome'];
        Sessao.perfilNome = dados['perfil_nome'];
        Sessao.isAdmin = dados['is_admin'] == 1;
        Sessao.fapEditar = dados['fap_editar'] == 1;
        Sessao.absenteismoEditar = dados['absenteismo_editar'] == 1;

        // Vai para a tela do Sistema
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LayoutBase()));
      } else {
        var erro = jsonDecode(resposta.body)['erro'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro de conexão."), backgroundColor: Colors.red));
    }
    setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Container(
          width: 400, padding: EdgeInsets.all(40),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              Icon(Icons.health_and_safety, size: 80, color: Colors.blue[800]),
              SizedBox(height: 10),
              Text("SISTEMA SST", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
              SizedBox(height: 30),
              TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "E-mail", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              SizedBox(height: 15),
              TextField(controller: senhaCtrl, obscureText: true, decoration: InputDecoration(labelText: "Senha", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              SizedBox(height: 20),
              carregando 
                ? CircularProgressIndicator() 
                : SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                      onPressed: fazerLogin, child: Text("ENTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}