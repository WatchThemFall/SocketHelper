local addonName, L = ...
DSH_ADDON = DSH_ADDON or LibStub("AceAddon-3.0"):NewAddon("DSH_ADDON", "AceConsole-3.0")
local DSH = DSH_ADDON

local L = LibStub ("AceLocale-3.0"):GetLocale ("DominationSocketHelper")
if (not L) then
	print ("|cFFFFAA00Domination Socket Helper|r: Can't load locale. Something went wrong.|r")
	return
end

local dbpr = DSH.dbpr
local remixInitialized

local socketedGemInfo = {}
local bagGemInfo = {}

local EF = CreateFrame('Frame') -- event handler frame
EF:RegisterEvent('ADDON_LOADED')
EF:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)

local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots

local REMIX_GEM_TYPES = {"Meta", "Tinker", "Cogwheel", "Prismatic"}
local BUTTON_SIZE = 25
local SLOT_GEM_WRAP = 6
local BUTTON_PAD = 2
local STAT_ORDER = {CRIT_ABBR, STAT_HASTE, STAT_MASTERY, STAT_VERSATILITY, STAT_ARMOR, MANA_REGEN_ABBR, STAT_LIFESTEAL, STAT_SPEED}
local STAT_COLUMN_WIDTH = 17

local GetItemInfoInstant = GetItemInfoInstant or C_Item.GetItemInfoInstant
local GetItemCount = GetItemCount or C_Item.GetItemCount

local META_GEM_INFO = {
    [221982] = true,
    [221977] = true,
    [220211] = true,
    [220120] = true,
    [220117] = true,
    [219878] = true,
    [219386] = true,
    [216711] = true,
    [216695] = true,
    [216671] = true,
    [216663] = true,
    [216974] = true,
}

local PRISMATIC_GEM_INFO = {
    [210714] = {CRIT_ABBR, 1},
    [216644] = {CRIT_ABBR, 2},
    [211123] = {CRIT_ABBR, 3},
    [211102] = {CRIT_ABBR, 4},
    [210681] = {STAT_HASTE, 1},
    [216643] = {STAT_HASTE, 2},
    [211107] = {STAT_HASTE, 3},
    [211110] = {STAT_HASTE, 4},
    [210715] = {STAT_MASTERY, 1},
    [216640] = {STAT_MASTERY, 2},
    [211106] = {STAT_MASTERY, 3},
    [211108] = {STAT_MASTERY, 4},
    [220371] = {STAT_VERSATILITY, 1},
    [220372] = {STAT_VERSATILITY, 2},
    [220374] = {STAT_VERSATILITY, 3},
    [220373] = {STAT_VERSATILITY, 4},
    [220367] = {STAT_ARMOR, 1},
    [220368] = {STAT_ARMOR, 2},
    [220370] = {STAT_ARMOR, 3},
    [220369] = {STAT_ARMOR, 4},
    [211109] = {MANA_REGEN_ABBR, 1},
    [216642] = {MANA_REGEN_ABBR, 2},
    [211125] = {MANA_REGEN_ABBR, 3},
    [211105] = {MANA_REGEN_ABBR, 4},
    [210717] = {STAT_LIFESTEAL, 1},
    [216641] = {STAT_LIFESTEAL, 2},
    [210718] = {STAT_LIFESTEAL, 3},
    [211103] = {STAT_LIFESTEAL, 4},
    [210716] = {STAT_SPEED, 1},
    [216639] = {STAT_SPEED, 2},
    [211124] = {STAT_SPEED, 3},
    [211101] = {STAT_SPEED, 4}
}

local COGWHEEL_GEM_INFO = {
    [218110] = true,
    [218109] = true,
    [218108] = true,
    [218082] = true,
    [218046] = true,
    [218045] = true,
    [218044] = true,
    [218043] = true,
    [218005] = true,
    [218004] = true,
    [218003] = true,
    [217989] = true,
    [217983] = true,
    [216632] = true,
    [216631] = true,
    [216630] = true,
    [216629] = true,
}

local TINKER_GEM_INFO = {
    [219801] = true,
    [212366] = true,
    [219944] = true,
    [219818] = true,
    [216649] = true,
    [216648] = true,
    [217957] = true,
    [212694] = true,
    [212749] = true,
    [212365] = true,
    [219817] = true,
    [212916] = true,
    [219777] = true,
    [217964] = true,
    [216647] = true,
    [212758] = true,
    [219389] = true,
    [216624] = true,
    [216650] = true,
    [212759] = true,
    [212361] = true,
    [216625] = true,
    [217961] = true,
    [217927] = true,
    [216651] = true,
    [216626] = true,
    [219452] = true,
    [219523] = true,
    [212362] = true,
    [216627] = true,
    [219527] = true,
    [216628] = true,
    [217903] = true,
    [217907] = true,
    [212760] = true,
    [219516] = true,

}

local GEM_INFO_TABLE = {["Meta"] = META_GEM_INFO, ["Tinker"] = TINKER_GEM_INFO, ["Cogwheel"] = COGWHEEL_GEM_INFO}

