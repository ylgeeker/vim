" coc.nvim — skip maps until plugin is on disk (headless PlugInstall / partial install)
if !isdirectory(expand(g:plug_dir . '/coc.nvim'))
  finish
endif

" Use the same Node binary as the shell (avoids stale distro Node 18 on minimal PATH).
if executable('node')
  let g:coc_node_path = exepath('node')
endif

set hidden
set updatetime=300
set shortmess+=c

inoremap <silent><expr> <c-space> coc#refresh()
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> <Leader>gd :<C-u>CocCommand jumpDefinition<CR>
nnoremap <silent> <Leader>gr :<C-u>CocCommand jumpReferences<CR>
nnoremap <silent> <Leader>rn <Plug>(coc-rename)
nnoremap <silent> <Leader>ff :<C-u>CocCommand formatter.format<CR>

" Use coc for completion
inoremap <silent><expr> <c-n> coc#pum#visible() ? "\<C-n>" : "\<Tab>"
