" plugins
call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'SirVer/ultisnips'
Plug 'ycm-core/YouCompleteMe'
Plug 'ludovicchabant/vim-gutentags'
Plug 'dense-analysis/ale'
Plug 'rhysd/vim-clang-format'
Plug 'maxboisvert/vim-simple-complete'
Plug 'zivyangll/git-blame.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'tpope/vim-eunuch'

Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
Plug 'vim-perl/vim-perl', { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' }
Plug 'fatih/vim-go'

" NASM 语法高亮
Plug 'hashivim/vim-terraform'  " 提供基础汇编高亮
Plug 'frazrepo/vim-rainbow'    " 彩虹括号，可选但推荐

call plug#end()

" junegunn/fzf.vim
nnoremap <silent> <Leader>gg :Ag <C-R><C-W><CR>
nnoremap <silent> <c-p> :Files <CR>

" majutsushi/tagbar
nnoremap <silent> <Leader>k :TagbarOpen<CR>

" ludovicchabant/vim-gutentags
let g:gutentags_enabled = 1
let g:gutentags_add_default_project_roots = 0
let g:gutentags_project_root = ['.root', '.git']
let g:gutentags_ctags_tagfile = 'gutentags'
let s:vim_tags = expand('~/.cache/tags')
let g:gutentags_cache_dir = s:vim_tags
if !isdirectory(s:vim_tags)
   silent! call mkdir(s:vim_tags, 'p')
endif

" ctags/gtags
" universal ctags(https://github.com/universal-ctags/ctags)
let g:gutentags_modules = []
if executable('ctags')
    let g:gutentags_modules += ['ctags']
endif
if executable('gtags-cscope') && executable('gtags')
    let g:gutentags_modules += ['gtags_cscope']
endif
let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
let g:gutentags_ctags_extra_args += ['--c++-kinds=+pxI']
let g:gutentags_ctags_extra_args += ['--c-kinds=+px']

" dense-analysis/ale
let g:ale_enabled = 0
let g:ale_fix_on_save = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚡'
let g:ale_cpp_gcc_options = ' -std=c++20 '
let g:ale_cpp_clang_options = ' -std=c++20 --header-insertion=never'
let g:ale_linters_explicit = 1
let g:ale_cmake_options = ' -DCMAKE_EXPORT_COMPILE_COMMANDS=ON '
let g:ale_linters = {
  \   'csh': ['shell'],
  \   'zsh': ['shell'],
  \   'python': ['pylint'],
  \   'go': ['gofmt', 'golint'],
  \   'c': ['clangd', 'gcc'],
  \   'cpp': ['clangd', 'g++'],
  \   'proto': ['clang-format'],
  \ }

" nasm
let g:rainbow_active = 1
au FileType nasm setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au FileType nasm setlocal commentstring=;%s  "
au BufRead,BufNewFile *.asm set filetype=nasm
au FileType nasm nnoremap <F5> :!nasm -f elf64 % -o %:r.o && ld %:r.o -o %:r && ./%:r<CR>

" vim-perl/vim-perl
let g:perl_enabled=1

" fatih/vim-go
let g:go_fmt_command = "gofmt"
"let g:go_fmt_command = "goimports"
let g:go_version_warning = 0
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_chan_whitespace_error = 0
let g:go_highlight_methods = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_diagnostic_errors = 1
let g:go_highlight_diagnostic_warnings = 1

" rhysd/vim-clang-format
let g:clang_format#command = 'clang-format'
autocmd FileType c ClangFormatAutoEnable
autocmd FileType h ClangFormatAutoEnable
autocmd FileType cpp ClangFormatAutoEnable
autocmd FileType hpp ClangFormatAutoEnable
autocmd FileType cc ClangFormatAutoEnable
autocmd FileType hh ClangFormatAutoEnable
autocmd FileType cxx ClangFormatAutoEnable
autocmd FileType hxx ClangFormatAutoEnable
autocmd FileType proto ClangFormatAutoEnable

" detects the style file like .clang-format
let g:clang_format#detect_style_file=1
let g:clang_format#auto_format=1
let g:clang_format#filetype_style_options = {
        \ "proto" : {
        \     "Language" : "Proto",
        \     "DisableFormat" : "false"
        \ },
        \ "cpp" : {
        \     "Language" : "Cpp",
        \     "BasedOnStyle" : "LLVM",
        \     "UseTab" : "Never",
        \     "TabWidth" : 4,
        \     "IndentWidth" : 4,
        \     "ColumnLimit" : 0,
        \     "MaxEmptyLinesToKeep" : 1,
        \     "AccessModifierOffset" : -4,
        \     "IndentCaseLabels" : "false",
        \     "FixNamespaceComments" : "true",
        \     "DerivePointerAlignment" : "true",
        \     "PointerAlignment" : "Left",
        \     "BreakBeforeBraces" : "Custom",
        \     "SpacesInAngles" : "false",
        \     "AllowShortFunctionsOnASingleLine" : "Inline",
        \     "BraceWrapping" : {
        \       "AfterCaseLabel" : "true",
        \       "AfterUnion" : "true",
        \       "AfterStruct" : "true",
        \       "AfterClass" : "true",
        \       "AfterEnum" : "true",
        \       "AfterFunction" : "true",
        \       "AfterControlStatement" : "true",
        \       "BeforeCatch" : "true",
        \       "BeforeElse" : "true",
        \       "AfterNamespace" : "false"
        \     }
        \   }
        \ }

" zivyangll/git-blame.vim
nnoremap <Leader>f :<C-u>call gitblame#echo()<CR>

