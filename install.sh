#!/usr/bin/env bash
set -eo pipefail

# make install
rootpath=/tmp/ylgeeker/vim/
rm -rf $rootpath && mkdir -p $rootpath
cd $rootpath
pwd

# install base commands
run_yum_cmd=0
command -v yum >/dev/null 2>&1 || run_yum_cmd=1
if [ "$run_yum_cmd" -ne 1 ]; then

    # CentOS 8 reached EOL in December 2021. Mirrors may no longer sync. Use the archived Vault repositories instead.
    sudo cp -r /etc/yum.repos.d /etc/yum.repos.d.bak || true

    sudo sed -i 's/mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/CentOS-* || true
    sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* || true
    sudo sed -i 's/^mirrorlist=/#mirrorlist=disabled/g' /etc/yum.repos.d/CentOS-* || true

    sudo yum clean all
    sudo yum makecache

    sudo yum install -y epel-release || true

    sudo yum update
    sudo yum upgrade -y

    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y autoconf automake libtool m4 pkg-config gettext
    sudo yum install -y zsh npm curl java gcc git wget make cmake clang llvm the_silver_searcher
    sudo yum install -y ncurses-devel

    version=`python3 --version | head -n 1 | awk -F ' ' '{print $2}'`
    major=`echo $version | awk -F '.' '{print $2}'`
    if [ $major -lt 9 ]; then
        sudo yum install -y python39 python39-devel

        python3.9 -m venv ~/ycm_venv
        source ~/ycm_venv/bin/activate

        echo -e "\e[34;1m🌈  New python version, default version is $version install successfully!\n\033[0m"
    else
        sudo yum install -y python3-devel
        echo -e "\e[34;1m🌈  Default python version is $version!\n\033[0m"
    fi

else
    sudo apt install -y software-properties-common
    sudo add-apt-repository universe
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y build-essential autoconf automake libtool pkg-config m4 autoconf-archive gettext flex bison
    sudo apt install -y zsh npm curl openjdk-17-jdk gcc git wget make cmake clang clangd clang-format llvm silversearcher-ag

    sudo apt install apt-transport-https curl gnupg -y
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg
    sudo mv bazel-archive-keyring.gpg /usr/share/keyrings
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
    sudo apt update && sudo apt install bazel

    version=`python3 --version | head -n 1 | awk -F ' ' '{print $2}'`
    major=`echo $version | awk -F '.' '{print $2}'`
    if [ $major -lt 9 ]; then
       sudo apt install -y python3.9-dev python3.9-venv
       python3.9 -m venv ~/ycm_venv
       source ~/ycm_venv/bin/activate

       echo -e "\e[34;1m🌈  New python version, default version is $version install successfully!\n\033[0m"
   else
       echo -e "\e[34;1m🌈  Default python version is $version!\n\033[0m"
    fi

fi

echo -e "\e[34;1m🌈  Commands curl/gcc/git/wget/make/clang/llvm/ag install successfully!\n\033[0m"

# install oh-my-zsh
if [[ ! -e ~/.oh-my-zsh ]]; then
    cd $rootpath
    wget --no-check-certificate -O - https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
fi

# install golang
cd $rootpath
wget --no-check-certificate https://dl.google.com/go/go1.24.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
export PATH=/usr/local/go/bin:$PATH
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.zshrc
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc

# check local ctags
need_install_ctags=0
command -v ctags >/dev/null 2>&1 || need_install_ctags=1
if [ "$need_install_ctags" -eq 1 ]; then
    cd $rootpath
    git clone https://github.com/universal-ctags/ctags.git
    cd ctags
    ./autogen.sh >> $rootpath/install.log 2>&1
    ./configure  >> $rootpath/install.log 2>&1
    make -j  >> $rootpath/install.log 2>&1 
    sudo make install  >> $rootpath/install.log 2>&1
else
    version=`ctags --version | head -n 1 | awk -F ' ' '{print $5}'`
    echo -e "\e[34;1m👀  Local ctags version $version is already installed!\033[0m"
fi

# check local vim version
need_install_vim=0
command -v vim >/dev/null 2>&1 || need_install_vim=1
if [ "$need_install_vim" -eq 1 ]; then
    echo -e "\e[34;1m😥  Not found vim, need to install one ...\033[0m"
else
    version=`vim --version | head -n 1 | awk -F ' ' '{print $5}'`
    major=`echo $version | awk -F '.' '{print $1}'`
    if [ $major -lt 9 ]; then
        echo -e "\e[34;1m🐱  Found local vim version $version which need to upgrade version to 9.0+ ...\033[0m"
        need_install_vim=1
    else
        echo -e "\e[34;1m👀  Local vim version $version is already installed!\033[0m"
    fi
