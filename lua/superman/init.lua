-- superman: ask Claude for the meaning of a word/term
local M = {}

M.config = {
  model = "claude-haiku-5-5",
  max_tokens = 1000,
  -- Name of the environment variable that holds the Anthropic API key
  api_key_env = "ANTHROPIC_API_KEY",
  system = "You are a technical software dictionary for developers. When given a word, term, function name or concept, reply in English with a concise definition, a short usage example in code if relevant.",
  prompt_title = "What does it mean?",
  result_title = "superman",
  -- Window sizes as a fraction of the editor
  prompt_width = 0.4,
  result_width = 0.6,
  result_max_height = 0.6,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Open the result window; returns a function to replace its text later
local function show(text)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  local w = math.floor(vim.o.columns * M.config.result_width)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = 1, row = 0, col = 0,
    style = "minimal", border = "rounded", title = " " .. M.config.result_title .. " ",
  })
  vim.wo[win].wrap = true
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<CR>", "<cmd>close<cr>", { buffer = buf })

  local function set(new_text)
    -- Window was closed before the answer arrived
    if not vim.api.nvim_win_is_valid(win) then return end
    local lines = vim.split(new_text, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local h = math.max(1, math.min(#lines, math.floor(vim.o.lines * M.config.result_max_height)))
    vim.api.nvim_win_set_config(win, {
      relative = "editor", width = w, height = h,
      row = math.floor((vim.o.lines - h - 2) / 2), col = math.floor((vim.o.columns - w) / 2),
    })
  end
  set(text)
  return set
end

-- Floating one-line prompt (telescope-like), title on the top border
local function prompt(title, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  local w = math.floor(vim.o.columns * M.config.prompt_width)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = 1,
    row = math.floor((vim.o.lines - 3) / 2), col = math.floor((vim.o.columns - w) / 2),
    style = "minimal", border = "rounded",
    title = " " .. title .. " ", title_pos = "left",
  })
  vim.cmd("startinsert")

  local function close()
    vim.cmd("stopinsert")
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  local function submit()
    local text = vim.trim(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
    close()
    if text ~= "" then on_submit(text) end
  end

  vim.keymap.set({ "i", "n" }, "<CR>", submit, { buffer = buf })
  vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
  -- Close if focus leaves the prompt
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })
end

-- Look up a word and show the answer in a floating window
function M.query(word)
  local key = os.getenv(M.config.api_key_env)
  if not key or key == "" then
    vim.notify("superman: " .. M.config.api_key_env .. " is not set", vim.log.levels.ERROR)
    return
  end
  local body = vim.json.encode({
    model = M.config.model,
    max_tokens = M.config.max_tokens,
    system = M.config.system,
    messages = { { role = "user", content = word } },
  })
  local set = show("Looking up \"" .. word .. "\"...")
  vim.system({
    "curl", "-s", "https://api.anthropic.com/v1/messages",
    "-H", "x-api-key: " .. key,
    "-H", "anthropic-version: 2023-06-01",
    "-H", "content-type: application/json",
    "-d", body,
  }, { text = true }, vim.schedule_wrap(function(res)
    local ok, data = pcall(vim.json.decode, res.stdout)
    if ok and data.content then
      -- Keep only text blocks (some models return a "thinking" block first)
      local parts = {}
      for _, block in ipairs(data.content) do
        if block.type == "text" then table.insert(parts, block.text) end
      end
      set(#parts > 0 and table.concat(parts, "\n") or "No text in response:\n" .. res.stdout)
    else
      set("Error:\n" .. (res.stdout ~= "" and res.stdout or res.stderr))
    end
  end))
end

-- Open an input prompt to type the word
function M.ask()
  prompt(M.config.prompt_title, M.query)
end

-- Use the word under the cursor
function M.ask_cword()
  M.query(vim.fn.expand("<cword>"))
end

return M
