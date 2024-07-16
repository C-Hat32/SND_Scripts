--[[

	Name: GBR Helper
	Author: C.Hat32
	Description: Helper for GatherBuddyReborn to handle food, repairs, materia extraction, aetherial reduction and retainers
	Version: 1.0
	
	Credits:
	LeafFriend and plottingCreeper for the wrapper functions and the Repair/Materias/Food management, in the GatheringHelper script. They deserve the credit for most of the script functionalities.
	Link: https://github.com/Jaksuhn/SomethingNeedDoing/blob/master/Community%20Scripts/Gathering/GatheringHelper.lua
	
	Prawellp for the AutoRetainer function, in the Fate Farming script.
	Link: https://github.com/Prawellp/FFXIV-SND/blob/main/Fate%20Farming.lua
	
	
	<Changelog>
    1.0	: 	First version of the script. The following features work: Repair/Materia extraction/Food/AutoRetainer. 
			Untested features (but expected to work): Aetherial Reduction
	
	<Additional Information>
	Needed Plugins: GatherBuddyReborn, vnavmesh, Pandora, YesAlready
	Optional plugins: Auto Retainer
	
	Additional advice for GBR:
	- Set GBR > Config > Auto-Gather > General > Mount Up Distance to 30 
	- Set GBR > Config > Auto-Gather > Advanced > Far Node Filter Distance to 100+ 
	
	
	<Usage>
    1. Change settings as wanted
	2. Setup an auto-gather list in GBR (GatherBuddyReborn)
	3. Make sure GBR auto-gather is off
    4. Run script in lua
	5. The script will run GBR auto-gather and do repairs/materia extraction/aetherial reduction/consume food, according to the settings
		
	
	
	=======-========+**#####*+======-------=-=
	====----====*%@@%%%%%%%%%%@@%+==----------
	===--======*@@@@%%%%%%@%@@@@@%==::--------
	===========*@@@@@%%%%@@%@@@@@%=-::--------
	===========+@@@@@%%%%@@@@@@@@#===---------
	===========+%%@@@%%%%%%@@@@@@+======-===--
	====----==+*#@#:*%*=##%%%%%@%==========---
	=-----==*##%%+.:-.:*%%%%%%@@%%*%%*=====---
	-=--:--=@%%%@@@%*++%@@@@@@@@@@%%%+=====-::
	--------*%%%%@@@@@@@@@@@@@@@@@%%*====-:::-
	------===*@@@%#%%%%%=:=%@@@%@@%%+==---::-:
	------===+*%@%%%%%@%: .%@%%@@@@*==----::--
	=--===---=*@@%@%#%%%: .*%*#@@@@#=-----:---
	=--------=*@@@%%%**=.  . .-%@@@*--:--:-::-
	-------====+****=: .**=..:-=+**=-=----:---
	==--===-===+=-=+=:::=*-:--=+===-=-------:-
	-------====+=======-:::-=======-=---------
	-----====+*#-=#@%%%*==+#%%@%-:*====-::----
	------==+%@*:=%@%%@@@@@@@@@%=-=@%==-------
	------=+@@@*:=*@@@%#*##%@@@%+-=%@@==---:--
	-----==%@@@@+:==+==--==+**#*==*@@@#=--:---
	=---==*@@@@@@*:::::-:::-:-=++#@@@@@=:-----
	=====+%@@@@@@@%*::::.::::-=*%@@@@@@#------
]]--

---Food Settings
food_to_eat = false --"Yakow Moussaka <hq>"             --Name of the food you want to use, in quotes (ie. "[Name of food]"), or
                                                        --Table of names of the foods you want to use (ie. {"[Name of food 1]", "[Name of food 2]"}), or
                                                        --Set false otherwise.
                                                        --Include <hq> if high quality. (i.e. "[Name of food] <hq>") DOES NOT CHECK ITEM COUNT YET
