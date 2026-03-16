import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sessao.dart'; // <--- IMPORTA A SESSÃO DINÂMICA

class FapScreen extends StatefulWidget {
  @override
  _FapScreenState createState() => _FapScreenState();
}

class _FapScreenState extends State<FapScreen> {
  List<dynamic> listaFap =[];
  bool carregando = true;
  String empresaSelecionada = "1"; 

  TextEditingController anoCtrl = TextEditingController();
  TextEditingController fapCtrl = TextEditingController();
  TextEditingController freqCtrl = TextEditingController();
  TextEditingController gravCtrl = TextEditingController();
  TextEditingController custoCtrl = TextEditingController();

  TextEditingController simFapAtualCtrl = TextEditingController(text: "1.20");
  TextEditingController simFapNovoCtrl = TextEditingController(text: "0.70");
  TextEditingController simFolhaCtrl = TextEditingController(text: "1000000"); 
  
  double economiaSimulada = 0;
  double tributacaoAtualSimulada = 0;
  double tributacaoNovaSimulada = 0;

  @override
  void initState() {
    super.initState();
    buscarHistorico();
    calcularSimulacao();
  }

  Future<void> buscarHistorico() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("https://meu-sst-backend.onrender.com/api/fap/historico/$empresaSelecionada");
      var resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        setState(() {
          listaFap = jsonDecode(resposta.body);
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  Future<void> salvarFap() async {
    // 1. Trava de Visão Geral
    if (empresaSelecionada == "0") {
      _mostrarAviso("Selecione um CNPJ específico no topo para registrar um FAP.", Colors.red);
      return;
    }
    
    // 2. Trava de Permissão (Segurança do Banco de Dados)
    if (!Sessao.fapEditar) {
      _mostrarAviso("Você não tem permissão para editar o FAP.", Colors.red);
      return;
    }

    if (anoCtrl.text.isEmpty || fapCtrl.text.isEmpty || freqCtrl.text.isEmpty || gravCtrl.text.isEmpty || custoCtrl.text.isEmpty) {
      _mostrarAviso("Todos os campos do formulário são obrigatórios!", Colors.red); return;
    }
    
    double valorFap = double.tryParse(fapCtrl.text.replaceAll(',', '.')) ?? 0;
    if (valorFap < 0.5000 || valorFap > 2.0000) {
      _mostrarAviso("O FAP deve estar entre 0.5000 e 2.0000.", Colors.red); return;
    }

    setState(() => carregando = true);
    var url = Uri.parse("https://meu-sst-backend.onrender.com/api/fap/registrar");
    var resposta = await http.post(
      url, headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "empresa_id": int.parse(empresaSelecionada), "ano": anoCtrl.text, "fap": valorFap,
        "ind_frequencia": double.parse(freqCtrl.text.replaceAll(',', '.')),
        "ind_gravidade": double.parse(gravCtrl.text.replaceAll(',', '.')),
        "ind_custo": double.parse(custoCtrl.text.replaceAll(',', '.'))
      }),
    );

    if (resposta.statusCode == 400) {
      var erro = jsonDecode(resposta.body)['erro'];
      _mostrarAviso(erro, Colors.red);
      setState(() => carregando = false);
    } else {
      anoCtrl.clear(); fapCtrl.clear(); freqCtrl.clear(); gravCtrl.clear(); custoCtrl.clear();
      buscarHistorico();
      _mostrarAviso("FAP Registrado com sucesso!", Colors.green);
    }
  }

  Future<void> excluirFap(int id) async {
    setState(() => carregando = true);
    var url = Uri.parse("https://meu-sst-backend.onrender.com/api/fap/excluir/$id");
    await http.delete(url);
    buscarHistorico();
    _mostrarAviso("Registro excluído com sucesso.", Colors.green);
  }

  void calcularSimulacao() {
    double fapAtual = double.tryParse(simFapAtualCtrl.text.replaceAll(',', '.')) ?? 0;
    double fapNovo = double.tryParse(simFapNovoCtrl.text.replaceAll(',', '.')) ?? 0;
    double folha = double.tryParse(simFolhaCtrl.text.replaceAll(',', '.')) ?? 0;
    double ratBase = 3.0; 
    double tributoAtual = folha * ((ratBase * fapAtual) / 100);
    double tributoNovo = folha * ((ratBase * fapNovo) / 100);
    
    setState(() { 
      tributacaoAtualSimulada = tributoAtual;
      tributacaoNovaSimulada = tributoNovo;
      economiaSimulada = tributoAtual - tributoNovo; 
    });
  }

  Color _corFap(double fap) {
    if (fap <= 0.9) return Colors.green; 
    if (fap <= 1.2) return Colors.orange; 
    return Colors.red; 
  }
  
  String _statusFap(double fap) {
    if (fap <= 0.9) return "Excelente";
    if (fap <= 1.2) return "Médio";
    return "Alto Risco";
  }

  String formatarDinheiro(double valor) {
    String valorString = valor.toStringAsFixed(2);
    List<String> partes = valorString.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return "R\$ ${partes[0].replaceAllMapped(reg, (Match m) => '${m[1]}.')},${partes[1]}";
  }

  void _mostrarAviso(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Módulo: FAP - Olá, ${Sessao.nome} (${Sessao.perfilNome})", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white, elevation: 1,
        actions:[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: DropdownButton<String>(
              value: empresaSelecionada, underline: Container(),
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              items:[
                DropdownMenuItem(value: "0", child: Text("👁️ Visão Geral")),
                DropdownMenuItem(value: "1", child: Text("🏢 SERVIÇOS")),
                DropdownMenuItem(value: "2", child: Text("🛡️ SEGURANÇA")),
                DropdownMenuItem(value: "3", child: Text("🔌 ELETRÔNICA")),
              ],
              onChanged: (valor) {
                if (valor != null) { setState(() => empresaSelecionada = valor); buscarHistorico(); }
              },
            ),
          )
        ],
      ),
      body: carregando 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    // 1. FORMULÁRIO DE REGISTRO
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text("Registrar Novo FAP Anual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(height: 30),
                            
                            // ==== TRAVA DE SEGURANÇA VISUAL ====
                            if (!Sessao.fapEditar)
                              Container(
                                padding: EdgeInsets.all(15), color: Colors.orange[100],
                                child: Row(children:[Icon(Icons.lock, color: Colors.orange[800]), SizedBox(width: 10), Expanded(child: Text("O seu perfil de ${Sessao.perfilNome} não tem permissão para alterar o FAP.", style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold)))]),
                              ),

                            // SE TIVER PERMISSÃO, MOSTRA O FORMULÁRIO
                            if (Sessao.fapEditar) ...[
                              _campoTexto(anoCtrl, "Ano (Ex: 2026)", Icons.calendar_today, false),
                              _campoTexto(fapCtrl, "Valor do FAP (0.5000 a 2.0000)", Icons.trending_up, false),
                              _campoTexto(freqCtrl, "Índice de Frequência", Icons.show_chart, false),
                              _campoTexto(gravCtrl, "Índice de Gravidade", Icons.warning_amber, false),
                              _campoTexto(custoCtrl, "Índice de Custo", Icons.attach_money, false),
                              SizedBox(height: 20),
                              SizedBox(width: double.infinity, height: 45,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.save), label: Text("Salvar Registro Oficial", style: TextStyle(fontSize: 16)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                                  onPressed: salvarFap,
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),

                    // 2. GRÁFICOS E SIMULADOR
                    Expanded(
                      flex: 2,
                      child: Column(
                        children:[
                          Container(
                            height: 250, padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Text("Evolução Histórica do FAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 10), Expanded(child: _criarGraficoLinhaFap()),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children:[Icon(Icons.calculate, color: Colors.greenAccent), SizedBox(width: 10), Text("Simulador e Projeção Futura", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]),
                                SizedBox(height: 20),
                                Row(
                                  children:[
                                    Expanded(child: _campoTexto(simFapAtualCtrl, "FAP Atual (Ex: 1.20)", Icons.trending_flat, true)), SizedBox(width: 10),
                                    Expanded(child: _campoTexto(simFapNovoCtrl, "FAP Simulado (Ex: 0.70)", Icons.trending_down, true)), SizedBox(width: 10),
                                    Expanded(child: _campoTexto(simFolhaCtrl, "Folha Salarial Anual", Icons.payments, true)),
                                  ],
                                ),
                                Divider(color: Colors.grey[700]),
                                Row(
                                  children:[
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:[
                                          Text("Economia Anual Projetada:", style: TextStyle(color: Colors.white, fontSize: 16)),
                                          SizedBox(height: 5), Text(formatarDinheiro(economiaSimulada), style: TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 10), Text("Tributação Atual: ${formatarDinheiro(tributacaoAtualSimulada)}", style: TextStyle(color: Colors.red[300], fontSize: 12)),
                                          Text("Tributação Nova: ${formatarDinheiro(tributacaoNovaSimulada)}", style: TextStyle(color: Colors.blue[300], fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Expanded(flex: 1, child: SizedBox(height: 100, child: _criarGraficoBarrasProjecao()))
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 30),

                // 3. TABELA HISTÓRICA
                Container(
                  width: double.infinity, padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text("Histórico Registrado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Divider(height: 30),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                                columns:[
                                  DataColumn(label: Text('Ano', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('FAP', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('RAT Ajustado', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Frequência', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Gravidade', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Custo', style: TextStyle(fontWeight: FontWeight.bold))),
                                  // SÓ MOSTRA A COLUNA "AÇÃO" SE O CARA PUDER EDITAR
                                  if (Sessao.fapEditar) DataColumn(label: Text('Ação', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: listaFap.map((item) {
                                  double valFap = double.parse(item['fap'].toString());
                                  return DataRow(cells:[
                                    DataCell(Text(item['ano'].toString(), style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(valFap.toStringAsFixed(4), style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Row(children:[Icon(Icons.circle, color: _corFap(valFap), size: 14), SizedBox(width: 5), Text(_statusFap(valFap), style: TextStyle(color: _corFap(valFap), fontWeight: FontWeight.bold))])),
                                    DataCell(Text("${(valFap * 3.0).toStringAsFixed(4)}%", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]))),
                                    DataCell(Text(double.parse(item['ind_frequencia'].toString()).toStringAsFixed(4))),
                                    DataCell(Text(double.parse(item['ind_gravidade'].toString()).toStringAsFixed(4))),
                                    DataCell(Text(double.parse(item['ind_custo'].toString()).toStringAsFixed(4))),
                                    // SÓ MOSTRA O BOTÃO DE EXCLUIR SE O CARA PUDER EDITAR
                                    if (Sessao.fapEditar) DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => excluirFap(item['id']))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        }
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }

  Widget _campoTexto(TextEditingController ctrl, String rotulo, IconData icone, bool escuro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: ctrl, onChanged: (val) { if (escuro) calcularSimulacao(); }, 
        style: TextStyle(color: escuro ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: rotulo, labelStyle: TextStyle(color: escuro ? Colors.grey[400] : Colors.grey[700]),
          prefixIcon: Icon(icone, color: escuro ? Colors.greenAccent : Colors.blueGrey),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: escuro ? Colors.grey[700]! : Colors.grey[400]!), borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: escuro ? Colors.greenAccent : Colors.blue), borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15)
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _criarGraficoLinhaFap() {
    if (listaFap.isEmpty) return Center(child: Text("Nenhum dado registrado."));
    List<FlSpot> pontos = listaFap.map((i) => FlSpot(double.parse(i['ano'].toString()), double.parse(i['fap'].toString()))).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
        lineBarsData:[LineChartBarData(spots: pontos, isCurved: true, color: Colors.purple, barWidth: 4, isStrokeCapRound: true, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: true, color: Colors.purple.withOpacity(0.1)))],
      )
    );
  }

  Widget _criarGraficoBarrasProjecao() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: tributacaoAtualSimulada > 0 ? tributacaoAtualSimulada * 1.2 : 100,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) { return Text(val.toInt() == 0 ? "Atual" : "Projetado", style: TextStyle(color: Colors.white, fontSize: 10)); })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups:[
          BarChartGroupData(x: 0, barRods:[BarChartRodData(toY: tributacaoAtualSimulada, color: Colors.red[400], width: 30, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods:[BarChartRodData(toY: tributacaoNovaSimulada, color: Colors.blue[400], width: 30, borderRadius: BorderRadius.circular(4))]),
        ]
      )
    );
  }
}