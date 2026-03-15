import 'package:flutter/material.dart';
import '../../services/sessao.dart'; // <--- Para sabermos se ele é o Gestor Master
import '../dashboard/dashboard_screen.dart';
import '../importacao/importacao_screen.dart';
import '../acidentes/acidentes_screen.dart';
import '../fap/fap_screen.dart';
import '../rat/rat_screen.dart';
import '../absenteismo/absenteismo_screen.dart';
import '../admin/admin_screen.dart'; // <--- Import da tela nova


class LayoutBase extends StatefulWidget {
  @override
  _LayoutBaseState createState() => _LayoutBaseState();
}

class _LayoutBaseState extends State<LayoutBase> {
  // Tela inicial que aparece ao lado do menu
  Widget telaAtual = DashboardScreen(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children:[
          // MENU LATERAL
          Container(
            width: 250,
            color: Colors.blueGrey[900],
            child: Column(
              children:[
                SizedBox(height: 50),
                Icon(Icons.health_and_safety, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text("SISTEMA SST", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                
                _menuItem(Icons.dashboard, "Dashboard", DashboardScreen()),
                _menuItem(Icons.warning, "Acidentes", AcidentesScreen()),
                _menuItem(Icons.trending_up, "FAP", FapScreen()),
                _menuItem(Icons.security, "RAT", RatScreen()),
                _menuItem(Icons.sick, "Absenteísmo", AbsenteismoScreen()),
                _menuItem(Icons.document_scanner, "Atestados", Container()),
                _menuItem(Icons.health_and_safety, "Diagnósticos", Container()),
                _menuItem(Icons.upload_file, "Importar Planilha", ImportacaoScreen()),
                
                // === BOTÃO EXCLUSIVO DO GESTOR MASTER ===
                if (Sessao.isAdmin) ...[
                  Divider(color: Colors.grey[700]), // Uma linha separadora
                  _menuItem(Icons.admin_panel_settings, "Administração", AdminScreen()),
                ]
              ],
            ),
          ),
          
          // ÁREA DO CONTEÚDO (DASHBOARD)
          Expanded(
            child: telaAtual,
          )
        ],
      ),
    );
  }

  // Função simples para criar os botões do menu
  Widget _menuItem(IconData icone, String titulo, Widget telaDestino) {
    return ListTile(
      leading: Icon(icone, color: Colors.white),
      title: Text(titulo, style: TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          telaAtual = telaDestino; // Muda a tela ao clicar
        });
      },
    );
  }
}