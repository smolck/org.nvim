local fold = require('orgnvim/fold')
local helpers = require('orgnvim/helpers')

local function create_autocmds()
    local autocmds = {
        general = {
            {'BufNewFile,BufRead',  '*.org', 'setfiletype org'},
        }
    }

    helpers.nvim_create_augroups(autocmds)
end

local function setup()
    create_autocmds()
end

return {
    setup = setup,
    file_setup = file_setup,
}
