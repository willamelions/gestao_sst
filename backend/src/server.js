const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./config/db'); // Ajustado para rodar de dentro de /src

// Importação das Rotas (Como server.js está em /src, o caminho é relativo a ele)
const importacaoRoutes = require('./routes/importacao'); 
const dashboardRoutes = require('./routes/dashboard');
const acidentesRoutes = require('./routes/acidentes');
const fapRoutes = require('./routes/fap');
const absenteismoRoutes = require('./routes/absenteismo');
const authRoutes = require('./routes/auth'); 
const adminRoutes = require('./routes/admin');

const app = express();

app.use(cors());
app.use(express.json());

// =============================================================
// 1. CONFIGURAÇÃO DOS CAMINHOS (IMPORTANTE!)
// =============================================================
// Como este arquivo está em 'backend/src', precisamos subir um nível (..) 
// para chegar na pasta 'public/web'
const publicPath = path.join(__dirname, '..', 'public', 'web');

// Servir arquivos estáticos do Flutter
app.use(express.static(publicPath));

// =============================================================
// 2. ROTAS DA API
// =============================================================
app.use('/api', importacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/acidentes', acidentesRoutes);
app.use('/api/fap', fapRoutes);
app.use('/api/absenteismo', absenteismoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// =============================================================
// 3. ROTA CORINGA (CORRIGIDA)
// =============================================================
// Usa a expressão regular /.*/ para evitar o erro do Render
app.get(/.*/, (req, res) => {
  res.sendFile(path.join(publicPath, 'index.html'));
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📂 Servindo Flutter de: ${publicPath}`);
});