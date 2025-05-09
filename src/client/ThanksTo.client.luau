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