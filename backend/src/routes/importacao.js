const express = require('express');
const multer = require('multer');
const xlsx = require('xlsx');
const db = require('../config/db'); 

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/upload', upload.single('planilha'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ erro: 'Nenhum arquivo foi enviado.' });

        const empresa_id = req.body.empresa_id || 1;

        const workbook = xlsx.read(req.file.buffer, { type: 'buffer' });
        const dadosPlanilha = xlsx.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);

        if (dadosPlanilha.length === 0) return res.status(400).json({ erro: 'A planilha está vazia.' });

        // TÉCNICA DE MESTRE: Corta textos gigantes automaticamente para o Aiven não bloquear!
        const valores = dadosPlanilha.map(linha => {
            let natureza = linha['Descricao_NatLesao'] || '-';
            if (natureza.length > 95) natureza = natureza.substring(0, 95) + '...';

            let funcionario = linha['desNomeFuncionario'] || 'Não informado';
            if (funcionario.length > 95) funcionario = funcionario.substring(0, 95);

            let tipo = linha['desTipoAcidente'] || 'Não informado';

            return [
                empresa_id,
                tipo,
                linha['durTratamento'] || 0,
                natureza,
                funcionario,
                linha['Estado'] || '-',
                linha['Municipio'] || '-',
                linha['Ano'] || 0,
                linha['Mes_Num'] || 0
            ];
        });

        // Inserção em Massa Ultra Rápida
        const sql = `INSERT INTO acidentes 
            (empresa_id, tipo_acidente, duracao_tratamento, natureza_lesao, funcionario, estado, municipio, ano, mes) 
            VALUES ?`;

        await db.promise().query(sql, [valores]);

        res.json({ mensagem: 'Planilha processada e salva instantaneamente!', totalLinhas: dadosPlanilha.length });

    } catch (erro) {
        console.error("Erro ao processar planilha:", erro);
        res.status(500).json({ erro: 'Erro interno ao processar a planilha.' });
    }
});

module.exports = router;