Toolkit = {}

Toolkit.log = function(...)
  local args = { ... }
  local chunks = {}
  for i, v in ipairs(args) do
    chunks[i] = { vim.inspect(v) }
  end
  vim.api.nvim_echo(chunks, true, {})
end