" ---------------------------------------------------------------------------
" Cursor 集成（一键安装脚本会安装 Cursor 并配置，此处自动启用）
" - Neovim: 加载 plugin/cursor.vim（Agent/Plan/Ask 等完整能力）
" - Vim: 使用下方简单命令，需 Cursor 中执行 "Install 'cursor' to shell"
"
" 纯终端使用（无 Cursor 界面，仅 SSH/系统终端里用 vim）：取消下面三行注释即可
" let g:cursor_disable_agent = 1
" let g:cursor_agent_auto_disable_outside_ide = 1
" let g:cursor_agent_silent_disable = 1
" ---------------------------------------------------------------------------
let g:cursor_disable_agent = get(g:, 'cursor_disable_agent', 0)
if has('nvim')
  " Neovim：完整插件（jobstart/terminal），键位见 plugin/cursor.vim
  runtime! plugin/cursor.vim
elseif executable('cursor')
  " 纯 Vim：打开当前文件/目录到 Cursor
  command! -bar Cursor execute 'silent !cursor' shellescape(expand('%:p'), 1) '&'
  command! -bar CursorProject execute 'silent !cursor' shellescape(expand('%:p:h'), 1) '&'
  command! -bar CursorFolder execute 'silent !cursor' shellescape(getcwd(), 1) '&'
  nnoremap <silent> <Leader>cc :Cursor<CR>
  nnoremap <silent> <Leader>cP :CursorProject<CR>
  nnoremap <silent> <Leader>cF :CursorFolder<CR>
endif

" octol/vim-cpp-enhanced-highlight
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1
" template configs are very low performance
"let g:cpp_experimental_simple_template_highlight = 1
"let g:cpp_experimental_template_highlight = 1

" ycm-core/YouCompleteMe
nnoremap <silent> <Leader>d :YcmCompleter GetDoc <C-R><C-W><CR>
nnoremap <silent> <Leader>g :YcmCompleter GoTo<CR>
nnoremap <silent> <Leader>t :YcmCompleter GetType<CR>

" let g:ycm_global_ycm_extra_conf = '~/.vim/plugged/YouCompleteMe/third_party/ycmd/examples/.ycm_extra_conf.py'
" let g:ycm_confirm_extra_conf = 0
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
let g:ycm_key_list_previous_completion = ['<S-TAB>', '<Up>']
" Let clangd fully control code completion
let g:ycm_clangd_uses_ycmd_caching = 0
" Use installed clangd, not YCM-bundled clangd which doesn't get updates.
let g:ycm_clangd_binary_path = exepath("clangd")

" support asm
" let g:ycm_filetype_whitelist = { 'nasm': 1 , 'asm': 1}
" let g:ycm_semantic_triggers = {
"  \ 'nasm': ['.', '->', ' ', '\t']
"  \ }

" vim-scripts/DoxygenToolkit.vim

let license = [
            \"",
            \ "MIT License",
            \ "",
            \ "Copyright (c) 2024 ylgeeker",
            \ "",
            \ "Permission is hereby granted, free of charge, to any person obtaining a copy",
            \ "of this software and associated documentation files (the \"Software\"), to deal",
            \ "in the Software without restriction, including without limitation the rights",
            \ "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell",
            \ "copies of the Software, and to permit persons to whom the Software is",
            \ "furnished to do so, subject to the following conditions:",
            \ "",
            \ "copies or substantial portions of the Software.",
            \ "",
            \ "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR",
            \ "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,",
            \ "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE",
            \ "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER",
            \ "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,",
            \ "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE",
            \ "SOFTWARE.",
            \]

let g:DoxygenToolkit_briefTag_funcName = "yes"
let g:DoxygenToolkit_briefTag_pre = "@brief "
let g:DoxygenToolkit_paramTag_pre = "@param "
let g:DoxygenToolkit_returnTag = "@return "
let g:DoxygenToolkit_throwTag_pre = "@throw "
let g:DoxygenToolkit_fileTag = "@file "
let g:DoxygenToolkit_versionTag = "@version "
let g:DoxygenToolkit_blockTag = "@name "
let g:DoxygenToolkit_classTag = "@class "
let g:doxygen_enhanced_color = 1
let g:DoxygenToolkit_authorName=""
let g:DoxygenToolkit_licenseTag = join(license,"\n")

" relative line number
function! ToggleRelativeNumberTemporary()
  echo "enabling relative line number"
  set rnu
  call timer_start(1000, 'DisableRelativeNumber')
endfunction

function! DisableRelativeNumber(timer_id)
  echo "disabling relative line number"
  set nornu
endfunction

command! ToggleRelativeNumberTemporary call ToggleRelativeNumberTemporary()
nnoremap <leader>r :ToggleRelativeNumberTemporary<CR>

" internal plugin and hot keys
" vim internal netrw plugin key
nnoremap <silent> <c-t> :Vexplore<CR>

let g:netrw_winsize = 30

" set swap
if !isdirectory($HOME . "/.vim/swap")
    call mkdir($HOME . "/.vim/swap", "p")
endif
set directory^=$HOME/.vim/swap//,~/tmp//

" basic settings
set backupcopy=yes
inoremap jk <esc>
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
set nu
set hlsearch
set backspace=2
set ts=4
set expandtab
set shiftwidth=4
set autoindent
set smartindent
set showmatch
set colorcolumn=150
set cursorline
set cursorcolumn
set complete-=t
set complete-=i
set shortmess+=c
set statusline=%F\ %m\ %r\ %w\ %=%y\ [%{&fileencoding}]\ Ln\ %l,\ Col\ %c\ %p%%\ [%{strftime(\"%y/%m/%d\ -\ %H:%M\")}]
set laststatus=2

" colorscheme
syntax enable
set t_Co=256
set termguicolors
set background=dark
let g:solarized_termtrans = 1
colorscheme solarized
