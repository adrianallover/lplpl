# In-game test kit: 8 actions on Dynamic Large

This checks the instruction pair on your own account. One small tavern scene covers:

- Attribution in a crowded room
- What NPCs can and can't know, and private thoughts
- Telepathy defined in a Story Card
- Handing an item from one character to another
- Exact action counts
- A god's punch landing on a mortal, and a mortal's sword against a god
- New characters reusing existing names
- The style rules

**Cost:** 8 Dynamic Large actions, plus one Retry for each failure if you want a second sample.

## Setup

1. Start a new custom adventure. Set Model to **Dynamic Large**, Response length to **150**, and turn Third Person **off**.
2. Paste the AI Instructions and the Author's Note from `README.md`.
3. **Plot Essentials:**

```
You are Rook, an ordinary human sellsword with mortal strength. Your short sword is sheathed at your left hip; a loaded crossbow lies on the bar beside your mug. Your left forearm is bandaged from a dog bite. Secret: three years ago you deserted the Ash Watch under another name; nobody in Grey Harrow knows.
```

4. **Story Cards:** create five Character cards.

| Card | Triggers | Entry |
|---|---|---|
| Tamsin Vey | `Tamsin, Vey, medic` | `Tamsin Vey: woman, 30s, field medic, cropped black hair, ink-stained fingers. Voice: sharp, swears constantly, secretly kind. Mortal. Can read surface thoughts, but only while touching someone's skin. Your oldest friend; knows your name, does not know you deserted the Ash Watch.` |
| Odo Marsh | `Odo, Marsh, innkeeper, barkeep` | `Odo Marsh: man, 50s, innkeeper of the Gutted Eel, bald, sweaty. Voice: nervous jokes, talks too much. Owes you twelve silver. Hiding a wounded smuggler in his cellar; tells no one.` |
| Hesk | `Hesk, pickpocket, key` | `Hesk: boy of 16, pickpocket. Voice: cocky, fast, calls everyone "friend". Stole a brass key from the Ash Watch and keeps it on him. Has never met you and does not know your name.` |
| Brannoc Hale | `Brannoc, Hale, Captain, commander, Watch` | `Captain Brannoc Hale: man, 40s, commander of the Ash Watch in Grey Harrow. Scar across his left eye, grey beard. Voice: curt, dry humor, by the book. Has never met you. Hunting whoever stole the Watch's brass key.` |
| Kur | `Kur, Red Fist, hearth, huge man` | `Kur, the Red Fist: god of war wearing the shape of a huge, silent man. Strength: divine, far beyond any mortal. Ordinary steel cannot wound him. Speaks rarely; amused by courage.` |

Kur's card deliberately doesn't say what his punch does. Test 6 checks whether the instructions alone scale it correctly.

5. **Opening text:**

```
Rain hammers the shutters of the Gutted Eel. You sit at the bar with Tamsin Vey on the stool to your right. Behind the bar, Odo Marsh polishes the same mug for the third time. In the corner, Hesk flips a brass key across his knuckles. A huge, silent man sits by the hearth, watching the fire. The door bangs open and Captain Brannoc Hale walks in with two Watch soldiers, rain streaming off their cloaks.
```

## The 8 inputs

Type each one exactly as shown, using the listed mode.

| # | Mode | Input | Passes if |
|---|---|---|---|
| 1 | Say | `Evening, Captain. Long way from the barracks.` | Brannoc matches his card (scar, curt). He doesn't know your name or your past. Every speaker is in their own paragraph and unmistakable. Speech sounds like people, not formal prose. |
| 2 | Do | `You think: Odo is hiding something in the cellar. You say nothing and sip your ale.` | Nobody reacts to the thought or brings up the cellar because of it. You say and do nothing more. |
| 3 | Say | `Hesk, toss that key to Odo before somebody gets hurt.` | By the end it's unambiguous who holds the key. Hesk sounds like his card (cocky, "friend"). Brannoc may react, since he can now see the key. |
| 4 | Do | `You grip Tamsin's wrist and think: get ready to run.` | Tamsin may respond to the thought, since her card allows it by touch. Nobody else knows what you thought. |
| 5 | Do | `You fire one crossbow bolt into the beam above Brannoc's head, then set the empty crossbow on the bar.` | Exactly one bolt is fired. The crossbow ends up on the bar, empty. The Watch responds like a real threat. You take no extra moves. |
| 6 | Story | `Kur rises from the hearth and punches the nearest Watch soldier in the chest.` | The soldier is launched, shattered or killed, never just staggered. Damage lands on things actually in the room, with no invented walls. Others react. |
| 7 | Do | `You draw your short sword and stab Kur in the back.` | The blade can't wound him, per his card. His response is lethal-level danger. Your bandaged forearm, the crossbow on the bar and everyone's positions stay consistent. The fight prose is short and fast. |
| 8 | Say | `You. Green cloak. Name. Now.` | Whoever answers has a new name. It must not be Tamsin, Vey, Odo, Marsh, Hesk, Brannoc, Hale, Kur or Rook. |

## Check every output for

- **G1:** Second person, present tense. You are never "I", "he/she" or "Rook" in the narration. NPCs may say your name in dialogue, but only if they know it.
- **G2:** The AI writes no words, decisions, thoughts or emotions for you.
- **G3:** One speaker per paragraph, and no "he" that could mean Odo, Hesk, Brannoc or Kur.
- **G4:** No NPC inner thoughts are narrated (for example "Odo wonders…" or "Brannoc feels…").
- **G5:** The prose is lean: no recaps, no repeated phrasing, short sentences in fights.
- **G6:** The output stops at a point where you can act.

## Scoring

For each input, mark Pass or Fail on its row, then on G1–G6. If anything fails, press Retry once and score that sample too, since Dynamic Large may have switched models. If both samples fail on the same point, the wording needs a fix. If only one fails, that's normal variation between models.

**Optional A/B test:** duplicate the adventure, paste your old v51 pair, and run the same 8 inputs.

**Report back:** send the failing output, the test number, and which check it broke.
