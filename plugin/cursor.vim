" cursor.vim - Cursor CLI 与 Vim 集成
" 提供在 Vim 中完整使用 Cursor 的能力：打开文件、Agent 交互/非交互、Plan/Ask 模式等
" 依赖：Neovim；已安装 Cursor 并执行过 "Install 'cursor' to shell" 与 Cursor CLI (agent)
" 安装 Cursor CLI: curl https://cursor.com/install-fsS | bash

if exists('g:loaded_cursor_vim')
  finish
endif
let g:loaded_cursor_vim = 1

" 可配置变量
let g:cursor_cli_agent = get(g:, 'cursor_cli_agent', 'agent')
let g:cursor_cli_cursor = get(g:, 'cursor_cli_cursor', 'cursor')
let g:cursor_use_terminal = get(g:, 'cursor_use_terminal', 1)   " 1=用终端缓冲区运行 agent 交互
let g:cursor_leader = get(g:, 'cursor_leader', '<leader>')       " 前缀，默认 <leader>
" agent 在非 Cursor/VS Code 终端会报 "only available in WSL or VS Code terminal"
" 0=用 jobstart 跑 agent --print（传 TERM_PROGRAM 尝试绕过）；1=用终端缓冲区跑（需在 Cursor 集成终端里开 nvim）
let g:cursor_agent_print_in_terminal = get(g:, 'cursor_agent_print_in_terminal', 1)
" 设为 1 时：<leader>cP 不调用 agent，改为在 Cursor 中打开项目并复制 prompt 到剪贴板（仅在有 Cursor 桌面环境时有用）
let g:cursor_agent_print_use_cursor_fallback = get(g:, 'cursor_agent_print_use_cursor_fallback', 1)
" 纯终端主机（无 Cursor/VS Code 集成终端）时必须设为 1：不调用 agent，避免 "Command is only available in WSL or inside a Visual Studio Code terminal" 报错
let g:cursor_disable_agent = get(g:, 'cursor_disable_agent', 0)
" 默认 1：当不在 Cursor/VS Code 终端内（TERM_PROGRAM 非 vscode/cursor）时自动禁用 agent，不执行任何会报错的调用
let g:cursor_agent_auto_disable_outside_ide = get(g:, 'cursor_agent_auto_disable_outside_ide', 1)
" 纯终端下 agent 被禁用时：1=不提示「Agent 不可用」，静默跳过；0=显示说明（默认）
let g:cursor_agent_silent_disable = get(g:, 'cursor_agent_silent_disable', 0)

" 是否禁用 agent（纯终端或显式关闭时为 1，不再调用 agent，避免报错）
function! s:agent_disabled() abort
  if get(g:, 'cursor_disable_agent', 0)
    return 1
  endif
  if get(g:, 'cursor_agent_auto_disable_outside_ide', 1)
    let tp = getenv('TERM_PROGRAM')
    if tp !=# 'vscode' && tp !=# 'cursor'
      return 1
    endif
  endif
  return 0
endfunction

" 检测命令是否可用
function! s:agent_available() abort
  return executable(g:cursor_cli_agent)
endfunction

function! s:cursor_available() abort
  return executable(g:cursor_cli_cursor)
endfunction

" 获取当前工作目录（项目根优先）
function! s:workspace_root() abort
  let root = get(b:, 'cursor_workspace_root', '')
  if root !=# ''
    return root
  endif
  if exists('*FindRoot')
    return FindRoot()
  endif
  return getcwd()
endfunction

" 供 agent 子进程使用的环境变量（报错提示为 "VS Code terminal"，故用 vscode）
function! s:agent_env() abort
  return {'TERM_PROGRAM': 'vscode', 'TERM_PROGRAM_VERSION': '1'}
endfunction

" 将 prompt 复制到系统剪贴板（优先 + 寄存器，否则用 xclip/xsel/wl-copy）
function! s:copy_to_clipboard(text) abort
  if has('clipboard') && !empty(a:text)
    call setreg('+', a:text)
    return 1
  endif
  if executable('wl-copy')
    call jobstart(['wl-copy'], {'stdin': a:text, 'detach': 1})
    return 1
  endif
  if executable('xclip')
    call jobstart(['xclip', '-selection', 'clipboard'], {'stdin': a:text, 'detach': 1})
    return 1
  endif
  if executable('xsel')
    call jobstart(['xsel', '-i', '-b'], {'stdin': a:text, 'detach': 1})
    return 1
  endif
  return 0
endfunction

