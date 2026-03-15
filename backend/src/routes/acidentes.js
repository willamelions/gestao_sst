const express = require('express');
const db = require('../config/db');
const router = express.Router();

// 1. ROTA PARA LISTAR
router.get('/listar/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        const [acidentes] = await db.promise().query(
            'SELECT * FROM acidentes WHERE empresa_id = ? ORDER BY id DESC',[empresa_id]
        );
        res.json(acidentes);
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao buscar a lista de acidentes' });
    }
});

// 2. ROTA PARA EXCLUIR
router.delete('/excluir/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await db.promise().query('DELETE FROM acidentes WHERE id = ?',[id]);
        res.json({ mensagem: 'Acidente excluído com sucesso!' });
    } catch (erro) {
        console.error("Erro ao excluir:", erro);
        res.status(500).json({ erro: 'Erro ao excluir acidente' });
    }
});

// 3. ROTA PARA EDITAR/SALVAR
router.put('/editar/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { funcionario, tipo_acidente, duracao_tratamento, municipio } = req.body;
        
        await db.promise().query(
            'UPDATE acidentes SET funcionario = ?, tipo_acidente = ?, duracao_tratamento = ?, municipio = ? WHERE id = ?',
            [funcionario, tipo_acidente, duracao_tratamento, municipio, id]
        );
        res.json({ mensagem: 'Acidente atualizado com sucesso!' });
    } catch (erro) {
        console.error("Erro ao atualizar:", erro);
        res.status(500).json({ erro: 'Erro ao atualizar acidente' });
    }
});

// ROTA PARA APAGAR TODOS OS ACIDENTES DA EMPRESA
router.delete('/apagar-tudo/:empresa_id', async (req, res) => {
    try {
        const { empresa_id } = req.params;
        await db.promise().query('DELETE FROM acidentes WHERE empresa_id = ?', [empresa_id]);
        res.json({ mensagem: 'Base de dados limpa com sucesso!' });
    } catch (erro) {
        console.error("Erro ao apagar tudo:", erro);
        res.status(500).json({ erro: 'Erro ao apagar a base de dados.' });
    }
});

module.exports = router;