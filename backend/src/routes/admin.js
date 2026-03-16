const express = require('express');
const db = require('../config/db');
const router = express.Router();

// ==========================================
// ROTAS DE PERFIS DE ACESSO (Com Caixinhas)
// ==========================================

router.get('/perfis', async (req, res) => {
    try {
        const[perfis] = await db.promise().query('SELECT * FROM perfis');
        res.json(perfis);
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao buscar perfis' });
    }
});

// Rota nova: Criar um perfil marcando as permissões
router.post('/perfis', async (req, res) => {
    try {
        const { nome, is_admin, fap_editar, absenteismo_editar } = req.body;
        await db.promise().query(
            'INSERT INTO perfis (nome, is_admin, fap_editar, absenteismo_editar) VALUES (?, ?, ?, ?)',[nome, is_admin ? 1 : 0, fap_editar ? 1 : 0, absenteismo_editar ? 1 : 0]
        );
        res.json({ mensagem: 'Perfil criado com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao criar perfil' });
    }
});

// Rota nova: Excluir um perfil
router.delete('/perfis/:id', async (req, res) => {
    try {
        // Trava de segurança: Se tiver alguém usando esse perfil, o sistema não deixa apagar!
        const [usuarios] = await db.promise().query('SELECT id FROM usuarios WHERE perfil_id = ?', [req.params.id]);
        if (usuarios.length > 0) {
            return res.status(400).json({ erro: 'Você não pode excluir este perfil porque existem usuários vinculados a ele!' });
        }

        await db.promise().query('DELETE FROM perfis WHERE id = ?', [req.params.id]);
        res.json({ mensagem: 'Perfil excluído com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao excluir perfil' });
    }
});


// ==========================================
// ROTAS DE USUÁRIOS / LOGINS
// ==========================================

router.get('/usuarios', async (req, res) => {
    try {
        const sql = `
            SELECT u.id, u.nome, u.email, p.nome as perfil_nome 
            FROM usuarios u 
            LEFT JOIN perfis p ON u.perfil_id = p.id
        `;
        const [usuarios] = await db.promise().query(sql);
        res.json(usuarios);
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao buscar usuários' });
    }
});

router.post('/usuarios', async (req, res) => {
    try {
        const { nome, email, senha, perfil_id } = req.body;
        const [existe] = await db.promise().query('SELECT id FROM usuarios WHERE email = ?', [email]);
        if (existe.length > 0) return res.status(400).json({ erro: 'Este e-mail já está em uso!' });

        await db.promise().query(
            'INSERT INTO usuarios (nome, email, senha, perfil_id) VALUES (?, ?, ?, ?)',
            [nome, email, senha, perfil_id]
        );
        res.json({ mensagem: 'Usuário criado com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao criar usuário' });
    }
});

router.delete('/usuarios/:id', async (req, res) => {
    try {
        await db.promise().query('DELETE FROM usuarios WHERE id = ?', [req.params.id]);
        res.json({ mensagem: 'Usuário excluído com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao excluir usuário' });
    }
});

// ==========================================
// ROTAS DE CONFIGURAÇÃO (CORES E LOGO)
// ==========================================

// Buscar a cor e logo atuais
router.get('/configuracoes', async (req, res) => {
    try {
        const [config] = await db.promise().query('SELECT * FROM configuracoes WHERE id = 1');
        res.json(config[0]);
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao buscar configurações' });
    }
});

// Salvar a nova cor e logo
router.put('/configuracoes', async (req, res) => {
    try {
        const { nome_empresa, cor_tema, url_logo } = req.body;
        await db.promise().query(
            'UPDATE configuracoes SET nome_empresa = ?, cor_tema = ?, url_logo = ? WHERE id = 1',
            [nome_empresa, cor_tema, url_logo]
        );
        res.json({ mensagem: 'Configurações atualizadas com sucesso!' });
    } catch (erro) {
        res.status(500).json({ erro: 'Erro ao atualizar configurações' });
    }
});

module.exports = router;