const express = require('express');
const cors = require('cors');
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

// rota raiz
app.get('/', (req, res) => {
  res.send('API Gestão SST rodando no Render 🚀');
});

// rotas da API
app.use('/api', importacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/acidentes', acidentesRoutes);
app.use('/api/fap', fapRoutes);
app.use('/api/absenteismo', absenteismoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});