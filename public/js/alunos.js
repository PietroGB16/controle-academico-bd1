// alunos.js
// -----------------------------------------------------------------------
// FRONT-END da página de Alunos. Consome a API REST com fetch().
// Também precisa carregar a lista de cursos (para os <select> de filtro
// e de cadastro), porque aluno tem uma chave estrangeira para curso.
// -----------------------------------------------------------------------

const API_ALUNOS = '/api/alunos';
const API_CURSOS = '/api/cursos';

function mostrarMensagem(texto, tipo) {
  const el = document.getElementById('mensagem');
  el.textContent = texto;
  el.className = 'msg ' + tipo;
  setTimeout(() => { el.className = 'msg'; }, 4000);
}

function formatarData(iso) {
  return new Date(iso).toLocaleDateString('pt-BR');
}

// Carrega os cursos e preenche os dois <select> (filtro e formulário)
async function carregarCursosNosSelects() {
  const resposta = await fetch(API_CURSOS);
  const cursos = await resposta.json();

  const selFiltro = document.getElementById('busca-curso');
  const selForm = document.getElementById('id_curso');
  selForm.innerHTML = '';

  cursos.forEach(c => {
    selFiltro.insertAdjacentHTML('beforeend',
      `<option value="${c.id_curso}">${c.nome}</option>`);
    selForm.insertAdjacentHTML('beforeend',
      `<option value="${c.id_curso}">${c.nome}</option>`);
  });
}

// LISTAR alunos aplicando os filtros de nome e curso (SELECT ... WHERE)
async function carregarAlunos() {
  const nome = document.getElementById('busca-nome').value.trim();
  const idCurso = document.getElementById('busca-curso').value;

  const params = new URLSearchParams();
  if (nome) params.append('nome', nome);
  if (idCurso) params.append('id_curso', idCurso);

  const url = params.toString() ? `${API_ALUNOS}?${params}` : API_ALUNOS;
  const resposta = await fetch(url);
  const alunos = await resposta.json();

  const corpo = document.getElementById('corpo-tabela');
  corpo.innerHTML = '';

  alunos.forEach(a => {
    const linha = document.createElement('tr');
    linha.innerHTML = `
      <td>${a.matricula}</td>
      <td>${a.nome}</td>
      <td>${a.email}</td>
      <td>${a.nome_curso}</td>
      <td>${formatarData(a.data_nascimento)}</td>
      <td>${formatarData(a.data_ingresso)}</td>
      <td class="acoes">
        <button onclick='abrirFormEdicao(${JSON.stringify(a)})'>Editar</button>
        <button class="btn-excluir" onclick="excluirAluno(${a.id_aluno})">Excluir</button>
      </td>`;
    corpo.appendChild(linha);
  });
}

function abrirFormNovo() {
  document.getElementById('modal-titulo').textContent = 'Novo Aluno';
  document.getElementById('id_aluno').value = '';
  document.getElementById('matricula').value = '';
  document.getElementById('nome').value = '';
  document.getElementById('email').value = '';
  document.getElementById('data_nascimento').value = '';
  document.getElementById('data_ingresso').value = '';
  document.getElementById('modal').classList.add('aberto');
}

function abrirFormEdicao(a) {
  document.getElementById('modal-titulo').textContent = 'Editar Aluno';
  document.getElementById('id_aluno').value = a.id_aluno;
  document.getElementById('matricula').value = a.matricula;
  document.getElementById('nome').value = a.nome;
  document.getElementById('email').value = a.email;
  document.getElementById('data_nascimento').value = a.data_nascimento.slice(0, 10);
  document.getElementById('data_ingresso').value = a.data_ingresso.slice(0, 10);
  document.getElementById('id_curso').value = a.id_curso;
  document.getElementById('modal').classList.add('aberto');
}

function fecharForm() {
  document.getElementById('modal').classList.remove('aberto');
}

// SALVAR: POST (novo) ou PUT (edição)
async function salvarAluno() {
  const id = document.getElementById('id_aluno').value;
  const dados = {
    matricula: document.getElementById('matricula').value,
    nome: document.getElementById('nome').value,
    email: document.getElementById('email').value,
    data_nascimento: document.getElementById('data_nascimento').value,
    data_ingresso: document.getElementById('data_ingresso').value,
    id_curso: document.getElementById('id_curso').value
  };

  const url = id ? `${API_ALUNOS}/${id}` : API_ALUNOS;
  const metodo = id ? 'PUT' : 'POST';

  const resposta = await fetch(url, {
    method: metodo,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(dados)
  });

  if (resposta.ok) {
    fecharForm();
    mostrarMensagem('Aluno salvo com sucesso!', 'ok');
    carregarAlunos();
  } else {
    const erro = await resposta.json();
    mostrarMensagem(erro.erro || 'Erro ao salvar.', 'erro');
  }
}

// EXCLUIR (regra CASCADE: matrículas do aluno seriam removidas junto)
async function excluirAluno(id) {
  if (!confirm('Excluir este aluno? Suas matrículas também serão removidas (CASCADE).')) return;

  const resposta = await fetch(`${API_ALUNOS}/${id}`, { method: 'DELETE' });

  if (resposta.ok) {
    mostrarMensagem('Aluno excluído.', 'ok');
    carregarAlunos();
  } else {
    const erro = await resposta.json();
    mostrarMensagem(erro.erro || 'Erro ao excluir.', 'erro');
  }
}

// Inicialização: primeiro carrega os cursos, depois a lista de alunos
(async function iniciar() {
  await carregarCursosNosSelects();
  await carregarAlunos();
})();
