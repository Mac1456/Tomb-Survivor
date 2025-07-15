# Tomb Survivor - Modular Development Checklist ✅

This checklist ensures each core feature is implemented and tested in an isolated, manageable step using Godot + GDScript. Use one Cursor chat per step.

---

## ✅ Step 1: Core Movement & Arena Setup (**FULLY WORKING - READY TO TEST**)
- [✅] **Complete Godot project created** (`project.godot`, `Main.tscn`, `Main.gd`, `icon.svg`)
- [✅] **Input mapping pre-configured** (W/A/S/D, Left/Right Click, Space for dodge, R for ultimate, Escape)
- [✅] **Collision layers organized** (Player, Walls, Enemies, SafeZones, Projectiles)
- [✅] **Performance-optimized architecture** (60+ FPS, monitoring system)
- [✅] **Top-down player movement** using WASD (✅ FIXED - now working!)
- [✅] **Static crypt arena** with barriers/safe corners
- [✅] **Player collision system** with walls and barriers
- [✅] **Camera following player** smoothly with proper setup
- [✅] **All syntax errors resolved** (no more script attachment issues)

**🎮 Test Results Expected:**
- **Movement**: WASD moves blue player smoothly ✅
- **Camera**: Follows player automatically ✅  
- **Collision**: Player bounces off brown walls/barriers ✅
- **Input**: All actions log to console (clicks, space for dodge, R for ultimate, escape) ✅
- **Performance**: 60+ FPS with good performance messages ✅

**🔧 Recent Fixes Applied:**
- Removed problematic inner class approach
- Moved player movement to main script's `_physics_process`
- Fixed all syntax errors and script attachment issues
- Optimized performance monitoring
- Ensured camera properly follows player

---

## ✅ Step 2: Core Combat Mechanics (**FULLY WORKING - READY TO TEST**)
- [✅] **Primary melee attack (Left Click)** - 50px range, 25 damage, white flash visual
- [✅] **Special ability (Right Click)** - projectile attack with 2s cooldown  
- [✅] **Hit detection system** - both melee and projectile attacks hit enemies
- [✅] **Placeholder enemies** - 3 red squares with chase AI (50 health, 100 speed)
- [✅] **Visual feedback** - white attack flashes, red hit flashes
- [✅] **Combat performance optimized** - maintains 60+ FPS with combat active

**🎮 Test Results Expected:**
- **Melee Attack**: Left click creates white flash, hits enemies in 50px range ✅
- **Projectile Attack**: Right click fires yellow projectiles toward mouse ✅
- **Cooldown System**: Right click shows cooldown message when used too quickly ✅
- **Enemy AI**: Red squares chase player smoothly ✅
- **Hit Detection**: Enemies flash red when hit, disappear when health reaches 0 ✅
- **Performance**: Combat maintains 60+ FPS with smooth visual effects ✅

**🔧 Combat Features Added:**
- Melee attack system with facing direction detection
- Projectile system with velocity-based movement
- Enemy health and damage calculation
- Visual feedback for all combat actions
- Basic enemy AI with chase behavior
- Cooldown management for special abilities

**🔧 Step 2.1 & 2.2 Additional Features:**
- [✅] **Dodge roll system** - Spacebar rolls toward mouse (1s cooldown, 600 speed)
- [✅] **Enemy health bars** - Visual bars above enemies with color coding (green→yellow→red)
- [✅] **Ultimate ability remapped** - Moved from spacebar to R key
- [✅] **Enhanced enemy AI** - Fixed sticking issue with 3-tier distance system
- [✅] **Anti-overlap system** - Strong push-back prevents enemies from sticking to player
- [✅] **Code quality improvements** - Fixed all compiler warnings

**🎮 Step 2.2 Test Results:**
- **Dodge Roll**: Spacebar dodge toward mouse works smoothly ✅
- **Health Bars**: Enemies show health with proper color changes ✅
- **Enemy AI**: No more sticking, enemies maintain proper distance ✅
- **Push-back System**: Enemies get pushed away when too close ✅
- **Controls**: All inputs working (WASD, clicks, spacebar, R key) ✅

---

## ✅ Step 3: Character System & Selection (**COMPLETED - MEDIEVAL FANTASY THEME**)
- [✅] **4 Medieval Fantasy Characters** with unique stats and abilities:
  - [✅] **Hero Knight (Paladin)** - Balanced melee with defensive abilities
  - [✅] **Hero Knight 2 (Berserker)** - High damage melee with berserker rage
  - [✅] **Huntress (Ranger)** - Ranged archer with trap abilities  
  - [✅] **Evil Wizard (Warlock)** - Ranged magic with dark spells
