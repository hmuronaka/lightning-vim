" lightning-vim.vim 
" Author:       hmuronaka
" GetLatestVimScripts: 1567 1 :AutoInstall: lightning-vim.vim

"if exists('g:loaded_lightning') || &cp || v:version < 700
"  finish
"endif
"let g:loaded_lightning = 1

" Utility Functions {{{1
"
let g:lightning_vim#enable_debug_log=1

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
  let component = lightning_component#create_from_path(expand(a:path))
  call component.change_to(a:target)
endfunction

function! s:Jump_to_declaration(path) abort
  call lightning_vim_util#debug(expand('<sfile>'), 'path:' . a:path)
  let component = lightning_component#create_from_path(expand(a:path))
  call component.jump_to(getline('.'))
endfunction

function! s:lightning_setup()
  command! -bang -buffer -nargs=0 Rcontroller call s:change_to('%', 'Controller.js')
  command! -bang -buffer -nargs=0 Rcss call s:change_to('%', '.css')
  command! -bang -buffer -nargs=0 Rhelper call s:change_to('%', 'Helper.js')
  command! -bang -buffer -nargs=0 Rcmp call s:change_to('%', '.cmp')
  command! -bang -buffer -nargs=0 Rrender call s:change_to('%', 'Renderer.js')
  command! -bang -buffer -nargs=0 Rapex call s:change_to('%', 'apex')

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
