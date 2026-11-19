--!strict
-- What the server tells players: toasts, sounds, receipts and celebrations, through the Remotes folder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Feedback = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local function remote(name: string): RemoteEvent
	return (ReplicatedStorage:WaitForChild("Remotes") :: Folder):WaitForChild(name) :: RemoteEvent
end

function Feedback.notify(player: Player, text: string, color: Color3?)
	remote("Notify"):FireClient(player, text, color or WHITE)
end

function Feedback.broadcast(text: string, color: Color3?)
	for _, player in Players:GetPlayers() do
		remote("Notify"):FireClient(player, text, color or WHITE)
	end
end

function Feedback.sfx(player: Player, name: string)
	remote("Sfx"):FireClient(player, name)
end

return Feedback
