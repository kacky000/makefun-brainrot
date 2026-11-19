# makefun-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**ROT CARNIVAL: Popcorn Panic** is a Roblox brainrot game set in a pastel-and-neon carnival. The Prize Cannon fires absurd characters onto the Prize Belt that runs down the Midway. Buy one, carry it on your head to your booth and put it on a pedestal, where it earns cash every second. Dash home before the Popcorn Machine overflows and the Popcorn Wave sweeps the street. Lock your gate before a Sneaky Clown steals your best brainrot. Then rebirth for a permanent income multiplier.

Play it: [ROT CARNIVAL: Popcorn Panic on Roblox](https://www.roblox.com/games/128360736232810)

## The game

- **36 original brainrots** in **7 rarities** (Common, Rare, Epic, Legendary, Mythic, Cosmic, Secret), each a 3D model built from parts, such as Toastolini Toastolino, Duckuccino Turbo, Ringmaster Rhinoccino and King Kernelcorn.
- **5 mutations** (Gold x2, Buttered x3, Neon x4, Rainbow x6, Galaxy x10) that multiply a brainrot's price and income and change its finish.
- **The loop:** buy from the belt, carry it home, place it on a pedestal, earn $/s, then buy the next tier.
- **Tension:** the Popcorn Wave rolls down the Midway every minute or so and makes you drop what you carry. Sneaky Clown thieves raid unlocked booths, and other players can steal too. The gate LOCK (a laser shield) stops both, and touching a clown bonks it.
- **Progression:** UPGRADES (pedestals 10→20, faster shoes, longer lock), REBIRTH (+50% income and +25% luck each time), and the INDEX book of every brainrot found.
- **4 events:** Golden Hour, Rainbow Rain, Cannon Frenzy and Butter Storm.

## Code

A Rojo project; every script is a `.luau` file under `src/`, built into `game.rbxl`.

| Script | Job |
| --- | --- |
| `ServerScriptService/Main` | makes the remotes and starts each service in its own pcall, world first |
| `Economy/ConveyorSpawner` | the Prize Cannon firing brainrots onto the Prize Belt, and buying them |
| `Economy/CarryService` | carrying a brainrot home, delivering it to a pedestal, dropping it |
| `Economy/IncomeTicker` | pays every booth once a second |
| `Economy/UpgradeShop`, `Economy/RebirthService` | pedestals, shoes and lock upgrades; rebirths |
| `Events/EventScheduler` | Golden Hour, Rainbow Rain, Cannon Frenzy, Butter Storm |
| `Hazards/PopcornWave` | the recurring wave that sweeps the Midway |
| `Hazards/ThiefRaids` | Sneaky Clown raids on booths |
| `Hazards/GateLock` | the gate's laser lock |
| `State/PlayerData` | the single store of player state (cash, slots, upgrades, discoveries) and its DataStore save |
| `State/BasePedestals` | booth ownership, the brainrots on pedestals, sell and steal |
| `World/CarnivalWorld` | builds the carnival (baked into the place as `world/Carnival.rbxm`) and spins its rides |
| `World/BrainrotModels`, `World/CastArt`, `World/PartShapes` | builds each brainrot's 3D model and label card |
| `World/Feedback` | toasts, sounds and receipts sent to players |
| `World/TourDirector` | stages the showcase screens (`TOUR.json`) |
| `ReplicatedStorage/*` | `BrainrotCatalog` (the cast), `MutationRoller`, `GameConfig` |
| `StarterPlayerScripts/*` | `HudController` (the HUD) and `IndexBook` |

The world in `world/Carnival.rbxm` is what `CarnivalWorld.buildCarnival` builds, baked in Studio's edit mode so that the place file carries it. At start `CarnivalWorld` adopts the baked world, or builds a fresh one if it is missing.

The server is authoritative: the client only shows attributes the server publishes and sends shop requests the server checks.

## Sound sources

Every sound is one of Roblox's built-in client sounds (`rbxasset://sounds/...`: `volume_slider.ogg`, `action_jump_land.mp3`, `ouch.ogg`, `impact_water.mp3`, `impact_explosion_03.mp3`, `oof.ogg`, `action_get_up.mp3`, `action_falling.ogg`, `action_jump.mp3`), played at different pitches. There are 11 cues: buy, place, collect, stolen, blocked, rebirth, wave, bonk, lock, alarm and upgrade. No uploaded audio is used.

## Run it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
