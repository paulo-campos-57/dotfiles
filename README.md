# 🐧 Dotfiles & Linux Utilities

<div align="center">

<img src="https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="GNU Bash" />
<img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
<img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git" />
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />

**Personal repository for Linux aliases, custom Bash functions, Git analytics, and interactive automation tools.**

</div>

---

## 🇺🇸 English Documentation

## ⚡ Quick Installation

Clone the repository and run the interactive installer:

```bash
git clone https://github.com/paulo-campos-57/dotfiles.git
cd dotfiles
bash scripts/install.sh
```

After installation, reload your shell configuration:

```bash
source ~/.bashrc
```

The installer automatically detects aliases, functions, and utility scripts. It also asks for permission before changing script execution permissions.

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

3. Run the installer:

   ```bash
   ./scripts/install.sh
   ```

4. Reload Bash:

   ```bash
   source ~/.bashrc
   ```

## 📁 Repository Structure

```text
dotfiles/
├── scripts/
│   ├── git/
│   │   ├── branch-report.sh
│   │   ├── code-churn.sh
│   │   ├── commit-report.sh
│   │   └── contributor-report.sh
│   ├── aliases.sh
│   └── install.sh
├── LICENSE
└── README.md
```

### Directory Overview

| File | Description |
| :--- | :--- |
| `scripts/aliases.sh` | Custom aliases, Bash functions, and universal Git report commands. |
| `scripts/install.sh` | Interactive installer for aliases, functions, and script permissions. |
| `scripts/git/branch-report.sh` | Analyzes Git branches, inactivity, merges, and divergence. |
| `scripts/git/code-churn.sh` | Identifies frequently modified files and code change volume. |
| `scripts/git/commit-report.sh` | Generates commit distribution and evolution reports. |
| `scripts/git/contributor-report.sh` | Analyzes contributors, commits, and lines changed. |

All Git report scripts can be executed independently or through the universal commands provided by `aliases.sh`.

## 🔧 Interactive Installer

The `scripts/install.sh` utility automates Bash environment configuration.

### Features

**1. Dependency validation**

Checks the commands required for installation and verifies that `aliases.sh` exists.

**2. Interactive collision detection**

Before installing aliases and functions, the installer checks whether commands with the same names already exist.

When a collision is detected, it asks:

```text
[WARNING] Command 'gco' already exists on your system.
Do you want to overwrite it with the repo version? (y/N):
```

Choosing `N` preserves the existing command.

**3. Alias and function installation**

Installs the selected aliases and functions into:

```text
~/.bash_aliases
```

The installer uses a managed section to organize definitions generated from the repository.

**4. Automatic script discovery**

Recursively searches the `scripts/` directory for `.sh` utility scripts, including scripts inside `scripts/git/`.

The files `install.sh` and `aliases.sh` are excluded from the utility permission step.

**5. Optional execution permissions**

Lists discovered scripts and asks whether execution permissions should be granted.

```text
--- Configure Script Permissions ---

Grant execution permission to all utility scripts? (y/N):
```

If confirmed, the installer applies `chmod u+x` to scripts that are not executable.

If declined, their permissions remain unchanged.

**6. Universal script path configuration**

Configures `DOTFILES_SCRIPTS_DIR` with the absolute path to the repository's `scripts/` directory.

This allows report functions to locate the original scripts regardless of the current working directory.

**7. Bash integration**

Configures `~/.bashrc` to load `~/.bash_aliases`, if necessary.

After installation:

```bash
source ~/.bashrc
```

> **Note:** The repository must remain at its installed location. If you move it, run the installer again to update the script path configuration.

## 📄 Available Commands & Aliases

### 🧹 System Utilities & Navigation

| Command | Description |
| :--- | :--- |
| `cls` | Clears the terminal screen. |
| `path` | Displays `$PATH` directories line by line. |
| `ff <file>` | Searches for files by name. |
| `mcd <directory>` | Creates a directory and navigates into it. |
| `gohome` | Navigates to the home directory. |
| `..` | Moves up one directory. |
| `...` | Moves up two directories. |
| `....` | Moves up three directories. |

### 🌐 Network & Operations

