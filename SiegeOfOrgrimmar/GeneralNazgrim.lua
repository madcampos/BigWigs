--[[
TODO:
	look for event for add waves - none atm 10N PTR
	maybe do target scanning on new waves, to start some short initial bars for add abilities?
	rethink proximity for different difficulties
	EJ says 10% new forces, but there is a special yell at 30% too: "Omega squad, kill them now!" look into it during further testing - look into these extra waves
]]--

if GetBuildInfo() ~= "5.4.0" then return end -- 4th return is 50300 on the PTR ATM so can't use that
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("General Nazgrim", 953, 850)
if not mod then return end
mod:RegisterEnableMob(71515, 71715, 71516, 71517, 71518, 71519) -- General Nazgrim, Orgrimmar Faithful, Kor'kron Ironblade, Kor'kron Arcweaver, Kor'kron Assassin, Kor'kron Warshaman

--------------------------------------------------------------------------------
-- Locals
--

local marksUsed = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.custom_off_bonecracker_marks = "Bonecracker"
	L.custom_off_bonecracker_marks_desc = "To help healing assignments, mark the people who have Bonecracker on them with %s%s%s%s%s%s%s (in that order)(not all marks may be used), requires promoted or leader."

	L.stance_bar = "%s (NOW: %s)"

	L.adds_trigger1 = "Defend the gate!"
	L.adds_trigger2 = "Rally the forces!"
	L.adds_trigger3 = "Next squad, to the front!"
	L.adds_trigger4 = "Warriors, on the double!"
	L.adds_trigger5 = "Kor'kron, at my side!"

	L.chain_heal, L.chain_heal_desc = EJ_GetSectionInfo(7935)
	L.chain_heal_icon = 1064
	L.chain_heal_message = "Your focus is casting Chain Heal!"

	L.arcane_shock, L.arcane_shock_desc = EJ_GetSectionInfo(7928)
	L.arcane_shock_icon = 114003
	L.arcane_shock_message = "Your focus is casting Arcane Shock!"

	L.focus_only = "|cffff0000Focus target alerts only.|r "
end
L = mod:GetLocale()
L.custom_off_bonecracker_marks_desc = L.custom_off_bonecracker_marks_desc:format( -- XXX cut down the number of marks used once we know the max amount used in 25H
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_2.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_4.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_5.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6.blp:15\124t",
	"\124TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcon_7.blp:15\124t"
)
L.chain_heal_desc = L.focus_only..L.chain_heal_desc
L.arcane_shock_desc = L.focus_only..L.arcane_shock_desc

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		143484, {143716, "FLASH"}, 143536, {143872, "FLASH", "SAY"}, 143503,
		"custom_off_bonecracker_marks",
		-7920, {-7933, "FLASH"}, {143475, "FLASH"}, "chain_heal", 143474, {143431, "DISPEL"}, 143432,
		{143494, "TANK_HEALER"}, {143638, "HEALER"}, -7915, "proximity", "berserk", "bosskill",
	}, {
		[143484] = -7909,
		["custom_off_bonecracker_marks"] = L.custom_off_bonecracker_marks,
		[-7920] = -7920,
		[143494] = "general",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")

	-- Adds
	self:Log("SPELL_CAST_START", "ArcaneShock", 143432)
	self:Log("SPELL_CAST_START", "ChainHeal", 143473)
	self:Log("SPELL_AURA_APPLIED", "Fixate", 143431)
	self:Log("SPELL_CAST_SUCCESS", "HealingTideTotem", 143474)
	self:Log("SPELL_CAST_START", "ChainHeal", 143473)
	self:Log("SPELL_CAST_SUCCESS", "EarthShield", 143475)
	self:Log("SPELL_AURA_APPLIED", "Fixate", 143480)
	self:Yell("Adds", L.adds_trigger1, L.adds_trigger2, L.adds_trigger3, L.adds_trigger4, L.adds_trigger5)
	-- Boss
	self:Log("SPELL_CAST_START", "WarSong", 143503)
	self:Log("SPELL_CAST_SUCCESS", "Ravager", 143872) -- _START has no destName but boss has target, so that could be better, but since this can target pets, and it takes 2 sec before any damage is done after _SUCCESS I guess we can live with using _SUCCESS over _START here
	self:Log("SPELL_SUMMON", "Banner", 143501) -- XXX this is a tiny bit faster sometimes than _SUCCESS however it's spellId does not match up with the rest atm, so pay attention in case this breaks
	self:Log("SPELL_DAMAGE", "HeroicShockwaveDamage", 143716)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "HeroicShockwave", "boss1") -- faster than _SUCCESS
	self:Log("SPELL_AURA_APPLIED", "CoolingOff", 143484)
	self:Log("SPELL_AURA_APPLIED", "Stances", 143589, 143594, 143593) -- Battle, Berserker, Defensive
	self:Log("SPELL_AURA_APPLIED", "BoneCrackerApplied", 143638)
	self:Log("SPELL_AURA_Removed", "BoneCrackerRemoved", 143638)
	self:Log("SPELL_CAST_START", "BoneCracker", 143638)
	self:Log("SPELL_AURA_APPLIED", "SunderingBlow", 143494)
	self:Log("SPELL_AURA_APPLIED_DOSE", "SunderingBlow", 143494)

	self:Death("Win", 71515)
end

function mod:OnEngage()
	self:OpenProximity("proximity", 10) -- Heroic Shockwave , Magistrike is 8 yard having a constant proximity meter might be too much for LFR
	self:Berserk(600) -- XXX Assumed
	wipe(marksUsed)
	self:CDBar(143494, 10) -- Sundering Blow
	self:Bar(143638, 15.5)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- Adds

