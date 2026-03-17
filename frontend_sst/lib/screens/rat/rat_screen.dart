import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RatScreen extends StatefulWidget {
  @override
  _RatScreenState createState() => _RatScreenState();
}

class _RatScreenState extends State<RatScreen> {
  bool carregando = true;
  Map<String, dynamic> dados = {};
  String empresaSelecionada = "1"; // Filtro de Empresa
  double fapSimulado = 0.5000; 

  @override
  void initState() {
    super.initState();
    buscarRelatorio();
  }

  Future<void> buscarRelatorio() async {
    setState(() => carregando = true);
    try {
      var url = Uri.parse("https://gestao-sst.onrender.com/api/fap/estrategico/$empresaSelecionada");
      var resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        setState(() {
          dados = jsonDecode(resposta.body);
          fapSimulado = double.parse(dados['estrategico']['fap_atual'].toString());
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  String formatarDinheiro(double valor) {
    String valorString = valor.toStringAsFixed(2);
    List<String> partes = valorString.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return "R\$ ${partes[0].replaceAllMapped(reg, (Match m) => '${m[1]}.')},${partes[1]}";
  }

  void exportar(String formato) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exportando relatório em $formato..."), backgroundColor: Colors.blue));
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) return Scaffold(body: Center(child: CircularProgressIndicator()));

    double folhaAnual = double.parse(dados['estrategico']['folha_anual'].toString());
    double ratCnae = double.parse(dados['estrategico']['rat_cnae'].toString());
    double economiaPrevidenciaria = double.parse(dados['estrategico']['economia_previdenciaria'].toString());
    
    double novoRatAjustado = ratCnae * fapSimulado;
    double novaTributacao = folhaAnual * (novoRatAjustado / 100);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Relatório Estratégico FAP x RAT", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white, elevation: 1,
        actions:[
          IconButton(icon: Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: () => exportar("PDF"), tooltip: "Exportar PDF"),
          IconButton(icon: Icon(Icons.table_chart, color: Colors.green), onPressed: () => exportar("Excel"), tooltip: "Exportar Excel"),
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
                if (valor != null) { setState(() => empresaSelecionada = valor); buscarRelatorio(); }
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children:[
                  Icon(Icons.precision_manufacturing, color: Colors.white), SizedBox(width: 10),
                  Text("SIMULAÇÃO ESTRATÉGICA:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Spacer(),
                  _btnSimulador("FAP Oficial (${dados['estrategico']['fap_atual']})", double.parse(dados['estrategico']['fap_atual'].toString())),
                  _btnSimulador("Simular FAP 0.5 (Ideal)", 0.5000),
                  _btnSimulador("Simular FAP 1.0 (Neutro)", 1.0000),
                  _btnSimulador("Simular FAP 2.0 (Grave)", 2.0000),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text("Resumo Financeiro & Indicadores Estratégicos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 15, runSpacing: 15,
              children:[
                _cardEstrategico("FAP Aplicado", fapSimulado.toStringAsFixed(4), Colors.blue, "O FAP reduz ou aumenta a contribuição."),
                _cardEstrategico("RAT CNAE", "${ratCnae.toStringAsFixed(2)}%", Colors.orange, "Risco Ambiental definido pelo CNAE."),
                _cardEstrategico("RAT Ajustado", "${novoRatAjustado.toStringAsFixed(2)}%", Colors.deepOrange, "RAT x FAP."),
                _cardEstrategico("Folha Anual", formatarDinheiro(folhaAnual), Colors.grey[800]!, "Massa salarial total."),
                _cardEstrategico("Tributação Anual", formatarDinheiro(novaTributacao), Colors.red, "Contribuição paga ao governo."),
                _cardEstrategico("Economia Previdenciária", formatarDinheiro(economiaPrevidenciaria), Colors.green, "Economia gerada pela redução do FAP."),
              ],
            ),
            SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Text("Parâmetros Oficiais do Cálculo FAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Divider(height: 30),
                        _linhaIndice("Índice de Frequência:", dados['indices']['frequencia'].toString(), "Acidentes em relação aos trabalhadores."),
                        _linhaIndice("Índice de Gravidade:", dados['indices']['gravidade'].toString(), "Severidade dos acidentes."),
                        _linhaIndice("Índice de Custo:", dados['indices']['custo'].toString(), "Impacto financeiro pro INSS."),
                        Divider(height: 30),
                        _linhaIndice("Performance Atual:", dados['estrategico']['performance'].toString(), "Posição no ranking nacional."),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        Row(children:[Text("Comparação Histórica (3 anos)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(width: 10), _iconeLegenda("Evolução do FAP e Tributação.")]),
                        Divider(height: 30),
                        DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                          columns:[
                            DataColumn(label: Text('Ano', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('FAP', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('RAT Ajust.', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tributação', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: (dados['historico'] as List).map((linha) {
                            return DataRow(cells:[
                              DataCell(Text(linha['ano'].toString())),
                              DataCell(Text(double.parse(linha['fap'].toString()).toStringAsFixed(4))),
                              DataCell(Text("${double.parse(linha['rat_ajustado'].toString()).toStringAsFixed(2)}%")),
                              DataCell(Text(formatarDinheiro(double.parse(linha['tributacao'].toString())))),
                            ]);
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 30),
            Container(
              width: double.infinity, padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(children:[Text("Detalhamento Analítico Mensal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(width: 10), _iconeLegenda("Distribuição mensal do RAT.")]),
                  Divider(height: 30),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 40, headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                      columns:[
                        DataColumn(label: Text('Mês', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Folha Salarial', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('RAT Aplicado', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Valor Pago (Tributo)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: (dados['mensal'] as List).map((linha) {
                        return DataRow(cells:[
                          DataCell(Text(linha['mes'].toString(), style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(formatarDinheiro(double.parse(linha['folha'].toString())))),
                          DataCell(Text("${linha['rat_aplicado']}%")),
                          DataCell(Text(formatarDinheiro(double.parse(linha['valor_pago'].toString())), style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _btnSimulador(String texto, double valorFap) {
    bool selecionado = fapSimulado == valorFap;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: selecionado ? Colors.green : Colors.white, foregroundColor: selecionado ? Colors.white : Colors.black),
        onPressed: () => setState(() => fapSimulado = valorFap), child: Text(texto),
      ),
    );
  }

  Widget _cardEstrategico(String titulo, String valor, Color cor, String legenda) {
    return Container(
      width: 280, padding: EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: cor, width: 5)), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Expanded(child: Text(titulo, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13))), _iconeLegenda(legenda)]),
          SizedBox(height: 10), Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }

  Widget _linhaIndice(String titulo, String valor, String legenda) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          Row(children:[Text(titulo, style: TextStyle(fontSize: 15, color: Colors.grey[800])), SizedBox(width: 5), _iconeLegenda(legenda)]),
          Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _iconeLegenda(String textoExplicativo) {
    return Tooltip(
      message: textoExplicativo, padding: EdgeInsets.all(15), margin: EdgeInsets.symmetric(horizontal: 20),
      textStyle: TextStyle(color: Colors.white, fontSize: 14), decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.info_outline, size: 16, color: Colors.blue),
    );
  }
}