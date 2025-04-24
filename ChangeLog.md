# 20/04/25-23/04/25

>[!WARNING]
> **Dependencies have had their paths changed. `ReplicatedStorage/dependencies` (`src/shared/dependencies`) has been separated into `ReplicatedStorage/dependencies wally` (`*/Packets`) for dependencies added via Wally and `ReplciatedStorage/dependencies other` (`src/shared/dependencies other`) for manually added dependencies/components.**

## Additions
- When a player joins the experience, if they already have data tracked (from `src/server/Trackers/PlayerTracker.server.luau`), the data will be applied to them.
- When a bullet pierces an object, its trails will change colour to indicate it.

## Changes
- Slightly changed `src/server/Trckers/PlayerTracker.server.luau` to now spawn the player when they load into the game.
  - Along with this, players no longer automatically load their character when they join the experience.

## Removals

## Fixes
- Bullets now properly disappear when they hit something.
  - Before this didn't work because of issues where the server wouldn't detect the bullet as being destroyed; thus, not telling the client to destroy the bullet.