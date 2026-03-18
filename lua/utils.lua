local U = {}

function U.print_table(t, indent)
  indent = indent or 0
  for k, v in pairs(t) do
    local formatting = string.rep('  ', indent) .. tostring(k) .. ': '
    if type(v) == 'table' then
      print(formatting)
      U.print_table(v, indent + 1)
    else
      print(formatting .. tostring(v))
    end
  end
end

return U
