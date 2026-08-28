# Changelog

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
