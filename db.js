// db.js
// -----------------------------------------------------------------------
// Pool de conexões com o MySQL. O pool reaproveita conexões já abertas,
// em vez de abrir/fechar uma conexão a cada requisição da API.
// -----------------------------------------------------------------------
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',          // ajuste para a senha do seu MySQL
  database: process.env.DB_NAME || 'controle_academico',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
