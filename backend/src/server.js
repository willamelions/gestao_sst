const express = require('express');
const cors = require('cors');
const db = require('./config/db');

// Importa a nossa nova rota
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

// Diz ao servidor para usar a rota de importação quando o endereço tiver "/api"
app.use('/api', importacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/acidentes', acidentesRoutes);
app.use('/api/fap', fapRoutes);
app.use('/api/absenteismo', absenteismoRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);


app.listen(3000, () => {
    console.log('Servidor rodando na porta 3000');
});