eat_food_threshold = 10                                 --Maximum number of seconds to check if food is consumed

---Repair/Materia Settings
do_repair   = "self"                                    --false, "npc" or "self". Add a number to set threshhold; "npc 10" to only repair if under 10%
repair_threshold = 50									--value at which to repair gear

do_extract  = true                                      --If true, will extract materia if possible
do_reduce   = false                                     --If true, will perform aetherial reduction if possible
do_retainers = true										--true enables Auto Retainer logic when a retainer is ready. Requires Auto Retainer plugin
summonning_bell_name = "Summoning Bell"					--Change this to the summonning bell name when playing in another language	

---Gathering logic Settings
num_inventory_free_slot_threshold = 1                   --Max number of free slots to be left before stopping script
interval_rate = 0.2                                     --Seconds to wait for each action

timeout_threshold = 10                                  --Maximum number of seconds script will attempt to wait before timing out and continuing the script


-- MAIN
function main()
		
	stop_main = false	
	
	Print("-----This script assumes you start with GBR OFF! If you have an issue make sure to turn GBR auto-gathering off before starting this script.-----") --Overall to do when GBR has on/o
	Print("-----There's currently issues with GBR when the auto-gather list has different materials in the same area. If you encounter pathing issues, try to use an auto gather list with only one resource node-----")
	
	yield("/gbr auto") -- enabling gbr
	Print("Enabling bgr auto-gathering")
	
	while not stop_main do -- Main Loop
					
		if not GetCharacterCondition(6) then EatFood() end
		
		if(HasActionsToDo()) then
			yield("/gbr auto") -- to improve
			Print("Actions required, pausing gbr")
			RepairExtractReduceCheck()
			yield("/wait "..interval_rate)
			CheckRetainers()
			yield("/gbr auto") -- to improve
			Print("Actions finished, enabling gbr")	
		end
		
		
		if (not GetCharacterCondition(6) and not RepairExtractReduceCheck())
			or GetInventoryFreeSlotCount() <= num_inventory_free_slot_threshold then
				if GetInventoryFreeSlotCount() <= num_inventory_free_slot_threshold then
					Print("Inventory free slot threshold reached. Disabling gbr and script")
				end
				
			stop_main = true
			yield("/gbr auto") -- disabling gbr, to improve when we get on/off commands
			return
		end
		
		repeat
			yield("/wait "..interval_rate)
		until not (GetCharacterCondition(6) or GetCharacterCondition(32)) and IsPlayerAvailable()
		
		yield("/wait "..interval_rate)
	end
end

--Check if actions needed
function HasActionsToDo()

	return (do_repair and IsNeedRepair())
		or (do_extract and CanExtractMateria())
		or (do_reduce and HasReducibles() and GetInventoryFreeSlotCount() + 1 > num_inventory_free_slot_threshold)
		or (do_retainers and ARRetainersWaitingToBeProcessed())
		
end

--Wrapper for repair/materia/aetherial reduction check, return true if repaired and extracted materia
function IsNeedRepair()
	if type(do_repair) ~= "string" then
		return false
	else
		repair_threshold = tonumber(repair_threshold) or 99
		if NeedsRepair(tonumber(repair_threshold)) then
			if string.find(string.lower(do_repair), "self") then
				return "self"
			else
				return "npc"
			end
		else
			return false
		end
	end
end

function HasReducibles()
	while not IsAddonVisible("PurifyItemSelector") and not IsAddonReady("PurifyItemSelector") do
		yield('/gaction "Aetherial Reduction"')
		local timeout_start = os.clock()
		repeat
			yield("/wait "..interval_rate)
		until IsNodeVisible("PurifyItemSelector", 1, 6) or IsNodeVisible("PurifyItemSelector", 1, 7) or os.clock() - timeout_start > timeout_threshold
	end
	yield("/wait "..interval_rate)
	local visible = IsNodeVisible("PurifyItemSelector", 1, 7) and not IsNodeVisible("PurifyItemSelector", 1, 6)
	while IsAddonVisible("PurifyItemSelector") do
		yield('/gaction "Aetherial Reduction"')
		repeat
			yield("/wait "..interval_rate)
		until IsPlayerAvailable()
	end
	return not visible
