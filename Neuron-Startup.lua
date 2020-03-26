--Neuron, a World of Warcraft® user interface addon.

--This file is part of Neuron.
--
--Neuron is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Neuron is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this add-on.  If not, see <https://www.gnu.org/licenses/>.
--
--Copyright for portions of Neuron are held by Connor Chenoweth,
--a.k.a Maul, 2014 as part of his original project, Ion. All other
--copyrights for Neuron are held by Britt Yazel, 2017-2019.

local DB

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")




function Neuron:Startup()

	DB = Neuron.db.profile

	Neuron:RegisterBars()

	Neuron:RegisterGUI()

	Neuron:CreateBarsAndButtons()

end



function Neuron:RegisterBars()

	--Neuron Action Bar
	Neuron:RegisterBarClass("ActionBar", "ActionBar", L["Action Bar"], "Action Button", DB.ActionBar, Neuron.ACTIONBUTTON, 250, true)

	--Neuron Bag Bar
	Neuron:RegisterBarClass("BagBar", "BagBar", L["Bag Bar"], "Bag Button", DB.BagBar, Neuron.BAGBTN, Neuron.NUM_BAG_BUTTONS, false) --Neuron.NUM_BAG_BUTTONS == 5 for retail and 6 for classic due to the keyring

	--Neuron Menu Bar
	Neuron:RegisterBarClass("MenuBar", "MenuBar", L["Menu Bar"], "Menu Button", DB.MenuBar, Neuron.MENUBTN, 11, false)

	--Neuron Pet Bar
	Neuron:RegisterBarClass("PetBar", "PetBar", L["Pet Bar"], "Pet Button", DB.PetBar, Neuron.PETBTN, 10, true)

	--Neuron XP Bar
	Neuron:RegisterBarClass("XPBar", "XPBar", L["XP Bar"], "XP Button", DB.XPBar, Neuron.XPBTN, 10, false)

	--Neuron Rep Bar
	Neuron:RegisterBarClass("RepBar", "RepBar", L["Rep Bar"], "Rep Button", DB.RepBar, Neuron.REPBTN, 10, false)

	--Neuron Cast Bar
	Neuron:RegisterBarClass("CastBar", "CastBar", L["Cast Bar"], "Cast Button", DB.CastBar, Neuron.CASTBTN, 10, false)

	--Neuron Mirror Bar
	Neuron:RegisterBarClass("MirrorBar", "MirrorBar", L["Mirror Bar"], "Mirror Button", DB.MirrorBar, Neuron.MIRRORBTN, 10, false)

	if not Neuron.isWoWClassic then
		--Neuron Zone Ability Bar
		Neuron:RegisterBarClass("ZoneAbilityBar", "ZoneAbilityBar", L["Zone Action Bar"], "Zone Action Button", DB.ZoneAbilityBar, Neuron.ZONEABILITYBTN, 1, true)

		--Neuron Extra Bar
		Neuron:RegisterBarClass("ExtraBar", "ExtraBar", L["Extra Action Bar"], "Extra Action Button", DB.ExtraBar, Neuron.EXTRABTN,1, true)

		--Neuron Exit Bar
		Neuron:RegisterBarClass("ExitBar", "ExitBar", L["Vehicle Exit Bar"], "Vehicle Exit Button", DB.ExitBar, Neuron.EXITBTN,1, false)
	end

end

