# Billeder til Sælliv

Appen virker allerede uden billeder (sælen, tilbehør og baggrunde er tegnet i kode).
Når du lægger billeder i `Assets/Incoming/` med **præcis de filnavne, der står herunder**, bruger appen dem automatisk i stedet for de kodede placeholders. Animationerne (vejrtrækning, hop, vippen, svømning osv.) bliver stadig lavet i kode oven på billederne.

## Rækkefølge

1. **Master-billedet** `seal_gray_content.png` – sælen forfra, neutral pose. Det er referencen for alt andet.
2. Humør-varianter af den grå sæl: glad, sulten, trist, syg, sover, ferie.
3. (Valgfrit) samme 7 varianter i brun og hvid pup.
4. Tilbehør (hatte, briller, hals).
5. Baggrunde/rum.
6. App-ikon.

Vedhæft altid i ChatGPT: dine egne sælbilleder (fx `References/Bedste billeder.png` og `References/Væreste billeder.png`) **og** det første master-billede, når det er lavet.

## Fælles stil (står også i hver prompt)

> Soft, cute, flat-pastel children's-book illustration. Rounded chubby shapes, no outlines or very soft outlines, gentle airbrushed shading, muted pastel palette (sea blue, ice grey, sand, warm cream). Kawaii but calm. No text, no watermark.

## Vigtigt om sælbillederne

- 1024 × 1024 px, **gennemsigtig PNG**.
- Sælen skal stå **midt i billedet**, med bunden af kroppen ca. 6 % fra den nederste kant og toppen af hovedet ca. 12 % fra den øverste kant. Øjnene ligger ca. 42 % nede. Så passer hatte og briller, der lægges ovenpå i koden.
- Ingen hat/briller/tilbehør på selve sælen (det lægges på i appen) – undtagen ferie-billedet, der gerne må have solbriller.
- Ingen skygge under sælen (den tegnes i koden).

---

## 1. Sælen (grå) – start her

| Filnavn | Størrelse | Gennemsigtig | Bruges |
|---|---|---|---|
| `seal_gray_content.png` | 1024×1024 | ja | **Master.** Tilfreds (humør 50–79), onboarding, widget |
| `seal_gray_happy.png` | 1024×1024 | ja | Glad (80+), historie-skærm, butik |
| `seal_gray_hungry.png` | 1024×1024 | ja | Sulten (25–49) |
| `seal_gray_sad.png` | 1024×1024 | ja | Trist (1–24) |
| `seal_gray_sick.png` | 1024×1024 | ja | Syg (0 i flere dage) |
| `seal_gray_sleeping.png` | 1024×1024 | ja | Om natten |
| `seal_gray_vacation.png` | 1024×1024 | ja | På ferie (widget) |

**`seal_gray_content.png` (MASTER)**
```
Using the attached seal images as character reference, create the master character sheet image of ONE cute baby harbor seal, front view, sitting upright, neutral content expression: small black dot eyes with a tiny white highlight, small dark nose, little "ω"-shaped smile, faint pink cheeks. Chubby egg-shaped body, light lavender-grey fur with soft darker grey spots on the head and back, pale cream-white belly and muzzle, darker grey front flippers resting at the sides and a small tail flipper peeking out on the right. Soft, cute, flat-pastel children's-book illustration, rounded chubby shapes, no outlines or very soft outlines, gentle airbrushed shading, muted pastel palette. Kawaii but calm. Centered in a 1024x1024 square, body bottom about 6% above the lower edge, top of head about 12% below the upper edge. Transparent background, no shadow, no accessories, no text, no watermark.
```

**`seal_gray_happy.png`**
```
Same seal character as the attached master image (identical proportions, colors, spots, size and position in the frame). Happy pose: eyes closed in happy upside-down "U" arcs, open little smile with a tiny pink tongue, flippers slightly raised as if clapping, rosy cheeks. Same soft flat-pastel children's-book style. 1024x1024, transparent background, no shadow, no accessories, no text.
```

