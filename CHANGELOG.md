# Changelog

## 5.5.0 PRO — revisão do workflow Windows

- Corrigida a etapa `Configurar Flutter` que podia encerrar com o código 35 no executor Windows do GitHub.
- O SDK do Windows agora é obtido diretamente do arquivo oficial do Flutter, com cinco tentativas automáticas.
- O pacote baixado é validado pelo SHA-256 oficial antes da compilação.
- Um cache próprio evita baixar novamente o SDK nas próximas execuções.
- A versão do aplicativo e o formato do banco permanecem inalterados.

## 5.5.0 PRO

- Editor avançado de temas com seleção visual e HEX para cor principal, secundária, fundo, cartões, campos, bordas e menu lateral.
- Perfis completos azul, roxo, cinza, verde, amarelo e colorido agora alteram toda a identidade, não apenas os botões.
- Semestres, matérias, conteúdos, cursos e resumos recebem cor, símbolo e imagem de fundo próprios, sem alterar registros antigos.
- Biblioteca de resumos redesenhada como grade de pastas e personalização incluída no rascunho automático, backup e sincronização.
- Pastas internas de cada conteúdo ganharam artes acadêmicas próprias para Resumos, Códigos, Imagens, Anexos, Simulados, Flashcards e Provas.
- Cor de cada pasta interna pode ser editada livremente; a arte correspondente permanece consistente para facilitar o reconhecimento.
- Nova Lixeira no menu lateral, com restauração individual/total, exclusão definitiva, esvaziamento e confirmações de segurança.
- Exclusão definitiva remove texto, imagens e anexos, preservando apenas o tombstone mínimo que impede ressurreição na sincronização.
- Horário de aulas movido para imediatamente depois da saudação e redesenhado com a cor e a borda de cada matéria.
- Indicadores soltos de matérias, resumos, avaliações e questões foram removidos da página inicial.
- `Tab` e `Shift+Tab` no editor de resumos agora aplicam e removem recuo, como em uma IDE.
- Pareamento Wi‑Fi documentado para celular, notebook e PC, e mensagens UTF-8 corrigidas.
- Três novos testes cobrem o tema completo, o tombstone seguro e os atalhos de recuo.
- Versão elevada para `5.5.0+55`.

## 5.3.0

- Editor de resumos redesenhado como folha A4 escura, centralizada e responsiva.
- Margens passaram para dentro da área rolável, impedindo que fontes grandes encostem ou sejam cortadas pela borda.
- Organização e Materiais ficaram mais estreitos, recolhíveis separadamente e ocultáveis no modo foco.
- Barra profissional ampliada com desfazer/refazer, alinhamento, entrelinhas, marca-texto, checklist, citação, recuos, linha divisória e seleção total.
- Código em linha e bloco de código agora são recursos distintos, com visual monoespaçado, fundo próprio e atalho `Ctrl+Shift+K`.
- Novas formatações são preservadas em rascunhos, banco, backup, sincronização, leitura e PDF.
- Formato rico elevado para a versão 2, mantendo leitura integral dos resumos criados nas versões anteriores.
- Contadores de palavras, caracteres e tempo estimado de leitura adicionados ao rodapé.
- Testes cobrem texto longo em fonte máxima, margens A4, painéis recolhíveis e serialização das novas formatações.
- Versão elevada para `5.3.0+54`.

## 5.2.0

- Área Faculdade reconstruída como navegação por pastas, sem a antiga tela de administração em abas.
- Faculdade posicionada imediatamente abaixo do Menu principal na barra lateral.
- Semestre atual destacado e ordenação do mais recente para o mais antigo.
- Telas independentes para semestres, matérias, conteúdos e ambiente de cada conteúdo.
- Botões de cadastro contextuais e atualização imediata após salvar, sem recarregar a tela.
- Matérias personalizáveis com oito cores, doze símbolos acadêmicos e imagem de fundo local.
- Cada conteúdo passa a reunir Resumos, Códigos, Imagens, Anexos, Simulados, Flashcards e Provas/Notas.
- Galeria de imagens e gerenciador de anexos próprios por conteúdo, incluídos no backup e na sincronização Wi-Fi.
- IDE filtrada por conteúdo, criando novos projetos já vinculados à pasta aberta.
- Horário de aulas preservado em tela própria e registros antigos sem semestre mantidos numa pasta de revisão.
- Indicadores compactados para aproveitar melhor o espaço no desktop.
- Testes responsivos cobrem a navegação completa e a atualização em tempo real.
- Versão elevada para `5.2.0+53`.

## 5.1.0

- Editor de resumos reconstruído em tela cheia, responsivo e integrado às cores do aplicativo.
- Formatação por trecho com títulos, subtítulos, tamanho da fonte, negrito, itálico, sublinhado, tachado, cor de destaque, código e listas.
- Rascunho automático agora preserva também o texto rico, imagens e anexos.
- Anexos de diversos formatos adicionados a cada resumo e incluídos no backup/sincronização.
- Leitura dos resumos redesenhada para impedir textos gigantes ou estilos herdados incorretamente.
- PDF individual passa a respeitar a formatação, listar anexos e sempre oferecer navegação de volta.
- Faculdade reorganizada em semestre → cadeira → conteúdo → resumo, com semestres atuais primeiro.
- Cada cadeira reúne Conteúdos, Flashcards, Provas/Notas e Simulados em abas próprias.
- Nova área Cursos, totalmente separada da graduação, com progresso, carga horária e imagens de certificados.
- Painel inicial compactado e reordenado: informações gerais, horário, metas/atividades e graduação.
- Cards e áreas acadêmicas receberam bordas, limites de largura e melhor encaixe no celular e no PC.
- Compatibilidade mantida com todos os resumos, imagens, períodos e cursos das versões anteriores.
- Versão elevada para `5.1.0+52`.

