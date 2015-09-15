local module = "nonFrameworkFiles"
return function()
  package.loaded[module] = nil
  module = nil

  local files = file.list()
  local frameworkFiles = {
    'availableNetworks.lc',
    'availableNetworks.lua',
    'config.lua',
    'configure.lc',
    'configure.lua',
    'HtmlHelpers.lc',
    'HtmlHelpers.lua',
    'HttpRequest.lc',
    'HttpRequest.lua',
    'HttpResponse.lc',
    'HttpResponse.lua',
    'index.html',
    'init.lua',
    'nonFrameworkFiles.lc',
    'nonFrameworkFiles.lua',
    'parseQueryString.lc',
    'parseQueryString.lua',
    'router.lc',
    'router.lua',
    'routes.lc',
    'routes.lua',
    'snor.lc',
    'snor.lua',
    'split.lc',
    'split.lua',
    'utils.lc',
    'utils.lua'
  }

  for _, v in pairs(frameworkFiles) do
    if files[v] ~= nil then
      files[v] = nil
    end
  end

  return files
end
