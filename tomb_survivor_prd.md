**Product Requirements Document (PRD)**

**Project Title:** Tomb Survivor

**Project Type:** Top-down 2D Multiplayer Survival Arena

**Platform:** PC (Exportable to HTML5 if needed)

**Engine:** Godot (GDScript)

**Target Audience:** Fans of arcade survival, co-op action games, and roguelikes; ages 13+

---

### **1. Objective**

To build a real-time, arcade-style dungeon survival game for 1–4 players. The game is set in a single, large crypt room where players must survive as many increasingly difficult enemy rounds as possible. Gameplay emphasizes fast-paced combat, tight co-op coordination, and character-specific skills in a progressively chaotic battlefield.

---

### **2. Core Gameplay Features**

#### **Playable Characters**

* **8 Rogue Characters** with unique stats and abilities
* Each rogue features:
  * **Stats:** Strength, Speed, Armor, Health
  * **Primary Attack:** Melee or Ranged, mapped to **Left Click**, mouse-aimed
  * **Special Ability:** Offensive, Defensive, or Supportive, mapped to **Right Click**, may be aimed
  * **Ultimate Ability:** Unlocked at a certain level, mapped to **R Key**, longer cooldown

**Character Selection:**

* Visual selection screen with sprite previews and stat breakdown
* Activated after hosting or joining a lobby
* Players can only ready up once they've selected a rogue

---

### **3. Combat and Controls**

* **Controls:**
  * Move: WASD
  * Aim: Mouse direction
  * Attack: Left Click
  * Special: Right Click
    * Ultimate: R Key
  * Dodge Roll: Spacebar
* Ranged attacks use **mild target-locking** to assist aim
* Combat is hitbox/collision-based with responsive animations

---

### **4. Game Loop and Progression**

* Players start in a large crypt-themed arena with barriers and safe corners for tactical positioning
* Game begins once all players are ready
* **Round-Based Survival:**
  * Round 1 starts automatically
  * Each round spawns increasingly difficult waves of enemies
  * Round 10 and every set boss-round introduces a **Witch Boss**, escalating in difficulty
  * Enemies get stronger per round, with a soft cap to prevent infinite scaling
* **Player Progression:**
  * XP is earned through kills and completing rounds
  * Leveling up boosts base stats and unlocks the ultimate ability
  * Death resets temporary upgrades; revived players return with stat reduction
* **Auto-Start:** Each round begins automatically after a short delay following the previous round
* **Inter-Round Elements:** Healing shrines and recruitable NPCs can occasionally appear during the break

---

### **5. Enemies and Bosses**

* **Enemy Types:**
  * Skeleton Grunt (melee)
  * Skeleton Archer (ranged)
  * Skeleton Guard (tank)
  * Bone Bomber (suicide unit)
  * Elite Skeletons (mini-bosses with enhanced AI)

* **Boss Rounds:**
  * Occur at Round 10 and every set interval thereafter
  * Feature a **Witch Boss** with unique attacks, summons, and phases
  * Multiple witch types with different mechanics
  * Boss difficulty scales with round number and player count

---

### **6. Powerups and Loot**

* **Temporary Powerups:**
  * Drop rarely from regular enemies, more often from elite ones
  * Examples: damage boosts, invincibility, temporary AI partner, powerful horde-clear weapons
  * Short duration, high impact

* **Permanent Powerups:**
  * Dropped from boss chests
  * 1–2 per boss, scaled to player count
  * Minor stat enhancements, skill efficiency, cooldown reduction
  * Lost on death and revived with stat penalty

---

### **7. Multiplayer and AI Support**

* **1–4 player co-op** via Godot multiplayer API
* **Matchmaking Options:**
  * Host Game
  * Join Friend’s Game
  * Character Selection then Lobby
* **Rejoin System:**
  * Players can reconnect at the start of a round
* **Bot Support:**
  * Solo players can include AI-controlled rogues
  * AI mimics player behavior and scales enemy difficulty