## 5.0.1

- Menu lateral do Windows agora pode ser recolhido para uma barra compacta de ícones.
- Botões dedicados para recolher e expandir, com tooltips de todas as seções.
- O conteúdo central passa a usar automaticamente o espaço liberado.
- A preferência aberta/recolhida é salva separadamente para cada usuário local.
- Comportamento validado no desktop, inclusive restauração após reabrir a conta.
- Versão elevada para `5.0.1+51`.

## 5.0.0

- Contas locais para múltiplos usuários, com isolamento por proprietário.
- Login por usuário/e-mail e senha, pergunta de segurança e código de recuperação.
- Migração segura do banco v1 para v2: primeira conta assume os dados antigos após snapshot automático e validação do PIN legado, quando existir.
- Metas diárias livres ou ligadas a matéria/conteúdo e cronograma semanal opcional.
- Cronômetro global persistente, sem reiniciar ao navegar e restaurado pausado após fechar ou ocultar o app.
- Rascunho automático dos resumos e correção da estabilidade dos campos de digitação.
- Novo Kanban com Pendentes, Fazendo e Concluídas, drag-and-drop, movimentação manual, prazos, ordenação e retenção configurável.
- Conversor local de arquivos para PDF e geração de PDF individual dos resumos preservada.
- Paletas azul, roxa, cinza, verde, amarela e colorida, aplicadas sem reiniciar.
- Períodos ampliados para semestre, curso ou trilha, mantendo a hierarquia matéria → conteúdo.
- Importação de `.mra.gz` recebido pelo WhatsApp, além do `.mra` normal.
- Sincronização Wi-Fi aprimorada com lista de IPs e prioridade para adaptadores físicos.
- Lixeira local para restaurar registros excluídos.
- Layout das ferramentas novas validado em 360 × 760 e navegação responsiva testada em celular e desktop.
- Versão elevada para `5.0.0+50`.

## 4.1.0

- Identidade visual redesenhada em azul, com novo ícone no Android e no Windows.
- Nova IDE acadêmica nativa, integrada ao menu principal e responsiva para celular e PC.
- Projetos de código vinculados a semestre, matéria e conteúdo.
- Editor com vários arquivos, numeração de linhas, realce de sintaxe, busca, desfazer/refazer, quebra de linha e salvamento automático.
- Modelos para Dart, Python, Java, JavaScript, TypeScript, C, C++, C#, Kotlin, PHP, SQL, HTML/CSS e JSON.
- Terminal integrado e execução local no Windows com os ambientes instalados pelo usuário.
- Verificador de runtimes para identificar JDK, Python, Node.js, TypeScript, GCC/G++, .NET, Kotlin, PHP, SQLite e Dart.
- Importação, exportação, renomeação e definição do arquivo principal de cada projeto.
- Projetos, arquivos e histórico de execução incluídos no banco local, backup `.mra` e sincronização Wi‑Fi.
- Nenhum WebView, nuvem, compilador remoto ou download automático de ferramentas.
- Versão elevada para `4.1.0+41`.

## 4.0.0

- Aplicativo convertido para uma edição totalmente focada em Sistemas de Informação.
- Novo painel acadêmico responsivo e somente para consulta.
- Menu lateral no celular e navegação permanente no desktop.
- Hierarquia semestre → matéria → conteúdo aplicada a resumos, flashcards e questões.
- Grade semanal de segunda a domingo, com blocos noturnos sugeridos.
- Biblioteca de resumos com várias imagens, busca, filtros e PDF individual.
- Banco de questões e simulados com filtros, cronômetro, correção e histórico.
- Agenda de provas, trabalhos, projetos, atividades e apresentações.
- Organização completa de semestres, matérias, conteúdos e horários.
- Novo nome, tema roxo acadêmico e ícones para Android e Windows.
- Compatibilidade preservada com banco, `.mra`, sincronização Wi‑Fi, assinatura Android e instalação anterior.
- Versão elevada para `4.0.0+40`.

## 3.0.0

- Home transformada em dashboard integrado.
- Agenda geral, busca global, lembretes e revisão de conflitos.
- Estudos: painel Hoje, repetição espaçada, revisão de flashcards, questões, simulados, foco e metas.
- Treinos: biblioteca, grupos musculares, snapshots, volume, PRs, comparação, meta semanal, corpo, fotos, água e cardio.
- Finanças: contas, transferências, categorias/subcategorias, orçamentos, metas, faturas, pagamentos, histórico e relatórios.
- Notificações locais Android.
- Suporte a assinatura Android fixa via GitHub Secrets.
- Novos testes para estudo, treino e análise financeira.
- Versão elevada para `3.0.0+30`.
