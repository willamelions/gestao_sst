import 'package:flutter/material.dart';
import '../../services/sessao.dart';
import '../../services/api.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  bool carregando = true;

  List<dynamic> usuarios = [];
  List<dynamic> perfis = [];

  // FORM USUÁRIO
  TextEditingController nomeCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController senhaCtrl = TextEditingController();

  String? perfilSelecionado;

  // FORM PERFIL
  TextEditingController nomePerfilCtrl = TextEditingController();

  bool checkAdmin = false;
  bool checkFap = false;
  bool checkAbsenteismo = false;

  @override
  void initState() {
    super.initState();
    buscarDados();
  }

  // =============================
  // BUSCAR DADOS
  // =============================

  Future<void> buscarDados() async {

    setState(() => carregando = true);

    try {

      var resUsuarios = await Api.get("admin/usuarios");
      var resPerfis = await Api.get("admin/perfis");

      setState(() {

        usuarios = resUsuarios;
        perfis = resPerfis;

        if (perfis.isNotEmpty) {

          bool existe = perfis.any((p) => p['id'].toString() == perfilSelecionado);

          if (!existe) {
            perfilSelecionado = perfis[0]['id'].toString();
          }

        } else {

          perfilSelecionado = null;

        }

        carregando = false;

      });

    } catch (e) {

      setState(() => carregando = false);

      _aviso("Erro ao carregar dados do servidor", Colors.red);

    }

  }

  // =============================
  // SALVAR USUÁRIO
  // =============================

  Future<void> salvarUsuario() async {

    if (nomeCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        senhaCtrl.text.isEmpty ||
        perfilSelecionado == null) {

      _aviso("Preencha todos os campos!", Colors.red);
      return;

    }

    setState(() => carregando = true);

    try {

      await Api.post("admin/usuarios", {
        "nome": nomeCtrl.text,
        "email": emailCtrl.text,
        "senha": senhaCtrl.text,
        "perfil_id": int.parse(perfilSelecionado!)
      });

      nomeCtrl.clear();
      emailCtrl.clear();
      senhaCtrl.clear();

      buscarDados();

      _aviso("Usuário criado com sucesso!", Colors.green);

    } catch (e) {

      setState(() => carregando = false);
      _aviso("Erro ao criar usuário", Colors.red);

    }

  }

  // =============================
  // EXCLUIR USUÁRIO
  // =============================

  Future<void> excluirUsuario(int id) async {

    setState(() => carregando = true);

    try {

      await Api.delete("admin/usuarios/$id");

      buscarDados();

      _aviso("Usuário excluído.", Colors.green);

    } catch (e) {

      setState(() => carregando = false);

      _aviso("Erro ao excluir usuário", Colors.red);

    }

  }

  // =============================
  // SALVAR PERFIL
  // =============================

  Future<void> salvarPerfil() async {

    if (nomePerfilCtrl.text.isEmpty) {

      _aviso("Digite um nome para o perfil.", Colors.red);
      return;

    }

    setState(() => carregando = true);

    try {

      await Api.post("admin/perfis", {
        "nome": nomePerfilCtrl.text,
        "is_admin": checkAdmin,
        "fap_editar": checkFap,
        "absenteismo_editar": checkAbsenteismo
      });

      nomePerfilCtrl.clear();

      setState(() {

        checkAdmin = false;
        checkFap = false;
        checkAbsenteismo = false;

      });

      buscarDados();

      _aviso("Perfil criado com sucesso!", Colors.green);

    } catch (e) {

      setState(() => carregando = false);

      _aviso("Erro ao criar perfil", Colors.red);

    }

  }

  // =============================
  // EXCLUIR PERFIL
  // =============================

  Future<void> excluirPerfil(int id) async {

    setState(() => carregando = true);

    try {

      await Api.delete("admin/perfis/$id");

      buscarDados();

      _aviso("Perfil excluído.", Colors.green);

    } catch (e) {

      setState(() => carregando = false);

      _aviso("Erro ao excluir perfil", Colors.red);

    }

  }

  // =============================
  // ALERTA
  // =============================

  void _aviso(String msg, Color cor) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor
      )
    );

  }

  // =============================
  // ICONE BOOLEANO
  // =============================

  Widget _iconeBool(int valor) {

    return valor == 1
        ? Icon(Icons.check_circle, color: Colors.green)
        : Icon(Icons.cancel, color: Colors.red);

  }

  // =============================
  // BUILD
  // =============================

  @override
  Widget build(BuildContext context) {

    if (carregando) {

      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

    }

    if (!Sessao.isAdmin) {

      return Scaffold(
        body: Center(
          child: Text(
            "Acesso Negado! Apenas Gestores podem acessar.",
            style: TextStyle(
              color: Colors.red,
              fontSize: 22,
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      );

    }

    return DefaultTabController(

      length: 2,

      child: Scaffold(

        backgroundColor: Colors.grey[100],

        appBar: AppBar(

          title: Text(
            "Administração e Gestão de Acessos",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold
            ),
          ),

          backgroundColor: Colors.white,

          bottom: TabBar(

            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue[800],

            tabs: [

              Tab(icon: Icon(Icons.people), text: "Usuários"),

              Tab(icon: Icon(Icons.security), text: "Perfis")

            ],

          ),

        ),

        body: TabBarView(

          children: [

            Center(child: Text("Tela de usuários carregada")),
            Center(child: Text("Tela de perfis carregada"))

          ],

        ),

      ),

    );

  }

}