
require('testrequired')
--require('requirefolder/requirefolderfile')
require('debug')

function GameMode:InitGameMode()
                            ---[[这个Gamerules在不同的OnGameRulesStateChange中，Gamerules可以是不同的值，也就是说我们可以声明不同的entity，在不同的state作用
GameRules.self = self        ---这一行并未理解，GameRules可以理解为和游戏相关的很多函数与参数的类，访问Gamerules便可以访问他们***
local gamemode = GameRules:GetGameModeEntity()
self.gamemode = gamemode
GameRules.gamemode = gamemode   ----这个过程我理解为，local gamemode声明一个Gamerules中的gm实体，且只应用在这个InitGM之中， 
                                    --为了方便后边全局使用，GR.gm = gm
                                    --所以这个过程是 GR请给我一个GM实例，我存在这里，但你也要记住这个实例，我把你存在GR.gm，以后你再全局用

-----------------------------               --[[debug用的print，未知功能]]
if IsInToolsMode() then
    print('inToolMode')
    DebugPrint()
    self:EnterDebugMode()                    ------Debug Mode~~~~
end
-----进入测试mod

GameRules:SetUseUniversalShopMode(true)             --[[这个部分是一些游戏功能的设置，缩短载入时间，方便游戏与测试]]
GameRules:SetHeroSelectionTime(0.1)
GameRules:SetStrategyTime(3)
GameRules:SetShowcaseTime(1)
gamemode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "OrderFilter"), self)   ------------配合下面的OrderFilter,
                                                                                --比如当任务__vHeroOrder为购买**，就做***神奇的__vHeroOrder!!

-------------------全球使用商店////以及一些事件缩短

requirePrint()
--require('requirefolder/requirefolderfile')
folderrequirefile()
requirefolderfile2()


GameMode:ReadKV()
GameMode:TestKV()


self:SetupGameEventListener()    ------监听事件~~~  --------这个函数见后面----------是启动所有监听的地方----

---监听游戏进度
ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode,"OnGameRulesStateChange"),  self)
----------------------------------------------------------------learning panorama

--GameMode:InitPlayerHero(hero)

--监听UI事件，UI事件管理器！
CustomGameEventManager:RegisterListener("myui_open", OnMyUIOpen)    --注册增添一个监听ui的东西
CustomGameEventManager:RegisterListener("js_to_lua", OnJsToLua)
CustomGameEventManager:RegisterListener("lua_to_js", OnLuaToJs)     ------增加了js与lua的联动事件
-------------
end

----------配合StateChange 的监听！

function GameMode:OnGameRulesStateChange(keys)
    local state = GameRules:State_Get()

    if state == DOTA_GAMERULES_STATE_PRE_GAME then
        ----调用ui
        CustomUI:DynamicHud_Create(-1, "MyUIButton", "file://{resources}/layout/custom_game/MyUI_button.xml", nil)
    end

end
-------------------------监听UI事件的部分！！！！-----

function OnMyUIOpen(index,keys)
   --index是事件的index值
   --keys是一个table，固定包含一个触发的playerID,其余的是传递过来的数据
   CustomUI:DynamicHud_Create(keys.PlayerID, "MyUIMain", "file://{resources}/layout/custom_game/MyUI_main.xml", nil)
end

----------------------------------------------------------------


--------------------------Js----->Lua-----------------
function OnJsToLua( index,keys )
    print("num:" .. keys.num.. " str:" .. tostring(keys.str))   ----在这里keys传递着数据
    CustomUI:DynamicHud_Destroy(keys.PlayerID, "MyUIMain")
end


-------------------------------------------------------

-----------------------Lua--->Js---------------------
function OnLuaToJs( index,keys )
    --print("functionLtoJ")
    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(keys.PlayerID), "on_lua_to_js", {str="Lua"} )
    CustomUI:DynamicHud_Destroy(keys.PlayerID, "MyUIMain")
end


------------------------------------------------

function GameMode:ReadKV()