**`seal_gray_hungry.png`**
```
Same seal character as the attached master image (identical proportions, colors and position). Hungry expression: big round hopeful eyes with highlights, small round open "o" mouth, one flipper on its round belly. Same soft flat-pastel style. 1024x1024, transparent background, no shadow, no text, no fish in the image.
```

**`seal_gray_sad.png`**
```
Same seal character as the attached master image (identical proportions, colors and position). Gently sad expression: slightly smaller eyes looking down, soft worried eyebrows, tiny downturned mouth, one small tear, flippers hanging low. Still cute and soft, not dramatic. Same soft flat-pastel style. 1024x1024, transparent background, no shadow, no text.
```

**`seal_gray_sick.png`**
```
Same seal character as the attached master image (identical proportions, colors and position). Feeling a bit sick: half-closed tired eyes drawn as short flat lines, slightly pale greenish tint on the face, tiny frown, wrapped in a small soft pastel-blue blanket around the lower body. Cute and cozy, not gross. Same soft flat-pastel style. 1024x1024, transparent background, no shadow, no text.
```

**`seal_gray_sleeping.png`**
```
Same seal character as the attached master image (identical colors and spots), now lying down asleep, but still filling the same area of the frame: eyes closed as gentle downward curves, peaceful little smile, flippers tucked in. Same soft flat-pastel style. 1024x1024, transparent background, no shadow, no "Zzz" letters (they are animated in the app), no text.
```

**`seal_gray_vacation.png`**
```
Same seal character as the attached master image (identical proportions, colors and position). Relaxed vacation mood: happy closed-eye smile, wearing small round black sunglasses, holding a tiny pastel drink with a paper umbrella in one flipper. Same soft flat-pastel style. 1024x1024, transparent background, no shadow, no text.
```

## 2. Andre farver (valgfrit)

Samme 7 filer, men `brown` / `white` i stedet for `gray`, fx `seal_brown_happy.png`, `seal_white_sleeping.png`. Mangler en fil, tegner appen den kodede sæl i den farve i stedet.

Brug prompten fra den grå variant og tilføj:
- **Brun:** `Recolor the seal: warm light caramel-brown fur with darker brown spots, cream belly and muzzle, darker brown flippers. Everything else identical.`
- **Hvid pup:** `Recolor the seal as a fluffy white newborn seal pup: soft creamy-white fluffy fur with almost no spots, very pale warm-grey flippers, slightly bigger eyes. Everything else identical.`

## 3. Tilbehør

512 × 512 px, **gennemsigtig PNG**, kun selve tingen, centreret, set forfra. Lægges ovenpå sælen i koden.

| Filnavn | Ting | Bruges |
|---|---|---|
| `acc_nissehue.png` | Nissehue (december) | Hat |
| `acc_pumpkin.png` | Lille græskarhat (oktober) | Hat |
| `acc_cap.png` | Kasket | Hat |
| `acc_flower.png` | Blomst til hovedet | Hat |
| `acc_bow.png` | Sløjfe | Hat |
| `acc_strawhat.png` | Stråhat | Hat |
| `acc_tophat.png` | Høj hat | Hat |
| `acc_crown.png` | Krone | Hat |
| `acc_sunglasses.png` | Solbriller | Briller |
| `acc_nerdglasses.png` | Runde læsebriller | Briller |
| `acc_goggles.png` | Svømmebriller | Briller |
| `acc_scarf_red.png` | Rødt halstørklæde | Hals |
| `acc_scarf_blue.png` | Blåt halstørklæde | Hals |
| `acc_bell.png` | Juleklokke i bånd (december) | Hals |
| `acc_lei.png` | Blomsterkrans | Hals |
| `acc_medal.png` | Medalje i bånd | Hals |

