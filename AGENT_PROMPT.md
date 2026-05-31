# AGENT ONBOARDING PROMPT — Dự án Du Lạc (Godot 4.6)

## Mày là AI agent làm việc trên dự án game Godot 4.6 tên "Du Lạc".
## Trước khi làm BẤT CỨ điều gì, đọc hết các file doc bên dưới bằng Desktop Commander.

---

## BƯỚC 1 — ĐỌC TÀI LIỆU DỰ ÁN (BẮT BUỘC, ĐỌC THEO THỨ TỰ)

Dùng Desktop Commander tool để đọc lần lượt:

```
1. desktop-commander:read_file("C:\godot\2d-o-an-quan\README.md")
   → Tổng quan dự án, scene list, asset map, TODO

2. desktop-commander:read_file("C:\godot\2d-o-an-quan\OVERVIEW.md")
   → Kiến trúc kỹ thuật, node tree, animation convention, script design

3. desktop-commander:read_file("C:\godot\2d-o-an-quan\WORKFLOW.md")
   → Phase hiện tại, việc cần làm theo thứ tự, quy ước đặt tên
```

---

## BƯỚC 2 — SCAN CẤU TRÚC THƯ MỤC

```
desktop-commander:list_directory("C:\godot\2d-o-an-quan", depth=2)
```

Chú ý:
- File `.gd` ở root = scripts chính
- Folder `assets/new/npc/` = sprite sheet NPC
- Folder `assets/new/tinh_move/` và `lan_anh_move/` = sprite nhân vật chính
- Mỗi `.tscn` ở root = 1 scene NPC hoặc map

---

## BƯỚC 3 — ĐỌC SCRIPT LIÊN QUAN ĐẾN TASK

Tùy task, đọc thêm các file sau:

```
# Script nhân vật chính
desktop-commander:read_file("C:\godot\2d-o-an-quan\tinh.gd")
desktop-commander:read_file("C:\godot\2d-o-an-quan\lan_anh.gd")

# Script NPC
desktop-commander:read_file("C:\godot\2d-o-an-quan\npc_roam.gd")
desktop-commander:read_file("C:\godot\2d-o-an-quan\npc_static.gd")

# Scene cụ thể nếu cần
desktop-commander:read_file("C:\godot\2d-o-an-quan\[tên_scene].tscn")
```

---

## CONTEXT KỸ THUẬT CỐT LÕI (đọc ngay không cần tool)

- **Engine:** Godot 4.6.3 stable — GDScript
- **Main scene:** `village.tscn`
- **Nhân vật chính:** Tính (`tinh.tscn` + `tinh.gd`) — AI-controlled, tự đi quanh Lan Anh
- **Nhân vật player:** Lan Anh (`lan_anh.tscn` + `lan_anh.gd`) — player dùng arrow keys + run
- **NPC static** (idle tại chỗ): `ong_gia`, `ba_gia`, `minh`, `hung`, `oanquanboy` → dùng `npc_static.gd`
- **NPC roam** (đi lại): `young_boy`, `young_girl`, `npc_nu` → dùng `npc_roam.gd`
- **Animation NPC:** 2 states — `idle` và `moving` (4 frames, side-view, flip_h để đổi chiều)
- **Animation Tính/Lan Anh:** 4 hướng — `walk_front/behind/left/right`, idle: `idle/behind/left/right`
- **Chưa có:** dialog system, camera follow, collision map, save/load, audio

---

## QUY TẮC KHI VIẾT CODE

1. **GDScript 4.x** — dùng `@onready`, `@export`, type hints khi có thể
2. **Không tự ý thêm node** vào `.tscn` bằng code — chỉ modify script `.gd`
3. **NPC dùng chung script** qua `@export var` — không viết riêng từng file NPC
4. **Signals** để communicate giữa các node, không gọi trực tiếp sang node khác
5. **State enum** cho mọi object có state (NPC, dialog, etc.)
6. Khi sửa file dùng `desktop-commander:edit_block` thay vì write_file để tránh mất code
7. **Luôn đọc file hiện tại trước khi sửa** — dùng `read_file` để lấy nội dung mới nhất

---

## VỊ TRÍ CÁC FILE QUAN TRỌNG

```
C:\godot\2d-o-an-quan\
├── README.md          ← tổng quan
├── OVERVIEW.md        ← kiến trúc kỹ thuật
├── WORKFLOW.md        ← phase & todo list
├── tinh.gd            ← script Tính (AI orbit Lan Anh)
├── lan_anh.gd         ← script Lan Anh (player)
├── npc_static.gd      ← NPC đứng yên
├── npc_roam.gd        ← NPC đi lại
├── village.tscn       ← main scene
├── ong_gia.tscn       ← NPC ông già
├── ba_gia.tscn        ← NPC bà già
├── hung.tscn          ← NPC thợ đan
├── minh.tscn          ← NPC chủ quán
├── npc_nu.tscn        ← NPC phụ nữ làng
├── young_boy.tscn     ← NPC bé trai
├── young_girl.tscn    ← NPC bé gái
├── oanquanboy.tscn    ← NPC đối thủ Ô Ăn Quan
└── assets/
	├── new/npc/       ← sprite NPC (idle + moving)
	├── new/tinh_move/ ← sprite Tính
	└── new/lan_anh_move/ ← sprite Lan Anh
```

---

## SAU KHI ĐỌC XONG

Tóm tắt lại bằng 3 câu:
1. Dự án đang ở phase nào
2. File nào liên quan đến task hiện tại
3. Sẽ làm gì cụ thể

Rồi mới bắt đầu làm.
