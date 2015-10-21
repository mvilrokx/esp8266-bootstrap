local router = {
  _VERSION     = "0.2.0",
  _DESCRIPTION = "Poor man's router"
}

local Router = {}

function Router:dispatch(req)
  local r = require("HttpRequest")(req)
  if not self._tree[r.path] then
    return {
      header = "HTTP/1.1 404 Not Found\r\n\r\n",
      body = "404.html"
    }
  end
  local node = self._tree[r.path][r.method]
  if not node then
    return {
      header = "HTTP/1.1 404 Not Found\r\n\r\n",
      body = "404.html"
    }
  end
  return node(r.params)
end

local router_mt = { __index = Router }

------------------------------ PUBLIC INTERFACE --------------------------------
router.new = function(routes)
  return setmetatable({ _tree = routes }, router_mt)
end

return router
