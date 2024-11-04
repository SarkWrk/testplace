local types = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("Types"))

local gunStatistics : {[string] : types.BaseGun}
gunStatistics = {}

--[[
NOTE:
BulletDrop, BulletSpeed, PierceAmount, and PierceFalOffDamage are only required for BulletTypes that aren't 1
ShotsPerBurst is only required if DelayBetweenBurst is not nil
]]

gunStatistics.G17 = {
    TypeOfBullet = 2,
    Damage = 10,
    ShotDelay = 1200,
    AmountOfShots = 1,
    ShotsPerBurst = 1,
    DelayBetweenBurst = nil,
    Range = 2500,
    BulletDrop = 1.5,
    XSpread = 0.5,
    YSpread = 0.5,
    BulletSpeed = 500,
    ReloadSpeed = 0.25,
    MagazineSize = 17,
    ReserveSize = 1000,
    PierceAmount = 0,
    PierceFallOffDamage = 0
}

return gunStatistics