GameRules.Heroes_KV = LoadKeyValues('scripts/npc/npc_heroes_custom.txt')
GameRules.Items_KV = LoadKeyValues('scripts/npc/npc_items_custom.txt')
GameRules.Units_KV = LoadKeyValues('scripts/npc/npc_units_custom.txt')
GameRules.Abilities_KV = LoadKeyValues('scripts/npc/npc_abilities_custom.txt')
GameRules.DotaItems_KV = LoadKeyValues("scripts/npc/items.txt")
GameRules.OverrideAbility_KV = LoadKeyValues("scripts/npc/npc_abilities_override.txt")
GameRules.OriginalAbilities = LoadKeyValues("scripts/npc/npc_abilities.txt")
GameRules.OriginalHeroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
-- 去除几个无效的字段
GameRules.OriginalHeroes['Version'] = nil
GameRules.OriginalHeroes['npc_dota_hero_target_dummy'] = nil

GameRules.ValidHeroes = LoadKeyValues("scripts/npc/herolist.txt")
-------------------------------------------------------------------------------------------------------------
-- 处理一下英雄的KV，以英雄本身的名字作为index
-------------------------------------------------------------------------------------------------------------
for _, data in pairs(GameRules.Heroes_KV) do   ---加入invoker之后有点问题，先给干掉
    if data and type(data) == "table" then
        GameRules.Heroes_KV[data.override_hero] = data
    end
end
-------------------------------------------------------------------------------------------------------------
-- 处理一下英雄的名字
-------------------------------------------------------------------------------------------------------------
for index, valid in pairs(GameRules.ValidHeroes) do
	if tonumber(valid) ~= 1 then
		GameRules.ValidHeroes[index] = nil
	end
end
GameRules.ValidHeroes = table.make_key_table(GameRules.ValidHeroes) -- 做一个key的表
-------------------------------------------------------------------------------------------------------------
-- 处理技能数据，做出几个表给游戏模式用
-------------------------------------------------------------------------------------------------------------
if GameRules.AvailableHeroesThisGame == nil then -- 重载的时候不重载技能
	local heroNameThisGame = table.random_some(table.make_key_table(GameRules.OriginalHeroes), 50)
	GameRules.AvailableHeroesThisGame = {}
	for _, heroName in pairs(heroNameThisGame) do
		GameRules.AvailableHeroesThisGame[heroName] = GameRules.OriginalHeroes[heroName]
	end
	GameRules.vBlackList = require("data/black_list")
	GameRules.vNormalAbilitiesPool = {}
	GameRules.vUltimateAbilitiesPool = {}

	GameRules.vHeroAbilityPoolForPlus = {}

	for heroName, data in pairs(GameRules.AvailableHeroesThisGame) do
		if type(data) == "table" then

			local hero_abilities = {}

			for i = 1, 23 do
				local abilityName = data["Ability" .. i]
				if abilityName then
					if GameRules.OriginalAbilities[abilityName] and
						GameRules.OriginalAbilities[abilityName].AbilityType ~= "DOTA_ABILITY_TYPE_ATTRIBUTES" and
						not table.contains(GameRules.vBlackList, abilityName) 
						then

						table.insert(hero_abilities, abilityName)

						-- 根据技能类型的不同，分别放到各自的表中
						if GameRules.OriginalAbilities[abilityName].AbilityType ~= "DOTA_ABILITY_TYPE_ULTIMATE" then
							table.insert(GameRules.vNormalAbilitiesPool, abilityName)
						else
							table.insert(GameRules.vUltimateAbilitiesPool, abilityName)
						end
					end
				end
			end

			table.insert(GameRules.vHeroAbilityPoolForPlus, {hero = heroName, abilities = hero_abilities})
		end
	end
end
end



function GameMode:TestKV()

for _, abilityName in pairs(GameRules.vUltimateAbilitiesPool) do
	print(abilityName)

	end
end



