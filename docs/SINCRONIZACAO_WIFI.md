# Sincronização Wi‑Fi local

## Princípio

Não existe servidor na internet. O Smart Routine SI para Windows abre temporariamente um `HttpServer` na porta `8765`, acessível pela rede local. Um código aleatório de seis dígitos autoriza cada sessão.

## Fluxo

1. Conecte PC e celular à mesma rede Wi‑Fi.
2. No PC, abra **Sincronização Wi‑Fi** e inicie a sessão.
3. No celular, abra a mesma tela, leia o QR Code ou informe IP, porta e código.
4. O Android envia seu pacote compactado ao PC.
5. O PC mescla os registros e devolve o conjunto resultante.
6. O Android mescla a resposta; os dois aparelhos terminam equivalentes.

Antes da transferência, cada lado gera um snapshot `.mra` automático.

## Regra de mesclagem

- registro existente em apenas um aparelho é inserido no outro;
- para o mesmo UUID, vence a versão com `updatedAtMs` mais recente;
- em empate, vence a maior revisão;
- persistindo o empate, o ID do aparelho aplica um critério determinístico;
- versões divergentes são guardadas em `sync_conflicts` antes da escolha;
- exclusões viajam como tombstones sincronizáveis.

## Imagens e tamanho

As imagens de resumos são serializadas em Base64 e viajam dentro do mesmo pacote. O limite de recebimento é de **250 MB**, adequado a resumos com vários anexos. Prefira imagens legíveis e compactas para que a sincronização termine mais rápido.

## Firewall do Windows

Na primeira sessão, o Windows pode pedir autorização. Marque somente **Redes privadas**. Se o aviso não aparecer e a conexão falhar, permita `Smart Routine SI` no Firewall do Windows para redes privadas e confirme que os dois aparelhos estão na mesma rede sem isolamento de clientes.

## Segurança

- código novo a cada abertura de sessão;
- servidor encerrado manualmente ou ao fechar o aplicativo;
- cabeçalhos sem cache;
- nenhum endpoint externo;
- transferência limitada à rede local e protegida pelo código temporário;
- PIN local opcional para abrir o aplicativo.
