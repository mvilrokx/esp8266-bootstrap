local router = {
  _VERSION     = "0.1.0",
  _DESCRIPTION = "Poor man's router"
}

local Router = {}

function Router:dispatch(req)
  local r = require("HttpRequest")(req)
  local node = self._tree[r.path][r.method]
  if not node then return nil, ("Unknown method: %s"):format(r.method) end
  return node(r.params)
end

local router_mt = { __index = Router }

------------------------------ PUBLIC INTERFACE --------------------------------
router.new = function(routes)
  return setmetatable({ _tree = routes }, router_mt)
end

return router
