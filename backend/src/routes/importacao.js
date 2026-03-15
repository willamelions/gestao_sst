const express = require('express');
const multer = require('multer');
const xlsx = require('xlsx');
const db = require('../config/db'); 

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/upload', upload.single('planilha'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ erro: 'Nenhum arquivo foi enviado.' });

        const empresa_id = req.body.empresa_id;

        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
        const dadosPlanilha = xlsx.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);

        if (dadosPlanilha.length === 0) return res.status(400).json({ erro: 'A planilha está vazia.' });

        // TÉCNICA DE BULK INSERT (Processa milhares de linhas em 1 segundo)
        const valores = dadosPlanilha.map(linha =>[
            empresa_id,
            linha['desTipoAcidente'] || 'Não informado',
            linha['durTratamento'] || 0,
            linha['Descricao_NatLesao'] || '-',
            linha['desNomeFuncionario'] || 'Não informado',
            linha['Estado'] || '-',
            linha['Municipio'] || '-',
            linha['Ano'] || 0,
            linha['Mes_Num'] || 0
        ]);

        const sql = `INSERT INTO acidentes 
            (empresa_id, tipo_acidente, duracao_tratamento, natureza_lesao, funcionario, estado, municipio, ano, mes) 
            VALUES ?`; // O ponto de interrogação sem parênteses ativa o modo rápido do MySQL

        // Manda o pacote inteiro de uma vez!
        await db.promise().query(sql, [valores]);

        res.json({ mensagem: 'Planilha processada e salva instantaneamente!', totalLinhas: dadosPlanilha.length });

    } catch (erro) {
        console.error("Erro ao processar planilha:", erro);
        res.status(500).json({ erro: 'Erro interno ao processar a planilha.' });
    }
});

module.exports = router;