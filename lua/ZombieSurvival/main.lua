local level = 1
local normalZedAttack
local activated = false
local Victim = nil
local ZedsKilled = 0
local multiplier = 1
local SquadName
local ZombieCount = 0
local Retries = 0
local wasDuo = false
function Start()

end

function SetupZombie(zombie)
    if zombie == nil or not Exists(zombie) then
        Retries = Retries + 1
        if Retries == 3 then
            ZombieCount = ZombieCount - 1
            Retries = 0
            return
        end
        SetupZombie(zombie)
        return
    end
    ChangeProperty(zombie, {math.ceil(10 * multiplier / 2.2)}, "strength")
    RemoveFromSquad(zombie)
    AddToSquad(SquadName, zombie)
    math.randomseed(os.time())
    ChangeProperty(zombie, {Player}, "target")
    multiplier = multiplier + 1
end

function Zombies()
    ZombieCount = ZombieCount + 1
    local zed = SpawnCharacterAtEntrance("Zed", true)
    RunAfter(1, "SetupZombie", {zed})
    return zed
end


function ZombiesAgent(pos)
    ZombieCount = ZombieCount + 1
    local zed = SpawnCharacter("Zed Agent", pos, true)
    RunAfter(1, "SetupZombie", {zed})
    return zed
end

function ZombiesPos(pos)
    ZombieCount = ZombieCount + 1
    local zed = SpawnCharacter("Zed", pos, true)
    RunAfter(1, "SetupZombie", {zed})
    return zed
end

function ZombieLeader()
    ZombieCount = ZombieCount + 1
    local zed = SpawnCharacterAtEntrance("Zed", true)
    SquadName = GetSquadName(zed)
    RunAfter(1, "SetupZombie", {zed})
    return zed
end
function Callback(ctype, args)
    if ctype == "death" and activated then
        if string.match(args[1], "Zed") or string.match(args[1], "Zed Agent") then
            ZedsKilled = ZedsKilled + 1
            ZombieCount = ZombieCount - 1
            for i = 1, ZedsKilled + 1 do
                if ZombieCount <= 10 then
                    Zombies()
                end
            end
        elseif string.match(args[1], "Agent") and string.match(args[2], "Zed") then
            local pos = GetProperty(args[1], "position")
            Destroy(args[1])
            ZombieCount = ZombieCount + 1
            ZombiesAgent(pos)
        elseif string.match(args[2], "Zed") then
            local pos = GetProperty(args[1], "position")
            Destroy(args[1])
            ZombieCount = ZombieCount + 1
            ZombiesPos(pos)
        elseif args[1] == Player then
            WriteToFile("highscore.txt", ZedsKilled)
            --kill all survivors
            for i = 1, #PlayerRoster do
                if PlayerRoster[i] != Player then
                    ChangeProperty(PlayerRoster[i], {"dead", true}, "state")
                end
            end
        end
    end
    if ctype == "character" and activated then
        if string.match(args[1], "Zed") and Victim == nil then
            ZombieCount = ZombieCount + 1
            Victim = args[1]
            ZombieLeader()
            SetupZombie(Victim)
        else
            if string.match(args[1], "Zed") then
                ZombieCount = ZombieCount + 1
                SetupZombie(args[1])
            end
        end
    end
end
function Cutscene(duo)
    if duo then
        if PlayerRoster[1] != Player then
            PlayCutscene("good.json", nil, true, 400)
        else
            PlayCutscene("good2.json", nil, true, 400)
        end
    else
        PlayCutscene("start.json", nil, true, 401)
    end
end

function SetupSurvior(Survivor)
    if not Exists(Survivor) then
        RunAfter(1, "SetupSurvior", {Survivor})
        return
    end
    local weapon = ReturnRandomObject("weapon")
    if weapon[1] != "None" then
        if weapon[1] == "Thrown" then
            while weapon[1] != "Thrown" do
                weapon = ReturnRandomObject("weapon")
            end
        end
        ChangeProperty(Survivor, {weapon[1], weapon[2]}, "weapon")
    end
    weapon = ReturnRandomObject("weapon")
    if weapon[1] != "None" then
        ChangeProperty(Survivor, {weapon[1], weapon[2], 1, 0}, "weapon")
    end
    RemoveFromSquad(Survivor)
    AddToSquad(GetSquadName(Player), Survivor)
    ChangeProperty(Survivor, {18.0}, "corpushp")
    ChangeProperty(Survivor, {GetProperty(Survivor, "strength") * 2}, "strength")
    ChangeProperty(Survivor, {GetProperty(Survivor, "lethality") * 2}, "lethality")
    if wasDuo then
        if PlayerRoster[1] != Player then
            PlayCutscene("survivors.json", {Survivor})
        else
            PlayCutscene("survivors2.json", {Survivor})
        end
    else
        PlayCutscene("survivors.json", {Survivor})
    end
    math.randomseed(os.time())
end
function SpawnSurvior()
    if ZedsKilled < 10 + (#PlayerRoster * 11) then
        RunAfter(math.random(5, 8), "SpawnSurvior", {})
    else
        local Survivor = SpawnCharacterAtEntrance("Grunt", true)
        RunAfter(1, "SetupSurvior", {Survivor})
        RunAfter(math.random(5, 8), "SpawnSurvior", {})
    end
end

function TurnIntoZombie()
    local characters = GetAllCharacters(true)
    --pick random character and turn them into a zombie
    math.randomseed(os.time())
    local character = characters[math.random(1, #characters)]
    if character != Player then
        ChangeProperty(character, {"Zed"}, "character")
    else
        TurnIntoZombie()
    end
    RunAfter(math.random(5, 8), "TurnIntoZombie")
end
function CutsceneCallback(id)
    if id == 400 then
        PlayMusic("event:/Music/Locknar/Blood Bath")
        local victimPos = nil
        if PlayerRoster[1] != Player then
            victimPos = GetProperty(PlayerRoster[1], "position")
        else
            victimPos = GetProperty(PlayerRoster[2], "position")
        end
        if PlayerRoster[1] != Player then
            ChangeProperty(PlayerRoster[1], {"Zed"}, "character")
        else
            ChangeProperty(PlayerRoster[2], {"Zed"}, "character")
        end
        math.randomseed(os.time())
        RunAfter(math.random(5, 8), "SpawnSurvior", {})
        RunAfter(5, "TurnIntoZombie")
    elseif id == 401 then
        PlayMusic("event:/Music/Locknar/Blood Son")
        Victim = Zombies()
        SquadName = GetSquadName(Victim)
        math.randomseed(os.time())
        --SpawnSurvior()
        RunAfter(math.random(5, 8), "SpawnSurvior", {})
        RunAfter(5, "TurnIntoZombie")
    end
end
function ButtonCallback(id)
    if id == 69 then
        wasDuo = #PlayerRoster == 2
        RunAfter(1, "Cutscene", {wasDuo})
        activated = true
    elseif id == 800 then
        if FileExists("highscore.txt") then
            local highscore = ReadFile("highscore.txt")
            CreateMenuUI("Highscore", "Highscore: " .. highscore, {"Ok"}, {900})
        else
            CreateMenuUI("Highscore", "No highscore yet", {"Ok"}, {900})
        end
    end
end
function Update()
    if GetKeyDown("Semicolon") and not activated then
        CreateMenuUI("Are you sure you want to run this mod?", "This mod will make you unable to progress in the current stage, you will have to restart the stage to play normally again. Are you sure you want to do this?", {"Yes", "No", "Checkout highscore"}, {69, 420, 800})
    end
end