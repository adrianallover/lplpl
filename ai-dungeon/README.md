# AI Dungeon setup: Dynamic Large, second person, real dialogue, lethal fights

You paste two fields and change four settings. The rest of this file explains why each line is there, which of your complaints it fixes, and how to check it in your own game.

## 1. Paste these

**AI Instructions**: 1,295 characters, 269 tokens (`AI_INSTRUCTIONS.txt`)

```
Second person, present tense: "you" is always the player's character; everyone else is third person.
- Lines starting with > are the player's input: resolve exactly what was attempted, no more. Never write the player's words, choices, thoughts or emotions. Show the outcome and reactions, then stop where the player can act.
- Narrate only what the player's character perceives; others' minds show only through words and actions.
- Make who did and said what unmistakable: one speaker per paragraph, name speakers in groups, use names when a pronoun could fit two people. Never swap actions, speech, items or wounds between characters.
- World Lore, Plot Essentials and past events are fact; names, looks, personalities, powers and relationships hold until the story changes them. Anyone matching an established character is that character; new characters never reuse a name.
- NPCs pursue their own goals and know only what they've seen, heard or learned by role or power, never narrator-only facts; thoughts stay private without telepathy.
- Positions, gear, clothes, wounds and time change only for a shown reason.
- Outcomes follow established power and condition: a god's punch sends a mortal flying, broken or dead, never a stagger.
- Gore, swearing and sex are fine where the story leads.
```

**Author's Note**: 529 characters, 112 tokens (`AUTHORS_NOTE.txt`)

```
NPCs talk plenty when they have reason to, like real people: casual, sometimes modern-sounding, each voice distinct, moods shifting with the moment through jokes, banter, irritation, swearing, awkwardness or tenderness. Fights are fast, brutal and potentially lethal; enemies fight to win and damage scales with each fighter's power. Tropes, bad luck and dreams grow from events. Narration stays lean: action and dialogue first, brief concrete details, no recaps or repeated phrasing. Every action and line is clearly attributed.
```

**Settings**

| Setting | Value | Why |
|---|---|---|
| Model | Dynamic Large | |
| Response length | 150 | Latitude's recommendation for Dynamic Large. At 100, fights get cut off mid-exchange. Much longer leaves the AI room to run past your turn and start acting for you. |
| Third Person (Plot component) | Off | It replaces "You" in your Do and Say lines with a name, which breaks the rule that "you" is always the player's character. |
| AI Instructions dropdown | Save as a reusable set | Scenarios bring their own instructions, which replace yours. A saved set (up to 5 sets, names up to 32 characters) can be selected in any adventure or scenario with one click. |

## 2. Why it's written this way

Each turn, AI Dungeon sends the AI these pieces, in this order:

1. Your AI Instructions, as the system prompt
2. Plot Essentials
3. Triggered Story Cards, under a `World Lore:` header
4. Story Summary
5. Memory Bank
6. Recent story
7. The Author's Note, in square brackets
8. Your newest action

Your Do and Say actions appear as lines starting with `>`. Every decision below follows from that layout.

1. **It names what the AI actually sees.** "Lines starting with > are the player's input" tells the model exactly which text is you. That stops it from treating your lines as narration or handing your actions to someone else. "World Lore" is the label your Story Cards carry in the prompt.
2. **Who did what gets concrete techniques, not a list of nouns.** One speaker per paragraph. Name the speakers in group scenes. Use names whenever "he" or "she" could mean two people. Never move actions, speech, items or wounds from one character to another.
3. **Narration only covers what you can perceive.** Perspective mix-ups start when the AI narrates an NPC's private thoughts. The point of view slides, lines get pinned on the wrong person, and NPCs start "knowing" what only the narrator knew. Latitude's own example instructions for Dynamic Large say the same thing ("only write what is perceivable").
4. **Story Cards stay canon without contradicting each other.**
   - Card facts hold *until the story changes them*, so relationships can still grow, and wounds or deaths stick.
   - Anyone who matches an established character *is* that character. The guard captain from your card shows up as her, not as a stranger with a new name.
   - New characters never reuse an existing name.
   - NPCs can know things through their role or powers, so oracles, gods and telepaths defined in your cards still work.
