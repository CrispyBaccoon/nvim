
-- RPC Server

local is_server = function()
  local sl = vim.fn.serverlist()
  return vim.tbl_contains(sl, '/tmp/vi.pipe')
end

local quit_server = function()
  if is_server() then
    vim.fn.system { 'rm', '/tmp/vi.pipe' }
  end
end

local server_au_id = vim.api.nvim_create_augroup('RPCServer', { clear = true })
vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  group = server_au_id,
  callback = function()
    if is_server() then
      vim.api.nvim_create_autocmd('VimLeavePre', {
        once = true,
        group = server_au_id,
        callback = function()
          quit_server()
        end
      })
    end
  end
})

keymaps.normal['<leader>x'] = ':<C-U>call StripTrailingWhitespace()<CR>'

vim.cmd [[
function! Get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction
]]

vim.api.nvim_create_user_command('SubstituteSelection', function (_)
  local select = vim.fn.Get_visual_selection()
  vim.ui.input({ prompt = "replace `".. select .."` with >" }, function (input)
    if not input then return end
    vim.cmd("%s/"..select.."/"..input.."/g")
    vim.cmd('norm ``')
  end)
end, {})

-- netrw
vim.g.netrw_liststyle = 3
vim.cmd [[hi! link netrwTreeBar NonText]]
