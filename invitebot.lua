botName = os.getenv("USER") -- your bot's name
botPw = os.getenv("PW") -- your bot's password
ownerID = os.getenv("ID") -- ownerID
key = os.getenv("KEY") -- key
chat = "blbots" -- If things get a little out of control in the #blbots chat, try changing this value to something else.
admins = {"Radioactium#0000", "Hollosou#6531", "Lanadelrey#1407", "Brooklyn#4914", "Ashbolt#0000", "Voyeur#9539", "Alfiecakes#0000", "Trivia#3603", "Floawt#0000", "Laurineeeeee#2008", "Voshk#1486", "Fluffy#3087", "Ninetailsdes#0000", "Sophsoul#0918"} -- add admins here
local timer, transfromage = require("timer"), require("transfromage")
client = transfromage.client()
client._handle_players = true

client:setCommunity(14)

admins = { ["Radioactium#0000"] = true, ["Hollosou#6531"] = true, ["Lanadelrey#1407"] = true, ["Brooklyn#4914"] = true, ["Ashbolt#0000"] = true, ["Voyeur#9539"] = true, ["Alfiecakes#0000"] = true, ["Trivia#3603"] = true, ["Floawt#0000"] = true, ["Laurineeeeee#2008"] = true, ["Voshk#1486"] = true, ["Fluffy#3087"] = true, ["Ninetailsdes#0000"] = true, ["Sophsoul#0918"] = true }

