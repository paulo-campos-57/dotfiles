<div align="center">
  <h1>
    <img src="https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" />
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" />
    <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" />
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
    <br>
    Dotfiles & Linux Utilities 🇺🇸
  </h1>
  <p>Personal repository for Linux aliases, custom functions, and interactive automation tools</p>
</div>

## ⚡ Quick Installation

Install all aliases and utility functions directly with a single command:

```bash
curl -sSL [https://raw.githubusercontent.com/paulo-campos-57/dotfiles/main/install.sh](https://raw.githubusercontent.com/paulo-campos-57/dotfiles/main/install.sh) | bash
```

### Manual instalation
1. Clone the repository:
   ```bash
   git clone https://github.com/paulo-campos-57/dotfiles.git
   cd dotfiles
   ```
2. Make the installer executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the setup script:
   ```bash
   ./install.sh
   ```
4. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```

## 🔍 Interactive Collision Detection

The `install.sh` script automatically inspects your enviroment before making changes:

- **[COLLISION]:** Detects if an alias, function, or system command with the same name already exists and prompts you to overwrite it `(y/N)`.
- **[SKIPPED]:** Safely preserves your original system commands whenever you decline an overwrite prompt.

## 📄 Available Commands & Aliases

### 🧹 System Utilities & Navigation
| Command | Description |
| :--- | :--- |
| `cls` | Clears the terminal screen (`clear`). |
| `path` | Displays `$PATH` directories formatted line by line. |
| `ff <file>` | Searches for files by name in the current directory (`find . -type f -name`). |
| `mcd <dir>` | Creates a directory and immediately navigates into it. |
| `gohome` | Navigates to `~` and displays the current path. |
| `..` | Move up 1 directory level. |
| `...` | Move up 2 directory levels. |
| `....` | Move up 3 directory levels. |

### 🌐 Network & Operations
| Command | Description |
| :--- | :--- |
| `myip` | Fetches public IP address via `ifconfig.me`. |
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
| `gbranch` | Displays current active Git branch. |
| `gph` | Pushes local changes to `origin HEAD`. |
| `glog` | Shows commit count per author (`git shortlog -s -n --all`). |
| `glogg` | Shows formatted visual commit graph tree. |
| `gprune` | Fetches remote updates and prunes deleted references. |
| `gfo` | Fetches updates from `origin` without merging. |
| `gnb <branch>` | Creates and switches to a new Git branch (`git switch -c`). |
| `gco <branch>` | Switches to an existing local branch (`git switch`). |
| `grs <file>` | Restores a modified file to HEAD state (`git restore`). |
| `gdb <branch>` | Prompts for confirmation before deleting a local branch. |
| `ghelp` | Displays a clean summary menu of available Git commands. |

### 🐳 Docker Shortcuts
| Command | Description |
| :--- | :--- |
| `dps` | Displays running containers in a clean, formatted table. |
| `dstopall` | Stops all running Docker containers. |
| `dexec <container> [shell]` | Opens interactive session inside container (defaults to `bash`). |
| `dclean` | Prunes unused containers, networks, images, and volumes. |

---

<div align="center">
  <h1>
    <img src="https://img.shields.io/badge/GNU%20Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white" />
    <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" />
    <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" />
    <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
    <br>
    Dotfiles e Utilitários Linux 🇧🇷
  </h1>
  <p>Repositório pessoal para aliases do Linux, funções customizadas e ferramentas automação interativa</p>
</div>

## ⚡ Instalação Rápida

Instale todos os aliases e funções utilitárias diretamente com um único comando no terminal:

```bash
curl -sSL [https://raw.githubusercontent.com/paulo-campos-57/dotfiles/main/install.sh](https://raw.githubusercontent.com/paulo-campos-57/dotfiles/main/install.sh) | bash
```

### Instalação Manual
1. Clone o repositório:
   ```bash
   git clone https://github.com/paulo-campos-57/dotfiles.git
   cd dotfiles
   ```
2. Dê permissão de execução ao instalador:
   ```bash
   chmod +x install.sh
   ```
3. Execute o script de instalação:
   ```bash
   ./install.sh
   ```
4. Recarregue as configurações do seu terminal:
   ```bash
   source ~/.bashrc
   ```

## 🔍 Detecção Interativa de Colisões

O script `install.sh` analisa o seu ambiente de sistema antes de aplicar qualquer alteração:

- **[COLLISION]:** Detecta se um alias, função ou comando do sistema com o mesmo nome já existe e pergunta se você deseja sobrescrevê-lo `(y/N)`.
- **[SKIPPED]:** Preserva seus comandos originais com segurança caso você recuse a substituição.

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
