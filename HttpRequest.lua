local module = "HttpRequest"
return function(req)
  -- Save RAM! http://www.esp8266.com/wiki/doku.php?id=nodemcu-unofficial-faq
  package.loaded[module] = nil
  module = nil

  print(req)

  local HttpReq = {
    META = {}
  }
  local qs
  local processingHeader = true

  for lNr, l in pairs(require("split")(req, "\r?\n")) do
    if lNr == 1 then -- process HTTP verb
      _, _, HttpReq.method, HttpReq.path, qs = string.find(l, "([A-Z]+) (/[^?]*)%??(.*) HTTP")
      if HttpReq.method == "GET" then
        -- query params are in url string
        HttpReq.GET = require("parseQueryString")(qs)
      end
    else -- not first line
      if l == "" or l == nil then -- indicate end of HEADER, start of BODY
        processingHeader = false
      else
        if processingHeader then
          for headerName, headerValue in pairs(require("split")(l, ":%s*")) do
            HttpReq.META[headerName] = headerValue
          end
        else -- processing body (of POST request)
          if HttpReq.method == "POST" then
            HttpReq.POST = require("parseQueryString")(l)
          end
        end
      end

    end
  end

  HttpReq.params = HttpReq.GET or HttpReq.POST
  return HttpReq

end