end

function RepairExtractReduceCheck() 

    local repair_token = IsNeedRepair()
    if repair_token then
        if repair_token == "self" then
			
			yield("/wait 1")
			while GetCharacterCondition(27) do -- while casting (mount probably)
				yield("/wait "..interval_rate)
			end
						
            StopMoveFly()
            if GetCharacterCondition(4) then
                Print("Attempting to dismount...")
                Dismount()
            end
            Print("Attempting to self repair...")
            while not IsAddonVisible("Repair") and not IsAddonReady("Repair") do
                yield('/gaction "Repair"')
                repeat
                    yield("/wait "..interval_rate)
                until IsPlayerAvailable()
            end
			yield("/wait 0.1")
            yield("/pcall Repair true 0")
            repeat
                yield("/wait "..interval_rate)
            until IsAddonVisible("SelectYesno") and IsAddonReady("SelectYesno")
            yield("/pcall SelectYesno true 0")
            repeat
                yield("/wait "..interval_rate)
            until not IsAddonVisible("SelectYesno")
            while GetCharacterCondition(39) do yield("/wait "..interval_rate) end
            while IsAddonVisible("Repair") do
                yield('/gaction "Repair"')
                repeat
                    yield("/wait "..interval_rate)
                until IsPlayerAvailable()
            end
            if NeedsRepair() then
                Print("Self Repair failed!")
                Print("Please place the appropriate Dark Matter in your inventory,")
                Print("Or find a NPC mender.")
                return false
            else
                Print("Repairs complete!")
            end
        elseif repair_token == "npc" then
            Print("Equipment below "..repair_threshold.."%!")
            Print("Please go find a NPC mender.")
            return false
        end
    end

    if do_extract and CanExtractMateria() and GetInventoryFreeSlotCount() + 1 > num_inventory_free_slot_threshold then
        StopMoveFly()
        if GetCharacterCondition(4) then
            Print("Attempting to dismount...")
            Dismount()
        end
        Print("Attempting to extract materia...")
        while not IsAddonVisible("Materialize") and not IsAddonReady("Materialize") do
                yield('/gaction "Materia Extraction"')
                repeat
                    yield("/wait "..interval_rate)
                until IsPlayerAvailable()
        end
        while CanExtractMateria() and GetInventoryFreeSlotCount() + 1 > num_inventory_free_slot_threshold do
yield("/wait 0.1")
            yield("/pcall Materialize true 2 0")
            repeat
                yield("/wait 1")
            until not GetCharacterCondition(39)
        end
        while IsAddonVisible("Materialize") do
            yield('/gaction "Materia Extraction"')
            repeat
                yield("/wait "..interval_rate)
            until IsPlayerAvailable()
        end
        if CanExtractMateria() then
            Print("Failed to fully extract all materia!")
            Print("Please check your if you have spare inventory slots,")
            Print("Or manually extract any materia.")
            return false
        else
            Print("Materia extraction complete!")
        end
    end

    

    if do_reduce and HasReducibles() and GetInventoryFreeSlotCount() + 1 > num_inventory_free_slot_threshold then
        StopMoveFly()
        if GetCharacterCondition(4) then
            Print("Attempting to dismount...")
            Dismount()
        end
        Print("Attempting to perform aetherial reduction...")
        repeat
            yield('/gaction "Aetherial Reduction"')
            local timeout_start = os.clock()
            repeat
                yield("/wait "..interval_rate)
            until IsNodeVisible("PurifyItemSelector", 1, 6) or IsNodeVisible("PurifyItemSelector", 1, 7) or os.clock() - timeout_start > timeout_threshold
        until IsAddonVisible("PurifyItemSelector") and IsAddonReady("PurifyItemSelector")
        yield("/wait "..interval_rate)
        while not IsNodeVisible("PurifyItemSelector", 1, 7) and IsNodeVisible("PurifyItemSelector", 1, 6) and GetInventoryFreeSlotCount() > num_inventory_free_slot_threshold do
            yield("/pcall PurifyItemSelector true 12 0")
            repeat
                yield("/wait "..interval_rate)
            until not GetCharacterCondition(39)
        end
        while IsAddonVisible("PurifyItemSelector") do
            yield('/gaction "Aetherial Reduction"')
            repeat
                yield("/wait "..interval_rate)
            until IsPlayerAvailable()
        end
        Print("Aetherial reduction complete!")
    end

    return true
