# The Wizard's Latin Curriculum — Engineering Reference

This document is **for developers, not an in-game screen**. In the player's world, learning appears as written books, the master's inked memory exercises, spoken Latin, NPC conversation, and consequential magic. Never display modern study-app concepts, login-day reminders, external academic citations, or fourth-wall messages in VERBA.

## Actual practice sequence

1. **Comprehensible reading in context.** The physical Latin volumes show short passages with a small glossary and a question about meaning. A first correct answer establishes initial comprehension; it does NOT prove permanent mastery. The five current volumes remain world objects and spell progression sources.
2. **Retrieval instead of recognition.** Inside the same physical grimoire, press R to open *Exercitia Memoriae* (memory exercises); answer with Latin typed into the physical page, without displaying the answer first. The initial authored set has 26 prompts including starter words and material from the five manuscripts.
3. **Meaning and structure, not arbitrary word guessing.** Cards contrast relevant grammatical features (singular/plural imperatives, nominative/accusative and ablative case, verbs and adverbs). Every correction supplies the correct form, an actual Latin example, and a brief reason. Macron input is optional, not marked wrong; punctuation and capitalization are ignored.
4. **Distributed recollection.** The game remembers each exercise and schedules it after 1, 3, 7, 14, 30 and 60 **in-world dawns** after success, with a next-dawn opportunity after error. These exact intervals are a **game-design heuristic**, not an empirically proven optimal schedule. Passing time does not by itself improve the language; only a correctly retrieved form does. Uses the shared world calendar rather than device time.
5. **Practice as wizardly competence.** Three genuinely successful delayed recollections of a form grant a modest 1-mana casting-efficiency improvement. Book comprehension continues to unlock its first use. A successfully **applied** Latin spell (after a period without consulting the book) can also satisfy a due memory of that command, so actually helping people or transforming the world counts as productive language use. Repeated casting on the same day, failed spells, and book consultation do not automatically increase the recall streak. No XP comes from guessing.
6. **Mixed subjects.** The selector prioritizes overdue passages and, where possible, switches among volumes so a player practices related but distinct forms; it does not show all identical exercises in a block.

Controls: open grimoire with **G**; **R** opens the next exercise; type normally; **Enter** inscribes the answer; **R** following feedback advances; **Tab** exits to the grimoire; **Escape** closes the book. The game intercepts character keys before global shortcuts, so Latin answers can contain G, B, R and H without closing the exercise.

## Educational evidence (external to the fiction)

- Dunlosky, Rawson, Marsh, Nathan & Willingham (2013), *Improving Students' Learning With Effective Learning Techniques*, *Psychological Science in the Public Interest* 14(1). DOI: https://doi.org/10.1177/1529100612453266. A broad review rated practice testing and distributed practice as high-utility learning techniques. This supports typed recollection and return intervals rather than rereading alone.
- Karpicke & Roediger (2008), *The Critical Importance of Retrieval for Learning*, *Science* 319:966–968. DOI: https://doi.org/10.1126/science.1152408. An experiment on foreign-language vocabulary showed that continued retrieval improved later recall even when additional restudy did not.
- Paul Nation (2007), *The Four Strands*, *Innovation in Language Learning and Teaching* 1(1), 2–13. DOI: https://doi.org/10.2167/illt039.0. A balanced curriculum needs meaning-focused input, meaning-focused output, deliberate attention to form, and fluency development. VERBA's book reading, NPC exchange, grammar-focused ink exercises and meaningful spell use are the first pieces of that balance.

This research does **not** prove that an English-language quest game by itself teaches Latin fluency; these are initial mechanics, not efficacy trials. Review lengths, reward size, exercise variety, language level and reading comprehension must be play-tested with real learners. No audio/pronunciation training, free-form translation, adaptive difficulty estimator, or broad Latin morphology generator is yet implemented.

## Expansion gate

Further lessons must be authored with checked Latin grammar, introduce one or two useful forms in comprehensible contextual reading, include both recognition and unprompted recall, and lead to a real craft/quest action. The next social interaction pass should allow NPCs to ask questions **in Latin** appropriate to the player's demonstrated comprehension, not merely the number of books clicked.