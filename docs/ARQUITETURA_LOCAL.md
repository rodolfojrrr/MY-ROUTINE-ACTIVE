# Arquitetura local — Smart Routine SI 5.0.1

## Plataformas e privacidade

Uma base Flutter gera aplicativos nativos para Android e Windows. Não há WebView, backend, analytics ou autenticação externa. GitHub guarda somente o código e executa builds; dados acadêmicos e credenciais ficam nos aparelhos.

## Banco e migração

O SQLite usa duas áreas principais:

- `entities`: registros versionados com UUID, tipo, JSON, revisão, aparelho, atualização e tombstone;
- `local_accounts`: credenciais locais, perguntas e hashes de recuperação.

`settings` guarda preferências por usuário e por aparelho. `sync_conflicts` preserva divergências.

Na migração v1 → v2, somente `local_accounts` é criada. A tabela `entities` não é apagada. A primeira conta reivindica registros legados ainda sem `ownerId`, depois de um snapshot automático. Um PIN legado, quando configurado, é exigido antes dessa etapa.

## Isolamento de usuários

Cada registro novo recebe `ownerId`. Consultas, edições, exclusões, backups e sincronização filtram a conta aberta. O identificador da conta deriva do nome de usuário normalizado, permitindo criar a mesma identidade de dados em dois aparelhos sem transferir credenciais.

Senhas, respostas e códigos de recuperação recebem salt aleatório e derivação SHA-256 iterativa. Eles não são exportados nem sincronizados.

## Modelo acadêmico

A hierarquia é `período → matéria → conteúdo`. Um período pode representar semestre, curso ou trilha. Resumos, avaliações, questões, flashcards, metas, cartões Kanban e projetos podem apontar para matéria/conteúdo sem obrigar o usuário a preencher relações quando a atividade for geral.

Tipos legados continuam reconhecidos internamente para que atualizações antigas não descartem registros, embora módulos fora de estudos não apareçam na navegação.

## Proteção contra perda

- snapshot `.mra` antes de migração, importação e sincronização;
- rascunho separado do resumo durante a edição;
- timer persistido periodicamente e pausado no ciclo de vida;
- tombstones para exclusões e lixeira para restauração;
- conflitos Wi-Fi preservados antes de escolher a versão vencedora;
- original preservado no conversor de PDF.

## Backup e sincronização

O `.mra` é JSON compactado em GZip com manifesto e SHA-256. A versão também aceita uma segunda camada GZip (`.mra.gz`). Imagens e arquivos de código acompanham as entidades. A sincronização usa HTTP temporário apenas na LAN e mescla UUID, horário, revisão e aparelho.

## IDE e PDF

Projetos da IDE são entidades sincronizáveis. No Windows, arquivos são materializados numa área local temporária para usar compiladores instalados; no Android, edição e sincronização continuam disponíveis sem embutir compiladores.

PDFs são criados no aparelho. Imagens e formatos textuais são convertidos diretamente. No Windows, formatos Office usam LibreOffice/Microsoft Office quando disponíveis; o fallback extrai conteúdo para um PDF de leitura.
