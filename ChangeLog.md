# 30/4/25-xx/xx/25

## Additions
- Added new dependencies: [Class++](https://github.com/TenebrisNoctua/ClassPP) and [Squash](https://github.com/Data-Oriented-House/Squash).
- Refactored `src/shared/Helpers/GeneralLibrary.luau`'s `Promise.PromiseHandler()` and `Promise.ExceptionHandler()` to have types.
  - As a side effect, the module is no longer strictly typed because I could not find a way to make it work without showing errors.
- Added initialisation parameters to `src/private/Components/AI/PathfindingAI`. 

## Changes
- Class++ refactorings:
  - Refactored `src/private/Components/BulletComponent/BulletComponent.luau`.
    - This means that `src/server/BulletManager/ManagerScript.server.luau` has been refactored to work with the refactor.
  - Refactored `src/private/Componenets/AI/PathfindingAI`.
- Moved from ByteNet to Squash.
- Changed the backtrace from `src/shared/dependencies other/Helpers/GeneralLibrary.luau`'s `Promise.ExceptionHandler()` to start from three levels instead of four levels.

## Removals
- Removed dependency: [ByteNet](https://github.com/ffrostfall/ByteNet).

## Fixes
- Fixed broken links.
  - View source link was leading to the wrong branch.
  - Other link(s) were missing the "testplace" in "https://sarkwrk.github.io/testplace".

# 24/04/25-30/4/25
## Additions
- Updating and adding new entries into the documentation.
  - Now using MkDocs.

## Changes
- Updated CONTRIBUTING.md
- Changed `src/Helpers/GeneralLibrary.luau`.NumberManipulation.Truncate() to return one number (the truncated number) instead of two (the leading digits and order of magnitude required to construct the truncated number).

## Removals
## Fixes
- Fixed some paths not being changed in `src/character/ZetaInformation.client.luau`.

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