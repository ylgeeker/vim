# Personal VimIDE

一键安装并配置 Vim，并自动安装、配置 Cursor，与 Vim 配置集成且自动启用。可直接修改仓库内 `vimrc` 后重新执行安装脚本使配置生效。

安装前建议备份并清理 HOME 下以 `.vim` 开头的目录，避免新旧配置冲突。

推荐系统：Ubuntu 或 CentOS 8+（Clang 11+、GCC 7+/8+）。

---

## 一键安装

**从本仓库克隆后安装（推荐，便于直接改 vimrc）：**

```sh
git clone https://github.com/ylgeeker/vim.git ~/vim-config && cd ~/vim-config
chmod +x install.sh && ./install.sh
```

**或直接远程执行（使用 GitHub 上的 vimrc，无法本地改 vimrc 再重跑）：**

```sh
sudo wget -O - https://raw.githubusercontent.com/ylgeeker/vim/master/install.sh | bash
```

安装脚本会：

- 安装/编译 Vim 9+、vim-plug、fzf、universal-ctags、Go 等依赖
- **自动安装 Cursor 编辑器**（Linux .deb/.rpm/AppImage）并**安装 Cursor CLI（agent）**
- 使用**本仓库的 vimrc** 和 **plugin/cursor.vim** 配置 Vim，并**自动启用 Cursor 集成**

---

## 自定义配置（直接改 vimrc）

- **推荐**：在仓库里改 `vimrc`，然后再次执行 `./install.sh`，脚本会把最新 `vimrc` 拷到 `~/.vimrc`。
- 也可直接编辑 `~/.vimrc`（重跑安装会按仓库内 vimrc 覆盖，除非你改的是仓库里的 vimrc）。

跳过 Cursor 安装（只配 Vim）时：

```sh
SKIP_CURSOR=1 ./install.sh
```

---

## Cursor 与 Vim 集成（自动启用）

- **Vim**：若已安装 Cursor 且 `cursor` 在 PATH 中，可用：
  - `<Leader>cc` 在 Cursor 中打开当前文件
  - `<Leader>cP` 打开当前文件所在目录
  - `<Leader>cF` 打开当前工作目录  
  首次使用需在 Cursor 中执行：Command Palette → `Install 'cursor' to shell`。

- **Neovim**：会加载 `plugin/cursor.vim`，支持在 Cursor 中打开文件/目录，以及 Agent 交互、Plan/Ask 等，键位见 [docs/cursor-vim-integration.md](docs/cursor-vim-integration.md)。

**纯终端主机**（仅 SSH/无 Cursor 桌面）：插件默认在非 Cursor/VS Code 终端下**不调用 agent**，只提示“当前为纯终端环境，Cursor Agent 不可用”，**不会出现** “Command is only available in WSL or inside a Visual Studio Code terminal” 报错。详见 [docs/cursor-vim-integration.md#故障排除](docs/cursor-vim-integration.md)。

---

## 其他

推荐主题： [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized)

```vim
let g:solarized_termcolors=256
let g:solarized_termtrans=1
```

推荐终端配色：

- Foreground: `00f900`
- Background: `002b36`

```sh
export PS1='\[\e[32;1m\][\u@\h \W]\\$> \[\e[0m\]'
```
