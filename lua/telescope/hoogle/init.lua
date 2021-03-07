local neorocks = require 'plenary.neorocks'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local previewers = require 'telescope.previewers'
local PreprocessJob = require 'telescope.hoogle.preprocess_job'
local json = require 'telescope.hoogle.json'

local function prompt_to_hoogle_cmd(opts)
  local function to_hoogle_cmd(_, prompt)
    if not prompt or prompt == '' then
      return nil
    end

    -- TODO results showing up twice when typing quickly?
    local count = opts.count or 500
    return {
      command = 'hoogle',
      args = vim.tbl_flatten { '--json', '--count=' .. count, prompt }
    }
  end

  return to_hoogle_cmd
end

local function strip_html_tags(doc)
  -- TODO handle pre tags specially, use syntax highlighting for haskell?
  return doc:gsub('</?[^>]+>\n?', '')
end

local function format_html_chars(doc)
  return doc:gsub('&lt;', '<')
            :gsub('&gt;', '>')
            :gsub('&amp', '&')
end

local function html_to_term(doc)
  return format_html_chars(strip_html_tags(doc))
end

local function show_preview(entry, buf)
  local docs = html_to_term(entry.docs)
  local lines = vim.split(docs, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
end

local function entry_maker(data)
  local module_name = (data.module or {}).name
  local line = module_name
    and module_name .. ' ' .. data.item
    or data.item
  return {
    valid = true,
    value = line,
    ordinal = line,
    display = line,
    docs = data.docs,
    preview_command = show_preview
  }
end

local function preprocess_data(data)
  if data == 'No results found' then
    return {}
  end
  return json.parse(data)
end

local function setup(opts)
  opts = opts or {}

  if vim.fn.executable('hoogle') == '1' then
    vim.api.nvim_err_writeln("telescope.hoogle: 'hoogle' command not found! Aborting.")
    return
  end

  local finder = PreprocessJob:new({
    fn_command = prompt_to_hoogle_cmd(opts),
    fn_preprocess = preprocess_data,
    entry_maker = entry_maker
  })

  pickers.new(opts, {
    prompt_title = 'Live Hoogle search',
    finder = finder,
    -- TODO don't use display_content
    previewer = previewers.display_content.new(opts),
    attach_mappings = function(_, map)
      -- TODO mappings, allow custom mappings
      -- map('i', '<CR>', actions.close)
      return true
    end
  }):find()
end


-- TODO
-- wrapping of text in preview window
-- add custom keybindings
-- actions:
--   open browser
--   copy type
--   copy import


-- Testing code:
test = setup
vim.cmd 'nnoremap <leader>t :lua test()<cr>'
