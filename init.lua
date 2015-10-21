-- This file (init.lua) will be auto-run on boot.
-- You can interrupt by sending tmr.stop(0) during the countdown
ssid = "ESP-" .. node.chipid()
bootDelay = 3
configureFile = "configure.lc"
bootFile = configureFile
wifiMode = wifi.STATIONAP

wifi.setmode(wifiMode)
require("availableNetworks")() -- this works asynchronously so init here

--print("WiFi Channel = " .. wifi.getchannel())
--print("WiFi Physical Mode = " .. wifi.getphymode())
--print("WiFi Sleep Type = " .. wifi.sleeptype(wifi.NONE_SLEEP))


local bootAlarmId = 0
local reconfigurePin = 3
local s
local err

print("Interrupt boot by executing tmr.stop(" .. bootAlarmId .. ") before countdown ends!")
print("Initiate reconfig by connecting pin " .. reconfigurePin .. " to GND before countdown ends!")
print("Booting in ...")

-- If GPIO changes during the countdown, launch config
gpio.mode(reconfigurePin, gpio.INT)
gpio.trig(reconfigurePin, "both", function()
  bootFile = configureFile
end)

if file.open("config.lua") then
  file.close()
  s, err = pcall(function() dofile("config.lua") end)
end

if wifiMode > 0 then
  wifi.setmode(wifiMode)
end

tmr.alarm(bootAlarmId, 1000, 1, function()
  print(bootDelay)
  bootDelay = bootDelay - 1
  if bootDelay < 1 then
    tmr.stop(bootAlarmId)
    gpio.mode(reconfigurePin, gpio.FLOAT)
    if bootFile == nil or bootFile == "" then
      bootFile = configureFile
    end
    if file.open(bootFile) then
      print('Booting ..' .. bootFile)
      file.close()
      s, err = pcall(function() dofile(bootFile) end)
    end
    if not s then print(err) end
  end
end)
