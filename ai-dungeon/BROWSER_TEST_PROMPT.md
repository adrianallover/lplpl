# Round 1 prompt for the Claude in Chrome side panel

Open your AI Dungeon tab, open the Claude in Chrome side panel, and paste everything inside the code block below. When the side panel is done, paste its whole report back into the Claude Code session.

**Cost:** 16 Dynamic Large actions (8 inputs, 2 samples each). If you play on the free daily premium actions, change `SAMPLES: 2` to `SAMPLES: 1`.

````
You are operating my logged-in AI Dungeon tab to run a scripted test of an instruction set. You are only the hands. Set things up exactly as written, run the inputs, and copy the results verbatim. Do not grade, summarize, fix typos, or "improve" any text. Another assistant will analyze your report.

SAMPLES: 2

RULES
- Paste every text block exactly, character for character, including straight quotes. The text between the ---BEGIN--- and ---END--- markers is the content. The markers themselves are not.
- Never publish anything. Never change account, billing or subscription settings. Never touch my other adventures or scenarios.
- If you can't find a control or a field, stop and tell me what you see instead of guessing.
- If AI Dungeon says I'm out of premium or Dynamic Large actions, or switches the model away from Dynamic Large, stop immediately and report what you have so far.

STEP 1: BUILD THE TEST
Create a private (unpublished) scenario named "ID test - do not publish". If you can't make a scenario, a custom adventure is fine. Fill in:

1. AI Instructions:
---BEGIN---
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
---END---

2. Author's Note:
---BEGIN---
Dialogue and action lead; narration stays brief. NPCs talk like real people: natural, modern-feeling rhythm and social cues, in words that fit the setting, each voice grounded in who they are and what just happened. Every action and line is clearly attributed.
---END---

3. Plot Essentials:
---BEGIN---
You are Rook, an ordinary human sellsword with mortal strength. Your short sword is sheathed at your left hip. Your left ankle is badly sprained from a fall yesterday. Secret: three years ago you deserted the Ash Watch under another name; nobody in Grey Harrow knows.
---END---

4. Story Cards: create 5 cards, all of type Character. For each one, fill in Name, Triggers and Entry exactly.

Card 1
Name: Tamsin Vey
Triggers: Tamsin, Vey, medic
Entry:
---BEGIN---
Tamsin Vey: woman, 30s, field medic, cropped black hair, ink-stained fingers. Voice: sharp, swears constantly, secretly kind. Mortal. Can read surface thoughts, but only while touching someone's skin. Your oldest friend; knows your name, does not know you deserted the Ash Watch.
---END---

Card 2
Name: Odo Marsh
Triggers: Odo, Marsh, innkeeper, barkeep
Entry:
---BEGIN---
Odo Marsh: man, 50s, innkeeper of the Gutted Eel, bald, sweaty. Voice: nervous jokes, talks too much. Owes you twelve silver. Hiding a wounded smuggler in his cellar; tells no one.
---END---

Card 3
Name: Hesk
Triggers: Hesk, pickpocket, key
Entry:
---BEGIN---
Hesk: boy of 16, pickpocket. Voice: cocky, fast, calls everyone "friend". Stole a brass key from the Ash Watch and keeps it on him. Has never met you and does not know your name.
---END---

Card 4
Name: Brannoc Hale
Triggers: Brannoc, Hale, Captain, commander, Watch
Entry:
---BEGIN---
Captain Brannoc Hale: man, 40s, commander of the Ash Watch in Grey Harrow. Scar across his left eye, grey beard. Voice: curt, dry humor, by the book. Has never met you. Hunting whoever stole the Watch's brass key.
---END---

Card 5
Name: Kur
Triggers: Kur, Red Fist, hearth, huge man
Entry:
---BEGIN---
Kur, the Red Fist: god of war wearing the shape of a huge, silent man. Strength: divine, far beyond any mortal. Ordinary steel cannot wound him. Speaks rarely; amused by courage.
---END---

5. Opening text (the story's first text):
---BEGIN---
Rain hammers the shutters of the Gutted Eel. You sit at the bar with Tamsin Vey on the stool to your right. Behind the bar, Odo Marsh polishes the same mug for the third time. In the corner, Hesk flips a brass key across his knuckles. A huge, silent man sits by the hearth, watching the fire. The door bangs open and Captain Brannoc Hale walks in with two Watch soldiers, rain streaming off their cloaks.
---END---

Start playing it. In the adventure's settings, confirm the AI model is Dynamic Large, Response Length is 150, and the Third Person plot component is off.

Then read every field back and confirm it matches the text above exactly. Write down the character count and any character limit or counter that the AI Instructions and Author's Note fields display.

STEP 2: RUN THE 8 INPUTS, IN ORDER
For each input:
1. Select the mode, type the input exactly, and submit.
2. Wait for the AI response to finish. Copy only the new AI-written text (not my input line) verbatim as Sample A.
3. If SAMPLES is 2: press Retry once, wait, and copy the new response verbatim as Sample B. Leave whatever is on screen in the story and go to the next input.

Input 1, Say mode: Evening, Captain. Long way from the barracks.
Input 2, Do mode: You think: Odo is hiding something in the cellar. You say nothing, rest your hand on your sword hilt, and sip your ale.
Input 3, Say mode: Hesk, toss that key to Odo before somebody gets hurt.
Input 4, Say mode: You. Green cloak. Name. Now.
Input 5, Do mode: You grip Tamsin's wrist and think: get ready to run.
Input 6, Do mode: You draw your sword and cut the lantern's rope above Brannoc's head with a single slash.
Input 7, Do mode: You sprint for the back door.
Input 8, Story mode: Kur rises from the hearth and punches the nearest Watch soldier in the chest.

STEP 3: CAPTURE THE RAW CONTEXT (once)
Right after Sample A of Input 1 appears, before pressing Retry, open AI Dungeon's View Context (the Context Viewer) for that response. Copy everything it shows, verbatim, including section names and token counts. Then continue with Step 2.

STEP 4: REPORT
Reply with one plain-text report in exactly this format and nothing else:

=== SETUP CHECK ===
Created as: (scenario / adventure)
Model: ... | Response length: ... | Third Person: ...
AI Instructions field: (character count shown, any limit shown, matches exactly? yes/no)
Author's Note field: (character count shown, any limit shown, matches exactly? yes/no)
Plot Essentials, 5 Story Cards, opening text match exactly? (yes/no, with details)

=== CONTEXT VIEW (Input 1, Sample A) ===
(verbatim)

=== INPUT 1 (Say) ===
Sample A:
(verbatim)
Sample B:
(verbatim)

(repeat for Inputs 2 to 8)

=== NOTES ===
(errors, warnings, model switches, running out of actions, which model generated each sample if AI Dungeon shows it, or anything you could not do)
````

**After each round:** I grade every sample against `TEST_KIT.md`, rewrite whatever failed (staying under 1,300 characters), and give you a short next-round prompt. That prompt swaps in the new wording, starts a fresh copy from the opening text, and reruns the same 8 inputs. We stop when every test passes in both samples.
