<div align="center">
  <h1>
    <img src="https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="GNU Bash" />
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git" />
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
    <br>
    Dotfiles & Linux Utilities 🇺🇸
  </h1>
  <p>Personal repository for Linux aliases, custom functions, and interactive automation tools</p>
</div>

## ⚡ Quick Installation

Clone the repository and install all aliases and utility functions:

```bash
git clone https://github.com/paulo-campos-57/dotfiles.git && cd dotfiles && bash scripts/install.sh
```

Reload your shell configuration with `source ~/.bashrc` after installation.

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/paulo-campos-57/dotfiles.git
   cd dotfiles
   ```
2. Make the installer executable:
   ```bash
   chmod +x scripts/install.sh
   ```
3. Run the setup script:
   ```bash
   ./scripts/install.sh
   ```
4. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```

## 📁 Repository Structure

```text
dotfiles/
├── scripts/
│   ├── aliases.sh          # Shell aliases and custom functions
│   ├── install.sh          # Interactive aliases/functions installer
│   └── commit-report.sh    # Git commit analytics and charts
├── LICENSE
└── README.md
```

The `scripts/` directory contains standalone Bash utilities. `install.sh` installs aliases and functions from `aliases.sh`; other scripts, such as `commit-report.sh`, are executed separately and are not automatically installed as aliases.

## 🔍 Interactive Collision Detection

The `scripts/install.sh` script automatically inspects your environment before making changes:

- **[COLLISION]:** Detects if an alias, function, or system command with the same name already exists and prompts you to overwrite it (`y/N`).
- **[SKIPPED]:** Preserves your existing command when you decline an overwrite prompt.

## 📄 Available Commands & Aliases

### 🧹 System Utilities & Navigation

| Command | Description |
| :--- | :--- |
| `cls` | Clears the terminal screen (`clear`). |
| `path` | Displays `$PATH` directories formatted line by line. |
| `ff <file>` | Searches for files by name in the current directory (`find . -type f -name`). |
| `mcd <dir>` | Creates a directory and immediately navigates into it. |
| `gohome` | Navigates to `~` and displays the current path. |
| `..` | Moves up 1 directory level. |
| `...` | Moves up 2 directory levels. |
| `....` | Moves up 3 directory levels. |

### 🌐 Network & Operations

| Command | Description |
| :--- | :--- |
| `myip` | Fetches the public IP address via `ifconfig.me`. |
| `ports` | Lists listening network sockets and ports via `netstat`. |
| `diskh` | Displays disk space usage in human-readable format (`df -h`). |
| `fmem` | Displays system memory usage in human-readable format (`free -m -h`). |
| `extract <file>` | Automatically extracts archives (`.tar.gz`, `.zip`, `.rar`, `.7z`, etc.). |
| `bak <file>` | Creates a duplicate backup file with a `.bak` extension. |
| `psg <process>` | Searches active processes by name, ignoring `grep` itself. |

### 🐙 Git Shortcuts

| Command | Description |
| :--- | :--- |
| `gsts` | Shortcut for `git status`. |
| `gbranch` | Displays the currently active Git branch. |
| `gph` | Pushes local changes to `origin HEAD`. |
| `glog` | Shows commit count per author (`git shortlog -s -n --all`). |
| `glogg` | Shows a formatted visual commit graph. |
| `gprune` | Fetches remote updates and prunes deleted references. |
| `gfo` | Fetches updates from `origin` without merging. |
| `gnb <branch>` | Creates and switches to a new Git branch (`git switch -c`). |
| `gco <branch>` | Switches to an existing local branch (`git switch`). |
| `grs <file>` | Restores a modified file to its HEAD state (`git restore`). |
| `gdb <branch>` | Prompts for confirmation before deleting a local branch. |
| `ghelp` | Displays a summary menu of available Git commands. |

### 🐳 Docker Shortcuts

| Command | Description |
| :--- | :--- |
| `dps` | Displays running containers in a formatted table. |
| `dstopall` | Stops all running Docker containers. |
| `dexec <container> [shell]` | Opens an interactive session inside a container (defaults to `bash`). |
| `dclean` | Prunes unused containers, networks, images, and volumes. |

## 📊 Git Commit Report

The standalone [`scripts/commit-report.sh`](scripts/commit-report.sh) utility analyzes Git commit messages and generates visual reports showing how development activity is distributed across categories.

**Requirements:** Linux, Bash, Git, AWK, GNU `date`, and Gnuplot. Install Gnuplot on Ubuntu with:

```bash
sudo apt update && sudo apt install gnuplot
```

**Usage:** From the repository root, run:

```bash
chmod +x scripts/commit-report.sh
./scripts/commit-report.sh /path/to/git/repository
```

You can optionally specify an output directory as the second argument:

