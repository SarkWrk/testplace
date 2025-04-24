local packets = {}

local byteNet = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("ByteNet"))

packets.BulletCreation = byteNet.defineNamespace("ClientBulletCreation", function()
	return {
		ClientBulletCreation = byteNet.definePacket({
			value = byteNet.struct({
				PositionX = byteNet.float32,
				PositionY = byteNet.float32,
				PositionZ = byteNet.float32,
				RotationX = byteNet.float32,
				RotationY = byteNet.float32,
				RotationZ = byteNet.float32,
			}),
			
			reliabilityType = "unreliable"
		}),

		ServerBulletCreation = byteNet.definePacket({
			value = byteNet.struct({
				Index = byteNet.uint16,
				PierceAmount = byteNet.optional(byteNet.uint8),
				PositionX = byteNet.optional(byteNet.float32),
				PositionY = byteNet.optional(byteNet.float32),
				PositionZ = byteNet.optional(byteNet.float32),
				EndPositionX = byteNet.optional(byteNet.float32),
				EndPositionY = byteNet.optional(byteNet.float32),
				EndPositionZ = byteNet.optional(byteNet.float32),
				Speed = byteNet.optional(byteNet.uint16),
				RotationX = byteNet.optional(byteNet.float32),
				RotationY = byteNet.optional(byteNet.float32),
				RotationZ = byteNet.optional(byteNet.float32),
				ID = byteNet.optional(byteNet.uint32)
			}),
			
			reliabilityType = "unreliable"
		})
	}
end)

packets.ArmClient = byteNet.defineNamespace("ArmClient", function()
	return {
		ArmClient = byteNet.definePacket({
			value = byteNet.nothing,

			reliabilityType = "unreliable"
		})
	}
end)

packets.SendPositionalInformation = byteNet.defineNamespace("SendPositionalInformation", function()
	return {
		SendPositionalInformation = byteNet.definePacket({
			value = byteNet.string,

			reliabilityType = "unreliable"
		})
	}
end)

return packets