blacklistNames = {}
for line in io.lines("blacklist.txt") do 
	blacklistNames[#blacklistNames+1] = line -- reads blacklist.txt
	--print(line)
end

print()

declinedNames = {}
usersOfDecline = {}
words = {}

for line in io.lines("declined.txt") do
	for k, v in line:gmatch("(%S+) (%S+)") do
		--print(k)
		declinedNames[#declinedNames+1] = k
	end
end

	
-- connects to tfm
client:once("ready", function()
    print("Ready to connect!")
    client:connect(botName, botPw)
end)

client:once("connection", function()
    print("Connected!")
    client:joinTribeHouse() --bot will be in tribehouse when connected.
	client:joinChat(chat)
	timer.setTimeout(2000, function() -- 10000
		client:sendChatMessage(chat, botName .. " has connected.")
	end)
end)

lastMessageTest = nil -- used to test if player is in black lodge
lastMessage = nil -- used when room cmd detected
lastMessageDeclined = nil -- used when declined cmd detected
recruits = {}
playerData = nil
bufferTimer = nil
whisperTimer = nil
playerListTimer = nil
tribeHouse = nil

client:on("whisperMessage", function(playerName, message) -- when whisper recieved
	if playerName == botName then
		return
	else
		if string.lower(message) == "close" and admins[playerName] then -- if bot recieves message "close" from admin
			client:sendChatMessage(chat, botName .. " has disconnected.")
			print("disconnecting...")
			client:disconnect()
		elseif string.lower(message) == "logs" and admins[playerName] then
			local declinedString = ""
			for i = 1, #declinedNames do
				if declinedNames[#declinedNames - #usersOfDecline + 1] and usersOfDecline[i] then
					declinedString = declinedString .. declinedNames[#declinedNames - #usersOfDecline + i] .. " " .. usersOfDecline[i] .. " "				print(usersOfDecline)
			        end
			end
			print(declinedString)
		end	
	end		
end)

client:on("chatMessage", function(chatName, playerName, message, playerCommunity)
    if playerName == botName or (chatName == chat and (lastMessage or lastMessageTest or lastMessageDeclined)) then return end
    lastMessageTest = playerName
    client:sendCommand("profile " .. playerName)
    timer.setTimeout(140, function() -- 700
        if tribeHouse == "Black Lodge" then
            tribeHouse = nil
            local words, c = { }, 0
            for slice in message:gmatch("%S+") do
                c = c + 1
                words[c] = slice
            end
            words[1] = words[1]:lower()
	    --print(words[1])
            if words[1] == "declined" and words[2] then -- detects the declined command
                lastMessageDeclined = playerName
                lastMessageTest = nil
                usersOfDecline[#usersOfDecline+1] = lastMessageDeclined
                declinedNames[#declinedNames + 1] = words[2]
                client:sendChatMessage(chat, playerName .. " has put " .. words[2] .. " on the declined list.")
                print(playerName .. " has put " .. words[2] .. " on the declined list.")
                lastMessageDeclined = nil
            else -- joins a room based on the message, and then finds all player's names' there
                lastMessage = playerName
                lastMessageTest = nil
                client:sendWhisper(playerName, "The possible recruits of room " .. message .. " will be whispered to you in a few moments.")
                print("[" .. playerName .. "] The possible recruits of room " .. message .. " will be whispered to you in a few moments.")
                client:sendChatMessage(chat, "The bot is now busy. Please do not enter any more room names until the bot is available again.")
                print("The bot is now busy. Please do not enter any more room names until the bot is available again.")
                client:enterRoom (message, false)
                playerListTimer = timer.setInterval(20, function() -- 100
                    if playerData then -- once playerList is loaded
                        timer.clearInterval(playerListTimer)
                        timer.setTimeout(20, function() -- 100
                            local nameList = {}
                            for k, v in pairs(playerData) do
                                nameList[#nameList+1] = v.playerName -- gets everyone's names
                            end
                            local i = 1
                            bufferTimer = timer.setInterval(200, function() -- 1000
                                client:sendCommand("profile " .. nameList[i])
                                i = i + 1								
                                if i-1 == #nameList then -- once all profile cmds are executed
                                    timer.clearInterval(bufferTimer)
                                    timer.setTimeout(200, function() -- 1000								
                                        if #recruits == 0 then
                                            print("[" .. lastMessage .. "] The bot couldn't find any recruits here.")
                                            client:sendWhisper(lastMessage, "The bot couldn't find any recruits here.")
                                            lastMessage = nil -- resets bot
                                            i = nil
                                            playerData = nil
                                            nameList = nil
                                            recruits = {}
                                            client:joinTribeHouse()
                                            client:sendChatMessage(chat, "The bot is now available again.")
                                            print("The bot is now available again.")
                                        elseif #recruits >= 4 then
                                            local j = 4
                                            whisperTimer = timer.setInterval(200, function() -- 1000
                                                print("[" .. lastMessage .. "] " .. recruits[j-3] .. ", " .. recruits[j-2] .. ", " .. recruits[j-1] .. ", " .. recruits[j])
                                                client:sendWhisper(lastMessage, recruits[j-3] .. ", " .. recruits[j-2] .. ", " .. recruits[j-1] .. ", " .. recruits[j]) -- whispers the player the recruits in groups of 4 to evade the 80 characters message limit
                                                j = j + 4
						-- print("j: "..j)		
                                                if j > #recruits then
                                                    timer.clearInterval(whisperTimer)
                                                    timer.setTimeout(200, function() -- 1000
                                                        local otherRecruits = nil
                                                        if #recruits % 4 == 3 then
                                                            otherRecruits = recruits[#recruits-2] .. ", " .. recruits[#recruits-1] .. ", " .. recruits[#recruits]
                                                        elseif #recruits % 4 == 2 then
                                                            otherRecruits = recruits[#recruits-1] .. ", " .. recruits[#recruits]
                                                        elseif #recruits % 4 == 1 then
                                                            otherRecruits = recruits[#recruits]
                                                        end
                                                        if #recruits % 4 ~= 0 then
                                                            print("[" .. lastMessage .. "] " .. otherRecruits)
                                                            client:sendWhisper(lastMessage, otherRecruits) -- whispers the rest of the recruits
                                                        end
                                                        lastMessage = nil -- resets bot
                                                        i = nil
                                                        j = nil
                                                        playerData = nil
                                                        nameList = nil
                                                        recruits = {}
                                                        client:joinTribeHouse()
                                                        print("The bot is now available again.")
                                                        client:sendChatMessage(chat, "The bot is now available again.")
                                                    end)
                                                end
                                            end)
                                        else
                                            local otherRecruits = nil
                                            if #recruits == 3 then
                                                otherRecruits = recruits[1] .. ", " .. recruits[2] .. ", " .. recruits[3]
                                            elseif #recruits == 2 then
                                                otherRecruits = recruits[1] .. ", " .. recruits[2]
                                            elseif #recruits == 1 then
                                                otherRecruits = recruits[1]
                                            end
                                            print("[" .. lastMessage .. "] " .. otherRecruits)
                                            client:sendWhisper(lastMessage, otherRecruits) -- whispers the rest of the recruits
                                            lastMessage = nil -- resets bot
                                            i = nil
                                            playerData = nil
                                            nameList = nil
                                            recruits = {}
                                            client:joinTribeHouse()
                                            print("The bot is now available again.")
                                            client:sendChatMessage(chat, "The bot is now available again.")
                                        end
                                    end)
                                end
                            end)
                        end)
                    end
                end)
            end
        end
        if lastMessageTest then
            lastMessageTest = false
        end
    end)
end)       

client:on("refreshPlayerList", function(playerList)
	if lastMessage then
		playerData = playerList -- gets list of all players in a room
	end
end)

client:on("profileLoaded", function(data)
	if lastMessageTest then
		tribeHouse = data.tribeName
	else
		if data.tribeName == "" and data.level >= 20 then -- checks if player is above lvl 20 and is not in a tribe
			valid = true
			for _,v in pairs(blacklistNames) do
				if v == data.playerName then -- checks if player is blacklisted
					--print(v)
					valid = false
					break
				end
			end
			if valid == true then
				for _,v in pairs(declinedNames) do
					if v == data.playerName then -- checks if player has declined an invite before
						valid = false
						break
					end
				end
				if valid == true then
					--print(#recruits)
					recruits[#recruits+1] = data.playerName -- new recruit!
				end
			end
		end
	end
end)

client:on("connectionFailed", function()
    client:start(ownerID, key)
end)

client:start(ownerID, key)
