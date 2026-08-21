# 🌙 Smooth Sleep

Vanilla-friendly Minecraft datapack — night acceleration proportional to sleepers, plus daytime naps. Inspired by Better Days.

## How it works

Vanilla's night-skip gamerule is disabled (set to an unreachable 101%). Instead, the datapack fast-forwards time itself, scaled to how many online players are resting:

| Players resting | Time added per tick |
|---|---|
| 1-49% | +40 ticks |
| 50-99% | +70 ticks |
| 100% | +110 ticks (near-instant) |

The step is clamped so it never skips past dawn, so datapacks that announce the day number still trigger correctly.

**Napping**: sneak on a bed during the day and it counts as resting too — no need to wait for night.

## Compatibility

- Minecraft Java Edition **26.2** (`pack_format` 107.1)

## Installation

1. Download [`smooth_sleep.zip`](./smooth_sleep.zip).
2. Drop it into your world's `datapacks/` folder.
3. Run `/reload` in-game.

## License

MIT
