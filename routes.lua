routes = {
  ["/"] = {
    GET = function(params)
      return {
        header = "HTTP/1.1 200 OK\r\nContent-type: text/html\r\nServer: ESP8266\r\n\r\n",
        body = "index.html"
      }
    end,
    POST = function(params)
      file.open("config.lua", "w+")
      for k, v in pairs(params) do
        -- print(k .. ' : ' .. v)
        file.writeline(k .. " = '" .. v .. "'")
      end
      file.close()
      return {
        header = "HTTP/1.1 303 See Other\r\nLocation: http://192.168.4.1\r\n\r\n"
      }
    end
  },
  ["/files"] = {
    GET = function(params)
      return {
        header = "HTTP/1.1 200 OK\r\nContent-type: application/json\r\nServer: ESP8266\r\n\r\n",
        body = {data = cjson.encode(require("nonFrameworkFiles")())}
      }
    end
  },
  ["/networks"] = {
    GET = function(params)
      return {
        header = "HTTP/1.1 200 OK\r\nContent-type: application/json\r\nServer: ESP8266\r\n\r\n",
        body = {data = cjson.encode(networks)}
      }
    end
  },
  ["/heap"] = {
    GET = function(params)
      return {
        header = "HTTP/1.1 200 OK\r\nContent-type: application/json\r\nServer: ESP8266\r\n\r\n",
        body = {data = cjson.encode({heap = node.heap()})}
      }
    end
  },
  ["/favicon.ico"] = {
    GET = function(params)
      return {
        header = "HTTP/1.1 404 file not found"
      }
    end
  }
}
