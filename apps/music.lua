-- @fullscreen
local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local update = require("/FrOS/sys/update")
local running = update.appCheck(0.81)
if not running then
    return
end
local httpViewer = require("/FrOS/sys/httpViewer")
if not fs.exists("FrOS/localization/music.loc") then
    httpViewer.installGithub("https://raw.githubusercontent.com/Timoh5709/FrOS/refs/heads/main/", "FrOS/localization/music.loc")
end
local locLua = require("/FrOS/sys/loc")
local stg = _G.FrOS.stg
local language = "FR"
language = stg["language"]
local loc = locLua.load("FrOS/localization/music.loc", language)
local textViewer = require("/FrOS/sys/textViewer")
local decoder = dfpwm.make_decoder()

local function player(filename)
  for chunk in io.lines(filename, 16 * 1024) do
    local buffer = decoder(chunk)
    
    while not speaker.playAudio(buffer) do
      local eventData = {os.pullEvent()}
      local event = eventData[1]

      if event == "speaker_audio_empty" then
      elseif event == "key" then
        speaker.stop()
        print(loc["main.stop"])
        return
      end
    end
  end 
end

local function main()
  local dossier = "music.lua"
  FrOS.statusBar.updateDossier(dossier)
  write(dossier .. "& ")
  local input = read()
  
  if fs.exists(input) then
    print(loc["main.playing"] .. input)
    player(input)
  end
end

if speaker ~= nil then
  main()
else
  textViewer.eout(loc["error.noSpeaker"])
end