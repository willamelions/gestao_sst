import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(MeuSistemaSST());
}

class MeuSistemaSST extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema SST',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // <--- AGORA INICIA NO LOGIN
    );
  }
}