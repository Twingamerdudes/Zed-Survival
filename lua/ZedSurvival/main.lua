local activated = false
local time = 4
local zombieStrength = 4 -- 4 + 1 = 5
local zombieLethality = 2 -- 2 + 1 = 3
local zombiesKilled = 0
local zombies = 0
local capZombies = true
local maxZombies = 40
local roster = nil
local survivor = nil
local swarmCount = 1
function Start()
    roster = GetSquadRoster(GetSquadName(Player))
end

function Cutscene(duo)
    if duo then
        if roster[1] == Player then
            PlayCutscene("good.json", nil, true, 401)
        else
            PlayCutscene("good2.json", nil, true, 401)
        end
    else
        PlayCutscene("start.json", nil, true, 400)
    end
end

function SpawnZombie(originalZombie)
    if zombies >= maxZombies then
        if capZombies then
            RunAfter(1, "SpawnZombie", {originalZombie})
            return
        end
    end
    zombies = zombies + 1
    local zed = SpawnCharacterAtEntrance("Zed", true, Factions.Zeds)
    if Exists(zed) then
        zombieStrength = zombieStrength + 1
        ChangeProperty(zed, {zombieStrength}, "strength")
        zombieLethality = zombieLethality + 1
        ChangeProperty(zed, {zombieLethality}, "lethality")
    end
    if time > 3 then
        time = time - 0.05
    end
    if originalZombie then
        for i = 1, swarmCount do
            if i == 1 then
                RunAfter(time, "SpawnZombie", {true})
            else
                RunAfter(time, "SpawnZombie", {false})
            end
        end
    end
end

function Callback(ctype, args)
    if activated then
        if ctype == "death" then
            if string.find(args[1], "Zed") then
                zombiesKilled = zombiesKilled + 1
                zombies = zombies - 1
                if zombies < 0 then
                    zombies = 0
                end
                if maxZombies < 150 then
                    maxZombies = math.max(maxZombies, zombiesKilled)
                end
                if zombiesKilled % 7 == 0 then
                    swarmCount = swarmCount + 1
                end
            end
            if args[1] == Player then
                if not FileExists("highscore.txt") then
                    WriteToFile("highscore.txt", zombiesKilled)
                else
                    local highscore = ReadFile("highscore.txt")
                    if tonumber(highscore) < zombiesKilled then
                        WriteToFile("highscore.txt", zombiesKilled)
                    end
                end
                for i = 1, #roster do
                    ChangeProperty(roster[i], {"dead", true}, "state")
                end
            end
        end
    end
end


function SpawnSurvivor()
    if zombiesKilled < -15 + (#roster * 11) then
        RunAfter(1, "SpawnSurvivor")
        return
    end
    local character = ReturnRandomObject("character")
    survivor = SpawnCharacterAtEntrance(character[1], true, Factions.Player)
    if not Exists(survivor) then
        --destroy everything that isn't a zed or in a player squad
        local all = GetAllCharacters(true)
        for i = 1, #all do
            if not string.find(all[i], "Zed") and not string.find(GetSquadName(all[i]), "Player") then
                Destroy(all[i])
            end
        end
        RunAfter(1, "SpawnSurvivor")
        return
    end
    AddSerial(survivor, "survivor")
    PlayCutscene("survivors.json", {survivor}, true, 190)
    AddToSquad(GetSquadName(Player), survivor)
    roster = GetSquadRoster(GetSquadName(Player))
    local weapon = ReturnRandomObject("weapon")
    if weapon[1] == "None" then
        while weapon[1] == "None" do
            weapon = ReturnRandomObject("weapon")
        end
    end
    ChangeProperty(survivor, {weapon[1], weapon[2]}, "weapon")
    RunAfter(8, "SpawnSurvivor")
end
function CutsceneCallback(id)
    if id == 400 then
        PlayMusic("event:/Music/Locknar/Blood Son")
        local zed = SpawnCharacterAtEntrance("Zed", true, Factions.Zeds)
        zombies = zombies + 1
        if Exists(zed) then
            zombieStrength = GetProperty(zed, "strength")
            zombieLethality = GetProperty(zed, "lethality")
        end
        RunAfter(5, "SpawnZombie", {true})
        RunAfter(8, "SpawnSurvivor")
        activated = true
    elseif id == 190 then
        RemoveSerial(survivor, "survivor")
    elseif id == 401 then
        PlayMusic("event:/Music/Locknar/Blood Bath")
        local zed = nil
        if roster[1] == Player then
            zed = roster[2]
        else
            zed = roster[1]
        end
        RemoveFromSquad(zed)
        SetFaction(zed, Factions.Zeds)
        MakeSquad("Victim squad", zed, Factions.Zeds)
        ChangeProperty(zed, {"Zed"}, "character")
        zombies = zombies + 1
        if Exists(zed) then
            zombieStrength = GetProperty(zed, "strength")
            zombieLethality = GetProperty(zed, "lethality")
        end
        RunAfter(5, "SpawnZombie", {true})
        RunAfter(8, "SpawnSurvivor")
        activated = true
    end
end

function ButtonCallback(id)
    if id == 69 then
        RunAfter(1, "Cutscene", {#roster == 2})
    elseif id == 800 then
        if FileExists("highscore.txt") then
            local highscore = ReadFile("highscore.txt")
            CreateMenuUI("Highscore", "Highscore: " .. highscore, {"Ok"}, {900})
        else
            CreateMenuUI("Highscore", "No highscore yet", {"Ok"}, {900})
        end
    elseif id == 900 then
        capZombies = false
    elseif id == 1000 then
        capZombies = true
    end
end

function Update()
    if GetKeyDown("Semicolon") and not activated then
        CreateMenuUI("Are you sure you want to run this mod?", "This mod will make you unable to progress in the current stage, you will have to restart the stage to play normally again. Are you sure you want to do this?", {"Yes", "No", "Checkout highscore"}, {69, 420, 800})
    end
    if GetKeyDown("Quote") and not activated then
        CreateMenuUI("Zombie survival settings", "Configure settings for zombie survival", {"Infinite zombies (god PC)", "40 zombies max"}, {900, 1000})
    end
end