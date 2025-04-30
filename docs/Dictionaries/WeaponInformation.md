# Gun Statistics

## General functionality

| Name                  | Value     | Explanation                                       |
|---                    |---        |---                                                |
|TypeOfBullet           | int       | 1: Hitscan <br/> 2: Bullet                        |
|Damage                 | number    | How much damage a bullet does.                    |
|ShotDelay              | number    | How many shots/minute to fire at.                 |
|Range                  | number    | How far the bullet can go in studs.               |
|XSpread                | number    | The x-component spread of the bullet in degrees.  |
|YSpread                | number    | The y-component spread of the bullet in degrees.  |
|ReloadSpeed            | number    | How long it takes to reload in seconds.           |
|MagazineSize           | int       | How many shots are in a magazine.                 |
|ReserveSize            | int       | The total amount of bullets.                      |

## For Shotguns

| Name          | Value | Explanation                           |
|---            |---    |---                                    |
|AmountOfShots  | int   | How many shots to fire in a pellet.   |

## For Burst-style Guns

| Name              | Value     | Explanation                                                   |
|---                |---        |---                                                            |
|ShotsPerBurst      | int       | How many shots to shoot per burst.                            |
|DelayBetweenBurst  | number    | How long to wait in seconds between each shot in a burst.     |

## If TypeOfBullet Is 2

| Name                  | Value     | Explanation                                                                                                                               |
|---                    |---        |---                                                                                                                                        |
|BulletSpeed            | number    | How fast the bullet should go in studs/second.                                                                                            |
|BulletDrop             | number    | How fast the bullet should drop in studs/second.                                                                                          |
|PierceAmount           | int       | How many parts the bullet can pierce.                                                                                                     |
|PierceFallOffDamage    | number    | How much damage should be lost when piercing a part. <br/> This is calculated as: $damage = damage - (damage \div {100 \times falloff})$. |