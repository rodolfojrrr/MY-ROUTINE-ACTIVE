# Arquitetura local — v3.0.0

## Plataformas

Uma única base Flutter gera Android e Windows. A interface é renderizada pelo Flutter; não há WebView, PWA ou site incorporado.

## Persistência

A tabela `entities` guarda registros genéricos versionados com UUID, tipo, JSON, revisão, dispositivo de origem, atualização e tombstone de exclusão. Isso permite adicionar recursos sem criar uma tabela nova para cada tela.

Tipos usados na v3 incluem matérias, aulas, provas, notas, flashcards, questões, simulados, sessões/metas de estudo, fichas, exercícios, séries, sessões de treino, medidas corporais, cardio, água, metas de treino, rendas, despesas, cartões, dívidas, empréstimos, contas, transferências, categorias, orçamentos, metas financeiras, pagamentos de fatura e lembretes.

A tabela `settings` guarda preferências locais, ID do dispositivo e dados do PIN. `sync_conflicts` preserva divergências detectadas durante a mesclagem e agora pode ser revisada pela interface.

## Backup `.mra`

O `.mra` é um envelope JSON compactado com GZip. O manifesto contém versão, dispositivo, quantidade de entidades e hash SHA-256. Como imagens são armazenadas em base64 nos registros, elas acompanham o backup.

## Sincronização Wi‑Fi

PC e celular se comunicam diretamente na rede local. A mesclagem considera UUID, revisão e horário de atualização. Exclusões usam tombstones. Antes de operações destrutivas, o aplicativo cria cópia de segurança.

## Notificações

Lembretes permanecem como entidades locais/sincronizáveis. No Android, o aplicativo agenda a notificação no sistema operacional; a agenda e a lista de lembretes continuam acessíveis no Windows.

## Ausência de nuvem

Não há backend remoto, analytics ou autenticação externa. GitHub é usado apenas para armazenar o código e executar as builds. Os dados pessoais não fazem parte do repositório.
