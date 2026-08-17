# Arquitetura local

## Plataformas

Uma única base Flutter gera dois executáveis nativos:

- Android: APK com renderização Flutter e banco SQLite do aparelho;
- Windows: `.exe` com renderização Flutter e banco SQLite via FFI.

Não há WebView, PWA, site incorporado ou login do ChatGPT.

## Persistência

A tabela `entities` guarda registros genéricos versionados:

- `id`: UUID estável;
- `entity_type`: tipo funcional;
- `payload`: JSON editável;
- `updated_at`: relógio de mesclagem;
- `deleted_at`: tombstone de exclusão;
- `device_id`: origem da versão;
- `revision`: contador local.

A tabela `settings` guarda ID do dispositivo e PIN local. A tabela `sync_conflicts` preserva divergências observadas durante a mesclagem.

## Formato `.mra`

É um envelope JSON compactado com GZip. O manifesto inclui versão, dispositivo, quantidade de entidades e SHA-256 do conteúdo. O importador rejeita pacote corrompido ou incompatível.

## Ausência de nuvem

O projeto não possui Firebase, Supabase, API REST remota, analytics ou credenciais. O único tráfego implementado é HTTP direto para um IP privado informado pelo usuário durante a sincronização local.

