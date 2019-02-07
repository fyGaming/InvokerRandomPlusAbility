--[[Author: Pizzalol, Rook
	Date: 12.04.2015.
	Invokes a new spell depending on the orb combination]]
count = 0							---可以在function外面声明参数，来记录方程内发生的事情
invoker_ability_table = {}

function InvokeRandom( keys )

	----要传入一个table，这个table是可供选择的技能
local random_ability_normal = GameRules.vNormalAbilitiesPool
local random_ability_table = GameRules.vUltimateAbilitiesPool
print(random_ability_table[1])
	--每次进行invoker都会进行一次随机，随机出10个技能，放到技能table -- 先不随机，先取十个


    ----

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	caster.invoked_orbs = caster.invoked_orbs or {}
	local max_invoked_spells = ability:GetLevelSpecialValueFor("max_invoked_spells", ability_level)
	local invoker_empty1 = "invoker_empty1_datadriven"
	local invoker_empty2 = "invoker_empty2_datadriven"
	local invoker_slot1 = caster:GetAbilityByIndex(3):GetAbilityName() -- First invoked spell
	local spell_to_be_invoked

	--Play the particle effect with the general color.
	local invoke_particle_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_invoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.caster)

	-- If we have 3 invoked orbs then do the Invoke logic
	if caster.invoked_orbs[1] and caster.invoked_orbs[2] and caster.invoked_orbs[3] then
		--The Invoke particle effect changes color depending on which orbs are out.
		local quas_particle_effect_color = Vector(0, 153, 204)
		local wex_particle_effect_color = Vector(204, 0, 153)
		local exort_particle_effect_color = Vector(255, 102, 0)
		
		local num_quas_orbs = 0
		local num_wex_orbs = 0
		local num_exort_orbs = 0
		for i=1, 3, 1 do
			if keys.caster.invoked_orbs[i]:GetName() == "quas_datadriven" then
				num_quas_orbs = num_quas_orbs + 1
			elseif keys.caster.invoked_orbs[i]:GetName() == "wex_datadriven" then
				num_wex_orbs = num_wex_orbs + 1
			elseif keys.caster.invoked_orbs[i]:GetName() == "exort_datadriven" then
				num_exort_orbs = num_exort_orbs + 1
			end
		end
		
		--Set the Invoke particle effect's color depending on which orbs are invoked.
		ParticleManager:SetParticleControl(invoke_particle_effect, 2, ((quas_particle_effect_color * num_quas_orbs) + (wex_particle_effect_color * num_wex_orbs) + (exort_particle_effect_color * num_exort_orbs)) / 3)

		-- Determine the invoked spell depending on which orbs are in use.
		if num_quas_orbs == 3 then
			spell_to_be_invoked = random_ability_table[math.random(1,20)]       					--注意用:也是方程模仿的一部分			----这个技能是需要动态让该英雄学习的，所以如何在这个最底层文件中使得召唤他的英雄学到技能呢
		elseif num_quas_orbs == 2 and num_wex_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_quas_orbs == 2 and num_exort_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_wex_orbs == 3 then
			spell_to_be_invoked = random_ability_table[math.random(1,20)]   
		elseif num_wex_orbs == 2 and num_quas_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_wex_orbs == 2 and num_exort_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_exort_orbs == 3 then
			spell_to_be_invoked = random_ability_table[math.random(1,20)]   
		elseif num_exort_orbs == 2 and num_quas_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_exort_orbs == 2 and num_wex_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		elseif num_quas_orbs == 1 and num_wex_orbs == 1 and num_exort_orbs == 1 then
			spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
		end

		  --测试bug出处
		count = count + 1
		print(count)
		print('want to learn' .. spell_to_be_invoked)

		

		if caster:HasAbility(spell_to_be_invoked) == false then
			                       ---roll到这个技能没学过
			caster:AddAbility(spell_to_be_invoked)     ---要学习这个魔法才能出现才能使用 如果没有学过这哥ability再学，学过了就不要添加技能了，避免1、2格子都沾满
			table.insert(invoker_ability_table, spell_to_be_invoked)
			print('already learn' .. spell_to_be_invoked)

			elseif caster:HasAbility(spell_to_be_invoked) == true then
				repeat
				spell_to_be_invoked = random_ability_normal[math.random(1,20)] 
				until caster:HasAbility(spell_to_be_invoked) == false
					caster:AddAbility(spell_to_be_invoked)     ---要学习这个魔法才能出现才能使用 如果没有学过这哥ability再学，学过了就不要添加技能了，避免1、2格子都沾满
					table.insert(invoker_ability_table, spell_to_be_invoked)
					print('already learn' .. spell_to_be_invoked)

		end

		-- If its only 1 max invoke spell then just swap abilities in the same slot
		if max_invoked_spells == 1 and invoker_slot1 ~= spell_to_be_invoked then
			caster:SwapAbilities(invoker_slot1, spell_to_be_invoked, false, true)
			caster:FindAbilityByName(spell_to_be_invoked):SetLevel(1)
		-- Otherwise reset the slots and then place the abilities in the proper slots
		elseif max_invoked_spells == 2 and invoker_slot1 ~= spell_to_be_invoked then
			if invoker_slot1 ~= invoker_empty1 then
				caster:SwapAbilities(invoker_empty1, invoker_slot1, true, false) 
			end
			print('TENSION!!' .. caster:GetAbilityByIndex(4):GetAbilityName())
			local invoker_slot2 = caster:GetAbilityByIndex(4):GetAbilityName() -- Second invoked spell
			print(invoker_slot2)
			print(invoker_empty2)
			if invoker_slot2 ~= invoker_empty2 then
				caster:SwapAbilities(invoker_empty2, invoker_slot2, true, false) 
			end

			caster:SwapAbilities(spell_to_be_invoked, invoker_empty1, true, false) 
			caster:SwapAbilities(invoker_slot1, invoker_empty2, true, false)
			caster:FindAbilityByName(spell_to_be_invoked):SetLevel(1)
		end


		if #invoker_ability_table > 2 and  invoker_ability_table[#invoker_ability_table-2] ~= invoker_slot2 then
		caster:RemoveAbility(invoker_ability_table[#invoker_ability_table-2])												 ---不能减0，要不然只减了一次
		print('has removed' .. invoker_ability_table[#invoker_ability_table-2])		
		table.remove(invoker_ability_table, #invoker_ability_table-2)												----当invker有两个技能的时候，把倒数第二个删掉，不然会遇到23技能顶
		end
		print('ability table length' .. #invoker_ability_table)


																										--神奇的bug：当运行到n = 110， 两个技能槽slot全没了并且显示 104 nil
	end
end