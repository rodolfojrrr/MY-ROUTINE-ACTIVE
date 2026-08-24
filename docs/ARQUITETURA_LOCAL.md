# Arquitetura local — Smart Routine SI 4.1.0

## Plataformas

Uma única base Flutter gera aplicativos nativos para Android e Windows. A interface é renderizada pelo Flutter; não há WebView, PWA ou site incorporado.

## Modelo acadêmico

A organização principal segue `semestre → matéria → conteúdo`. Resumos, flashcards e questões registram o identificador da matéria e do conteúdo. Horários e avaliações registram a matéria e podem apontar para um conteúdo específico.

O painel inicial é de leitura. As operações de cadastro, edição e exclusão ficam nas seções do menu lateral. Isso mantém a visão diária simples sem limitar a estrutura de dados.

## Persistência

A tabela `entities` guarda registros genéricos e versionados com UUID, tipo, JSON, revisão, dispositivo de origem, instante de atualização e tombstone de exclusão. Os tipos acadêmicos principais incluem `semester` e `study_content`; projetos, arquivos e execuções da IDE usam `code_project`, `code_file` e `code_run`. Os tipos anteriores de matéria, aula, prova, resumo, flashcard, questão, simulado e sessão de estudo continuam compatíveis.

A tabela `settings` guarda preferências, ID do aparelho e configuração do PIN. `sync_conflicts` preserva divergências encontradas na mesclagem para que nenhuma edição desapareça silenciosamente.

Os tipos legados de versões anteriores continuam reconhecidos pelo banco e pela sincronização. Eles não aparecem na navegação acadêmica, mas essa compatibilidade evita perda de dados durante a atualização.

## Resumos e PDF

As imagens são armazenadas em Base64 junto ao resumo. Um resumo novo aceita uma lista ordenada de imagens; o leitor também converte em memória o formato antigo de imagem única. O PDF é montado localmente com título, semestre, matéria, conteúdo, texto e anexos e só é gravado no local escolhido pelo usuário.

## Backup `.mra`

O `.mra` é um envelope JSON compactado com GZip. O manifesto contém versão, dispositivo, quantidade de entidades e hash SHA-256. Como as imagens ficam nos registros, elas acompanham o backup e a sincronização.

## Sincronização Wi‑Fi

PC e celular se comunicam diretamente na rede local. A mesclagem considera UUID, revisão e horário de atualização. Exclusões usam tombstones. Antes de importar ou mesclar dados, o aplicativo cria uma cópia de segurança automática.

## IDE acadêmica

O editor é um componente Flutter nativo e não usa WebView. Projetos e arquivos ficam nas entidades sincronizáveis e podem ser vinculados a semestre, matéria e conteúdo. Ao executar um projeto no Windows, o aplicativo materializa temporariamente os arquivos em `MyRoutineActive/code_workspace/<id-do-projeto>` dentro da pasta de suporte da aplicação e chama somente os ambientes já instalados na máquina.

O Android oferece a mesma edição e organização, mas não inclui compiladores. Essa separação mantém o APK enxuto, offline e previsível: o celular edita e sincroniza; o Windows compila e executa. O aplicativo não usa serviços de compilação remota e não instala ferramentas sem autorização.

## Ausência de nuvem

Não há backend remoto, analytics ou autenticação externa. GitHub é usado somente para armazenar o código e executar as compilações do aplicativo. Banco, imagens, backups, projetos pessoais e chave de assinatura são ignorados pelo Git.
