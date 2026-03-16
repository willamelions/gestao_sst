import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; 
import '../../services/sessao.dart';

class AbsenteismoScreen extends StatefulWidget {
  @override
  _AbsenteismoScreenState createState() => _AbsenteismoScreenState();
}

class _AbsenteismoScreenState extends State<AbsenteismoScreen> {
  bool carregando = true;
  Map<String, dynamic> dados = {};
  String empresaSelecionada = "1"; 

  TextEditingController funcCtrl = TextEditingController();
  TextEditingController motivoCtrl = TextEditingController();
  TextEditingController cidCtrl = TextEditingController();
  
  DateTime? dataInicio;
  DateTime? dataFim;
  int totalDias = 0;
  String tipoSelecionado = 'Médico'; 
  List<String> tiposAbsenteismo =['Médico', 'Acidente de Trabalho', 'Justificado', 'Injustificado'];

  @override
  void initState() { super.initState(); buscarDados(); }

  Future<void> buscarDados() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/absenteismo/indicadores/$empresaSelecionada");
      var resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        setState(() { dados = jsonDecode(resposta.body); carregando = false; });
      }
    } catch (e) { setState(() => carregando = false); }
  }

  void calcularDias() {
    if (dataInicio != null && dataFim != null) setState(() { totalDias = dataFim!.difference(dataInicio!).inDays + 1; });
  }

  Future<void> selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? escolhida = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (escolhida != null) {
      setState(() { if (isInicio) dataInicio = escolhida; else dataFim = escolhida; });
      calcularDias();
    }
  }

  Future<void> salvarRegistro() async {
    if (empresaSelecionada == "0") { _aviso("Selecione um CNPJ específico no topo.", Colors.red); return; }
    if (funcCtrl.text.isEmpty || dataInicio == null || dataFim == null || motivoCtrl.text.isEmpty) { _aviso("Preencha os campos obrigatórios.", Colors.red); return; }
    if (dataFim!.isBefore(dataInicio!)) { _aviso("Data Fim inválida.", Colors.red); return; }
    if (tipoSelecionado == 'Médico' && cidCtrl.text.isEmpty) { _aviso("CID Obrigatório.", Colors.red); return; }

    setState(() => carregando = true);
    var url = Uri.parse("https://meu-sst-backend.onrender.com/api/absenteismo/registrar");
    await http.post(url, headers: {"Content-Type": "application/json"},
      body: jsonEncode({"empresa_id": int.parse(empresaSelecionada), "funcionario": funcCtrl.text, "data_inicio": DateFormat('yyyy-MM-dd').format(dataInicio!), "data_fim": DateFormat('yyyy-MM-dd').format(dataFim!), "total_dias": totalDias, "tipo": tipoSelecionado, "motivo": motivoCtrl.text, "cid": cidCtrl.text}),
    );
    funcCtrl.clear(); motivoCtrl.clear(); cidCtrl.clear(); setState(() { dataInicio = null; dataFim = null; totalDias = 0; });
    buscarDados(); _aviso("Salvo com sucesso!", Colors.green);
  }

  Future<void> excluirRegistro(int id) async {
    setState(() => carregando = true);
    await http.delete(Uri.parse("https://meu-sst-backend.onrender.com/api/absenteismo/excluir/$id"));
    buscarDados(); _aviso("Excluído.", Colors.green);
  }

  void _aviso(String msg, Color cor) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor)); }
  Color _cor(double i) { if (i <= 2.0) return Colors.green; if (i <= 4.0) return Colors.orange; return Colors.red; }
  String _status(double i) { if (i <= 2.0) return "Saudável (Até 2%)"; if (i <= 4.0) return "Moderado (2% a 4%)"; return "Crítico (Acima de 4%)"; }

  @override
  Widget build(BuildContext context) {
    if (carregando) return Scaffold(body: Center(child: CircularProgressIndicator()));
    var kpis = dados['kpis']; double indAbs = double.parse(kpis['indice_absenteismo']);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Gestão de Absenteísmo - Olá, ${Sessao.nome} (${Sessao.perfilNome})", style: TextStyle(color: Colors.black87, fontSize: 16)), 
        backgroundColor: Colors.white, elevation: 1,
        actions:[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: DropdownButton<String>(
              value: empresaSelecionada, underline: Container(),
              items:[
                DropdownMenuItem(value: "0", child: Text("👁️ Visão Geral")),
                DropdownMenuItem(value: "1", child: Text("🏢 SERVIÇOS")),
                DropdownMenuItem(value: "2", child: Text("🛡️ SEGURANÇA")),
                DropdownMenuItem(value: "3", child: Text("🔌 ELETRÔNICA")),
              ],
              onChanged: (valor) { if (valor != null) { setState(() => empresaSelecionada = valor); buscarDados(); } },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Row(
              children:[
                Expanded(child: _cardKpi("Índice Absenteísmo", "${kpis['indice_absenteismo']}%", _cor(indAbs), _status(indAbs))), SizedBox(width: 15),
                Expanded(child: _cardKpi("Dias Perdidos", kpis['dias_perdidos'].toString(), Colors.blue, "Total ausentes")), SizedBox(width: 15),
                Expanded(child: _cardKpi("Taxa Frequência", kpis['taxa_frequencia'], Colors.purple, "Ausências / Trabalhadores")), SizedBox(width: 15),
                Expanded(child: _cardKpi("Taxa Gravidade", kpis['taxa_gravidade'], Colors.deepOrange, "Dias Perdidos / Trabalhadores")),
              ],
            ),
            SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                // LADO ESQUERDO: FORMULÁRIO
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text("Registrar Ausência / Atestado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Divider(),
                        
                        // BLOQUEIO DINÂMICO DE PERMISSÃO
                        if (!Sessao.absenteismoEditar)
                          Container(
                            padding: EdgeInsets.all(15), color: Colors.orange[100],
                            child: Row(children:[Icon(Icons.lock, color: Colors.orange[800]), SizedBox(width: 10), Expanded(child: Text("O seu perfil de ${Sessao.perfilNome} não tem permissão para editar Absenteísmos.", style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold)))]),
                          ),
                        
                        if (Sessao.absenteismoEditar) ...[
                          TextField(controller: funcCtrl, decoration: InputDecoration(labelText: "Funcionário", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())), SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: tipoSelecionado, decoration: InputDecoration(labelText: "Tipo", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                            items: tiposAbsenteismo.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => tipoSelecionado = v!),
                          ), SizedBox(height: 15),
                          Row(children:[
                            Expanded(child: ElevatedButton.icon(icon: Icon(Icons.date_range), label: Text(dataInicio == null ? "Início" : DateFormat('dd/MM').format(dataInicio!)), onPressed: () => selecionarData(context, true))), SizedBox(width: 10),
                            Expanded(child: ElevatedButton.icon(icon: Icon(Icons.date_range), label: Text(dataFim == null ? "Fim" : DateFormat('dd/MM').format(dataFim!)), onPressed: () => selecionarData(context, false))),
                          ]), SizedBox(height: 10),
                          TextField(controller: motivoCtrl, decoration: InputDecoration(labelText: "Motivo", prefixIcon: Icon(Icons.text_snippet), border: OutlineInputBorder())), SizedBox(height: 15),
                          if (tipoSelecionado == 'Médico') TextField(controller: cidCtrl, decoration: InputDecoration(labelText: "CID (Obrigatório)", prefixIcon: Icon(Icons.local_hospital), border: OutlineInputBorder())), SizedBox(height: 20),
                          SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(icon: Icon(Icons.save), label: Text("Salvar Registro"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white), onPressed: salvarRegistro))
                        ]
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                
                // LADO DIREITO: GRÁFICO DE PIZZA + TABELA
                Expanded(
                  flex: 2,
                  child: Column(
                    children:[
                      // O GRÁFICO VOLTOU AQUI!
                      Container(
                        height: 250, padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text("Top CIDs Recorrentes (Doenças)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Expanded(child: _criarGraficoCID()),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // TABELA
                      Container(
                        padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text("Histórico", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Divider(),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                                columns:[
                                  DataColumn(label: Text('Funcionário', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Tipo')), DataColumn(label: Text('CID')), DataColumn(label: Text('Período')), DataColumn(label: Text('Dias')),
                                  if (Sessao.absenteismoEditar) DataColumn(label: Text('Ação')),
                                ],
                                rows: (dados['lista'] as List).map((item) {
                                  return DataRow(cells:[
                                    DataCell(Text(item['funcionario'])), DataCell(Text(item['tipo'])), DataCell(Text(item['cid'] ?? '-')),
                                    DataCell(Text("${DateFormat('dd/MM').format(DateTime.parse(item['data_inicio']))} a ${DateFormat('dd/MM').format(DateTime.parse(item['data_fim']))}")),
                                    DataCell(Text(item['total_dias'].toString(), style: TextStyle(fontWeight: FontWeight.bold))),
                                    if (Sessao.absenteismoEditar) DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => excluirRegistro(item['id']))),
                                  ]);
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardKpi(String t, String v, Color c, String sub) { return Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border(bottom: BorderSide(color: c, width: 5)), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(t, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13)), SizedBox(height: 10), Text(v, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: c)), SizedBox(height: 5), Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500]))])); }

  Widget _criarGraficoCID() {
    List<dynamic> cids = dados['graficos']['top_cids'];
    if (cids.isEmpty) return Center(child: Text("Nenhum CID médico registrado."));
    List<Color> cores =[Colors.blue, Colors.orange, Colors.red, Colors.green, Colors.purple];
    
    return Row(
      children:[
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 2, centerSpaceRadius: 40,
            sections: cids.asMap().entries.map((entry) {
              return PieChartSectionData(color: cores[entry.key % cores.length], value: entry.value['total'].toDouble(), title: entry.value['total'].toString(), radius: 50, titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
            }).toList(),
          )),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: cids.asMap().entries.map((entry) {
            return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children:[ Container(width: 12, height: 12, color: cores[entry.key % cores.length]), SizedBox(width: 8), Text("CID: ${entry.value['cid']}", style: TextStyle(fontWeight: FontWeight.bold)) ]));
          }).toList(),
        )
      ],
    );
  }
}