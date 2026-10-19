if vim.g.loaded_superman then return end
vim.g.loaded_superman = true

-- :Superman          -> open the prompt
-- :Superman <word>   -> look up <word> directly
vim.api.nvim_create_user_command("Superman", function(opts)
  if opts.args ~= "" then
    require("superman").query(opts.args)
  else
    require("superman").ask()
  end
end, { nargs = "?", desc = "Ask Claude what a word means" })
