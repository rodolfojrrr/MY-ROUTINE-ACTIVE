# Sincronização Wi‑Fi local

## Antes de começar

Crie o **mesmo nome de usuário** no PC e no celular. Esse nome gera o mesmo proprietário dos dados. Senha, pergunta e código de recuperação continuam locais e podem ser diferentes.

## Fluxo

1. Conecte PC e celular ao mesmo roteador.
2. No PC, abra **Configurações → Sincronizar pela mesma rede Wi‑Fi**.
3. Inicie a sessão e escolha o IP do Wi‑Fi/Ethernet caso mais de um seja exibido.
4. No celular, leia o QR Code ou informe IP, porta `8765` e código de seis dígitos.
5. Os dois lados criam snapshots, mesclam os registros da conta aberta e terminam equivalentes.

Não existe servidor na internet. A sessão usa um `HttpServer` temporário no PC e fecha ao encerrar a tela/aplicativo.

## Escolha de IP

O aplicativo lista endereços privados e prioriza Wi‑Fi e Ethernet. VPN, WSL, Hyper‑V, Docker, VMware, VirtualBox, Tailscale e outros adaptadores virtuais recebem prioridade menor. Se a conexão falhar, escolha manualmente o IPv4 mostrado em `ipconfig` no adaptador físico.

Teste opcional no navegador do celular:

```text
http://IP_DO_PC:8765/health
```

A resposta esperada é `Smart Routine SI local`.

## Mesclagem e segurança

- UUID inexistente é inserido;
- vence a edição com horário mais recente;
- em empate, vence a maior revisão e depois o ID do aparelho;
- divergências são gravadas em `sync_conflicts`;
- exclusões usam tombstones e podem ser restauradas pela lixeira;
- registros de outra conta são ignorados;
- código de pareamento muda em cada sessão;
- limite do pacote: 250 MB;
- cabeçalhos desativam cache.

## Firewall e roteador

Autorize o Smart Routine SI somente em **Redes privadas** no Firewall do Windows. Evite Wi‑Fi de convidados e desative isolamento de clientes/AP Isolation. VPN nos aparelhos também pode impedir a rota local.

## Alternativa manual

Exporte `.mra` no celular e importe no PC dentro da conta de mesmo usuário. Arquivos enviados pelo WhatsApp podem aparecer como `.mra.gz`; esta versão reconhece os dois formatos sem renomear.
