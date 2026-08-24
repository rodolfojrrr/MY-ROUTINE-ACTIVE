# Smart Routine SI

**Versão 4.0.0 — edição acadêmica local**

Aplicativo pessoal em Flutter para organizar a graduação em **Sistemas de Informação** no Android e no Windows. É um aplicativo nativo, não uma página dentro do navegador. Todos os dados ficam nos seus aparelhos: não há Firebase, Supabase, analytics, conta externa nem armazenamento em nuvem.

## Organização acadêmica

O conteúdo segue uma hierarquia única para evitar resumos e questões soltos:

```text
Semestre
└── Matéria
    └── Conteúdo
        ├── Resumos e imagens
        ├── Flashcards
        └── Questões de simulados
```

- semestres atuais, concluídos ou planejados;
- matérias com código, professor, sala, carga horária e ordem de exibição;
- conteúdos ordenados dentro de cada matéria;
- exclusão em cascata com confirmação para impedir registros órfãos;
- filtros por semestre, matéria e conteúdo nas telas de estudo.

## Menu principal somente para consulta

A tela inicial funciona como painel de exibição e não mistura formulários com sua rotina diária:

- horário de aulas de segunda a domingo;
- blocos rápidos sugeridos de `18:30–20:10` e `20:30–22:00`;
- semestre atual e todas as cadeiras cursadas em cada período;
- detalhes de cada matéria, seus conteúdos, resumos e avaliações;
- próximas provas, trabalhos, projetos, atividades e apresentações;
- totais de matérias, resumos, avaliações e questões.

Os cadastros e edições ficam no menu lateral, aberto pelos três traços no celular e permanentemente visível em telas maiores.

## Resumos com imagens e PDF

- título, texto completo e tags;
- vínculo obrigatório com matéria e conteúdo;
- várias imagens JPG/PNG em cada resumo;
- reordenação e remoção das imagens antes de salvar;
- busca e filtros acadêmicos;
- visualização em tela cheia;
- geração de um PDF individual com identificação do semestre, matéria e conteúdo, texto e imagens anexadas;
- compatibilidade com anotações antigas que usavam apenas uma imagem.

## Questões e simulados

- banco de questões com quatro alternativas, resposta correta e explicação;
- dificuldade e vínculo com matéria/conteúdo;
- simulado geral ou filtrado por cadeira e assunto;
- quantidade configurável e cronômetro opcional;
- navegação questão por questão e confirmação antes de entregar respostas em branco;
- resultado com percentual, correção detalhada e explicações;
- histórico local de tentativas e estatísticas de desempenho.

## Avaliações, flashcards e foco

- provas, trabalhos, projetos, atividades e apresentações;
- data, horário, peso, nota, observações, situação e conteúdo relacionado;
- agenda de próximas avaliações e histórico concluído;
- flashcards por matéria e conteúdo, com repetição espaçada;
- revisão de cartões vencidos, acertos, erros e próxima revisão;
- cronômetro de foco/Pomodoro e histórico de tempo estudado.

## Privacidade, backup e sincronização

- SQLite local e independente em cada aparelho;
- exportação e importação manual do banco no formato `.mra`;
- textos e imagens incluídos no backup;
- cópia de segurança automática antes de importações e sincronizações;
- sincronização bidirecional PC ↔ celular pela mesma rede Wi‑Fi;
- mesclagem por UUID, revisão e horário de atualização;
- exclusões sincronizadas e conflitos preservados para revisão;
- PIN local opcional;
- limite ampliado para transferir resumos com várias imagens.

O formato `.mra`, o identificador Android, a pasta de dados do Windows e o protocolo Wi‑Fi foram mantidos. Assim, esta versão pode ser instalada como atualização da anterior e continua aceitando seus backups existentes.

## Primeiro uso recomendado

1. Abra **Organização acadêmica**.
2. Cadastre o semestre atual.
3. Cadastre as matérias desse semestre.
4. Cadastre os conteúdos de cada matéria.
5. Monte o horário semanal.
6. Use **Resumos**, **Flashcards**, **Simulados** e **Avaliações** durante o período.
7. Faça backup `.mra` regularmente e sincronize quando PC e celular estiverem na mesma rede.

## Gerar APK e Windows pelo GitHub

1. Execute `07_SUBIR_GITHUB.bat` no computador ou envie os arquivos pelo aplicativo/site do GitHub.
2. Abra a aba **Actions** do repositório.
3. Aguarde o fluxo **Validar e gerar aplicativos** ficar verde.
4. Abra a execução e baixe os artefatos:
   - `Smart-Routine-SI-Android` — contém o APK;
   - `Smart-Routine-SI-Windows` — contém a versão portátil e o instalador.

O workflow executa `flutter analyze`, `flutter test`, confirma que o repositório não contém banco pessoal e gera as duas plataformas.

## BATs incluídos

| Objetivo | Arquivo |
|---|---|
| Preparar dependências | `01_PREPARAR_PROJETO.bat` |
| Executar no Windows | `02_EXECUTAR_WINDOWS.bat` |
| Executar no Android por USB | `03_EXECUTAR_ANDROID_USB.bat` |
| Analisar e testar | `04_VALIDAR_PROJETO.bat` |
| Gerar APK local | `05_GERAR_APK.bat` |
| Gerar Windows portátil e Setup | `06_GERAR_WINDOWS.bat` |
| Criar commit e enviar ao GitHub | `07_SUBIR_GITHUB.bat` |
| Limpar arquivos de compilação | `08_LIMPAR_BUILD.bat` |
| Criar assinatura Android fixa | `09_GERAR_ASSINATURA_ANDROID.bat` |

## Atualização Android sem perder dados

Para que o Android aceite um APK novo por cima do instalado, as versões precisam usar a mesma chave. Execute `09_GERAR_ASSINATURA_ANDROID.bat` uma única vez e cadastre os quatro Secrets `MRA_*` no GitHub. Esses nomes foram mantidos por compatibilidade. Leia `docs/ASSINATURA_ANDROID.md` antes da primeira migração.

> Se o APK antigo usar outra assinatura, exporte primeiro um backup `.mra`. Depois de instalar a edição assinada pela chave fixa, importe esse backup e preserve a mesma chave em todas as atualizações futuras.

## Estrutura principal

```text
lib/core/       banco, modelo acadêmico, PDF, backup e sincronização
lib/screens/    painel, resumos, simulados, avaliações e organização
lib/widgets/    componentes visuais responsivos
test/           testes de backup, dados acadêmicos e compatibilidade
android/        aplicativo Android
windows/        aplicativo Windows
installer/      instalador Inno Setup
docs/           documentação técnica e operacional
```

O repositório deve permanecer sem arquivos `.db`, `.sqlite`, `.sqlite3`, `.mra`, `.jks` ou senhas.