```bash
./scripts/commit-report.sh /path/to/git/repository ./git-report
```

The script prompts you to select an analysis period:

| Option | Period | Evolution chart granularity |
| :--- | :--- | :--- |
| `1` | Specific day (`YYYY-MM-DD`) | Hourly |
| `2` | Specific month (`YYYY-MM`) | Daily |
| `3` | Specific year (`YYYY`) | Monthly |
| `4` | Entire repository history | Monthly |

**Commit categories:** Tags are matched case-insensitively (`[FIX]`, `[fix]`, and `[Fix]` are equivalent).

| Category | Recognized tags |
| :--- | :--- |
| `FEAT/ADD` | `[FEAT]`, `[ADD]` |
| `FIX` | `[FIX]` |
| `TEST` | `[TEST]` |
| `REFACTOR` | `[REFACTOR]` |
| `DOCS` | `[DOCS]` |
| `CHORE` | `[CHORE]` |
| `STYLE` | `[STYLE]` |
| `OTHER` | Messages without a recognized tag |

**Generated files:** Reports are stored in a period-specific folder under the output directory.

| File | Description |
| :--- | :--- |
| `distribution.png` | Percentage of commits in each category. |
| `evolution.png` | Commit activity over time by category. |
| `resume.dat` | Commit counts and percentages per category. |
| `evolution.dat` | Time-series counts for the evolution chart. |
| `commits_raw.tsv` | Raw commit dates and subjects used for the analysis. |

The report uses locally available Git references (`git log --all`), excludes merge commits, and counts each commit once. Run `git fetch --all --prune` in the target repository first if you want to refresh remote-tracking references. Percentages include `OTHER` and sum to approximately 100% (subject to rounding). When multiple recognized tags occur in one message, the script applies its configured category priority.

---

<div align="center">
  <h1>
    <img src="https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="GNU Bash" />
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git" />
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
    <br>
    Dotfiles e Utilitários Linux 🇧🇷
  </h1>
  <p>Repositório pessoal para aliases do Linux, funções customizadas e ferramentas de automação interativa</p>
</div>

## ⚡ Instalação Rápida

Clone o repositório e instale todos os aliases e funções utilitárias:

```bash
git clone https://github.com/paulo-campos-57/dotfiles.git && cd dotfiles && bash scripts/install.sh
```

Após a instalação, execute `source ~/.bashrc` para recarregar as configurações do terminal.

### Instalação Manual

1. Clone o repositório:
   ```bash
   git clone https://github.com/paulo-campos-57/dotfiles.git
   cd dotfiles
   ```
2. Dê permissão de execução ao instalador:
   ```bash
   chmod +x scripts/install.sh
   ```
3. Execute o script de instalação:
   ```bash
   ./scripts/install.sh
   ```
4. Recarregue as configurações do terminal:
   ```bash
   source ~/.bashrc
   ```

## 📁 Estrutura do Repositório

```text
dotfiles/
├── scripts/
│   ├── aliases.sh          # Aliases e funções personalizadas
│   ├── install.sh          # Instalador interativo
│   └── commit-report.sh    # Relatórios e gráficos de commits Git
├── LICENSE
└── README.md
```

O diretório `scripts/` reúne utilitários Bash independentes. O `install.sh` instala os aliases e funções definidos em `aliases.sh`. Outros scripts, como o `commit-report.sh`, são executados separadamente e não são instalados automaticamente como aliases.

## 🔍 Detecção Interativa de Colisões

O script `scripts/install.sh` analisa o ambiente antes de aplicar alterações:

- **[COLLISION]:** Detecta se um alias, função ou comando do sistema com o mesmo nome já existe e pergunta se você deseja sobrescrevê-lo (`y/N`).
- **[SKIPPED]:** Preserva o comando existente caso você recuse a substituição.

## 📄 Comandos e Aliases Disponíveis

### 🧹 Utilitários do Sistema & Navegação

| Comando | Descrição |
| :--- | :--- |
| `cls` | Limpa a tela do terminal (`clear`). |
| `path` | Exibe os diretórios do `$PATH` formatados linha por linha. |
| `ff <arquivo>` | Busca arquivos pelo nome no diretório atual (`find . -type f -name`). |
| `mcd <diretório>` | Cria um diretório e entra nele imediatamente. |
| `gohome` | Navega para o diretório `~` e exibe o caminho atual. |
| `..` | Volta 1 nível de diretório. |
| `...` | Volta 2 níveis de diretório. |
| `....` | Volta 3 níveis de diretório. |

### 🌐 Rede & Operações

