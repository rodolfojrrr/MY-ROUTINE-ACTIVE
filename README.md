# My Routine Active

**Versão 3.0.0 — escopo local final**

Aplicativo pessoal em Flutter para **Estudos, Treinos, Finanças e organização da rotina**, com a mesma base no Android e Windows. O aplicativo é local: não usa WebView, conta externa, Firebase, Supabase, analytics ou armazenamento em nuvem.

## Painel inicial integrado

A Home passou a funcionar como central da rotina. Ela reúne aulas do dia, próxima prova, flashcards vencidos, tempo de estudo, treino sugerido, hidratação, próximo lembrete e resumo financeiro do mês. Também oferece acesso rápido à busca global, agenda, lembretes, sincronização Wi‑Fi e configurações.

## Estudos

- painel **Hoje** com aulas, revisões, provas próximas e meta diária;
- matérias, professores, salas e grade semanal;
- provas e trabalhos;
- anotações com imagens incorporadas ao banco/backup;
- flashcards com repetição espaçada, acertos, erros, sequência e próxima revisão;
- sessão de revisão dedicada;
- banco de questões por matéria;
- simulados rápidos com resultado salvo;
- cronômetro de foco/Pomodoro em 15, 25 ou 50 minutos;
- meta diária e histórico de minutos estudados por matéria.

## Treinos

- fichas, exercícios e séries editáveis;
- tipos de série: aquecimento, normal, falha e drop-set;
- grupo muscular por exercício;
- biblioteca de exercícios pronta para adicionar às fichas;
- cronômetro de exercício e descanso;
- histórico de sessões com fotografia das séries executadas;
- volume por treino e por grupo muscular;
- recordes de carga;
- comparação de volume com o treino anterior;
- meta semanal e consistência;
- peso, cintura, peito, braço, coxa, gordura corporal e foto de evolução;
- hidratação diária;
- registro de cardio.

## Finanças

- salário fixo mensal e lançamentos recorrentes/avulsos;
- contas financeiras com saldo e transferências;
- categorias e **subcategorias** de receita/despesa;
- cartões com limite total, limite disponível, fatura do mês, valor pago e restante;
- compra parcelada vinculada diretamente ao cartão;
- registro de pagamento da fatura, opcionalmente debitado de uma conta;
- histórico de faturas;
- dívidas e empréstimos;
- orçamentos mensais por categoria;
- metas financeiras;
- relatórios de seis meses e estimativa de patrimônio.

## Organização geral

- agenda integrada com aulas, treinos planejados, provas, lembretes e vencimentos;
- busca local global;
- lembretes locais com notificação no Android;
- tela para revisar conflitos encontrados na sincronização;
- PIN opcional local.

## Privacidade, backup e sincronização

- SQLite local e separado em cada aparelho;
- exportação/importação `.mra`;
- imagens incluídas no backup;
- backup de segurança antes de importação/sincronização;
- sincronização bidirecional PC ↔ celular pela mesma rede Wi‑Fi;
- mesclagem por UUID, revisão e horário de atualização;
- conflitos preservados em vez de descartados silenciosamente;
- banco, backups e chave de assinatura bloqueados pelo `.gitignore`.

## Atualização Android sem perder dados

A versão 3 inclui suporte a **assinatura Android fixa**. Execute `09_GERAR_ASSINATURA_ANDROID.bat` uma única vez e cadastre os quatro valores gerados como Secrets do GitHub. Leia `docs/ASSINATURA_ANDROID.md` antes da primeira migração para a assinatura fixa.

> Se o APK que já está instalado tiver sido assinado por outra chave, faça um backup `.mra` antes da migração. Depois que a assinatura fixa estiver configurada, mantenha a mesma chave para todas as versões futuras.

## Gerar pelo GitHub Actions

O fluxo recomendado continua simples:

1. aplique a atualização sobre a pasta atual;
2. execute `07_SUBIR_GITHUB.bat`;
3. aguarde o workflow **Validar e gerar aplicativos**;
4. em **Artifacts**, baixe `My-Routine-Active-Android` e `My-Routine-Active-Windows`.

O workflow executa `flutter analyze`, `flutter test`, gera o APK, o pacote Windows portátil e o instalador Windows.

## Ferramentas locais opcionais

Você só precisa instalar todo o ambiente de compilação se quiser gerar os executáveis no próprio PC. Para usar o GitHub Actions, basta enviar o projeto com Git. Os BATs locais continuam disponíveis:

| Objetivo | Arquivo |
|---|---|
| Preparar dependências | `01_PREPARAR_PROJETO.bat` |
| Executar Windows local | `02_EXECUTAR_WINDOWS.bat` |
| Executar Android por USB | `03_EXECUTAR_ANDROID_USB.bat` |
| Analisar e testar localmente | `04_VALIDAR_PROJETO.bat` |
| Gerar APK local | `05_GERAR_APK.bat` |
| Gerar Windows local | `06_GERAR_WINDOWS.bat` |
| Enviar ao GitHub | `07_SUBIR_GITHUB.bat` |
| Limpar builds | `08_LIMPAR_BUILD.bat` |
| Criar assinatura Android fixa | `09_GERAR_ASSINATURA_ANDROID.bat` |

## Estrutura principal

```text
lib/core/       banco, backup, sync, notificações e cálculos
lib/screens/    Home, Estudos, Treinos, Finanças e utilitários
lib/widgets/    componentes visuais responsivos
test/           testes de backup, finanças, estudos e treinos
android/        projeto Android
windows/        projeto Windows
installer/      instalador Inno Setup
docs/           documentação operacional
```

O repositório deve continuar sem arquivos `.db`, `.sqlite`, `.sqlite3`, `.mra`, `.jks` ou senhas.
