require("lib.moonloader")
samp = require("lib.samp.events")

function main()
	while not isSampAvailable() do wait(100) end
	
    while true do
        wait(0)
    end
end

--isPauseMenuActive()
function samp.onShowTextDraw(id, data)
	if (data.text):find(".+ %- .+ [%-+]") then
		print(data.text:match("[^~]+"))
	end
end