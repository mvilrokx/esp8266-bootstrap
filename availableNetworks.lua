local module = "availableNetworks"
return function()
  package.loaded[module] = nil
  module = nil

  networks = {}

  -- local currentWifiMode = wifi.getmode()
  -- print("currentWifiMode = " .. wifi.getmode())

  -- wifi.setmode(wifi.STATIONAP) -- Need this mode to get available networks
  -- print("currentWifiMode = " .. wifi.getmode())

  wifi.sta.getap(function(t)
    for ssid, attr in pairs(t) do
      local network = {}
      network.authmode, network.rssi, network.bssid, network.channel = string.match(attr, "(%d),(-?%d+),(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x),(%d+)")
      -- if network.authmode == "0" then
      --   network.authmodeSymbol = "\uD83D\uDD13" -- unsecured
      -- else
      --   network.authmodeSymbol = "\uD83D\uDD10" -- secured
      -- end
      networks[ssid] = network
    end
    -- wifi.setmode(currentWifiMode)
    -- print("currentWifiMode = " .. wifi.getmode())
  end)

end
