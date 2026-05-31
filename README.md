# Du Lạc — 2D Adventure Game (Godot 4.6)

> Game phiêu lưu 2D lấy bối cảnh làng quê Bắc Bộ Việt Nam, kể câu chuyện về Tính — một cậu bé đặc biệt — và phóng viên Lan Anh khám phá làng Dú Lạc đầy bí ẩn.

---

## Tổng quan nhanh

| Thuộc tính | Giá trị |
|---|---|
| Engine | Godot 4.6.3 stable |
| Renderer | Forward+ / D3D12 (Windows) |
| Ngôn ngữ | GDScript |
| Main scene | `village.tscn` |
| Thể loại | 2D Top-down Adventure / Story-driven |
| Platform mục tiêu | PC (Windows), Mobile (Android/iOS) |
| Trạng thái | 🟡 Prototype — asset setup, chưa có gameplay logic |

---

## Cốt truyện tóm tắt

Lan Anh, phóng viên trẻ, đến làng Dú Lạc điều tra tin đồn về một đứa trẻ kỳ lạ tên Tính — cậu bé có thể giao tiếp với đom đóm và bướm. Qua hành trình khám phá làng, Lan Anh dần hiểu ra bí mật phía sau sự đặc biệt của Tính và vẻ đẹp tiềm ẩn của cuộc sống làng quê.

**Gameplay loop chính:**
- Điều khiển Tính đi khắp làng
- Nói chuyện với NPC để mở khóa câu chuyện
- Mini-game Ô Ăn Quan với NPC đối thủ
- Khám phá các địa điểm: làng, ngọn núi, hang động bí mật

---

## Cấu trúc thư mục

```
2d-o-an-quan/
├── assets/
│   ├── new/                    # Asset mới nhất (NPC sprites từ ChatGPT)
│   │   ├── npc/                # Sprite sheet các NPC phụ
│   │   ├── lan_anh_move/       # Sprite sheet Lan Anh di chuyển
│   │   └── tinh_move/          # Sprite sheet Tính di chuyển
│   ├── background/
│   │   ├── morning/            # Background ban sáng
│   │   └── evening/            # Background ban chiều/tối
│   ├── characters/             # Sprite sheet nhân vật tổng hợp
│   ├── items/
│   │   ├── village/            # Item trong làng
│   │   ├── mountain/           # Item trên núi
│   │   └── hang/               # Item trong hang
│   └── *.png                   # Map, tileset, gameplay assets
├── *.tscn                      # Scene files (1 scene = 1 NPC + village)
├── tinh.gd                     # Script nhân vật chính Tính
├── lan_anh.gd                  # Script nhân vật Lan Anh
├── project.godot               # Cấu hình dự án
└── docs/                       # (cần tạo) Tài liệu dự án
```

---

## Scenes hiện có

| Scene | Mô tả |
|---|---|
| `village.tscn` | **Main scene** — map làng, spawn tất cả NPC |
| `tinh.tscn` | Nhân vật chính Tính (CharacterBody2D, player-controlled) |
| `lan_anh.tscn` | Nhân vật đồng hành Lan Anh |
| `ong_gia.tscn` | NPC Ông Nhiêu (cụ già) |
| `ba_gia.tscn` | NPC Bà Tư (cụ già nữ) |
| `hung.tscn` | NPC Hùng (thợ đan lát) |
| `minh.tscn` | NPC Minh (chủ quán nước) |
| `npc_nu.tscn` | NPC phụ nữ làng |
| `young_boy.tscn` | NPC bé trai |
| `young_girl.tscn` | NPC bé gái |
| `oanquanboy.tscn` | NPC bé trai đối thủ Ô Ăn Quan |

---

## Scripts hiện có

### `tinh.gd`
- Extends `CharacterBody2D`
- 4 hướng di chuyển: up/down/left/right
- Animation states: `idle`, `walk_right`, `walk_left`, `walk_front`, `walk_behind`
- Speed: 90 px/s

### `lan_anh.gd`
- Extends `CharacterBody2D`
- 4 hướng + run mode (giữ "run")
- Walk speed: 90 px/s | Run speed: 150 px/s
- Animation prefix: `walk_*` / `run_*`

---

## Assets map

| File | Dùng cho |
|---|---|
| `du_lac_village_map.png` | Tileset map làng (ban ngày) |
| `du_lac_evening_map.png` | Tileset map làng (ban tối) |
| `du_lac_ngon_nui_*.png` | Map ngọn núi + hang bí mật |
| `o_an_quan_gameplay*.png` | UI/board game Ô Ăn Quan |
| `du_lac_talking_template.png` | Template dialog box |
| `noithat_*.png` | Nội thất các địa điểm (đình làng, nhà bà Tư...) |

---

## Những gì chưa có (TODO)

- [ ] Dialog system (chưa có code)
- [ ] NPC AI movement script
- [ ] Game state / save system
- [ ] Ô Ăn Quan logic
- [ ] Scene transitions
- [ ] Audio
- [ ] Camera follow player
- [ ] Collision map cho village.tscn
