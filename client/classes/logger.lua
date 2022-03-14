Logger = {
  Log = function(info, string)
      local formattedLog = string.format('%s\t[^2%s^7] %s', "[^2LOG^7]", info, string)
      print(formattedLog)
  end,
  Info = function(info, string)
      local formattedLog = string.format('%s\t[^5%s^7] %s', "[^5INFO^7]", info, string)
      print(formattedLog)
  end,
  Warn = function(info, string)
      local formattedLog = string.format('%s\t[^3%s^7] %s', "[^3WARN^7]", info, string)
      print(formattedLog)
  end,
  Error = function(info, string)
      local formattedLog = string.format('%s\t[^9%s^7] %s', "[^9ERROR^7]", info, string)
      print(formattedLog)
  end
}