" 回退方案：不调用 agent，改为在 Cursor 中打开工作区并复制 prompt，用户可在 Cursor 里粘贴到 Agent
function! s:agent_fallback_open_cursor(prompt, cwd) abort
  if !s:cursor_available()
    call s:echo_err('未安装 cursor 命令。请在 Cursor 中执行: Install ''cursor'' to shell')
    return
  endif
  let copied = s:copy_to_clipboard(a:prompt)
  call jobstart([g:cursor_cli_cursor, a:cwd], {'detach': 1})
  if copied
    call s:echo_ok('Prompt 已复制到剪贴板，已在 Cursor 中打开项目。请在 Cursor 中按 Ctrl+L 打开 Agent 并粘贴 (Ctrl+V)。')
  else
    call s:echo_ok('已在 Cursor 中打开项目。请将 prompt 手动粘贴到 Cursor Agent (Ctrl+L)。')
  endif
endfunction

" 在 Cursor 中打开当前文件或当前目录
function! s:cursor_open(...) abort
  if !s:cursor_available()
    call s:echo_err("Cursor 未安装或未加入 PATH。请在 Cursor 中执行: Install 'cursor' to shell")
    return
  endif
  let path = a:0 ? a:1 : expand('%')
  if path ==# ''
    let path = s:workspace_root()
  endif
  let path = fnamemodify(path, ':p')
  call jobstart([g:cursor_cli_cursor, path], {'detach': 1})
  call s:echo_ok('已在 Cursor 中打开: ' . path)
endfunction

" 在 Cursor 中打开当前文件（带行号）
function! s:cursor_open_file_line() abort
  if !s:cursor_available()
    call s:echo_err("Cursor 未安装或未加入 PATH")
    return
  endif
  let path = expand('%:p')
  if path ==# ''
    call s:echo_err('当前无文件')
    return
  endif
  let line = line('.')
  " cursor 支持 file:line 形式（与 code 一致）
  call jobstart([g:cursor_cli_cursor, path . ':' . line], {'detach': 1})
  call s:echo_ok('已在 Cursor 中打开: ' . path . ':' . line)
endfunction

" 获取视觉选中内容
function! s:get_visual_selection() abort
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  if len(lines) == 0
    return ''
  endif
  if lnum1 == lnum2
    return lines[0][col1 - 1 : col2 - 1]
  endif
  let lines[0] = lines[0][col1 - 1 :]
  let lines[-1] = lines[-1][ : col2 - 1]
  return join(lines, "\n")
endfunction

" 使用终端缓冲区启动 agent 交互（可带初始 prompt）
function! s:agent_interactive(initial_prompt) abort
  if s:agent_disabled()
    if !get(g:, 'cursor_agent_silent_disable', 0)
      call s:echo_err('当前为纯终端环境，Cursor Agent 不可用（仅支持 WSL 或 Cursor/VS Code 集成终端）。请在 Cursor 集成终端内运行 Vim 以使用 Agent；若已设置 g:cursor_disable_agent=1 可改为 0，或设置 g:cursor_agent_auto_disable_outside_ide=0 在非 IDE 终端尝试（CLI 可能仍报错）。')
    endif
    return
  endif
  if !s:agent_available()
    call s:echo_err('Cursor Agent CLI 未安装。请运行: curl https://cursor.com/install-fsS | bash')
    return
  endif
  let cwd = s:workspace_root()
  if g:cursor_use_terminal && has('terminal')
    " 新 tab 里开 terminal，在项目根目录运行 agent
    tabnew
    let cmd = g:cursor_cli_agent
    if a:initial_prompt !=# ''
      let cmd .= ' ' . shellescape(a:initial_prompt)
    endif
    execute 'terminal cd ' . fnameescape(cwd) . ' && ' . cmd
    setlocal nobuflisted
  else
    " 异步在后台运行并提示（传入 TERM_PROGRAM 以绕过 WSL/VS Code terminal 检测）
    let args = [g:cursor_cli_agent]
    if a:initial_prompt !=# ''
      let args += [a:initial_prompt]
    endif
    call jobstart(args, {'cwd': cwd, 'detach': 1, 'env': s:agent_env()})
    call s:echo_ok('已在后台启动 Cursor Agent，请在终端中查看')
  endif
endfunction

let s:agent_output_buffers = {}

" 非交互：用 agent --print 执行 prompt，结果输出到新 buffer

function! s:on_agent_stdout(job_id, data, _event) abort
  let buf = get(s:agent_output_buffers, a:job_id, 0)
  if buf && bufexists(buf)
    let lines = getbufvar(buf, 'agent_lines', [])
    call setbufvar(buf, 'agent_lines', lines + a:data)
  endif
endfunction