Prompt (skift `[ITEM]` ud):
```
Using the attached seal master image only as a style and scale reference, draw ONLY a single [ITEM] that would fit this seal, front view, centered, no seal in the picture. Soft, cute, flat-pastel children's-book illustration, rounded shapes, very soft outlines, gentle airbrushed shading, muted pastel colors that match the seal image. 512x512, transparent background, no shadow, no text.
```
Forslag til `[ITEM]`:
- nissehue: `small Danish Christmas elf hat (red with a white fluffy brim and white pompom, slightly floppy tip to the right)`
- pumpkin: `tiny pumpkin worn as a hat, pastel orange with a little green stem`
- cap: `small pastel sea-blue baseball cap, seen from the front`
- flower: `single big pastel pink flower hair clip`
- bow: `small pastel pink ribbon bow`
- strawhat: `small straw sun hat with a pastel blue ribbon`
- tophat: `small dark grey top hat with a sand-colored band`
- crown: `small soft golden crown with rounded points`
- sunglasses: `pair of round black sunglasses with a tiny white shine`
- nerdglasses: `pair of large round thin-framed reading glasses`
- goggles: `pair of pastel blue swimming goggles with strap`
- scarf_red: `short knitted pastel red scarf, wrapped as a band with one end hanging down on the right`
- scarf_blue: `short knitted pastel blue scarf, wrapped as a band with one end hanging down on the right`
- bell: `small golden Christmas bell on a red ribbon collar`
- lei: `Hawaiian flower garland in pastel pink, yellow and white, shown as a curved band`
- medal: `round golden medal on a pastel blue ribbon, shown as a short necklace`

## 4. Baggrunde / rum

1170 × 1400 px, **ikke gennemsigtig**, PNG. Ingen sæl i billedet. Hold den nederste tredjedel rolig (der står sælen), og lad toppen være enkel (der ligger navn, fisk og taleboble).

| Filnavn | Sted | Bruges |
|---|---|---|
| `bg_hule.png` | Hyggelig sælehule/rum (standard) | Hjem |
| `bg_ocean.png` | Åbent hav (sælen er på eventyr) | Hjem om dagen |
| `bg_isflage.png` | Isflage på havet | Butik + ferie |
| `bg_strand.png` | Amager Strand | Butik |
| `bg_undervand.png` | Under vandet | Butik |
| `bg_nyhavn.png` | Nyhavn | Butik |
| `bg_nordlys.png` | Nordlys over sne | Butik |

Prompt (skift `[SCENE]` ud):
```
Background illustration in the same style as the attached seal master image: soft, cute, flat-pastel children's-book illustration, rounded shapes, very soft outlines, gentle airbrushed shading, muted pastel palette (sea blue, ice grey, sand, warm cream). Scene: [SCENE]. Calm and cozy, simple shapes, low detail. Leave the lower-middle third fairly empty and flat (a character will be placed there) and keep the top area simple. No characters, no animals, no text. 1170x1400, full-bleed, not transparent.
```
Forslag til `[SCENE]`:
- hule: `a cozy round seal den inside an ice cave, round porthole window showing the sea, a warm hanging lamp, sandy floor with a soft round rug`
- ocean: `open calm sea seen from water level, soft waves in the lower half, pale sky, a few round clouds and a soft sun`
- isflage: `a large flat ice floe floating on a calm pastel sea, pale sky`
- strand: `Amager Strand beach in Copenhagen, soft sand in front, calm sea and a distant low bridge silhouette, a parasol on the side`
- undervand: `under the sea, soft light rays from above, swaying seaweed, sandy bottom, a few bubbles`
- nyhavn: `Nyhavn harbor in Copenhagen with colorful pastel townhouses along the canal and a small wooden boat, calm water in front`
- nordlys: `soft green and lavender northern lights over a snowy landscape at night, twinkling stars`

## 5. App-ikon

| Filnavn | Størrelse | Gennemsigtig | Bruges |
|---|---|---|---|
| `AppIcon.png` | 1024×1024 | **nej** | App-ikon på hjemmeskærmen |

```
App icon using the attached seal master image: the seal's face and upper body, big and centered, happy closed-eye smile, on a soft sea-blue to light-blue gradient background with one gentle wave at the bottom. Same soft flat-pastel children's-book style. Square 1024x1024, fully opaque background (no transparency), no rounded corners (iOS adds them), no text.
```

---

Når billederne ligger i `Assets/Incoming/`, så sig til – så forbinder jeg app-ikonet og tjekker, at alt sidder rigtigt.
