# GG CAD / GG Editor — Initialization Prompt

## Project

GG CAD (GG Editor) is a lightweight CAD/CAE frontend written in Godot 4.5.1 using typed GDScript 2.0.

Purpose:

* create and edit geometric entities;
* generate Gmsh `.geo` files;
* manage physical groups;
* prepare mesh generation workflows;
* export geometry and problem definitions for external CLI solvers.

The project follows a document-centric architecture and is being developed incrementally through small commits.

---

## Core Principles

* Typed GDScript everywhere.
* MVC-inspired architecture.
* Source of truth is always stored in the model.
* Rendering never owns geometry.
* UI never owns geometry.
* Small incremental commits.
* Minimal Godot magic.
* Explicit state transitions.
* Predictable command processing.

---

## Technology Stack

* Godot 4.5.1
* GDScript 2.0
* VS Code + godot-tools
* Git CLI
* Windows 11

---

## Current Scene Structure

```text
Main
└─ RootLayout
   ├─ VSplitContainer
   │  ├─ ViewportPanel
   │  │  └─ GGViewport
   │  └─ ConsolePanel
   └─ StatusLabel
```

Viewport occupies the upper workspace.

Console occupies the lower workspace.

StatusLabel displays the active document name.

---

## Architecture

### GGModel

Stores document state.

Responsibilities:

* document metadata;
* geometry storage;
* object identifiers;
* dirty-state tracking.

Contains:

```text
document_name
units
is_dirty

points : Array[GGPoint2D]
next_point_id : int
```

---

### GGPoint2D

Represents a geometric point.

Contains:

```text
id : int
x : float
y : float
```

Point identifiers are stable.

Deleted identifiers are never reused.

User-visible operations use IDs instead of array indices.

---

### GGViewport

Rendering layer.

Responsibilities:

* read geometry from GGModel;
* convert world coordinates to screen coordinates;
* draw geometry;
* display point identifiers.

Viewport must never modify geometry.

Source of truth always remains inside GGModel.

Current rendering pipeline:

```text
GGModel.points
        ↓
world_to_screen()
        ↓
draw_circle()
        ↓
draw_string()
```

---

### main.gd

Acts as shell/controller.

Responsibilities:

* command parsing;
* command dispatch;
* validation;
* command history;
* communication with model;
* viewport redraw requests.

Uses command handlers:

```text
cmd_help()
cmd_about()
cmd_new()
cmd_status()
cmd_history()
cmd_clear()

cmd_add_point()
cmd_move_point()
cmd_remove_point()
cmd_list_points()
cmd_clear_points()

cmd_rename()
```

---

## Command Language

Implemented commands:

```text
help
about
clear
new
status
history
rename

add_point
move_point
remove_point
list_points
clear_points
```

Command workflow:

```text
input
↓
tokenize
↓
validate
↓
convert types
↓
mutate model
↓
viewport redraw
↓
render output
```

---

## Coordinate System

Current geometry representation:

```text
x : float
y : float
```

Current viewport pipeline:

```text
world coordinates
↓
world_to_screen()
↓
screen coordinates
```

Viewport currently displays:

* points;
* point identifiers.

---

## Important Architectural Decisions

### Stable Point IDs

Points are identified by:

```text
point.id
```

and never by array position.

Correct:

```text
move_point 17
remove_point 17
```

Incorrect:

```text
move point at array index 3
```

Reason:

Future entities such as:

```text
GGLine2D
GGArc2D
GGCurveLoop
GGSurface
```

must reference persistent point identifiers.

---

### Rendering Is Read-Only

Viewport never modifies geometry.

Workflow:

```text
command
↓
model
↓
viewport redraw
```

Never:

```text
viewport
↓
modifies model
```

---

### Typed GDScript Required

Always prefer explicit typing:

```gdscript
var point_id: int
var x: float
var name: String
```

Avoid implicit Variant usage whenever possible.

---

## Current Development Status

Completed:

```text
Shell prototype
Command history
Parser validation
Console subsystem

GGModel
GGPoint2D

Stable point IDs

Point CRUD:
- add_point
- move_point
- remove_point
- list_points
- clear_points

GGViewport

Point rendering
Point labels
Viewport redraw pipeline
```

Current architecture:

```text
GG Shell
↓
GGModel
↓
GGPoint2D
↓
GGViewport
↓
Canvas Rendering
```

---

## Next Planned Milestones

Near-term:

```text
Coordinate axes

World origin visualization

Y-axis inversion

Viewport centering

Zoom

Pan
```

After viewport stabilization:

```text
GGLine2D

Line rendering

GGArc2D

Arc rendering

Geometry serialization

Gmsh .geo export
```

Long-term:

```text
Selection state

Undo / Redo

Physical groups

Mesh controls

Solver export
```

---

## Coding Style

* No emojis.
* Technical precision preferred.
* Explain architectural reasons behind decisions.
* Follow Godot 4.x best practices.
* Use typed GDScript only.
* Prefer incremental evolution over large rewrites.
* Respect existing architecture unless there is a strong reason to change it.

---

## Current Development Focus

The project has successfully transitioned from a shell prototype to a graphical CAD prototype.

Current priority:

```text
GGViewport
↓
Coordinate axes
↓
World coordinate system
↓
Viewport navigation
```

Geometry entities (lines, arcs, loops and surfaces) should be introduced only after viewport foundations become stable.
