// cursos.js
// -----------------------------------------------------------------------
// FRONT-END (JavaScript do navegador). Toda a comunicação com o back-end
// é feita com fetch(), recebendo/enviando JSON. Nenhuma query SQL aqui:
// o JS só pede dados à API REST, que é quem fala com o MySQL.
// -----------------------------------------------------------------------

const API = '/api/cursos';

// Mostra uma mensagem de sucesso ou erro no topo da tabela
function mostrarMensagem(texto, tipo) {
  const el = document.getElementById('mensagem');
  el.textContent = texto;
  el.className = 'msg ' + tipo;
  setTimeout(() => { el.className = 'msg'; }, 4000);
}

// Formata uma data ISO (YYYY-MM-DD...) para o padrão brasileiro
function formatarData(iso) {
  return new Date(iso).toLocaleDateString('pt-BR');
}

// LISTAR: busca os cursos na API e monta as linhas da tabela
async function carregarCursos() {
  const busca = document.getElementById('busca').value.trim();
  const url = busca ? `${API}?nome=${encodeURIComponent(busca)}` : API;

  const resposta = await fetch(url);
  const cursos = await resposta.json();

  const corpo = document.getElementById('corpo-tabela');
  corpo.innerHTML = '';

  cursos.forEach(c => {
    const linha = document.createElement('tr');
    linha.innerHTML = `
      <td>${c.codigo}</td>
      <td>${c.nome}</td>
      <td>${c.modalidade}</td>
      <td>${c.carga_horaria}h</td>
      <td>${formatarData(c.data_criacao)}</td>
      <td class="acoes">
        <button onclick='abrirFormEdicao(${JSON.stringify(c)})'>Editar</button>
        <button class="btn-excluir" onclick="excluirCurso(${c.id_curso})">Excluir</button>
      </td>`;
    corpo.appendChild(linha);
  });
}

// Abre o modal em modo "novo" (campos vazios)
function abrirFormNovo() {
  document.getElementById('modal-titulo').textContent = 'Novo Curso';
  document.getElementById('id_curso').value = '';
  document.getElementById('codigo').value = '';
  document.getElementById('nome').value = '';
  document.getElementById('modalidade').value = 'Presencial';
  document.getElementById('carga_horaria').value = '';
  document.getElementById('data_criacao').value = '';
  document.getElementById('modal').classList.add('aberto');
}

// Abre o modal em modo "edição" preenchido com os dados do curso
function abrirFormEdicao(c) {
  document.getElementById('modal-titulo').textContent = 'Editar Curso';
  document.getElementById('id_curso').value = c.id_curso;
  document.getElementById('codigo').value = c.codigo;
  document.getElementById('nome').value = c.nome;
  document.getElementById('modalidade').value = c.modalidade;
  document.getElementById('carga_horaria').value = c.carga_horaria;
  document.getElementById('data_criacao').value = c.data_criacao.slice(0, 10);
  document.getElementById('modal').classList.add('aberto');
}

function fecharForm() {
  document.getElementById('modal').classList.remove('aberto');
}

// SALVAR: decide entre INSERT (POST) e UPDATE (PUT) conforme houver id
async function salvarCurso() {
  const id = document.getElementById('id_curso').value;
  const dados = {
    codigo: document.getElementById('codigo').value,
    nome: document.getElementById('nome').value,
    modalidade: document.getElementById('modalidade').value,
    carga_horaria: document.getElementById('carga_horaria').value,
    data_criacao: document.getElementById('data_criacao').value
  };

  const url = id ? `${API}/${id}` : API;
  const metodo = id ? 'PUT' : 'POST';

  const resposta = await fetch(url, {
    method: metodo,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(dados)
  });

  if (resposta.ok) {
    fecharForm();
    mostrarMensagem('Curso salvo com sucesso!', 'ok');
    carregarCursos();
  } else {
    const erro = await resposta.json();
    mostrarMensagem(erro.erro || 'Erro ao salvar.', 'erro');
  }
}

// EXCLUIR: envia DELETE; trata o caso da regra RESTRICT (status 409)
async function excluirCurso(id) {
  if (!confirm('Deseja excluir este curso?')) return;

  const resposta = await fetch(`${API}/${id}`, { method: 'DELETE' });

  if (resposta.ok) {
    mostrarMensagem('Curso excluído.', 'ok');
    carregarCursos();
  } else {
    const erro = await resposta.json();
    mostrarMensagem(erro.erro || 'Erro ao excluir.', 'erro');
  }
}

// Carrega a lista assim que a página abre
carregarCursos();
