-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local NeuronGUI = Neuron.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceGUI = LibStub("AceGUI-3.0")

local iconSelector
local iconList = {}


-----------------------------------------------------------------------------
--------------------------Button Editor--------------------------------------
-----------------------------------------------------------------------------

function NeuronGUI:ButtonEditPanel(tabContainer)
	Neuron:ToggleButtonEditMode(true)

	if Neuron.currentButton then
		--container to hold all of our widgets, added to our tab frame
		local settingContainer = AceGUI:Create("SimpleGroup")
		settingContainer:SetFullWidth(true)
		settingContainer:SetLayout("Flow")
		tabContainer:AddChild(settingContainer)

		--icon button that represents the currently selected icon
		local iconFrame=AceGUI:Create("Icon")
		NeuronGUI:RefreshIconPreview(iconFrame)
		iconFrame:SetImageSize(60,60)
		iconFrame:SetWidth(60)
		iconFrame:SetCallback("OnClick", function() NeuronGUI:IconFrame_OnClick() end)
		settingContainer:AddChild(iconFrame)

		--edit box to show the current macro
		local macroEditFrame = AceGUI:Create("MultiLineEditBox")
		macroEditFrame:SetLabel("Edit Macro")
		macroEditFrame:SetWidth(400)
		macroEditFrame:SetHeight(200)
		if Neuron.currentButton.data.macro_Text then
			macroEditFrame:SetText(Neuron.currentButton.data.macro_Text)
		else
			macroEditFrame:SetText("")
		end
		settingContainer:AddChild(macroEditFrame)
	end
end

-----------------------------------------------------------------------------
--------------------------Icon Selector--------------------------------------
-----------------------------------------------------------------------------

function NeuronGUI:RefreshIconPreview(iconFrame)
	--try to get the texture currently on the button itself
	local texture = Neuron.currentButton.Icon:GetTexture()
	if texture then
		iconFrame:SetImage(texture)
	else --fallback to question mark icon if nothing is found
		iconFrame:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end
end

function NeuronGUI:IconFrame_OnClick()
	if not iconSelector then
		NeuronGUI:CreateIconSelector()
	else
		iconSelector:Show()
	end
end

function NeuronGUI:CreateIconSelector()
	iconSelector = AceGUI:Create("Frame")
	iconSelector:SetTitle("Select and icon")
	iconSelector:SetCallback("OnClose", function() iconSelector:Hide() end)
	iconSelector:SetWidth(660)
	iconSelector:SetHeight(500)
	iconSelector:SetLayout("Fill") -- important!

	local scrollContainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
	scrollContainer:SetLayout("Fill") -- important!
	iconSelector:AddChild(scrollContainer)

	local iconScroll = AceGUI:Create("ScrollFrame")
	iconScroll:SetLayout("Flow") -- probably?
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:AddChild(iconScroll)

	--this is temporary. We need to populate a list of icons here

	NeuronGUI:RefreshPlayerSpellIconInfo()

	for i=1,#iconList do
		local iconFrame=AceGUI:Create("Icon")
		iconFrame:SetImage(iconList[i])
		iconFrame:SetImageSize(40,40)
		iconFrame:SetWidth(50)
		iconScroll:AddChild(iconFrame)
	end
end

function NeuronGUI:RefreshPlayerSpellIconInfo()
	wipe(iconList)
	--we need a quick function to check if a table contains a value already
	local function tContains(table, item)
		local index = 1;
		while table[index] do
			if item == table[index] then
				return 1;
			end
			index = index + 1;
		end
		return nil;
	end

	for _,v in pairs(Neuron.spellCache) do
		if v.icon and not tContains(iconList, v.icon) then
			table.insert(iconList, v.icon)
		end
	end

	for _,v in pairs(Neuron.itemCache) do
		if v.icon and not tContains(iconList, v.icon) then
			table.insert(iconList, v.icon)
		end
	end
end