function GameMode:InitPlayerHero(hero)      ---给英雄重新安排技能
    -- 移除除了天赋树技能之外的全部技能
    -- 要记住天赋的顺序
   hero.__bInited = true
    for i = 0, 23 do
        local ability = hero:GetAbilityByIndex(i)
        if ability then
            local name = ability:GetAbilityName()
            if not string.find(name, "special_bonus") then  --special_bonus应该就是天赋
                hero:RemoveAbility(name)
            end
        end
    end

    -- 为玩家添加所有的空技能
    local empty_abilities = {
        'empty_a1', -- 4个购买技能？
        'empty_a2',
        'empty_a3',
        'empty_a4', -- 4,5两个技能会隐藏
        'empty_a5', -- 4,5两个技能会隐藏
        'empty_a6',
        'empty_1', -- 6个随机掉落技能
        'empty_2',
        'empty_3',
        'empty_4',
        'empty_5',
        -- 'empty_6',
    }

    if hero:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
        table.insert(empty_abilities, "empty_6")
    end

    for _, name in ipairs(empty_abilities) do
        hero:AddAbility(name)                   -------这几个empty技能在custom_ability是预设值好的，相当于空白的板子
        hero:FindAbilityByName(name):SetLevel(1)
    end

---------------------------------------------------------------------------------------
    local heroName = hero:GetName()          -----尝试给召唤师换技能
  if heroName == "npc_dota_hero_rubick" or heroName ==  "npc_dota_hero_invoker" then
    	--hero:AddAbility("abyssal_underlord_atrophy_aura_datadriven")

    for i = 0, 23 do
        local ability = hero:GetAbilityByIndex(i)
        if ability then
            local name = ability:GetAbilityName()
            if not string.find(name, "special_bonus") then  --special_bonus应该就是天赋
                hero:RemoveAbility(name)
            end
        end
    end									----召唤师的技能先全都remove掉

    	local invoker_abilities = {

    	'quas_datadriven',
    	'wex_datadriven',
    	'exort_datadriven',
        'fyorbs1_datadriven' ,          
        'fyorbs2_datadriven',         ------先让他占个格子 学者 测试图标和特效
    	'invoker_empty1_datadriven',
    	'invoker_empty2_datadriven',
    	'invoke_random_datadriven',


    }

    for _,name in ipairs(invoker_abilities) do 
    	hero:AddAbility(name)
    	hero:FindAbilityByName(name):SetLevel(1)
    end
  end
----------------------------------------------------------------------------------------


end


function GameMode:SetupGameEventListener()
    ListenToGameEvent("npc_spawned",Dynamic_Wrap(GameMode, "OnNpcSpawned"),self)
    ListenToGameEvent("player_chat",Dynamic_Wrap(GameMode, "OnPlayerChat"),self)
end


function GameMode:OnNpcSpawned(keys)
 local hSpawnedUnit = EntIndexToHScript( keys.entindex )
    if hSpawnedUnit:IsRealHero() then
        self:InitPlayerHero(hSpawnedUnit)
	end
end



function GameMode:OnPlayerChat(keys)
    if IsInToolsMode() then
        self:Debug_OnPlayerChat(keys)

        print('FYInToolMode~Debugging~')
    end

end

-------------------------測試物品是如何自動使用的，懷疑root中gamemode的OrderFilter可能有關，可能是自動命令