local function createRemixRemoveButton()
    if DSH:IsRemix() and not DSH.RemixRemoveButton then
        DSH.RemixRemoveButton = CreateFrame ("button", nil, ItemSocketingFrame, "SecureActionButtonTemplate")
        local frame = DSH.RemixRemoveButton
        frame:RegisterForClicks("AnyUp", "AnyDown")
		frame:SetAttribute("type", "macro")
        frame:SetFrameStrata("HIGH")
        local castName = GetSpellInfo(433397)
        frame:SetAttribute("macrotext", "/cast "..castName)
        frame:SetPoint("BOTTOMRIGHT", ItemSocketingFrame, "BOTTOMRIGHT", -20, 33)
        frame:SetSize(35, 35)
        frame.tex = frame:CreateTexture()
        frame.tex:SetAllPoints()
        --frame.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        frame.tex:SetTexture(1379201)
    end
end

function EF:ADDON_LOADED(addon)

    if addon == "Blizzard_ItemSocketingUI" then
        createRemixRemoveButton()
        EF:UnregisterEvent("ADDON_LOADED")
    end
end

function EF:BAG_UPDATE_DELAYED(unit)
    DSH:RemixBagUpdate()
end

local function createBackdrop()
    if DSH.SBC.RemixButtons.backdrop then 
        DSH.SBC.RemixButtons.backdrop:Show()
        return
    end

    local frame = CreateFrame("Frame", nil, DSH.SBC, "BackdropTemplate")

    --DSH.SBC.RemixButtons[i] = frame

    frame:SetPoint("TOPLEFT", DSH.SBC, "BOTTOMRIGHT", 2, -2)
    -- frame.bg = CreateFrame("Frame", nil, CharacterMainHandSlot, "BackdropTemplate")
    DSH:FormatFrame(frame)
    frame:SetSize(50, 50)

    frame.PC = CreateFrame("Frame", nil, frame)
    frame.PC:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)

    frame.OC = CreateFrame("Frame", nil, frame)
    frame.OC:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)

    hooksecurefunc(frame, "Show", function() EF:RegisterEvent("BAG_UPDATE_DELAYED") end)
    hooksecurefunc(frame, "Hide", function() EF:UnregisterEvent("BAG_UPDATE_DELAYED") end)

    EF:RegisterEvent("BAG_UPDATE_DELAYED") 
    DSH.SBC.RemixButtons.backdrop = frame
end

local function createPrismaticString(text, anchor1, anchorFrame, anchor2, xOff, yOff, width, height, justifyH)

    local PC = DSH.SBC.RemixButtons.backdrop.PC

    local fontStr = PC:CreateFontString(nil, "overlay", "GameFontNormal")
    fontStr:SetPoint(anchor1, anchorFrame, anchor2, xOff, yOff)
    fontStr:SetTextColor (1, 1, 1, 1)
    fontStr:SetSpacing(2)
    fontStr:SetText(text)
    fontStr:SetSize(width or fontStr:GetStringWidth(), height or fontStr:GetStringHeight())
	fontStr:SetJustifyH(justifyH or "CENTER")
    fontStr:SetJustifyV("TOP")

    return fontStr

end

local function getPrismaticInBags()

    local prismaticInBags = {}

    for gemID, v in pairs(DSH.gemsInBags) do
    
        if PRISMATIC_GEM_INFO[gemID] then
            local gemType = PRISMATIC_GEM_INFO[gemID][1]
            local gemLevel = PRISMATIC_GEM_INFO[gemID][2]

            if not prismaticInBags[gemType] then prismaticInBags[gemType] = {} end
            if not prismaticInBags[gemType][gemLevel] then prismaticInBags[gemType][gemLevel] = {count = GetItemCount(gemID), gemID = gemID} end

            --prismaticInBags[gemType][gemLevel] = prismaticInBags[gemType][gemLevel] + 1
            
        end

    end

    return prismaticInBags

end

