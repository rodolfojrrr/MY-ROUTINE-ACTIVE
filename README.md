# Smart Routine SI

**Versão 5.5.1 PRO — recuperação automática de dados grandes no Android**

Aplicativo Flutter nativo para Android e Windows. Foi pensado para a graduação em **Sistemas de Informação**, mas também organiza cursos livres, trilhas, certificações e estudos pessoais. Não há WebView, nuvem, analytics ou login externo: banco, imagens, projetos e credenciais ficam somente nos aparelhos do usuário.

## O que há nesta versão

- contas locais para vários usuários, com senha, pergunta de segurança e código de recuperação;
- migração automática dos dados existentes para a primeira conta, sem zerar o banco;
- Faculdade logo abaixo do Menu principal, separada de cursos e das demais ferramentas;
- navegação visual por pastas: semestres → matérias → conteúdos → materiais;
- semestre atual destacado e semestres mais recentes sempre primeiro;
- semestres, matérias, conteúdos, cursos e resumos com cor, símbolo e imagem de fundo personalizados;
- cada conteúdo reúne pastas ilustradas de Resumos, Códigos, Imagens, Anexos, Simulados, Flashcards e Provas/Notas, cada uma com sua própria cor;
- cadastros aparecem imediatamente na pasta aberta, sem sair e entrar novamente;
- metas diárias flexíveis e cronograma semanal opcional;
- cronômetro global que continua ao trocar de tela e volta **pausado** após fechar ou ocultar o aplicativo;
- Kanban com Pendentes, Fazendo e Concluídas, movimentação livre, prazos e limpeza configurável;
- editor de resumos em uma folha A4 escura, centralizada, com margens seguras, rolagem interna e modo foco;
- painéis de organização e materiais mais estreitos, recolhíveis separadamente ou ocultáveis por completo no PC;
- formatação profissional com desfazer/refazer, títulos, tamanhos, negrito, itálico, sublinhado, tachado, alinhamento, entrelinhas, marca-texto, listas, checklist, citação, recuo e divisória;
- código em linha e blocos de código diferenciados, com fonte monoespaçada, fundo próprio, atalho de teclado e exportação formatada no PDF;
- resumos com várias imagens, anexos de arquivos, rascunho automático e PDF individual;
- cursos livres separados, com instituição, carga horária, progresso e imagens de certificados;
- conversor local de arquivos para PDF;
- temas azul, roxo, cinza, verde, amarelo e colorido, além de editor avançado para fundo, superfícies, campos, bordas, menu, cor principal e secundária;
- simulados, avaliações, flashcards e IDE acadêmica local;
- backup `.mra`, importação de `.mra.gz` do WhatsApp e sincronização Wi‑Fi bidirecional entre celular, notebook e PC;
- lixeira no menu principal para restaurar, excluir definitivamente ou esvaziar, sempre com confirmação;
- interface responsiva para celular compacto e desktop.
- menu lateral do PC expansível/recolhível, com a escolha salva por usuário.

## Organização acadêmica

```text
Faculdade
└── Semestre (mais atual primeiro)
    └── Matéria (cor, símbolo e capa)
        └── Conteúdo (cor, símbolo e capa)
            ├── Resumos
            ├── Códigos
            ├── Imagens
            ├── Anexos
            ├── Simulados
            ├── Flashcards
            └── Provas, datas e notas

Resumos
└── Pasta personalizada (cor, símbolo e capa)

Cursos
└── Curso livre
    └── Progresso, observações e certificados
```

O painel inicial é de consulta. Logo depois da saudação aparece o horário semanal, com borda e cor da matéria selecionada. Os antigos contadores soltos de matérias/resumos/avaliações/questões foram removidos. Cadastros e edições ficam no menu lateral, que aparece pelos três traços no celular e pode ser expandido ou recolhido no desktop.

## Metas, cronômetro e Kanban

As metas podem ser gerais ou vinculadas a uma matéria/conteúdo. O cronograma semanal serve como sugestão, não como trava: o usuário continua livre para iniciar qualquer foco ou meta. O cronômetro pertence ao aplicativo inteiro, portanto não zera quando o usuário abre um resumo, consulta o horário ou troca de menu.

Se o aplicativo for ocultado ou fechado, o estado é salvo e a sessão volta pausada na próxima abertura. O Kanban permite mover cartões por arrastar, pelo menu de ações ou por botões, e a permanência de concluídos pode ser configurada de zero a 90 dias ou para sempre.

## Resumos e PDF