5. **Scaling has a concrete example.** "A god's punch sends a mortal flying, broken or dead, never a stagger." The example deliberately mentions no walls. Models copy examples, and an example with walls tends to produce walls that weren't in the scene.
6. **The Author's Note is short, and its order is deliberate.**
   - It sits directly before your newest action, the most influential spot in the prompt. Latitude recommends keeping it to 3 or 4 sentences, because long notes there hurt coherence.
   - It carries only what drifts fastest: dialogue voice, fight style and lean narration.
   - It ends on attribution, so "every action and line is clearly attributed" is the last instruction the model reads before your action.
   - Its dialogue line is scoped to NPCs, so asking for lots of dialogue doesn't invite the AI to write your lines.
7. **Mature content is allowed but never pushed.** It sits in the instructions, limited by "where the story leads." It is not in the Author's Note, where it would be read right before your action on every turn.

### What changed from the previous (v51) pair

| Problem in v51 | Fix here |
|---|---|
| "Preserve identity, speaker, referent, ownership, location, posture, grip, readied gear…" is a 13-item list. It says what to care about, not how. | Concrete rules: one speaker per paragraph, names instead of ambiguous pronouns, never swap actions, speech, items or wounds |
| Never mentions the `>` input lines or World Lore | Both named explicitly |
| No rule that someone matching a card *is* that character. A card character who shows up by title alone ("the watch captain") can be treated as a new person and given a new name. | "Anyone matching an established character is that character" |
| "Established means" is the only allowance for special knowledge | Role and power named explicitly, plus a telepathy exception for private thoughts |
| Rules overfitted to single test failures ("Preserve stated geometry; insert no extra obstacle or collision", "surroundings take remaining force") | Removed. The general continuity and scaling rules cover these cases. |
| No perspective limit, so narration drifted into NPCs' heads | "Narrate only what the player's character perceives" |
| Author's Note: 847 characters in three paragraphs, sex and gore words read every turn, ending on "leave the next voluntary choice to the player" | 529 characters in one paragraph, ending on attribution. Mature content moved to the conditional instruction line. |
| "Fit diction … to setting" fought your "sometimes modern" dialogue | Dropped. Dialogue is "casual, sometimes modern-sounding." |

The size is about the same: 381 Llama-3 tokens in total, versus 405 before. That's roughly a tenth of a 4k free-tier context.

## 3. Where each of your preferences lives

| Your preference | Covered by |
|---|---|
| Second person, present tense for you; NPCs in third person | Instructions, line 1 |
| The AI never speaks, chooses, thinks or feels for you | Line 2 |
| Your input carried out exactly ("once", "don't", counts) | Line 2 |
| The outcome is finished, then control returns to you | Line 2 |
| Who did what and who said what | Line 4, plus the Author's Note's last sentence |
| No perspective drift | Line 3 |
| Consistency with Story Cards and Plot Essentials | Line 5 |
| No merged identities or reused names | Lines 4 and 5 |
| NPCs don't know what they couldn't know | Line 6 |
| NPCs pursue their own goals | Line 6 |
| Consistency with what has happened | Lines 5 and 7 |
| Scaling ("a god punches him") | Line 8, plus the Author's Note |
| Fast, terse, dangerous fights | Author's Note |
| Lots of natural dialogue with range: comedy, irritation, casual, modern-sounding, tender | Author's Note |
| Less description | Author's Note ("lean … brief concrete details") |
| Tropes, bad luck, dreams | Author's Note |
| Mature content follows the story and is never forced | Line 9 |

## 4. Make your Story Cards and Plot Essentials do their part

