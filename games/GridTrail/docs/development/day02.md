# GridTrail — Day 2 Development

**Project:** YORQO — GridTrail  
**Day:** 2  
**Date:** 2026-11-24  
**Status:** Completed  
**Engine:** Godot 4.7.1  
**Language:** GDScript

---

## 1. Objective

Implement the main gameplay system and develop the 100-level structure for GridTrail.

## 2. Features Implemented

- 100-level progression system.
- Five difficulty stages.
- Different grid sizes.
- Different checkpoint positions.
- Obstacles.
- Mouse and touch path input.
- Stopwatch.
- Move counter.
- Personal best records.
- Star rating system.
- Undo functionality.
- Restart functionality.
- Level unlocking.
- Local progress saving.

## 3. Level Structure

| Levels | Grid Size | Difficulty |
|---|---|---|
| 1–20 | 5×5 | Easy |
| 21–40 | 6×6 | Normal |
| 41–60 | 7×7 | Hard |
| 61–80 | 8×8 | Expert |
| 81–100 | 9×9 | Master |

## 4. Game Rules

1. Visit checkpoints in numerical order.
2. Move only up, down, left and right.
3. Diagonal movement is prohibited.
4. Every playable square must be filled exactly once.
5. Obstacles are blocked squares and do not need to be filled.
6. Previously visited squares cannot be visited again.
7. Completing a level unlocks the next level.

## 5. Important Code Logic

### Grid size

```gdscript
grid_size = 5 + stage
```

### Tile size

```gdscript
tile_size = 72 - (stage * 7)
```

### Four-direction movement

```gdscript
func is_adjacent(row_a, col_a, row_b, col_b):
    return abs(row_a - row_b) + abs(col_a - col_b) == 1
```

This allows horizontal and vertical movement while preventing diagonal movement.

## 6. Puzzle Generation

The current puzzle generator uses:

- Horizontal and vertical snake routes.
- Horizontal and vertical flips.
- Route reversal.
- Different checkpoint positions.
- Obstacles placed outside the generated playable route.

Each level uses a level-based random seed.

The current generator provides variations, but does not yet guarantee 100 mathematically unique puzzles or unique solutions.

## 7. Progress Saving

Progress is stored locally in:

```text
user://gridtrail_progress.cfg
```

The game saves unlocked-level progress and personal best times.

## 8. Project Structure

```text
GridTrail/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   └── main.gd
└── docs/
    └── development/
        ├── day01.md
        └── day02.md
```

## 9. Testing Checklist

- [ ] Main menu opens.
- [ ] Level selection displays 100 levels.
- [ ] Level 1 uses a 5×5 grid.
- [ ] Level 21 uses a 6×6 grid.
- [ ] Level 41 uses a 7×7 grid.
- [ ] Level 61 uses an 8×8 grid.
- [ ] Level 81 uses a 9×9 grid.
- [ ] Checkpoint numbers appear.
- [ ] Obstacles cannot be entered.
- [ ] Diagonal movement is rejected.
- [ ] Revisiting squares is rejected.
- [ ] Stopwatch works.
- [ ] Move counter works.
- [ ] Undo works.
- [ ] Restart works.
- [ ] Level unlocking works.
- [ ] Personal best is saved.
- [ ] Progress remains after restarting the game.

## 10. Development Decisions

- All playable squares must be filled.
- Obstacles do not need to be filled.
- Movement is restricted to four directions.
- Tile sizing follows:

```gdscript
tile_size = 72 - (stage * 7)
```

- GridTrail will contain 100 levels divided into five difficulty stages.

## 11. Day 2 Completion

**Day 2 development is marked complete.**

The 100-level gameplay structure and supporting gameplay systems have been implemented in the main script.

The latest implementation still requires testing to verify all features.

## 12. Day 3 — Planned Work

- Test the complete game.
- Fix gameplay bugs.
- Improve puzzle variety.
- Improve drag interaction.
- Improve the completion screen.
- Continue polishing GridTrail.

---

**YORQO — GridTrail**

CONNECT • SOLVE • WIN
