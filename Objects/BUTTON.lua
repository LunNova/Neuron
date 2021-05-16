-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2021 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

---@class BUTTON : CheckButton @define BUTTON as inheriting from CheckButton
local BUTTON = setmetatable({}, {__index = CreateFrame("CheckButton")}) --this is the metatable for our button object
Neuron.BUTTON = BUTTON

local SKIN = LibStub("Masque", true)
local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")

LibStub("AceBucket-3.0"):Embed(BUTTON)
LibStub("AceEvent-3.0"):Embed(BUTTON)
LibStub("AceTimer-3.0"):Embed(BUTTON)
LibStub("AceHook-3.0"):Embed(BUTTON)


---Constructor: Create a new Neuron BUTTON object (this is the base object for all Neuron button types)
---@param bar BAR @Bar Object this button will be a child of
---@param buttonID number @Button ID that this button will be assigned
---@param baseObj BUTTON @Base object class for this specific button
---@param barClass string @Class type for the bar the button will be on
---@param objType string @Type of object this button will be
---@param template string @The template name that this frame will derive from
---@return BUTTON @ A newly created BUTTON object
function BUTTON.new(bar, buttonID, baseObj, barClass, objType, template)
	local newButton
	local newButtonName = bar:GetName().."_"..objType..buttonID

	if _G[newButtonName] then --try to reuse a current frame if it exists instead of making a new one
		newButton = _G[newButtonName]
	else
		newButton = CreateFrame("CheckButton", newButtonName, bar, template) --create the new button frame using the desired parameters
		setmetatable(newButton, {__index = baseObj})
	end

	--crosslink the bar and button for easy referencing
	bar.buttons[buttonID] = newButton
	newButton.bar = bar

	newButton.class = barClass
	newButton.id = buttonID
	newButton.objType = objType:upper()

	if not bar.data.buttons[buttonID] then --if the database for a bar doesn't exist (because it's a new bar) make a new table
		bar.data.buttons[buttonID] = {}
	end
	newButton.DB = bar.data.buttons[buttonID] --set our button database table as the DB for our object

	--this is a hack to add some unique information to an object so it doesn't get wiped from the database
	if newButton.DB.config then
		newButton.DB.config.date = date("%m/%d/%y %H:%M:%S")
	end

	return newButton
end

-------------------------------------------------
-----Base Methods that all buttons have----------
---These will often be overwritten per bar type--
------------------------------------------------

function BUTTON.ChangeSelectedButton(newButton)
	if newButton and newButton ~= Neuron.currentButton then
		if Neuron.currentButton and Neuron.currentButton.bar ~= newButton.bar then
			local bar = Neuron.currentButton.bar

			if bar.handler:GetAttribute("assertstate") then
				bar.handler:SetAttribute("state-"..bar.handler:GetAttribute("assertstate"), bar.handler:GetAttribute("activestate") or "homestate")
			end

			newButton.bar.handler:SetAttribute("fauxstate", bar.handler:GetAttribute("activestate"))
		end

		Neuron.currentButton = newButton
		Neuron.currentBar = newButton.bar
		newButton.editFrame.select:Show()
	elseif not newButton then
		Neuron.currentButton = nil
		for _, bar in pairs(Neuron.bars) do
			for _, button in pairs(bar.buttons) do
				if button.editFrame then
					button.editFrame.select:Hide()
				end
			end
		end
	end

	for _, bar in pairs(Neuron.bars) do
		for _, button in pairs(bar.buttons) do
			if button.editFrame then
				if newButton and button.editFrame ~= newButton.editFrame then
					button.editFrame.select:Hide()
				end
			end
		end
	end
end

function BUTTON:CancelCooldownTimer(stopAnimation)
	--cleanup so on state changes the cooldowns don't persist
	if self:TimeLeft(self.Cooldown.cooldownTimer) ~= 0 then
		self:CancelTimer(self.Cooldown.cooldownTimer)
	end

	if self:TimeLeft(self.Cooldown.cooldownUpdateTimer) ~= 0 then
		self:CancelTimer(self.Cooldown.cooldownUpdateTimer)
	end

	self.Countdown:SetText("")

	self.Cooldown.showCountdownTimer = false
	self.Cooldown.showCountdownAlpha = false

	--clear previous sweeping cooldown animations
	if stopAnimation then
		CooldownFrame_Clear(self.Cooldown) --clear the cooldown frame
	end
