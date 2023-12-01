require 'core.load'
require 'core.plugin.globals'

local Util = require 'core.utils'
local parts = require 'core.parts'

---@alias MainModule 'core'|'config'|string

---@class ModuleSpec
---@field name ModuleName
---@field event string
---@field opts table

---@alias ModuleName 'options'|'highlights'|'base'|'maps'|'plugins'|string
---@alias ModuleField { [MainModule]: Modules }

---@class Config
---@field log_level integer
---@field colorscheme string
---@field transparent_background boolean
---@field transparent_fn { [string]: function(bool) }
---@field modules Modules

---@class Core
---@field config Config
---@field group_id integer
---@field path CorePath

---@class CorePath
---@field root string
---@field keymaps string

local M = {}

---@type Core
---@diagnostic disable: missing-fields
_G.core = _G.core or {}

---@type Config
M.default_config = {
  log_level = vim.log.levels.INFO,
  colorscheme = "habamax", -- or "zaibatsu" or "retrobox"
  transparent_background = false,
  transparent_fn = {},
  modules = {},
}

---@type Config
_G.core.config = vim.tbl_deep_extend('force', M.default_config, _G.core.config or {})

local root_path = vim.fn.stdpath("data") .. "/core"
_G.core.path = {
  root = root_path,
}

---@param config Config
function M.setup(config)
  if vim.loader and vim.fn.has "nvim-0.9.1" == 1 then vim.loader.enable() end
  core.group_id = vim.api.nvim_create_augroup("config:" .. CONFIG_MODULE, {})

  -- preload keymaps module
  parts.preload {}

  ---@class Config
  local _config = {
    colorscheme = config.colorscheme,
    transparent_background = config.transparent_background,
    transparent_fn = config.transparent_fn,
    modules = {},
  }

  for main_mod, modules in pairs(config.modules) do
    _config.modules[main_mod] = {}
    for i, spec in ipairs(modules) do
      _config.modules[main_mod][i] = {
        name = spec[1],
        reload = spec.reload or true,
        event = spec.event or false,
        opts = spec.opts or {},
        loaded = false,
      }
    end
  end

  _G.core.config = vim.tbl_deep_extend('force', _G.core.config, _config)

  M.load()
end

--- load config
function M.load()
  Util.log('loading config')

  parts.load_modules {}

  parts.colorscheme {}

  _G.transparent_background_fn = core.config.transparent_fn
  vim.api.nvim_create_user_command('ToggleTransparentBG', function ()
    _G.toggle_transparent_background()
  end, {})

  toggle_transparent_background(core.config.transparent_background)

  parts.platform {}
end

function M.reload()
  Util.log('reloading config')

  vim.api.nvim_del_augroup_by_id(core.group_id)
  core.group_id = vim.api.nvim_create_augroup("config:" .. CONFIG_MODULE, {})
  require 'core.load.autocmds'.setup {
    group_id = core.group_id,
  }

  parts.load_modules {}

  parts.colorscheme {}

  _G.transparent_background_fn = core.config.transparent_fn
  vim.api.nvim_create_user_command('ToggleTransparentBG', function ()
    _G.toggle_transparent_background()
  end, {})

  toggle_transparent_background(core.config.transparent_background)

  parts.platform {}
end

return M
