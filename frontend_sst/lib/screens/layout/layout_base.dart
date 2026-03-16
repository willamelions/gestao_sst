import 'package:flutter/material.dart';
import '../../services/sessao.dart'; 
import '../dashboard/dashboard_screen.dart';
import '../importacao/importacao_screen.dart';
import '../acidentes/acidentes_screen.dart';
import '../fap/fap_screen.dart';
import '../rat/rat_screen.dart';
import '../absenteismo/absenteismo_screen.dart';
import '../admin/admin_screen.dart'; 

class LayoutBase extends StatefulWidget {
  @override
  _LayoutBaseState createState() => _LayoutBaseState();
}

class _LayoutBaseState extends State<LayoutBase> {
  Widget telaAtual = DashboardScreen(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children:[
          // MENU LATERAL ESCURO
          Container(
            width: 250,
            color: Colors.blueGrey[900],
            child: Column(
              children:[
                SizedBox(height: 50),
                
                // A logo no menu lateral! (Se não achar a imagem, usa o escudo)
                Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.health_and_safety, size: 50, color: Colors.white),
                ),
                
                SizedBox(height: 10),
                Text("SISTEMA SST", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                
                // LISTA DE TELAS
                _menuItem(Icons.dashboard, "Dashboard", DashboardScreen()),
                _menuItem(Icons.warning, "Acidentes", AcidentesScreen()),
                _menuItem(Icons.trending_up, "FAP", FapScreen()),
                _menuItem(Icons.security, "RAT", RatScreen()),
                _menuItem(Icons.sick, "Absenteísmo", AbsenteismoScreen()),
                _menuItem(Icons.upload_file, "Importar Planilha", ImportacaoScreen()),
                
                // === BOTÃO EXCLUSIVO DO GESTOR MASTER ===
                if (Sessao.isAdmin) ...[
                  SizedBox(height: 20),
                  Divider(color: Colors.blueGrey[700], thickness: 1, indent: 20, endIndent: 20), 
                  _menuItem(Icons.admin_panel_settings, "Administração", AdminScreen()),
                ]
              ],
            ),
          ),
          
          // ÁREA DO CONTEÚDO (TELA DIREITA)
          Expanded(
            child: telaAtual,
          )
        ],
      ),
    );
  }

  // Função criadora dos botões do menu
  Widget _menuItem(IconData icone, String titulo, Widget telaDestino) {
    return ListTile(
      leading: Icon(icone, color: Colors.white70),
      title: Text(titulo, style: TextStyle(color: Colors.white, fontSize: 15)),
      hoverColor: Colors.blueGrey[800], // Efeito bonito ao passar o mouse
      onTap: () {
        setState(() {
          telaAtual = telaDestino; 
        });
      },
    );
  }
}