end

function BUTTON:SetCooldownTimer(start, duration, enable, modrate, showCountdownTimer, color1, color2, showCountdownAlpha, charges, maxCharges)
	if not self.isShown then --if the button isn't shown, don't do set any cooldowns
		--if there's currently a timer, cancel it
		self:CancelCooldownTimer(true)
		return
	end

	if start and start > 0 and duration > 0 and enable > 0 then

		if duration > 2 then --sets non GCD cooldowns
			if charges and charges > 0 and maxCharges > 1 then
				self.Cooldown:SetDrawSwipe(false);
				CooldownFrame_Set(self.Cooldown, start, duration, enable, true, modrate) --set clock style cooldown animation. Show Draw Edge.
			else
				self.Cooldown:SetDrawSwipe(true);
				CooldownFrame_Set(self.Cooldown, start, duration, enable, true, modrate) --set clock style cooldown animation for ability cooldown. Show Draw Edge.
			end
		else --sets GCD cooldowns
			self.Cooldown:SetDrawSwipe(true);
			CooldownFrame_Set(self.Cooldown, start, duration, enable, false, modrate) --don't show the Draw Edge for the GCD
		end

		--this is only for abilities that have CD's >4 sec. Any less than that and we don't want to track the CD with text or alpha, just with the standard animation
		if duration >= Neuron.TIMERLIMIT then --if spells have a cooldown less than 4sec then don't show a full cooldown

			if showCountdownTimer or showCountdownAlpha then --only set a timer if we explicitely want to (this saves CPU for a lot of people)

				--set a local variable to the boolean state of either Timer or the Alpha
				self.Cooldown.showCountdownTimer = showCountdownTimer
				self.Cooldown.showCountdownAlpha = showCountdownAlpha


				self.Cooldown.charges = charges or 0 --used to know if we should set alpha on the button (if cdAlpha is enabled) immediately, or if we need to wait for charges to run out

				--clear old timer before starting a new one
				if self:TimeLeft(self.Cooldown.cooldownTimer) ~= 0 then
					self:CancelTimer(self.Cooldown.cooldownTimer)
				end

				--Get the remaining time left so when we re-call the timer when switching back to a state it has the correct time left instead of the full time
				local timeleft = duration-(GetTime()-start)

				--safety check in case some timeleft value comes back ridiculously long. This happened once after a weird game glitch, it came back as like 42000000. We should cap it at 1 day max (even that's overkill)
				if timeleft > 86400 then
					timeleft = 86400
				end

				--set timer that is both our cooldown counter, but also the cancels the repeating updating timer at the end
				self.Cooldown.cooldownTimer = self:ScheduleTimer(function() self:CancelTimer(self.Cooldown.cooldownUpdateTimer) end, timeleft + 1) --add 1 to the length of the timer to keep it going for 1 second once the spell cd is over (to fully finish the animations/alpha transition)

				--clear old timer before starting a new one
				if self:TimeLeft(self.Cooldown.cooldownUpdateTimer) ~= 0 then
					self:CancelTimer(self.Cooldown.cooldownUpdateTimer)
				end

				--schedule a repeating timer that is physically keeping track of the countdown and switching the alpha and count text
				self.Cooldown.cooldownUpdateTimer = self:ScheduleRepeatingTimer("CooldownCounterUpdate", 0.20)
				self.Cooldown.normalcolor = color1
				self.Cooldown.expirecolor = color2
			else
				self.Cooldown.showCountdownTimer = false
				self.Cooldown.showCountdownAlpha = false
			end

		else
			self:CancelCooldownTimer(false)
		end
	else
		self:CancelCooldownTimer(true)
	end
end

---this function is called by a repeating timer set in SetCooldownTimer every 0.2sec, which is autoGmatically is set to terminate 1sec after the cooldown timer ends
---this function's job is to overlay the countdown text on a button and set the button's cooldown alpha
function BUTTON:CooldownCounterUpdate()
	local coolDown, formatted, size

	local normalcolor = self.Cooldown.normalcolor
	local expirecolor = self.Cooldown.expirecolor

	coolDown = self:TimeLeft(self.Cooldown.cooldownTimer) - 1 --subtract 1 from the timer because we added 1 in SetCooldownTimer to keep the timer runing for 1 extra second after the spell

	if self.Cooldown.showCountdownTimer then --check if flag is set, otherwise skip

		if coolDown < 1 then
			if coolDown <= 0 then
				self.Countdown:SetText("")
				self.Cooldown.expirecolor = nil
				self.Cooldown.cdsize = nil

			elseif coolDown > 0 then
				if self.Cooldown.alphafade then
					self.Cooldown:SetAlpha(coolDown)
				end
			end
		else
			if coolDown >= 86400 then --append a "d" if the timer is longer than 1 day
				formatted = string.format( "%.0f", coolDown/86400)
				formatted = formatted.."d"
				size = self:GetWidth()*0.3
				self.Countdown:SetTextColor(normalcolor[1], normalcolor[2], normalcolor[3])

			elseif coolDown >= 3600 then --append a "h" if the timer is longer than 1 hour
				formatted = string.format( "%.0f",coolDown/3600)
				formatted = formatted.."h"
				size = self:GetWidth()*0.3
				self.Countdown:SetTextColor(normalcolor[1], normalcolor[2], normalcolor[3])

			elseif coolDown >= 60 then --append a "m" if the timer is longer than 1 min
				formatted = string.format( "%.0f",coolDown/60)
				formatted = formatted.."m"
				size = self:GetWidth()*0.3
				self.Countdown:SetTextColor(normalcolor[1], normalcolor[2], normalcolor[3])

			elseif coolDown >=6 then --this is the 'normal' countdown text state
				formatted = string.format( "%.0f",coolDown)
				size = self:GetWidth()*0.45
				self.Countdown:SetTextColor(normalcolor[1], normalcolor[2], normalcolor[3])

			elseif coolDown < 6 then --this is the countdown text state but with the text larger and set to the expire color (usually red)
				formatted = string.format( "%.0f",coolDown)
				size = self:GetWidth()*0.6
				if expirecolor then
					self.Countdown:SetTextColor(expirecolor[1], expirecolor[2], expirecolor[3])
					expirecolor = nil
				end

			end

			if not self.Cooldown.cdsize or self.Cooldown.cdsize ~= size then
				self.Countdown:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
				self.Cooldown.cdsize = size
			end

			self.Cooldown.timer:SetText(formatted)

		end
	end

	if self.Cooldown.showCountdownAlpha and self.Cooldown.charges == 0 then --check if flag is set and if charges are nil or zero, otherwise skip
		if self.Cooldown.showCountdownAlpha and self.Cooldown.charges == 0 then --check if flag is set and if charges are nil or zero, otherwise skip

			if coolDown > 0 then
				self:SetAlpha(0.2)
			else
				self:SetAlpha(1)
			end
		else
			self:SetAlpha(1)
		end
	end
end

function BUTTON:LoadDataFromDatabase(curSpec, curState)
	self.config = self.DB.config
	self.keys = self.DB.keys

	if self.class ~= "ActionBar" then
		self.data = self.DB.data
	else
		self.statedata = self.DB[curSpec] --all of the states for a given spec
		self.data = self.statedata[curState] --loads a single state of a single spec into self.data

		for state, data in pairs(self.statedata) do
			self:SetAttribute(state.."-macro_Text", data.macro_Text)
			self:SetAttribute(state.."-actionID", data.actionID)
		end
	end
end

function BUTTON:SetDefaults(defaults)
	if not defaults then
		return
	end

	if defaults.config then
		for k, v in pairs(defaults.config) do
			self.DB.config[k] = v
		end
	end

	if defaults.keys then
		for k, v in pairs(defaults.keys) do
			self.DB.keys[k] = v
		end
	end
end

function BUTTON:SetSkinned(flyout)
	if SKIN then
		local btnData = {
			Normal = self.Normal,
			Icon = self.Icon,
			HotKey = self.Hotkey,
			Count = self.Count,
			Name = self.Name,
			Border = self.Border,
			Shine = self.Shine,
			Cooldown = self.Cooldown,
			AutoCastable = self.AutoCastable,
			Checked = self.Checked,
			Pushed = self.Pushed,
			Disabled = self:GetDisabledTexture(),
			Highlight = self.Highlight,
		}
		if flyout then
			SKIN:Group("Neuron", self.anchor.bar.data.name):AddButton(self, btnData, "Action")
		else
			SKIN:Group("Neuron", self.bar.data.name):AddButton(self, btnData, "Action")
		end
	end
end

function BUTTON:HasAction()
	if self.actionID then
		if self.actionID == 0 then
			return true
		elseif HasAction(self.actionID) then
			return true
		elseif self.class == "PetBar" and GetPetActionInfo(self.actionID) then
			return true
		end
	elseif self.spell or self.item then
		return true
	else
		return false
	end
end


-----------------------------------------------------------------------------------------
------------------------------------- Update Functions ----------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateAll()
	self:UpdateData()
	self:UpdateIcon()
	self:UpdateStatus()
	self:UpdateCooldown()
	self:UpdateUsable()
end

function BUTTON:UpdateData()
	-- empty --
end

function BUTTON:UpdateNormalTexture()
	local actionTexture, noactionTexture

	if self.__MSQ_NormalSkin then
		actionTexture = self.__MSQ_NormalSkin.Texture
		noactionTexture = self.__MSQ_NormalSkin.Texture.EmptyTexture
	else
		actionTexture = "Interface\\Buttons\\UI-Quickslot2"
		noactionTexture = "Interface\\Buttons\\UI-Quickslot"
	end

	if self:HasAction() then
		self:SetNormalTexture(actionTexture or "")
		self:GetNormalTexture():SetVertexColor(1,1,1,1)
	else
		self:SetNormalTexture(noactionTexture or "")
		self:GetNormalTexture():SetVertexColor(1,1,1,0.5)
	end
end

function BUTTON:UpdateVisibility()
	if self.isShown or Neuron.barEditMode or (Neuron.buttonEditMode and self.editFrame) or (Neuron.bindingMode and self.keybindFrame) then
		self.isShown = true
	else
		self.isShown = false
	end

	if self.isShown then
		self:SetAlpha(1)
	else
		self:SetAlpha(0)
	end
end

-----------------------------------------------------------------------------------------
------------------------------------- Set Count/Charge ----------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateCount()
	if self.actionID then
		self:UpdateActionCount()
	elseif self.spell then
		self:UpdateSpellCount()
	elseif self.item then
		self:UpdateItemCount()
	else
		self.Count:SetText("")
	end
end


---Updates the buttons "count", i.e. the spell charges
function BUTTON:UpdateSpellCount()
	local charges, maxCharges = GetSpellCharges(self.spell)
	local count = GetSpellCount(self.spell)

	if maxCharges and maxCharges > 1 then
		self.Count:SetText(charges)
	elseif count and count > 0 then
		self.Count:SetText(count)
	else
		self.Count:SetText("")
	end
end


---Updates the buttons "count", i.e. the item stack size
function BUTTON:UpdateItemCount()
	local count = GetItemCount(self.item,nil,true)

	if count and count > 1 then
		self.Count:SetText(count)
	else
		self.Count:SetText("")
	end
end


function BUTTON:UpdateActionCount()
	local count = GetActionCount(self.actionID)

	if count and count > 0 then
		self.Count:SetText(count)
	else
		self.Count:SetText("")
	end
end

-----------------------------------------------------------------------------------------
------------------------------------- Set Cooldown --------------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateCooldown()
	if self.actionID then
		self:UpdateActionCooldown()
	elseif self.spell then
		self:UpdateSpellCooldown()
	elseif self.item then
		self:UpdateItemCooldown()
	else
		--this is super important for removing CD's from empty buttons, like when switching states. You don't want the CD from one state to show on a different state.
		self:CancelCooldownTimer(true)
	end
end

function BUTTON:UpdateSpellCooldown()
	if self.spell and self.isShown then
		local start, duration, enable, modrate = GetSpellCooldown(self.spell)
		local charges, maxCharges, chStart, chDuration, chargemodrate = GetSpellCharges(self.spell)

		if charges and maxCharges and maxCharges > 0 and charges < maxCharges then
			self:SetCooldownTimer(chStart, chDuration, enable, chargemodrate, self.bar:GetShowCooldownText(), self.bar:GetCooldownColor1(), self.bar:GetCooldownColor2(), self.bar:GetShowCooldownAlpha(), charges, maxCharges) --only evoke charge cooldown (outer border) if charges are present and less than maxCharges (this is the case with the GCD)
		else
			self:SetCooldownTimer(start, duration, enable, modrate, self.bar:GetShowCooldownText(), self.bar:GetCooldownColor1(), self.bar:GetCooldownColor2(), self.bar:GetShowCooldownAlpha()) --call standard cooldown, handles both abilty cooldowns and GCD
		end
	else
		self:CancelCooldownTimer(true)
	end
end

function BUTTON:UpdateItemCooldown()
	if self.item and self.isShown then
		local start, duration, enable, modrate
		if Neuron.itemCache[self.item:lower()] then
			start, duration, enable, modrate = GetItemCooldown(Neuron.itemCache[self.item:lower()])
		else
			local itemID = GetItemInfoInstant(self.item)
			start, duration, enable, modrate = GetItemCooldown(itemID)
		end
		self:SetCooldownTimer(start, duration, enable, modrate, self.bar:GetShowCooldownText(), self.bar:GetCooldownColor1(), self.bar:GetCooldownColor2(), self.bar:GetShowCooldownAlpha())
	else
		self:CancelCooldownTimer(true)
	end
end

function BUTTON:UpdateActionCooldown()
	if self.actionID and self.isShown then
		if HasAction(self.actionID) then
			local start, duration, enable, modrate = GetActionCooldown(self.actionID)
			self:SetCooldownTimer(start, duration, enable, modrate, self.bar:GetShowCooldownText(), self.bar:GetCooldownColor1(), self.bar:GetCooldownColor2(), self.bar:GetShowCooldownAlpha())
		end
	else
		self:CancelCooldownTimer(true)
	end
end

-----------------------------------------------------------------------------------------
------------------------------------- Set Usable ----------------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateUsable()
	if Neuron.buttonEditMode or Neuron.bindingMode then
		self.Icon:SetVertexColor(0.2, 0.2, 0.2)
	elseif self.actionID then
		self:UpdateUsableAction()
	elseif self.spell then
		self:UpdateUsableSpell()
	elseif self.item then
		self:UpdateUsableItem()
	else
		self.Icon:SetVertexColor(1.0, 1.0, 1.0)
	end
end

function BUTTON:UpdateUsableSpell()
	local isUsable, notEnoughMana = IsUsableSpell(self.spell)

	if notEnoughMana and self.bar:GetManaColor() then
		self.Icon:SetVertexColor(self.bar:GetManaColor()[1], self.bar:GetManaColor()[2], self.bar:GetManaColor()[3])
	elseif isUsable then
		if not self.rangeInd or IsSpellInRange(self.spell, self.unit)==1 then
			self.Icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif self.bar:GetShowRangeIndicator() and IsSpellInRange(self.spell, self.unit) == 0 then
			self.Icon:SetVertexColor(self.bar:GetRangeColor()[1], self.bar:GetRangeColor()[2], self.bar:GetRangeColor()[3])
		elseif self.bar:GetShowRangeIndicator() and Neuron.spellCache[self.spell:lower()] and IsSpellInRange(Neuron.spellCache[self.spell:lower()].index,"spell", self.unit) == 0 then
			self.Icon:SetVertexColor(self.bar:GetRangeColor()[1], self.bar:GetRangeColor()[2], self.bar:GetRangeColor()[3])
		else
			self.Icon:SetVertexColor(1.0, 1.0, 1.0)
		end
	else
		self.Icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

function BUTTON:UpdateUsableItem()
	local isUsable, notEnoughMana = IsUsableItem(self.item)

	--for some reason toys don't show as usable items, so this is a workaround for that
	if not isUsable then
		local itemID = GetItemInfoInstant(self.item)
		if not Neuron.isWoWClassic and not Neuron.isWoWClassic_TBC and itemID and PlayerHasToy(itemID) then
			isUsable = true
		end
	end

	if notEnoughMana and self.bar:GetManaColor() then
		self.Icon:SetVertexColor(self.bar:GetManaColor()[1], self.bar:GetManaColor()[2], self.bar:GetManaColor()[3])
	elseif isUsable then
		if self.bar:GetShowRangeIndicator() and IsItemInRange(self.item, self.unit) == 0 then
			self.Icon:SetVertexColor(self.bar:GetRangeColor()[1], self.bar:GetRangeColor()[2], self.bar:GetRangeColor()[3])
		elseif Neuron.itemCache[self.item:lower()] and self.bar:GetShowRangeIndicator() and IsItemInRange(Neuron.itemCache[self.item:lower()], self.unit) == 0 then
			self.Icon:SetVertexColor(self.bar:GetRangeColor()[1], self.bar:GetRangeColor()[2], self.bar:GetRangeColor()[3])
		else
			self.Icon:SetVertexColor(1.0, 1.0, 1.0)
		end
	else
		self.Icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

function BUTTON:UpdateUsableAction()
	if self.actionID == 0 then
		self.Icon:SetVertexColor(1.0, 1.0, 1.0)
		return
	end

	local isUsable, notEnoughMana = IsUsableAction(self.actionID)

	if notEnoughMana and self.bar:GetManaColor() then
		self.Icon:SetVertexColor(self.bar:GetManaColor()[1], self.bar:GetManaColor()[2], self.bar:GetManaColor()[3])
	elseif isUsable then
		if self.bar:GetShowRangeIndicator() and IsActionInRange(self.spell, self.unit) == 0 then
			self.Icon:SetVertexColor(self.bar:GetRangeColor()[1], self.bar:GetRangeColor()[2], self.bar:GetRangeColor()[3])
		else
			self.Icon:SetVertexColor(1.0, 1.0, 1.0)
		end
	else
		self.Icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

-----------------------------------------------------------------------------------------
-------------------------------------- Set Icon -----------------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateIcon()
	if self.actionID then
		self:UpdateActionIcon()
	elseif self.data.macro_Icon then
		self.Icon:SetTexture(self.data.macro_Icon)
		self.Icon:Show()
	elseif self.spell then
		self:UpdateSpellIcon()
	elseif self.item then
		self:UpdateItemIcon()
	else
		self.Name:SetText("")
		self.Icon:SetTexture("")
		self.Icon:Hide()
		self.Border:Hide()
	end

	--make sure our button gets the correct Normal texture if we're not using a Masque skin
	self:UpdateNormalTexture()
end

function BUTTON:UpdateSpellIcon()
	local texture = GetSpellTexture(self.spell)

	if not texture then
		if Neuron.spellCache[self.spell:lower()] then
			texture = Neuron.spellCache[self.spell:lower()].icon
		end
	end

	if texture then
		self.Icon:SetTexture(texture)
	else
		self.Icon:SetTexture("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end
	self.Icon:Show()
end

function BUTTON:UpdateItemIcon()
	local texture = GetItemIcon(self.item)

	if not texture then
		if Neuron.itemCache[self.item:lower()] then
			texture = GetItemIcon("item:"..Neuron.itemCache[self.item:lower()]..":0:0:0:0:0:0:0")
		end
	end

	if texture then
		self.Icon:SetTexture(texture)
	else
		self.Icon:SetTexture("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end

	self.Icon:Show()

	if IsEquippedItem(self.item) then --makes the border green when item is equipped and dragged to a button
		self.Border:SetVertexColor(0, 1.0, 0, 0.2)
		self.Border:Show()
	else
		self.Border:Hide()
	end
end

function BUTTON:UpdateActionIcon()
	local texture

	if HasAction(self.actionID) then
		texture = GetActionTexture(self.actionID)
	end

	if texture then
		self.Icon:SetTexture(texture)
	else
		--self.Icon:SetTexture("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
		self.Icon:SetTexture("")
	end

	self.Icon:Show()
end

-----------------------------------------------------------------------------------------
-------------------------------------- Set Status ---------------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateStatus()
	if self.actionID then
		self:UpdateActionStatus()
	elseif self.data.macro_BlizzMacro then
		self.Name:SetText(self.data.macro_Name)
	elseif self.data.macro_EquipmentSet then
		self.Name:SetText(self.data.macro_Name)
	elseif self.spell then
		self:UpdateSpellStatus()
	elseif self.item then
		self:UpdateItemStatus()
	else
		self:SetChecked(false)
		self.Name:SetText("")
		self.Count:SetText("")
	end
end

function BUTTON:UpdateSpellStatus()
	if IsCurrentSpell(self.spell) or IsAutoRepeatSpell(self.spell) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	self.Name:SetText(self.data.macro_Name)
	self:UpdateCount()
	self:UpdateUsable()
end

function BUTTON:UpdateItemStatus()
	if IsCurrentItem(self.item) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	self.Name:SetText(self.data.macro_Name)
	self:UpdateCount()
	self:UpdateUsable()
end

function BUTTON:UpdateActionStatus()
	local name

	if self.actionID then
		if IsCurrentAction(self.actionID) or IsAutoRepeatAction(self.actionID) then
			self:SetChecked(true)
		else
			self:SetChecked(false)
		end

		--find out the action name
		local type, id, _ = GetActionInfo(self.actionID)
		if type == "spell" then
			name = GetSpellInfo(id)
		elseif type == "item" then
			name = GetItemInfo(id)
		end
	else
		self:SetChecked(false)
	end

	if name then
		self.Name:SetText(name)
	else
		self.Name:SetText("")
	end

	self:UpdateUsable()
end

-----------------------------------------------------------------------------------------
------------------------------------- Set Tooltip ---------------------------------------
-----------------------------------------------------------------------------------------

function BUTTON:UpdateTooltip()
	if self.bar:GetTooltipOption() ~= "off" then --if the bar isn't showing tooltips, don't proceed

		--if we are in combat and we don't have tooltips enable in-combat, don't go any further
		if InCombatLockdown() and not self.bar:GetTooltipCombat() then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if self.actionID then
			self:UpdateActionTooltip()
		elseif self.data.macro_BlizzMacro then
			GameTooltip:SetText(self.data.macro_Name)
		elseif self.data.macro_EquipmentSet then
			GameTooltip:SetEquipmentSet(self.data.macro_EquipmentSet)
			GameTooltip:Show()
		elseif self.spell then
			self:UpdateSpellTooltip()
		elseif self.item then
			self:UpdateItemTooltip()
		elseif self.data.macro_Text and #self.data.macro_Text > 0 then
			GameTooltip:SetText(self.data.macro_Name)
		end

		GameTooltip:Show()
	end
end

function BUTTON:UpdateSpellTooltip()
	if self.spell and self.spellID then --try to get the correct spell from the spellbook first
		if self.bar:GetTooltipOption() == "normal" then
			GameTooltip:SetSpellByID(self.spellID)
		elseif self.bar:GetTooltipOption() == "minimal" then
			GameTooltip:SetText(self.spell, 1, 1, 1)
		end
	elseif Neuron.spellCache[self.spell:lower()] then --if the spell isn't in the spellbook, check our spell cache
		if self.bar:GetTooltipOption() == "normal" then
			GameTooltip:SetSpellByID(Neuron.spellCache[self.spell:lower()].spellID)
		elseif self.bar:GetTooltipOption() == "minimal" then
			GameTooltip:SetText(Neuron.spellCache[self.spell:lower()].spellName, 1, 1, 1)
		end
	else
		GameTooltip:SetText(UNKNOWN, 1, 1, 1)
	end
end

function BUTTON:UpdateItemTooltip()
	local name, link = GetItemInfo(self.item)
	if name and link then
		if self.bar:GetTooltipOption() == "normal" then
			GameTooltip:SetHyperlink(link)
		elseif self.bar:GetTooltipOption() == "minimal" then
			GameTooltip:SetText(name, 1, 1, 1)
		end
	elseif Neuron.itemCache[self.item:lower()] then
		if self.bar:GetTooltipOption() == "normal" then
			GameTooltip:SetHyperlink("item:"..Neuron.itemCache[self.item:lower()]..":0:0:0:0:0:0:0")
		elseif self.bar:GetTooltipOption() == "minimal" then
			GameTooltip:SetText(Neuron.itemCache[self.item:lower()], 1, 1, 1)
		end
	end
end

function BUTTON:UpdateActionTooltip()
	if HasAction(self.actionID) then
		if self.bar:GetTooltipOption() == "normal" or elf.bar:GetTooltipOption() == "minimal" then
			GameTooltip:SetAction(self.actionID)
		end
	end
end
