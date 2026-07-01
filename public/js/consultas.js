// consultas.js
// -----------------------------------------------------------------------
// FRONT-END da página de Consultas. Cada função chama uma rota da API que
// executa uma consulta com INNER JOIN no banco e devolve o resultado em JSON.
// -----------------------------------------------------------------------

function formatarData(iso) {
  return new Date(iso).toLocaleDateString('pt-BR');
}

// Consulta 1: número de alunos por curso (INNER JOIN + GROUP BY)
async function carregarAlunosPorCurso() {
  const resposta = await fetch('/api/consultas/alunos-por-curso');
  const dados = await resposta.json();

  const corpo = document.getElementById('tabela-por-curso');
  corpo.innerHTML = '';
  dados.forEach(d => {
    corpo.insertAdjacentHTML('beforeend',
      `<tr><td>${d.curso}</td><td>${d.total_alunos}</td></tr>`);
  });
}

// Consulta 2: alunos por período de ingresso (INNER JOIN + WHERE BETWEEN)
async function consultarPeriodo() {
  const inicio = document.getElementById('inicio').value;
  const fim = document.getElementById('fim').value;

  if (!inicio || !fim) {
    alert('Informe as duas datas.');
    return;
  }

  const resposta = await fetch(`/api/consultas/alunos-periodo?inicio=${inicio}&fim=${fim}`);
  const dados = await resposta.json();

  const corpo = document.getElementById('tabela-periodo');
  corpo.innerHTML = '';

  if (dados.length === 0) {
    corpo.innerHTML = '<tr><td colspan="4">Nenhum aluno encontrado nesse período.</td></tr>';
    return;
  }

  dados.forEach(d => {
    corpo.insertAdjacentHTML('beforeend', `
      <tr>
        <td>${d.nome}</td>
        <td>${d.email}</td>
        <td>${d.curso}</td>
        <td>${formatarData(d.data_ingresso)}</td>
      </tr>`);
  });
}

// A consulta 1 carrega automaticamente ao abrir a página
carregarAlunosPorCurso();
