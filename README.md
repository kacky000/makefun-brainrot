# ROT CARNIVAL: Popcorn Panic

[![make.fun bounty](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game set in a pastel-and-neon carnival, built for make.fun's
[Make the best AI Roblox brainrot game](https://make.fun/bounty/roblox-brainrot-01) bounty.

Play it: https://www.roblox.com/games/128360736232810

## The loop

1. The **Prize Cannon** fires brainrots onto the **Prize Belt** that runs down the checkered street.
2. Walk up, **buy** one (it rides over your head) and **run it home** to your booth.
3. Crossing your gate **places** it on a pedestal, where it earns its **money a second** into the booth stash.
4. Step on the green pad to **collect**, then buy the next, rarer one.

## What is in it

- **36 original brainrots** on **7 rarities** (Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret), each a 3D
  model built from parts: Toastolini Toastolino, Duckuccino Turbo, Ringmaster Rhinoccino, King Kernelcorn,
  Trofeo Infinito and friends. Every one carries a card with its name, rarity and money a second.
- **5 mutations** rolled as the cannon fires: Gold x2, Buttered x3, Neon x4, Rainbow x6, Galaxy x10.
- **Popcorn Wave**: every so often the Popcorn Machine blows and a wall of popcorn rolls down the street. Get
  caught and you are thrown and drop what you carry. Booths are safe; staying clear pays a dodge bonus.
- **Sneaky Clown thieves**: he comes for your best brainrot. **LOCK** your gate (red lasers) and he bounces off
  with "BLOCKED BY LOCK!"; leave it open and you must bonk him before he reaches the exit.
- **Stealing** between players from any booth whose gate is not locked.
- **Rebirth** (permanent money and luck multiplier), **upgrades** (pedestals, speed, lock time), an **Index** of
  everything found, and four timed **events**: Golden Hour, Rainbow Rain, Cannon Frenzy, Butter Storm.

## How the code is laid out

One module, one job. The server decides everything; the client draws it and asks.

| Path | Job |
| --- | --- |
| `src/ReplicatedStorage/GameConfig` | every number: rarities, mutations, prices, timings |
| `src/ReplicatedStorage/BrainrotCatalog` | the cast of 36 and its ladder |
| `src/ReplicatedStorage/MutationRoller` | `rollMutation` |
| `src/ServerScriptService/Economy/ConveyorSpawner` | cannon shots onto the belt |
| `src/ServerScriptService/Economy/CarryService` | buy, carry, deliver, steal |
| `src/ServerScriptService/Economy/BasePedestals` | booths and pedestals |
| `src/ServerScriptService/Economy/IncomeTicker` | money a second, stash, collect |
| `src/ServerScriptService/Economy/RebirthService`, `UpgradeShop` | progression |
| `src/ServerScriptService/Events/EventScheduler` | the four events |
| `src/ServerScriptService/Hazards/PopcornWave`, `ThiefRaids`, `GateLock` | the threats and the defence |
| `src/ServerScriptService/State/PlayerState` | the one place player state lives |
| `src/ServerScriptService/World/CarnivalBuilder`, `BrainrotModels`, `TourDirector` | the 3D world, the models, the screenshot scenes |
| `src/StarterGui/HudController`, `HudPanels`, `HudEffects` | the interface and its feedback |

## Build and hand in

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output
and writes `dossier.json` with the kit's unchanged `vendor/makefun-roblox.ts`.

The three screenshots are captures of the game running in Roblox Studio, staged by
`TourDirector.showcase("cover" | "lock" | "index")`; `TOUR.json` lists the calls.

## Assets

No uploaded assets. Every model is built from parts by the scripts. Every sound is one that ships with the Roblox
client (`rbxasset://sounds/...`: electronicpingshort, button, snap, clickfast, uuhhh, bass, splat, switch, collide,
swordslash, victory). Fonts are Roblox's built-in Luckiest Guy and Fredoka One.

## License

MIT, see `LICENSE`.
