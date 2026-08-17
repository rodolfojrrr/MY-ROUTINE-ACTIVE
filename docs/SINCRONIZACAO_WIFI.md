# Sincronização Wi‑Fi local

## Princípio

Não existe servidor na internet. O aplicativo Windows abre temporariamente um `HttpServer` na porta `8765`, acessível apenas pela rede local. Um código aleatório de seis dígitos autoriza a sessão.

## Fluxo

1. PC e Android criam seus registros com UUID, revisão, horário de edição e ID do aparelho.
2. Antes da transferência, cada lado cria um snapshot `.mra` automático.
3. O Android envia seu pacote compactado ao PC.
4. O PC mescla os registros e responde com o conjunto resultante.
5. O Android mescla a resposta; os dois lados terminam equivalentes.

## Regra de mesclagem

- registro que existe somente de um lado é inserido;
- para o mesmo UUID, ganha a versão com `updatedAtMs` mais recente;
- em empate, ganha a maior revisão;
- persistindo o empate, o ID do aparelho serve como critério determinístico;
- quando conteúdos diferentes vieram de aparelhos diferentes, as duas versões são registradas em `sync_conflicts` antes de aplicar a vencedora;
- exclusões são tombstones sincronizáveis, não desaparecimentos sem histórico.

## Imagens

Anexos de anotações são serializados em Base64 dentro do registro. Assim, banco e imagens viajam juntos no mesmo `.mra`.

## Firewall do Windows

Na primeira sessão, o Windows pode pedir autorização. Marque apenas **Redes privadas**. Se o aviso não aparecer e a conexão falhar, permita `My Routine Active` no Firewall do Windows para redes privadas.

## Segurança

- código novo a cada abertura de sessão;
- servidor desligável manualmente e encerrado ao sair do aplicativo;
- limite de 50 MB por pacote;
- cabeçalhos sem cache;
- nenhum endpoint externo no código.