function GameMode:OrderFilter(filterTable)
    local orderType = filterTable["order_type"]

    local target = EntIndexToHScript(filterTable.entindex_target)
    local hero = EntIndexToHScript(filterTable.units['0'])
    local order_type = filterTable["order_type"]

    hero.__vLastOrder = filterTable

    if filterTable.entindex_ability and order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
        if table.contains({
            1504, 1505, -- 加星 随星
            1502, 1500, -- 技能点 移除技能
            4096, -- 自爆a
            4097,4098,4099
            }, filterTable.entindex_ability)
            then

            if not hero:IsAlive() then
                msg.bottom('#cannot_purchase_this_item_while_dead', hero:GetPlayerID())
                return false
            else
            end
        end
    end

    if filterTable.entindex_ability and order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
        if filterTable.entindex_ability == 4096 then
            if hero.__bSuiciding then return false end
            if hero.__nSuicideCount and hero.__nSuicideCount >= 10 then return false end

            if not hero.__DoubleSuicideConfirm then
                msg.bottom("#purchase_again_to_confirm", hero:GetPlayerID(), nil, "General.PingWarning")
                hero.__DoubleSuicideConfirm = true
                return
            end
            hero.__DoubleSuicideConfirm = nil
            
            msg.bottom("#suicide_in_20_seconds", hero:GetPlayerID(), nil, "General.PingDefense")
            hero.__bSuiciding = true
            Timer(20, function()
                hero.__bSuiciding = false
                if hero:IsAlive() then
                    hero.__nSuicideCount = hero.__nSuicideCount or 0
                    hero.__nSuicideCount = hero.__nSuicideCount + 1
                    hero.__hLastDamageHero = hero.__hLastDamageHero or hero
                    ApplyDamage({
                        attacker = hero.__hLastDamageHero,
                        victim = hero,
                        damage = hero:GetMaxHealth() * 2,
                        damage_type = DAMAGE_TYPE_PURE,
                    })
                end
            end)
            return false
        end

        -- 交换技能位置
        if filterTable.entindex_ability == 4097 then
            local ability1 = hero:GetAbilityByIndex(0):GetAbilityName()
            local ability2 = hero:GetAbilityByIndex(1):GetAbilityName()
            hero:SwapAbilities(ability1, ability2, true, true)
            return false
        end

        if filterTable.entindex_ability == 4098 then
            local ability1 = hero:GetAbilityByIndex(1):GetAbilityName()
            local ability2 = hero:GetAbilityByIndex(2):GetAbilityName()
            hero:SwapAbilities(ability1, ability2, true, true)
            return false
        end

        if filterTable.entindex_ability == 4099 then
            -- 只有智力英雄可以替换34技能的位置
            if hero:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_INTELLECT then
                return false
            end
            local ability1 = hero:GetAbilityByIndex(2):GetAbilityName()
            local ability2 = hero:GetAbilityByIndex(3):GetAbilityName()
            hero:SwapAbilities(ability1, ability2, true, true)
            return false
        end
    end

    if ( orderType ~= DOTA_UNIT_ORDER_PICKUP_ITEM or filterTable["issuer_player_id_const"] == -1 ) then
        return true
    else
        local player = PlayerResource:GetPlayer(filterTable["issuer_player_id_const"])
        local hero = player:GetAssignedHero()

        local item = EntIndexToHScript( filterTable["entindex_target"] )
        if item == nil then
            return true
        end
        local pickedItem = item:GetContainedItem()
        if pickedItem == nil then
            return true
        end
        local itemName = pickedItem:GetAbilityName()
        if itemName == "item_treasure_chest" then
            if hero:GetNumItemsInInventory() < 9 then
                return true
            else
                local position = item:GetAbsOrigin()
                filterTable["position_x"] = position.x
                filterTable["position_y"] = position.y
                filterTable["position_z"] = position.z
                filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
                return true
            end
        end

        -- 如果玩家在装备已满的情况下拾取技能，如果玩家拥有技能，那么直接为玩家添加技能
        if hero:GetNumItemsInInventory() >= 9 
            and table.contains(GameRules.RandomDropAbilityScrolls, itemName) 
            and not hero:HasItemInInventory(itemName) then
            
            local abilityName = string.sub(itemName, 6)
            
            local function autoLevelAbility()
                local ability = hero:FindAbilityByName(abilityName)
                if ability:GetLevel() < hero:GetLevel() and ability:GetLevel() < ability:GetMaxLevel() then
                    ability:UpgradeAbility(false)
                    UTIL_Remove(item)
                end
            end

            local function moveToItem()
                local position = item:GetAbsOrigin()
                filterTable["position_x"] = position.x
                filterTable["position_y"] = position.y
                filterTable["position_z"] = position.z
                filterTable["order_type"] = DOTA_UNIT_ORDER_MOVE_TO_POSITION
            end

            if hero:HasAbility(abilityName) then
                if (hero:GetOrigin() - item:GetAbsOrigin()):Length2D() < 128 then
                    autoLevelAbility()
                    return false
                else
                    moveToItem()
                    Timer(function()
                        -- 如果下达了其他指令，那么就不去拾取物品了
                        if hero.__vLastOrder ~= filterTable then return nil end
                        if (hero:GetOrigin() - item:GetAbsOrigin()):Length2D() < 128 then
                            autoLevelAbility()
                            return nil
                        end

                        return 0.03
                    end)
                    return true
                end
            else
                moveToItem()
                return true
            end
            
        end
    end
    return true
end

------------------------------------------------OrderFilter結束------------------