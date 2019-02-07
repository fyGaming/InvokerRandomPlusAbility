-- Battle of Mirkwood - Battle Royale Game Mode
-- Created By Xavier @2017.4
--

print("Loading Dota Arena")

-------------------------------------------------------------------------------------------------------------
-- 初始化游戏模式
-------------------------------------------------------------------------------------------------------------


if _G.GameMode == nil then
	_G.GameMode = class({})
end

-------------------------------------------------------------------------------------------------------------
-- 类似于python中的文件载入机制
-- 使用一个文件夹中的_loader载入文件夹中的所有需要载入的文件
-- 这个函数当然会同时运行_loader中的所有语句
-- path表示文件夹
-------------------------------------------------------------------------------------------------------------
function fyrequire(path)    -------nice可以用！！

	local files = require(path .. '/_loader')
	if not files then 
	error('fyquire failed to load'  .. path)
	end

	if files and type(files) == 'table' then
		for _,file in pairs(files) do
			print(file)
			print(path)
			require(path .. '/' .. file)
		end

	elseif files and not type(files) == 'table' then
			print (path, 'doesnt retuen a table contains files to require')
	
	end
end

fyrequire('requirefolder')
fyrequire('utils')
fyrequire('libraries')  --notifications && timer(for spell library)



Precache = require('precache')


require("gamemode")   ---注意require的要是lua文件，不然后面要写.txt
require('ui')


function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end


local _print = print
function print(...)
	if IsInToolsMode() then
		_print(...)
	end
end

-------------------------------------------------------------------------------------------------------------
-- 以下内容没有写在函数里面，是为了在测试的时候每次reload都可以重新载入技能、单位的数据
-- 现在已经不需要写在外面了，但是懒得挪了
-- 就这样吧，目前不会有什么错误
-- 
-------------------------------------------------------------------------------------------------------------
-- 载入KV数据
