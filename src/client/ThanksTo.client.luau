<<<<<<< HEAD
local thankyouModulesMessage = "The modules:"

thankyouModulesMessage ..= "\n\tFrom Wally:"

for _, module in pairs(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("_Index"):GetChildren()) do
    local name: string = module.Name
    local creator_sub: string = name:split("@")[1]
    local creator_split: { string } = creator_sub:split("_")
    local dependency_creator: string = ""

    for i, v in pairs(creator_split) do
        if table.maxn(creator_split) == i then
            continue
        end

        dependency_creator ..= v
    end

    local dependency_version = name:split("@")[2]

    local dependency = module:GetChildren()[1].Name

    thankyouModulesMessage ..= "\n\t\t" .. dependency .. " (version " .. dependency_version ..") by " .. dependency_creator
end

thankyouModulesMessage ..= "\n\tFrom npm:"
    .. "\n\t\tpretty-vide-utils (version 0.0.5) by PepeElToro41"

thankyouModulesMessage ..= "\n\tFrom elsewhere:"
    .. "\n\t\tCRSplineModules (version 2.0.0) by bhristt"

local thankyouDevTools = "The development tools:"
    .. "\n\t\tLuau LSP by JohnnyMorganz"
    .. "\n\t\tRojo by The Rojo Team"

if game:GetService("RunService"):IsStudio() == false then
    game:GetService("TestService"):Message("\nThis project was made possible due to:\n"
    .. thankyouModulesMessage
    .. "\n"
    .. thankyouDevTools
    .. "\n\nNote: each module name, version, and author name in the Wally section is auto-generated based on the src/Packages/_Index directory.")
end

script:Destroy()
=======
local thankyouModulesMessage = "Greatly aided by the modules:"
local thankyouDevTools = "Also thanks to the development tools:"

--[[
name : Name of the module, author : Name of the author, type : Whether to add to modules(1) or dev tools(2), modified : Whether the module has been modified.
]]
local function AddThanks(name : string, author : string, type : number, license : string?, modified : boolean?)
    local message = "\n" .. '"' .. name .. '"'

    if modified == true then
        message = message .. " (modified)"
    end

    message = message .. " by " .. author

    if license then
        message = message .. " licensed under the " .. license
    end

    if type == 1 then
        thankyouModulesMessage = thankyouModulesMessage .. message
    elseif type == 2 then
        thankyouDevTools = thankyouDevTools .. message
    end
end

AddThanks("CRSplineModules [v2.0.0]", "bhristt", 1, "MIT license", true)
AddThanks("ByteNet", "ffrostfall", 1, "MIT license")
AddThanks("roblox-lua-promise", "evaera", 1, "MIT license")
AddThanks("FastSignal", "LucasMZ", 1, "MIT license")
AddThanks("Vide", "centau", 1, "MIT license")

AddThanks("Luau LSP", "JohnnyMorganz", 2)
AddThanks("Rojo", "The Rojo Team", 2)

if game:GetService("RunService"):IsStudio() == false then
    print(thankyouModulesMessage)
    print(thankyouDevTools)
end
>>>>>>> main
