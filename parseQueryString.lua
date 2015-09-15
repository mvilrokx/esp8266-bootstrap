local module = "parseQueryString"
return function(qs)
  package.loaded[module] = nil
  module = nil

  local params = {}

  for _, p in pairs(require("split")(qs, "&")) do
    _, _, name, value = string.find(p, "([^&=]+)=([^&=]*)")
    params[name] = value
  end
  return params
end
