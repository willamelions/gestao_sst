const express = require('express');
const db = require('../config/db');
const router = express.Router();

// 1. ROTA DE INDICADORES (Com Filtro de CNPJ)
router.get('/indicadores/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        
        let sql = 'SELECT * FROM absenteismo';
        let params =[];
        // Se não for "0" (Visão Geral), filtra pela empresa selecionada
        if (empresa_id !== '0') {
            sql += ' WHERE empresa_id = ?';
            params.push(empresa_id);
        }

        const[registros] = await db.promise().query(sql, params);

        // Se for visão geral (0), soma os funcionários do grupo (ex: 600). Se for uma, usa 200.
        const numeroTrabalhadores = empresa_id === '0' ? 600 : 200; 
        const diasTrabalhadosMes = numeroTrabalhadores * 22; 

        let diasPerdidos = 0;
        let numeroAusencias = registros.length;
        let trabalhadoresAfastados = new Set();
        let cidsMap = {};
        let tiposMap = {};

        registros.forEach(reg => {
            diasPerdidos += reg.total_dias;
            trabalhadoresAfastados.add(reg.funcionario);
            tiposMap[reg.tipo] = (tiposMap[reg.tipo] || 0) + 1;
            if (reg.cid) cidsMap[reg.cid] = (cidsMap[reg.cid] || 0) + 1;
        });

        res.json({
            kpis: {
                indice_absenteismo: ((diasPerdidos / diasTrabalhadosMes) * 100).toFixed(2),
                taxa_frequencia: (numeroAusencias / numeroTrabalhadores).toFixed(2),
                taxa_gravidade: (diasPerdidos / numeroTrabalhadores).toFixed(2),
                indice_incidencia: (trabalhadoresAfastados.size / numeroTrabalhadores).toFixed(2),
                dias_perdidos: diasPerdidos,
                total_ausencias: numeroAusencias
            },
            graficos: { top_cids: Object.keys(cidsMap).map(k => ({ cid: k, total: cidsMap[k] })), tipos: tiposMap },
            lista: registros
        });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao gerar indicadores de absenteísmo' });
    }
});

// 2. ROTA PARA REGISTRAR
router.post('/registrar', async (req, res) => {
    try {
        const { empresa_id, funcionario, data_inicio, data_fim, total_dias, tipo, motivo, cid } = req.body;

        if (tipo === 'Médico' && (!cid || cid.trim() === '')) {
            return res.status(400).json({ erro: 'O CID é obrigatório para Absenteísmo Médico.' });
        }

        await db.promise().query(
            'INSERT INTO absenteismo (empresa_id, funcionario, data_inicio, data_fim, total_dias, tipo, motivo, cid) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',[empresa_id, funcionario, data_inicio, data_fim, total_dias, tipo, motivo, cid || null]
        );
        res.json({ mensagem: 'Absenteísmo registrado com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao registrar absenteísmo' });
    }
});

// 3. ROTA EXCLUIR
router.delete('/excluir/:id', async (req, res) => {
    try {
        await db.promise().query('DELETE FROM absenteismo WHERE id = ?',[req.params.id]);
        res.json({ mensagem: 'Registro excluído!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao excluir' });
    }
});

module.exports = router;