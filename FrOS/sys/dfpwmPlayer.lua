local dfpwmPlayer = {}
local dfpwm = require("cc.audio.dfpwm")
local textViewer = require("/FrOS/sys/textViewer")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")

function dfpwmPlayer.play(path)
    if speaker ~= nil then
        if fs.exists(path) then
            for chunk in io.lines(path, 16 * 1024) do
                local buffer = decoder(chunk)
            
                while not speaker.playAudio(buffer) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        else
            textViewer.eout("Erreur : Fichier introuvable.")
        end
    end
end

function dfpwmPlayer.playErrorSound()
  if speaker ~= nil then
    speaker.playNote("bit")
  end
end

function dfpwmPlayer.playConfirmationSound()
  if speaker ~= nil then
    speaker.playNote("chime")
  end
end

return dfpwmPlayer