- [✅] **Character selection UI** with animated character sprite previews and stat breakdown
- [✅] **AnimatedSprite2D Integration** - Replaced static TextureRect with proper AnimatedSprite2D
- [✅] **Character Animations** - Idle, attack, and run animations for all characters
- [✅] **Sprite Sheet Splitting** - Properly split sprite sheets into individual frames for all characters
- [✅] **Hero Knight Full Animation** - Complete frame-by-frame animation (8 idle, 6 attack, 10 run frames)
- [✅] **Character-specific VFX** for abilities (slash effects, holy effects, dark magic, smoke effects)
- [✅] **Visual consistency** - All characters use 32-bit medieval fantasy sprite style
- [✅] **Load selected character** into the arena with proper sprite and abilities
- [✅] **VFX Integration** - Primary attacks, special abilities, ultimate abilities, and dodge roll all have VFX
- [✅] **Input System** - WASD movement, Left Click primary attack, Right Click special, R ultimate, Space dodge
- [✅] **Fixed Player Functions** - Added missing perform_* functions for proper Main.gd integration
- [✅] **Animation State Management** - Proper idle/run/attack animation transitions
- [✅] **Collision Detection Fix** - Adjusted collision shape (32x40) to match scaled sprites
- [✅] **Directional Attack System** - Cursor-based directional attacks with 60° cone area
- [✅] **Character Selection UI Fix** - Improved sprite positioning, sizing, and layout
- [✅] **VFX Positioning Fix** - Fixed VFX anchoring to prevent flickering and off-screen rendering
- [✅] **Debug System** - Added comprehensive debug logging for character data and VFX

**🎮 Test Results:**
- **Character Selection**: UI displays all 4 medieval characters with properly positioned animated previews
- **Character Animations**: All characters have full frame-by-frame animations from split sprite sheets
- **Character Loading**: Selected character loads in arena with correct animations and abilities
- **Collision Detection**: Player collision properly matches sprite size, no more clipping into walls
- **Attack System**: Directional attacks work with cursor aiming and 60° cone detection
- **VFX System**: All character abilities trigger appropriate visual effects properly positioned
- **Visual Consistency**: All character sprites use consistent 32-bit medieval fantasy style
- **Input Integration**: All controls work correctly with proper attack animations and VFX
- **Performance**: AnimatedSprite2D system works smoothly with proper sprite scaling

**🔧 Recent Bug Fixes:**
- **Sprite Sheet Handling**: Implemented AtlasTexture splitting for multi-frame sheets
- **Animation Frames**: Proper frame counts and regions for each character's animations
- **Preview Scaling**: Adjusted scales per character for better fit in selection UI
- **Collision Shape**: Increased from 24x24 to 32x40 to match scaled sprites (1.5x scale)
- **Attack Detection**: Implemented cone-shaped directional attacks based on cursor position
- **Character Selection**: Fixed sprite positioning and sizing with proper 80x80 containers
- **VFX Positioning**: Fixed VFX anchoring to player with proper local coordinates
- **Debug Logging**: Added comprehensive debug output for troubleshooting VFX and character data

**⚠️ Notes:**
- All characters now use properly split sprite sheets for full animations
- Hero Knight uses individual frame files (fully animated)
- Other characters use split sprite sheets (8 frames for idle/run, variable for attack)
- All characters have proper idle/attack/run state management
- VFX system integrated with character abilities and properly positioned
- Directional attack system provides intuitive cursor-based combat

---

## ⏳ Step 4: Enemy System (**NOT STARTED**)
- [ ] **Tier 1 Enemies (Rounds 1-10)** - Fully animated only
  - [ ] **Skeleton Warriors** (melee) - Basic melee enemies with full animation set (Fantasy Skeleton Enemies pack)
  - [ ] **Skeleton Archers** (ranged) - Basic ranged enemies with full animation set (Fantasy Skeleton Enemies pack)
- [ ] **Tier 2 Enemies (Rounds 11-20)**
  - [ ] **Skeleton Mages** (magic ranged) - Magic projectile enemies with full animation set (Fantasy Skeleton Enemies pack)
- [ ] **Elite Enemies (Rounds 21-30)** - Visually distinct versions
  - [ ] **Elite Skeleton Warriors** - Enhanced with visual distinction (glowing effects, different coloring, or enhanced sprites)
  - [ ] **Elite Skeleton Archers** - Enhanced with visual distinction (glowing effects, different coloring, or enhanced sprites)
  - [ ] **Elite Skeleton Mages** - Enhanced with visual distinction (glowing effects, different coloring, or enhanced sprites)
- [ ] **Enemy Pool System** - Once introduced, enemies remain in spawn pool permanently
- [ ] **Enemy AI** - Basic pathfinding and attack patterns
- [ ] **Enemy Scaling** - Stat scaling throughout the game
- [ ] **VFX Integration** - Hit effects, death animations, and ability effects

---

## ⬜ Step 5: Round System (**ENDLESS SURVIVAL**)
- [ ] **Auto-start round logic** with delay between waves
- [ ] **Enemy spawn scaling** by round with mix of enemy types
- [ ] **Enemy pool management** - retain all enemy types once introduced
- [ ] **Boss round triggers** - Every 10 rounds (10, 20, 30, 40, etc.)
- [ ] **UI shows current round** and enemy wave status
- [ ] **Endless progression** - Game continues indefinitely with scaling difficulty