- rascunho local salvo durante a digitação;
- restauração do rascunho ao reabrir o formulário;
- matéria e conteúdo relacionados;
- editor escuro integrado à paleta do aplicativo, amplo e responsivo;
- formatação persistente por trecho e por parágrafo;
- várias imagens JPG/PNG e até 20 anexos diversos por resumo;
- filtros por semestre, matéria e conteúdo;
- biblioteca exibida como pastas personalizáveis, com capa, cor e símbolo próprios;
- `Tab` e `Shift+Tab` aplicam e removem recuo como em uma IDE;
- PDF individual com navegação de volta, identificação acadêmica, texto formatado, imagens e relação dos anexos;
- conversor geral para imagens, texto, código, HTML e PDF;
- no Windows, DOCX/XLSX/PPTX tentam usar LibreOffice ou Microsoft Office; sem esses programas, o aplicativo cria um PDF de leitura com o texto extraído.

O arquivo original nunca é apagado ou substituído pelo conversor.

## Contas locais e recuperação

Cada conta enxerga apenas seus próprios dados. Senhas, respostas e códigos são armazenados como hashes com salt; o aplicativo não guarda a senha em texto. A recuperação funciona pela pergunta de segurança ou pelo código exibido no cadastro.

Como não existe servidor, não há envio de e-mail. Guarde o código fora do aparelho. Credenciais não entram no backup nem na sincronização.

Para usar a mesma coleção acadêmica no PC e no celular, crie uma conta com o **mesmo nome de usuário** nos dois aparelhos. As senhas podem ser diferentes, pois são locais. Depois, sincronize pelo Wi‑Fi ou importe o `.mra` na conta correspondente.

## Atualização sem perder dados

1. Não desinstale o aplicativo e não limpe os dados.
2. Por segurança, exporte um `.mra` na versão atual.
3. Instale a nova versão por cima usando a mesma assinatura Android.
4. Na primeira abertura, crie a primeira conta local.
5. Essa conta assume os registros já existentes e o aplicativo cria antes um snapshot automático.
6. Se havia PIN, informe-o uma única vez durante a migração.

O banco passa da versão 1 para a versão 2 adicionando a tabela de contas. Na versão 3, imagens, anexos e rascunhos grandes são divididos em blocos seguros antes da leitura no Android. A tabela acadêmica existente não é recriada. Leia `00_MIGRACAO_PARA_V5.txt` e `00_RECUPERAR_BANCO_ANDROID_V5.5.1.txt`.

## Backup e sincronização local

- SQLite separado em cada aparelho;
- exportação da conta aberta em `.mra`;
- importação de `.mra` e `.mra.gz` sem renomear o arquivo recebido pelo WhatsApp;
- snapshot automático antes de importar, sincronizar ou migrar dados legados;
- sincronização bidirecional na mesma rede Wi‑Fi entre quaisquer dois aparelhos compatíveis, sem internet;
- seleção entre os IPs do PC, priorizando Wi‑Fi/Ethernet e rebaixando VPN, WSL, Hyper‑V e adaptadores virtuais;
- conflitos e exclusões preservados para evitar perda silenciosa.

## IDE acadêmica

O editor nativo organiza projetos por período, matéria e conteúdo e oferece vários arquivos, busca, realce, numeração de linhas, desfazer/refazer, autosave, importação/exportação e saída de execução. Há modelos para Dart, Python, Java, JavaScript, TypeScript, C, C++, C#, Kotlin, PHP, SQL, HTML/CSS e JSON.

No Android, os projetos podem ser criados, editados e sincronizados. No Windows, a execução usa somente os compiladores já instalados no PC. Consulte `docs/IDE_ACADEMICA.md`.

## Gerar APK e Windows pelo GitHub

1. Extraia o ZIP.
2. Execute `07_SUBIR_GITHUB.bat`.
3. Digite apenas uma mensagem de commit ou pressione Enter.
4. No GitHub, abra **Actions → Validar e gerar aplicativos**.
5. Baixe `Smart-Routine-SI-Android` e `Smart-Routine-SI-Windows`.

O workflow executa análise estática, 54 testes, auditoria de arquivos pessoais e gera o APK, o Windows portátil e o instalador `Setup.exe`.

## BATs incluídos

| Objetivo | Arquivo |
|---|---|
| Preparar dependências | `01_PREPARAR_PROJETO.bat` |
| Executar no Windows | `02_EXECUTAR_WINDOWS.bat` |
| Executar no Android por USB | `03_EXECUTAR_ANDROID_USB.bat` |
| Analisar e testar | `04_VALIDAR_PROJETO.bat` |
| Gerar APK local | `05_GERAR_APK.bat` |
| Gerar Windows e Setup | `06_GERAR_WINDOWS.bat` |
| Enviar ao GitHub | `07_SUBIR_GITHUB.bat` |
| Limpar compilação | `08_LIMPAR_BUILD.bat` |
| Criar assinatura Android | `09_GERAR_ASSINATURA_ANDROID.bat` |

O repositório deve permanecer sem `.db`, `.sqlite`, `.mra`, `.jks`, chaves ou dados pessoais.
