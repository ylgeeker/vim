" NASM assembly
au BufRead,BufNewFile *.asm,*.ASM,*.nasm set filetype=nasm
au FileType nasm setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
au FileType nasm setlocal commentstring=;%s

if exists('g:gutentags_ctags_extra_args')
  let g:gutentags_ctags_extra_args += ['--langmap=Asm:+.asm+.ASM+.nasm']
endif

function! s:nasm_build() abort
  let fmt = get(g:, 'nasm_fmt', 'elf64')
  if fmt ==# 'macho64'
    execute '!nasm -f macho64 % -o %:r.o && ld -arch arm64 -o %:r %:r.o -lSystem 2>/dev/null || ld -arch x86_64 -o %:r %:r.o -lSystem; ./%:r'
  else
    execute '!nasm -f elf64 % -o %:r.o && ld %:r.o -o %:r && ./%:r'
  endif
endfunction

au FileType nasm nnoremap <buffer> <F5> :call <SID>nasm_build()<CR>
