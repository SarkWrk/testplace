local squash = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Squash"))

local record = squash.record
local array = squash.array
local T = squash.T
local str = squash.string

local float = {
    [4] = squash.number(4),
    [8] = squash.number(8),
}

local uint = {
    [1] = squash.uint(1),
    [2] = squash.uint(2),
    [8] = squash.uint(8),
}

return {
    cursor = squash.cursor,
    tobuffer = squash.tobuffer,
    frombuffer = squash.frombuffer,
    squash = squash,

    --[[
    Converts a prefix into a buffer to be intercepted by `module.prefix_des()`. Has an 8-bit limit.
    ]]
    prefix_ser = function(prefix: number)
        local cursor = squash.cursor()
        squash.uint(1).ser(cursor, prefix)
        return squash.tobuffer(cursor)
    end,

    --[[
    Converts a buffer created by `module.prefix_ser()` into a number.
    ]]
    prefix_des = function(prefix: buffer)
        return squash.uint(1).des(squash.frombuffer(prefix))
    end,

    prefix_key = require(script.Parent.Parent.RemoteExplainer),

    weapon_stuffs = {
		client_bullet_creation = T(record({
			PositionX = T(float[4]),
			PositionY = T(float[4]),
			PositionZ = T(float[4]),
			RotationX = T(float[4]),
			RotationY = T(float[4]),
			RotationZ = T(float[4]),
		})),

        server_bullet_creation = {
            Index = uint[1],
            PierceAmount = uint[1],
            Speed = T(float[4]),
            ID = T(uint[8]),

            Position = T(record({
                X = T(float[4]),
                Y = T(float[4]),
                Z = T(float[4]),
            })),

            EndPosition = T(record({
                X = T(float[4]),
                Y = T(float[4]),
                Z = T(float[4]),
            })),

            Rotation = T(record({
                X = T(float[4]),
                Y = T(float[4]),
                Z = T(float[4]),
            })),
        },
    },
    drone_directions = {
        drone_movement = record({
            drone_speed = T(uint[1]),
            drone_path_smoothening = T(uint[1]),

            positions = T(array(record({
                X = T(float[4]),
                Y = T(float[4]),
                Z = T(float[4]),
            }))),
        }),
        send_positional_information = str
    }
}