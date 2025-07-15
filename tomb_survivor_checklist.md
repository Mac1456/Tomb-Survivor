# Tomb Survivor - Modular Development Checklist ✅

This checklist ensures each core feature is implemented and tested in an isolated, manageable step using Godot + GDScript. Use one Cursor chat per step.

---

## ✅ Step 1: Core Movement & Arena Setup (**FULLY WORKING - READY TO TEST**)
- [✅] **Complete Godot project created** (`project.godot`, `Main.tscn`, `Main.gd`, `icon.svg`)
- [✅] **Input mapping pre-configured** (W/A/S/D, Left/Right Click, Space, Escape)
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
- **Input**: All actions log to console (clicks, space, escape) ✅
- **Performance**: 60+ FPS with good performance messages ✅

**🔧 Recent Fixes Applied:**
- Removed problematic inner class approach
- Moved player movement to main script's `_physics_process`
- Fixed all syntax errors and script attachment issues
- Optimized performance monitoring
- Ensured camera properly follows player

---

## ⬜ Step 2: Core Combat Mechanics
- [ ] Primary attack (Left Click), melee or ranged
- [ ] Special ability (Right Click) with cooldown
- [ ] Hit detection and placeholder enemies

---

## ⬜ Step 3: Character System & Selection
- [ ] 8 rogues with unique stats (strength, speed, armor, health)
- [ ] Character selection UI with previews
- [ ] Load selected character into the arena

---

## ⬜ Step 4: Enemy System
- [ ] Implement Skeleton Grunt and Archer
- [ ] State machine AI: idle → chase → attack
- [ ] Damage detection from player attacks

---

## ⬜ Step 5: Round System
- [ ] Auto-start round logic with delay between waves
- [ ] Enemy spawn scaling by round
- [ ] UI shows current round

---

## ⬜ Step 6: XP and Leveling
- [ ] XP from kills and round completion
- [ ] Level-up triggers stat boosts
- [ ] Unlock ultimate ability at milestone

---

## ⬜ Step 7: Boss Logic
- [ ] Witch Boss appears at Round 10+
- [ ] Multi-phase spellcasting and summoning
- [ ] Boss round UI + transition logic

---

## ⬜ Step 8: Powerups and Drops
- [ ] Temporary powerups (buffs, weapons, companions)
- [ ] Permanent powerups (from bosses only)
- [ ] Loot drop logic and pickup effects

---

## ⬜ Step 9: Inter-Round Features
- [ ] Healing shrine logic and visuals
- [ ] Recruitable NPC companion logic
- [ ] Spawned randomly between rounds

---

## ⬜ Step 10: Real-Time Multiplayer
- [ ] Host + Join functionality using Godot multiplayer API
- [ ] Player position and action sync
- [ ] Lobby + reconnect support

---

## ⬜ Step 11: Background Music and Audio Polish
- [ ] Background music for menu + gameplay
- [ ] SFX for attacks, UI, abilities, bosses
- [ ] Central AudioManager with fade/loop control

---

## 🏁 Final Polish
- [ ] Playtest all features as a complete loop
- [ ] Fix critical bugs and optimize performance
- [ ] Review PRD and finalize for submission/demo
