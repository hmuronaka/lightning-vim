
""""""""""""""""""""""""""""""""""""""""
" log

" error log
function! lightning_vim_util#error(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
  let v:errmsg = a:msg
endfunction

function! lightning_vim_util#debug(expanded_sfile, msg)
  if exists("g:lightning_vim#enable_debug_log") && g:lightning_vim#enable_debug_log != 0
    let method_name = s:method_name(a:expanded_sfile)
    echomsg method_name . ': ' . a:msg
  endif
endfunction

function s:method_name(expanded_sfile)
  "return substitute(a:expanded_sfile, '.*\(\.\.\|\s\)', '', '')
  return a:expanded_sfile
endfunction

""""""""""""""""""""""""""""""""""""""""
" file

" return: matched: [mattched_string, line_number]
"         notmatched: ['', -1]
function! lightning_vim_util#line_and_str_from_file(path, pattern, max_length)
  let matched_str = ''
  let line_num = 1

  if a:max_length > 0
    for line in readfile(a:path, '', a:max_length)
      let matched_str = matchstr(line, a:pattern)
      if !empty(matched_str)
        break
      endif
      let line_num += 1
    endfor
  else
    for line in readfile(a:path, '')
      let matched_str = matchstr(line, a:pattern)
      if !empty(matched_str)
        break
      endif
      let line_num += 1
    endfor
  endif

  if empty(matched_str)
    return ['', -1]
  endif

  return [matched_str, line_num]
endfunction

function! lightning_vim_util#line_from_file(path, pattern)
  let line_num = 1
  for line in readfile(a:path, '')
    let result = matchstr(line, a:pattern)
    if !empty(result)
      return line_num
    endif
    let line_num += 1
  endfor
  return -1
endfunction

function! lightning_vim_util#edit(path, line_num)
  if !filereadable(a:path)
    call lightning_vim_util#debug('file isn''t readable. path: ' . a:path)
    return 0
  endif

  if a:line_num != -1
    exe 'edit+' . a:line_num . ' ' . a:path
  else
    exe 'edit ' . a:path
  endif

  return 1
endfunction

""""""""""""""""""""""""""""""""""""""""
" string
function! lightning_vim_util#endswith(string,suffix)
    return strpart(a:string, len(a:string) - len(a:suffix), len(a:suffix)) ==# a:suffix
endfunction

function! lightning_vim_util#matchstr_in_cursor(str, pattern)
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

