# Blender Tips — The Frontier

## Viewport Navigation

### Pan / Orbit feels incredibly slow
Most likely cause: orbit pivot is far from geometry because **Orbit Around Selection** is off.

- Edit → Preferences → Navigation → enable **Orbit Around Selection**
- `Numpad .` — re-center viewport on current selection (resets orbit pivot)
- `N` panel → View tab → set **Clip Start** to `0.1` and **End** to `10000`+ for large scenes

---

## Edit Mode — Selection

### Select rings around hex corners (river banks / edge slopes)
Useful for creating identical transitions at all 6 hex corners:

1. Select all 6 corner vertices manually (the hex boundary vertices E, NE, NW, W, SW, SE)
2. `Ctrl+Numpad+` — grow selection outward one ring. Repeat up to 5 times.
3. Each press adds one more ring symmetrically around all 6 corners simultaneously
4. `G` → `Z` → move down

Because you start from the fixed corner positions, all 6 divots are identical — guaranteeing the boundary matches on every tile that shares those corners.

### Proportional editing for smooth slopes
Better than discrete rings for organic terrain transitions:

1. `Alt+Click` a boundary edge to select the outer loop
2. `O` — enable Proportional Editing
3. `G` → `Z` → move down; scroll wheel adjusts the falloff radius

---

## Texture Paint

### Setup — do this before painting
1. In Edit Mode, `A` to select all → `U` → **Smart UV Project** (or **Unwrap** if you have seams marked)
2. Switch to the **Shading** workspace
3. In the Shader Editor, add an **Image Texture** node → click **New** → set resolution (e.g. 2048×2048) → OK
4. Drag from the **Color** output dot on the Image Texture node to the **Base Color** input dot on the Principled BSDF node
5. Keep the Image Texture node **selected/highlighted** — Blender paints to whichever one is active
6. Switch to the **Texture Paint** workspace and paint

**Easy thing to forget:** if the Image Texture node isn't selected in the Shader Editor before switching to Texture Paint, Blender won't know which image to paint onto.

**Save when done:** Image → Save in the Image Editor — painted textures live in memory only until saved.

### Airbrush not working
Check in the **Properties panel → Active Tool → Stroke** sub-panel:
- **Rate** — if set too high the brush applies paint so infrequently it appears broken. Default is `0.1`
- **Stabilize Stroke** — if accidentally enabled it lags the brush behind the cursor

Also check the **Advanced** sub-panel for pressure sensitivity icons next to Strength — if lit and you're using a mouse (not a tablet), click to disable them.

### Colour palette
- In the **N panel → Tool** tab → **Color Palette** section → click **New**
- Click **+** to add the current foreground colour
- To import a palette from another .blend file: **File → Append** → navigate to that file → look in **Palettes** or **Brushes**

### Sampling a colour from the canvas
- `S` while hovering over the canvas — eyedropper, picks colour directly from the texture

---

## Mesh Smoothing

Blender offers three levels under **Mesh → Shade Smooth**:

- **Smooth Faces** — basic per-face normal smoothing
- **Smooth Edges** — smooths across edges based on angle threshold (most useful for terrain — set angle to ~30–45°)
- **Smooth Vertices** — smooths per-vertex normals

For terrain, **Smooth Edges** with an angle threshold gives the most control: sharp cliffs stay sharp, gentle slopes become smooth.

---

## River Banks — Keeping Tiles Consistent

Rivers run **along hex edges** (the boundary between two tiles), not through tile centres. At corners (where 3 tiles meet) the river transitions from one edge to another.

The challenge: the river bank terrain inside each tile must match its neighbour's bank at the shared edge, even though they're separate meshes.

### The approach

Rivers are pre-planned. For each tile that borders a river edge, the bank geometry is authored in Blender against fixed reference points so every tile that shares that edge is guaranteed to line up.

**Reference script:** `blender/hex_river_reference.py` — run it in Blender's Scripting workspace to generate a `Hex Reference` collection containing:
- A wireframe hex boundary (circumradius 200, flat-top, vertices E/W)
- Corner empties at all 6 hex vertices
- 7 profile empties per edge showing exactly where mesh vertices must land for a seamless river crossing (`corner_A`, `bank_left`, `channel_left`, `channel_mid`, `channel_right`, `bank_right`, `corner_B`)

