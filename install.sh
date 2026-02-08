#!/usr/bin/env bash
# 一键安装并配置 Vim + Cursor 集成
# 使用本仓库内的 vimrc 与 plugin，可直接修改 vimrc 后重新执行此脚本生效
set -eo pipefail

# 仓库根目录（脚本所在目录）；若从 wget | bash 运行则脚本在 /tmp，用 INSTALL_ROOT 存下载文件
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
INSTALL_ROOT="${INSTALL_ROOT:-/tmp/ylgeeker/vim}"
mkdir -p "$INSTALL_ROOT"
cd "$INSTALL_ROOT"
# 远程安装时 REPO_ROOT 可能无 vimrc，用 GITHUB_RAW 拉取
GITHUB_RAW="${GITHUB_RAW:-https://raw.githubusercontent.com/ylgeeker/vim/master}"

# 颜色输出
info()  { echo -e "\033[34;1m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[32;1m[OK]\033[0m $*"; }
warn()  { echo -e "\033[33;1m[WARN]\033[0m $*"; }
err()   { echo -e "\033[31;1m[ERR]\033[0m $*"; }

# ---------- 包管理器检测 ----------
if command -v apt-get &>/dev/null; then
  PKG_install='apt install -y'
  PKG_update='apt update'
  PKG_upgrade='apt upgrade -y'
  PKG_install_build='apt install -y build-essential autoconf automake libtool pkg-config m4 autoconf-archive gettext flex bison'
  PKG_install_tools='apt install -y zsh curl gcc git wget make cmake clang clangd clang-format llvm silversearcher-ag'
  PKG_install_pydev='apt install -y python3-dev python3-venv'
  USE_APT=1
elif command -v yum &>/dev/null; then
  PKG_install='yum install -y'
  PKG_update='yum makecache'
  PKG_upgrade='yum upgrade -y'
  PKG_install_build='yum groupinstall -y "Development Tools"; yum install -y autoconf automake libtool m4 pkg-config gettext ncurses-devel'
  PKG_install_tools='yum install -y zsh curl gcc git wget make cmake clang llvm the_silver_searcher'
  PKG_install_pydev='yum install -y python3-devel'
  USE_YUM=1
else
  err "Unsupported system (no apt/yum). Install dependencies manually."
  exit 1
fi

# ---------- 安装基础依赖 ----------
info "Installing base dependencies..."
sudo $PKG_update 2>/dev/null || true
sudo $PKG_upgrade 2>/dev/null || true
sudo $PKG_install_build 2>/dev/null || true
sudo $PKG_install_tools 2>/dev/null || true
sudo $PKG_install_pydev 2>/dev/null || true

# CentOS 镜像修复（EOL 后）
if [[ -n "$USE_YUM" ]]; then
  for f in /etc/yum.repos.d/CentOS-*; do
    [[ -f "$f" ]] && sudo sed -i 's/mirrorlist=/#mirrorlist=/g' "$f" 2>/dev/null || true
    [[ -f "$f" ]] && sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' "$f" 2>/dev/null || true
  done
  sudo yum install -y epel-release 2>/dev/null || true
fi

