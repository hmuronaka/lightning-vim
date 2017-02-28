let s:lightning_tooling_vim = {}
function! lightning_tooling_vim#create(deploy_json_path)
  let deploy_json_str = readfile(a:deploy_json_path)
  let deploy_json = json_decode(deploy_json_str)

  let obj = copy(s:lightning_tooling_vim)
  obj.username = deploy_json.username . deploy_json.security_token
  obj.password = deploy_json.password

  return obj
endfunction

function! lightning_tooling_vim.executeAnonymous()

endfunction
