local dfpwmPlayer = {}
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")

local function eout(text)
    term.setTextColor(colors.red)
    print(text)
    term.setTextColor(colors.white)
    dfpwmPlayer.playErrorSound()
end

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
            eout("Erreur : Fichier introuvable.")
        end
    end
end

function dfpwmPlayer.playStartupSound()
    if speaker ~= nil then
        local co = coroutine.create(function ()
            dfpwmPlayer.play("FrOS/media/startup.dfpwm")
        end)
        coroutine.resume(co)
    end
end

function dfpwmPlayer.playShutdownSound()
    if speaker ~= nil then
        dfpwmPlayer.play("FrOS/media/shutdown.dfpwm")
        os.sleep(2.15)
    end
end

function dfpwmPlayer.playErrorSound()
    if speaker ~= nil then
        local co = coroutine.create(function ()
            dfpwmPlayer.play("FrOS/media/error.dfpwm")
        end)
        coroutine.resume(co)
    end
end

function dfpwmPlayer.playConfirmationSound()
    if speaker ~= nil then
        local co = coroutine.create(function ()
            dfpwmPlayer.play("FrOS/media/ask.dfpwm")
        end)
        coroutine.resume(co)
    end
end

return dfpwmPlayer