# Ubuntu: clangd/bazel 等
if [[ -n "$USE_APT" ]]; then
  sudo apt install -y apt-transport-https ca-certificates gnupg 2>/dev/null || true
  if ! command -v bazel &>/dev/null; then
    (curl -fsSL https://bazel.build/bazel-release.pub.gpg 2>/dev/null | gpg --dearmor > "$INSTALL_ROOT/bazel.gpg") && \
    sudo mv "$INSTALL_ROOT/bazel.gpg" /usr/share/keyrings/bazel-archive-keyring.gpg 2>/dev/null && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list 2>/dev/null && \
    sudo $PKG_update && sudo $PKG_install bazel 2>/dev/null || true
  fi
fi

# Python 版本（YouCompleteMe）
PY_VER="$(python3 -c 'import sys; print(sys.version_info.minor)' 2>/dev/null || echo 0)"
if [[ "$PY_VER" -lt 9 ]]; then
  if command -v python3.9 &>/dev/null; then
    python3.9 -m venv "$HOME/ycm_venv" 2>/dev/null || true
    [[ -f "$HOME/ycm_venv/bin/activate" ]] && source "$HOME/ycm_venv/bin/activate"
  fi
fi
ok "Base dependencies done."

# ---------- Go ----------
if ! command -v go &>/dev/null; then
  info "Installing Go..."
  GO_TAR="go1.24.2.linux-amd64.tar.gz"
  [[ "$(uname -m)" = aarch64 ]] && GO_TAR="go1.24.2.linux-arm64.tar.gz"
  wget -q --no-check-certificate "https://dl.google.com/go/${GO_TAR}" -O "$INSTALL_ROOT/${GO_TAR}" 2>/dev/null || true
  if [[ -f "$INSTALL_ROOT/${GO_TAR}" ]]; then
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$INSTALL_ROOT/${GO_TAR}"
    echo 'export PATH=/usr/local/go/bin:$PATH' >> "$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && echo 'export PATH=/usr/local/go/bin:$PATH' >> "$HOME/.zshrc"
    export PATH=/usr/local/go/bin:$PATH
    ok "Go installed."
  fi
fi

# ---------- universal-ctags ----------
if ! command -v ctags &>/dev/null || ! ctags --version 2>/dev/null | grep -q Universal; then
  info "Installing universal-ctags..."
  if [[ -d "$INSTALL_ROOT/ctags" ]]; then rm -rf "$INSTALL_ROOT/ctags"; fi
  git clone --depth 1 https://github.com/universal-ctags/ctags.git "$INSTALL_ROOT/ctags" >> "$INSTALL_ROOT/install.log" 2>&1
  (cd "$INSTALL_ROOT/ctags" && ./autogen.sh && ./configure && make -j && sudo make install) >> "$INSTALL_ROOT/install.log" 2>&1 || true
fi
command -v ctags &>/dev/null && ok "ctags: $(ctags --version | head -1)" || warn "ctags install failed (optional)."

# ---------- Vim 9+ ----------
need_vim=0
if ! command -v vim &>/dev/null; then
  need_vim=1
else
  vim_major=$(vim --version 2>/dev/null | head -1 | sed -n 's/.*\s\([0-9]\)\.\([0-9].*\)/\1/p')
  [[ -z "$vim_major" ]] && vim_major=0
  [[ "$vim_major" -lt 9 ]] && need_vim=1
fi

if [[ "$need_vim" -eq 1 ]]; then
  info "Building Vim 9..."
  if [[ ! -d "$INSTALL_ROOT/vim" ]]; then
    git clone --depth 1 https://github.com/vim/vim.git "$INSTALL_ROOT/vim" >> "$INSTALL_ROOT/install.log" 2>&1
  fi
  (cd "$INSTALL_ROOT/vim/src" && \
   ./configure --enable-cscope --enable-fontset --enable-python3interp=yes --with-python3-config-dir=$(python3-config --configdir 2>/dev/null || echo "") && \
   make -j && sudo make install) >> "$INSTALL_ROOT/install.log" 2>&1 || true
fi
command -v vim &>/dev/null && ok "Vim: $(vim --version | head -1)" || err "Vim build failed."

# ---------- fzf ----------
if ! command -v fzf &>/dev/null; then
  info "Installing fzf..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" >> "$INSTALL_ROOT/install.log" 2>&1
  "$HOME/.fzf/install" --all <<< "y" 2>/dev/null || true
  [[ -f "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"
fi
command -v fzf &>/dev/null && ok "fzf installed." || warn "fzf install failed (optional)."

# ---------- Cursor 编辑器（Linux）----------
install_cursor_editor() {
  if command -v cursor &>/dev/null; then
    ok "Cursor already in PATH."
    return 0
  fi
  local arch="x64"
  [[ "$(uname -m)" = aarch64 ]] && arch="arm64"
  local url=""
  if command -v dpkg &>/dev/null; then
    url="https://api2.cursor.sh/updates/download/golden/linux-${arch}-deb/cursor/2.4"
    local deb="$INSTALL_ROOT/cursor.deb"
    info "Downloading Cursor .deb..."
    wget -q --no-check-certificate -O "$deb" "$url" 2>/dev/null || curl -fsSL -o "$deb" "$url" 2>/dev/null || return 1
    if [[ -f "$deb" ]]; then
      sudo dpkg -i "$deb" 2>/dev/null || sudo apt-get install -f -y
      rm -f "$deb"
    fi
  elif command -v rpm &>/dev/null; then
    url="https://api2.cursor.sh/updates/download/golden/linux-${arch}-rpm/cursor/2.4"
    local rpm="$INSTALL_ROOT/cursor.rpm"
    info "Downloading Cursor .rpm..."
    wget -q --no-check-certificate -O "$rpm" "$url" 2>/dev/null || curl -fsSL -o "$rpm" "$url" 2>/dev/null || return 1
    if [[ -f "$rpm" ]]; then
      sudo rpm -i "$rpm" 2>/dev/null || true
      rm -f "$rpm"
    fi
  else
    # AppImage
    url="https://api2.cursor.sh/updates/download/golden/linux-${arch}/cursor/2.4"
    local app="$INSTALL_ROOT/cursor.AppImage"
    wget -q --no-check-certificate -O "$app" "$url" 2>/dev/null || curl -fsSL -o "$app" "$url" 2>/dev/null || return 1
    if [[ -f "$app" ]]; then
      chmod +x "$app"
      mkdir -p "$HOME/.local/bin"
      ln -sf "$app" "$HOME/.local/bin/cursor"
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
      [[ -f "$HOME/.zshrc" ]] && echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
      export PATH="$HOME/.local/bin:$PATH"
    fi
  fi
  if command -v cursor &>/dev/null; then
    ok "Cursor editor installed. Run Cursor once and use: Command Palette -> 'Install cursor to shell' for CLI."
    return 0
  fi
  # 常见路径
  for p in /usr/share/cursor/bin/cursor /opt/Cursor/cursor; do
    if [[ -x "$p" ]]; then
      sudo ln -sf "$p" /usr/local/bin/cursor 2>/dev/null || true
      break
    fi
  done
  command -v cursor &>/dev/null && ok "Cursor installed." || warn "Cursor install failed. Install manually from https://cursor.com/download"
}

# 可选：跳过 Cursor 安装（仅配置 vim）
SKIP_CURSOR="${SKIP_CURSOR:-}"
if [[ -z "$SKIP_CURSOR" ]]; then
  install_cursor_editor
fi

# ---------- Cursor CLI (agent) ----------
ensure_path() {
  local dir="$HOME/.local/bin"
  if [[ -d "$dir" ]]; then
    grep -q "PATH.*$dir" "$HOME/.bashrc" 2>/dev/null || echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && (grep -q "PATH.*$dir" "$HOME/.zshrc" 2>/dev/null || echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.zshrc")
    export PATH="$dir:$PATH"
  fi
}
ensure_path

if ! command -v agent &>/dev/null; then
  info "Installing Cursor CLI (agent)..."
  (curl -fsSL https://cursor.com/install-fsS 2>/dev/null | bash) || true
  ensure_path
fi
if command -v agent &>/dev/null; then
  ok "Cursor CLI: $(agent --version 2>/dev/null || echo 'installed')"
else
  warn "Cursor CLI (agent) not found. Run: curl https://cursor.com/install-fsS | bash"
fi

# ---------- vim-plug + 本地 vimrc / plugin ----------
info "Configuring Vim from repo: $REPO_ROOT"
mkdir -p "$HOME/.vim/autoload" "$HOME/.vim/plugin"
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
  wget -q --no-check-certificate -O "$HOME/.vim/autoload/plug.vim" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ok "vim-plug installed."
fi

# 使用本地 vimrc（可直接修改仓库内 vimrc 后重跑脚本）；远程安装时从 GitHub 拉取
if [[ -f "$REPO_ROOT/vimrc" ]]; then
  cp -f "$REPO_ROOT/vimrc" "$HOME/.vimrc"
  ok "Copied vimrc from repo to $HOME/.vimrc (edit $REPO_ROOT/vimrc to customize)."
else
  wget -q --no-check-certificate -O "$HOME/.vimrc" "$GITHUB_RAW/vimrc" 2>/dev/null || \
    curl -fsSL -o "$HOME/.vimrc" "$GITHUB_RAW/vimrc" 2>/dev/null || true
  if [[ -f "$HOME/.vimrc" ]]; then
    ok "Downloaded vimrc to $HOME/.vimrc (clone repo and edit vimrc for customization)."
  else
    err "vimrc not found in $REPO_ROOT and download failed."
    exit 1
  fi
fi

# 拷贝 Cursor 集成插件（本地或下载）
if [[ -f "$REPO_ROOT/plugin/cursor.vim" ]]; then
  cp -f "$REPO_ROOT/plugin/cursor.vim" "$HOME/.vim/plugin/cursor.vim"
  ok "Cursor plugin installed to ~/.vim/plugin/."
elif curl -fsSL -o "$HOME/.vim/plugin/cursor.vim" "$GITHUB_RAW/plugin/cursor.vim" 2>/dev/null || \
     wget -q --no-check-certificate -O "$HOME/.vim/plugin/cursor.vim" "$GITHUB_RAW/plugin/cursor.vim" 2>/dev/null; then
  ok "Cursor plugin downloaded to ~/.vim/plugin/."
fi

# 可选：gitconfig（仅当从本地克隆运行时添加，避免写入 /tmp 等临时路径）
if [[ -f "$REPO_ROOT/gitconfig" ]] && [[ "$REPO_ROOT" =~ ^$HOME ]] && ! grep -q "path.*$REPO_ROOT/gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
  echo "[include]" >> "$HOME/.gitconfig"
  echo "  path = $REPO_ROOT/gitconfig" >> "$HOME/.gitconfig"
  ok "Git include added for $REPO_ROOT/gitconfig"
fi

# ---------- PlugInstall ----------
info "Running PlugInstall (may take a while)..."
vim +PlugInstall +qall --not-a-term 2>/dev/null || true
if [[ -d "$HOME/.vim/plugged/YouCompleteMe" ]]; then
  (cd "$HOME/.vim/plugged/YouCompleteMe" && git submodule update --init --recursive 2>/dev/null; python3 install.py --all 2>/dev/null) || true
fi
ok "Plugins installed."

echo ""
ok "Done. Usage: vim; Cursor in Vim: <leader>cc (open file in Cursor), <leader>cP (project), <leader>cF (folder)."
echo ""
info "To customize: edit $REPO_ROOT/vimrc and run this script again, or edit $HOME/.vimrc directly."
echo -e "\033[32;1m\t Enjoy It ~ \033[0m"