| Comando | Descrição |
| :--- | :--- |
| `myip` | Obtém o IP público via `ifconfig.me`. |
| `ports` | Lista conexões e portas de rede ativas usando `netstat`. |
| `diskh` | Exibe o uso de espaço em disco de forma legível (`df -h`). |
| `fmem` | Exibe o uso de memória do sistema de forma legível (`free -m -h`). |
| `extract <arquivo>` | Extrai automaticamente arquivos compactados (`.tar.gz`, `.zip`, `.rar`, `.7z`, etc.). |
| `bak <arquivo>` | Cria um arquivo de backup duplicado com a extensão `.bak`. |
| `psg <processo>` | Busca processos ativos pelo nome, ignorando o próprio `grep`. |

### 🐙 Atalhos do Git

| Comando | Descrição |
| :--- | :--- |
| `gsts` | Atalho para `git status`. |
| `gbranch` | Exibe a branch Git ativa no momento. |
| `gph` | Envia as alterações locais para `origin HEAD`. |
| `glog` | Exibe a contagem de commits por autor (`git shortlog -s -n --all`). |
| `glogg` | Exibe a árvore visual de commits formatada. |
| `gprune` | Busca atualizações remotas e limpa referências excluídas. |
| `gfo` | Busca atualizações do `origin` sem aplicar merge. |
| `gnb <branch>` | Cria e alterna para uma nova branch (`git switch -c`). |
| `gco <branch>` | Alterna para uma branch existente (`git switch`). |
| `grs <arquivo>` | Restaura um arquivo modificado para o estado da HEAD (`git restore`). |
| `gdb <branch>` | Solicita confirmação antes de excluir uma branch local. |
| `ghelp` | Exibe um menu formatado com todos os comandos Git disponíveis. |

### 🐳 Atalhos do Docker

| Comando | Descrição |
| :--- | :--- |
| `dps` | Exibe os containers em execução em uma tabela formatada. |
| `dstopall` | Para todos os containers Docker em execução. |
| `dexec <container> [shell]` | Abre um terminal interativo dentro do container (padrão `bash`). |
| `dclean` | Remove containers, redes, imagens e volumes não utilizados. |

## 📊 Relatório de Commits Git

O utilitário independente [`scripts/commit-report.sh`](scripts/commit-report.sh) analisa mensagens de commits Git e gera relatórios visuais que mostram a distribuição das atividades de desenvolvimento por categoria.

**Dependências:** Linux, Bash, Git, AWK, GNU `date` e Gnuplot. Para instalar o Gnuplot no Ubuntu:

```bash
sudo apt update && sudo apt install gnuplot
```

**Execução:** Na raiz do repositório, execute:

```bash
chmod +x scripts/commit-report.sh
./scripts/commit-report.sh /caminho/do/repositorio/git
```

Opcionalmente, informe um diretório de saída como segundo argumento:

```bash
./scripts/commit-report.sh /caminho/do/repositorio/git ./git-report
```

O script apresenta um menu interativo para selecionar o período de análise:

| Opção | Período | Granularidade do gráfico de evolução |
| :--- | :--- | :--- |
| `1` | Dia específico (`YYYY-MM-DD`) | Por hora |
| `2` | Mês específico (`YYYY-MM`) | Por dia |
| `3` | Ano específico (`YYYY`) | Por mês |
| `4` | Todo o histórico do repositório | Por mês |

**Categorias de commits:** As tags são identificadas sem diferenciar maiúsculas de minúsculas (`[FIX]`, `[fix]` e `[Fix]` são equivalentes).

| Categoria | Tags reconhecidas |
| :--- | :--- |
| `FEAT/ADD` | `[FEAT]`, `[ADD]` |
| `FIX` | `[FIX]` |
| `TEST` | `[TEST]` |
| `REFACTOR` | `[REFACTOR]` |
| `DOCS` | `[DOCS]` |
| `CHORE` | `[CHORE]` |
| `STYLE` | `[STYLE]` |
| `OTHER` | Mensagens sem nenhuma tag reconhecida |

**Arquivos gerados:** Os relatórios são armazenados em uma pasta específica para o período selecionado, dentro do diretório de saída.

| Arquivo | Descrição |
| :--- | :--- |
| `distribution.png` | Percentual de commits por categoria. |
| `evolution.png` | Evolução dos commits por categoria ao longo do tempo. |
| `resume.dat` | Quantidades e percentuais por categoria. |
| `evolution.dat` | Dados temporais utilizados no gráfico de evolução. |
| `commits_raw.tsv` | Datas e títulos dos commits utilizados na análise. |

A análise utiliza as referências Git disponíveis localmente (`git log --all`), ignora commits de merge e conta cada commit uma única vez. Para atualizar as referências remotas antes da execução, utilize `git fetch --all --prune` no repositório analisado. Os percentuais incluem a categoria `OTHER` e totalizam aproximadamente 100% (considerando arredondamentos). Se uma mensagem contiver mais de uma tag reconhecida, será aplicada a prioridade de categorias definida no script.
