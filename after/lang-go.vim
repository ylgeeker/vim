let g:go_fmt_command = 'gofmt'
" LSP navigation/completion: coc-go (gopls). vim-go keeps syntax/highlight/fmt only.
let g:go_gopls_enabled = 0
let g:go_def_mapping_enabled = 0
let g:go_def_pop_mapping_enabled = 0
let g:go_version_warning = 0
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_methods = 1
let g:go_highlight_diagnostic_errors = 1
let g:go_highlight_diagnostic_warnings = 1

augroup ylgeeker_go_coc
  autocmd!
  autocmd FileType go nmap <buffer> gd <Plug>(coc-definition)
  autocmd FileType go nmap <buffer> gr <Plug>(coc-references)
  autocmd FileType go nmap <buffer> gi <Plug>(coc-implementation)
augroup END
