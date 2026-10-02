# In-game test kit: 8 actions on Dynamic Large

This checks the instruction pair on your own account. One tavern scene tests:

- Who's speaking and who's being referred to, in a room with three men
- What NPCs can and can't know, and private thoughts
- Story Card identity, new names, and telepathy that only works by touch
- Chains of logic: a hand already on the hilt, a sprained ankle
- Exact counts, and a god's punch landing on a mortal
- Dialogue, emotion and setting language
- Fast, clear fights

**Cost:** 8 Dynamic Large actions, or 16 with a second sample of each.

## Setup

1. Start a new custom adventure. Set Model to **Dynamic Large**, Response length to **150**, and turn Third Person **off**.
2. Paste the AI Instructions and the Author's Note from `README.md`.
3. **Plot Essentials:**

```
You are Rook, an ordinary human sellsword with mortal strength. Your short sword is sheathed at your left hip. Your left ankle is badly sprained from a fall yesterday. Secret: three years ago you deserted the Ash Watch under another name; nobody in Grey Harrow knows.
```

4. **Story Cards:** create five Character cards.

| Card | Triggers | Entry |
|---|---|---|
| Tamsin Vey | `Tamsin, Vey, medic` | `Tamsin Vey: woman, 30s, field medic, cropped black hair, ink-stained fingers. Voice: sharp, swears constantly, secretly kind. Mortal. Can read surface thoughts, but only while touching someone's skin. Your oldest friend; knows your name, does not know you deserted the Ash Watch.` |
| Odo Marsh | `Odo, Marsh, innkeeper, barkeep` | `Odo Marsh: man, 50s, innkeeper of the Gutted Eel, bald, sweaty. Voice: nervous jokes, talks too much. Owes you twelve silver. Hiding a wounded smuggler in his cellar; tells no one.` |
| Hesk | `Hesk, pickpocket, key` | `Hesk: boy of 16, pickpocket. Voice: cocky, fast, calls everyone "friend". Stole a brass key from the Ash Watch and keeps it on him. Has never met you and does not know your name.` |
| Brannoc Hale | `Brannoc, Hale, Captain, commander, Watch` | `Captain Brannoc Hale: man, 40s, commander of the Ash Watch in Grey Harrow. Scar across his left eye, grey beard. Voice: curt, dry humor, by the book. Has never met you. Hunting whoever stole the Watch's brass key.` |
| Kur | `Kur, Red Fist, hearth, huge man` | `Kur, the Red Fist: god of war wearing the shape of a huge, silent man. Strength: divine, far beyond any mortal. Ordinary steel cannot wound him. Speaks rarely; amused by courage.` |

Kur's card deliberately doesn't say what his punch does. Test 8 checks whether the scaling rule alone gets it right.

5. **Opening text:**

```
Rain hammers the shutters of the Gutted Eel. You sit at the bar with Tamsin Vey on the stool to your right. Behind the bar, Odo Marsh polishes the same mug for the third time. In the corner, Hesk flips a brass key across his knuckles. A huge, silent man sits by the hearth, watching the fire. The door bangs open and Captain Brannoc Hale walks in with two Watch soldiers, rain streaming off their cloaks.
```

## The 8 inputs

Type each one exactly as shown, using the listed mode.

| # | Mode | Input | Passes if |
|---|---|---|---|
| 1 | Say | `Evening, Captain. Long way from the barracks.` | Brannoc matches his card (scar, curt, dry). He doesn't know your name or your past. Each speaker has their own paragraph and is unmistakable. Speech sounds like real people, in words that fit the setting. |
| 2 | Do | `You think: Odo is hiding something in the cellar. You say nothing, rest your hand on your sword hilt, and sip your ale.` | Nobody reacts to the thought or brings up the cellar because of it. You say and do nothing more. |
| 3 | Say | `Hesk, toss that key to Odo before somebody gets hurt.` | By the end it's unambiguous who holds the key. Hesk sounds like his card. Brannoc may react, since he can now see the key. |
| 4 | Say | `You. Green cloak. Name. Now.` | Whoever answers has a name not used anywhere in the story or cards: not Tamsin, Vey, Odo, Marsh, Hesk, Brannoc, Hale, Kur or Rook. |
| 5 | Do | `You grip Tamsin's wrist and think: get ready to run.` | Tamsin may respond to the thought, since her card allows it by touch. Nobody else knows what you thought. |
| 6 | Do | `You draw your sword and cut the lantern's rope above Brannoc's head with a single slash.` | The draw is instant because your hand was already on the hilt (any fumbling fails). Exactly one slash. The falling lantern has consequences that follow from it. The Watch reacts as a real threat. You take no extra moves. |
| 7 | Do | `You sprint for the back door.` | The sprained ankle hampers the sprint: pain, a stumble, or a slower run. It isn't ignored. |
| 8 | Story | `Kur rises from the hearth and punches the nearest Watch soldier in the chest.` | The result matches divine strength: the soldier is thrown far, shattered or killed, never just staggered, and the damage lands on things actually in the room. The fight reads fast and clear: who moves where, what connects. |

## Check every output for

- **G1:** Second person, present tense. You are never "I", "he/she" or "Rook" in the narration. NPCs may say your name, but only if they know it.
- **G2:** The AI writes no words, actions, thoughts or intentions for you. Describing sensations and injuries is fine.
- **G3:** One speaker per paragraph, and no "he" that could mean Odo, Hesk, Brannoc or Kur.
- **G4:** No NPC inner thoughts are narrated. Emotions show through what NPCs say and do.
- **G5:** Dialogue and action lead. Description is brief, with no recaps.
- **G6:** Emotions fit each personality and the moment, with no out-of-character outbursts. Speech sounds natural. Nothing modern intrudes on the setting (gadgets, brands, modern slang).
- **G7:** The output stops at a point where you can act.

## Scoring

For each input, mark Pass or Fail on its row, then on G1–G7. If anything fails, press Retry once and score that sample too, since Dynamic Large may have switched models. If both samples fail on the same point, the wording needs a fix. If only one fails, that's normal variation between models.

**Report back:** send the failing output, the test number, and which check it broke.
