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
  // === ATENÇÃO: COLOQUEI A URL DO SEU RENDER AQUI ===
  final String apiUrl = "https://gestao-sst.onrender.com"; 

  TextEditingController emailCtrl = TextEditingController(text: "admin@sst.com");
  TextEditingController senhaCtrl = TextEditingController(text: "123");
  bool carregando = false;

  // ==========================================
  // 1. FUNÇÃO DE FAZER LOGIN
  // ==========================================
  Future<void> fazerLogin() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("$apiUrl/api/auth/login");
      var resposta = await http.post(
        url, headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text, "senha": senhaCtrl.text}),
      );

      if (resposta.statusCode == 200) {
        var dados = jsonDecode(resposta.body);
        
        // Salva as permissões na sessão
        // Salva as permissões de forma 100% segura (Aceita 1 ou true)
        Sessao.nome = dados['nome'];
        Sessao.perfilNome = dados['perfil_nome'];
        Sessao.isAdmin = dados['is_admin'] == 1 || dados['is_admin'] == true;
        Sessao.fapEditar = dados['fap_editar'] == 1 || dados['fap_editar'] == true;
        Sessao.absenteismoEditar = dados['absenteismo_editar'] == 1 || dados['absenteismo_editar'] == true;
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LayoutBase()));
      } else {
        var erro = jsonDecode(resposta.body)['erro'] ?? "Erro de login";
        _mostrarAviso(erro, Colors.red);
      }
    } catch (e) {
      _mostrarAviso("Erro de conexão com o servidor na nuvem.", Colors.red);
    }
    setState(() => carregando = false);
  }

  // ==========================================
  // 2. MODAL DE RECUPERAR SENHA
  // ==========================================
  void abrirModalRecuperarSenha() {
    TextEditingController emailResetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Recuperar Senha"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Text("Digite seu e-mail abaixo. Enviaremos um link de recuperação (Simulação)."),
            SizedBox(height: 15),
            TextField(controller: emailResetCtrl, decoration: InputDecoration(labelText: "E-mail cadastrado", border: OutlineInputBorder())),
          ],
        ),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _mostrarAviso("Um link de recuperação foi enviado para ${emailResetCtrl.text}!", Colors.green);
            }, 
            child: Text("Enviar Link")
          )
        ],
      )
    );
  }

  // ==========================================
  // 3. MODAL DE CRIAR NOVA CONTA
  // ==========================================
  void abrirModalCriarConta() {
    TextEditingController nomeNovoCtrl = TextEditingController();
    TextEditingController emailNovoCtrl = TextEditingController();
    TextEditingController senhaNovaCtrl = TextEditingController();
    bool criando = false;

    showDialog(
      context: context,
      barrierDismissible: false, // O usuário não pode fechar clicando fora
      builder: (context) => StatefulBuilder( // StatefulBuilder para atualizar o Modal
        builder: (context, setStateModal) {
          return AlertDialog(
            title: Text("Criar Nova Conta"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:[
                  TextField(controller: nomeNovoCtrl, decoration: InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder())),
                  SizedBox(height: 15),
                  TextField(controller: emailNovoCtrl, decoration: InputDecoration(labelText: "E-mail", border: OutlineInputBorder())),
                  SizedBox(height: 15),
                  TextField(controller: senhaNovaCtrl, obscureText: true, decoration: InputDecoration(labelText: "Criar Senha", border: OutlineInputBorder())),
                  SizedBox(height: 15),
                  Text("Sua conta será criada como 'Usuário Padrão' e precisará de aprovação do Gestor para acessar módulos avançados.", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center,)
                ],
              ),
            ),
            actions:[
              if (!criando) TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
              
              criando 
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (nomeNovoCtrl.text.isEmpty || emailNovoCtrl.text.isEmpty || senhaNovaCtrl.text.isEmpty) {
                        _mostrarAviso("Preencha todos os campos!", Colors.red); return;
                      }

                      setStateModal(() => criando = true);

                      try {
                        // Envia para a nossa rota do Node.js de criar usuário (Perfil 2 = Usuário Padrão)
                        var res = await http.post(
                          Uri.parse("$apiUrl/api/admin/usuarios"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({"nome": nomeNovoCtrl.text, "email": emailNovoCtrl.text, "senha": senhaNovaCtrl.text, "perfil_id": 2}),
                        );

                        if (res.statusCode == 200) {
                          Navigator.pop(context);
                          _mostrarAviso("Conta criada com sucesso! Faça login.", Colors.green);
                        } else {
                          var erro = jsonDecode(res.body)['erro'];
                          _mostrarAviso(erro, Colors.red);
                          setStateModal(() => criando = false);
                        }
                      } catch (e) {
                        _mostrarAviso("Erro de conexão com o servidor.", Colors.red);
                        setStateModal(() => criando = false);
                      }
                    }, 
                    child: Text("Criar Minha Conta")
                  )
            ],
          );
        }
      )
    );
  }

  void _mostrarAviso(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Fundo escuro do sistema
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, padding: EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow:[BoxShadow(color: Colors.black26, blurRadius: 10)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                
                // === AQUI ENTRA A SUA LOGO ===
                // O Flutter vai tentar carregar a imagem. Se ela não existir ou o nome estiver errado, 
                // ele usa o ícone antigo como plano B para a tela não quebrar.
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.health_and_safety, size: 80, color: Colors.blue[800]);
                  },
                ),
                
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
                
                SizedBox(height: 20),
                Divider(),
                
                // === BOTÕES NOVOS (RECUPERAR E CRIAR CONTA) ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:[
                    TextButton(
                      onPressed: abrirModalRecuperarSenha,
                      child: Text("Esqueceu a senha?", style: TextStyle(color: Colors.blueGrey[700])),
                    ),
                    TextButton(
                      onPressed: abrirModalCriarConta,
                      child: Text("Criar uma conta", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}