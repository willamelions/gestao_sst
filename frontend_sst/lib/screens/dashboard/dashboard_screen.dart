import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // O Filtro selecionado ("0" = Visão Geral, "1" = Serviços, etc...)
  String empresaSelecionada = "0"; 

  // Variáveis dos Cards
  String totalAcidentes = "0", diasPerdidos = "0", comAfastamento = "0", taxaFrequencia = "0", taxaGravidade = "0";
  
  // Variáveis Gráfico Pizza
  double totalTipico = 0, totalTrajeto = 0;

  // Variáveis Gráfico Linha Mensal
  List<FlSpot> pontosMensais =[];

  bool carregando = true;

  @override
  void initState() {
    super.initState();
    buscarDadosDoDashboard();
  }

  // Busca os dados da empresa selecionada (ou "0" para todas)
  Future<void> buscarDadosDoDashboard() async {
    setState(() => carregando = true);
    try {
      var urlIndicadores = Uri.parse("https://meu-sst-backend.onrender.com/api/dashboard/indicadores/$empresaSelecionada");
      var urlPizza = Uri.parse("https://meu-sst-backend.onrender.com/api/dashboard/grafico-tipo/$empresaSelecionada");
      var urlMensal = Uri.parse("https://meu-sst-backend.onrender.com/api/dashboard/grafico-mensal/$empresaSelecionada");

      var resInd = await http.get(urlIndicadores);
      var resPiz = await http.get(urlPizza);
      var resMen = await http.get(urlMensal);

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
      }
    } catch (e) {
      print("Erro ao buscar dados: $e");
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Dashboard de Indicadores", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions:[
          // FILTRO DE EMPRESA / VISÃO GERAL VOLTOU!
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: DropdownButton<String>(
              value: empresaSelecionada,
              underline: Container(), // Remove a linha feia do dropdown
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              items:[
                DropdownMenuItem(value: "0", child: Text("👁️ Visão Geral (Todas as Empresas)")),
                DropdownMenuItem(value: "1", child: Text("🏢 SERVIÇOS")),
                DropdownMenuItem(value: "2", child: Text("🛡️ SEGURANÇA")),
                DropdownMenuItem(value: "3", child: Text("🔌 ELETRÔNICA")),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => empresaSelecionada = valor);
                  buscarDadosDoDashboard(); // Recarrega tudo ao trocar!
                }
              },
            ),
          )
        ],
      ),
      body: carregando 
        ? Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                // CARDS
                Wrap(
                  spacing: 20, runSpacing: 20,
                  children:[
                    _criarCard("Total Acidentes", totalAcidentes, Colors.blue),
                    _criarCard("Com Afastamento", comAfastamento, Colors.orange),
                    _criarCard("Dias Perdidos", diasPerdidos, Colors.red),
                    _criarCard("Taxa Frequência", taxaFrequencia, Colors.purple),
                    _criarCard("Taxa Gravidade", taxaGravidade, Colors.deepPurple),
                  ],
                ),
                SizedBox(height: 30),
                
                // LINHA 1 DE GRÁFICOS (Pizza, Gravidade, Setores)
                Wrap(
                  spacing: 20, runSpacing: 20,
                  children:[
                    _criarGraficoPizza(),
                    _criarGraficoGravidade(), // Fixo por enquanto
                    _criarGraficoSetor(),     // Fixo por enquanto
                  ],
                ),
                SizedBox(height: 30),

                // LINHA 2 DE GRÁFICOS (Linha Mensal e Linha Anual)
                Wrap(
                  spacing: 20, runSpacing: 20,
                  children:[
                    _criarGraficoLinha("Evolução Mensal de Acidentes", pontosMensais, false, Colors.blue),
                    _criarGraficoLinha("Tendência Anual",[FlSpot(1, 40), FlSpot(2, 170), FlSpot(3, 45), FlSpot(4, 0)], true, Colors.teal), // Fixo por enquanto
                  ],
                )
              ],
            ),
          ),
    );
  }

  // WIDGET CARD
  Widget _criarCard(String titulo, String valor, Color cor) {
    return Container(
      width: 220, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border(bottom: BorderSide(color: cor, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(titulo, style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(valor, style: TextStyle(color: cor, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // WIDGET PIZZA
  Widget _criarGraficoPizza() {
    return _boxGrafico("Tipo de Acidente", 350, PieChart(
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
  Widget _criarGraficoLinha(String titulo, List<FlSpot> pontos, bool curva, Color cor) {
    return _boxGrafico(titulo, 500, LineChart(
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
          LineChartBarData(
            spots: pontos.isEmpty ? [FlSpot(0,0)] : pontos,
            isCurved: curva, // Se for true faz curva (Tendência Anual), se for false faz bico (Evolução)
            color: cor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true), // Mostra as bolinhas
            belowBarData: BarAreaData(show: false),
          ),
        ],
      )
    ));
  }

  // WIDGET BARRAS GRAVIDADE (Visual igual imagem 2)
  Widget _criarGraficoGravidade() {
    return _boxGrafico("Gravidade", 350, BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
            const titulos = ['Leve', 'Grave', 'Moderad', 'Fatal'];
            return Text(titulos[val.toInt()], style: TextStyle(fontSize: 10));
          })),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups:[
          BarChartGroupData(x: 0, barRods:[BarChartRodData(toY: 70, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods:[BarChartRodData(toY: 65, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 55, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 3, barRods:[BarChartRodData(toY: 50, color: Colors.red[600], width: 35, borderRadius: BorderRadius.circular(4))]),
        ]
      )
    ));
  }

  // WIDGET BARRAS HORIZONTAIS SETOR (Feito customizado para ficar igual sua imagem)
  Widget _criarGraficoSetor() {
    return Container(
      width: 350, height: 300, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text("Acidentes por Setor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:[
              _barraHorizontal("Administrativo", 55),
              _barraHorizontal("Produção", 50),
              _barraHorizontal("Manutenção", 50),
              _barraHorizontal("Qualidade", 45),
              _barraHorizontal("Logística", 40),
            ],
          ))
        ],
      ),
    );
  }

  // Ajuda a desenhar a barra deitada
  Widget _barraHorizontal(String titulo, double tamanho) {
    return Row(
      children:[
        SizedBox(width: 80, child: Text(titulo, style: TextStyle(fontSize: 11), textAlign: TextAlign.right)),
        SizedBox(width: 10),
        Container(height: 25, width: tamanho * 3, decoration: BoxDecoration(color: Colors.red[500], borderRadius: BorderRadius.circular(4))),
      ],
    );
  }

  // Molde padrão para não repetir código das caixas brancas
  Widget _boxGrafico(String titulo, double largura, Widget grafico) {
    return Container(
      width: largura, height: 300, padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Expanded(child: grafico)
        ],
      ),
    );
  }
}