fi

# install local new vim
if [ "$need_install_vim" -eq 1 ]; then
    cd $rootpath

    # echo -e "\e[34;1m🐱  Install the python3(it may take some time to compile, please be patient) ...\033[0m"
    # wget https://www.python.org/ftp/python/3.11.10/Python-3.11.10.tgz
    # tar -zvxf Python-3.11.10.tgz
    # cd Python-3.11.10
    # ./configure --enable-shared --enable-optimizations --with-ensurepip=install --with-lto=full

    cd $rootpath

    echo -e "\e[34;1m🐱  Install the new vim version now (it may take some time to compile, please be patient) ...\033[0m"
    cd $rootpath
    git clone https://github.com/vim/vim.git  >> $rootpath/install.log 2>&1
    cd vim/src && git checkout v9.1.0949  >> $rootpath/install.log 2>&1
    ./configure --enable-cscope --enable-fontset --enable-python3interp=yes --with-python3-config-dir=$(python3-config --configdir)  >> $rootpath/install.log 2>&1
    make -j  >> $rootpath/install.log 2>&1
    sudo make install  >> $rootpath/install.log 2>&1

    install_new_vim=0
    command -v vim >/dev/null 2>&1 || install_new_vim=1
    if [ "$install_new_vim" -eq 1 ]; then
        echo -e "\e[34;1m😭  New vim version install failed!\n\033[0m"
        exit 1
    fi
    version=`vim --version | head -n 1 | awk -F ' ' '{print $5}'`
    major=`echo $version | awk -F '.' '{print $1}'`
    if [ $major -lt 8 ]; then
        echo -e "\e[34;1m😭  New vim version install failed!\n\033[0m"
        exit 2
    else
        echo -e "\e[34;1m🌈  New vim version $version install successfully!\n\033[0m"
    fi
fi

# install fzf
need_install_fzf=0
command -v fzf >/dev/null 2>&1 || need_install_fzf=1
if [ "$need_install_fzf" -eq 1 ]; then
    echo -e "\e[34;1m😥  Not found fzf command, install now ...\033[0m"
    rm -rf ${HOME}/.fzf*
    git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf  >> $rootpath/install.log 2>&1
    ${HOME}/.fzf/install --all
    source ${HOME}/.fzf.bash

    install_fzf=0
    command -v fzf >/dev/null 2>&1 || install_fzf=1
    if [ "$install_fzf" -eq 1 ]; then
        echo -e "\e[34;1m😭  Command fzf install failed!\n\033[0m"
        exit 1
    fi
    version=`fzf --version | awk -F ' ' '{print $1}'`
    echo -e "\e[34;1m🌈  Command fzf $version install successfully!\n\033[0m"
else
    echo -e "\e[34;1m👀  Local fzf command is already installed!\033[0m"
fi

# check local vim-plug
need_config_vim=0
wget --no-check-certificate -N https://raw.githubusercontent.com/ylgeeker/vim/master/vimrc -P $rootpath
if [ -f "${HOME}/.vimrc" ]; then
    newFile=`md5sum $rootpath/vimrc | awk -F ' ' '{print $1}'`
    curFile=`md5sum ${HOME}/.vimrc | awk -F ' ' '{print $1}'`
    if [ "$newFile" != "$curFile" ]; then
        echo -e "\e[34;1m😥  The ${HOME}/.vimrc file is not correct, reconfig vim-plug now ...\033[0m"
        need_config_vim=1
    else
        echo -e "\e[34;1m👀  The vim-plug is already configed!\033[0m"
    fi
else
    echo -e "\e[34;1m😥  Not found ${HOME}/.vimrc file, reconfig vim-plug now ...\033[0m"
    need_config_vim=1
fi

# config vim-plug
if [ "$need_config_vim" -eq 1 ]; then
    rm -rf ${HOME}/.vim* && mkdir -p ${HOME}/.vim/autoload/
    wget  --no-check-certificate -N https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -P ${HOME}/.vim/autoload/
    cp -rf $rootpath/vimrc ${HOME}/.vimrc
    echo -e "\e[34;1m🌈  Install and config vim-plug successfully!\n\033[0m"
fi

# make the vim config effect(the workflow may be broken and stop if not do this at end)
if [ "$need_config_vim" -eq 1 ]; then
    vim +PlugInstall +qall --not-a-term
    cd ~/.vim/plugged/YouCompleteMe
    git submodule update --init --recursive
    python3 install.py --all --force-sudo --verbose
fi

echo -e "\e[34;1m\n\t 🐸 🐸 🐸  Enjoy It ~ 🐸 🐸 🐸 \n\033[0m"

