const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./config/db'); 

// Importação das Rotas
const importacaoRoutes = require('./routes/importacao'); 
const dashboardRoutes = require('./routes/dashboard');
const acidentesRoutes = require('./routes/acidentes');
const fapRoutes = require('./routes/fap');
const absenteismoRoutes = require('./routes/absenteismo');
const authRoutes = require('./routes/auth'); 
const adminRoutes = require('./routes/admin');

const app = express();

// =============================================================
// 1. CONFIGURAÇÃO DE SEGURANÇA (CORS) - MATA O "ERRO DE CONEXÃO"
// =============================================================
app.use(cors({
  origin: '*', // Permite que qualquer origem acesse a API (essencial para o Render)
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// =============================================================
// 2. CONFIGURAÇÃO DOS CAMINHOS (ESTÁTICOS) - MATA O "NOT FOUND"
// =============================================================
// path.resolve garante o caminho correto no Linux do Render
const publicPath = path.resolve(__dirname, '..', 'public', 'web');

// Serve os arquivos do Flutter
app.use(express.static(publicPath));

// =============================================================
// 3. ROTAS DA API
// =============================================================
app.use('/api', importacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/acidentes', acidentesRoutes);
app.use('/api/fap', fapRoutes);
app.use('/api/absenteismo', absenteismoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// =============================================================
// 4. ROTA CORINGA PARA SINGLE PAGE APPLICATION (SPA)
// =============================================================
// Se não for uma rota de API e não for um arquivo físico, envia o index.html
app.get(/.*/, (req, res) => {
    // Evita que erros em chamadas de API retornem o index.html
    if (req.url.startsWith('/api')) {
        return res.status(404).json({ erro: 'Rota de API não encontrada' });
    }
    res.sendFile(path.join(publicPath, 'index.html'));
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📂 Servindo Flutter de: ${publicPath}`);
});