function mod:ArcaneShock(args)
	if UnitGUID("focus") == args.sourceGUID then
		self:Message("arcane_shock", "Personal", "Alert", L["arcane_shock_message"], args.spellId)
	end
end

do
	local prev = 0
	function mod:Magistrike(args)
		local t = GetTime()
		if t-prev > 3 and self:Dispeller("magic", nil, args.spellId) then -- don't spam
			prev = t
			self:Message(args.spellId, "Important", "Alarm", args.spellName, args.spellId)
		end
	end
end

function mod:HealingTideTotem(args)
	self:Message(args.spellId, "Attention")
end

function mod:ChainHeal(args)
	if UnitGUID("focus") == args.sourceGUID then
		self:Message("chain_heal", "Personal", "Alert", L["chain_heal_message"], args.spellId)
	end
end

function mod:EarthShield(args)
	local offensiveDispeller = self:Dispeller("magic", true)
	self:Message(args.spellId, "Positive", offensiveDispeller and "Warning")
	if offensiveDispeller then
		self:Flash(args.spellId) -- for pulse (best would be pulse only no flash :S)
	end
end

function mod:Fixate(args)
	self:TargetMessage(-7933, args.destName, "Attention", "Info")
	if self:Me(args.destGUID) then
		self:Flash(-7933)
	end
end

function mod:Adds()
	self:Bar(-7920, 46, nil, "achievement_guildperk_everybodysfriend")
	self:Message(-7920, "Neutral", "Long")
end

-- Boss

function mod:WarSong(args)
	self:Bar(args.spellId, 3, CL["cast"]:format(args.spellName))
	self:Message(args.spellId, "Important", "Warning")
end

function mod:Ravager(args)
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Say(args.spellId)
	end
	if self:Range(args.destName) < 6 then
		self:RangeMessage(args.spellId)
		self:Flash(args.spellId)
	else
		self:TargetMessage(args.spellId, args.destName, "Urgent", "Alarm")
	end
end

function mod:Banner(args)
	self:Message(143536, "Attention", "Alert")
end

do
	local timer, shockwaveTarget = nil, nil
	local function warnShockwave(player, guid)
		if mod:Me(guid) then
			mod:Flash(143716)
		end
		-- 5 is assumed, also a circular distance check is not the best for this
		-- EJ says 10 yard, but that is for the landing, don't get confused!
		-- this could get fancy if we used player facing and some math
		if mod:Range(player) < 5 then
			mod:RangeMessage(143716)
			mod:Flash(143716)
		else
			mod:TargetMessage(143716, player, "Urgent", "Alarm")
		end
	end
	local function checkshockwaveTarget()
		local player = mod:UnitName("boss1target")
		if player and (not UnitDetailedThreatSituation("boss1target", "boss1") and not mod:Tank("boss1target")) then -- assuming tanks are not valid targets
			shockwaveTarget = UnitGUID("boss1target")
			warnShockwave(player, shockwaveTarget)
			mod:CancelTimer(timer)
			timer = nil
		end
	end
	function mod:HeroicShockwave(_, _, _, _, spellId)
		if spellId == 143500 then -- Heroic Shockwave
			shockwaveTarget = nil
			if not timer then
				timer = self:ScheduleRepeatingTimer(checkshockwaveTarget, 0.05)
			end
		end
	end
	function mod:HeroicShockwaveDamage(args)
		if timer then
			self:CancelTimer(timer)
			self:ScheduleTimer(checkshockwaveTarget, 0.05)
			timer = nil
		end
		 -- don't do anything if we warned for the target already
		if args.destGUID ~= shockwaveTarget then
			warnShockwave(args.destName, args.destGUID)
		end
	end
end

function mod:CoolingOff(args)
	self:Bar(args.spellId, 15)
end

function mod:Stances(args)
	self:Message(-7915, "Positive", (args.spellId == 143593) and "Warning") -- Play sound if he switches to defensive -- this might conflich with War Song
	local nextStance
	if args.spellId == 143589 then
		nextStance = 143594
	elseif args.spellId == 143594 then
		nextStance = 143593
	elseif args.spellId == 143593 then
		nextStance = 143589
	end
	self:Bar(-7915, 60, L["stance_bar"]:format(self:SpellName(nextStance), args.spellName), nextStance)
end

do
	function mod:BoneCrackerRemoved(args)
		if self.db.profile.custom_off_bonecracker_marks then
			for i = 1, 7 do
				if marksUsed[i] == args.destName then
					marksUsed[i] = false
					SetRaidTarget(args.destName, 0)
				end
			end
		end
	end

	local function markBonecrackers(destName)
		for i = 1, 7 do
			if not marksUsed[i] then
				SetRaidTarget(destName, i)
				marksUsed[i] = destName
				return
			end
		end
	end
	function mod:BoneCrackerApplied(args)
		if self:Me(args.destGUID) then
			self:TargetMessage(args.spellId, args.destName, "Personal", "Info") -- so you know to be extra careful since your max hp is halved
		end
		if self.db.profile.custom_off_bonecracker_marks then
			markBonecrackers(args.destName)
		end
	end
end

function mod:BoneCracker(args)
	self:Message(args.spellId, "Urgent", "Alarm")
	self:Bar(args.spellId, 32)
end

function mod:SunderingBlow(args)
	local amount = args.amount or 1
	self:StackMessage(args.spellId, args.destName, amount, "Attention", "Info")
	self:CDBar(args.spellId, 10)
end