| Command | Description |
| :--- | :--- |
| `myip` | Displays the public IP address. |
| `ports` | Lists network ports and connections. |
| `diskh` | Displays disk usage. |
| `fmem` | Displays memory usage. |
| `extract <file>` | Extracts supported archive formats. |
| `bak <file>` | Creates a `.bak` copy of a file or directory. |
| `psg <process>` | Searches running processes by name. |

### 🐙 Git Shortcuts

| Command | Description |
| :--- | :--- |
| `gsts` | Displays Git repository status. |
| `gbranch` | Displays the current branch. |
| `gph` | Pushes the current branch to `origin`. |
| `glog` | Displays commit counts by author. |
| `glogg` | Displays the visual commit graph. |
| `gprune` | Fetches and prunes deleted remote references. |
| `gfo` | Fetches changes from `origin`. |
| `gnb <branch>` | Creates a new branch. |
| `gco <branch>` | Switches to an existing branch. |
| `grs <file>` | Restores a file from Git. |
| `gdb <branch>` | Deletes a local branch after confirmation. |
| `ghelp` | Displays available Git shortcuts. |

### 🐳 Docker Shortcuts

| Command | Description |
| :--- | :--- |
| `dps` | Lists running containers. |
| `dstopall` | Stops all running containers. |
| `dexec <container> [shell]` | Opens an interactive shell inside a container. |
| `dclean` | Removes unused Docker resources, including volumes. |

> **Warning:** `gdb` uses force deletion (`git branch -D`), and `dclean` removes unused Docker volumes. Review their effects before confirming or running them.

## 📊 Universal Git Report Commands

The `aliases.sh` file provides universal commands for executing Git analytics scripts.

| Command | Script | Description |
| :--- | :--- | :--- |
| `gcommits` | `commit-report.sh` | Commit distribution and evolution. |
| `gbranches` | `branch-report.sh` | Branch activity and status. |
| `gcontributors` | `contributor-report.sh` | Contributor statistics. |
| `gchurn` | `code-churn.sh` | File modification and churn analysis. |
| `greports` | — | Displays available report commands. |

### Usage

All report commands support the following syntax:

```bash
<command> [repository] [output-directory]
```

Examples:

```bash
gcommits
gbranches
gcontributors
gchurn
```

Without arguments, the current directory is used as the target repository.

You can also specify a repository:

```bash
gcommits "/path/to/repository"
gbranches "/path/to/repository"
gcontributors "/path/to/repository"
gchurn "/path/to/repository"
```

Or specify an output directory:

```bash
gchurn "/path/to/repository" "./reports/code-churn"
```

By default, the universal commands store generated reports under:

```text
repository/
└── git-reports/
    ├── commit-report/
    ├── branch-report/
    ├── contributor-report/
    └── code-churn/
```

Add `git-reports/` to the target repository's `.gitignore` if you do not want generated reports tracked by Git.

### Requirements

The report utilities use Git, Bash, AWK, GNU `date`, and other standard Linux tools.

Gnuplot is used to generate charts.

Install it on Ubuntu:

```bash
sudo apt update
sudo apt install gnuplot
```

For `commit-report.sh`, Gnuplot is required by the script. For the other reports, charts are skipped if Gnuplot is unavailable.

---

## 📈 Git Commit Report

**Script:** [`scripts/git/commit-report.sh`](scripts/git/commit-report.sh)

Analyzes commit messages and generates statistics based on conventional commit tags.

### Features

- Interactive period selection.
- Case-insensitive commit tag classification.
- Commit distribution by category.
- Commit evolution over time.
- Percentage calculation.
- PNG charts generated with Gnuplot.

### Available Periods

| Option | Period | Evolution Granularity |
| :--- | :--- | :--- |
| `1` | Daily | Hourly |
| `2` | Monthly | Daily |
| `3` | Yearly | Monthly |
| `4` | All Time | Monthly |

### Commit Categories

| Category | Recognized Tags |
| :--- | :--- |
| `FEAT/ADD` | `[FEAT]`, `[ADD]` |
| `FIX` | `[FIX]` |
| `TEST` | `[TEST]` |
| `REFACTOR` | `[REFACTOR]` |
| `DOCS` | `[DOCS]` |
| `CHORE` | `[CHORE]` |
| `STYLE` | `[STYLE]` |
| `OTHER` | Unrecognized or missing tags |

