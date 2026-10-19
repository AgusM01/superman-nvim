# superman.nvim

A tiny "super `man`" for Neovim: press a key, type a word, and Claude tells you what it means — right inside a floating window.

```
╭ What does it mean? ─────────────────────╮
│ debounce                                │
╰─────────────────────────────────────────╯
```

- Telescope-like floating prompt
- Answer rendered as Markdown in a centered floating window
- Look up the word under the cursor with a single key
- No dependencies — just `curl` and Neovim ≥ 0.10

## Requirements

- Neovim **0.10+**
- `curl`
- An [Anthropic API key](https://console.anthropic.com/) exported as `ANTHROPIC_API_KEY`:

```sh
export ANTHROPIC_API_KEY="sk-ant-..."
```

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "<your-github-user>/superman.nvim",
  cmd = "Superman",
  opts = {},
  keys = {
    { "<leader>m", function() require("superman").ask() end, desc = "Superman: look up meaning" },
    { "<leader>M", function() require("superman").ask_cword() end, desc = "Superman: word under cursor" },
  },
}
```

### Other plugin managers

Install the repo and call `require("superman").setup()` (optional), then map the functions below to your keys.

## Usage

| Action | How |
| --- | --- |
| Open the prompt | `:Superman` or `require("superman").ask()` |
| Look up a word directly | `:Superman <word>` or `require("superman").query("word")` |
| Look up the word under the cursor | `require("superman").ask_cword()` |

In the prompt: `<CR>` searches, `<Esc>` cancels.
In the result window: `<CR>` or `q` closes it.

## Configuration

Defaults:

```lua
require("superman").setup({
  model = "claude-haiku-5-5",
  max_tokens = 1000,
  api_key_env = "ANTHROPIC_API_KEY",
  system = "You are a technical software dictionary for developers. ...",
  prompt_title = "What does it mean?",
  result_title = "superman",
  prompt_width = 0.4,      -- fraction of the editor width
  result_width = 0.6,
  result_max_height = 0.6, -- fraction of the editor height
})
```

Tip: change `system` to make it a general dictionary, answer in another language, or keep answers shorter.

## License

MIT