end



--Wrapper for food checking, and if want to consume, consume if not fooded
function EatFood()
    if type(food_to_eat) ~= "string" and type(food_to_eat) ~= "table" then return end
    if GetZoneID() == 1055 then return end
    
    if not HasStatus("Well Fed") then
        local timeout_start = os.clock()
        local user_settings = {GetSNDProperty("UseItemStructsVersion"), GetSNDProperty("StopMacroIfItemNotFound"), GetSNDProperty("StopMacroIfCantUseItem")}
        SetSNDProperty("UseItemStructsVersion", "true")
        SetSNDProperty("StopMacroIfItemNotFound", "false")
        SetSNDProperty("StopMacroIfCantUseItem", "false")
        repeat
            if type(food_to_eat) == "string" then
                Print("Attempt to consume " .. food_to_eat)
                yield("/item " .. food_to_eat)
            elseif type(food_to_eat) == "table" then
                for _, food in ipairs(food_to_eat) do
                    yield("/item " .. food)
                    yield("/wait " .. math.max(interval_rate, 1))
                    if HasStatus("Well Fed") then break end
                end
            end

            yield("/wait " .. math.max(interval_rate, 1))
        until HasStatus("Well Fed") or os.clock() - timeout_start > eat_food_threshold
        SetSNDProperty("UseItemStructsVersion", tostring(user_settings[1]))
        SetSNDProperty("StopMacroIfItemNotFound", tostring(user_settings[2]))
        SetSNDProperty("StopMacroIfCantUseItem", tostring(user_settings[3]))
    end
end

--Wrapper to handle Retainers
function CheckRetainers()
	if do_retainers == true then
		if ARRetainersWaitingToBeProcessed() == true then
			while not IsInZone(129) do
				yield("/tp limsa")
				yield("/wait 7")
			end
			
			while IsPlayerAvailable() == false do
				yield("/wait 1")
			end
			
			CheckNavmeshReady()
			
			if not PathIsRunning() and not PathfindInProgress() then
				PathfindAndMoveTo(-122.7251, 18.0000, 20.3941)
				yield("/wait 1")
			end
			while PathIsRunning() or PathfindInProgress() do
				yield("/wait 1")
			end
			while GetTargetName() ~= summonning_bell_name do
				yield("/target "..summonning_bell_name)
				yield("/wait 0.5")
			end 
			yield("/interact")
			yield("/wait 0.5")
			yield("/ays e")
			Print("Processing retainers...")
			while ARRetainersWaitingToBeProcessed() == true do
				yield("/wait 1")
			end
			yield("/waitaddon RetainerList")
			while not IsAddonVisible("RetainerList") do
				yield("/wait 1")
			end
			yield("/wait 1")
			Print("Finished processing retainers")
			yield("/wait 1")
			yield("/pcall RetainerList true -1")
			yield("/wait 1")
			while GetCharacterCondition(45) do
				yield("/wait 1")
			end
		end
	end
end

--Wrapper to handle stopping vnavmesh movement
function StopMoveFly()
    PathStop()
    while PathIsRunning() do
        yield("/wait "..interval_rate)
    end
