while task.wait() do
	if game:GetService("Players").LocalPlayer.Character:GetAttribute("Armed") == true then
		script.Parent.Text = "Safety off."
	else
		script.Parent.Text = "Safety on."
	end
end