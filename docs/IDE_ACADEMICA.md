# IDE acadêmica local

A IDE do Studium SI foi criada para exercícios, trabalhos e pequenos projetos da graduação. O mesmo editor funciona no Android e no Windows. Todos os projetos ficam no banco local, acompanham o backup `.mra` e podem ser sincronizados diretamente pela rede Wi‑Fi.

## Recursos do editor

- projetos vinculados a semestre, matéria e conteúdo;
- vários arquivos por projeto e definição do arquivo principal;
- realce de sintaxe, numeração de linhas, busca, quebra de linha, desfazer e refazer;
- salvamento automático e indicação de alterações pendentes;
- importação e exportação de arquivos com limite de 1 MB por arquivo;
- terminal de saída e tempo de execução;
- verificador dos ambientes instalados no Windows.

## Linguagens e ambientes no Windows

| Linguagem | Ambiente local usado |
|---|---|
| Dart | Dart SDK (`dart`) |
| Python | Python 3 (`python` ou `py`) |
| Java | JDK (`javac` e `java`) |
| JavaScript | Node.js (`node`) |
| TypeScript | Node.js e TypeScript (`node` e `tsc`) |
| C | GCC (`gcc`) |
| C++ | G++ (`g++`) |
| C# | .NET SDK (`dotnet`) |
| Kotlin | Kotlin Compiler e JDK (`kotlinc` e `java`) |
| PHP | PHP (`php`) |
| SQL | SQLite CLI (`sqlite3`) em um banco temporário na memória |
| HTML/CSS | Navegador padrão local |
| JSON | Edição e organização, sem comando de execução |

Abra **IDE de código → Verificar ambientes** para saber o que já está disponível na máquina. O aplicativo não baixa nem atualiza compiladores automaticamente.

## Fluxo entre celular e PC

1. Crie ou edite o projeto em qualquer aparelho.
2. Salve ou aguarde o salvamento automático.
3. Use a sincronização Wi‑Fi com os dois aparelhos na mesma rede.
4. Abra o projeto no Windows e toque em **Executar**.

No Android, o botão de execução explica que o projeto deve ser aberto no Windows. O código continua completamente editável no celular.

## Privacidade e limites

Nenhum arquivo é enviado para nuvem ou serviço de compilação. A execução local tem limite de 30 segundos e a saída é limitada para proteger o aplicativo contra processos travados ou textos excessivos. Programas interativos que aguardam entrada pelo terminal ainda não são suportados.

O código executado possui as mesmas permissões do seu usuário do Windows. Execute somente projetos e arquivos em que você confia.
