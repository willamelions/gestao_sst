import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/sessao.dart'; // Import da Sessão

class AcidentesScreen extends StatefulWidget {
  @override
  _AcidentesScreenState createState() => _AcidentesScreenState();
}

class _AcidentesScreenState extends State<AcidentesScreen> {
  List<dynamic> listaAcidentes =[];
  bool carregando = true;
  String empresaSelecionada = "1"; // Filtro de Empresa

  @override
  void initState() {
    super.initState();
    buscarAcidentes();
  }

  Future<void> buscarAcidentes() async {
    setState(() => carregando = true);
    try {
      // Se for "0" (Visão Geral), nós mandamos o ID que o backend trata ou filtramos no Node
      // Para listar acidentes, geralmente queremos de uma empresa específica.
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/acidentes/listar/$empresaSelecionada");
      
      // Se o usuário selecionou Visão Geral, para evitar travar com 10.000 linhas,
      // O ideal é ver por empresa. Mas vamos deixar mandar o 0 caso você implemente depois.
      if(empresaSelecionada == "0") {
         setState(() { listaAcidentes =[]; carregando = false; });
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selecione um CNPJ específico para listar a tabela de acidentes."), backgroundColor: Colors.orange));
         return;
      }

      var resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        setState(() {
          listaAcidentes = jsonDecode(resposta.body);
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  // ================= EXCLUIR TUDO DE UMA VEZ =================
  Future<void> excluirTudo() async {
    if (empresaSelecionada == "0") return;

    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🚨 APAGAR BASE DE DADOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Tem certeza absoluta que deseja apagar TODOS os acidentes desta empresa? Esta ação não pode ser desfeita."),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: Text("SIM, APAGAR TUDO!", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;

    if (confirmar) {
      setState(() => carregando = true);
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/acidentes/apagar-tudo/$empresaSelecionada");
      await http.delete(url);
      buscarAcidentes(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Base de dados apagada com sucesso!"), backgroundColor: Colors.green));
    }
  }

  Future<void> excluirAcidente(int id) async {
    setState(() => carregando = true);
    var url = Uri.parse("https://meu-sst-backend.onrender.com/api/acidentes/excluir/$id");
    await http.delete(url);
    buscarAcidentes(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Registro de Acidentes", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions:[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: DropdownButton<String>(
              value: empresaSelecionada,
              underline: Container(),
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              items:[
                DropdownMenuItem(value: "0", child: Text("👁️ Selecione uma Empresa...")),
                DropdownMenuItem(value: "1", child: Text("🏢 SERVIÇOS")),
                DropdownMenuItem(value: "2", child: Text("🛡️ SEGURANÇA")),
                DropdownMenuItem(value: "3", child: Text("🔌 ELETRÔNICA")),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => empresaSelecionada = valor);
                  buscarAcidentes();
                }
              },
            ),
          )
        ],
      ),
      body: carregando
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  
                  // TOPO DA TELA (TÍTULO E BOTÃO APAGAR TUDO)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text("Todos os Acidentes Cadastrados", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (Sessao.isAdmin && empresaSelecionada != "0" && listaAcidentes.isNotEmpty)
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete_forever),
                          label: Text("Apagar Todos os Acidentes", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white),
                          onPressed: excluirTudo,
                        )
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // A TABELA
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(8),
                        boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (listaAcidentes.isEmpty) return Center(child: Text("Nenhum acidente encontrado para esta empresa.", style: TextStyle(fontSize: 16, color: Colors.grey)));
                          
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columnSpacing: MediaQuery.of(context).size.width * 0.05, 
                                  headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                                  columns:[
                                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Funcionário', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Dias', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Ano/Mês', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Município', style: TextStyle(fontWeight: FontWeight.bold))),
                                    if (Sessao.isAdmin) DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: listaAcidentes.map((acidente) {
                                    return DataRow(cells: [
                                      DataCell(Text(acidente['id'].toString())),
                                      DataCell(Text(acidente['funcionario'] ?? 'Não informado')),
                                      DataCell(Text(acidente['tipo_acidente'] ?? '-')),
                                      DataCell(Text(acidente['duracao_tratamento'].toString())),
                                      DataCell(Text("${acidente['ano']}/${acidente['mes']}")),
                                      DataCell(Text(acidente['municipio'] ?? '-')),
                                      if (Sessao.isAdmin) DataCell(
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          tooltip: "Excluir",
                                          onPressed: () => excluirAcidente(acidente['id']),
                                        )
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}