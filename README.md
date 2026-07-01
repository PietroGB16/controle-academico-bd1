# Controle de Atividades Acadêmicas

Aplicação web para o Trabalho Prático de Banco de Dados I (IFRJ Campus Niterói).

## Arquitetura (duas camadas separadas)

```
  NAVEGADOR                          SERVIDOR                      BANCO
  -----------                        ----------                   -------
  HTML + CSS + JS   --- fetch() -->  API REST (Node/Express) ---> MySQL
   (front-end)       (JSON)           (back-end)          (SQL)
```

- **Front-end:** HTML + CSS + JavaScript puro (sem framework). O JavaScript
  do navegador usa `fetch()` para pedir e enviar dados em JSON.
- **Back-end:** Node.js + Express, expõe uma API REST (`/api/...`) que executa
  as queries SQL e devolve JSON.
- **Banco:** MySQL.

## Estrutura de pastas

```
controle-academico-app/
├── server.js              # back-end: API REST + serve os arquivos estáticos
├── db.js                  # conexão (pool) com o MySQL
├── package.json
└── public/                # front-end (tudo o que roda no navegador)
    ├── index.html
    ├── cursos.html
    ├── alunos.html
    ├── consultas.html
    ├── css/style.css
    └── js/
        ├── cursos.js
        ├── alunos.js
        └── consultas.js
```

## Pré-requisitos
- Node.js instalado (v18+)
- MySQL Server rodando localmente
- Banco `controle_academico` já criado (rode o `controle_academico.sql`
  no MySQL Workbench ou DBeaver antes de iniciar)

## Configuração da conexão

Por padrão o app conecta como `root` sem senha em `localhost:3306`,
banco `controle_academico` (veja `db.js`). Se o seu MySQL tiver senha,
ajuste em `db.js` ou defina variáveis de ambiente:

Windows (PowerShell/CMD):
```
set DB_USER=root
set DB_PASS=sua_senha
```

## Como executar

```
npm install
npm start
```

Abra **http://localhost:3000** no navegador.

## Endpoints da API (referência)

| Método | Rota                                  | O que faz                          |
|--------|---------------------------------------|------------------------------------|
| GET    | /api/cursos?nome=                     | lista cursos (filtro por nome)     |
| POST   | /api/cursos                           | cadastra curso (INSERT)            |
| PUT    | /api/cursos/:id                       | edita curso (UPDATE)               |
| DELETE | /api/cursos/:id                       | exclui curso (RESTRICT pode barrar)|
| GET    | /api/alunos?nome=&id_curso=           | lista alunos (filtros + JOIN)      |
| POST   | /api/alunos                           | cadastra aluno (INSERT)            |
| PUT    | /api/alunos/:id                       | edita aluno (UPDATE)               |
| DELETE | /api/alunos/:id                       | exclui aluno (CASCADE)             |
| GET    | /api/consultas/alunos-por-curso       | INNER JOIN + GROUP BY              |
| GET    | /api/consultas/alunos-periodo?inicio=&fim= | INNER JOIN + WHERE BETWEEN    |
