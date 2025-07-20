# Tomb Survivor - Project Structure

## Directory Organization

The project has been refactored for clarity and maintainability:

### `/scenes/` - All Godot Scene Files (.tscn)
- `Main.tscn` - Main game arena scene
- `Player.tscn` - Player character scene  
- `Enemy.tscn` - Basic enemy scene
- `BlueBoss.tscn` - Boss enemy scene
- `CharacterSelect.tscn` - Character selection UI
- `MainMenu.tscn` - Main menu UI
- `GameManager.tscn` - Game state management scene

### `/scripts/` - All GDScript Logic (.gd + .uid files)
- `Main.gd` - Main game logic and arena management
- `Player.gd` - Player movement, combat, and abilities
- `Enemy.gd` - Enemy AI and behavior
- `BlueBoss.gd` - Boss AI and multi-phase logic
- `CharacterSelect.gd` - Character selection UI logic
- `CharacterData.gd` - Character stats and configuration
- `MainMenu.gd` - Main menu functionality
- `GameManager.gd` - Game state management and scene transitions
- `*.uid` files - Godot's unique identifier files

### `/assets/` - All Game Assets (unchanged)
- Well-organized subdirectories for sprites, audio, backgrounds, etc.
- Medieval fantasy theme with consistent 32-bit art style

### `/docs/` - All Documentation
- `README.md` - Project overview and setup instructions
- `tomb_survivor_checklist.md` - Development progress tracking
- `tomb_survivor_prd.md` - Product requirements document
- Character guides and implementation notes

### Root Directory - Core Project Files
- `project.godot` - Godot project configuration
- `icon.svg` - Project icon
- `.godot/` - Godot editor cache (auto-generated)
- `.git/` - Git version control

## Benefits of This Organization

1. **Clear Separation of Concerns**: Scenes, logic, assets, and docs are clearly separated
2. **Easy Navigation**: Developers can quickly find the type of file they need
3. **Better Maintainability**: Related files are grouped together logically  
4. **Scalability**: Easy to add new scenes, scripts, or documentation
5. **Team Development**: Multiple developers can work on different aspects without conflicts

## Path Updates Made

All internal references have been updated to use the new directory structure:
- Scene script references: `res://scripts/ScriptName.gd`
- Scene loading in scripts: `res://scenes/SceneName.tscn`  
- Main scene in project.godot: `res://scenes/GameManager.tscn` 