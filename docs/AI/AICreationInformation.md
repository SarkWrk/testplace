# AI Initialisation Parameters

Located at [`src/pirvate/Components/AI/init.luau`](https://github.com/SarkWrk/testplace/blob/main/src/private/Components/AI/init.luau).

!!! Caution "Required*"
    Entries with a * are required parameters. Each table represents a table in the order each parameter goes in.

## Pathfinding Component

Located at [`src/private/Components/AI/PathfindingAI.luau`](https://github.com/SarkWrk/testplace/blob/main/src/private/Components/AI/PathfindingAI.luau).

!!! Warning "Deprecation"
    [`src/private/Components/AI/PathfindingAIOld.luau`](https://github.com/SarkWrk/testplace/blob/main/src/private/Components/AI/PathfindingAIOld.luau) is now deprecated. Scripts relying on that module should switch over to the newer module.

### locked_information*

| Name                  | Value  | Explanation                                                                  |
|---                    |---     |---                                                                           |
| rig*                  | model  | The rig that should be controlled by this script. It must have a `Humanoid`. |
| state_manager_script* | script | Used to adjust attributes that are used by a "StateManagerScript".           |
| owner_script*         | script | The script that created the class.                                           |
| seed                  | number | What seed should be used when creating `Random.new()`.                       |

### target_tags

| Name  | Value | Explanation                                                                                                       |
|---    |---    |---                                                                                                                |
| [None]| string| A tag from `CollectionService` whose tagged parts should be included in the list of possible parts to pathfind to.|
| [None]| string| A tag from `CollectionService` whose tagged parts should be included in the list of possible parts to pathfind to.|
| [None]| string| A tag from `CollectionService` whose tagged parts should be included in the list of possible parts to pathfind to.|
| ...   | string| A tag from `CollectionService` whose tagged parts should be included in the list of possible parts to pathfind to.|

### pathfinding_settings

| Name                  | Value     | Explanation                                                                                                           |
|---                    |---        |---                                                                                                                    |
| view_distance         | number    | How far the AI should be able to see targets from.                                                                    |
| search_tries          | number    | How many times the AI should try to search for the target if it can't find the target.                                |
| maximum_target_index  | number    | How many targets should be chosen from.<br/>(This is based off which targets are closest, and then chosen randomly.)  |
| path_settings         | table     | See: [below](/testplace/AI/AICreationInformation/#path_settings).                                                     |
| combat_settings       | table     | See: [below](/testplace/AI/AICreationInformation/#combat_settings).                                                   |

#### path_settings

Please reference [Roblox's documentation](https://create.roblox.com/docs/reference/engine/classes/PathfindingService#CreatePath).

#### combat_settings

| Name                              | Value     | Explanation                                                       |
|---                                |---        |---                                                                |
| should_stop_on_enemy_sight        | number    | Whether the AI should stop when seeing an enemy or not.           |
| movespeed_reduction_on_enemy_sight| number    | How much slower should the AI move when seeing an enemy.          |
| grenade_avoidance_radius          | number    | How close can the AI be to a grenade before trying to avoid it.   |

### visualisation_settings

| Name                          | Value     | Explanation                                                                                                                                                                                                               |
|---                            |---        |---                                                                                                                                                                                                                        |
| visualise_path                | boolean   | Whether the path the AI is going to take should be visualised or not.                                                                                                                                                     |
| node_spacing                  | number    | How far away each node should be from each other in studs in the visualised path.<br/>**Note: The smallest node spacing possible is equal to the node spacing from `pathfinding_settings.path_settings.WaypointSpacing`**.|
| node_size                     | number    | How big each node should be (in studs). Note: The size will be `Vector3.new(#, #, #)`.                                                                                                                                    |
| jump_node_size_multiplier     | number    | How much bigger (multiplied) should a `Jump` `PathWaypoint.Action` should be compared to a `Walk` `PathWaypoint.Action`.                                                                                                  |
| custom_node_size_multiplier   | number    | How much bigger (multiplied) should a `Custom` `PathWaypoint.Action` should be compared to a `Walk` `PathWaypoint.Action`.                                                                                                |

### target_information

| Name          | Value         | Explanation                                                                                                                                           |
|---            |---            |---                                                                                                                                                    |
| shared_table  | SharedTable   | A `SharedTable` which includes the positions of every potential target.<br/>This table should be indexed as {[tag]: {[path_to_target]: `Vector3`}}.   |

## Combat Component

Located at [`src/private/Components/AI/CombatAI.luau`](https://github.com/SarkWrk/testplace/blob/main/src/private/Components/AI/CombatAI.luau).

TBA.