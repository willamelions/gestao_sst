const express = require('express');
const db = require('../config/db');
const router = express.Router();

// ==========================================
// 1. ROTA: RELATÓRIO ESTRATÉGICO (Tela RAT)
// ==========================================
router.get('/estrategico/:empresa_id', (req, res) => {
    try {
        const { empresa_id } = req.params;
        
        // Folhas de pagamento diferentes dependendo da empresa ou da Visão Geral (0)
        let folhaAnual = 62000000; 
        if (empresa_id === '0') folhaAnual = 180000000; 
        if (empresa_id === '2') folhaAnual = 45000000;
        if (empresa_id === '3') folhaAnual = 73000000;

        const ratCnae = 3.00;        
        const fapAtual = 0.5000;     
        const ratAjustado = ratCnae * fapAtual; 
        const tributacaoAnual = folhaAnual * (ratAjustado / 100); 
        const fapAnoAnterior = 1.2000; 
        const ratAjustadoAnterior = ratCnae * fapAnoAnterior; 
        const tributacaoAnterior = folhaAnual * (ratAjustadoAnterior / 100); 
        const economia = tributacaoAnterior - tributacaoAnual; 

        res.json({
            indices: { frequencia: "1,25", gravidade: "0,45", custo: "0,80" },
            estrategico: {
                fap_atual: fapAtual.toFixed(4), rat_cnae: ratCnae.toFixed(2), rat_ajustado: ratAjustado.toFixed(2),
                folha_anual: folhaAnual, tributacao_anual: tributacaoAnual, economia_previdenciaria: economia,
                performance: fapAtual < 1 ? "Positivo (Melhora)" : "Risco"
            },
            historico:[
                { ano: 2023, fap: 1.5000, rat_ajustado: 4.50, tributacao: folhaAnual * 0.045 },
                { ano: 2024, fap: 1.2000, rat_ajustado: 3.60, tributacao: folhaAnual * 0.036 },
                { ano: 2025, fap: 0.5000, rat_ajustado: 1.50, tributacao: folhaAnual * 0.015 },
            ],
            mensal:["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"].map(mes => ({
                mes: mes, folha: folhaAnual / 12, rat_aplicado: ratAjustado.toFixed(2), valor_pago: tributacaoAnual / 12
            }))
        });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao gerar relatório estratégico' });
    }
});

// ==========================================
// 2. ROTAS: GESTÃO E HISTÓRICO (Tela FAP)
// ==========================================
router.get('/historico/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        let sql = 'SELECT * FROM fap_historico';
        let params =[];
        if (empresa_id !== '0') {
            sql += ' WHERE empresa_id = ?';
            params.push(empresa_id);
        }
        sql += ' ORDER BY ano ASC';
        
        const [linhas] = await db.promise().query(sql, params);
        res.json(linhas);
    } catch (erro) {
        console.error(erro);
        res.status(500).json({ erro: 'Erro ao buscar histórico do FAP' });
    }
});

router.post('/registrar', async (req, res) => {
    try {
        const { empresa_id, ano, fap, ind_frequencia, ind_gravidade, ind_custo } = req.body;

        if (fap < 0.5 || fap > 2.0) return res.status(400).json({ erro: 'O FAP deve estar entre 0.5000 e 2.0000.' });
        if (ind_frequencia < 0 || ind_gravidade < 0 || ind_custo < 0) return res.status(400).json({ erro: 'Os índices não podem ser negativos.' });

        const [existe] = await db.promise().query('SELECT id FROM fap_historico WHERE empresa_id = ? AND ano = ?', [empresa_id, ano]);
        if (existe.length > 0) return res.status(400).json({ erro: `Já existe um registro de FAP para o ano ${ano}.` });

        await db.promise().query(
            'INSERT INTO fap_historico (empresa_id, ano, fap, ind_frequencia, ind_gravidade, ind_custo) VALUES (?, ?, ?, ?, ?, ?)',[empresa_id, ano, fap, ind_frequencia, ind_gravidade, ind_custo]
        );
        res.json({ mensagem: 'FAP registrado com sucesso!' });
    } catch (erro) {
        console.error(erro);
        res.status(500).json({ erro: 'Erro interno ao registrar FAP' });
    }
});

router.delete('/excluir/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.promise().query('DELETE FROM fap_historico WHERE id = ?', [id]);
        res.json({ mensagem: 'FAP excluído com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao excluir FAP' });
    }
});

module.exports = router;