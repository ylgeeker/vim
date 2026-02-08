# Cursor CLI 与 Vim 集成

本说明介绍如何在 Vim/Neovim 中集成本机 Cursor CLI，从而在编辑器内使用 Cursor 的完整能力（在 Cursor 中打开文件、启动 Agent 交互/非交互、Plan/Ask 模式、会话管理等）。

## 一键安装（推荐）

本仓库的 **一键安装脚本** 会自动：

- 安装 Cursor 编辑器（Linux .deb/.rpm/AppImage）
- 安装 Cursor CLI（agent）并确保 `~/.local/bin` 在 PATH
- 将 `plugin/cursor.vim` 复制到 `~/.vim/plugin/` 并在 vimrc 中自动启用（Neovim 加载完整插件，Vim 使用内置简单命令）

克隆仓库后执行：

```bash
./install.sh
```

跳过 Cursor 安装仅配 Vim：`SKIP_CURSOR=1 ./install.sh`。

## 前置条件（若未使用一键脚本）

1. **已安装 Cursor 桌面版**  
   从 [cursor.com/downloads](https://cursor.com/downloads) 下载并安装；或由 `install.sh` 自动安装。

2. **安装 Shell 命令 `cursor`**  
   在 Cursor 中打开命令面板（Ctrl/Cmd+Shift+P），执行：
   - `Install 'cursor' to shell`

3. **安装 Cursor CLI（agent）**  
   在终端执行：
   ```bash
   curl https://cursor.com/install-fsS | bash
   ```
   并将 `~/.local/bin` 加入 PATH（若尚未加入）：
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```
   验证：
   ```bash
   agent --version
   cursor path/to/file
   ```

4. **Neovim**  
   完整插件（Agent/Plan/Ask 等）使用 `jobstart()`，需 **Neovim**。纯 Vim 使用 vimrc 内置的简单「在 Cursor 中打开」命令。

## 安装插件（非一键脚本时）

任选其一：

### 方式 A：复制到 runtimepath

```bash
mkdir -p ~/.vim/plugin
cp /path/to/vim/plugin/cursor.vim ~/.vim/plugin/
```

Neovim 用户也可用 `~/.config/nvim/plugin/cursor.vim`。

### 方式 B：在配置中 source

在 `~/.vimrc` 或 `~/.config/nvim/init.vim` 中：

```vim
if has('nvim')
  runtime! plugin/cursor.vim
endif
```

## 命令一览

| 命令 | 说明 |
|------|------|
| `CursorOpen [path]` | 在 Cursor 中打开路径（默认当前文件或项目根） |
| `CursorOpenFile` | 在 Cursor 中打开当前文件 |
| `CursorOpenLine` | 在 Cursor 中打开当前文件并跳转到当前行 |
| `CursorAgent [prompt]` | 启动 Agent 交互会话（可带初始 prompt） |
| `CursorAgentPlan [prompt]` | 以 Plan 模式启动 Agent 交互 |
| `CursorAgentAsk [prompt]` | 以 Ask 模式启动 Agent 交互 |
| `CursorAgentResume` | 恢复最近一次 Agent 会话 |
| `CursorAgentLs` | 列出 Agent 会话列表 |
| `CursorAgentPrompt {prompt}` | 非交互执行 prompt，输出到新 buffer |
| `CursorAgentPromptPlan {prompt}` | 非交互 Plan 模式执行 |
| `CursorAgentPromptAsk {prompt}` | 非交互 Ask 模式执行 |

## 默认键位

在未设置 `g:cursor_no_mappings` 时，使用 `<leader>` 前缀（默认 `\`）：

| 按键 | 对应命令 |
|------|----------|
| `<leader>co` | 在 Cursor 中打开（当前文件/目录） |
| `<leader>cf` | 在 Cursor 中打开当前文件 |
| `<leader>cl` | 在 Cursor 中打开当前文件并定位到行 |
| `<leader>ca` | 启动 Agent 交互 |
| `<leader>cA` | 启动 Agent 并输入 prompt |
| `<leader>cp` | Plan 模式交互 |
| `<leader>ck` | Ask 模式交互 |
| `<leader>cr` | 恢复上次会话 |
| `<leader>cL` | 列出会话 |
| 选中后 `<leader>ca` | 以选中内容为初始 prompt 启动 Agent |
| 选中后 `<leader>cP` | 以选中内容为 prompt 非交互执行并输出到 buffer |

## 配置项

在 `init.vim` / `init.lua` 中可设置：

```vim
" 禁用默认键位
let g:cursor_no_mappings = 1

" 使用其他前缀（例如空格）
let g:cursor_leader = '<Space>'

" agent / cursor 命令路径（若不在 PATH）
let g:cursor_cli_agent = 'agent'
let g:cursor_cli_cursor = 'cursor'

" 是否在 Neovim 终端 buffer 中运行交互式 agent（1=是，0=后台 detach）
let g:cursor_use_terminal = 1

" 纯终端下不调用 agent，避免报错：1=强制禁用；0=不强制（仍会受下面自动检测影响）
let g:cursor_disable_agent = 0
" 默认 1：当 TERM_PROGRAM 非 vscode/cursor 时自动禁用 agent（纯终端主机不再出现该报错）
let g:cursor_agent_auto_disable_outside_ide = 1
" 在 IDE 终端内且未禁用时：1=用 Cursor 打开并复制 prompt；0=在 Vim 内跑 agent
let g:cursor_agent_print_use_cursor_fallback = 1
" 当上面为 0 时：0=jobstart 跑 agent；1=在终端 buffer 跑（需从 Cursor 集成终端启动 nvim）
let g:cursor_agent_print_in_terminal = 1
```

## 项目根目录

非交互命令和 Agent 的工作目录默认为：

1. 当前 buffer 的 `b:cursor_workspace_root`（若设置）
2. 或 `FindRoot()`（若存在该函数，如 vim-rooter）
3. 否则为 `getcwd()`

可在项目内设置：

```vim
let b:cursor_workspace_root = expand('%:p:h')
" 或使用插件检测到的根目录
```

## 使用示例

- 在 Cursor 中打开当前文件：  
  `:CursorOpenFile` 或 `<leader>cf`

- 用当前选中内容问 Agent，结果在 Vim 里看：  
  选中文字 → `<leader>cP`

- 先规划再写代码：  
  `:CursorAgentPlan` 或 `<leader>cp`，然后输入需求

- 只问不改（只读）：  
  `:CursorAgentAsk 这段代码在做什么`

- 脚本/自动化（非交互）：  
  `:CursorAgentPrompt 列出所有 TODO 并给出修改建议`

## 故障排除

### "Command is only available in WSL or inside a Visual Studio Code terminal"（纯终端主机彻底避免）

在**仅终端的主机**（SSH、无 Cursor/VS Code 桌面）上，agent CLI 只能报此错误且无法真正可用。插件已**默认在非 IDE 终端下禁用 agent**，不再执行任何会触发该报错的调用。

**行为说明：**

- **自动禁用**（默认）：当环境变量 `TERM_PROGRAM` 不是 `vscode` 或 `cursor` 时（即普通终端、SSH 等），所有 Agent 相关操作（`<leader>ca`、`<leader>cP`、`:CursorAgent`、`:CursorAgentPrompt` 等）**不会调用 agent**，只提示“当前为纯终端环境，Cursor Agent 不可用”，并提示可在 Cursor 集成终端内运行或设置 `g:cursor_agent_auto_disable_outside_ide=0` 尝试。
- 因此**纯终端主机上不会再出现** "Command is only available in WSL or inside a Visual Studio Code terminal" 报错。
- 若你**确实在 WSL 或 Cursor 集成终端内**运行 nvim 且希望使用 Agent，无需改配置（自动检测到 `TERM_PROGRAM` 即会启用）。若在非 IDE 终端仍想尝试，可在 vimrc 中关闭自动禁用：
  ```vim
  let g:cursor_agent_auto_disable_outside_ide = 0
  ```
  （CLI 在非 Cursor/VS Code 终端可能仍会报错。）
- 也可**显式强制禁用**（任何环境下都不调用 agent）：
  ```vim
  let g:cursor_disable_agent = 1
  ```
  若曾设置过，改为 `0` 即可恢复（仍受上面自动禁用影响）。

**有 Cursor 桌面时**：若在带图形界面的机器上、且希望 `<leader>cP` 不直接跑 agent 而是打开 Cursor 并复制 prompt，可保持 `g:cursor_agent_print_use_cursor_fallback = 1`（默认）。纯终端下因已自动禁用 agent，不会执行“打开 Cursor”的回退。

**计划只用纯终端写代码（无 Cursor 界面）**：在 vimrc 里**先于**加载 Cursor 插件的位置加上：

```vim
let g:cursor_disable_agent = 1
let g:cursor_agent_auto_disable_outside_ide = 1
let g:cursor_agent_silent_disable = 1
```

- `cursor_disable_agent = 1`：显式关闭 Agent，不调用 CLI。
- `cursor_agent_auto_disable_outside_ide = 1`：在非 IDE 终端下也禁用（与上条一起保证纯终端不调 agent）。
- `cursor_agent_silent_disable = 1`：被禁用时不再提示「Agent 不可用」，按到 `<leader>ca` / `<leader>cP` 等会静默跳过。

这样在 SSH/系统终端里用 Vim 时不会报错、也不会每次按到 Agent 键位就弹提示。若本机装了 `cursor` 命令，仍可用 `:CursorOpen` 等在 Cursor 里打开文件（需有图形环境）。

### 从 Shell 中卸载 Cursor 命令

若要移除「Install 'cursor' to shell」添加的 `cursor` 命令，在仓库根目录执行：

```bash
chmod +x uninstall-cursor-shell.sh && ./uninstall-cursor-shell.sh
```

脚本会从 `~/.bashrc`、`~/.zshrc`、`~/.profile` 中删除 Cursor 的 PATH 行，并删除常见位置的 `cursor` 符号链接；修改前会自动备份 rc 文件。执行后请 `source ~/.bashrc` 或重新打开终端。

## 参考

- [Cursor CLI 概述](https://cursor.com/docs/cli/overview)
- [Cursor CLI 安装](https://cursor.com/docs/cli/installation)
- [Shell 命令（cursor/code）](https://cursor.com/docs/configuration/shell)
