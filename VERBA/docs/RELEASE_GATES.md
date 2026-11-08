# VERBA release gates

1. **Complete-source gate:** repository includes `VERBA/project.godot`, scenes, scripts, models, shaders and textures (not just a design brief).
2. **No-installer gate:** no external fetch script needs to be executed on Windows to display the expected art.
3. **Godot import gate:** cold import succeeds in supported Godot 4 versions.
4. **Godot parse gate:** zero script parser errors.
5. **Movement gate:** WASD moves on solid ground, captured mouse independently rotates yaw/pitch.
6. **Collision gate:** player/animal cannot pass through cottage walls, trunks, boulders; animals navigate around them.
7. **Art gate:** first-person grimoire reads as a book; cottage reads as a building; animals read at typical distances; lighting not blown out.
8. **Learning gate:** Latin words must be recalled from keyboard and successful casts produce visible world-space feedback.

**Current status (2026-11-08):** source-side checks passed for v1.2.1 ZIP. Native engine checks have not yet been performed. The GitHub branch does not yet contain the complete Godot project.
