function! OrgIndent()
    return luaeval("require('orgnvim/fold').org_indent()")
endfunction

function! OrgFoldText()
    return luaeval("require('orgnvim/fold').org_fold_text()")
endfunction

lua vim.api.nvim_command('set fillchars+=fold:\\ ')
lua vim.api.nvim_command('set listchars+=conceal:\\ ')
lua vim.api.nvim_command('set conceallevel=1')

set foldmethod=expr
set foldtext=OrgFoldText()
set foldexpr=OrgIndent()
setlocal shiftwidth=2
