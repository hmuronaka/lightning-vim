function! s:endswith(string,suffix)
  return lightning_vim_util#endswith(a:string, a:suffix)
endfunction

let s:lightning_component = {}
function! lightning_component#create_from_path(path) abort
  call lightning_vim_util#debug(expand('<sfile>'), 'path: ' . a:path)
  let result = copy(s:lightning_component)
  
  let dirname = fnamemodify(a:path, ':h')
  let result.path = a:path
  let result.component_name = fnamemodify(dirname, ':t')
  let result.base_dir = fnamemodify(a:path, ':p:h')

  call lightning_vim_util#debug(expand('<sfile>'), 'dict: ' . result.component_name . ', ' . result.base_dir)

  return result
endfunction

function! s:lightning_component.get_path(suffix) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'suffix: ' . a:suffix)

  let result = ''
  if a:suffix == 'apex'
    let apex_controller_name = self.get_apex_controller_name()
    let result = 'pkg/classes/' . apex_controller_name . '.cls'
  elseif a:suffix == 'self'
    let result = self.path
  else
    let result = self.base_dir . '/' . self.component_name . a:suffix
  endif

  return result
endfunction

" suffix: 
"   "Controller.js, Helper.js, Render.js, apex ...
function! s:lightning_component.change_to(suffix) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'suffix: ' . a:suffix)

  let to_path = self.get_path(a:suffix)
  if filereadable(to_path)
    exe 'edit ' . to_path
  endif
endfunction


""""""""""""""""""""""""""""""""""""""""
" jump_to

function! s:lightning_component.jump_to(line) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'line: ' . a:line)

  if s:endswith(self.path, '.cmp')
    call self.jump_from_cmp(a:line)
  elseif s:endswith(self.path, '.js') 
    call self.jump_from_js(a:line)
  else
    call lightning_vim_util#debug(expand('<sfile>'), 'not match')
  endif
endfunction

function! s:lightning_component.jump_from_cmp(line) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'line: ' . a:line)

  let patterns = [
        \ {'pattern': '\<c\.\zs\w\+\ze', 'function': 'jump_to_js_controller'},
        \ {'pattern': '\%(\<v\.\)\zs\w\+\ze', 'function': 'jump_to_cmp_attribute'},
        \ {'pattern': '\%(<\w\+:\)\zs\w\+\ze\s*', 'function': 'jump_to_cmp'}
        \ ]

   for pattern in patterns
     let matched_str = lightning_vim_util#matchstr_in_cursor(a:line, pattern.pattern)
     if !empty(matched_str)
       call self[pattern.function](matched_str)
       return
     endif
   endfor

   call lightning_vim_util#debug(expand('<sfile>'), 'not matched.')
endfunction

function! s:lightning_component.jump_from_js(line) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'line: ' . a:line)

  let patterns = [
        \ {'pattern': '\(["'']\)c\.\zs\w\+\ze\1', 'function': 'jump_to_apex_controller'},
        \ {'pattern': 'helper\.\zs\w\+\ze', 'function': 'jump_to_js_helper'},
        \ {'pattern': '\%(self\|this\)\.\zs\w\+\ze', 'function': 'jump_to_js_self'}
        \ ]

   for pattern in patterns
     let matched_str = lightning_vim_util#matchstr_in_cursor(a:line, pattern.pattern)
     if !empty(matched_str)
       call self[pattern.function](matched_str)
       return
     endif
   endfor

   call lightning_vim_util#debug(expand('<sfile>'), 'not matched.')
endfunction

function! s:lightning_component.jump_to_js_controller(method_name) dict abort
  return self.jump_to_js(a:method_name, 'Controller.js')
endfunction

function! s:lightning_component.jump_to_js_helper(method_name) dict abort
  return self.jump_to_js(a:method_name, 'Helper.js')
endfunction

function! s:lightning_component.jump_to_js_self(method_name) dict abort
  return self.jump_to_js(a:method_name, 'self')
endfunction

function! s:lightning_component.jump_to_js(method_name, suffix) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'method_name: ' . a:method_name . ', suffix: ' . a:suffix)

  let controller_path = self.get_path(a:suffix)
  let pattern = s:pattern('js_method', a:method_name)
  let linenum = lightning_vim_util#line_from_file(controller_path, pattern)

  if a:suffix != 'self'
    call lightning_vim_util#edit(controller_path, linenum)
  else
    if linenum != -1
      exe linenum
    endif
  endif
endfunction


function! s:lightning_component.jump_to_cmp_attribute(attribute_name) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'attribute_name: ' . a:attribute_name)

  let cmp_path = self.get_path('.cmp')
  let pattern = s:pattern('cmp_attribute', a:attribute_name)
  let linenum = lightning_vim_util#line_from_file(cmp_path, pattern)
  call lightning_vim_util#edit(cmp_path, linenum)
endfunction

" Componentのcmpファイルにジャンプする
function! s:lightning_component.jump_to_cmp(component_name) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'component_name: ' . a:component_name)

  let cmp_path = 'pkg/aura/' . a:component_name . '/' . a:component_name . '.cmp'
  call lightning_vim_util#edit(cmp_path, -1)
endfunction


function! s:lightning_component.jump_to_apex_controller(method_name) dict abort
  call lightning_vim_util#debug(expand('<sfile>'), 'method_name: ' . a:method_name)

  let apex_controller_path = self.get_path('apex')
  if empty(apex_controller_path)
    call lightning_vim_util#debug(expand('<sfile>'), 'apex_controller not found from: ' . apex_controller_path)
    return
  endif

  let apex = apex_class#create_from_path(apex_controller_path)
  call apex.jump_to_method(a:method_name)
endfunction



""""""""""""""""""""""""""""""""""""""""
" static
function! s:pattern(pattern_type, name)
  let pattern = ''
  if a:pattern_type == 'js_method'
    let pattern = '^\s*' . a:name . '\s*\:\s*function'
  elseif a:pattern_type == 'cmp_attribute'
    let pattern ='aura:attribute\s\+.*\%(name\)\s*=\s*\(["'']\)' . a:name . '\1.*'
  else
    call lightning_vim_util#error(expand('<sfile>'), 'invalid pattern_type. ' . a:pattern_type . ', name: ' . a:name)
  endif
  return pattern
endfunction


""""""""""""""""""""""""""""""""""""""""
" util

function! s:lightning_component.get_apex_controller_name() dict
  "当該cmpの存在チェック
  let cmp_path = self.get_path('.cmp')
  let file = findfile(cmp_path, '.')
  if empty(file)
    return ''
  endif

  let apex_controller_name = s:get_apex_controller_name_from_cmp(cmp_path)
  return apex_controller_name
endfunction

function! s:get_apex_controller_name_from_cmp(cmp_path) 
  call lightning_vim_util#debug(expand('<sfile>'), 'cmp_path: ' . a:cmp_path)

  if !filereadable(a:cmp_path)
    call lightning_vim_util#debug(expand('<sfile>'), 'file is not readable')
    return ''
  endif

  let pattern = 'controller\s*=\s*\(["'']\)\(\w\+\.\)\?\zs\w\+\ze\1'
  let result = lightning_vim_util#line_and_str_from_file(a:cmp_path, pattern, 10)

  " matchした場合は、マッチした文字列を返す。
  " matchしなかったら、''を返す。
  return result[0]
endfunction


