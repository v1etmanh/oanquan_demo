# Overview — Kiến trúc kỹ thuật dự án Du Lạc

> Tài liệu kỹ thuật cho AI và developer đọc để hiểu cấu trúc code, node tree, và design pattern của dự án.

---

## Tech Stack

- **Engine:** Godot 4.6.3 stable
- **Language:** GDScript (dynamic typed, có thể thêm type hints)
- **Renderer:** Forward+ với D3D12 trên Windows
- **Physics:** Jolt Physics (3D engine, dùng CharacterBody2D cho 2D)
- **Input:** Arrow keys để di chuyển, Space/Enter để interact

---

## Node Tree — Kiến trúc tổng thể

```
village.tscn  (Node2D — Main Scene)
├── TileMap                          # Map làng, tileset từ PNG atlas
├── Camera2D                         # (TODO) Follow player
├── Tinh (CharacterBody2D)           # Nhân vật chính — player controlled
│   ├── AnimatedSprite2D             # Sprite + animations
│   ├── CollisionShape2D             # Physics body
│   └── [tinh.gd]                    # Script điều khiển
├── LanAnh (CharacterBody2D)         # Nhân vật đồng hành
│   ├── AnimatedSprite2D
│   ├── CollisionShape2D
│   └── [lan_anh.gd]
├── OngGia (CharacterBody2D)         # NPC — ông Nhiêu
│   ├── AnimatedSprite2D             # animations: idle, moving
│   ├── CollisionShape2D (Circle)    # r=61px
│   └── [npc_base.gd — TODO]
├── BaGia / Hung / Minh / ...        # Các NPC khác, cùng cấu trúc
└── CanvasLayer                      # (TODO) Dialog UI overlay
    └── DialogUI (Control)
```

---

## Animation System

### Quy ước animation name

**Nhân vật chính (Tính, Lan Anh) — 4 hướng:**
```
idle          # đứng yên, hướng front (mặc định)
left          # idle nhìn trái
right         # idle nhìn phải
behind        # idle nhìn sau
walk_front    # đi xuống
walk_behind   # đi lên
walk_left     # đi trái
walk_right    # đi phải
run_front     # chạy xuống (Lan Anh only)
run_behind    # chạy lên
run_left      # chạy trái
run_right     # chạy phải
```

**NPC phụ — side-view 2 trạng thái:**
```
idle          # hành động đặc trưng tại chỗ (ngồi, vá áo, đan...)
moving        # đi về một hướng (side-view)
              # flip_h = true khi đổi chiều
```

### Sprite sheet format
- Mỗi animation: 4 frames nằm ngang
- Frame size NPC: 250×250px (moving) hoặc ~139×211px (idle)
- Format: PNG với transparent background (removebg)
- Cắt bằng `AtlasTexture` với `region = Rect2(x, 0, width, height)`

---

## Script Architecture

### `tinh.gd` — Player Controller
```
CharacterBody2D
  ├── Input polling trong _physics_process()
  ├── velocity = normalized_input * WALK_SPEED
  ├── move_and_slide()
  └── update_animation(input_vector)
      ├── if zero → play_idle_animation() theo last_direction
      └── else → play walk_* theo axis ưu tiên (|x| > |y|)
```

### `lan_anh.gd` — Companion Controller  
```
Giống tinh.gd + thêm:
  ├── RUN_SPEED = 150.0
  ├── Input.is_action_pressed("run") → bool is_running
  └── animation prefix: "walk_" hoặc "run_"
```

### `npc_base.gd` — NPC AI (TODO)
```
CharacterBody2D
  ├── State Machine: MOVING / IDLE / TALKING
  ├── MOVING: velocity = direction * walk_speed, move_and_slide()
  │          khi chạm boundary → IDLE, flip_h
  ├── IDLE: play("idle"), đếm idle_timer
  │        hết timer → MOVING
  └── TALKING: velocity = 0, play("idle"), face player
```

---

## Dialog System (TODO)

### Thiết kế
```
Autoload: DialogManager (singleton)
  ├── show_dialog(npc_name, lines: Array[String])
  ├── next_line() → advance hoặc close
  ├── close_dialog() → emit dialog_closed
  └── is_dialog_open: bool

CanvasLayer → DialogUI
  ├── Panel (background box)
  ├── Label speaker_name
  ├── RichTextLabel dialog_text  (typewriter via Timer)
  └── Button "Tiếp >"
```

### Flow
```
Player enters Area2D của NPC
  → NPC emit signal player_nearby
  → NPC set state = TALKING, stop moving, face player
  → call DialogManager.show_dialog(npc_name, dialog_lines)
  → Player input locked

Player press Space/tap
  → DialogManager.next_line()
  → Nếu hết lines: emit dialog_closed
    → NPC resume MOVING
    → Player input unlocked
```

---

## Game State (TODO)

```gdscript
# Autoload: GameState
var talked_to: Dictionary = {}      # { "ong_gia": true, ... }
var visited_places: Array = []      # ["village", "mountain", ...]
var o_an_quan_wins: int = 0
var story_flags: Dictionary = {}    # { "found_firefly": false, ... }
```

---

## Asset Pipeline

```
ChatGPT → PNG (4 frames nằm ngang, nền đen)
  ↓ remove.bg
  → PNG transparent
  ↓ import vào Godot
  → AtlasTexture (cắt từng frame bằng Rect2)
  ↓ gắn vào SpriteFrames
  → AnimatedSprite2D
```

**Lưu ý quan trọng:**
- NPC moving sprite: frame width = total_width / 4
- NPC idle sprite: crop thủ công từ sprite sheet (xem `ong_gia.tscn` làm mẫu)
- Tất cả sprite dùng `Filter: Nearest` để giữ pixel crisp

---

## Input Map

| Action | Key mặc định |
|---|---|
| `ui_left` | Arrow Left |
| `ui_right` | Arrow Right |
| `ui_up` | Arrow Up |
| `ui_down` | Arrow Down |
| `run` | Shift (TODO: thêm) |
| `interact` | Space / Enter (TODO) |

---

## Các pattern cần nhất quán

1. **NPC scripts** dùng chung `npc_base.gd` qua `@export var` — không viết riêng từng file
2. **Dialog data** lưu trong NPC script, không hardcode trong dialog manager
3. **Signals** dùng để communicate giữa NPC ↔ DialogManager ↔ Player, không gọi trực tiếp
4. **State enum** cho mọi stateful object (NPC, dialog, game flow)
