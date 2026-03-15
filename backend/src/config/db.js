const mysql = require('mysql2');
require('dotenv').config(); // Puxa as senhas do arquivo .env

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'SuaSenhaLocal',
    database: process.env.DB_NAME || 'sst_sistema',
    port: process.env.DB_PORT || 3306,
    // O Aiven exige conexão segura (SSL). Essa linha liga o SSL automaticamente.
    ssl: process.env.DB_HOST ? { rejectUnauthorized: false } : null,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

console.log('Conexão com o banco de dados estabelecida!');

module.exports = pool;