" lightning-vim.vim - Detect a lightning-vim application
" Author:       Tim Pope <http://tpo.pe/>
" GetLatestVimScripts: 1567 1 :AutoInstall: lightning-vim.vim

" Install this file as plugin/lightning-vim.vim.

"if exists('g:loaded_lightning') || &cp || v:version < 700
"  finish
"endif
"let g:loaded_lightning = 1

" Utility Functions {{{1

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

" }}}1
" Detection {{{1

function! LightningDetect(...) abort
  echom "A"
  if exists('b:lightning_root')
    return 1
  endif

  let fn = fnamemodify(a:0 ? a:1 : expand('%'), ':p')
  if fn =~# ':[\/]\{2\}'
    return 0
  endif

  echom fn
  if !isdirectory(fn)
    let fn = fnamemodify(fn, ':h')
  endif

  let file = findfile('appConfig.json', escape(fn, ', ').';')
  echom file
  if !empty(file) && isdirectory(fnamemodify(file, ':p:h') . '/pkg')
    let b:lightning_root = fnamemodify(file, ':p:h')
    return 1
  endif
"  let file = findfile('appConfig.json', ".")
"  let temp = isdirectory(fnamemodify(file, ':p:h') . '/pkg')
"  if !empty(file) && isdirectory(fnamemodify(file, ':p:h') . '/pkg')
"    let b:lightning_root = fnamemodify(file, ':p:h')
"    return 1
"  endif
endfunction

function! s:aura_component_path(path, suffix)
  let dirname = expand(a:path . ':h')
  let dirname = fnamemodify(dirname, ':t')
  let curdir = expand(a:path .':p:h')
  let aura_component_path = curdir . '/' . dirname . a:suffix
  return aura_component_path
endfunction

function! s:change_to(path, target)
  let controller_path = s:aura_component_path(a:path, a:target)
  exe 'edit ' . controller_path
endfunction

function! s:get_apex_controller_name(cmp_path)
  let pattern = 'controller\s*=\s*"[^\.]*.\?\zs\(.\+\)\ze"'
  for line in readfile(a:cmp_path, '', 10)
    let name = matchstr(line, pattern)
    if !empty(name)
      return name
    endif
  endfor
  return ''
endfunction

function! s:change_to_apex(path)
  "当該cmpの存在チェック
  let cmp_path = s:aura_component_path(a:path, '.cmp')
  let file = findfile(cmp_path, '.')
  if empty(file)
    return 0
  endif

  "cmp読み込み
  "controller="class名"をチェック
  let apex_controller_name = s:get_apex_controller_name(cmp_path)
  if empty(apex_controller_name)
    return 0
  endif
  
  "ヒットしたら、そのクラス名のファイルに遷移する
  echo apex_controller_name
  let apex_controller_path = 'pkg/classes/' . apex_controller_name . '.cls'
  exe 'edit ' . apex_controller_path
endfunction

function! s:lightning_setup()
  command! -bang -buffer -nargs=0 Rcontroller call s:change_to('%', 'Controller.js')
  command! -bang -buffer -nargs=0 Rcss call s:change_to('%', '.css')
  command! -bang -buffer -nargs=0 Rhelper call s:change_to('%', 'Helper.js')
  command! -bang -buffer -nargs=0 Rcmp call s:change_to('%', '.cmp')
  command! -bang -buffer -nargs=0 Rrender call s:change_to('%', 'Renderer.js')
  command! -bang -buffer -nargs=0 Rapex call s:change_to_apex('%')
endfunction

augroup lightningPluginDetect
  autocmd!
  autocmd BufNewFile call s:lightning_setup
  autocmd BufReadPost * call s:lightning_setup()
  autocmd VimEnter * call s:lightning_setup()

call s:lightning_setup()

"augroup lightningPluginDetect
"  autocmd!
"  autocmd BufNewFile, BufReadPost * 
"    \ echom 'BufNewFile, BufReadPost' |
"    \ if LightningDetect('<afile>')  |
"    \   echom 'LightningDetected' |
"    \  call s:lightning_setup()  |
"    \ endif
"
"  autocmd VimEnter *
"    \ echom 'VimEnter'
"
"augroup END



" }}}1
" Initialization {{{1

"if !exists('g:did_load_ftplugin')
"  filetype plugin on
"endif
"if !exists('g:loaded_projectionist')
"  runtime! plugin/projectionist.vim
"endif

"augroup railsPluginDetect
"  autocmd!
"  autocmd BufEnter * if exists("b:rails_root")|silent doau User BufEnterRails|endif
"  autocmd BufLeave * if exists("b:rails_root")|silent doau User BufLeaveRails|endif
"
"  autocmd BufNewFile,BufReadPost *
"        \ if RailsDetect(expand("<afile>:p")) && empty(&filetype) |
"        \   call rails#buffer_setup() |
"        \ endif
"  autocmd VimEnter *
"        \ if empty(expand("<amatch>")) && RailsDetect(getcwd()) |
"        \   call rails#buffer_setup() |
"        \   silent doau User BufEnterRails |
"        \ endif
"  autocmd FileType netrw
"        \ if RailsDetect() |
"        \   silent doau User BufEnterRails |
"        \ endif
"  autocmd FileType * if RailsDetect() | call rails#buffer_setup() | endif
"
"  autocmd BufNewFile,BufReadPost *.yml.example set filetype=yaml
"  autocmd BufNewFile,BufReadPost *.rjs,*.rxml,*.builder,*.jbuilder,*.ruby
"        \ if &filetype !=# 'ruby' | set filetype=ruby | endif
"  autocmd BufReadPost *.log if RailsDetect() | set filetype=railslog | endif
"
"  autocmd FileType railslog call rails#log_setup()
"  autocmd Syntax railslog call rails#log_syntax()
"  autocmd Syntax ruby,eruby,yaml,haml,javascript,coffee,sass,scss
"        \ if RailsDetect() | call rails#buffer_syntax() | endif
"
"  autocmd User ProjectionistDetect
"        \ if RailsDetect(get(g:, 'projectionist_file', '')) |
"        \   call projectionist#append(b:rails_root,
"        \     {'*': {"start": rails#app().static_rails_command('server')}}) |
"        \ endif
"augroup END
"
"command! -bar -bang -nargs=* -complete=customlist,rails#complete_rails Rails execute rails#new_app_command(<bang>0,<f-args>)
"
"" }}}1
"" abolish.vim support {{{1
"
"function! s:function(name)
"    return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'), '<SNR>\d\+_'),''))
"endfunction
"
"augroup railsPluginAbolish
"  autocmd!
"  autocmd VimEnter * call s:abolish_setup()
"augroup END
"
"function! s:abolish_setup()
"  if exists('g:Abolish') && has_key(g:Abolish,'Coercions')
"    if !has_key(g:Abolish.Coercions,'l')
"      let g:Abolish.Coercions.l = s:function('s:abolish_l')
"    endif
"    if !has_key(g:Abolish.Coercions,'t')
"      let g:Abolish.Coercions.t = s:function('s:abolish_t')
"    endif
"  endif
"endfunction
"
"function! s:abolish_l(word)
"  let singular = rails#singularize(a:word)
"  return a:word ==? singular ? rails#pluralize(a:word) : singular
"endfunction
"
"function! s:abolish_t(word)
"  if a:word =~# '\u'
"    return rails#pluralize(rails#underscore(a:word))
"  else
"    return rails#singularize(rails#camelize(a:word))
"  endif
"endfunction
"
"" }}}1
"" vim:set sw=2 sts=2:
