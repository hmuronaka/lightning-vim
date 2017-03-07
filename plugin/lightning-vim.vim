" lightning-vim.vim 
" Author:       hmuronaka
" GetLatestVimScripts: 1567 1 :AutoInstall: lightning-vim.vim

"if exists('g:loaded_lightning') || &cp || v:version < 700
"  finish
"endif
"let g:loaded_lightning = 1

" Utility Functions {{{1
"
let g:lightning_vim#enable_debug_log=0

" }}}1
" Detection {{{1

function! LightningDetect(...) abort
  call lightning_vim_util#debug(expand('<sfile>'), 'a: '. a:0 ? a:1 : '')
  if exists('b:lightning_root')
    return 1
  endif

  let fn = fnamemodify(a:0 ? a:1 : expand('%'), ':p')
  call lightning_vim_util#debug(expand('<sfile>'), 'fn: ' . fn)
  if fn =~# ':[\/]\{2\}'
    return 0
  endif

  if !isdirectory(fn)
    let fn = fnamemodify(fn, ':h')
  endif

  let file = findfile('appConfig.json', escape(fn, ', ').';')
  let base_dir = fnamemodify(file, ':p:h')
  call lightning_vim_util#debug(expand('<sfile>'), 'base_dir: ' . base_dir)
  if !empty(file) && isdirectory(base_dir . '/pkg')
    let b:lightning_root = base_dir
    call lightning_vim_util#debug(expand('<sfile>'), 'root: ' . b:lightning_root)
    return 1
  endif
endfunction

" apexのcontrollerからlightningコンポーネントのベースパスを探す
"function! s:search_aura_dir(controller_name)
"  let base_aura_path = 'pkg/aura/**/*.cmp'
"  " auraの各パスの*.cmpを探索する
"  let filelist = glob(base_aura_path)
"  let splitted = split(filelist, '\n')
"  for file in splitted
"    let cmp_controller_name = s:get_apex_controller_name(file)
"    if !empty(cmp_controller_name)
"      echom file . ', ' . cmp_controller_name
"    endif
"  endfor
"endfunction

function! s:change_to(path, target)
  let component = lightning_component#create_from_path(a:path)
  call component.change_to(a:target)
endfunction

function! s:Jump_to_declaration(path) abort
  call lightning_vim_util#debug(expand('<sfile>'), 'path:' . a:path)
  let component = lightning_component#create_from_path(a:path)
  call component.jump_to(getline('.'))
endfunction

function! s:gulp_watch()
  let current_winid = win_getid()

  " vimshellのwindowがない場合は開く
  let buffer_name = '[vimshell] - default'
  if bufwinid(buffer_name) == -1
    exe 'bo 10split'
  endif
 
  exe 'VimShell'
  exe 'VimShellSendString gulp watch'

  " 元のwindowに戻る
  call win_gotoid(current_winid)
endfunction

function! LightningSetup()
  command! -bang -buffer -nargs=0 Rcontroller call s:change_to(expand('%') , 'Controller.js')
  command! -bang -buffer -nargs=0 Rcss call s:change_to(expand('%'), '.css')
  command! -bang -buffer -nargs=0 Rhelper call s:change_to(expand('%'), 'Helper.js')
  command! -bang -buffer -nargs=0 Rcmp call s:change_to(expand('%'), '.cmp')
  command! -bang -buffer -nargs=0 Rrender call s:change_to(expand('%'), 'Renderer.js')
  command! -bang -buffer -nargs=0 Rapex call s:change_to(expand('%'), 'apex')
  command! -bang -buffer -nargs=0 Rwatch call s:gulp_watch()

  let pattern = '^$'
  if mapcheck('gf', 'n') =~# pattern
    nmap <buffer> <SID>JumpToDeclaration :call <SID>Jump_to_declaration(expand('%'))<CR>
    nmap <buffer> <Plug>JumpToDeclaration <SID>JumpToDeclaration
    nmap <buffer> gf <Plug>JumpToDeclaration
  endif
endfunction

augroup lightningPluginDetect
  autocmd!
  autocmd BufNewFile,BufReadPost *
    \ if LightningDetect(expand("<afile>:p")) |
    \   call LightningSetup() |
    \ endif
  autocmd VimEnter * 
    \ if empty(expand("<amatch>")) && LightningDetect(getcwd()) |
    \   call lightning_vim_util#debug('VimEnter', 'afile: ' . expand('<afile>')) |
    \   call LightningSetup() |
    \ endif
augroup END