end

--Wrapper to dismount
function Dismount()
    if GetCharacterCondition(77) then
        local random_j = 0
        ::DISMOUNT_START::
        CheckNavmeshReady()
        local land_x
        local land_y
        local land_z
        local i = 0
        while not land_x or not land_y or not land_z do
            land_x = QueryMeshPointOnFloorX(GetPlayerRawXPos() + math.random(0, random_j), GetPlayerRawYPos() + math.random(0, random_j), GetPlayerRawZPos() + math.random(0, random_j), false, i)
            land_y = QueryMeshPointOnFloorY(GetPlayerRawXPos() + math.random(0, random_j), GetPlayerRawYPos() + math.random(0, random_j), GetPlayerRawZPos() + math.random(0, random_j), false, i)
            land_z = QueryMeshPointOnFloorZ(GetPlayerRawXPos() + math.random(0, random_j), GetPlayerRawYPos() + math.random(0, random_j), GetPlayerRawZPos() + math.random(0, random_j), false, i)
            i = i  + 1
        end
        NodeMoveFly("land,"..land_x..","..land_y..","..land_z)


        local timeout_start = os.clock()
        repeat
            yield("/wait "..interval_rate)
            if os.clock() - timeout_start > timeout_threshold then
                Print("Failed to navigate to dismountable terrain.")
                Print("Trying another place to dismount...")
                random_j = random_j + 1
                goto DISMOUNT_START
            end
        until not PathIsRunning()

        yield('/gaction "Mount Roulette"')

        timeout_start = os.clock()
        repeat
            yield("/wait "..interval_rate)
            if os.clock() - timeout_start > timeout_threshold then
                Print("Failed to dismount.")
                Print("Trying another place to dismount...")
                random_j = random_j + 1
                goto DISMOUNT_START
            end
        until not GetCharacterCondition(77)
    end
    if GetCharacterCondition(4) then
        yield('/gaction "Mount Roulette"')
        repeat
            yield("/wait "..interval_rate)
        until not GetCharacterCondition(4)
    end
end

--Wrapper to handle vnavmesh Movement
function NodeMoveFly(node, force_moveto)
    local force_moveto = force_moveto or false
    local x = tonumber(ParseNodeDataString(node)[2]) or 0
    local y = tonumber(ParseNodeDataString(node)[3]) or 0
    local z = tonumber(ParseNodeDataString(node)[4]) or 0
    last_move_type = last_move_type or "NA"

    CheckNavmeshReady()
    start_pos = Truncate1Dp(GetPlayerRawXPos())..","..Truncate1Dp(GetPlayerRawYPos())..","..Truncate1Dp(GetPlayerRawZPos())
    if not force_moveto and ((GetCharacterCondition(4) and GetCharacterCondition(77)) or GetCharacterCondition(81)) then
        last_move_type = "fly"
        PathfindAndMoveTo(x, y, z, true)
    else
        last_move_type = "walk"
        PathfindAndMoveTo(x, y, z)
    end
    while PathfindInProgress() do
        yield("/wait "..interval_rate)
    end
end

--Parse given string containing node name and co-ords and returns a table containing them
function ParseNodeDataString(string)
    return Split(string, ",")
end

function Split (inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

--Returns given number truncated to 1 decimal place
function Truncate1Dp(num)
    return truncate and ("%.1f"):format(num) or num
end

--Wrapper to check navmesh readiness
function CheckNavmeshReady()
    was_ready = NavIsReady()
    while not NavIsReady() do
        Print("Building navmesh, currently at "..Truncate1Dp(NavBuildProgress()*100).."%")
        yield("/wait "..(interval_rate * 10))
    end
    if not was_ready then Print("Navmesh is ready!") end
end


--Prints given string into chat with script identifier
function Print(message)
	yield("/echo "..message)
end

main()