No wording can make the AI obey a card it can't see, and on the free tier space is tight. These habits matter as much as the instructions do:

- **Put the name inside the Entry.** The AI sees only the Entry text, never the card's title.
- **Use every name the story calls them by as a trigger:** name, surname, nickname and title ("Brannoc, Hale, Captain, commander"). A card loads only when one of its triggers appears in the last few actions.
- **Give power a concrete line.** Scaling can only follow power that has been *established*. For example: "Power: divine; a casual punch kills a mortal."
- **Spell out what each character knows:** "Knows: … / Does not know: …"
- **Keep your own character in Plot Essentials, not a card.** Plot Essentials are always sent; cards are not.

Plot Essentials template:

```
You are [name], [one-line identity]. Power: [ordinary human / trained fighter / demigod...]; [what a full-strength blow from you does]. Carrying: [items and where]. Injuries: [current]. Secrets no one knows: [...].
```

Character card Entry template:

```
[Full name] ([aliases]): [gender, age, role]. Looks: [2-3 details]. Voice: [how they talk: blunt, swears, dry jokes...]. Power: [level + concrete example]. Wants: [goal]. Knows: [...]. Does not know: [...]. With you: [relationship].
```

## 5. Play habits that matter more than any wording

- **Fix errors immediately** with Retry or Edit. The rules tell the AI that the story so far is fact, so a misattributed line left in place becomes canon and gets copied forward.
- **Use Say for your speech and Do for your actions.** Both arrive as `>` lines, which is how the AI tells you apart from everyone else.
- **Use Story mode when you want something to *happen*,** such as an NPC's move or a scene cut. The AI treats it as fact, not as your attempt.
- **In long adventures,** turn on the Memory System and keep Plot Essentials current (injuries, who holds the key).

## 6. Limits

- Dynamic Large switches between several models, so how well it follows the rules varies from one generation to the next. Expect an occasional miss, and Retry it.
- If a card isn't triggered, or an event has scrolled out of context, the AI can't use it. See section 4.
- **This version has not been run live yet.** The environment it was built in blocks aidungeon.com and huggingface.co. `TEST_KIT.md` is a ready-made 8-action test you can run in your own game.

## 7. Optional tweaks

- **Want the AI to describe your character's emotions?** In line 2, change "Never write the player's words, choices, thoughts or emotions." to "Never write the player's words, choices or thoughts."
- **Per-story genre or tone:** add one short sentence at the **start** of the Author's Note (for example, "Grimdark border fantasy."). Keep the rest, and keep the attribution sentence last.

## Sources

- [What goes into the Context sent to the AI?](https://help.aidungeon.com/faq/what-goes-into-the-context-sent-to-the-ai)
- [How are AI responses generated?](https://help.aidungeon.com/faq/how-are-ai-responses-generated) (context order; instructions sent as the system prompt)
- [What is Author's Note?](https://help.aidungeon.com/faq/what-is-the-authors-note) (square brackets; placed just before your last action; 3 or 4 sentences)
- [What is AI Instructions?](https://help.aidungeon.com/faq/ai-instructions)
- [AI Models and their Differences](https://help.aidungeon.com/ai-model-differences) (Dynamic Large example instructions and response length 150; Wayfarer Large notes on `>` inputs and avoiding "dungeon master" wording)
- [What are Story Cards?](https://help.aidungeon.com/faq/story-cards) (trigger scanning)
- [What are Plot Components?](https://help.aidungeon.com/faq/plot-components) (Third Person component)
- [AI Dungeon Story Cards (2026)](https://arcanumrpgs.com/blog/ai-dungeon-story-cards/) (the `World Lore:` header; the AI sees the Entry, never the card title)
- [Memberships & Benefits](https://help.aidungeon.com/memberships-benefits) (context size by tier)
- [What's New](https://play.aidungeon.com/whats-new) (reusable AI Instruction sets)