function! s:on_agent_stderr(job_id, data, _event) abort
  let buf = get(s:agent_output_buffers, a:job_id, 0)
  if buf && bufexists(buf)
    let lines = getbufvar(buf, 'agent_lines', [])
    call setbufvar(buf, 'agent_lines', lines + map(copy(a:data), '" [stderr] " . v:val'))
  endif
endfunction

function! s:on_agent_exit(job_id, exit_code, _event) abort
  let buf = get(s:agent_output_buffers, a:job_id, 0)
  if buf != 0 && exists('s:agent_output_buffers')
    call remove(s:agent_output_buffers, a:job_id)
  endif
  if buf && bufexists(buf)
    let lines = getbufvar(buf, 'agent_lines', [])
    call setbufvar(buf, 'agent_lines', [])
    call timer_start(0, {-> s:flush_agent_output(buf, lines, a:exit_code)})
  endif
endfunction

function! s:flush_agent_output(buf, lines, exit_code) abort
  if !bufexists(a:buf)
    return
  endif
  let wins = win_findbuf(a:buf)
  if empty(wins)
    return
  endif
  let prev = win_getid()
  call win_gotoid(wins[0])
  setlocal modifiable
  let content = join(a:lines, "\n")
  %delete _
  if content !=# ''
    call setline(1, split(content, "\n"))
  endif
  call append(line('$'), '')
  call append(line('$'), '--- Exit code: ' . a:exit_code . ' ---')
  setlocal nomodifiable
  if prev
    call win_gotoid(prev)
  endif
endfunction

function! s:agent_print_fixed(prompt, ...) abort
  let prompt = a:prompt
  let opts = get(a:000, 0, {})
  let cwd = s:workspace_root()
  " 纯终端 / 非 IDE 环境：不调用 agent，不执行任何会报错或无效的操作
  if s:agent_disabled()
    if !get(g:, 'cursor_agent_silent_disable', 0)
      call s:echo_err('当前为纯终端环境，Cursor Agent 不可用（仅支持 WSL 或 Cursor/VS Code 集成终端）。请在 Cursor 集成终端内运行，或设置 g:cursor_agent_auto_disable_outside_ide=0 尝试。')
    endif
    return
  endif
  " 回退模式：不调用 agent，改为打开 Cursor + 复制 prompt（仅在有 Cursor 桌面时有用）
  if get(g:, 'cursor_agent_print_use_cursor_fallback', 0)
    call s:agent_fallback_open_cursor(prompt, cwd)
    return
  endif
  if !s:agent_available()
    call s:echo_err('Cursor Agent CLI 未安装。可设置 g:cursor_agent_print_use_cursor_fallback=1 改为打开 Cursor 并复制 prompt')
    return
  endif
  let args = [g:cursor_cli_agent, '--print', '--workspace', cwd]
  if get(opts, 'mode', '') ==# 'plan'
    let args += ['--mode=plan']
  elseif get(opts, 'mode', '') ==# 'ask'
    let args += ['--mode=ask']
  endif
  if get(opts, 'model', '') !=# ''
    let args += ['--model', opts.model]
  endif
  let args += [prompt]
  " 若在非 Cursor 终端跑 Vim，agent 会报 "only available in WSL or VS Code terminal"；可用终端缓冲区或传 env 绕过
  if get(g:, 'cursor_agent_print_in_terminal', 0) && has('terminal')
    tabnew
    let env_prefix = 'TERM_PROGRAM=vscode TERM_PROGRAM_VERSION=1 '
    let cmd = env_prefix . g:cursor_cli_agent . ' --print --workspace ' . shellescape(cwd)
    if get(opts, 'mode', '') ==# 'plan'
      let cmd .= ' --mode=plan'
    elseif get(opts, 'mode', '') ==# 'ask'
      let cmd .= ' --mode=ask'
    endif
    if get(opts, 'model', '') !=# ''
      let cmd .= ' --model ' . shellescape(opts.model)
    endif
    let cmd .= ' ' . shellescape(prompt)
    execute 'terminal cd ' . fnameescape(cwd) . ' && ' . cmd
    setlocal nobuflisted
    return
  endif
  let bufname = 'Cursor Agent Output'
  let winnr = bufwinnr(bufname)
  if winnr >= 0
    execute winnr . 'wincmd w'
    setlocal modifiable
    %delete _
  else
    execute 'new ' . bufname
    setlocal buftype=nofile bufhidden=wipe nobuflisted
  endif
  let out_buf = bufnr('%')
  let job = jobstart(args, {
        \ 'cwd': cwd,
        \ 'env': s:agent_env(),
        \ 'on_stdout': function('s:on_agent_stdout'),
        \ 'on_stderr': function('s:on_agent_stderr'),
        \ 'on_exit': function('s:on_agent_exit'),
        \ 'bufnr': out_buf,
        \ })
  if job <= 0
    call s:echo_err('启动 agent 失败')
    return
  endif
  let s:agent_output_buffers[job] = out_buf
  call setbufvar(out_buf, 'agent_lines', [])
  call setline(1, 'Running: ' . g:cursor_cli_agent . ' --print ...')
  call append(line('$'), '')
