" Reference rails-vim by Tim Pope
" lightning-vim.vim - Detect a lightning-vim application
" Author:       hmuronaka
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

function! s:endswith(string,suffix)
    return strpart(a:string, len(a:string) - len(a:suffix), len(a:suffix)) ==# a:suffix
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

" apexのcontrollerからlightningコンポーネントのベースパスを探す
function! s:search_aura_dir(controller_name)
  let base_aura_path = 'pkg/aura/**/*.cmp'
  " auraの各パスの*.cmpを探索する
  let filelist = glob(base_aura_path)
  let splitted = split(filelist, '\n')
  for file in splitted
    let cmp_controller_name = s:get_apex_controller_name(file)
    if !empty(cmp_controller_name)
      echom file . ', ' . cmp_controller_name
    endif
  endfor
endfunction

"comp{suffix}ファイル名を取得する
function! s:aura_component_path(path, suffix)
  if s:is_lightning_directory(expand(a:path), 'pkg/aura/')
    let dirname = expand(a:path . ':h')
    let dirname = fnamemodify(dirname, ':t')
    let curdir = expand(a:path .':p:h')
    let aura_component_path = curdir . '/' . dirname . a:suffix
    return aura_component_path
  elseif s:is_lightning_directory(expand(a:path), 'pkg/classes/')
    "call s:search_aura_dir('test')
  endif
  return ''
endfunction

function! s:change_to(path, target)
  let controller_path = s:aura_component_path(a:path, a:target)
  if filereadable(controller_path)
    exe 'edit ' . controller_path
  endif
endfunction

" pathが'pkg/aura/'など内のパスかどうか
function! s:is_lightning_directory(path, target)
  return stridx(a:path, a:target) == 0
endfunction

function! s:get_apex_controller_name(cmp_path)
  "echom 's:get_apex_controller_name(cmp_path) cmp_path: ' . a:cmp_path
  let pattern1 = 'controller\s*=\s*"\(\w\+\.\)\?\zs\w\+\ze"'
  for line in readfile(a:cmp_path, '', 10)
    let name = matchstr(line, pattern1)
    if !empty(name)
      return name
    endif
  endfor
  return ''
endfunction

function! s:get_apex_controller_path(apex_controller_name)
  let apex_controller_path = 'pkg/classes/' . a:apex_controller_name . '.cls'
  return apex_controller_path
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
  let apex_controller_path = s:get_apex_controller_path(apex_controller_name)
  exe 'edit ' . apex_controller_path
endfunction

function! s:Jump_to_declaration(path) abort
  if s:endswith(expand(a:path), '.cmp')
    "echom 'Jump_to_declaration'
    call s:jump_from_cmp(a:path)
  elseif s:endswith(expand(a:path), '.js') 
    call s:jump_from_js_controller(a:path)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""
" jump_fromp_cmp

function! s:jump_from_cmp(path) abort
  let line = getline('.')

  " {!c.methodname}
  let method_name = s:matchstr_in_cursor(line, '{!c\.\zs\w\+\ze}')
  if !empty(method_name)
    "echom 'method_name: ' . method_name
    call s:jump_to_js_controller(a:path, method_name)
  endif

  " {!v.data} {!v.data.a}
  let attribute_name = s:matchstr_in_cursor(line, '\%(\<v\.\)\zs\w\+\ze')
  if !empty(attribute_name)
    echom 'attribute_name: ' . attribute_name
    call s:jump_to_cmp_attribute(a:path, attribute_name)
  endif

  let component_name = s:matchstr_in_cursor(line,'\%(<\w\+:\)\zs\w\+\ze\s*')
  if !empty(component_name)
    echom 'component_name: ' . component_name
    call s:jump_to_cmp(a:path, component_name)
  endif
endfunction

function! s:jump_to_js_controller(path, method_name) abort
  let controller_path = s:aura_component_path(a:path, 'Controller.js')
  "echom 'controller_path: ' . controller_path
  let linenum = s:pos_of_js_method_declaration(controller_path, a:method_name)
  "echom 'linenum: ' . linenum
  
  if linenum != -1
    exe 'edit +' . linenum . ' ' . controller_path
  else
    exe 'edit ' . controller_path
  endif
  " move line num
endfunction

function! s:pos_of_js_method_declaration(controller_path, method_name)
  "echom a:method_name
  let pattern = '^\s*' . a:method_name . '\s*\:\s*function'
  let line_num = 1
  for line in readfile(a:controller_path, '')
    let name = matchstr(line, pattern)
    if !empty(name)
      return line_num
    endif
    let line_num += 1
  endfor
  return -1
endfunction