### Usage

```bash
gcommits "/path/to/repository"
```

Or directly:

```bash
bash scripts/git/commit-report.sh "/path/to/repository"
```

### Generated Files

| File | Description |
| :--- | :--- |
| `distribuicao.png` | Commit distribution chart. |
| `evolucao.png` | Commit evolution chart. |
| `resumo.dat` | Commit counts and percentages. |
| `evolution.dat` | Time-series data. |
| `commits_raw.tsv` | Raw commit history. |

The script analyzes locally available Git references and excludes merge commits.

---

## 🌿 Git Branch Report

**Script:** [`scripts/git/branch-report.sh`](scripts/git/branch-report.sh)

Analyzes repository branches to identify their activity, integration status, and divergence.

### Features

- Local, remote-tracking, or combined branch analysis.
- Interactive base branch selection.
- Configurable inactivity threshold.
- Ahead/behind commit counts.
- Identification of integrated and divergent branches.
- Optional remote reference update.
- CSV export and status distribution chart.

### Branch Status Categories

| Status | Description |
| :--- | :--- |
| `MERGED` | Branch tip is already contained in the base branch history. |
| `DIVERGED` | Branch contains exclusive commits and is behind the base. |
| `STALE` | Unmerged branch exceeds the inactivity threshold. |
| `ACTIVE` | Branch contains exclusive commits and recent activity. |
| `UP_TO_DATE` | Remaining branch state not classified above. |

### Usage

```bash
gbranches "/path/to/repository"
```

Or directly:

```bash
bash scripts/git/branch-report.sh "/path/to/repository"
```

### Generated Files

| File | Description |
| :--- | :--- |
| `branches.csv` | Detailed information for each branch. |
| `summary.dat` | Branch counts grouped by status. |
| `branch-status.png` | Branch status distribution chart. |

The script does not merge or delete branches.

An optional `git fetch --all --prune` operation may update local remote-tracking references when authorized.

---

## 👥 Git Contributor Report

**Script:** [`scripts/git/contributor-report.sh`](scripts/git/contributor-report.sh)

Analyzes contribution activity across a Git repository.

### Features

- Commit counts per contributor.
- Percentage of total commits.
- Lines added and deleted.
- Total changed lines.
- Contributor rankings.
- Daily activity data.
- Git `.mailmap` support.
- Commit and code change charts.

### Available Periods

| Option | Period |
| :--- | :--- |
| `1` | Daily |
| `2` | Monthly |
| `3` | Yearly |
| `4` | Custom date range |
| `5` | All Time |

The script also allows selecting all branches or the current branch and choosing whether merge commits should be included.

### Usage

```bash
gcontributors "/path/to/repository"
```

Or directly:

```bash
bash scripts/git/contributor-report.sh "/path/to/repository"
```

### Generated Files

| File | Description |
| :--- | :--- |
| `contributors.csv` | Contributor statistics. |
| `commits_raw.tsv` | Raw Git history. |
| `ranking.dat` | Contributor ranking. |
| `activity.dat` | Daily activity per contributor. |
| `authors.dat` | Author identification data. |
| `top-contributors.dat` | Data for the top contributors chart. |
| `contributors-commits.png` | Commits by contributor rank. |
| `contributors-changes.png` | Changed lines by contributor rank. |

> **Note:** Commit counts and changed lines indicate repository activity, not individual productivity or code quality.

---

## 🔥 Git Code Churn Report

**Script:** [`scripts/git/code-churn.sh`](scripts/git/code-churn.sh)

Identifies files with the highest modification frequency and change volume.

Code churn describes how frequently code changes over time.

Files with high churn may indicate active development, frequent maintenance, or areas worth reviewing.

### Features

- Counts commits modifying each file.
- Calculates added and deleted lines.
- Measures total changed lines.
- Identifies binary file modifications.
- Ranks files by commits or changed lines.
- Configurable ranking size.
- CSV export and visual chart.

### Available Periods

| Option | Period |
| :--- | :--- |
| `1` | Daily |
| `2` | Monthly |
| `3` | Yearly |
| `4` | Custom date range |
| `5` | All Time |

### Ranking Metrics

| Metric | Description |
| :--- | :--- |
| Commits | Number of commits modifying a file. |
| Lines Changed | Sum of added and deleted lines. |

### Usage

```bash
gchurn "/path/to/repository"
```

Or directly:

```bash
bash scripts/git/code-churn.sh "/path/to/repository"
```

### Generated Files

| File | Description |
| :--- | :--- |
| `code-churn.csv` | Complete file statistics. |
| `commits_raw.tsv` | Raw Git modification history. |
| `ranking.dat` | Ranked files. |
| `top-files.dat` | Chart data for top-ranked files. |
| `code-churn.png` | Code churn ranking chart. |

Merge commits are excluded, and renamed paths are treated separately.

Binary changes are counted without inventing added or deleted line totals.

> **Note:** High churn does not automatically indicate poor code quality. It should be interpreted alongside project context.

---

## 🇧🇷 Documentação em Português

## ⚡ Instalação Rápida

Clone o repositório e execute o instalador interativo:

```bash
git clone https://github.com/paulo-campos-57/dotfiles.git
cd dotfiles
bash scripts/install.sh
```

Após a instalação, recarregue as configurações do Bash:

```bash
source ~/.bashrc
```

O instalador identifica automaticamente aliases, funções e scripts utilitários, solicitando autorização antes de modificar permissões de execução.

### Instalação Manual

1. Clone o repositório:

   ```bash
   git clone https://github.com/paulo-campos-57/dotfiles.git
   cd dotfiles
   ```

2. Conceda permissão de execução ao instalador:

   ```bash
   chmod +x scripts/install.sh
   ```

3. Execute o instalador:

   ```bash
   ./scripts/install.sh
   ```

4. Recarregue o Bash:

   ```bash
   source ~/.bashrc
   ```

## 📁 Estrutura do Repositório

```text
dotfiles/
├── scripts/
│   ├── git/
│   │   ├── branch-report.sh
│   │   ├── code-churn.sh
│   │   ├── commit-report.sh
│   │   └── contributor-report.sh
│   ├── aliases.sh
│   └── install.sh
├── LICENSE
└── README.md
```

### Organização dos Arquivos

| Arquivo | Descrição |
| :--- | :--- |
| `scripts/aliases.sh` | Aliases, funções Bash e comandos universais de relatórios Git. |
| `scripts/install.sh` | Instalador interativo de aliases, funções e permissões. |
| `scripts/git/branch-report.sh` | Analisa branches, inatividade, integração e divergência. |
| `scripts/git/code-churn.sh` | Identifica arquivos frequentemente modificados. |
| `scripts/git/commit-report.sh` | Gera relatórios de distribuição e evolução de commits. |
| `scripts/git/contributor-report.sh` | Analisa contribuidores, commits e linhas alteradas. |

Os scripts de relatórios podem ser executados individualmente ou pelos comandos universais definidos em `aliases.sh`.

## 🔧 Instalador Interativo

O `scripts/install.sh` automatiza a configuração do ambiente Bash.

### Funcionalidades

**1. Validação de dependências**

Verifica os comandos necessários para a instalação e confirma a existência do arquivo `aliases.sh`.

**2. Detecção interativa de colisões**

Antes de instalar aliases e funções, verifica se existem comandos com os mesmos nomes no ambiente.

Quando encontra uma colisão, solicita confirmação:

```text
[WARNING] Command 'gco' already exists on your system.
Do you want to overwrite it with the repo version? (y/N):
```

Se o usuário responder `N`, o comando existente será preservado.

**3. Instalação de aliases e funções**

Instala as definições selecionadas em:

```text
~/.bash_aliases
```

As configurações geradas são organizadas em uma seção gerenciada pelo instalador.

**4. Descoberta automática de scripts**

Percorre recursivamente o diretório `scripts/`, identificando arquivos `.sh`, inclusive os presentes em `scripts/git/`.

Os arquivos `install.sh` e `aliases.sh` não participam da etapa de alteração de permissões dos utilitários.

**5. Permissões de execução opcionais**

Exibe os scripts encontrados e pergunta se deve conceder permissão de execução:

```text
--- Configure Script Permissions ---

Grant execution permission to all utility scripts? (y/N):
```

Caso autorizado, aplica `chmod u+x` aos scripts que ainda não possuem permissão de execução.

