// server.js
// -----------------------------------------------------------------------
// BACK-END: servidor Express que faz DUAS coisas:
//   1) Serve os arquivos estáticos do front-end (HTML, CSS, JS) da pasta /public
//   2) Expõe uma API REST (rotas /api/...) que devolve JSON e fala com o MySQL
//
// O front-end (JavaScript no navegador) consome essas rotas com fetch().
// -----------------------------------------------------------------------
const express = require('express');
const path = require('path');
const pool = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());                                   // lê o corpo JSON das requisições
app.use(express.static(path.join(__dirname, 'public')));   // serve o front-end

// =====================================================================
// API: CURSO
// =====================================================================

// LISTAR cursos (com busca opcional por nome -> SELECT ... WHERE)
app.get('/api/cursos', async (req, res) => {
  try {
    const { nome } = req.query;
    let sql = 'SELECT * FROM curso';
    const params = [];
    if (nome) { sql += ' WHERE nome LIKE ?'; params.push(`%${nome}%`); }
    sql += ' ORDER BY nome';
    const [cursos] = await pool.query(sql, params);
    res.json(cursos);
  } catch (err) {
    res.status(500).json({ erro: err.message });
  }
});

// OBTER um curso por id
app.get('/api/cursos/:id', async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM curso WHERE id_curso = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ erro: 'Curso não encontrado' });
  res.json(rows[0]);
});

// CRIAR curso (INSERT)
app.post('/api/cursos', async (req, res) => {
  try {
    const { codigo, nome, modalidade, carga_horaria, data_criacao } = req.body;
    const [r] = await pool.query(
      `INSERT INTO curso (codigo, nome, modalidade, carga_horaria, data_criacao)
       VALUES (?, ?, ?, ?, ?)`,
      [codigo, nome, modalidade, carga_horaria, data_criacao]
    );
    res.status(201).json({ id_curso: r.insertId });
  } catch (err) {
    res.status(400).json({ erro: err.message });
  }
});

// ATUALIZAR curso (UPDATE)
app.put('/api/cursos/:id', async (req, res) => {
  try {
    const { codigo, nome, modalidade, carga_horaria, data_criacao } = req.body;
    await pool.query(
      `UPDATE curso SET codigo = ?, nome = ?, modalidade = ?, carga_horaria = ?, data_criacao = ?
       WHERE id_curso = ?`,
      [codigo, nome, modalidade, carga_horaria, data_criacao, req.params.id]
    );
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ erro: err.message });
  }
});

// EXCLUIR curso (DELETE) -- a regra RESTRICT pode bloquear se houver alunos
app.delete('/api/cursos/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM curso WHERE id_curso = ?', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    // ER_ROW_IS_REFERENCED_2: a FK com ON DELETE RESTRICT impediu a exclusão
    if (err.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(409).json({
        erro: 'Não é possível excluir: existem alunos vinculados a este curso (regra RESTRICT).'
      });
    }
    res.status(500).json({ erro: err.message });
  }
});

// =====================================================================
// API: ALUNO
// =====================================================================

// LISTAR alunos (busca opcional por nome e/ou curso -> SELECT ... WHERE)
// Já traz o nome do curso via JOIN para exibir na tabela.
app.get('/api/alunos', async (req, res) => {
  try {
    const { nome, id_curso } = req.query;
    let sql = `SELECT a.*, c.nome AS nome_curso
               FROM aluno a
               INNER JOIN curso c ON c.id_curso = a.id_curso
               WHERE 1 = 1`;
    const params = [];
    if (nome) { sql += ' AND a.nome LIKE ?'; params.push(`%${nome}%`); }
    if (id_curso) { sql += ' AND a.id_curso = ?'; params.push(id_curso); }
    sql += ' ORDER BY a.nome';
    const [alunos] = await pool.query(sql, params);
    res.json(alunos);
  } catch (err) {
    res.status(500).json({ erro: err.message });
  }
});

// OBTER um aluno por id
app.get('/api/alunos/:id', async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM aluno WHERE id_aluno = ?', [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ erro: 'Aluno não encontrado' });
  res.json(rows[0]);
});

// CRIAR aluno (INSERT)
app.post('/api/alunos', async (req, res) => {
  try {
    const { matricula, nome, email, data_nascimento, data_ingresso, id_curso } = req.body;
    const [r] = await pool.query(
      `INSERT INTO aluno (matricula, nome, email, data_nascimento, data_ingresso, id_curso)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [matricula, nome, email, data_nascimento, data_ingresso, id_curso]
    );
    res.status(201).json({ id_aluno: r.insertId });
  } catch (err) {
    res.status(400).json({ erro: err.message });
  }
});

// ATUALIZAR aluno (UPDATE)
app.put('/api/alunos/:id', async (req, res) => {
  try {
    const { matricula, nome, email, data_nascimento, data_ingresso, id_curso } = req.body;
    await pool.query(
      `UPDATE aluno SET matricula = ?, nome = ?, email = ?, data_nascimento = ?,
              data_ingresso = ?, id_curso = ?
       WHERE id_aluno = ?`,
      [matricula, nome, email, data_nascimento, data_ingresso, id_curso, req.params.id]
    );
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ erro: err.message });
  }
});

// EXCLUIR aluno (DELETE) -- regra CASCADE remove as matrículas dele junto
app.delete('/api/alunos/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM aluno WHERE id_aluno = ?', [req.params.id]);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ erro: err.message });
  }
});

// =====================================================================
// API: CONSULTAS (envolvendo duas tabelas com INNER JOIN)
// =====================================================================

// 1) Número de alunos por curso (INNER JOIN + GROUP BY)
app.get('/api/consultas/alunos-por-curso', async (req, res) => {
  const [dados] = await pool.query(`
    SELECT c.nome AS curso, COUNT(a.id_aluno) AS total_alunos
    FROM curso c
    INNER JOIN aluno a ON a.id_curso = c.id_curso
    GROUP BY c.id_curso, c.nome
    ORDER BY total_alunos DESC
  `);
  res.json(dados);
});

// 2) Alunos que ingressaram num período (INNER JOIN + WHERE ... BETWEEN)
app.get('/api/consultas/alunos-periodo', async (req, res) => {
  const { inicio, fim } = req.query;
  if (!inicio || !fim) return res.json([]);
  const [dados] = await pool.query(`
    SELECT a.nome, a.email, c.nome AS curso, a.data_ingresso
    FROM aluno a
    INNER JOIN curso c ON c.id_curso = a.id_curso
    WHERE a.data_ingresso BETWEEN ? AND ?
    ORDER BY a.data_ingresso
  `, [inicio, fim]);
  res.json(dados);
});

app.listen(PORT, () => {
  console.log(`Servidor rodando em http://localhost:${PORT}`);
});