local function createPrismaticStrings()

    local PC = DSH.SBC.RemixButtons.backdrop.PC

    if PC.StatNames then return end

    --PC.StatNames:SetFontObject(GameFontNormal)

    local text = "\n"

    for _, v in pairs(STAT_ORDER) do
        text = text .. v .. "\n"
    end
    text = text:sub(1, -1)

    PC.StatNames = createPrismaticString(text, "TOPLEFT", DSH.SBC.RemixButtons.backdrop, "TOPLEFT", 5, -5, nil, nil, "LEFT")
    PC.StatNames.height = PC.StatNames:GetStringHeight();
    PC.StatNames.lineHeight = PC.StatNames.height / 9

    PC.StatBag = {}

    PC.StatBag[1] = createPrismaticString("1" , "TOPLEFT", PC.StatNames, "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")

    --quick hack to fix column width depending on font size (Elvui changes size?)
    PC.StatBag[1]:SetText("88")
    STAT_COLUMN_WIDTH = PC.StatBag[1]:GetStringWidth() + 2
    --STAT_COLUMN_WIDTH = width
    PC.StatBag[1]:SetWidth(STAT_COLUMN_WIDTH)

    --dbpr(width)
    
    PC.StatBag[2] = createPrismaticString("2" , "TOPLEFT", PC.StatBag[1], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")
    PC.StatBag[3] = createPrismaticString("3" , "TOPLEFT", PC.StatBag[2], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")
    PC.StatBag[4] = createPrismaticString("4" , "TOPLEFT", PC.StatBag[3], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")

    PC.StatEquip = {}

    PC.StatEquip[1] = createPrismaticString("1" , "TOPLEFT",PC.StatBag[3], "TOPRIGHT", 50, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")
    PC.StatEquip[2] = createPrismaticString("2" , "TOPLEFT", PC.StatEquip[1], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")
    PC.StatEquip[3] = createPrismaticString("3" , "TOPLEFT", PC.StatEquip[2], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")
    PC.StatEquip[4] = createPrismaticString("4" , "TOPLEFT", PC.StatEquip[3], "TOPRIGHT", 5, 0, STAT_COLUMN_WIDTH, PC.StatNames:GetHeight(), "CENTER")

end

local emptyPrismaticSlots = 0

local function getSocketedGemInfo()

    --emptyPrismaticSlots = 0

    --dbpr("EMPTYING TABLE")

    socketedGemInfo = {}

    if not DSH.socketInfo then return end

    for socketType, socketInfo in pairs(DSH.socketInfo) do

        --dbpr("TYPE", socketType)
        if not socketedGemInfo[socketType] then socketedGemInfo[socketType] = {} end
        socketedGemInfo[socketType].emptyCount = 0 

        for slotNum, slotInfo in pairs(socketInfo) do
            for socketNum, socketInfo in pairs(slotInfo) do
                --dbpr(socketInfo.gemID, PRISMATIC_GEM_INFO[socketInfo.gemID][1])

                if socketInfo.gemID then

                    --dbpr("GEMID", socketInfo.gemID)

                    if PRISMATIC_GEM_INFO[socketInfo.gemID] then

                        local statType = PRISMATIC_GEM_INFO[socketInfo.gemID][1]
                        local statLevel = PRISMATIC_GEM_INFO[socketInfo.gemID][2]

                        if not socketedGemInfo[socketType][statType] then socketedGemInfo[socketType][statType] = {} end
                        if not socketedGemInfo[socketType][statType][statLevel] then socketedGemInfo[socketType][statType][statLevel] = {} end
                        if not socketedGemInfo[socketType][statType][statLevel].count then socketedGemInfo[socketType][statType][statLevel].count = 0 end

                        local count = socketedGemInfo[socketType][statType][statLevel].count + 1

                        socketedGemInfo[socketType][statType][statLevel] = {count = count, slotNum = slotNum, socketNum = socketNum}
                    else
                        --dbpr("found", socketType, socketInfo.gemID)
                        if not socketedGemInfo[socketType].gemInfo then socketedGemInfo[socketType].gemInfo = {} end
                        socketedGemInfo[socketType].gemInfo[socketInfo.gemID] = {slotNum = slotNum, socketNum = socketNum}
                    end
                        --equippedPrismatic[gemType][gemLevel]["slotNum"] = {slotNum = slotNum, socketNum = socketNum}

                else
                    socketedGemInfo[socketType].emptyCount = socketedGemInfo[socketType].emptyCount + 1
                end
            end
        end
    end

    --return equippedPrismatic

end

local function setGemColumnText(gemTable, stringTable)
    for i = 1, 4 do
        local text = i
        for j, stat in ipairs(STAT_ORDER) do
            local statCount = ""
            if gemTable and gemTable[stat] and gemTable[stat][i] then
                statCount = gemTable[stat][i].count
            else
                statCount = "|cFF7B807D-|r"    
            end
            text = text .."\n" .. statCount
        end

        stringTable[i]:SetText(text)
    end

end


local bagPrismatic, equippedPrismatic

local function updatePrismaticStrings()

    --createBackdrop()
    createPrismaticStrings()

    local PC = DSH.SBC.RemixButtons.backdrop.PC
    PC:Show()

    bagPrismatic = getPrismaticInBags()
    setGemColumnText(bagPrismatic, PC.StatBag)

    --equippedPrismatic = getPrismaticEquipped()
    --dbpr('THIS', socketedGemInfo["Prismatic"])
    setGemColumnText(socketedGemInfo["Prismatic"], PC.StatEquip)


end

local function getRemixItemGemType(gemIDs)
    for _, gemID in pairs(gemIDs) do
        if gemID then
            if PRISMATIC_GEM_INFO[gemID] then
                return "Prismatic"
            elseif COGWHEEL_GEM_INFO[gemID] then
                return "Cogwheel"
            elseif META_GEM_INFO[gemID] then
                return "Meta"
            elseif TINKER_GEM_INFO[gemID] then
                return "Tinker"
            end
        end
    end
end

local function getSocketedItemsInBags()
    --dbpr("Scanning Bags For Gems")
    local socketedItemsInBags = {}
    for b = 0, NUM_BAG_SLOTS do
        for s = 1, GetContainerNumSlots(b) do
            local itemLink = GetContainerItemLink(b, s)
            if itemLink then
                --ToDo make this work for multiple gems
                local gem1, gem2, gem3 = DSH:GetGemID(itemLink, 1), DSH:GetGemID(itemLink, 2), DSH:GetGemID(itemLink, 3)
                --local gemID = DSH:GetGemID(itemLink, 1)
                if gem1 or gem2 or gem3 then
                    --not good, but I don't have time.
                    --dbpr(gem1, gem2, gem3)

                    --saveSlotTypeForItemID(itemLink, gem1)
                    --saveSlotTypeForItemID(itemLink, gem2)
                    --saveSlotTypeForItemID(itemLink, gem3)
                    --if not DSH.remixGemType[gemID] then end
                    --local cleanLink = DSH:RemoveGemsFromItemLink(itemLink)
                    local gemType = getRemixItemGemType({gem1, gem2, gem3})

                    --return GetContainerItemID(b, s)

                    local itemID, _, _, _, icon = GetItemInfoInstant(itemLink) 

                    table.insert(socketedItemsInBags, {gemType = gemType, itemLink = itemLink, gemIDs = {gem1 or false, gem2 or false, gem3 or false}, bag = b, slot = s, itemID = itemID, icon = icon})
                end
            end
        end
    end
    --dbpr("Size", #socketedItemsInBags)

    return socketedItemsInBags
end

--local function createBagButton()

--    DSH.socketedItemsInBags = {}
--    --dbpr("REDO BAGS")

--    DSH.socketedItemsInBags = getSocketedItemsInBags()
--    --I don't like this, but scan bags for gems and only show if gems found. It's just better this way.
--    if #DSH.socketedItemsInBags == 0 then
--        if DSH.slotButtons["Bags"] then DSH.slotButtons["Bags"]:Hide() end
--    else
--        --dbpr("GOT HERE")
--        DSH:CreateSlotButton("Bags")
--        local slotBtn = DSH.slotButtons["Bags"]
--        slotBtn:SetNormalTexture(133633)
--        slotBtn.qualityTex:Hide()
--        slotBtn.position = buttonCount
--        --slotBtn:SetAtlas("bag-main")
--        if buttonCount > 1 then
--            slotBtn:SetPoint("LEFT", DSH.slotButtons[buttonCount-1],"RIGHT", SLOT_BUTTON_PAD, 0)
--        else
--            slotBtn:SetPoint("LEFT", DSH.SBC, "RIGHT", SLOT_BUTTON_PAD, 0)
--        end
        
--        --remixBagButtonShown = true
--        slotBtn:SetText(#DSH.socketedItemsInBags)
--        slotBtn:Show()

--        if DSH.SBC.bagSlotExtended then
--            bagSlotButtonEnter(slotBtn, true)
--        end
--    end

--end

local allowClickPrismatic = true


--local function delayPrismaticButtons()

--    for _, btn in pairs(PC.PrismaticButtons) do
--        btn:SetEnabled(false)
--    end

--    C_Timer.After(1, function() 
--        for _, btn in pairs(PC.PrismaticButtons) do
--            btn:SetEnabled(true)
--        end
    
--    end)


--end

local PRISMATIC_BUTTONS_SIZE = 12.5
local ignoreGemSlot = {}

local function createPrismaticButton(statNum, btnTable, stat, statBtnNum)
    local btnName = stat..statBtnNum

    if statBtnNum == 1 then
        btnTable[btnName] = CreateFrame("Button", nil, DSH.SBC.RemixButtons.backdrop.PC, "SecureActionButtonTemplate")
        btnTable[btnName] :SetAttribute("type", "macro")
    else
        btnTable[btnName] = CreateFrame("Button", nil, DSH.SBC.RemixButtons.backdrop.PC, "UIPanelButtonTemplate")
        btnTable[btnName]:SetScript("OnClick", function(self, button, down)

            local gemID, slotNum, socketNum = self.gemID, self.slotNum, self.socketNum

            if ignoreGemSlot[slotNum] and ignoreGemSlot[slotNum][socketNum] then dbpr("UH OH") return end

            if down and gemID and slotNum and socketNum then
                SocketInventoryItem(slotNum)

                --exit in case the code is f'ed (Doesn't actually work? thx blizzard)
                if GetExistingSocketLink(socketNum) then return end

                --local itemLink = GetInventoryItemLink("player", slotNum)

                --delayPrismaticButtons()

                DSH:UseContainerItemByID(gemID, socketNum)

                ignoreGemSlot[slotNum] = ignoreGemSlot[slotNum] or {}
                ignoreGemSlot[slotNum][socketNum] = true

                C_Timer.After(3, function() ignoreGemSlot[slotNum][socketNum] = false end)

                AcceptSockets()
                CloseSocketInfo()
            end
        end)
    end

    local frame = btnTable[btnName]
    frame:RegisterForClicks("AnyUp", "AnyDown")
    --frame:SetAttribute("type", "macro")
    frame:SetFrameStrata("HIGH")
    frame:SetNormalFontObject("GameFontNormal")
    frame:SetText(statBtnNum == 1 and "<" or ">")

    frame.stat = stat
    frame.statBtnNum = statBtnNum

    --local yOff = -1 * ((DSH.SBC.RemixButtons.backdrop.PC.StatNames.height/9) - PRISMATIC_BUTTONS_SIZE)

    if statNum == 1 and statBtnNum == 1 then
        --dbpr(statNum, statBtnNum)
        local xOff = DSH.SBC.RemixButtons.backdrop.PC.StatBag[4]:GetRight() - DSH.SBC.RemixButtons.backdrop:GetLeft()
        --dbpr(xOff)

        local yOff = -1 * (DSH.SBC.RemixButtons.backdrop.PC.StatNames.lineHeight * 1.4)

    
        --frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.backdrop, "TOPLEFT", xOff, yOff)
    elseif statBtnNum == 2 then
        frame:SetPoint("LEFT", btnTable[stat.."1"], "RIGHT", 2, 0)
    else
        local yOff = -1 * (DSH.SBC.RemixButtons.backdrop.PC.StatNames.lineHeight - PRISMATIC_BUTTONS_SIZE + 0.15)

        frame:SetPoint("TOPLEFT", btnTable[STAT_ORDER[statNum-1].."1"], "BOTTOMLEFT", 0, yOff)
    end

    frame:SetSize(PRISMATIC_BUTTONS_SIZE, PRISMATIC_BUTTONS_SIZE)

    --frame:SetScript("OnEnter", function()



    --    frame:SetAttribute("macrotext", "/laugh") -- text for macro on left click


    --end)


end

local function createPrismaticButtons()

    local PC = DSH.SBC.RemixButtons.backdrop.PC
    if PC.PrismaticButtons then return end

    --PC.PrismaticButtonsContainer = CreateFrame("Frame", nil, PC, "BackdropTemplate")
    --PC.PrismaticButtonsContainer:SetPoint("LEFT", DSH.SBC.RemixButtons.backdrop.PC.StatBag[4], "LEFT")

    PC.PrismaticButtons = {}

    --local lineHeight = DSH.SBC.RemixButtons.backdrop.PC.StatNames.height/9
    --local yOff = -1 * (lineHeight - PRISMATIC_BUTTONS_SIZE)


    for statNum, stat in pairs(STAT_ORDER) do
        createPrismaticButton(statNum, PC.PrismaticButtons, stat, 1)
        createPrismaticButton(statNum, PC.PrismaticButtons, stat, 2)
    end

end

local function setRemoveMacro(btn)

    local castName = GetSpellInfo(433397)

    if not socketedGemInfo["Prismatic"] then return end


    if socketedGemInfo["Prismatic"][btn.stat] then
        for gemLevel = 1, 4 do
            if socketedGemInfo["Prismatic"][btn.stat][gemLevel] then
                
                --dbpr(btn.stat, "found", gemLevel)

                local slotNum = socketedGemInfo["Prismatic"][btn.stat][gemLevel].slotNum
                local socketNum = socketedGemInfo["Prismatic"][btn.stat][gemLevel].socketNum

                local macroText = "/cast "..castName..
                                "\n/script SocketInventoryItem("..slotNum..")"..
                                "\n/click ItemSocketingSocket"..socketNum..
                                "\n/script HideUIPanel(ItemSocketingFrame)"

                btn:SetAttribute("macrotext", macroText)

                return

            end
        end
    end
end

local function getNextEmptySlot(gemType)

    if DSH.socketInfo[gemType] then
        for slotNum, slotInfo in pairs(DSH.socketInfo[gemType]) do

            for socketNum, socketInfo in pairs(slotInfo) do
                if not socketInfo.gemID then
                    return slotNum, socketNum
                end
            end

        end
    end
end

local function setAddMacro(btn)

    local gemID

    for gemLevel=4,1,-1 do
        if bagPrismatic[btn.stat][gemLevel] then
        --print(i)
            gemID = bagPrismatic[btn.stat][gemLevel].gemID
            local slotNum, socketNum = getNextEmptySlot("Prismatic")

            btn.gemID = gemID
            btn.slotNum = slotNum
            btn.socketNum = socketNum

            if gemID and slotNum and socketNum then
                return
            end
        end
    end
end


local function updatePrismaticButtons()
    local PC = DSH.SBC.RemixButtons.backdrop.PC

    createPrismaticButtons()

    local prismaticInfo = socketedGemInfo["Prismatic"]

    for _, btn in pairs(PC.PrismaticButtons) do
    
        --dbpr(btn.stat, btn.statBtnNum)

        --remove buttons
        if btn.statBtnNum == 1 then
            if prismaticInfo and prismaticInfo[btn.stat] then
                btn:Show()
                setRemoveMacro(btn)
            else
                btn:Hide()
            end
        --add buttons
        else
            if bagPrismatic[btn.stat] and prismaticInfo and prismaticInfo.emptyCount > 0 then
                btn:Show()
                setAddMacro(btn)
            else
                btn:Hide()
            end
        end
    end

end

local function hideBagButtons()
    if not DSH.SBC.RemixButtons.BagButtons then return end
    for _, btn in pairs(DSH.SBC.RemixButtons.BagButtons) do
        btn.nextGemID = nil
        btn.gemType = nil
        btn.nextGemSlot = nil
        btn.slotNum = nil
        btn.socketNum = nil
        btn:Hide()
    end
end


local function createBagButton(i)

    if not DSH.SBC.RemixButtons.BagButtons then DSH.SBC.RemixButtons.BagButtons = {} end
    if DSH.SBC.RemixButtons.BagButtons[i] then return end
    
    local frame = CreateFrame("Button", nil, DSH.SBC.RemixButtons.backdrop, "SecureActionButtonTemplate")
    frame:SetNormalTexture(133633)
    frame:RegisterForClicks("AnyUp", "AnyDown")
    frame:SetAttribute("type1", "macro")
    frame:SetAttribute("type2", "macro")
    frame:SetSize(15,15)
    if i == 1 then
        frame:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.backdrop, "TOPRIGHT", 2, 0)
    else
        frame:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.BagButtons[i-1], "BOTTOMLEFT", 0, -2)
    end

    frame:SetScript("PostClick", function(self, button, down)
        if down and button == "RightButton" then
            --quick and dirty, with timers.
            C_Timer.After(0.1, function() self:SetEnabled(false) end)
            local slotNum, socketNum, gemID = self.slotNum, self.socketNum, self.nextGemID
            --dbpr("B4 Timer", slotNum, socketNum, gemID)
            --local btn = self
            C_Timer.After(1, function()
                C_Timer.After(0.5, function() self:SetEnabled(true) end)
                if gemID then

                    --dbpr("AFTER TIMER", slotNum, socketNum, gemID)

                    SocketInventoryItem(slotNum)

                    --exit in case the code is f'ed
                    if GetExistingSocketLink(socketNum) then return end

                    --dbpr("DIDNT EXIT", gemID, socketNum)

                    DSH:UseContainerItemByID(gemID, socketNum)
                    AcceptSockets()
                    CloseSocketInfo()
                end
            end)
        end
    end)

    frame:SetScript("OnEnter", function(self)
        DSH:ToggleItemTooltip(true, self)
 

        DSH:ToggleInfoTooltip(true, L["LCLICK_REMOVE"] .. (self.slotNum and L["RCLICK_TRANSFER"] or "") , self)
    end)
    frame:SetScript("OnLeave", function(self)
        DSH:ToggleItemTooltip(false)
        DSH:ToggleInfoTooltip(false)
    end)

    DSH.SBC.RemixButtons.BagButtons[i] = frame


end


local function updateBagButtons()
    --DSH.socketedItemsInBags = {}
    --dbpr("REDO BAGS")

    hideBagButtons()

    local castName = GetSpellInfo(433397)
    local socketedItemsInBags = getSocketedItemsInBags()
    local bagCount = 1
    local slotNum, socketNum = getNextEmptySlot(DSH.CurrentRemixWindow)

    for _, socketedBagItemInfo in pairs(socketedItemsInBags) do

        --dbpr(socketedBagItemInfo.gemType, DSH.CurrentRemixWindow)

        if socketedBagItemInfo.gemType == DSH.CurrentRemixWindow then


            createBagButton(bagCount)
            local btn = DSH.SBC.RemixButtons.BagButtons[bagCount]
            btn.itemLink = socketedBagItemInfo.itemLink
            btn:SetNormalTexture(socketedBagItemInfo.icon)

            btn:SetAttribute("macrotext1", "/cast "..castName..
                                        "\n/script C_Container.SocketContainerItem("..socketedBagItemInfo.bag..", "..socketedBagItemInfo.slot..")"..
                                        "\n/click ItemSocketingSocket1"..
                                        "\n/cast "..castName..
                                        "\n/click ItemSocketingSocket2"..
                                        "\n/cast "..castName..
                                        "\n/click ItemSocketingSocket3"..
                                        "\n/script HideUIPanel(ItemSocketingFrame)")


            if slotNum and socketNum then
                for i, gemID in ipairs(socketedBagItemInfo.gemIDs) do
                    if gemID and not btn.nextGemID then
                        btn.nextGemSlot = i
                        btn.nextGemID = gemID
                        btn.gemType = socketedBagItemInfo.gemType
                    end
                end

                btn.slotNum = slotNum
                btn.socketNum = socketNum

                btn:SetAttribute("macrotext2", "/cast "..castName..
                                            "\n/script C_Container.SocketContainerItem("..socketedBagItemInfo.bag..", "..socketedBagItemInfo.slot..")"..
                                            "\n/click ItemSocketingSocket"..btn.nextGemSlot..
                                            "\n/script HideUIPanel(ItemSocketingFrame)")
            else
                btn:SetAttribute("macrotext2", "")
            end

            btn:Show()

            bagCount = bagCount + 1
        end
    end
end

local function hideSecureGemButtons()
    if not DSH.SBC.RemixButtons.backdrop.OC.SecureButtons then return end
    for _, btn in pairs(DSH.SBC.RemixButtons.backdrop.OC.SecureButtons) do
        btn:Hide()
    end
end

local function createSecureRemoveButton(i)

    --dbpr("Creating", i)

    if not DSH.SBC.RemixButtons.backdrop.OC.SecureButtons then DSH.SBC.RemixButtons.backdrop.OC.SecureButtons = {} end
    if DSH.SBC.RemixButtons.backdrop.OC.SecureButtons[i] then return end

    local btn = CreateFrame("Button", nil, DSH.SBC.RemixButtons.backdrop.OC, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    if i == 1 then
        btn:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.backdrop, "TOPLEFT", 2, -2)
    else
        if ((i-1) % SLOT_GEM_WRAP == 0) then
            btn:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.backdrop.OC.SecureButtons[i-SLOT_GEM_WRAP], "BOTTOMLEFT", 0, -1*BUTTON_PAD)
        else
            --dbpr("setting btn", i)
            btn:SetPoint("TOPLEFT", DSH.SBC.RemixButtons.backdrop.OC.SecureButtons[i-1], "TOPRIGHT", BUTTON_PAD, 0)
        end
    end

    btn:SetScript("OnEnter", function(self)
        DSH:ToggleItemTooltip(true, self)
        --DSH:ToggleInfoTooltip(true, "TEST REMOVE", self)
    end)
    btn:SetScript("OnLeave", function(self)
        DSH:ToggleItemTooltip(false)
        --DSH:ToggleInfoTooltip()
    end)

    btn:SetScript("PostClick", function(self, button, down)
        if down and self.slotNum and self.socketNum then
            SocketInventoryItem(self.slotNum)

            --exit in case the code is f'ed
            if GetExistingSocketLink(self.socketNum) then return end

            DSH:UseContainerItemByID(self.gemID, self.socketNum)
            AcceptSockets()
            CloseSocketInfo()
        end
    end)

    DSH.SBC.RemixButtons.backdrop.OC.SecureButtons[i] = btn

end


local function updateSecureRemoveButton(i, gemID, gemType, slotNum, socketNum, isSocketed)

    local castName = GetSpellInfo(433397)
    createSecureRemoveButton(i)
    local btn = DSH.SBC.RemixButtons.backdrop.OC.SecureButtons[i]
    --local itemID, _, _, _, icon = GetItemInfoInstant(itemLink) 
    btn.itemLink = "item:"..gemID
    btn:SetNormalTexture(select(5, GetItemInfoInstant(gemID)))

    btn:SetAttribute("macrotext", "") 
    btn.slotNum = nil
    btn.socketNum = nil
    btn.gemID = nil
    --btn:SetScript("OnClick", nil)

    --btn:Show()

    --btn:SetDesaturated(true)
    btn:SetEnabled(true)

    --dbpr(btn:GetNormalTexture())

    local tex = btn:GetNormalTexture()
    tex:SetTexCoord(.08, .92, .08, .92)

    btn:SetAlpha(1)

    if isSocketed then
        --tex:SetDesaturated(false)
        --gem already has a gem, need to remove it
        local macroText = "/cast "..castName..
                        "\n/script SocketInventoryItem("..slotNum..")"..
                        "\n/click ItemSocketingSocket"..socketNum..
                        "\n/script HideUIPanel(ItemSocketingFrame)"
        btn:SetAttribute("macrotext", macroText) 
        --btn:SetAlpha(1)

        --AutoCastShine_AutoCastStart(btn)

    else
        --btn:SetAlpha(0.3)
        --putting the gem in
        --tex:SetDesaturated(true)
        if slotNum and socketNum then
            btn.slotNum = slotNum
            btn.socketNum = socketNum
            btn.gemID = gemID
            btn:SetAlpha(0.4)

            --btn:SetDesaturated(true)
        else
            --tex:SetDesaturated(true)
            btn:SetEnabled(false)
            btn:SetAlpha(0.1)
        end
    end

    btn:Show()

end

local function getGemTypeInBags(gemType)

    local searchTable = GEM_INFO_TABLE[gemType]
    local gemTypeInBag = {}


    for gemID, v in pairs(DSH.gemsInBags) do
        if searchTable[gemID] then
            table.insert(gemTypeInBag, gemID)
        end

    end
    return gemTypeInBag

end



local function updateSecureRemoveButtons(gemType)

    hideSecureGemButtons()

    --if not socketedGemInfo[gemType].gemInfo then return end

    local btnCount = 1

    if socketedGemInfo[gemType] and socketedGemInfo[gemType].gemInfo then
        for gemID, socketInfo in pairs(socketedGemInfo[gemType].gemInfo) do
            --dbpr("HERE2", gemID, socketInfo, gemType, socketInfo.gemID)
            updateSecureRemoveButton(btnCount, gemID, gemType, socketInfo.slotNum, socketInfo.socketNum, true)
            btnCount = btnCount + 1
        end
    end

    local gemTypeInBags = getGemTypeInBags(gemType)

    local slotNum, socketNum = getNextEmptySlot(gemType)

    for i, gemID in ipairs(gemTypeInBags) do
        updateSecureRemoveButton(btnCount, gemID, gemType, slotNum, socketNum)
        btnCount = btnCount + 1
    end

    local colCount = (btnCount - 1  >= SLOT_GEM_WRAP) and SLOT_GEM_WRAP or btnCount - 1
    local rowCount = ceil((btnCount -1) / SLOT_GEM_WRAP)


    DSH.SBC.RemixButtons.backdrop:SetWidth(colCount * (BUTTON_SIZE + BUTTON_PAD) + BUTTON_PAD)
    DSH.SBC.RemixButtons.backdrop:SetHeight(rowCount * (BUTTON_SIZE + BUTTON_PAD) + BUTTON_PAD)
    --if btnCount - 1  >= SLOT_GEM_WRAP then


end

local RemixButtonEnter = {
    ["Meta"] = function()
        DSH:UpdateGemsInBags()
        DSH.SBC.RemixButtons.backdrop.OC:Show()
        updateSecureRemoveButtons("Meta")
        updateBagButtons()

        --DSH.SBC.RemixButtons.backdrop:SetPoint("TOP", frame, "BOTTOM", 2, -2)

    end,
    ["Prismatic"] = function()

        DSH:UpdateGemsInBags()
        updatePrismaticStrings()
        updatePrismaticButtons()

        local width = DSH.SBC.RemixButtons.backdrop.PC.StatEquip[4]:GetRight() - DSH.SBC.RemixButtons.backdrop:GetLeft() + 5
        local height = DSH.SBC.RemixButtons.backdrop:GetTop() - DSH.SBC.RemixButtons.backdrop.PC.StatNames:GetBottom() + 5
        DSH.SBC.RemixButtons.backdrop:SetSize(width, height)

        DSH.SBC.RemixButtons.backdrop:SetPoint("TOPLEFT", DSH.SBC, "BOTTOMRIGHT", 2, -2)

        updateBagButtons()

    end,
    ["Tinker"] = function()
        DSH:UpdateGemsInBags()
        DSH.SBC.RemixButtons.backdrop.OC:Show()
        updateSecureRemoveButtons("Tinker")
        updateBagButtons()

        --DSH.SBC.RemixButtons.backdrop:SetPoint("TOP", frame, "BOTTOM", 2, -2)

    end,
    ["Cogwheel"] = function()
        DSH:UpdateGemsInBags()
        DSH.SBC.RemixButtons.backdrop.OC:Show()
        updateSecureRemoveButtons("Cogwheel")
        updateBagButtons()

        --DSH.SBC.RemixButtons.backdrop:SetPoint("TOP", frame, "BOTTOM", 2, -2)

    end,
}

local function createRemixSlotButtons(buttonTable)

    DSH.SBC.RemixButtons = {}

    for i, v in ipairs (buttonTable) do
        local frame = CreateFrame("Button", nil, DSH.SBC, "BackdropTemplate")

        DSH.SBC.RemixButtons[i] = frame

        frame:SetPoint("LEFT", i == 1 and DSH.SBC or DSH.SBC.RemixButtons[i-1], "RIGHT", 2, 0)
        -- frame.bg = CreateFrame("Frame", nil, CharacterMainHandSlot, "BackdropTemplate")
        DSH:FormatFrame(frame, true)
        frame:SetText(v)
        frame:SetSize(frame:GetTextWidth()+6, 20)
        --frame:SetWidth(frame:GetStringWidth())
        frame:SetScript("OnClick", slotExtendClick)
        frame:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        frame:SetScript("OnEnter", function()
            -- if not DSH.db.char.quickslots.extended then slotExtendClick(frame, "LeftButton") end
            
            if InCombatLockdown() then return end
            
            createBackdrop()
            if DSH.SBC.RemixButtons.backdrop.PC then DSH.SBC.RemixButtons.backdrop.PC:Hide() end
            if DSH.SBC.RemixButtons.backdrop.OC then DSH.SBC.RemixButtons.backdrop.OC:Hide() end

            DSH.CurrentRemixWindow = v
            DSH.SBC.RemixButtons.backdrop:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 2, -2)

            RemixButtonEnter[v]()
            --DSH.CurrentRemixWindow = v
        end)
    end
	--return frame
end

--function DSH:

function EF:CHARACTER_FRAME_HIDE_GBC()
    if not DSH.CurrentRemixWindow then return end
    DSH.CurrentRemixWindow = nil
    DSH.SBC.RemixButtons.backdrop:Hide()
end

local function updateRemixButtonText()

    for i, gemType in ipairs(REMIX_GEM_TYPES) do
        if socketedGemInfo[gemType] then
            local btnText = socketedGemInfo[gemType].emptyCount > 0 and gemType .. " (|cFFFC0316"..socketedGemInfo[gemType].emptyCount.."|r)" or gemType
            DSH.SBC.RemixButtons[i]:SetText(btnText)
            DSH.SBC.RemixButtons[i]:SetWidth(DSH.SBC.RemixButtons[i]:GetTextWidth()+6)
        end
    end

end

function EF:PLAYER_REGEN_DISABLED()
    EF:CHARACTER_FRAME_HIDE_GBC()
end

local function InitializeRemix()
    if remixInitialized then return end

    CharacterFrame:HookScript('OnHide', function() EF:CHARACTER_FRAME_HIDE_GBC() end)
    CharacterFrame:HookScript('OnEnter', function() EF:CHARACTER_FRAME_HIDE_GBC() end)

    remixInitialized = true

    EF:RegisterEvent("PLAYER_REGEN_DISABLED")

    createRemixSlotButtons(REMIX_GEM_TYPES)

    --createBagButton()

end

hooksecurefunc(DSH, "UpdateSlotButtons", function()

    
    if DSH:IsRemix() then

        --dbpr("REMIXHOOK")
        InitializeRemix()

        getSocketedGemInfo()

        updateRemixButtonText()

        if InCombatLockdown() then return end

        if DSH.CurrentRemixWindow then RemixButtonEnter[DSH.CurrentRemixWindow]() end

        --for k, v in pairs(DSH.socketInfo) do
        --    dbpr(k)

        --    for k, v  in pairs(v) do
        --        dbpr(k, v)
        --    end
            
        --    dbpr("---")
        --end

    end

end)