# AI Dungeon instruction set (Dynamic Large, second person)

Built against your 14-point brief. The AI Instructions are 1,299 of your 1,300 characters. The Author's Note is short and universal.

## 1. Paste these

**AI Instructions** (`AI_INSTRUCTIONS.txt`)

```
"You" is the player's character, in present tense; everyone else is third person.
Resolve each > line (player input) exactly as attempted, then stop where the player can act. Only the player decides what you say, do, think or intend.
Narrate only what the player's character perceives. Others know only what they saw, heard or could know by role or power.
Make who acts, speaks and is meant unmistakable: one speaker per paragraph, names over unclear pronouns. Actions, lines, items and wounds keep their owners.
World Lore, Plot Essentials and past events are fact until the story changes them. Anyone matching an established character is that character; newcomers get names not yet in use.
Readiness, injuries, fatigue, lingering sensations and damage carry forward and shape what follows; choices have lasting consequences.
Damage, distance thrown and destruction scale with the established power behind each blow.
When a fight happens, it's fast and clear: each exchange shows who moves where and what connects, flowing into the next, terrain used and broken.
The world moves on its own, with good and bad luck. Agendas, moods and history drive real emotion and shifting tone, humor included; language fits the setting.
Mature content of any kind is allowed where characters and situations lead.
```

**Author's Note** (`AUTHORS_NOTE.txt`)

```
Dialogue and action lead; narration stays brief. NPCs talk like real people: natural, modern-feeling rhythm and social cues, in words that fit the setting, each voice grounded in who they are and what just happened. Every action and line is clearly attributed.
```

**Settings:**

- Model: Dynamic Large.
- Response length: 150. That's Latitude's recommendation for Dynamic Large; longer outputs give the AI room to run past your turn.
- Third Person plot component: off.
- Save the instructions as a reusable set from the AI Instructions dropdown, so scenarios don't replace them.

## 2. How it's built

What the AI receives each turn, in order:

1. Your AI Instructions, as the system prompt
2. Plot Essentials
3. Story Cards, under `World Lore:`
4. Story Summary and memories
5. Recent story
6. The Author's Note, in square brackets
7. Your newest action

Your Do and Say inputs appear as lines starting with `>`. Every choice below follows from that layout and from your point 12.

- **Principles, not lists (point 12).** Latitude's own guidance confirms your suspicion: whatever the instructions mention gets primed. So there are no personality types, mood lists or theme lists. Instead of naming comedy, tropes or gore, the instructions describe the *source* of variety: a world that moves on its own, luck in both directions, and emotion driven by agendas, moods and history. Variety then comes from the story rather than from a menu.
- **None of your examples copied (point 4).** There are no blades, vomit or "hundreds of feet." The instructions state the general rules those examples are instances of:
  - readiness, injuries, fatigue and lingering sensations carry forward and shape what follows
  - damage, distance thrown and destruction scale with established power
- **No category headers.** A "Combat:" heading raises combat's weight in every story, including ones that shouldn't have any (point 9). Plain lines keep every rule equal, and the fight line is conditional: "When a fight happens."
- **Mature content in one neutral line (points 13–14).** There is no "sex" keyword and no talk of "balance" or "care," which you've seen make stories revolve around it. The line grants permission and names the trigger: characters and situations.
- **Words that would leak are avoided.** Instruction vocabulary shows up in the prose, so there are no style adjectives like brutal, visceral or gritty. There's also no "beat," which the AI already overuses as "a beat passes."
- **"You" means one thing only.** The instructions never address the AI as "you." In every line, "you" means the player's character, which removes one source of perspective mix-ups.
- **The Author's Note carries only what every story needs:**
  - dialogue and action first
  - human-sounding speech
  - attribution
  It is read right before every action. Anything else in it, such as fights, sex or a list of moods, would be pushed into every scene. It ends on "Every action and line is clearly attributed," which is the last instruction before your input.

## 3. Your 14 points, line by line

Lines are numbered as they appear in the AI Instructions (1–10); AN = Author's Note.