Keep this collection visible and locked while sculpting. Snap boundary vertices to the empties — never freehand the edge.

### Creating the corner divots

The 6 hex corners are where river edges meet. To create identical geometry at all corners simultaneously:

1. Select all 6 corner vertices (E, NE, NW, W, SW, SE)
2. `Ctrl+Numpad+` up to 5 times — grows the selection outward one ring at a time, symmetrically around all corners
3. `G` → `Z` → move down to shape the bank

Because you start from the fixed corner positions every tile shares, all divots are identical — the corners will always line up between tiles.

### Edge crossing points (local space)

| Edge | X | Z |
|------|------|------|
| N (flat) | 0 | +173 |
| NE | +150 | +86.5 |
| SE | +150 | −86.5 |
| S (flat) | 0 | −173 |
| SW | −150 | −86.5 |
| NW | −150 | +86.5 |

---

## New Hex Tile Workflow

1. File → New → General → delete the default cube (`X`)
2. Add → Mesh → Circle → Vertices `6`, Radius `230` (oversized so geometry extends past the boundary)
3. `F` to fill → Tab into Edit Mode → right-click → **Subdivide** 5–6 times
4. Tab back to Object Mode → switch to **Sculpt Mode** and shape the terrain
   - **Optional — river ports at corners:** Tab into Edit Mode (Vertex select), select a corner vertex, `Ctrl+Numpad+` × 5 to expand the selection 5 rings outward, `G` → `Z` → `-5` → Enter to drop 5 units, then enable Proportional Editing (`O`), select just the corner vertex, `G` → `Z` → type `1` → scroll wheel to expand falloff radius until it covers the divot → Enter to confirm. Repeat for each corner that has a river.
5. Tab into Edit Mode → delete vertices outside the hex boundary, or use a Boolean modifier set to **Intersect** with the hex reference mesh → Apply
6. Snap outermost vertices to the reference empties so the edge profile is exact
7. `A` → `U` → **Smart UV Project**
8. Shading workspace → add **Image Texture** node → **New** → 2048×2048 → connect **Color** → **Base Color**
9. Keep the Image Texture node selected → switch to **Texture Paint** workspace → paint
10. Image → **Save**
11. File → Export → **glTF 2.0** → untick the `Hex Reference` collection → save to `assets/terrain/`

### Building river banks

Rivers are built using two techniques in combination:

**Corner divots — exact vertex selection:**
Set Proportional Size to `10` in the header bar. Select a corner vertex → `Ctrl+Numpad+` × 2 → `G` → `Z` → `-5` → Enter.  

Results seem to be:
Corner Vertex: -4
First layer:   -4
Second Layer:  -4
Third Layer:   -1.085
Forth Layer:   0.48 (imprecise)
Fifth Layer:   1.0

---

### Loading the hex reference
Run `blender/hex_river_reference.py` in the Scripting workspace to generate the reference empties and wireframe boundary. Do this once per file — keep the `Hex Reference` collection visible and locked while working.

---

## Hex Tile Template

### As a reference boundary
- Add → Mesh → **Circle**, Vertices = `6`, Radius = `200` (matches in-game hex circumradius)
- Rotate 90° on Z if needed to match in-game orientation
- Object Properties → Viewport Display → **Display As: Wire** — renders as see-through outline
- Lock it on a separate collection; keep visible while sculpting tiles

### As a starting .blend template
- Set up hex boundary, lighting, camera, and scale once
- File → Save As → `hex_template.blend`
- For each new tile: open template → immediately Save As the new tile name

### As a boolean cutter
- Extrude the hex shape into a solid volume
- Add **Boolean** modifier to terrain mesh → **Intersect** → pick the hex
- Apply to trim terrain geometry exactly to hex boundary

### As a linked asset
- Right-click the hex object → **Mark as Asset**
- Drag into any scene from the Asset Browser
- `Alt+D` (linked duplicate) — all instances share one mesh; edit one, all update
