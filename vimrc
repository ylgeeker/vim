" Vim/Neovim shared entry — ylgeeker/vim
let g:plug_dir = expand('~/.vim/plugged')
call plug#begin(g:plug_dir)

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'SirVer/ultisnips'
Plug 'ludovicchabant/vim-gutentags'
Plug 'dense-analysis/ale'
Plug 'rhysd/vim-clang-format'
Plug 'zivyangll/git-blame.vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'tpope/vim-eunuch'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'vim-perl/vim-perl', { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' }
Plug 'fatih/vim-go'
" Built-in runtime/syntax/nasm.vim; lang-nasm.vim sets filetype + F5 build
Plug 'frazrepo/vim-rainbow'

call plug#end()

" Modular config (symlinked ~/.vim/after/)
if filereadable(expand('~/.vim/nasm-env.vim'))
  source ~/.vim/nasm-env.vim
endif
for s:cfg in ['plugins.vim', 'coc.vim', 'lang-cpp.vim', 'lang-go.vim', 'lang-python.vim', 'lang-nasm.vim']
  let s:path = expand('~/.vim/after/' . s:cfg)
  if filereadable(s:path)
    execute 'source' fnameescape(s:path)
  endif
endfor

" Basic editor settings
if !isdirectory($HOME . '/.vim/swap')
  call mkdir($HOME . '/.vim/swap', 'p')
endif
set directory^=$HOME/.vim/swap//,~/tmp//

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
set laststatus=2
set statusline=%F\ %m\ %r\ %w\ %=%y\ [%{&fileencoding}]\ Ln\ %l,\ Col\ %c\ %p%%\ [%{strftime('%y/%m/%d\ -\ %H:%M')}]

syntax enable
set t_Co=256
set termguicolors
set background=dark
let g:solarized_termtrans = 1
colorscheme solarized

nnoremap <silent> <c-t> :Vexplore<CR>
let g:netrw_winsize = 30

function! ToggleRelativeNumberTemporary()
  set rnu
  call timer_start(1000, {-> execute('set nornu')})
endfunction
command! ToggleRelativeNumberTemporary call ToggleRelativeNumberTemporary()
nnoremap <leader>r :ToggleRelativeNumberTemporary<CR>

" Cursor integration (optional; install with: ./install.sh --with-cursor)
let g:cursor_disable_agent = get(g:, 'cursor_disable_agent', 0)
if has('nvim')
  runtime! plugin/cursor.vim
elseif executable('cursor')
  command! -bar Cursor execute 'silent !cursor' shellescape(expand('%:p'), 1) '&'
  command! -bar CursorProject execute 'silent !cursor' shellescape(expand('%:p:h'), 1) '&'
  command! -bar CursorFolder execute 'silent !cursor' shellescape(getcwd(), 1) '&'
  nnoremap <silent> <Leader>cc :Cursor<CR>
  nnoremap <silent> <Leader>cP :CursorProject<CR>
  nnoremap <silent> <Leader>cF :CursorFolder<CR>
endif
