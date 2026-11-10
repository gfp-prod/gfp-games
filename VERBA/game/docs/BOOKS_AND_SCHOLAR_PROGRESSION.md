# VERBA — Books, Latin, Scholar XP and Mana (first implementation)

**Status:** Implemented and checked in the actual Godot CI test suite. Visual quality is reviewed separately.

## First playable sequence

1. Start the Hollow Vale and look for the low stone marked **DE HERBIS**, near the starting clearing. It holds an actual three-dimensional book.
2. Approach and press **E**. The book enters your library and the physical grimoire rises to show its Latin passage.
3. Read the three Latin sentences. The opposite page gives a short glossary.
4. Press **N** to attempt the Latin comprehension question. Select an answer with **1, 2, or 3**.
5. A correct response grants **one-time scholarship XP** and teaches subject-specific magic. Wrong answers can be retried, but earn no XP. Rereading completed books earns no additional XP.
6. Earning enough XP increases Scholar level and maximum mana. Successful magic consumes mana, and known forms cost less.
7. Use **G** to open/close the physical grimoire, **B** to cycle collected books and spell notes, and **S/L** to save/restore from within it.

Other books in the current region: `De Animalibus` (bestiary) and `De Igne et Aqua` (elements). All three are collected from the world, not selected from a start-screen menu.

## Authored reading content

Books live in `data/books.json`; every record has a unique ID, subject, physical location, short graded Latin passage, glossary, Latin comprehension question, three answer choices, answer index, XP, and taught spell forms. The file passes `tests/validate_books.py`.

The present book contents and questions are original starter educational material. Expand them with vetted Latin rather than automatically fabricated grammar.

## Leveling rules (initial balancing, subject to playtesting)

- Scholar begins at level 1 with **26 maximum mana**.
- Each mastered book grants a predefined XP reward **once**.
- Next-level threshold is `20 + (level - 1) × 15` XP.
- Gaining a level increases maximum mana by **12** and refills mana.
- A form taught by a studied book costs **7 mana**; an unknown valid form can still be attempted for **16 mana**, preserving the principle that actual Latin knowledge can precede a collected book.
- Mana regenerates gradually. Incorrect, unrecognized, or ineffective spells do not spend mana.

This progression rewards understanding without requiring endless experience farming or treating vocabulary as arbitrary icons.

## Files and validation

- `scripts/scholar.gd`: book ownership, level/XP, mana, studied forms and schema-compatible saved state
- `scripts/grimoire.gd`: physical book pages, Latin comprehension, answer feedback, diegetic XP/mana readout
- `scripts/player.gd`: existing FPS controls, new book keys, mana-gated world spellcasting
- `scripts/pickup.gd`, `scripts/world.gd`: physical book placement/collection
- `scripts/world_persistence.gd`: retains discovered and completed books, mana and spell knowledge and suppresses respawn of collected volumes
- `tests/scholar_progression_test.gd`: correct/wrong answers, mastery costs, no repeat XP, persistence
- `tests/book_world_loop_test.gd`: actual world object -> E pickup -> physical page -> answer -> XP/mana -> growth spell -> fresh-world restore
- `tests/book_visual_gallery.gd`: three actual rendered first-person screenshots of the open book, question and result

## Important limits

This is one *complete starter loop*, not the finished education system. Longer manuscripts, page-turn geometry, a richer bookcase/library, subject mastery trees, fully natural conversation, mana/audio VFX, interactive writing and more convincing parchment/binding are future work. Actual GPU screenshots must be reviewed before claiming an artistic improvement.
