let s:lightning_tooling = {}
function! lightning_tooling#create(deploy_json_path)
  let deploy_json_str = readfile(a:deploy_json_path)
  let deploy_json = json_decode(deploy_json_str)

  let obj = copy(s:lightning_tooling_vim)
  obj.username = deploy_json.username . deploy_json.security_token
  obj.password = deploy_json.password

  return obj
endfunction

function! s:lightning_tooling.executeAnonymous() dict abort
endfunction

function! lightning_tooling#execute(params) abort
  if empty(g:apex_tooling_force_dot_com_path)
    return
  endif

  let cmd = 'java -jar ' . g:apex_tooling_force_dot_com_path
  call vimproc#cmd#system(cmd)
endfunction


