# Wizard Character Design Breakdown 🧙‍♂️

## Overview
This document provides detailed design specifications for the Wizard character in Tomb Survivor, following the Blue Witch design principles but adapted for a playable character with 24x30 SVG sprites.

---

## 🎨 Visual Design Specifications

### Core Design Principles
- **Art Style**: Medieval fantasy traditional wizard theme
- **Sprite Format**: SVG files (24x30 pixels)
- **Color Palette**: Blues (#4169E1, #2563EB, #1E3A8A) with gold (#FFD700) highlights
- **Detail Level**: High detail with multiple visual elements per sprite
- **Character Theme**: Wise sorcerer with elemental magic and traditional wizard appearance

### Visual Elements Structure
Each Wizard sprite contains these core components:

1. **Staff** - Magical weapon with runes and orb (primary prop)
2. **Body/Robes** - Flowing dark robes with purple accents
3. **Arms** - Positioned differently per animation state
4. **Hands** - Visible flesh-toned hands for spellcasting gestures
5. **Head** - Hooded with glowing eyes or visible scholarly face
6. **Hood/Hat** - Dark hood or pointed wizard hat
7. **Hair** - Flowing dark hair (if visible)
8. **Magic Effects** - Purple/green energy auras and spell effects

---

## 🎭 Animation Breakdown

### **1. Idle Animation (wizard_idle.svg)**
**Purpose**: Default resting state with subtle breathing and magical presence
**Timing**: 6 FPS
**Key Features**:
- Staff held vertically at side (x=6, y=8 to y=25)
- Gentle breathing motion in chest area
- Subtle magical sparkles around body
- Calm, scholarly expression
- Slight staff bob to show life

**Visual Elements**:
- **Staff**: Dark wood (#654321) with purple runes, glowing orb (#8B008B)
- **Body**: Layered dark robes (#1E1E1E) with purple trim (#8B008B)
- **Face**: Hooded with glowing purple eyes or scholarly features
- **Magic**: Faint purple sparkles (#8B008B) with low opacity

### **2. Move Animation (wizard_move.svg)**
**Purpose**: Walking/movement with robed stride
**Timing**: 8-10 FPS
**Key Features**:
- Staff angled for walking support
- Robes flowing with movement
- Hood/hair shifting with motion
- Maintained magical aura
- Scholarly stride pattern

**Movement Details**:
- Staff swings naturally with walking rhythm
- Robes billow behind character
- Arms move in walking pattern
- Slight lean forward for purposeful movement

### **3. Attack Animation (wizard_attack.svg)**
**Purpose**: Primary spellcasting pose - magic burst/projectile
**Timing**: 12 FPS
**Key Features**:
- Staff raised diagonally (x=18, y=6 to x=14, y=20)
- Energy burst from staff orb
- Dramatic casting stance
- Focused expression
- Primary purple energy effects

**Spellcasting Details**:
- Staff orb glows intensely with purple energy
- Casting arm extended forward
- Other arm supports staff
- Robes billow with magical energy
- Concentrated magical aura

### **4. Special Animation (wizard_special.svg)**
**Purpose**: Shadow curse or beam spell - visually distinct from attack
**Timing**: 6-8 FPS
**Key Features**:
- Staff held horizontally across body
- Dark energy emanating from staff
- Sinister casting pose
- Green energy highlights for curse magic
- More aggressive stance than attack

**Special Spell Details**:
- Staff positioned for channeling dark magic
- Green curse energy (#228B22) mixed with purple
- Menacing posture with leaning forward
- Darker magical aura
- Eyes glowing more intensely

### **5. Ultimate Animation (wizard_ultimate.svg)**
**Purpose**: High-impact magic channeling/dark explosion charge
**Timing**: 6-8 FPS
**Key Features**:
- Staff raised high above head (x=12, y=4)
- Maximum magical energy buildup
- Dramatic power-channeling pose
- Ultimate spell concentration
- Combined purple/green/silver energy effects

**Ultimate Spell Details**:
- Staff orb at maximum glow intensity
- Both arms raised for ultimate power
- Robes swirling with intense energy
- Multiple energy colors combining
- Most dramatic pose of all animations

### **6. Dodge Animation (wizard_dodge.svg)**
**Purpose**: Quick sidestep or blink-style evasion
**Timing**: 12 FPS (quick animation)
**Key Features**:
- Crouched evasive pose
- Staff held defensively
- Robes trailing from movement
- Slight magical shimmer effect
- Quick, agile movement despite robes

**Dodge Details**:
- Body lowered and angled for evasion
- Staff positioned for protection
- Robes showing motion blur
- Slight transparency effect for "blink" magic
- Defensive posture

### **7. Death Animation (wizard_death.svg)**
**Purpose**: Magical collapse or disintegration stance
**Timing**: 8 FPS
**Key Features**:
- Staff falling or planted in ground
- Collapsing/kneeling pose
- Magical energy dissipating
- Defeated but dignified posture
- Fading magical aura

**Death Details**:
- Staff either dropping or used as support
- Body slumping forward or backward
- Robes settling around fallen form
- Magical energy fading away
- Peaceful or dramatic final pose

---

## 📏 Technical Specifications

### SVG Template Structure
```svg
<svg width="24" height="30" viewBox="0 0 24 30" xmlns="http://www.w3.org/2000/svg">
  <!-- Wizard [Animation State] -->
  
  <!-- Staff (primary weapon) -->
  <line x1="X" y1="Y" x2="X2" y2="Y2" stroke="#654321" stroke-width="1.5"/>
  <circle cx="X" cy="Y" r="1.5" fill="#8B008B"/>
  
  <!-- Body/Robes (layered for depth) -->
  <ellipse cx="12" cy="24" rx="6" ry="4" fill="#1E1E1E"/>
  <ellipse cx="12" cy="20" rx="5" ry="6" fill="#2F2F2F"/>
  
  <!-- Arms (positioned per animation) -->
  <ellipse cx="X" cy="Y" rx="1.5" ry="3" fill="#8B008B"/>
  
  <!-- Head/Hood -->
  <circle cx="12" cy="12" r="3" fill="#1E1E1E"/>
  <circle cx="11" cy="11" r="0.5" fill="#8B008B"/> <!-- Left eye -->
  <circle cx="13" cy="11" r="0.5" fill="#8B008B"/> <!-- Right eye -->
  
  <!-- Magic Effects (per animation) -->
  <circle cx="X" cy="Y" r="1" fill="#8B008B" opacity="0.6"/>
  
</svg>
```

### Color Palette
- **Primary Blue**: #4169E1 (magic energy, crystal)
- **Dark Blue**: #1E3A8A (robes, hat)
- **Medium Blue**: #2563EB (robe shading)
- **Gold**: #FFD700 (sparkles, star, accents)
- **Skin Tone**: #DDBEA9 (face, hands)
- **Wood Brown**: #8B4513 (staff material)

### Animation Timing Guidelines
- **Idle**: 6 FPS - Subtle breathing and magical presence
- **Move**: 8-10 FPS - Smooth walking motion
- **Attack**: 12 FPS - Sharp, impactful casting
- **Special**: 6-8 FPS - Dramatic curse buildup
- **Ultimate**: 6-8 FPS - Maximum power channeling
- **Dodge**: 12 FPS - Quick evasive movement
- **Death**: 8 FPS - Dignified final sequence

---

## 🎯 Implementation Requirements

### File Structure
```
assets/characters/wizard/sprites/
├── wizard_idle.svg
├── wizard_move.svg
├── wizard_attack.svg
├── wizard_special.svg
├── wizard_ultimate.svg
├── wizard_dodge.svg
└── wizard_death.svg
```

### Animation Integration
- Replace current sprite sheet system with SVG-based animations
- Implement proper animation state management
- Include wizard in all animation functions
- Add to character selection system

### Character Stats (for reference)
- **Strength**: 6/10 (Moderate magical power)
- **Speed**: 8/10 (Quick movement and casting)
- **Armor**: 4/10 (Light robes, magical protection)
- **Health**: 6/10 (Moderate survivability)

---

## 🔧 Next Steps

1. **Create SVG sprites** following the above specifications
2. **Update Player.gd** animation system for wizard
3. **Integrate into character selection**
4. **Test all animations** in-game
5. **Adjust timing and visual effects** as needed

---

*This design breakdown provides the foundation for creating a fully animated Wizard character that matches the quality and complexity of other playable characters while maintaining the dark sorcerer theme.* 