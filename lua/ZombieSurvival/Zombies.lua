local level = 1
local normalZedAttack
local activated = false
local Victim
local LeaderZed = nil
function Start()

end

function Zombies()
    local playerPos = GetProperty(Player, "position")
    local zed = nil
    if Leader == nil or IsDead(Leader) then
        zed = SpawnSquad({"Zed"}, {2000, 2000, 2000}, true)
        Leader = zed[1]
        ChangeProperty(zed[1], {Player}, "target")
        normalZedAttack = GetProperty(zed[1], "strength") * 2
        ChangeProperty(zed[1], {normalZedAttack}, "strength")
    else
        zed = SpawnCharacter("Zed", {2000, 2000, 2000}, true)
        AddToSquad(Leader, zed)
        ChangeProperty(zed, {Player}, "target")
        normalZedAttack = GetProperty(zed, "strength") * 2
        ChangeProperty(zed, {normalZedAttack}, "strength")
    end
    RunAfter(2, "Zombies", {})
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

function SpawnSurvior()
    local survivors = SpawnSquad({"Grunt"}, {2000, 2000, 2000}, true)
    local Survivor = survivors[1]
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
    AddToSquad(Player, Survivor)
    ChangeProperty(Survivor, {18.0}, "corpushp")
    ChangeProperty(Survivor, {GetProperty(Survivor, "strength") * 2}, "strength")
    ChangeProperty(Survivor, {GetProperty(Survivor, "lethality") * 2}, "lethality")
    if #PlayerRoster == 2 then
        if PlayerRoster[1] != Player then
            PlayCutscene("survivors.json", {Survivor})
        else
            PlayCutscene("survivors2.json", {Survivor})
        end
    else
        PlayCutscene("survivors.json", {Survivor})
    end
    --RunAfter(3, "SpawnSurvior", {})
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
            Destroy(PlayerRoster[1])
        else
            Destroy(PlayerRoster[2])
        end
        Victim = SpawnSquad({"Zed"}, victimPos, true)
        Leader = Victim[1]
        ChangeProperty(Victim[1], {Player}, "target")
        RunAfter(2, "Zombies", {})
    elseif id == 401 then
        PlayMusic("event:/Music/Locknar/Blood Son")
        RunAfter(2, "Zombies", {})
    end
end
function ButtonCallback(id)
    if id == 69 then
        RunAfter(1, "Cutscene", {#PlayerRoster == 2})
        activated = true
    end
end
function Update()
    if GetKeyDown("Semicolon") then
        CreateMenuUI("Are you sure you want to run this mod?", "This mod will make you unable to progress in the current stage, you will have to restart the stage to play normally again. Are you sure you want to do this?", {"Yes", "No"}, {69, 420})
    end
end