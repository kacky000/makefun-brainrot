# makefun-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/kacky000/makefun-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**ROT CARNIVAL: Popcorn Panic** is a 3D Roblox brainrot game set on a carnival midway.

The Prize Cannon fires absurd carnival brainrots onto the Prize Belt. Buy one, carry it over your head to your
booth, and it earns money every second from its pedestal. Then buy a rarer one.

- **36 brainrots** of its own (Toastolini Toastolino, Duckuccino Turbo, King Kernelcorn, Trofeo Infinito ...),
  each built from parts, on **7 rarities** (Common to Secret) with **5 mutations** (Gold x2, Buttered x3, Neon x4,
  Rainbow x6, Galaxy x10).
- **Popcorn Wave**: every 75 seconds the Popcorn Machine overflows and a wall of popcorn rolls down the street.
  Get caught and you drop what you carry, so run for your booth.
- **Sneaky Clown thieves** walk off with your best earner. **Lock** your gate (laser bars) to bounce them, or
  catch the clown and bonk him to get it back.
- **Rebirth** for a permanent income multiplier and better cannon luck, **upgrades** (pedestals, shoes, lock time),
  four **events** (Golden Hour, Rainbow Rain, Cannon Frenzy, Butter Storm) and an **Index** with a 3D preview of
  every brainrot.

Play it: https://www.roblox.com/games/128360736232810

## How it is built

A Rojo project. Every script of the place is a `.luau` file under `src/`:

| Where | Scripts |
| --- | --- |
| `src/ReplicatedStorage` | `GameConfig` (numbers and layout), `BrainrotCatalog` (the cast), `MutationRoller` |
| `src/ServerScriptService/Economy` | `BasePedestals`, `CarryService`, `ConveyorSpawner`, `IncomeTicker`, `RebirthService`, `UpgradeShop` |
| `src/ServerScriptService/Events` | `EventScheduler` |
| `src/ServerScriptService/Hazards` | `GateLock`, `PopcornWave`, `ThiefRaids` |
| `src/ServerScriptService/State` | `PlayerState` (all player state lives here, on the server) |
| `src/ServerScriptService/World` | `CarnivalBuilder` (the 3D world), `BrainrotModels` (the 3D cast), `TourDirector` |
| `src/StarterGui` | `HudController` (client), `HudPanels`, `HudEffects` |

The server owns everything: clients send three requests (`lock`, `rebirth`, `upgrade`) and buying is a
ProximityPrompt the server answers. `tools/bake-world.luau` runs `CarnivalBuilder` under lune and writes
`world/Carnival.rbxm`, which the project places in `Workspace`.

Sounds are Roblox's built-in `rbxasset://sounds/` files; nothing is uploaded.

## Run it

```sh
rokit install
lune run tools/bake-world.luau
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio and press Play. `TOUR.json` names the call that stages each screenshot:
`TourDirector.showcase("cover" | "belt" | "panels")`, and `showcase("play")` hands the game back.

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
