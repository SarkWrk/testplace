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