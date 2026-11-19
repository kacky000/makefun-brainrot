// ROT CARNIVAL: Popcorn Panic, a roblox-brainrot-01 entry (Node 22, standard library only).
// The game is this directory's Rojo project: the Luau under src/ plus the baked carnival world
// (world/Carnival.rbxm, written by `lune run tools/bake-world.luau` from the game's own
// CarnivalBuilder), built into game.rbxl with `rojo build default.project.json --output game.rbxl`.
// This program hands it in: it copies game.rbxl, src/, screenshots/ and PLAY.json from beside this
// file to /output and writes /output/dossier.json, the summary the judge reads, with the vendored
// make.fun library.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -,
// so src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

// Refuse to hand in a play link that names no published place: the gate would refuse it anyway.
const play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8')) as { url?: string; place_id?: number; universe_id?: number };
if (!Number.isInteger(play.place_id) || !Number.isInteger(play.universe_id) || (play.place_id ?? 0) <= 0 || (play.universe_id ?? 0) <= 0) {
  throw new Error('PLAY.json must name the published place: positive place_id and universe_id');
}
if (play.url !== undefined && !play.url.includes(String(play.place_id))) {
  throw new Error('PLAY.json url must be the play link of place_id');
}

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