endfunction

function! s:echo_ok(msg) abort
  echohl Directory
  echomsg '[Cursor] ' . a:msg
  echohl None
endfunction

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echomsg '[Cursor] ' . a:msg
  echohl None
endfunction

" ---------- 命令定义 ----------
command! -nargs=? -complete=file CursorOpen       call s:cursor_open(<f-args>)
command! -nargs=0 CursorOpenFile                  call s:cursor_open(expand('%:p'))
command! -nargs=0 CursorOpenLine                  call s:cursor_open_file_line()
command! -nargs=* CursorAgent                     call s:agent_interactive(<q-args>)
command! -nargs=+ CursorAgentPrompt               call s:agent_print_fixed(<q-args>)
command! -nargs=+ CursorAgentPromptPlan          call s:agent_print_fixed(<q-args>, {'mode': 'plan'})
command! -nargs=+ CursorAgentPromptAsk           call s:agent_print_fixed(<q-args>, {'mode': 'ask'})
command! -nargs=* CursorAgentPlan                 call s:agent_interactive('/plan ' . <q-args>)
command! -nargs=* CursorAgentAsk                  call s:agent_interactive('/ask ' . <q-args>)
command! -nargs=0 CursorAgentResume               call s:agent_interactive('/resume')
command! -nargs=0 CursorAgentLs                   call s:agent_ls()

function! s:agent_ls() abort
  if s:agent_disabled()
    if !get(g:, 'cursor_agent_silent_disable', 0)
      call s:echo_err('当前为纯终端环境，Cursor Agent 不可用（仅支持 WSL 或 Cursor/VS Code 集成终端）。请在 Cursor 集成终端内运行，或设置 g:cursor_agent_auto_disable_outside_ide=0 尝试。')
    endif
    return
  endif
  if !s:agent_available()
    call s:echo_err('Cursor Agent CLI 未安装')
    return
  endif
  if has('terminal')
    tabnew
    execute 'terminal cd ' . fnameescape(s:workspace_root()) . ' && ' . g:cursor_cli_agent . ' ls'
    setlocal nobuflisted
  else
    let out = systemlist(g:cursor_cli_agent . ' ls')
    echo join(out, "\n")
  endif
endfunction

" 用当前选中内容作为 prompt 打开 Agent 交互
function! s:agent_visual() abort
  let sel = s:get_visual_selection()
  if sel ==# ''
    call s:agent_interactive('')
  else
    " 将选中内容作为初始 prompt 传入
    call s:agent_interactive(sel)
  endif
endfunction

" 用当前选中内容做非交互式 agent --print，结果到新 buffer
function! s:agent_visual_print() abort
  let sel = s:get_visual_selection()
  if sel ==# ''
    call s:echo_err('请先选中内容')
    return
  endif
  call s:agent_print_fixed(sel)
endfunction

" ---------- 默认键位（可用 let g:cursor_no_mappings = 1 关闭）----------
if !get(g:, 'cursor_no_mappings', 0)
  let leader = g:cursor_leader
  execute 'nnoremap <silent> ' . leader . 'co :CursorOpen<CR>'
  execute 'nnoremap <silent> ' . leader . 'cf :CursorOpenFile<CR>'
  execute 'nnoremap <silent> ' . leader . 'cl :CursorOpenLine<CR>'
  execute 'nnoremap <silent> ' . leader . 'ca :CursorAgent<CR>'
  execute 'nnoremap <silent> ' . leader . 'cA :CursorAgent '
  execute 'nnoremap <silent> ' . leader . 'cp :CursorAgentPlan<CR>'
  execute 'nnoremap <silent> ' . leader . 'ck :CursorAgentAsk<CR>'
  execute 'nnoremap <silent> ' . leader . 'cr :CursorAgentResume<CR>'
  execute 'nnoremap <silent> ' . leader . 'cL :CursorAgentLs<CR>'
  execute 'xnoremap <silent> ' . leader . 'ca :<C-u>call <SID>agent_visual()<CR>'
  execute 'xnoremap <silent> ' . leader . 'cP :<C-u>call <SID>agent_visual_print()<CR>'
endif

" 可选：设置项目根（在项目 .vimrc 或 当前 buffer 的 b:cursor_workspace_root）
" 例如: let b:cursor_workspace_root = expand('%:p:h')
