﻿------------------------------
--      Are you local?      --
------------------------------

local boss = AceLibrary("Babble-Boss-2.2")["Attumen the Huntsman"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local horse = AceLibrary("Babble-Boss-2.2")["Midnight"]
local playerName = nil
local started

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Attumen",

	phase_cmd = "phase",
	phase_name = "Phase",
	phase_desc = "Warn when entering a new Phase",

	curse_cmd = "curse",
	curse_name = "Cursed Warriors",
	curse_desc = "Warn when a warrior is cursed",

	curse_trigger = "^([^%s]+) ([^%s]+) afflicted by Intangible Presence",
	curse_message = "Warrior Cursed - %s",

	phase1_message = "Phase 1 - Midnight",
	phase2_trigger1 = "Perhaps you would rather test yourselves against a more formidable opponent?!",
	phase2_trigger2 = "Cowards! Wretches!",
	phase2_message = "Phase 2 - Midnight & Attumen",
	phase3_trigger = "Come Midnight, let's disperse this petty rabble!",
	phase3_message = "Phase 3 - Attumen the Huntsman",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

BigWigsAttumen = BigWigs:NewModule(boss)
BigWigsAttumen.zonename = AceLibrary("Babble-Zone-2.2")["Karazhan"]
BigWigsAttumen.enabletrigger = horse
BigWigsAttumen.toggleoptions = {"phase", "curse", "bosskill"}
BigWigsAttumen.revision = tonumber(string.sub("$Revision$", 12, -3))

------------------------------
--      Initialization      --
------------------------------

function BigWigsAttumen:OnEnable()
	started = nil
	playerName = UnitName("player")

	self:RegisterEvent("BigWigs_RecvSync")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	if select(2, UnitClass("player")) == "WARRIOR" then
		self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "CurseEvent")
		self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "CurseEvent")
		self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "CurseEvent")
	end

	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "GenericBossDeath")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
end

------------------------------
--      Event Handlers      --
------------------------------

function BigWigsAttumen:CHAT_MSG_MONSTER_YELL(msg)
	if self.db.profile.phase and msg == L["phase3_trigger"] then
		self:TriggerEvent("BigWigs_Message", L["phase3_message"], "Important")
	elseif self.db.profile.phase and (msg == L["phase2_trigger1"] or msg == L["phase2_trigger2"]) then
		self:TriggerEvent("BigWigs_Message", L["phase2_message"], "Urgent")
	end
end

function BigWigsAttumen:BigWigs_RecvSync( sync, rest, nick )
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		if self.db.profile.phase then
			self:TriggerEvent("BigWigs_Message", L["phase1_message"], "Attention")
		end
	end
end

function BigWigsAttumen:CurseEvent(msg)
	local cplayer, ctype = select(3, msg:find(L["curse_trigger"]))
	if cplayer then
		if cplayer == L["you"] then
			cplayer = playerName
		end
		if cplayer == playerName and self.db.profile.curse then
			self:TriggerEvent("BigWigs_Message", string.format(L["curse_message"], cplayer), "Attention")
		end
	end
end
