# Tomb Survivor - AGENT.md

## Build/Test Commands
- `godot --headless --path . --script scripts/TestRunner.gd` - Run automated tests (if TestRunner exists)
- Run game: Open project in Godot Editor and press F5 or F6
- Export: Project > Export from Godot Editor
- No traditional build system - Godot handles compilation internally

## Architecture
- **Godot 4.4 project** - Top-down 2D multiplayer survival arena game
- **Main scene**: `scenes/GameManager.tscn` manages game states (MAIN_MENU, CHARACTER_SELECT, GAME)
- **Core systems**: Player movement/combat, Enemy AI, Character selection, Boss encounters
- **Physics layers**: Player(1), Walls(2), Enemies(3), SafeZones(4), Projectiles(5)
- **Key managers**: GameManager for state, Player for character mechanics
- **Input map**: WASD movement, mouse attacks, R ultimate, Space dodge roll

## Code Style (from .cursor/rules)
- **File naming**: PascalCase for scenes (`MainMenu.tscn`), snake_case for scripts (`enemy_ai.gd`)
- **Organization**: Scripts/scenes by role: `Player/`, `Enemies/`, `UI/`, `Managers/`
- **GDScript conventions**: PascalCase for classes, snake_case for variables/functions
- **Modularity**: Each script focused on single responsibility, reusable design
- **Testing**: Include test scenes, debug logs, dummy data for isolation testing
- **Asset consistency**: All created assets must be visually consistent
- **Development order**: Complete local gameplay before multiplayer (Step 10) or audio (Step 11)

## Project Progress
- Following modular checklist in `docs/tomb_survivor_checklist.md`
- Current implementation: Character system, basic gameplay loop
- Available characters: Hero Knight variants, Huntress, Evil Wizard with full ability sets
