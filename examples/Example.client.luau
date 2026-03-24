local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Neutron = require(ReplicatedStorage.Neutron)
local remoteFunction = ReplicatedStorage:WaitForChild("NeutronFetch")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NeutronDemo"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mount = Instance.new("Frame")
mount.Name = "Mount"
mount.BackgroundTransparency = 1
mount.Size = UDim2.fromScale(1, 1)
mount.Parent = screenGui

local fetcher = Neutron.Fetcher.fromRemoteFunction(remoteFunction)

local renderer = Neutron.new({
	fetcher = fetcher,
	rendererOptions = {
		imageResolver = function(source)
			return source
		end,
	},
})

renderer:renderUrl("https://example.com", mount)