function Neuron:RegisterGUI()

	--Neuron Action Bar
	Neuron:RegisterGUIOptions("ActionBar",
			{AUTOHIDE = true,
			 SHOWGRID = true,
			 SPELLGLOW = true,
			 SNAPTO = true,
			 UPCLICKS = true,
			 DOWNCLICKS = true,
			 MULTISPEC = true,
			 HIDDEN = true,
			 LOCKBAR = true,
			 TOOLTIPS = true},

			{BINDTEXT = true,
			 MACROTEXT = true,
			 COUNTTEXT = true,
			 RANGEIND = true,
			 CDTEXT = true,
			 CDALPHA = true,
			 AURAIND = true})


	--Neuron Bag Bar
	Neuron:RegisterGUIOptions("BagBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true})

	--Neuron Menu Bar
	Neuron:RegisterGUIOptions("MenuBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true})

	--Neuron Pet Bar
	Neuron:RegisterGUIOptions("PetBar",
			{AUTOHIDE = true,
			 SHOWGRID = true,
			 SNAPTO = true,
			 UPCLICKS = true,
			 DOWNCLICKS = true,
			 HIDDEN = true,
			 LOCKBAR = true,
			 TOOLTIPS = true,
			 BINDTEXT = true,
			 RANGEIND = true,
			 CDTEXT = true,
			 CDALPHA = true})

	--Neuron XP Bar
	Neuron:RegisterGUIOptions("XPBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true})

	--Neuron Rep Bar
	Neuron:RegisterGUIOptions("RepBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true })

	--Neuron Cast Bar
	Neuron:RegisterGUIOptions("CastBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true })

	--Neuron Mirror Bar
	Neuron:RegisterGUIOptions("MirrorBar",
			{AUTOHIDE = true,
			 SNAPTO = true,
			 HIDDEN = true,
			 TOOLTIPS = true })

	if not Neuron.isWoWClassic then
		--Neuron Zone Ability Bar
		Neuron:RegisterGUIOptions("ZoneAbilityBar",
				{AUTOHIDE = true,
				 SNAPTO = true,
				 UPCLICKS = true,
				 DOWNCLICKS = true,
				 HIDDEN = true,
				 TOOLTIPS = true,
				 BORDERSTYLE = true},

				{BINDTEXT = true,
				 COUNTTEXT = true,
                 CDTEXT = true,
                 CDALPHA = true})


		--Neuron Extra Bar
		Neuron:RegisterGUIOptions("ExtraBar",
				{AUTOHIDE = true,
				 SNAPTO = true,
				 UPCLICKS = true,
				 DOWNCLICKS = true,
				 HIDDEN = true,
				 TOOLTIPS = true,
				 BORDERSTYLE = true},

				{BINDTEXT = true,
				 COUNTTEXT = true,
                 CDTEXT = true,
                 CDALPHA = true})

		--Neuron Exit Bar
		Neuron:RegisterGUIOptions("ExitBar",
				{ AUTOHIDE = true,
				  SHOWGRID = false,
				  SNAPTO = true,
				  UPCLICKS = true,
				  DOWNCLICKS = true,
				  HIDDEN = true,
				  LOCKBAR = false, },

				false, 65)

	end

end

function Neuron:CreateBarsAndButtons()

	if (DB.firstRun) then

		for barClass, barDefaults in pairs(NeuronDefaultBarOptions) do
			if Neuron.registeredBarData[barClass] then --only build default bars for registered bars types (Classic doesn't use all the bar types that Retail does)
				for i, defaults in ipairs(barDefaults) do --create the bar objects
					local newBar = Neuron.BAR.new(barClass, i) --this calls the bar constructor

					--create the default button objects for a given bar with the default values
					newBar:SetDefaults(defaults)

					for buttonID=1,#defaults.buttons do
						newBar.objTemplate.new(newBar, buttonID, defaults.buttons[buttonID]) --newBar.objTemplate is something like ACTIONBUTTON or EXTRABTN, we just need to code it agnostic
					end
				end
			end

		end

		DB.firstRun = false

	else

		for barClass, barClassData in pairs (Neuron.registeredBarData) do
			for id,data in pairs(barClassData.barDB) do
				if (data ~= nil) then
					local newBar = Neuron.BAR.new(barClass, id) --this calls the bar constructor

					--create all the saved button objects for a given bar
					for buttonID=1,#newBar.DB.buttons do
						newBar.objTemplate.new(newBar, buttonID) --newBar.objTemplate is something like ACTIONBUTTON or EXTRABTN, we just need to code it agnostic
					end
				end
			end
		end
	end

end


function Neuron:Overrides()

	--bag bar overrides
	if DB.blizzbar == false then
		--hide the weird color border around bag bars
		CharacterBag0Slot.IconBorder:Hide()
		CharacterBag1Slot.IconBorder:Hide()
		CharacterBag2Slot.IconBorder:Hide()
		CharacterBag3Slot.IconBorder:Hide()

		--overwrite the Show function with a null function because it keeps coming back and won't stay hidden
		if not Neuron:IsHooked(CharacterBag0Slot.IconBorder, "Show") then
			Neuron:RawHook(CharacterBag0Slot.IconBorder, "Show", function() end, true)
		end
		if not Neuron:IsHooked(CharacterBag1Slot.IconBorder, "Show") then
			Neuron:RawHook(CharacterBag1Slot.IconBorder, "Show", function() end, true)
		end
		if not Neuron:IsHooked(CharacterBag2Slot.IconBorder, "Show") then
			Neuron:RawHook(CharacterBag2Slot.IconBorder, "Show", function() end, true)
		end
		if not Neuron:IsHooked(CharacterBag3Slot.IconBorder, "Show") then
			Neuron:RawHook(CharacterBag3Slot.IconBorder, "Show", function() end, true)
		end
	end



	--status bar overrides
	local disableDefaultCast = false
	local disableDefaultMirror = false

	for _,v in ipairs(Neuron.BARIndex) do

		if v.barType == "CastBar" then
			for _, button in ipairs(v.buttons) do
				if button then
					disableDefaultCast = true
				end
			end
		end


		if v.barType == "MirrorBar" then
			for _, button in ipairs(v.buttons) do
				if button then
					disableDefaultMirror = true
				end
			end
		end
	end


	if disableDefaultCast then
		CastingBarFrame:UnregisterAllEvents()
		CastingBarFrame:SetParent(Neuron.hiddenFrame)
	end

	if disableDefaultMirror then
		UIParent:UnregisterEvent("MIRROR_TIMER_START")
		MirrorTimer1:UnregisterAllEvents()
		MirrorTimer1:SetParent(Neuron.hiddenFrame)
		MirrorTimer2:UnregisterAllEvents()
		MirrorTimer2:SetParent(Neuron.hiddenFrame)
		MirrorTimer3:UnregisterAllEvents()
		MirrorTimer3:SetParent(Neuron.hiddenFrame)
	end


end