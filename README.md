# My Routine Active

Aplicativo unificado para organizar estudos, treinos e finanças em uma única conta, com interface responsiva para celular e computador.

## Módulos

### Estudos

- horários de aula e matérias
- provas, trabalhos e tarefas
- anotações com imagens
- flashcards, questões e simulados
- sessões de foco e acompanhamento de progresso

### Treinos

- fichas e exercícios editáveis
- configuração individual de carga e repetições por série
- séries de aquecimento, trabalho e até a falha
- cronômetro separado para exercício e descanso
- histórico, volume, medidas, cardio, hidratação e fotos de progresso

### Finanças

- rendas recorrentes por dia fixo do mês
- contas, transações e transferências
- cartões, compras, faturas e parcelamentos
- dívidas e empréstimos
- categorias, orçamentos, investimentos e planejamento 50/30/20
- projeção mensal e calendário financeiro

## Estado desta cópia

Este pacote foi preparado para publicação no GitHub com o banco zerado:

- nenhum usuário ou e-mail salvo
- nenhum salário, cartão, conta, dívida ou movimentação
- nenhuma matéria, anotação, imagem, horário ou avaliação
- nenhum treino, medida corporal ou histórico
- nenhuma credencial, arquivo de banco ou chave de assinatura
- a migração cria apenas a estrutura vazia da tabela `app_states`

As categorias financeiras e a biblioteca genérica de exercícios são configurações do próprio sistema, não dados pessoais.

## Requisitos

- Node.js 22 LTS ou superior
- Git para Windows
- Git Bash, instalado junto com o Git, para executar a validação completa no Windows

## Uso rápido no Windows

| Arquivo | Função |
| --- | --- |
| `01_INSTALAR_DEPENDENCIAS.bat` | Instala exatamente as dependências registradas no projeto |
| `02_INICIAR_APP.bat` | Inicia o ambiente local de desenvolvimento |
| `03_TESTAR_PROJETO.bat` | Executa lint, compilação e testes |
| `04_SUBIR_OU_ATUALIZAR_GITHUB.bat` | Cria o repositório Git local, faz o commit e envia ao GitHub |
| `05_ZERAR_BANCO_LOCAL.bat` | Apaga somente o banco local de desenvolvimento, após confirmação |

## Como subir no GitHub

1. Crie um repositório vazio no GitHub, sem adicionar README, licença ou `.gitignore`.
2. Extraia este ZIP para uma pasta normal do computador.
3. Execute `04_SUBIR_OU_ATUALIZAR_GITHUB.bat`.
4. Cole o endereço HTTPS do repositório quando o arquivo solicitar.
5. Faça login no GitHub caso o Gerenciador de Credenciais abra uma janela.

O mesmo arquivo pode ser usado futuramente para enviar atualizações.

## Desenvolvimento local

Execute `01_INSTALAR_DEPENDENCIAS.bat` uma vez e depois `02_INICIAR_APP.bat`. O modo local usa armazenamento separado e não acessa os dados da versão publicada.

A autenticação real com ChatGPT, o banco D1 e o armazenamento de imagens R2 são fornecidos pelo ambiente de hospedagem. O arquivo `.openai/hosting.json` deste pacote não contém o identificador do site publicado.

## Comandos pelo terminal

```bash
npm ci
npm run dev
npm run lint
npm test
```

## Tecnologias

- React 19
- Next.js 16
- Vinext e Vite
- Cloudflare Workers, D1 e R2
- Drizzle ORM
- TypeScript

## Banco de dados

O schema fica em `db/schema.ts` e a migração inicial em `drizzle/0000_busy_crusher_hogan.sql`. A tabela usa o e-mail autenticado como chave para manter os dados de cada conta separados.

Não adicione arquivos `.env`, bancos locais, chaves Android ou certificados ao GitHub. O `.gitignore` já bloqueia esses arquivos.
