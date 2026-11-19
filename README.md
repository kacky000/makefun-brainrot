# makefun-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**ROT CARNIVAL: Popcorn Panic** is a 3D Roblox brainrot game set on a pastel carnival midway.
The Prize Cannon fires absurd carnival brainrots onto the Prize Belt. Buy one, carry it on your head
across the midway, and it is placed on a pedestal in your booth, where it earns money every second.
Every 75 seconds the Popcorn Machine overflows and a wall of popcorn rolls down the street: get caught
and you drop your catch. Sneaky Clown thieves raid booths that are not locked.

Play it: https://www.roblox.com/games/128360736232810

## The loop

1. **Walk** the midway and watch the Prize Belt.
2. **Buy** a brainrot off the belt (its card shows name, rarity, money a second and price).
3. **Carry** it home before the Popcorn Wave rolls. Stepping into your booth **places** it on a pedestal.
4. **Earn**: every placed brainrot pays its rate each second, times your rebirth multiplier and events.
5. **Climb**: buy the next rarity, more pedestals, roller skates, a longer lock; then **rebirth**.

## What is in it

- **36 original brainrots** on **7 rarities** (Common to Secret), built from parts by recipe:
  Toastolini Toastolino, Duckuccino Turbo, Slushi Brainfreezi, Ringmaster Rhinoccino, King Kernelcorn,
  Popcornado Supremo and 30 more. Rarer ones are bigger and glow.
- **5 mutations**: Gold x2, Buttered x3, Neon x4, Rainbow x6, Galaxy x10.
- **Popcorn Wave** hazard, **Sneaky Clown** thieves, rival **stealing**, and the **gate lock** (three lasers)
  that blocks both. Bonk a clown to save your brainrot and earn a reward.
- **Rebirth** (+50% income and +25% mutation luck each), **upgrades** (pedestals 8 to 20, walk speed,
  lock time), **4 events** (Golden Hour, Rainbow Rain, Cannon Frenzy, Butter Storm), and an **INDEX**
  with 3D previews.
- A built world of about 2,300 instances: checkered midway, Prize Cannon, Popcorn Machine, six booths,
  two Ferris wheels, two carousels, four big tops, lollipop trees, balloons, bunting.

## How the code is laid out

One module, one job. All rules run on the server; the client only draws the HUD and sends three requests.

| Path | Job |
| --- | --- |
| `src/ReplicatedStorage/GameConfig` | every number: rarities, mutations, layout, upgrades, rebirth, wave, events |
| `src/ReplicatedStorage/BrainrotCatalog` | the 36 brainrots, prices, income, belt weights |
| `src/ReplicatedStorage/MutationRoller` | mutation rolls and the mutation paint |
| `src/ServerScriptService/State/PlayerState` | the single store of player state (cash, pedestals, upgrades, index) |
| `src/ServerScriptService/Economy/*` | belt spawner, buy and carry, pedestals, income tick, rebirth, upgrades |
| `src/ServerScriptService/Hazards/*` | Popcorn Wave, Sneaky Clown raids, gate lock |
| `src/ServerScriptService/Events/EventScheduler` | timed carnival events |
| `src/ServerScriptService/World/*` | the carnival builder, brainrot model builder, showcase tour |
| `src/StarterGui/*` | HUD and the INDEX / REBIRTH / UPGRADES panels |

## Run it

```sh
rokit install                                   # rojo 7.7.1 and lune 0.11.1
lune run tools/bake-world.luau                  # bakes world/Carnival.rbxm from CarnivalBuilder
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio and press Play. `TOUR.json` names the function that stages each screenshot.

## Assets

No uploaded assets. Every model is built from Roblox parts by the scripts. Sound effects are the sounds
that ship with the Roblox client (`rbxasset://sounds/...`), pitched differently per action. Fonts are
Roblox's built-in Fredoka One and Luckiest Guy.

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