function! s:jump_to_cmp_attribute(path, attribute_name) abort
  let cmp_path = s:aura_component_path(a:path, '.cmp')
  "echom 'controller_path: ' . controller_path
  let linenum = s:pos_of_cmp_attribute_declaration(cmp_path, a:attribute_name)
  "echom 'linenum: ' . linenum
  
  if linenum != -1
    exe 'edit +' . linenum . ' ' . cmp_path
  else
    exe 'edit ' . cmp_path
  endif
  " move line num
endfunction

function! s:pos_of_cmp_attribute_declaration(cmp_path, attribute_name)
  echom 's:pos_of_cmp_attribute_declaration(cmp_path, attribute_name): ' . a:attribute_name

  let pattern ='aura:attribute\s\+.*\%(name\)\s*=\s*"' . a:attribute_name . '".*'
  let line_num = 1
  for line in readfile(a:cmp_path, '')
    let name = matchstr(line, pattern)
    if !empty(name)
      return line_num
    endif
    let line_num += 1
  endfor
  return -1
endfunction

" Componentのcmpファイルにジャンプする
function! s:jump_to_cmp(path, component_name) abort
  let cmp_path = 'pkg/aura/' . a:component_name . '/' . a:component_name . '.cmp'
  if filereadable(cmp_path)
    exe 'edit ' . cmp_path
  endif
endfunction




""""""""""""""""""""""""""""""""""""""""
" jump_from_js_controller

function! s:jump_from_js_controller(path) abort
  let line = getline('.')
  let method_name = s:matchstr_in_cursor(line, '"c\.\zs\w\+\ze"')
  "echom 's:jump_from_js_controller(path) method_name: ' . method_name
  if !empty(method_name)
    call s:jump_to_apex_controller(a:path, method_name)
  else
    let method_name = s:matchstr_in_cursor(line, 'helper\.\zs\w\+\ze')
    echom 'helper.method_name: ' . method_name
    if !empty(method_name)
      call s:jump_to_helper(a:path, method_name)
    endif
  endif
endfunction

function! s:jump_to_apex_controller(path, method_name)
  let component_path = s:aura_component_path(a:path, '.cmp')
  let apex_controller_name = s:get_apex_controller_name(component_path)
  if empty(apex_controller_name)
    return
  endif

  echom 's:jump_to_apex_controller(path, method_name) controller_name: ' . apex_controller_name
  let apex_controller_path = s:get_apex_controller_path(apex_controller_name)
  let line_num = s:line_of_apex_method_declaration(apex_controller_path, a:method_name)
  exe 'edit ' . apex_controller_path

  if line_num != -1
    exe line_num
  endif
endfunction

function! s:line_of_apex_method_declaration(apex_path, method_name)
  let pattern = '\s*' . a:method_name . '\s*\(.*\)\s*{\?\s*$'
  let line_num = 1
  for line in readfile(a:apex_path, '')
    let name = matchstr(line, pattern)
    if !empty(name)
      return line_num
    endif
    let line_num += 1
  endfor
  return -1
endfunction

function! s:jump_to_helper(path, method_name)
  let helper_path = s:aura_component_path(a:path, 'Helper.js')
  let line_num = s:pos_of_js_method_declaration(helper_path, a:method_name)
  if line_num != -1
    exe 'edit +' . line_num . ' ' . helper_path
  else
    exe 'edit ' . helper_path
  endif
endfunction

function! s:matchstr_in_cursor(str, pattern)
  let startPos = 0
  let result_str = ''
  while 1
    let result = matchstrpos(a:str, a:pattern, startPos)
    if empty(result[0])
      let result_str = ''
      break
    endif

    let column = col('.')
    if result[1] <= column && column <= result[2]
      let result_str = result[0]
      break
    endif
    let startPos = result[2]
  endwhile
  return result_str
endfunction

function! s:lightning_setup()
  command! -bang -buffer -nargs=0 Rcontroller call s:change_to('%', 'Controller.js')
  command! -bang -buffer -nargs=0 Rcss call s:change_to('%', '.css')
  command! -bang -buffer -nargs=0 Rhelper call s:change_to('%', 'Helper.js')
  command! -bang -buffer -nargs=0 Rcmp call s:change_to('%', '.cmp')
  command! -bang -buffer -nargs=0 Rrender call s:change_to('%', 'Renderer.js')
  command! -bang -buffer -nargs=0 Rapex call s:change_to_apex('%')

  let pattern = '^$'
  if mapcheck('gf', 'n') =~# pattern
    nmap <buffer> <SID>JumpToDeclaration :call <SID>Jump_to_declaration('%')<CR>
    nmap <buffer> <Plug>JumpToDeclaration <SID>JumpToDeclaration
    nmap <buffer> gf <Plug>JumpToDeclaration
  endif
endfunction

augroup lightningPluginDetect
  autocmd!
  autocmd BufNewFile call s:lightning_setup
  autocmd BufReadPost * call s:lightning_setup()
  autocmd VimEnter * call s:lightning_setup()
augroup END

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
