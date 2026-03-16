import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImportacaoScreen extends StatefulWidget {
  @override
  _ImportacaoScreenState createState() => _ImportacaoScreenState();
}

class _ImportacaoScreenState extends State<ImportacaoScreen> {
  String mensagemStatus = "Nenhum arquivo selecionado";
  bool carregando = false;
  String empresaSelecionada = "0"; // Começa pedindo para selecionar

  Future<void> escolherEEnviarArquivo() async {
    // Trava de segurança: Tem que escolher um CNPJ primeiro!
    if (empresaSelecionada == "0") {
      setState(() => mensagemStatus = "❌ Selecione uma Empresa (CNPJ) no topo antes de enviar!");
      return;
    }

    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true, 
    );

    if (resultado != null) {
      setState(() {
        carregando = true;
        mensagemStatus = "Enviando e processando arquivo...";
      });

      PlatformFile arquivo = resultado.files.first;
      Uint8List? bytesDoArquivo = arquivo.bytes;

      if (bytesDoArquivo != null) {
        var uri = Uri.parse("https://meu-sst-backend.onrender.com/api/upload");
        var request = http.MultipartRequest("POST", uri);

        // Manda o ID da empresa para o Node.js saber onde salvar!
        request.fields['empresa_id'] = empresaSelecionada;

        var arquivoEnvio = http.MultipartFile.fromBytes(
          'planilha', 
          bytesDoArquivo,
          filename: arquivo.name,
        );
        request.files.add(arquivoEnvio);

        try {
          var resposta = await request.send();
          if (resposta.statusCode == 200) {
            setState(() => mensagemStatus = "✅ Sucesso! Planilha importada e salva na empresa selecionada.");
          } else {
            setState(() => mensagemStatus = "❌ Erro ao processar a planilha. Verifique as colunas.");
          }
        } catch (e) {
          setState(() => mensagemStatus = "❌ Erro de conexão com o servidor.");
        }
      }
    } else {
      setState(() => mensagemStatus = "Ação cancelada pelo usuário.");
    }
    setState(() => carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Importação de Planilha NBR 14280", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
                if (valor != null) setState(() => empresaSelecionada = valor);
              },
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text("Importar Banco de Acidentes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              
              // Alerta visual para o usuário não esquecer do filtro
              Container(
                padding: EdgeInsets.all(15), color: Colors.orange[50],
                child: Row(children:[
                  Icon(Icons.warning, color: Colors.orange[800]), SizedBox(width: 10), 
                  Text("Atenção: Selecione no menu superior para qual empresa os dados da planilha serão enviados.", style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))
                ]),
              ),
              SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: carregando ? null : escolherEEnviarArquivo,
                icon: Icon(Icons.upload_file),
                label: Text("Selecionar e Enviar Planilha", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              
              SizedBox(height: 30),
              
              carregando 
                  ? CircularProgressIndicator() 
                  : Text(mensagemStatus, style: TextStyle(fontSize: 18, color: mensagemStatus.contains('❌') ? Colors.red : Colors.green[700], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}