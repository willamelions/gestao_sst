import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/sessao.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool carregando = true;
  List<dynamic> usuarios = [];
  List<dynamic> perfis =[];

  // Variáveis Formulário Usuário
  TextEditingController nomeCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController senhaCtrl = TextEditingController();
  String? perfilSelecionado;

  // Variáveis Formulário NOVO PERFIL
  TextEditingController nomePerfilCtrl = TextEditingController();
  bool checkAdmin = false;
  bool checkFap = false;
  bool checkAbsenteismo = false;

  @override
  void initState() {
    super.initState();
    buscarDados();
  }

  Future<void> buscarDados() async {
    setState(() => carregando = true);
    try {
      var resUsuarios = await http.get(Uri.parse("https://meu-sst-backend.onrender.com/api/admin/usuarios"));
      var resPerfis = await http.get(Uri.parse("https://meu-sst-backend.onrender.com/api/admin/perfis"));
      
      if (resUsuarios.statusCode == 200 && resPerfis.statusCode == 200) {
        setState(() {
          usuarios = jsonDecode(resUsuarios.body);
          perfis = jsonDecode(resPerfis.body);
          
          // Mantém o perfil selecionado válido, ou pega o primeiro
          if (perfis.isNotEmpty) {
            bool aindaExiste = perfis.any((p) => p['id'].toString() == perfilSelecionado);
            if (!aindaExiste) perfilSelecionado = perfis[0]['id'].toString();
          } else {
            perfilSelecionado = null;
          }
          
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  // ===================== FUNÇÕES DE USUÁRIO =====================
  Future<void> salvarUsuario() async {
    if (nomeCtrl.text.isEmpty || emailCtrl.text.isEmpty || senhaCtrl.text.isEmpty || perfilSelecionado == null) {
      _aviso("Preencha todos os campos!", Colors.red); return;
    }

    setState(() => carregando = true);
    var res = await http.post(
      Uri.parse("https://meu-sst-backend.onrender.com/api/admin/usuarios"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nome": nomeCtrl.text, "email": emailCtrl.text, "senha": senhaCtrl.text, "perfil_id": int.parse(perfilSelecionado!)}),
    );

    if (res.statusCode == 400) {
      _aviso(jsonDecode(res.body)['erro'], Colors.red);
      setState(() => carregando = false);
    } else {
      nomeCtrl.clear(); emailCtrl.clear(); senhaCtrl.clear();
      buscarDados();
      _aviso("Usuário criado com sucesso!", Colors.green);
    }
  }

  Future<void> excluirUsuario(int id) async {
    setState(() => carregando = true);
    await http.delete(Uri.parse("https://meu-sst-backend.onrender.com/api/admin/usuarios/$id"));
    buscarDados();
    _aviso("Usuário excluído.", Colors.green);
  }

  // ===================== FUNÇÕES DE PERFIL =====================
  Future<void> salvarPerfil() async {
    if (nomePerfilCtrl.text.isEmpty) {
      _aviso("Digite um nome para o perfil (Ex: Médico Coordenador).", Colors.red); return;
    }

    setState(() => carregando = true);
    var res = await http.post(
      Uri.parse("https://meu-sst-backend.onrender.com/api/admin/perfis"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nome": nomePerfilCtrl.text, 
        "is_admin": checkAdmin, 
        "fap_editar": checkFap, 
        "absenteismo_editar": checkAbsenteismo
      }),
    );

    nomePerfilCtrl.clear();
    setState(() { checkAdmin = false; checkFap = false; checkAbsenteismo = false; });
    buscarDados();
    _aviso("Perfil de Acesso criado com sucesso!", Colors.green);
  }

  Future<void> excluirPerfil(int id) async {
    setState(() => carregando = true);
    var res = await http.delete(Uri.parse("https://meu-sst-backend.onrender.com/api/admin/perfis/$id"));
    
    if (res.statusCode == 400) {
      _aviso(jsonDecode(res.body)['erro'], Colors.red);
      setState(() => carregando = false);
    } else {
      buscarDados();
      _aviso("Perfil excluído.", Colors.green);
    }
  }

  void _aviso(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  // Widget ajudante para não repetir código na tabela
  Widget _iconeBool(int valor) {
    return valor == 1 ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.cancel, color: Colors.red[300]);
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) return Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!Sessao.isAdmin) {
      return Scaffold(body: Center(child: Text("Acesso Negado! Apenas Gestores podem acessar.", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold))));
    }

    // Usando DefaultTabController para criar as Abas
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text("Administração e Gestão de Acessos", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.white, elevation: 1,
          bottom: TabBar(
            labelColor: Colors.blue[800],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue[800],
            tabs:[
              Tab(icon: Icon(Icons.people), text: "Logins de Usuários"),
              Tab(icon: Icon(Icons.security), text: "Perfis e Permissões (Acessos)"),
            ],
          ),
        ),
        body: TabBarView(
          children:[
            // ================= ABA 1: LOGINS E USUÁRIOS =================
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(children:[Icon(Icons.person_add, color: Colors.blue), SizedBox(width: 10), Text("Criar Novo Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          Divider(height: 30),
                          TextField(controller: nomeCtrl, decoration: InputDecoration(labelText: "Nome Completo", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())), SizedBox(height: 15),
                          TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "E-mail de Acesso", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())), SizedBox(height: 15),
                          TextField(controller: senhaCtrl, obscureText: true, decoration: InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())), SizedBox(height: 15),
                          
                          DropdownButtonFormField<String>(
                            value: perfilSelecionado,
                            decoration: InputDecoration(labelText: "Perfil de Acesso", border: OutlineInputBorder(), prefixIcon: Icon(Icons.security)),
                            items: perfis.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['nome']))).toList(),
                            onChanged: (v) => setState(() => perfilSelecionado = v),
                          ),
                          SizedBox(height: 20),
                          SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(icon: Icon(Icons.save), label: Text("Salvar Usuário"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white), onPressed: salvarUsuario))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(children:[Icon(Icons.group, color: Colors.blueGrey), SizedBox(width: 10), Text("Usuários Cadastrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          Divider(height: 30),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                              columns:[
                                DataColumn(label: Text('Nome')), DataColumn(label: Text('E-mail')),
                                DataColumn(label: Text('Perfil Vinculado')), DataColumn(label: Text('Ação')),
                              ],
                              rows: usuarios.map((u) {
                                return DataRow(cells:[
                                  DataCell(Text(u['nome'], style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(u['email'])),
                                  DataCell(Chip(label: Text(u['perfil_nome'] ?? 'Sem perfil', style: TextStyle(color: Colors.white)), backgroundColor: Colors.blue[400])),
                                  DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => excluirUsuario(u['id']))),
                                ]);
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // ================= ABA 2: PERFIS E CAIXINHAS DE PERMISSÃO =================
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[800]!, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(children:[Icon(Icons.settings, color: Colors.blue[800]), SizedBox(width: 10), Text("Criar Perfil de Acessos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]))]),
                          Divider(height: 30),
                          
                          TextField(controller: nomePerfilCtrl, decoration: InputDecoration(labelText: "Nome do Perfil (Ex: Médico Coordenador)", prefixIcon: Icon(Icons.label), border: OutlineInputBorder())), 
                          SizedBox(height: 20),
                          
                          Text("Marque o que este perfil pode acessar:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          SizedBox(height: 10),
                          
                          // CAIXINHAS DE PERMISSÃO
                          CheckboxListTile(
                            title: Text("Acesso de Administrador/Gestor Master", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Pode criar e excluir usuários e perfis."),
                            activeColor: Colors.red,
                            value: checkAdmin,
                            onChanged: (v) => setState(() => checkAdmin = v!),
                          ),
                          CheckboxListTile(
                            title: Text("Pode Editar FAP e RAT"),
                            activeColor: Colors.blue,
                            value: checkFap,
                            onChanged: (v) => setState(() => checkFap = v!),
                          ),
                          CheckboxListTile(
                            title: Text("Pode Editar Absenteísmo e Atestados"),
                            activeColor: Colors.blue,
                            value: checkAbsenteismo,
                            onChanged: (v) => setState(() => checkAbsenteismo = v!),
                          ),
                          
                          SizedBox(height: 20),
                          SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(icon: Icon(Icons.security), label: Text("Salvar Perfil de Acesso"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white), onPressed: salvarPerfil))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
                          Row(children:[Icon(Icons.list_alt, color: Colors.blueGrey), SizedBox(width: 10), Text("Lista de Perfis Cadastrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                          Divider(height: 30),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                              columns:[
                                DataColumn(label: Text('Nome do Perfil')), 
                                DataColumn(label: Text('Admin?')),
                                DataColumn(label: Text('Editar FAP?')), 
                                DataColumn(label: Text('Editar Absent.?')), 
                                DataColumn(label: Text('Ação')),
                              ],
                              rows: perfis.map((p) {
                                return DataRow(cells:[
                                  DataCell(Text(p['nome'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]))),
                                  DataCell(_iconeBool(p['is_admin'])),
                                  DataCell(_iconeBool(p['fap_editar'])),
                                  DataCell(_iconeBool(p['absenteismo_editar'])),
                                  DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => excluirPerfil(p['id']))),
                                ]);
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}