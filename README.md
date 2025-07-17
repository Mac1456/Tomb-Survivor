# Tomb Survivor

A top-down 2D medieval fantasy survival arena game built with Godot and GDScript. Battle through waves of enemies as one of four unique characters in a mystical crypt arena.

## Project Overview

**Tomb Survivor** is a real-time, arcade-style dungeon survival game featuring medieval fantasy characters. Players fight through increasingly difficult enemy waves using distinct character classes with unique abilities and combat styles.

## 🎮 Current Features (What's Actually Implemented)

### ✅ Complete Character System
- **4 Medieval Fantasy Characters** with fully animated sprites and unique abilities:
  - **Knight** - Balanced melee fighter with sword techniques and protective abilities
  - **Berserker** - High-damage melee warrior with rage abilities
  - **Huntress** - Ranged archer with multi-shot and area attacks
  - **Wizard** - Magical caster with projectile spells and area effects
- **Character Selection Screen** with animated sprite previews and detailed stat breakdown
- **Character-specific animations** - Idle, run, and attack animations for all characters
- **Unique combat styles** - Each character has distinct primary, special, and ultimate abilities

### ✅ Advanced Combat System
- **Directional Combat** - Cursor-based directional attacks with 60° cone detection
- **Dual Attack Types** - Melee attacks for Knight/Berserker, ranged projectiles for Huntress/Wizard
- **Dodge Roll System** - Spacebar dodge with cooldown and directional control
- **VFX Integration** - Visual effects for all character abilities and attacks
- **Projectile System** - Arrows and fireballs with physics-based movement
- **Hit Detection** - Precise collision-based combat with visual feedback

### ✅ Sophisticated Enemy AI System
- **Sword Skeletons** - Melee enemies with Hades-style AI (Idle→Patrol→Chase→Windup→Attack→Cooldown)
- **Archer Skeletons** - Ranged enemies with positioning and kiting behavior
- **Elite Skeletons** - Enhanced versions with 8x health and purple visual tint
- **Adaptive AI** - Enemies adjust behavior based on player character type (more aggressive vs ranged players)
- **Enemy Health Bars** - Visual health indicators with color-coded damage states
- **Scaling System** - Enemy stats scale with difficulty progression

### ✅ Boss System
- **Blue Witch Boss** - Multi-phase boss with 3 distinct phases
- **Custom Boss Sprites** - 5 unique SVG sprites (idle, move, attack, charge, death)
- **10 Animation States** - Complete animation system with state management
- **Phase Transitions** - Shield phases at 66% and 33% health
- **Spell System** - 6 different spells (fireball, orb, missiles, lightning, repel, summon)
- **Elite Summons** - Boss spawns enhanced skeleton minions
- **Boss Health Bar** - Top-screen health display with boss name
- **Adaptive Difficulty** - Health scales with player count

### ✅ Complete UI System
- **Main Menu** - Start game, options, and quit functionality
- **Character Selection** - Visual character picker with stat displays
- **Game Manager** - State management between menu, character select, and game
- **Scene Transitions** - Smooth navigation between game states
- **Input Handling** - Complete input system with escape/back navigation

### ✅ Arena & Environment
- **Crypt Arena** - 1200x800 performance-optimized arena
- **Tactical Barriers** - Strategic positioning elements (no more safe zones)
- **Cave Background** - Atmospheric dungeon environment
- **Collision System** - Optimized StaticBody2D walls and barriers
- **Camera System** - Smooth camera following with proper bounds

### ✅ Performance System
- **Entity Limit** - Max 50 entities to prevent overload
- **Performance Monitoring** - FPS tracking and performance warnings
- **Optimized Rendering** - Efficient collision and rendering systems
- **Memory Management** - Proper cleanup and resource management

## 🎯 Controls

- **Movement**: WASD
- **Aim**: Mouse direction
- **Primary Attack**: Left Click (melee/ranged based on character)
- **Special Ability**: Right Click (character-specific abilities)
- **Ultimate Ability**: R Key (enhanced character abilities)
- **Dodge Roll**: Spacebar (directional dodge with cooldown)
- **Menu Navigation**: Escape to return to menu

## 🧪 Testing Features

- **Press 1**: Spawn Sword Skeleton enemy
- **Press 2**: Spawn Archer Skeleton enemy  
- **Press 3**: Spawn Blue Witch Boss
- **Escape**: Return to main menu

## 🚀 How to Play

1. **Launch Game**: Open project in Godot 4.x and run
2. **Character Selection**: Choose from 4 medieval fantasy characters
3. **Combat**: Use directional attacks, special abilities, and dodge rolls
4. **Survive**: Fight waves of skeletons and boss encounters
5. **Test Features**: Use number keys to spawn enemies and test combat

## 🏗️ Technical Architecture

### Core Systems
- **Main.gd** (1086 lines) - Complete game logic and combat system
- **Player.gd** (686 lines) - Character controller with abilities
- **Enemy.gd** (519 lines) - Sophisticated AI system
- **BlueBoss.gd** (497 lines) - Multi-phase boss implementation
- **GameManager.gd** (129 lines) - Scene and state management