Caso contrário, mantém as permissões existentes.

**6. Configuração universal de caminhos**

Define a variável `DOTFILES_SCRIPTS_DIR` com o caminho absoluto do diretório `scripts/`.

Isso permite executar os relatórios Git independentemente do diretório atual do terminal.

**7. Integração com Bash**

Configura o `~/.bashrc` para carregar o arquivo `~/.bash_aliases`, quando necessário.

Após instalar:

```bash
source ~/.bashrc
```

> **Observação:** se o repositório `dotfiles` for movido, execute novamente o instalador para atualizar os caminhos configurados.

## 📄 Comandos e Aliases Disponíveis

### 🧹 Utilitários do Sistema & Navegação

| Comando | Descrição |
| :--- | :--- |
| `cls` | Limpa a tela do terminal. |
| `path` | Exibe os diretórios de `$PATH`, um por linha. |
| `ff <arquivo>` | Busca arquivos pelo nome. |
| `mcd <diretório>` | Cria um diretório e entra nele. |
| `gohome` | Navega para o diretório pessoal. |
| `..` | Volta um nível de diretório. |
| `...` | Volta dois níveis de diretório. |
| `....` | Volta três níveis de diretório. |

### 🌐 Rede & Operações

| Comando | Descrição |
| :--- | :--- |
| `myip` | Exibe o endereço IP público. |
| `ports` | Lista portas e conexões de rede. |
| `diskh` | Exibe o uso de disco. |
| `fmem` | Exibe o consumo de memória. |
| `extract <arquivo>` | Extrai arquivos compactados suportados. |
| `bak <arquivo>` | Cria uma cópia de backup com extensão `.bak`. |
| `psg <processo>` | Pesquisa processos em execução pelo nome. |

### 🐙 Atalhos do Git

| Comando | Descrição |
| :--- | :--- |
| `gsts` | Exibe o status do repositório Git. |
| `gbranch` | Exibe a branch atual. |
| `gph` | Envia a branch atual para `origin`. |
| `glog` | Exibe a quantidade de commits por autor. |
| `glogg` | Exibe a árvore visual de commits. |
| `gprune` | Atualiza e limpa referências remotas excluídas. |
| `gfo` | Busca atualizações do `origin`. |
| `gnb <branch>` | Cria uma nova branch. |
| `gco <branch>` | Alterna para uma branch existente. |
| `grs <arquivo>` | Restaura um arquivo usando Git. |
| `gdb <branch>` | Exclui uma branch local após confirmação. |
| `ghelp` | Exibe os atalhos Git disponíveis. |

### 🐳 Atalhos do Docker

| Comando | Descrição |
| :--- | :--- |
| `dps` | Lista containers em execução. |
| `dstopall` | Interrompe todos os containers em execução. |
| `dexec <container> [shell]` | Abre um terminal interativo dentro de um container. |
| `dclean` | Remove recursos Docker não utilizados, incluindo volumes. |

> **Atenção:** `gdb` utiliza exclusão forçada (`git branch -D`), enquanto `dclean` pode remover volumes Docker não utilizados. Verifique os efeitos desses comandos antes de executá-los.

## 📊 Comandos Universais de Relatórios Git

O `aliases.sh` disponibiliza funções para executar os scripts de relatórios de qualquer diretório.

| Comando | Script | Descrição |
| :--- | :--- | :--- |
| `gcommits` | `commit-report.sh` | Distribuição e evolução dos commits. |
| `gbranches` | `branch-report.sh` | Análise de branches. |
| `gcontributors` | `contributor-report.sh` | Estatísticas de contribuidores. |
| `gchurn` | `code-churn.sh` | Análise de modificações em arquivos. |
| `greports` | — | Exibe os comandos disponíveis. |

### Utilização

Os comandos seguem a sintaxe:

```bash
<comando> [repositório] [diretório-de-saída]
```

Para analisar o repositório atual:

```bash
gcommits
gbranches
gcontributors
gchurn
```

Para analisar outro repositório:

```bash
gcommits "/caminho/do/repositorio"
gbranches "/caminho/do/repositorio"
gcontributors "/caminho/do/repositorio"
gchurn "/caminho/do/repositorio"
```

Também é possível informar um diretório de saída:

```bash
gchurn "/caminho/do/repositorio" "./reports/code-churn"
```

Por padrão, os relatórios são armazenados em:

```text
repositorio/
└── git-reports/
    ├── commit-report/
    ├── branch-report/
    ├── contributor-report/
    └── code-churn/
```

Recomenda-se adicionar `git-reports/` ao `.gitignore` dos repositórios analisados para evitar o versionamento dos arquivos gerados.

### Dependências

Os scripts utilizam Bash, Git, AWK, GNU `date` e ferramentas comuns do Linux.

O Gnuplot é utilizado para gerar gráficos.

No Ubuntu:

```bash
sudo apt update
sudo apt install gnuplot
```

No `commit-report.sh`, o Gnuplot é obrigatório. Nos demais relatórios, os gráficos são ignorados caso ele não esteja instalado.

---

## 📈 Relatório de Commits Git

**Script:** [`scripts/git/commit-report.sh`](scripts/git/commit-report.sh)

Analisa mensagens de commits e gera estatísticas a partir das tags utilizadas.

### Funcionalidades

- Seleção interativa de período.
- Identificação de tags sem diferenciar maiúsculas e minúsculas.
- Distribuição dos commits por categoria.
- Evolução temporal dos commits.
- Cálculo de percentuais.
- Geração de gráficos PNG.

### Períodos Disponíveis

| Opção | Período | Granularidade |
| :--- | :--- | :--- |
| `1` | Diário | Por hora |
| `2` | Mensal | Por dia |
| `3` | Anual | Por mês |
| `4` | Todo o histórico | Por mês |

### Categorias

| Categoria | Tags Reconhecidas |
| :--- | :--- |
| `FEAT/ADD` | `[FEAT]`, `[ADD]` |
| `FIX` | `[FIX]` |
| `TEST` | `[TEST]` |
| `REFACTOR` | `[REFACTOR]` |
| `DOCS` | `[DOCS]` |
| `CHORE` | `[CHORE]` |
| `STYLE` | `[STYLE]` |
| `OTHER` | Tags não reconhecidas ou ausentes |

### Execução

```bash
gcommits "/caminho/do/repositorio"
```

Ou diretamente:

```bash
bash scripts/git/commit-report.sh "/caminho/do/repositorio"
```

### Arquivos Gerados

| Arquivo | Descrição |
| :--- | :--- |
| `distribuicao.png` | Gráfico de distribuição dos commits. |
| `evolucao.png` | Gráfico de evolução temporal. |
| `resumo.dat` | Quantidades e percentuais por categoria. |
| `evolution.dat` | Dados de evolução temporal. |
| `commits_raw.tsv` | Histórico bruto utilizado na análise. |

O script utiliza as referências Git disponíveis localmente e exclui commits de merge.

---

## 🌿 Relatório de Branches Git

**Script:** [`scripts/git/branch-report.sh`](scripts/git/branch-report.sh)

Analisa as branches do repositório para identificar atividade, integração e divergência.

### Funcionalidades

- Análise de branches locais e remotas.
- Seleção interativa da branch de referência.
- Configuração do limite de inatividade.
- Contagem de commits à frente e atrás.
- Identificação de branches integradas e divergentes.
- Atualização opcional das referências remotas.
- Exportação CSV e gráfico de distribuição.

### Classificações

| Status | Descrição |
| :--- | :--- |
| `MERGED` | O commit da branch já está contido no histórico da referência. |
| `DIVERGED` | Possui commits exclusivos e está atrás da referência. |
| `STALE` | Não integrada e ultrapassou o limite de inatividade. |
| `ACTIVE` | Possui commits exclusivos e atividade recente. |
| `UP_TO_DATE` | Estado restante não enquadrado nas categorias anteriores. |

### Execução

```bash
gbranches "/caminho/do/repositorio"
```

Ou diretamente:

```bash
bash scripts/git/branch-report.sh "/caminho/do/repositorio"
```

### Arquivos Gerados

| Arquivo | Descrição |
| :--- | :--- |
| `branches.csv` | Informações detalhadas das branches. |
| `summary.dat` | Quantidade de branches por status. |
| `branch-status.png` | Gráfico de distribuição dos status. |

O script não realiza merges nem exclui branches.

