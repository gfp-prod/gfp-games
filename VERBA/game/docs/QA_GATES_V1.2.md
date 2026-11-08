# Quality gates — do not call a build finished until these pass

1. **Engine import:** Godot 4.5+ loads the scene with zero parser errors. Headless import on GitHub Actions is configured but not yet run.
2. **Movement:** F5. With mouse captured, W walks forward, S backward, A/D strafe, Space jumps, Shift sprints; no click-drag and no terrain-height teleport.
3. **Solid terrain:** Player cannot fall through terrain and can collide with tree trunks, rocks and the cottage. Player can move on gentle slopes.
4. **Animal navigation:** Deer and wolves replan around obstacles, physically collide with the world, and have terrain contact. Agent navigation paths should be inspected in running Godot.
5. **Art install:** Run INSTALL_VERBA_ASSETS.bat. Check `assets/models/cc0/tree1.glb` and `assets/textures/real/bark_diffuse.jpg` are present, and texture image metadata changes after installation.
6. **Readable art:** Examine a first-person screenshot of the cottage, a tree trunk, the grimoire and wildlife. Discard/rework anything visually incoherent.
7. **Magic:** Cast `ignis`, `cresce`, `pluvia` and watch effects on independent object state and ecology; the grimoire should respond to collected vocabulary.
8. **Release:** Do not publish or call the build verified merely because the ZIP passes integrity checks; use actual Godot engine and screenshot review.
