import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // === IMPORTANTE: COLOQUE AQUI O SEU LINK REAL DO RENDER ===
  final String apiUrl = "https://SEU-LINK-REAL-DO-BACKEND.onrender.com"; 

  String empresaSelecionada = "0"; 

  String totalAcidentes = "0", diasPerdidos = "0", comAfastamento = "0", taxaFrequencia = "0", taxaGravidade = "0";
  double totalTipico = 0, totalTrajeto = 0;
  List<FlSpot> pontosMensais =[];
  
  bool carregando = true;
  bool erroConexao = false; // Proteção contra tela cinza

  @override
  void initState() {
    super.initState();
    buscarDadosDoDashboard();
  }

  Future<void> buscarDadosDoDashboard() async {
    setState(() { carregando = true; erroConexao = false; });
    try {
      var resInd = await http.get(Uri.parse("$apiUrl/api/dashboard/indicadores/$empresaSelecionada"));
      var resPiz = await http.get(Uri.parse("$apiUrl/api/dashboard/grafico-tipo/$empresaSelecionada"));
      var resMen = await http.get(Uri.parse("$apiUrl/api/dashboard/grafico-mensal/$empresaSelecionada"));

      if (resInd.statusCode == 200 && resPiz.statusCode == 200 && resMen.statusCode == 200) {
        var dados = jsonDecode(resInd.body);
        List<dynamic> dadosPizza = jsonDecode(resPiz.body);
        List<dynamic> dadosMensais = jsonDecode(resMen.body);
        
        double tipicoTemp = 0, trajetoTemp = 0;
        for (var item in dadosPizza) {
          if (item['tipo_acidente'] == 'Típico') tipicoTemp = double.parse(item['total'].toString());
          else if (item['tipo_acidente'] == 'Trajeto') trajetoTemp = double.parse(item['total'].toString());
        }

        List<FlSpot> pontosTemp =[];
        for (var item in dadosMensais) {
          pontosTemp.add(FlSpot(double.parse(item['mes'].toString()), double.parse(item['total'].toString())));
        }

        setState(() {
          totalAcidentes = dados['total_acidentes'].toString();
          diasPerdidos = dados['dias_perdidos'].toString();
          comAfastamento = dados['com_afastamento'].toString();
          taxaFrequencia = dados['taxa_frequencia'].toString();
          taxaGravidade = dados['taxa_gravidade'].toString();
          totalTipico = tipicoTemp;
          totalTrajeto = trajetoTemp;
          pontosMensais = pontosTemp;
          carregando = false;
        });
      } else {
        setState(() { carregando = false; erroConexao = true; });
      }
    } catch (e) {
      setState(() { carregando = false; erroConexao = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Dashboard de Indicadores (NBR 14280)", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                if (valor != null) { setState(() => empresaSelecionada = valor); buscarDadosDoDashboard(); }
              },
            ),
          )
        ],
      ),
      body: carregando 
        ? Center(child: CircularProgressIndicator()) 
        : erroConexao 
          ? Center(child: Text("Erro ao conectar com o banco de dados. Verifique a internet ou o CNPJ selecionado.", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  
                  // CARDS COM LEGENDAS DA NBR 14280
                  Wrap(
                    spacing: 20, runSpacing: 20,
                    children:[
                      _criarCard("Total Acidentes", totalAcidentes, Colors.blue, "Soma de todos os acidentes registrados na base de dados."),
                      _criarCard("Com Afastamento", comAfastamento, Colors.orange, "Acidentes onde o trabalhador precisou ser afastado de suas atividades (Dias Perdidos > 0)."),
                      _criarCard("Dias Perdidos", diasPerdidos, Colors.red, "Total de dias de trabalho perdidos devido a acidentes."),
                      _criarCard("Taxa Frequência (TF)", taxaFrequencia, Colors.purple, "Fórmula NBR 14280: (Acidentes com Afastamento × 1.000.000) ÷ Horas Trabalhadas. Indica a frequência dos acidentes."),
                      _criarCard("Taxa Gravidade (TG)", taxaGravidade, Colors.deepPurple, "Fórmula NBR 14280: (Dias Perdidos × 1.000.000) ÷ Horas Trabalhadas. Indica a severidade dos acidentes."),
                    ],
                  ),
                  SizedBox(height: 30),
                  
                  // GRÁFICOS COM LEGENDAS
                  Wrap(
                    spacing: 20, runSpacing: 20,
                    children:[
                      _criarGraficoPizza(),
                      _criarGraficoGravidade(), 
                      _criarGraficoSetor(),     
                    ],
                  ),
                  SizedBox(height: 30),

                  Wrap(
                    spacing: 20, runSpacing: 20,
                    children:[
                      _criarGraficoLinha("Evolução Mensal de Acidentes", pontosMensais, false, Colors.blue, "Mostra a quantidade de acidentes ocorridos em cada mês do ano, permitindo identificar períodos críticos."),
                      _criarGraficoLinha("Tendência Anual",[FlSpot(1, 40), FlSpot(2, 170), FlSpot(3, 45), FlSpot(4, 0)], true, Colors.teal, "Exibe o histórico consolidado de acidentes dos últimos anos para medir a eficiência da gestão de SST a longo prazo."), 
                    ],
                  )
                ],
              ),
            ),
    );
  }

  // WIDGET CARD COM ÍCONE DE LEGENDA
  Widget _criarCard(String titulo, String valor, Color cor, String legenda) {
    return Container(
      width: 220, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border(bottom: BorderSide(color: cor, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Expanded(child: Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.bold))),
              Tooltip(
                message: legenda, padding: EdgeInsets.all(15), margin: EdgeInsets.symmetric(horizontal: 20),
                textStyle: TextStyle(color: Colors.white, fontSize: 14), decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.info_outline, size: 16, color: cor),
              )
            ],
          ),
          SizedBox(height: 10),
          Text(valor, style: TextStyle(color: cor, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // WIDGET PIZZA
  Widget _criarGraficoPizza() {
    return _boxGrafico("Tipo de Acidente", "Classifica os acidentes entre 'Típico' (Ocorrido no local de trabalho) e 'Trajeto' (Ocorrido no percurso casa-trabalho).", 350, PieChart(
      PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 0,
        sections:[
          PieChartSectionData(color: Colors.blue[400], value: totalTipico, title: 'Típico\n${totalTipico.toInt()}', radius: 110, titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.teal[400], value: totalTrajeto, title: 'Trajeto\n${totalTrajeto.toInt()}', radius: 110, titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ]
      )
    ));
  }

  // WIDGET LINHA (Mensal e Anual)
  Widget _criarGraficoLinha(String titulo, List<FlSpot> pontos, bool curva, Color cor, String legenda) {
    return _boxGrafico(titulo, legenda, 500, LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
        lineBarsData:[
          LineChartBarData(spots: pontos.isEmpty ? [FlSpot(0,0)] : pontos, isCurved: curva, color: cor, barWidth: 3, isStrokeCapRound: true, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: false)),
        ],
      )
    ));
  }

  Widget _criarGraficoGravidade() {
    return _boxGrafico("Gravidade", "Mede o nível da lesão conforme a NBR 14280 (Leve, Grave, Moderado, Fatal).", 350, BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
            const titulos =['Leve', 'Grave', 'Moderad', 'Fatal'];
            return Text(titulos[val.toInt()], style: TextStyle(fontSize: 10));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups:[
          BarChartGroupData(x: 0, barRods:[BarChartRodData(toY: 70, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods:[BarChartRodData(toY: 65, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods:[BarChartRodData(toY: 55, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 3, barRods:[BarChartRodData(toY: 50, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
        ]
      )
    ));
  }

  Widget _criarGraficoSetor() {
    return _boxGrafico("Acidentes por Setor", "Identifica quais setores operacionais da empresa possuem a maior concentração de acidentes registrados.", 350, Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:[
        _barraHorizontal("Administrativo", 55), _barraHorizontal("Produção", 50),
        _barraHorizontal("Manutenção", 50), _barraHorizontal("Qualidade", 45), _barraHorizontal("Logística", 40),
      ],
    ));
  }

  Widget _barraHorizontal(String titulo, double tamanho) {
    return Row(children:[ SizedBox(width: 80, child: Text(titulo, style: TextStyle(fontSize: 11), textAlign: TextAlign.right)), SizedBox(width: 10), Container(height: 25, width: tamanho * 3, decoration: BoxDecoration(color: Colors.red[500], borderRadius: BorderRadius.circular(4))) ]);
  }

  // Molde com Legenda para os Gráficos
  Widget _boxGrafico(String titulo, String legenda, double largura, Widget grafico) {
    return Container(
      width: largura, height: 300, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Tooltip(
                message: legenda, padding: EdgeInsets.all(15), textStyle: TextStyle(color: Colors.white, fontSize: 14),
                decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.info_outline, size: 16, color: Colors.blue),
              )
            ],
          ),
          SizedBox(height: 20),
          Expanded(child: grafico)
        ],
      ),
    );
  }
}