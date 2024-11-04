local thankyouModulesMessage = "Greatly aided by the modules:"
local thankyouDevTools = "Also thanks to the development tools:"

--[[
name : Name of the module, author : Name of the author, type : Whether to add to modules(1) or dev tools(2), modified : Whether the module has been modified.
]]
local function AddThanks(name : string, author : string, type : number, modified : boolean?)
    if type == 1 then
        thankyouModulesMessage = thankyouModulesMessage .. "\n" .. '"' .. name .. '"'

        if modified == true then
            thankyouModulesMessage = thankyouModulesMessage .. " (modified)"
        end

        thankyouModulesMessage = thankyouModulesMessage .. ' by ' .. author
    elseif type == 2 then
        thankyouDevTools = thankyouDevTools .. "\n" .. '"' .. name .. '" by ' .. author
    end
end

AddThanks("CRSplineModules [v2.0.0]", "bhristt", 1, true)
AddThanks("ByteNet", "ffrostfall", 1)
AddThanks("roblox-lua-promise", "evaera", 1)

AddThanks("Luau LSP", "JohnnyMorganz", 2)
AddThanks("Rojo", "evaera(?)", 2)

if game:GetService("RunService"):IsStudio() == false then
    print(thankyouModulesMessage)
    print(thankyouDevTools)
end