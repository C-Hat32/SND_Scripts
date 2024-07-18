--[[

	Name: GBR Helper
	Author: C.Hat32
	Description: Helper for GatherBuddyReborn to handle food, repairs, materia extraction, aetherial reduction and retainers
	Version: 1.3.1
	
	Credits:
	LeafFriend for the navigation/materia extract/misc wrapper functions, in their GatheringHelper script
	Link: https://github.com/Jaksuhn/SomethingNeedDoing/blob/master/Community%20Scripts/Gathering/GatheringHelper.lua
	
	plottingCreeper for the Food/Repair management features
	Link: https://github.com/plottingCreeper/FFXIV-scripts-and-macros
	
	Prawellp for the AutoRetainer function, in their Fate Farming script
	Link: https://github.com/Prawellp/FFXIV-SND/blob/main/Fate%20Farming.lua
	
	
	<Changelog>
	1.0		:	First version of the script. The following features work: Repair/Materia extraction/Food/AutoRetainer. 
				Untested features (but expected to work): Aetherial Reduction
			
	1.0.1	:	Updated plugins dependancies and added a dependancy check
				Fixed some features being called while changing areas
	
	1.1		:	Added a random wait option. To enable, put do_random_pause = true
	
	1.2		:	Added potion usage, by LeChuckXIV
				Changed /gbr auto usage to use specific on/off commands
				Added auto stop on Duty Pop
				
	1.2.1	:	Reset pause timer when doing retainers
	
	1.3		:	Attempting to fix an issue when GBR wants to change area while waiting on script actions
				Implemented an unstuck feature to try and dislodge/dismount the character when it's stuck on a path
				
	1.3.1	:	Improved the unstuck logic
				Various unstuck bugfixes
				Impremented another check to prevent an issue with materias/repair while mounted
	
	<Additional Information>
	Needed Plugins: 
		SomethingNeedDoing (Expanded Edition): https://puni.sh/api/repository/croizat
			-> Enable lua on this script
		GatherBuddyReborn
		vnavmesh
			
	Optional plugins: 
		For retainers feature:
			Auto Retainer
			Teleporter
				Required to teleport to Limsa for AutoRetainer
				
		For repair/extract materias/aetherial reduction features:
			YesAlready:
				Enable: -> Bothers -> MaterializeDialog
				
				
	
	Additional advice for GBR:
	- Set GBR > Config > Auto-Gather > General > Mount Up Distance to 30 
	- Set GBR > Config > Auto-Gather > Advanced > Far Node Filter Distance to 100+ 
	- There's currently issues with GBR when the auto-gather list has different materials in the same area. If you encounter pathing issues, try to use an auto gather list with only one resource node
	
	
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
food_to_eat = false 						            --Name of the food you want to use, in quotes (ie. "[Name of food]"), or
                                                        --Table of names of the foods you want to use (ie. {"[Name of food 1]", "[Name of food 2]"}), or
                                                        --Set false otherwise.
                                                        --Include <hq> if high quality. (i.e. "[Name of food] <hq>") DOES NOT CHECK ITEM COUNT YET
eat_food_threshold = 10                                 --Maximum number of seconds to check if food is consumed

---Pot Settings
pot_to_drink = false 									--Name of the potion you want to use, in quotes (ie. "[Name of potion]"), or
                                                        --Table of names of the foods you want to use (ie. {"[Name of potion 1]", "[Name of potion 2]"}), or
                                                        --Set false otherwise.
                                                        --Include <hq> if high quality. (i.e. "[Name of potion] <hq>") DOES NOT CHECK ITEM COUNT YET
														
drink_pot_threshold = 10                                --Maximum number of seconds to check if potion is consumed

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

do_random_pause = false									--Make random pauses at set intervals
pause_duration = 40										--Pause duration in seconds
pause_duration_rand = 10								--Random range for the pause duration, in seconds
pause_delay = 900										--Time between two pauses, in seconds
pause_delay_rand = 120									--Random range for the time between two pauses, in seconds
timeout_threshold = 10                                  --Maximum number of seconds script will attempt to wait before timing out and continuing the script

---Stuck Prevention Settings
do_try_unstuck = true
stuck_time = 2											--Time not moving before considering player is stuck
time_to_wait_after_dislodge = 8							--Wait time between the unstuck movement and the next actions
stuck_distance_allowed = 0.05							--Error margin for considering character is not moving
position_rounding_precision = 2							--Numbers of decimals to keep when checking the player position


-- INIT
stop_main = false

last_pause = os.clock()
next_pause_time = pause_delay + math.random(-pause_delay_rand, pause_delay_rand)
last_player_position = {x = 0, y = 0, z = 0}
last_checkstuck_time = os.clock()


-- MAIN
function main()	
		
	if not HasAllDependencies() then
		return
	end	
	
	if (do_random_pause) then
		Print("Next pause in "..GetTimeString(next_pause_time))
	end
	last_player_position = GetPlayerPosition()
	
	yield("/gbr auto on") -- enabling gbr
	WaitNextLoop()
	
	while not stop_main do -- Main Loop
		
		if (CheckQueue()) then return end
		
		if not GetCharacterCondition(6) then EatFood() end
		if not GetCharacterCondition(6) then DrinkPot() end
				
		if(HasActionsToDo()) then
			
			yield("/gbr auto off")
			Print("Actions required, pausing gbr")
			
			while (GetCharacterCondition(27) or GetCharacterCondition(45)) and not IsPlayerAvailable() do -- while busy
				yield("/wait "..interval_rate)
			end
			yield("/wait 1.5")
			
			RepairExtractReduceCheck()
			if (CheckQueue()) then return end
			
			yield("/wait "..interval_rate)
			CheckRetainers()
			if (CheckQueue()) then return end
			
			yield("/gbr auto on")
			Print("Actions finished, enabling gbr")	
			ResetStuck()
		end		
		
		if (not GetCharacterCondition(6) and not RepairExtractReduceCheck())
			or GetInventoryFreeSlotCount() <= num_inventory_free_slot_threshold then
				if GetInventoryFreeSlotCount() <= num_inventory_free_slot_threshold then
					Print("Inventory free slot threshold reached. Disabling gbr and script")
				end
				
			stop_main = true
			yield("/gbr auto off") -- disabling gbr
			return
		end
		
		CheckStuck()
		
		if (do_random_pause) then
			CheckRandomPause()
		end
		
		WaitNextLoop()
		
		yield("/wait "..interval_rate)
	end
end

function WaitNextLoop()

	while (GetCharacterCondition(6) or GetCharacterCondition(32) or GetCharacterCondition(45) or GetCharacterCondition(27) or not IsPlayerAvailable() or PathfindInProgress()) do
		yield("/wait "..interval_rate)
		ResetStuck()
	end
end

--Wrapper for the random pause
function CheckRandomPause()

	if not do_random_pause then return end
	
	if (os.clock() - last_pause > next_pause_time) then
		
		local current_pause_duration = pause_duration + math.random(-pause_duration_rand, pause_duration_rand)
		Print("Pausing gbr for "..GetTimeString(current_pause_duration))		
		yield("/gbr auto off")
		
		local current_pause_start = os.clock()		
		repeat
			yield("/wait "..interval_rate)
			if (CheckQueue()) then return end
		until os.clock() - current_pause_start > current_pause_duration
		
		yield("/wait "..current_pause_duration)
		
		last_pause = os.clock()
		next_pause_time = pause_delay + math.random(-pause_delay_rand, pause_delay_rand)
		Print("Resuming gbr. Next pause in "..GetTimeString(next_pause_time))
		ResetStuck()
		yield("/gbr auto on")	
	end
end

--Check plugins dependencies
function HasAllDependencies()

	local allDependencies = true
	
	if not HasPlugin("vnavmesh") then
		Print("Please Install vnavmesh")
		allDependencies = false
	end
	if not HasPlugin("GatherbuddyReborn") then
		Print("Please Install Gather Buddy Reborn")
		allDependencies = false
	end
	
	--Optional dependencies
	if do_retainers == true then
		if not HasPlugin("AutoRetainer") then
			Print("Please Install AutoRetainer")
			allDependencies = false
		end
		if not HasPlugin("TeleporterPlugin") then
			Print("Please Install Teleporter")
			allDependencies = false
		end
	end
	if do_extract == true or do_repair == true or do_reduce == true then
		if not HasPlugin("YesAlready") then
			Print("Please Install YesAlready")
			allDependencies = false
		elseif do_extract == true then
			Print("Materia extraction detected. Please make sure YesAlready setting -> Bothers -> MaterializeDialog option is enabled.")
		end
	end
	
	if (food_to_eat == true or pot_to_drink == true) then
		Print("STOPPING SCRIPT!")
		Print("Please specify a food/drink name instead of 'true'")
		allDependencies = false
	end
	
	if(do_reduce == true) then
		Print("Warning: You're using the untested Aetherial Reduction feature. Issues may occur.")
	end
	
	return allDependencies
	
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
						
            StopMoveFly()
            if GetCharacterCondition(4) then
                Print("Attempting to dismount...")
                Dismount()
            end
            Print("Attempting to self repair...")
            while not IsAddonVisible("Repair") and not IsAddonReady("Repair") do
				if GetCharacterCondition(4) then
					Print("Attempting to dismount...")
					Dismount()
				end
				
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
            if GetCharacterCondition(4) then
                Print("Attempting to dismount...")
                Dismount()
            end
			
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
        repeat --Show reduction window
            yield('/gaction "Aetherial Reduction"')
            local timeout_start = os.clock()
            repeat
                yield("/wait "..interval_rate)
            until IsNodeVisible("PurifyItemSelector", 1, 6) or IsNodeVisible("PurifyItemSelector", 1, 7) or os.clock() - timeout_start > timeout_threshold
        until IsAddonVisible("PurifyItemSelector") and IsAddonReady("PurifyItemSelector")
        yield("/wait "..interval_rate)
        while not IsNodeVisible("PurifyItemSelector", 1, 7) and IsNodeVisible("PurifyItemSelector", 1, 6) and GetInventoryFreeSlotCount() > num_inventory_free_slot_threshold do -- reduce all
			if GetCharacterCondition(4) then
				Print("Attempting to dismount...")
				Dismount()
			end
            yield("/pcall PurifyItemSelector true 12 0")
            repeat
                yield("/wait "..interval_rate)
            until not GetCharacterCondition(39)
			
			if (stop_main) then 
				yield('/gaction "Aetherial Reduction"')
				return 
			end
        end
        while IsAddonVisible("PurifyItemSelector") do --Hide reduction window
            yield('/gaction "Aetherial Reduction"')
            repeat
                yield("/wait "..interval_rate)
            until IsPlayerAvailable()		
        end
        Print("Aetherial reduction complete!")
    end

    return true
end

function CheckQueue()

	if GetCharacterCondition(59) then -- Queue popped
		stop_main = true
		Print("Queue pop, stopping script and gbr")
		WaitNextLoop()
		yield("/gbr auto off")
		return true
	end
	
	return false
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

function DrinkPot()
    if type(pot_to_drink) ~= "string" and type(pot_to_drink) ~= "table" then return end
    if GetZoneID() == 1055 then return end
    
    if not HasStatus("Medicated") then
        local timeout_start = os.clock()
        local user_settings = {GetSNDProperty("UseItemStructsVersion"), GetSNDProperty("StopMacroIfItemNotFound"), GetSNDProperty("StopMacroIfCantUseItem")}
        SetSNDProperty("UseItemStructsVersion", "true")
        SetSNDProperty("StopMacroIfItemNotFound", "false")
        SetSNDProperty("StopMacroIfCantUseItem", "false")
        repeat
            if type(pot_to_drink) == "string" then
                Print("Attempt to consume " .. pot_to_drink)
                yield("/item " .. pot_to_drink)
            elseif type(pot_to_drink) == "table" then
                for _, pot in ipairs(pot_to_drink) do
                    yield("/item " .. pot)
                    yield("/wait " .. math.max(interval_rate, 1))
                    if HasStatus("Medicated") then break end
                end
            end

            yield("/wait " .. math.max(interval_rate, 1))
        until HasStatus("Medicated") or os.clock() - timeout_start > drink_pot_threshold
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
			
			if (IsAddonVisible("RetainerList")) then
				yield("/waitaddon RetainerList")
			end
			while not IsAddonVisible("RetainerList") do
				yield("/wait 1")
			end
			yield("/wait 1")
			Print("Finished processing retainers")
			yield("/wait 1")
			if (IsAddonVisible("RetainerList")) then
				yield("/pcall RetainerList true -1")
			end
			yield("/wait 1")
			while GetCharacterCondition(45) do
				yield("/wait 1")
			end
			if (do_random_pause) then
				last_pause = os.clock() -- set last pause as now as we're already doing something other than gathering
				Print("Reset pause timer. Next pause in "..GetTimeString(next_pause_time))
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

function UnstuckFly()
	
	Print("Dismounting.")
	yield("/gbr auto off")
	yield("/wait "..interval_rate)
	Dismount()
	yield("/gbr auto on")
	yield("/wait "..(time_to_wait_after_dislodge + math.random(0, 3 * 1000) / 1000))
    Print("Waiting for "..Truncate1Dp(time_to_wait_after_dislodge + math.random(0, 3 * 1000) / 1000).."s before moving on...")
end

--Wrapper handling when player stopped moving
function UnstuckGeneric(target)
    Print("Attempting to dislodge...")
	yield("/gbr auto off")

    --Implement random coord base on current player position
    PathMoveTo(tonumber(GetPlayerRawXPos()+math.random(-5, 5)),
        tonumber(GetPlayerRawYPos()+math.random(-5, 5)),
        tonumber(GetPlayerRawZPos()+math.random(-5, 5)))
	
	yield("/wait "..interval_rate * 3)
	yield("/gbr auto on")
    yield("/wait "..(time_to_wait_after_dislodge + math.random(0, 3 * 1000) / 1000))
    Print("Waiting for "..Truncate1Dp(time_to_wait_after_dislodge + math.random(0, 3 * 1000) / 1000).."s before moving on...")
end

function ComparePositionsByMagnitude(pos1, pos2)
    local distance = CalculateDistance(pos1, pos2)
    return distance <= stuck_distance_allowed
end

function CalculateDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function GetPlayerPosition()

	local xPos = Round(tonumber(GetPlayerRawXPos()) or 0, position_rounding_precision)
	local yPos = Round(tonumber(GetPlayerRawYPos()) or 0, position_rounding_precision)
	local zPos = Round(tonumber(GetPlayerRawZPos()) or 0, position_rounding_precision)
	return {x = xPos, y = yPos, z = zPos}
end

--Check if player is stuck
function CheckStuck()

	if (GetCharacterCondition(6) or GetCharacterCondition(32) or GetCharacterCondition(45) or GetCharacterCondition(27) or not IsPlayerAvailable() or not NavIsReady() or PathfindInProgress()) then
		ResetStuck()
		return 
	end
	
	if os.clock() - last_checkstuck_time < math.max(stuck_time, 1.5) then return end
	
	last_checkstuck_time = os.clock()
	
	new_player_position = GetPlayerPosition()
	if (ComparePositionsByMagnitude(new_player_position, last_player_position)) then -- Player is stuck
		Print("Player stuck detected.")
		--Unstuck the player in the right way
		
		if PathIsRunning() then
			UnstuckGeneric()
		elseif GetCharacterCondition(4) then
			UnstuckFly()
		else
			UnstuckGeneric()
		end
	end	
	
	last_player_position = new_player_position
	WaitNextLoop()
	
end

function ResetStuck()
	last_player_position = GetPlayerPosition()
	last_checkstuck_time = os.clock()
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

--Converts time to minutes and seconds
function GetTimeString(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%dm %02ds", minutes, remainingSeconds)
end

--Rounds a number with decimals precision
function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

--Prints given string into chat with script identifier
function Print(message)
	yield("/echo [GBR HELPER] "..message)
end

main()