| # | Point | Where it lives |
|---|---|---|
| 1 | All themes, a real active world, long-term consequences | Line 9 (world moves on its own, good and bad luck, shifting tone); line 6 (lasting consequences); line 10 |
| 2 | Who knows what; who is acting, speaking, being referred to | Lines 1, 3, 4; AN's last sentence |
| 3 | Combat choreography, consistency, impact | Line 8 (who moves where, what connects); line 4 (ownership); lines 6–7 |
| 4 | Chains of logic and consequence; strength scaling | Line 6 (readiness, injuries, fatigue, lingering sensations); line 7 (damage, distance, destruction) |
| 5 | No names shared with Story Cards | Line 5: newcomers get names not yet in use; card matches stay that character |
| 6 | Setting-appropriate language | Line 9; AN ("words that fit the setting") |
| 7 | Atmosphere not stagnant, humor | Line 9 |
| 8 | Human dialogue, social cues, real and contextual emotion, no forced personalities | Line 9 (emotion driven by agendas, moods, history); AN (rhythm, social cues, voices grounded in who they are and what just happened) |
| 9 | Fast, momentum-driven, scaled, environmental fights, only when the story calls for them | Line 8 (conditional), line 7; the per-story line below |
| 10–11 | Dialogue and action over description and prose | AN's first sentence |
| 12 | No priming | The whole design (section 2) |
| 13–14 | Sex, gore, swearing allowed, never pushed | Line 10 |

The baseline rules are lines 1, 2 and 5: second person, your control over your character, and Story Cards as canon.

## 4. Telling the AI what kind of story it is (point 9)

The AI can't tell whether a story should center on combat, romance or comedy unless it's told. Give each adventure one short line at the **start** of the Author's Note, and keep the rest as is. For example:

- `War story in a collapsing empire; fights are frequent.`
- `Small-town slice of life; violence is rare and shocking.`
- `Brothel-district noir; crude humor and sex are part of daily life.`

This line is the dial. The instructions stay neutral so they work for any story.

## 5. Make Story Cards and Plot Essentials do their part

- **Put the name inside the Entry.** The AI only sees the Entry text, never the card's title.
- **Triggers:** use every way the story refers to someone: name, surname, nickname, title.
- **Give power a concrete line** ("Strength: divine, far beyond any mortal"). Scaling follows *established* power.
- **Write knowledge explicitly:** "Knows: … / Does not know: …"
- **Keep your character in Plot Essentials.** Plot Essentials are always sent; cards only load when triggered.

Character card Entry template:

```
[Full name] ([aliases]): [gender, age, role]. Looks: [2-3 details]. Voice: [how they talk]. Power: [level + concrete example]. Wants: [goal]. Knows: [...]. Does not know: [...]. With you: [relationship].
```

## 6. Habits that matter as much as the wording

- **Fix mistakes right away** with Retry or Edit. The instructions make past events fact, so an error left in becomes canon.
- **Use Say for your speech and Do for your actions.** Both become `>` lines, which is how the AI tells you apart from everyone else.
- **Use Story mode** for things you want to simply happen.

## 7. Testing

This version hasn't been run live yet, and this Claude Code session has no browser access. `BROWSER_TEST_PROMPT.md` gives the Claude in Chrome side panel a ready-made test: it builds the `TEST_KIT.md` scene in your AI Dungeon tab, runs 8 inputs with 2 samples each, and copies everything back word for word. Paste the report into the Claude Code session to get a revised version and the next round.

## Sources

- [What goes into the Context sent to the AI?](https://help.aidungeon.com/faq/what-goes-into-the-context-sent-to-the-ai)
- [How are AI responses generated?](https://help.aidungeon.com/faq/how-are-ai-responses-generated)
- [What is Author's Note?](https://help.aidungeon.com/faq/what-is-the-authors-note)
- [What is AI Instructions?](https://help.aidungeon.com/faq/ai-instructions) (positive phrasing; mentioned things get primed)
- [AI Models and their Differences](https://help.aidungeon.com/ai-model-differences) (Dynamic Large, response length 150, `>` inputs)
- [What are Story Cards?](https://help.aidungeon.com/faq/story-cards)
- [AI Dungeon Story Cards (2026)](https://arcanumrpgs.com/blog/ai-dungeon-story-cards/) (`World Lore:` header; only the Entry is seen)
