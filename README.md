# ylgeeker/vim

一套可一键部署的 **Vim / Neovim** 开发环境配置，面向 **C++、Go、Python、NASM** 日常编码。

---

## 项目目的

本仓库解决两件事：

1. **配置即代码** — `vimrc`、`after/` 等配置集中在 Git 仓库，默认 symlink 到 `~/.vimrc`。
2. **环境一键就绪** — `install.sh` 自动安装 Vim/Neovim、Node.js、语言服务器（clangd、gopls 等）、插件与 coc 扩展，无需手工拼插件和 LSP。

Vim 与 Neovim **共用同一套配置**（`~/.vim/plugged`），在终端里用 `vim` 或 `nvim` 体验一致。

---

## 能做什么

| 能力 | 实现方式 |
|------|----------|
| C++ 跳转 / 补全 / 诊断 | coc-clangd（需 `compile_commands.json`） |
| Go 跳转 / 补全 | coc-go（gopls） |
| Python 跳转 / 补全 | coc-pyright |
| NASM 语法高亮 / 编译运行 | 内置语法 + gutentags；`<F5>` 一键构建 |
| 文件搜索 / 符号浏览 | fzf、NERDTree、Tagbar |
| Cursor 联动（可选） | `--with-cursor` 后：Vim `<leader>cc` / Neovim `<leader>cf` 在 Cursor 中打开当前文件 |

---

## 快速开始

**推荐：克隆仓库后本地安装**（配置 symlink 到仓库，修改即时生效）

```sh
git clone https://github.com/ylgeeker/vim.git ~/vim-config
cd ~/vim-config
chmod +x install.sh scripts/bootstrap.sh uninstall.sh
./install.sh
```

**远程一行安装**（shallow clone 到 `~/.local/share/ylgeeker/vim`，可用 `--install-dir` 修改；需本机已安装 `git`）：

```sh
curl -fsSL https://raw.githubusercontent.com/ylgeeker/vim/main/scripts/bootstrap.sh | bash
```

带参数示例：

```sh
curl -fsSL https://raw.githubusercontent.com/ylgeeker/vim/main/scripts/bootstrap.sh | bash -s -- --with-cursor
curl -fsSL https://raw.githubusercontent.com/ylgeeker/vim/main/scripts/bootstrap.sh | bash -s -- --user-install
# 指定 clone 目录与 fork 仓库
curl -fsSL .../bootstrap.sh | bash -s -- --install-dir ~/vim-config --repo-url https://github.com/you/vim.git
```

也可直接管道执行 `install.sh`（效果相同）：

```sh
curl -fsSL https://raw.githubusercontent.com/ylgeeker/vim/main/install.sh | bash -s -- --dry-run
```

远程 `--dry-run` 仅检测操作系统，**不会** clone 仓库。clone 目录与仓库地址请用 bootstrap 参数 `--install-dir`、`--repo-url`（见上方示例）。

开发/CI 测试远程入口时可用环境变量（**不**影响已 clone 后 `./install.sh` 的 CLI 参数）：

- `REPO_RAW`：管道模式下拉取脚本的 base URL（默认 GitHub `main` raw）
- `REPO_URL`：未传 `--repo-url` 时的 git clone 地址（例如 `file:///path/to/checkout`）

本地开发请直接运行 `./install.sh`；`./scripts/bootstrap.sh` 会 clone 到 `~/.local/share/ylgeeker/vim` 再安装。

安装结束前会自动运行 L1 验证（工具链、coc 扩展、NASM 样例编译等）。首次安装约 **15–60 分钟**，视网络与是否需编译 Vim/ctags 而定。

> 安装前建议备份 `~/.vimrc` 与 `~/.vim`。

---

## 常用命令

```sh
./install.sh                 # 安装 / 更新环境（默认不装 Cursor）
./install.sh --with-cursor   # 额外安装 Cursor 编辑器集成
./install.sh --user-install  # 无 sudo，安装到 ~/.local（能力有限）
./install.sh --copy-config   # 拷贝配置而非 symlink
./install.sh --dry-run       # 仅检测操作系统
./install.sh --help          # 查看全部参数

./uninstall.sh               # 移除 symlink 与生成的 coc-settings
./uninstall.sh --full        # 额外删除插件与 coc 数据
```

### 主要参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--with-cursor` | off | 安装 Cursor 与 agent CLI |
| `--copy-config` | off | 拷贝配置，不用 symlink |
| `--user-install` | off | 用户态安装，不用 sudo |
| `--node-version N` | `20` | Node.js 主版本 |
| `--go-version V` | `1.24.2` | Go 工具链版本 |
| `--install-bazel` | off | 安装 Bazel（Debian/Ubuntu） |
| `--dry-run` | off | 检测 OS 后退出 |

完整列表见 `./install.sh --help`。`install.sh` 安装选项**仅通过命令行传入**；远程 bootstrap 另支持 `REPO_RAW` / `REPO_URL`（见上文）。

---

## 日常使用

安装完成后，直接打开编辑器：

```sh
vim    # 或 nvim
```

常用快捷键（coc.nvim）：

| 按键 | 作用 |
|------|------|
| `gd` | 跳转到定义 |
| `gr` | 查找引用 |
| `<leader>rn` | 重命名符号 |
| `<leader>ff` | 格式化 |
| `<C-p>` | 模糊搜索文件 |
| `<leader>gg` | 项目内搜索（优先 ripgrep，回退 silver-searcher） |

**C++** 项目需生成编译数据库后 clangd 才能完整工作：

```sh
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/compile_commands.json .
```

**NASM** 在 `.asm` 文件中按 `<F5>` 编译并运行。

---

## 自定义配置

| 路径 | 说明 |
|------|------|
| [`vimrc`](vimrc) | 插件列表与入口 |
| [`after/`](after/) | 分语言配置（`lang-cpp.vim`、`lang-go.vim` 等） |
| [`coc-settings.json.in`](coc-settings.json.in) | coc 模板；安装时**生成**到 `~/.vim/coc-settings.json`（非 symlink） |

修改 `vimrc` / `after/` 后即时生效（symlink）。修改 `coc-settings.json.in` 或需刷新插件时，重新执行 `./install.sh`。

---

## 平台支持

| 系统 | 包管理 |
|------|--------|
| Ubuntu / Debian | apt |
| CentOS / Rocky / Alma / Fedora | yum / dnf |
| macOS 12+ | Homebrew |
| WSL2 | 同 Linux |

暂不支持 Alpine、Arch（欢迎贡献 `scripts/lib/deps-*.sh`）。

---

## 其他说明

**从 YouCompleteMe 迁移** — 新配置已移除 YCM；`install.sh` 会自动清理旧插件。也可手动：

```sh
vim +PlugClean! +qall
rm -rf ~/.vim/plugged/YouCompleteMe
```

**Cursor 集成** — 默认不安装。详见 [docs/cursor-vim-integration.md](docs/cursor-vim-integration.md)。

**验证安装** — 安装脚本末尾自动校验；也可手动测试 NASM 样例（Linux 用 `elf64`，macOS 用 `macho64`）：

```sh
# Linux
nasm -f elf64 test/fixtures/nasm/hello.asm -o /tmp/t.o && echo OK
# macOS
nasm -f macho64 test/fixtures/nasm/hello.asm -o /tmp/t.o && echo OK
```
