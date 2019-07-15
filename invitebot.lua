botName = "Hollobot#4908" -- your bot's name
botPw = "2KnightsOfTheHollow48" -- your bot's password
ownerID = "101454901" -- ownerID
key = "pcAVfk2e-Mk3plwXgE284gFW6iFfmQ9gpyVp8U9g4Mb-BqKSdED3QIvXURbRDr" -- key
chat = "blbots" -- If things get a little out of control in the #blbots chat, try changing this value to something else.
admins = {"Radioactium#0000", "Hollosou#6531", "Lanadelrey#1407", "Brooklyn#4914", "Ashbolt#0000", "Voyeur#9539", "Alfiecakes#0000", "Trivia#3603", "Floawt#0000", "Laurineeeeee#2008", "Voshk#1486", "Fluffy#3087", "Ninetailsdes#0000", "Sophsoul#0918"} -- add admins here

local timer = require("timer")
local transfromage = require("transfromage")
local client = transfromage.client()
client._handle_players = true
client:setCommunity(14) -- currently this causes the bot to join the en2 server. If you want it to join the en1 server, check the transfromage docs.

blacklistNames = {}
for line in io.lines("blacklist.txt") do 
	blacklistNames[#blacklistNames + 1] = line -- reads blacklist.txt
	print(line)
end

declinedNames = {}
local words = {}
for line in io.lines("declined.txt") do
	words[1], words[2] = line:match("(%w+) (%w+)")
	declinedNames[#declinedNames + 1] = words[1] -- reads only the first name of each line in declined.txt
end

declinedFile = io.open("declined.txt", "a") -- allows values to be appended to declined.txt

-- connects to tfm
client:once("ready", function()
    print("Ready to connect!")
    client:connect(botName, botPw)
end)

client:once("connection", function()
    print("Connected!")
    client:joinTribeHouse() --bot will be in tribehouse when connected.
	client:joinChat(chat)
	timer.setTimeout(10000, function()
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
		if string.lower(message) == "close" then -- if bot recieves message "close" from admin
			for k, v in pairs(admins) do
				if playerName == v then
					declinedFile:close()
					client:sendChatMessage(chat, botName .. " has disconnected.")
					print("disconnecting...")
					client:disconnect()
					break
				end
			end
		end
    end
end)

client:on("chatMessage", function(chatName, playerName, message, playerCommunity)
	if playerName == botName then
		return
	elseif chatName == chat then
		if lastMessage or lastMessageTest or lastMessageDeclined then
			return
		else
			lastMessageTest = playerName
			client:sendCommand("profile " .. playerName)
			timer.setTimeout(700, function()
				if tribeHouse == "Black Lodge" then
					tribeHouse = nil
					local words = {}
					words[1], words[2] = message:match("(%w+) (%w+)")
					if words[1] == "declined" and words[2] then -- detects the declined command
						lastMessageDeclined = playerName
						lastMessageTest = nil
						declinedFile:write(words[2] .. " " .. playerName, "\n")
						declinedNames[#declinedNames + 1] = words[2]
						client:sendChatMessage(chat, playerName .. "has put " .. words[2] .. " on the declined list.")
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
						playerListTimer = timer.setInterval(100, function()
							if playerData then -- once playerList is loaded
								timer.clearInterval(playerListTimer)
								timer.setTimeout(100, function()
									local nameList = {}
									for k, v in pairs(playerData) do
										nameList[#nameList+1] = v.playerName -- gets everyone's names
									end
									local i = 1
									bufferTimer = timer.setInterval(1000, function() -- experiment with this
										client:sendCommand("profile " .. nameList[i])
										i = i + 1
										if i-1 == #nameList then -- once all profile cmds are executed
											timer.clearInterval(bufferTimer)
											timer.setTimeout(1000, function()
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
													whisperTimer = timer.setInterval(1000, function()
														print("[" .. lastMessage .. "] " .. recruits[j-3] .. ", " .. recruits[j-2] .. ", " .. recruits[j-1] .. ", " .. recruits[j])
														client:sendWhisper(lastMessage, recruits[j-3] .. ", " .. recruits[j-2] .. ", " .. recruits[j-1] .. ", " .. recruits[j]) -- whispers the player the recruits in groups of 4 to evade the 80 characters message limit
														j = j + 4
														if j > #recruits then
															timer.clearInterval(whisperTimer)
															timer.setTimeout(1000, function()
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
					lastMessageTest = nil
				end
			end)
		end
	end
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
			local valid = true
			for _,v in pairs(blacklistNames) do
				if v == data.playerName then -- checks if player is blacklisted
					print(v)
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
					recruits[#recruits+1] = data.playerName -- new recruit!
				end
			end
		end
	end
end)

client:start(ownerID, key)
