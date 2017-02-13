
let s:apex_class = {}
function! apex_class#create_from_path(path)
  let result = copy(s:apex_class)
  let result.path = a:path
  return result
endfunction

function! s:apex_class.jump_to_method(method_name) dict abort
  let pattern = '\s*' . a:method_name . '\s*\(.*\)\s*{\?\s*$'
  let linenum = lightning_vim_util#line_from_file(self.path, pattern)
  call lightning_vim_util#edit(self.path, linenum)
endfunction

