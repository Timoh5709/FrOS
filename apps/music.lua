local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local statusBar = require("/sys/statusBar")

local function player(filename)
  for chunk in io.lines(filename, 16 * 1024) do
    local buffer = decoder(chunk)
    
    while not speaker.playAudio(buffer) do
      os.pullEvent("speaker_audio_empty")
    end
  end 
end

local function main()
  dossier = "music.lua"
  write(dossier .. "& ")
  statusBar.draw(dossier)
  local input = read()
  
  if fs.exists(input) then
    print("Joue actuellement : " .. input)
    player(input)
  end
end

if speaker ~= nil then
  main()
else
  print("Erreur : Aucun haut-parleur detecte.")
end