A atualização opcional com `git fetch --all --prune` modifica apenas as referências remotas locais.

---

## 👥 Relatório de Contribuidores Git

**Script:** [`scripts/git/contributor-report.sh`](scripts/git/contributor-report.sh)

Analisa a participação dos autores no histórico de commits do repositório.

### Funcionalidades

- Contagem de commits por autor.
- Percentual de participação no total de commits.
- Quantidade de linhas adicionadas e removidas.
- Total de linhas alteradas.
- Ranking de contribuidores.
- Histórico diário de atividade.
- Suporte a `.mailmap`.
- Gráficos de commits e alterações.

### Períodos Disponíveis

| Opção | Período |
| :--- | :--- |
| `1` | Diário |
| `2` | Mensal |
| `3` | Anual |
| `4` | Intervalo personalizado |
| `5` | Todo o histórico |

O script permite analisar todas as branches ou apenas a atual, além de escolher se commits de merge serão incluídos.

### Execução

```bash
gcontributors "/caminho/do/repositorio"
```

Ou diretamente:

```bash
bash scripts/git/contributor-report.sh "/caminho/do/repositorio"
```

### Arquivos Gerados

| Arquivo | Descrição |
| :--- | :--- |
| `contributors.csv` | Estatísticas por contribuidor. |
| `commits_raw.tsv` | Histórico bruto do Git. |
| `ranking.dat` | Ranking dos contribuidores. |
| `activity.dat` | Atividade diária por autor. |
| `authors.dat` | Identificação dos autores. |
| `top-contributors.dat` | Dados dos principais contribuidores. |
| `contributors-commits.png` | Gráfico de commits por posição no ranking. |
| `contributors-changes.png` | Gráfico de linhas alteradas por posição no ranking. |

> **Observação:** quantidade de commits e linhas alteradas não representam, isoladamente, produtividade ou qualidade do código.

---

## 🔥 Relatório de Code Churn

**Script:** [`scripts/git/code-churn.sh`](scripts/git/code-churn.sh)

Identifica os arquivos que sofreram mais modificações ao longo do histórico Git.

*Code churn* representa a frequência e o volume de alterações realizadas no código.

Arquivos com churn elevado podem indicar desenvolvimento ativo, manutenção frequente ou áreas que merecem investigação.

### Funcionalidades

- Contagem de commits que modificaram cada arquivo.
- Quantidade de linhas adicionadas e removidas.
- Cálculo do volume total de alterações.
- Identificação de modificações em arquivos binários.
- Ranking por commits ou linhas alteradas.
- Quantidade configurável de arquivos no ranking.
- Exportação CSV e gráfico PNG.

### Períodos Disponíveis

| Opção | Período |
| :--- | :--- |
| `1` | Diário |
| `2` | Mensal |
| `3` | Anual |
| `4` | Intervalo personalizado |
| `5` | Todo o histórico |

### Métricas de Ranking

| Métrica | Descrição |
| :--- | :--- |
| Commits | Quantidade de commits que modificaram o arquivo. |
| Linhas Alteradas | Soma das linhas adicionadas e removidas. |

### Execução

```bash
gchurn "/caminho/do/repositorio"
```

Ou diretamente:

```bash
bash scripts/git/code-churn.sh "/caminho/do/repositorio"
```

### Arquivos Gerados

| Arquivo | Descrição |
| :--- | :--- |
| `code-churn.csv` | Estatísticas completas por arquivo. |
| `commits_raw.tsv` | Histórico bruto das modificações. |
| `ranking.dat` | Ranking dos arquivos. |
| `top-files.dat` | Dados utilizados no gráfico. |
| `code-churn.png` | Gráfico de code churn. |

Os commits de merge são excluídos e os caminhos de arquivos renomeados são tratados separadamente.

Alterações em arquivos binários são contabilizadas sem atribuir valores artificiais de linhas adicionadas ou removidas.

> **Observação:** churn elevado não significa necessariamente baixa qualidade. Os resultados devem ser interpretados considerando o contexto e o histórico de desenvolvimento do projeto.

---

## 📜 License / Licença

See the [`LICENSE`](LICENSE) file for licensing information.

Consulte o arquivo [`LICENSE`](LICENSE) para informações sobre a licença do projeto.
