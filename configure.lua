local router = require "router"

if file.open("routes.lc") then
  file.close()
  s, err = pcall(function() dofile("routes.lc") end)
end

local r = router.new(routes)

-- Channel is optional but I suspect that if there is overlap,
-- the signal of the chip gets drowned out by the more powerful AP
wifi.ap.config({ssid = ssid, channel = 2})
--print("WiFi Channel = " .. wifi.getchannel())

local s = net.createServer(net.TCP, 30)

s:listen(80, function(c)
  local res = {}
  local DataToGet = 0

  c:on("receive", function(c, req)
    -- print(req)
    res = r:dispatch(req)
    c:send(res.header)
  end)

  c:on("sent", function(c)
    if res.body then
      if res.body.data then
        c:send(res.body.data)
      else
        local maxBytes = 512 -- DO NOT CHANGE!!!
        if DataToGet >= 0 then
          if file.open(res.body, "r") then
            file.seek("set", DataToGet)
            local line = file.read(maxBytes)
            file.close()
            if line then
              c:send(line)
              DataToGet = DataToGet + maxBytes
              if (string.len(line) == maxBytes) then -- there are more lines in the file
                return
              end
            end
          end
        end
      end
    end
    c:close()
  end)

end)
