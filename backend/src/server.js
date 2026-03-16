const express = require('express');
const cors = require('cors');
const path = require('path'); // IMPORTANTE: Adicione esta linha
const db = require('./config/db');

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

// --- CONFIGURAÇÃO PARA SERVIR O FRONTEND FLUTTER ---

// 1. Diz ao Express para servir os arquivos da pasta 'public'
app.use(express.static(path.join(__dirname, 'public')));

// 2. Suas rotas da API (Mantenha todas aqui)
app.use('/api', importacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/acidentes', acidentesRoutes);
app.use('/api/fap', fapRoutes);
app.use('/api/absenteismo', absenteismoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// 3. ROTA CORINGA: Se o usuário acessar qualquer rota que não seja da API,
// o servidor envia o index.html do Flutter. Isso permite que o Refresh da página funcione.
app.get('/*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});