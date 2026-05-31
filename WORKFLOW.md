# Workflow — Quy trình làm việc dự án Du Lạc

> Tài liệu này mô tả các giai đoạn phát triển, thứ tự ưu tiên, và cách làm việc hiệu quả với AI assistant trên dự án này.

---

## Trạng thái hiện tại (31/05/2026)

```
Phase 1: Asset Setup     ████████░░  80% hoàn thành
Phase 2: NPC System      ██░░░░░░░░  20% (script đang viết)
Phase 3: Dialog System   ░░░░░░░░░░   0% (chưa bắt đầu)
Phase 4: Gameplay        ░░░░░░░░░░   0% (chưa bắt đầu)
Phase 5: Polish          ░░░░░░░░░░   0%
```

---

## Phase 1 — Asset Setup ✅ (gần xong)

### Đã xong
- [x] Map làng `du_lac_village_map.png` import vào TileMap
- [x] Sprite sheet tất cả NPC: idle + moving (4 frames mỗi animation)
- [x] Scene file cho từng NPC (`.tscn`) với SpriteFrames setup
- [x] Nhân vật chính Tính — script di chuyển 4 hướng
- [x] Lan Anh — script di chuyển 4 hướng + run

### Còn lại
- [ ] Đặt NPC đúng vị trí trên map village
- [ ] Setup CollisionShape2D cho TileMap
- [ ] Camera2D follow Tính

---

## Phase 2 — NPC System 🟡 (đang làm)

### Mục tiêu
Mỗi NPC tự di chuyển qua lại (moving) và có idle animation tại chỗ.

### Việc cần làm theo thứ tự
1. Viết `npc_base.gd` — script dùng chung cho tất cả NPC
2. Gắn script vào từng `.tscn` NPC
3. Config export variables per-NPC (tốc độ, giới hạn di chuyển)
4. Test collision + boundary

### Thiết kế NPC movement
```
State Machine:
  MOVING → đi về một hướng với walk_speed
          → khi chạm boundary hoặc hết timer → IDLE
  IDLE   → play idle animation, đứng yên idle_duration giây
          → sau đó → MOVING (đổi chiều)
```

---

## Phase 3 — Dialog System ⬜ (tiếp theo)

### Mục tiêu
Chạm vào NPC → hiện hộp thoại → đọc → đóng → NPC tiếp tục di chuyển.

### Việc cần làm
1. Tạo `DialogUI.tscn` (CanvasLayer → Control → Panel, Label, Button)
2. Viết `dialog_manager.gd` (Autoload singleton)
3. Thêm `Area2D` detect vào mỗi NPC
4. Viết dialog data per-NPC (Array of Strings)
5. Typewriter effect (hiện chữ từng ký tự)
6. Test trên PC + mobile (touch)

### Cấu trúc dialog data
```gdscript
# Trong mỗi NPC script
var dialog_lines: Array[String] = [
    "Ê nhóc, mày lạc hả?",
    "Ngồi xuống đây cái đã.",
    "Làng này tao biết hết..."
]
```

---

## Phase 4 — Core Gameplay ⬜

### Ô Ăn Quan mini-game
1. Setup board UI từ `o_an_quan_gameplay.png`
2. Viết game logic (6 ô mỗi bên, quân cờ, lượt đi)
3. AI đối thủ đơn giản (oanquanboy)
4. Win/lose condition

### Story progression
1. Biến `GameState` autoload (đã nói chuyện với ai, đã khám phá đâu)
2. Mở khóa dialog mới theo tiến trình
3. Scene transitions (làng → núi → hang)

---

## Phase 5 — Polish ⬜

- [ ] Audio: nhạc nền, sound effect bước chân, dialog
- [ ] Particle effects: đom đóm, bướm
- [ ] Lighting: ban tối dùng PointLight2D
- [ ] Save/load game state
- [ ] Mobile controls (virtual joystick)
- [ ] Export build Android

---

## Quy ước đặt tên

| Loại | Convention | Ví dụ |
|---|---|---|
| Scene | `snake_case.tscn` | `ong_gia.tscn` |
| Script | `snake_case.gd` | `npc_base.gd` |
| Asset | `snake_case.png` | `du_lac_village_map.png` |
| Node | `PascalCase` | `AnimatedSprite2D` |
| Variable | `snake_case` | `walk_speed` |
| Constant | `UPPER_SNAKE` | `WALK_SPEED` |
| Signal | `snake_case` | `dialog_closed` |

---

## Cách làm việc với AI

Khi nhờ AI (Claude/ChatGPT) hỗ trợ, cung cấp context:

```
- Engine: Godot 4.6.3 GDScript
- Scene đang làm: [tên scene]
- Script hiện tại: [paste code]
- Vấn đề: [mô tả]
- Đã thử: [những gì đã thử]
```

Các file quan trọng cần đọc trước:
- `README.md` — tổng quan
- `WORKFLOW.md` — file này
- `OVERVIEW.md` — kiến trúc kỹ thuật
