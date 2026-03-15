const express = require('express');
const db = require('../config/db');
const router = express.Router();

// Função ajudante para criar o filtro SQL dinâmico
function montarFiltro(empresa_id) {
    if (empresa_id === '0') {
        return { condicao: '1 = 1', params:[] }; // "1=1" significa "Traga tudo (Visão Geral)"
    } else {
        return { condicao: 'empresa_id = ?', params: [empresa_id] }; // Filtra por empresa
    }
}

// 1. Rota de Indicadores (Cards)
router.get('/indicadores/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        const filtro = montarFiltro(empresa_id);
        
        const [totalRes] = await db.promise().query(`SELECT COUNT(*) as total FROM acidentes WHERE ${filtro.condicao}`, filtro.params);
        const [diasRes] = await db.promise().query(`SELECT SUM(duracao_tratamento) as dias FROM acidentes WHERE ${filtro.condicao}`, filtro.params);
        const [afastRes] = await db.promise().query(`SELECT COUNT(*) as total FROM acidentes WHERE ${filtro.condicao} AND duracao_tratamento > 0`, filtro.params);

        const total_acidentes = totalRes[0].total || 0;
        const dias_perdidos = diasRes[0].dias || 0;
        const com_afastamento = afastRes[0].total || 0;
        const horasTrabalhadas = 500000; 

        res.json({
            total_acidentes, dias_perdidos, com_afastamento,
            taxa_frequencia: com_afastamento > 0 ? ((com_afastamento * 1000000) / horasTrabalhadas).toFixed(2) : 0,
            taxa_gravidade: dias_perdidos > 0 ? ((dias_perdidos * 1000000) / horasTrabalhadas).toFixed(2) : 0
        });
    } catch (erro) { res.status(500).json({ erro: 'Erro indicadores' }); }
});

// 2. Rota do Gráfico de Pizza (Tipos)
router.get('/grafico-tipo/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        const filtro = montarFiltro(empresa_id);
        const [linhas] = await db.promise().query(`SELECT tipo_acidente, COUNT(*) as total FROM acidentes WHERE ${filtro.condicao} GROUP BY tipo_acidente`, filtro.params);
        res.json(linhas);
    } catch (erro) { res.status(500).json({ erro: 'Erro pizza' }); }
});

// 3. Rota do Gráfico Mensal (Linha)
router.get('/grafico-mensal/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        const filtro = montarFiltro(empresa_id);
        const [linhas] = await db.promise().query(`SELECT mes, COUNT(*) as total FROM acidentes WHERE ${filtro.condicao} GROUP BY mes ORDER BY mes`, filtro.params);
        res.json(linhas);
    } catch (erro) { res.status(500).json({ erro: 'Erro mensal' }); }
});

module.exports = router;