**Note:** Real-time multiplayer is implemented last in the development sequence, after all local and offline gameplay systems are fully validated.

---

### **8. Visual and Audio Style**

* Stylized pixel-art sprites from asset packs
* Eerie crypt/dungeon atmosphere with ambient effects
* Dynamic sound design for attacks, spells, and boss battles
* Background visuals for menus to reflect crypt theme

**Note:** Background music and final sound implementation are reserved for the final development stages to ensure focus remains on gameplay and mechanical validation first.

---

### **9. User Interface**

* **Main Menu:**
  * Start (Host Game)
  * Join Game
  * Options (audio/video)
* **Character Select:**
  * Shows all 8 rogues with stats, visuals, and abilities
  * Ready button activates once selection is made
* **In-Game UI:**
  * Health bars, cooldown indicators, level meter
  * Round number display, enemy wave status

---

### **10. Technical Architecture**

* `Main.gd` - Game loop and round progression
* `Player.tscn` - Rogue logic and ability mappings
* `Enemy.tscn` - Shared logic for enemy types
* `WitchBoss.tscn` - Multi-phase spellcasting boss
* `MultiplayerManager.gd` - Lobby creation, joining, syncing
* `PowerupSystem.gd` - Handles random drops and effects
* `CharacterSelect.tscn` - Rogue display and selection
* `MainMenu.tscn` - UI interactions and background

---

### **11. Modular Development Plan (Step-by-Step Testing-Friendly Approach)**

**Step 1: Core Movement & Arena Setup**
* Create basic top-down player movement with camera
* Build a static test arena with barriers and safe corners
* Add simple collision and input logic

**Step 2: Core Combat Mechanics**
* Implement melee and ranged attacks
* Add hit detection and damage logic
* Test special abilities (mapped to Right Click)

**Step 3: Character System & Selection**
* Create 8 player characters with unique stats
* Build character selection UI
* Display character info and allow selection before game start

**Step 4: Enemy System**
* Implement enemy types with basic AI (Grunt, Archer, etc.)
* Spawn single enemy waves for testing
* Tune collision and damage detection

**Step 5: Round System**
* Create round logic and automatic wave escalation
* Implement round delay timer
* Track and display round number in UI

**Step 6: XP and Leveling**
* Add XP gain and leveling system
* Trigger stat increases and ultimate ability unlock
* Test cooldown management and progression pacing

**Step 7: Boss Logic**
* Implement Witch Boss and round-based triggers
* Design multi-phase boss behavior
* Add boss round indicator and special effects

**Step 8: Powerups and Drops**
* Create drop system for temporary and permanent powerups
* Add visual effects and spawn animations
* Test impact and balance of each drop

**Step 9: Inter-Round Features**
* Add healing shrines and recruitable NPCs between rounds
* Implement visual/audio cues for shrine activation
* Ensure functionality integrates with wave system

**Step 10: Real-Time Multiplayer Integration**
* Sync player actions and round logic across host and clients
* Add lobby system and rejoin capability
* Introduce AI bot fallback if no players join

**Step 11: Background Music and Audio Polish**
* Implement ambient background music and theme tracks
* Add SFX for combat, pickups, UI, and boss effects
* Final audio tuning and fade/loop testing

---

### **12. Success Criteria**

* Players can host, join, and select characters in a stable multiplayer session
* Responsive combat with distinct rogue abilities
* Balanced round-based enemy spawns and boss encounters
* Character progression and powerups function correctly
* Game scales difficulty and feels fair but challenging
* Play sessions last 15–40 minutes depending on skill
* Project shows mastery of Godot and AI-assisted development

---

### **13. Tools and Resources**

* **Engine:** Godot 4.x
* **Assets:** Sprite and animation packs
* **AI Tools:** ChatGPT, Meshy.ai
* **Version Control:** Git + GitHub

---

### **14. Future Considerations**

* Leaderboards and score tracking
* New rogue characters with unique abilities
* Additional boss types and spell mechanics
* Alternative arenas or biome skins
* Controller support and web export

