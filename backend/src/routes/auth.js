const express = require('express');
const db = require('../config/db');
const router = express.Router();

router.post('/login', async (req, res) => {
    try {
        const { email, senha } = req.body;
        
        // Faz um JOIN para buscar o usuário E as permissões do perfil dele
        const sql = `
            SELECT u.nome, u.email, p.nome as perfil_nome, 
                   p.is_admin, p.fap_editar, p.absenteismo_editar 
            FROM usuarios u 
            INNER JOIN perfis p ON u.perfil_id = p.id 
            WHERE u.email = ? AND u.senha = ?
        `;
        const [users] = await db.promise().query(sql, [email, senha]);
        
        if (users.length > 0) {
            res.json(users[0]); // Devolve todos os dados e permissões para o Flutter
        } else {
            res.status(401).json({ erro: 'E-mail ou senha incorretos!' });
        }
    } catch (erro) {
        res.status(500).json({ erro: 'Erro interno no servidor.' });
    }
});

module.exports = router;