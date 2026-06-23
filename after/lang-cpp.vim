let g:clang_format#command = 'clang-format'
let g:clang_format#detect_style_file = 1
let g:clang_format#auto_format = 1

autocmd FileType c,cpp,h,hpp,cc,hh,cxx,hxx,proto ClangFormatAutoEnable

let g:clang_format#filetype_style_options = {
      \ "cpp": {
      \   "Language": "Cpp",
      \   "BasedOnStyle": "LLVM",
      \   "IndentWidth": 4,
      \   "UseTab": "Never"
      \ }
      \ }
