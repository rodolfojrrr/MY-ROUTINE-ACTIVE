# My Routine Active

Aplicativo pessoal completo para **Estudos, Treinos e Finanças**, com a mesma experiência no Android e no Windows. O projeto é Flutter nativo: **não é site, não abre em navegador, não usa WebView e não salva nada em nuvem**.

## O que já está implementado

### Estudos

- grade semanal com os períodos noturnos `18:30–20:10` e `20:30–22:00`;
- cadastro, edição e exclusão de matérias, professores e salas;
- calendário de provas e trabalhos por matéria;
- anotações por matéria com imagem anexada;
- flashcards de pergunta e resposta.

### Treinos

- fichas e exercícios totalmente editáveis;
- cada série possui tipo, repetições e carga próprios;
- tipos de série: aquecimento, normal, falha e drop-set;
- cronômetro separado para cada exercício;
- descanso automático após concluir uma série;
- total diário = tempo de exercícios + todos os descansos;
- histórico de sessões concluídas.

### Finanças

- salário recorrente por **dia fixo do mês** — por exemplo, todo dia 5, sem vincular a um mês específico;
- rendas e despesas avulsas ou recorrentes;
- cartões com banco, bandeira, limite, fechamento e vencimento;
- dívidas/compras parceladas vinculadas ou não a cartão;
- cálculo automático da parcela atual, parcelas restantes e mês final;
- empréstimos com credor, prazo, parcela e vencimento;
- visão geral e calendário mensal de compromissos.

### Privacidade, backup e sincronização

- banco SQLite separado e local em cada aparelho;
- PIN opcional, armazenado localmente com salt e hash SHA-256;
- exportação/importação do pacote `.mra`;
- imagens incluídas no mesmo backup;
- backup automático antes de importação ou sincronização;
- sincronização bidirecional PC ↔ celular pela mesma rede Wi‑Fi;
- mesclagem por UUID, data de atualização e revisão;
- conflitos preservados no banco para evitar perda silenciosa;
- zero APIs de nuvem, zero telemetria e zero login externo.

## Requisitos de desenvolvimento

Instale:

1. [Flutter 3.47 ou superior](https://docs.flutter.dev/get-started/install/windows);
2. Android Studio com Android SDK, para compilar o APK;
3. Visual Studio 2022 Community com a carga **Desenvolvimento para desktop com C++**, para compilar Windows;
4. Git para Windows, para usar o BAT de envio.

No Windows, ative também **Configurações → Sistema → Para desenvolvedores → Modo de Desenvolvedor**; isso permite que o Flutter prepare os plugins do aplicativo.

Depois, execute `01_PREPARAR_PROJETO.bat`.

## Executar e compilar

| Objetivo | Arquivo |
|---|---|
| Preparar dependências | `01_PREPARAR_PROJETO.bat` |
| Abrir no Windows em modo de desenvolvimento | `02_EXECUTAR_WINDOWS.bat` |
| Abrir no Android conectado por USB | `03_EXECUTAR_ANDROID_USB.bat` |
| Rodar análise e testes | `04_VALIDAR_PROJETO.bat` |
| Gerar APK instalável | `05_GERAR_APK.bat` |
| Gerar pacote Windows | `06_GERAR_WINDOWS.bat` |
| Commit e push para o GitHub | `07_SUBIR_GITHUB.bat` |
| Limpar somente arquivos de compilação | `08_LIMPAR_BUILD.bat` |

Os pacotes locais aparecem na pasta `ENTREGAS`.
Se o Inno Setup 6 estiver instalado, o BAT do Windows também cria
`My-Routine-Active-Setup.exe`; o GitHub Actions sempre tenta gerar esse instalador.

## Baixar APK e Windows pelo GitHub

O workflow `.github/workflows/validar-e-gerar.yml` faz análise, testes e builds reais.

1. Execute `07_SUBIR_GITHUB.bat`.
2. Abra o repositório `rodolfojrrr/MY-ROUTINE-ACTIVE`.
3. Entre em **Actions** e abra a execução verde mais recente.
4. Na seção **Artifacts**, baixe:
   - `My-Routine-Active-Android`;
   - `My-Routine-Active-Windows`.

O artefato Windows contém o ZIP portátil e o instalador `Setup.exe`.

O APK é um aplicativo Android nativo renderizado pelo Flutter; ele não abre o site nem depende de internet.

## Sincronizar PC e celular pelo Wi‑Fi

1. Conecte os dois aparelhos ao mesmo roteador.
2. No PC, abra **Configurações → Sincronização Wi‑Fi → Abrir sessão no PC**.
3. Permita acesso em **redes privadas** se o Firewall do Windows perguntar.
4. No celular, informe o IP, a porta `8765` e o código de seis dígitos mostrados no PC.
5. Toque em **Sincronizar agora**.

O celular envia sua versão, o PC mescla os registros e devolve o conjunto final. Portanto, alterações feitas em qualquer lado são preservadas. O servidor local só fica aberto durante a sessão.

Mais detalhes: [docs/SINCRONIZACAO_WIFI.md](docs/SINCRONIZACAO_WIFI.md).

## Banco zerado

O repositório não contém nenhum `.db`, `.sqlite`, `.sqlite3` ou `.mra`. O banco é criado na primeira abertura. A `.gitignore` bloqueia a inclusão acidental desses arquivos.

## Estrutura

```text
lib/
  core/       SQLite, backup, mesclagem, Wi‑Fi e cálculos
  screens/    Estudos, Treinos, Finanças, PIN e Configurações
  widgets/    identidade visual responsiva
android/      projeto Android nativo
windows/      projeto Windows nativo
test/         testes do backup e das parcelas
```

Versão: **2.0.1 local final**.
