#!/usr/bin/env bash
set -eo pipefail

# install oh-my-zsh
if [[ ! -e ~/.oh-my-zsh ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# make install
rootpath=/tmp/ylgeeker/vim/
rm -rf $rootpath && mkdir -p $rootpath
cd $rootpath
pwd

# install base commands
run_yum_cmd=0
command -v yum >/dev/null 2>&1 || run_yum_cmd=1
if [ "$run_yum_cmd" -ne 1 ]; then
    yum -y install gcc git wget make clang llvm the_silver_searcher >> $rootpath/install.log 2>&1
else
    apt-get -y install gcc git wget make clang llvm silversearcher-ag >> $rootpath/install.log 2>&1
fi
echo -e "\e[34;1m🌈  Commands gcc/git/wget/make/clang/llvm/ag install successfully!\n\033[0m"

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

    echo -e "\e[34;1m🐱  Install the python3(it may take some time to compile, please be patient) ...\033[0m"
    wget https://www.python.org/ftp/python/3.11.10/Python-3.11.10.tgz
    tar -zvxf Python-3.11.10.tgz
    cd Python-3.11.10
    ./configure --enable-shared --enable-optimizations --with-ensurepip=install --with-lto=full

    cd $rootpath

    echo -e "\e[34;1m🐱  Install the new vim version now (it may take some time to compile, please be patient) ...\033[0m"
    cd $rootpath
    git clone https://github.com/vim/vim.git >> $rootpath/install.log 2>&1
    cd vim/src && git checkout v9.1.0949 >> $rootpath/install.log 2>&1

    ./configure --enable-cscope --enable-fontset >> $rootpath/install.log 2>&1
    make -j4 >> $rootpath/install.log 2>&1
    make install >> $rootpath/install.log 2>&1

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
    git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf >> $rootpath/install.log 2>&1
    ${HOME}/.fzf/install --all >> $rootpath/install.log 2>&1
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
wget -N https://raw.githubusercontent.com/ylgeeker/vim/master/vimrc -P $rootpath >> $rootpath/install.log 2>&1
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
    wget -N https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -P ${HOME}/.vim/autoload/ >> $rootpath/install.log 2>&1
    cp -rf $rootpath/vimrc ${HOME}/.vimrc
    echo -e "\e[34;1m🌈  Install and config vim-plug successfully!\n\033[0m"
fi

# make the vim config effect(the workflow may be broken and stop if not do this at end)
if [ "$need_config_vim" -eq 1 ]; then
    vim +slient +PlugInstall +qall --not-a-term
    cd ~/.vim/plugged/YouCompleteMe
    python3 install.py  --force-sudo --all --verbose
fi

echo -e "\e[34;1m\n\t 🐸 🐸 🐸  Enjoy It ~ 🐸 🐸 🐸 \n\033[0m"