**🎮 Test Results Expected:**
- **Round Progression**: Automatic round advancement with proper delays
- **Enemy Scaling**: Mix of enemy types in each wave, increasing difficulty
- **Boss Timing**: Bosses appear every 10 rounds consistently
- **UI Updates**: Round number and wave status display correctly

---

## ⬜ Step 6: XP and Leveling
- [ ] **XP from kills and round completion**
- [ ] **Level-up triggers stat boosts**
- [ ] **Unlock ultimate ability** at milestone
- [ ] **Character-specific progression** - Different abilities for each character

---

## ⏳ Step 7: Boss Logic (**ENDLESS SURVIVAL SYSTEM**)
- [ ] **Pre-Round 30 Bosses:**
  - [ ] **Blue Witch** - Multi-phase spellcasting boss with full animation set
  - [ ] Boss difficulty scales with round number and player count
- [ ] **Post-Round 30 Boss System:**
  - [ ] **Balanced Difficulty** - All bosses equally challenging
  - [ ] **Interchangeable Spawning** - Random boss selection every 10 rounds
  - [ ] **Boss Roster:**
    - [ ] **Blue Witch** (buffed with additional abilities for post-30)
    - [ ] **Necromancer** (powerful spellcaster with full animation set)
    - [ ] **NightBorne** (fast melee boss with teleportation abilities and full animation set)
  - [ ] **Difficulty Scaling** - Multiple instances or enhanced abilities
- [ ] **Boss Phases** - Multi-phase behavior for complex encounters
- [ ] **Boss VFX** - Special effects for abilities and phase transitions
- [ ] **Boss Arena** - Environmental effects during boss encounters

---

## ⬜ Step 8: VFX System & Effects (**EXPANDED VFX SYSTEM**)
- [ ] **Character Ability VFX:**
  - [ ] **Hero Knight (Paladin)** - Holy/protective effects for abilities
  - [ ] **Hero Knight 2 (Berserker)** - Rage/blood effects for berserker abilities
  - [ ] **Huntress 2 (Ranger)** - Arrow trails, trap effects
  - [ ] **Evil Wizard 2 (Warlock)** - Dark magic effects, spell animations
- [ ] **Combat VFX:**
  - [ ] **Hit Effects** - Different effects for different damage types
  - [ ] **Death Animations** - Character-specific death effects
  - [ ] **Projectile Effects** - Trails and impact effects
- [ ] **Environmental VFX:**
  - [ ] **Smoke Effects** - Environmental atmosphere
  - [ ] **Fire Effects** - Torches, magical flames
  - [ ] **Holy/Dark Auras** - Character ability enhancements
- [ ] **Elite Enemy VFX:**
  - [ ] **Glowing Effects** - Visual distinction for elite enemies
  - [ ] **Color Variations** - Elite enemy visual enhancements
  - [ ] **Enhanced Sprites** - Elite enemy visual upgrades
- [ ] **Boss VFX:**
  - [ ] **Blue Witch** - Spell casting effects, phase transitions
  - [ ] **Necromancer** - Dark magic effects, summoning animations
  - [ ] **NightBorne** - Teleportation effects, shadow abilities

---

## ⏳ Step 9: Powerups and Drops (**NOT STARTED**)
- [ ] **Temporary powerups** (buffs, weapons, companions)
- [ ] **Permanent powerups** (from bosses only)
- [ ] **Loot drop logic** and pickup effects
- [ ] **VFX for powerups** - Visual effects for pickup and activation

---

## ⏳ Step 10: Inter-Round Features (**NOT STARTED**)
- [ ] **Healing shrines** - Occasional healing between rounds
- [ ] **Recruitable NPCs** - Temporary AI companions
- [ ] **Inter-round timing** - Proper delays between rounds
- [ ] **Visual/audio cues** - Shrine activation feedback

---

## ⏳ Step 11: Real-Time Multiplayer Integration (**NOT STARTED**)
- [ ] **Multiplayer synchronization** - Player actions and round logic
- [ ] **Lobby system** - Host/join functionality
- [ ] **Rejoin capability** - Players can reconnect
- [ ] **AI bot fallback** - Fill empty slots with AI
- [ ] **Network optimization** - Stable multiplayer performance

---

## ⏳ Step 12: Background Music and Audio Polish (**NOT STARTED**)
- [ ] **Ambient background music** - Crypt atmosphere
- [ ] **Combat SFX** - Attacks, hits, abilities
- [ ] **UI SFX** - Button clicks, pickups, notifications
- [ ] **Boss theme music** - Special music for boss encounters
- [ ] **Audio fade/loop testing** - Seamless audio transitions

---

## 🏁 Final Polish
- [ ] **Playtest all features** as a complete loop
- [ ] **Fix critical bugs** and optimize performance
- [ ] **Review PRD** and finalize for submission/demo
- [ ] **Ensure visual consistency** across all medieval fantasy elements
