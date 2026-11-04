# Sælliv 🦭

En blid vane-tracker med en sæl som virtuelt kæledyr. Alt er lokalt på telefonen – ingen konto, ingen server, ingen iCloud.

## Hent appen

Hver gang der pushes til `main`, bygger GitHub Actions en usigneret `.ipa` og lægger den i releasen **latest**:

**https://github.com/Thyxo/Seal-Life/releases/tag/latest** → `SealLife.ipa`

## Installér med AltStore eller SideStore

Du skal bruge et gratis Apple ID.

1. Installér **AltStore** (altstore.io) eller **SideStore** (sidestore.io) på din iPhone, hvis du ikke har det. Følg deres egen guide.
2. Åbn linket ovenfor i **Safari på iPhonen** og tryk på `SealLife.ipa` for at hente den. Den lander i **Filer → Overførsler**.
3. Åbn AltStore/SideStore → fanen **My Apps** → tryk **+** øverst → vælg `SealLife.ipa`.
4. Log ind med dit Apple ID, hvis du bliver spurgt. Appen bliver signeret og installeret.
5. Første gang: **Indstillinger → Generelt → VPN og enhedsadministration** → stol på dit Apple ID, hvis iOS beder om det.
6. Widget: hold fingeren på hjemmeskærmen → **+** → søg efter **Sælliv**.

### Vigtigt: 7 dage

Apps installeret med et gratis Apple ID udløber efter **7 dage**. AltStore/SideStore kan forny dem automatisk (Refresh). Lav alligevel en backup jævnligt:

**Mig → Eksportér backup** → gem filen i Filer. Hvis appen nogensinde skal geninstalleres: **Mig → Importér backup**.

Sælen minder dig blidt om det én gang om ugen.

### Opdatér

Hent den nye `SealLife.ipa` fra releasen og installér den oven i den gamle via AltStore/SideStore (+). Data bliver liggende.

## Udvikling

- Swift + SwiftUI + SwiftData, iOS 17+, ingen tredjepartsbiblioteker.
- Xcode-projektet genereres med [XcodeGen](https://github.com/yonaskolb/XcodeGen) ud fra `project.yml` (`xcodegen generate`).
- `App/` – hovedappen · `Widget/` – widget + Live Activity · `Shared/` – kode der deles mellem dem.
- **Alle tal** (humør, grænser, fisk, priser, påmindelser) ligger i [`Shared/Tuning.swift`](Shared/Tuning.swift).
- App Group-ID'et læses ved runtime (AltStore/SideStore omskriver det ved signering).
- Billeder: se [`ASSETS.md`](ASSETS.md). Læg dem i `Assets/Incoming/`, så bruges de automatisk.
