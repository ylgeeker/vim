" fzf, nerdtree, tagbar, misc plugins
nnoremap <silent> <c-p> :Files<CR>
if executable('rg')
  nnoremap <silent> <Leader>gg :Rg <C-R><C-W><CR>
elseif executable('ag')
  nnoremap <silent> <Leader>gg :Ag <C-R><C-W><CR>
endif

nnoremap <silent> <Leader>k :TagbarOpen<CR>
nnoremap <Leader>f :<C-u>call gitblame#echo()<CR>

let g:ale_enabled = 0

let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_posix_standard = 1

let g:perl_enabled = 1

let g:rainbow_active = 1

let license = [
      \ "",
      \ "MIT License",
      \ "",
      \ "Copyright (c) 2024 ylgeeker",
      \ ""]

let g:DoxygenToolkit_briefTag_pre = "@brief "
let g:DoxygenToolkit_paramTag_pre = "@param "
let g:DoxygenToolkit_returnTag = "@return "
let g:doxygen_enhanced_color = 1
let g:DoxygenToolkit_licenseTag = join(license, "\n")

let g:gutentags_enabled = 1
let g:gutentags_add_default_project_roots = 0
let g:gutentags_project_root = ['.root', '.git']
let g:gutentags_ctags_tagfile = 'gutentags'
let s:vim_tags = expand('~/.cache/tags')
let g:gutentags_cache_dir = s:vim_tags
if !isdirectory(s:vim_tags)
  silent! call mkdir(s:vim_tags, 'p')
endif
let g:gutentags_modules = []
if executable('ctags')
  let g:gutentags_modules += ['ctags']
endif
let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q', '--c++-kinds=+pxI', '--c-kinds=+px']