### Data Systems
- **CharacterData.gd** - Character stats and ability definitions
- **CharacterSelect.gd** - Character selection UI and animations

### Scene Structure
- **GameManager.tscn** - Main game entry point
- **MainMenu.tscn** - Menu interface
- **CharacterSelect.tscn** - Character selection screen
- **Main.tscn** - Game arena
- **Player.tscn** - Player character
- **Enemy.tscn** - Enemy entities
- **BlueBoss.tscn** - Boss encounter

## 🎨 Art & Animation

- **Character Sprites** - 32-bit medieval fantasy style with full animation sets
- **Enemy Sprites** - Custom SVG skeleton warriors and archers
- **Boss Sprites** - 5 custom Blue Witch sprites with VFX
- **Environment** - Crypt/dungeon themed backgrounds and barriers
- **VFX System** - Attack effects, hit flashes, and ability animations

## ⚙️ Performance Features

- **60+ FPS** - Optimized for smooth gameplay
- **Entity Management** - Automatic cleanup and limits
- **Collision Optimization** - Efficient physics and collision detection
- **Memory Efficient** - Proper resource management and cleanup

## 🔧 Development Status

### ✅ **COMPLETED SYSTEMS** (Steps 1-3 + Advanced Features)
1. **Core Movement & Arena Setup** - FULLY COMPLETE
2. **Core Combat Mechanics** - FULLY COMPLETE  
3. **Character System & Selection** - FULLY COMPLETE
4. **Advanced Enemy AI** - IMPLEMENTED
5. **Boss System** - IMPLEMENTED
6. **UI System** - COMPLETE
7. **VFX System** - IMPLEMENTED
8. **Performance Optimization** - COMPLETE

### ⏳ **NOT YET IMPLEMENTED**
- **Round System** - Auto-progression wave system
- **XP and Leveling** - Character progression
- **Powerups and Drops** - Temporary and permanent upgrades
- **Inter-Round Features** - Healing shrines, NPCs
- **Multiplayer** - 1-4 player co-op
- **Audio System** - Music and sound effects

## 📋 Project Structure

```
Tomb-Survivor/
├── project.godot           # ✅ Godot project configuration
├── Main.tscn              # ✅ Main game arena
├── Main.gd                # ✅ Complete game logic (1086 lines)
├── GameManager.tscn       # ✅ Game state management
├── MainMenu.tscn          # ✅ Main menu interface
├── CharacterSelect.tscn   # ✅ Character selection screen
├── Player.tscn            # ✅ Player character
├── Enemy.tscn             # ✅ Enemy entities
├── BlueBoss.tscn          # ✅ Boss encounter
├── assets/                # ✅ All game assets
│   ├── characters/        # 4 medieval fantasy characters
│   ├── enemies/           # Skeleton sprites and boss
│   ├── backgrounds/       # Crypt/dungeon environments
│   ├── audio/             # Background music and SFX
│   └── props/             # Decorative elements
├── README.md              # ✅ This file
├── tomb_survivor_prd.md   # ✅ Product requirements
└── tomb_survivor_checklist.md # ✅ Development checklist
```

## 🎯 Success Criteria (Current Status)

- ✅ **Character Selection** - Complete with 4 animated characters
- ✅ **Responsive Combat** - Directional attacks with distinct character abilities
- ✅ **Enemy AI** - Sophisticated Hades-style AI with multiple enemy types
- ✅ **Boss Encounters** - Multi-phase Blue Witch boss with custom sprites
- ✅ **Performance** - 60+ FPS with optimized systems
- ✅ **Visual Polish** - Complete animation system with VFX
- ⏳ **Round-Based Progression** - Not yet implemented
- ⏳ **Multiplayer** - Not yet implemented

## 🚀 Getting Started

### ✅ Ready to Play - Complete Game Available!

1. **Open Godot 4.x**
2. **Import Project**: Select `project.godot` in this folder
3. **Run Game**: Click the Play button (▶️)
4. **Choose Character**: Select from 4 medieval fantasy characters
5. **Start Combat**: Use testing keys (1, 2, 3) to spawn enemies
6. **Experience Features**: Test all implemented systems

### Current Game Loop
1. **Main Menu** → **Character Selection** → **Game Arena**
2. **Manual Enemy Spawning** for testing (keys 1, 2, 3)
3. **Combat System** with all character abilities
4. **Boss Encounters** with Blue Witch
5. **Return to Menu** with Escape

---

**Project Status**: ✅ **PLAYABLE GAME WITH ADVANCED FEATURES**  
**Current Build**: Steps 1-3 Complete + Advanced Enemy AI + Boss System + Full UI  
**Engine**: Godot 4.x + GDScript  
**Performance**: 60+ FPS, optimized systems  
**Next Priority**: Round system and wave progression