# The store page in Dutch

The Dutch for everything [STEAM.md](../STEAM.md) has the store page say in words, "Words for the
store page" and the supporter pack's "Words for its store page", in the game's own terms
([TRANSLATING.md](../TRANSLATING.md), Dutch): informal *je*, *het Huis*, *fiches*, *verzilveren*.
Steam shows each visitor the page in the language their Steam is in, and English where a part has
none, so the English stays as it is. When the English changes, this changes with it.

Everything the game hands Steam itself, the friends list's words, the achievements and the
controller actions, comes from the game's translations, see STEAM.md.

## Putting it up

1. **Supported languages** (Edit Store Page > Basic Info): add Dutch with Interface ticked, not Full
   Audio, not Subtitles, as nothing is voiced.
2. **The words** (Edit Store Page, each tab with words): pick Dutch in the language menu at the top
   and fill in the fields below, then save. A field left empty in Dutch shows the English.
3. **The description's pictures**: `make steam-art` draws the ones with words in them in Dutch, into
   `build/steam-art/description/dutch/` and `docs/description/dutch/`, each named for the
   language, `heading_your_ride_dutch.png`, so it goes up beside the English instead of over it.
   With the Dutch description open, upload them with the editor's image button as the English ones
   were. The karts have no words: the Dutch description shows the English picture.
4. **The screenshots**: `make steam-art` also takes them in Dutch, into
   `build/steam-art/screenshots/dutch/`, `01-teams-close-up_dutch.png` and on. On the screenshots
   page, drag each onto the thumbnail of the English one with its number: Steam keeps it as that
   screenshot's Dutch version, which the `_dutch` in its name tells it. Mark each suitable for all
   ages, as the English ones are.
5. **The trailer**, if wanted: `make trailer LANGUAGE=nl` records it in Dutch into
   `build/trailer/dutch/`, see STEAM.md "The trailer". Upload `jackpot-junction-trailer.mp4` from
   there as a trailer of its own and set its language to Dutch, so Dutch visitors see it in place
   of the English one.
6. Publish the store page. The capsules and the library's art have no words but the game's name,
   which stays, and Steam has no Dutch version of them.

## Short description

> Een kartarena van bovenaf waarin elk leven een hand kaarten is. Raap fiches op, schakel de andere
> karts uit, buig de regels met jokers en verzilver bij de Junction voordat iemand jou te grazen
> neemt. Met z'n vieren op één scherm, met z'n achten online.

## About This Game

The pictures, with their alt text in the Description tab:

| Picture | Alt text |
|---|---|
| `heading_how_the_cards_roll_dutch.png` | Zo liggen de kaarten |
| `heading_whats_in_the_deck_dutch.png` | Wat zit er in het deck, vraag je? |
| `picture_jokers_dutch.png` | Een hand van vijf jokers: Valse stenen, Effectbal, Zakkenroller, Beschermengel en Wildcard |
| `picture_power_ups_dutch.png` | Een hand van vijf power-ups: Raket, Schild, Bom, Geschutstoren en Lokkart |
| `heading_never_play_alone_dutch.png` | Je speelt nooit alleen kaart. Of toch? |
| `heading_your_ride_dutch.png` | Jouw kart, jouw stijl |
| `picture_karts.png`, the English one | Vijf karts op een rij, elk met een eigen model, lak en hoed |

```text
[b]Zei iemand chaos?[/b] Drift, ontwijk kogels en graai pokerfiches bij elkaar alsof je huur ervan afhangt, terwijl je probeert niet als verkeersslachtoffer te eindigen. Haal je rijbewijs, spring in je opgevoerde kart en daag tot zeven vrienden uit: wie strijkt de grootste buit op? Ga je eraan voordat je verzilvert, dan ben je je winst kwijt. Makkelijk, toch? Ja hoor, veel succes ermee.

[img]{STEAM_APP_IMAGE}/extras/heading_how_the_cards_roll_dutch.png[/img]
[list]
[*][b]Verzamel[/b] fiches van de pads, uit kratten, van de Jackpot en van de karts die je uitschakelt. Elke fiche gaat in je pot.
[*][b]Vermenigvuldig[/b] door je medekarts uit te schakelen. Je pot is zijn fiches maal zijn mult waard.
[*][b]Buig de regels[/b] met jokers die het spel op zijn kop zetten. Ga onderuit en heb geluk, of word vervloekt... wie zal het zeggen.
[*][b]Verzilver[/b] door je kart op de Junction te rijden. Ga je onderweg dood, dan ben je al je harde werk kwijt.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_whats_in_the_deck_dutch.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_jokers_dutch.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_power_ups_dutch.png[/img]
[list]
[*]Casinotafels zijn je arena. Drift om obstakels heen, val in kuilen en verzamel pokerfiches om te winnen.
[*]48 jokers. Denk aan effectballen, driftende fiches, stuiterende kogels en zakkenrollen. Je krijgt 27 jokers van het Huis en wint de rest onderweg.
[*]21 power-ups. Schilden, bommen, geschutstorens, lokkarts, olievlekken en meer om de kart van je vriend dwars te zitten alsof je leven ervan afhangt (dat doet het ook).
[*]Eén minuut of de hele santenkraam: er zijn snelle matches en Grand Prix-reeksen over meerdere maps. Elke kart voor zich, of in teams die samen één score binnenhalen.
[*]Je eigen kart, helemaal naar jouw smaak. Van haaienvinhoeden tot confettisliertjes en een kenteken met je naam erop.
[*]Loyaliteit loont. Je wegenkaart vol weddenschappen levert aankleding voor je kart op, of kaarten voor je jokerdeck.
[*]Nieuw hier? We leiden je rond. Haal je rijbewijs op de rijschool en oefen je driftkunsten in de garage.
[*]Onderweg loopt een verhaal waarmee je je kart en je kaarten verder verbetert. Zet het gerust uit als het je ophoudt.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_never_play_alone_dutch.png[/img]
[list]
[*][b]Eén scherm?[/b] Ga de weg op met tot vier vrienden, die meedoen wanneer ze willen. Ja, zelfs midden in een match.
[*][b]Aan het LAN-nen?[/b] Host je eigen spel en nodig je vrienden uit, op jouw manier.
[*][b]Online spelen?[/b] Start een spel op een dedicated server of doe mee met een bestaand spel, met tot acht roekeloze coureurs.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_your_ride_dutch.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_karts.png[/img]
Of je nu niet onder de indruk bent van het discopubliek langs de kant, of speelt met die ene vriend die richthulp nodig heeft: je stemt het spel af op wat jij nodig hebt.

Jackpot Junction is open source, onder de GPL-3.0, gemaakt met Godot. De eigen art valt onder CC BY 4.0.
```

## System requirements

The additional notes, where Steamworks takes them per language; the rest of the table is the
English, with numbers and names that need no translating.

> Een internetverbinding is alleen nodig om online te spelen; alleen tegen bots, lokaal en via LAN
> werkt het spel offline. Tot 4 spelers op één scherm met controllers, tot 8 online. Verlaag op
> geïntegreerde graphics de renderschaal en de schaduwen in de Instellingen.

## Content and legal

Where Steamworks takes them per language.

- **AI disclosure**: "Dit spel is gebouwd met generatieve AI, met wat hulp van een mens. AI schreef
  de code en de teksten in het spel, en de art wordt door die code getekend, dus er zijn geen
  beeld-, stem- of muziekgeneratoren gebruikt. De muziek, de geluidseffecten en de lettertypen zijn
  door mensen gemaakt."
- **Legal notice**: "Jackpot Junction is vrije software onder de GPL-3.0, met een extra
  toestemming om de Steamworks SDK te linken. De eigen art valt onder CC BY 4.0. Muziek door Ovani
  Sound, in licentie gegeven aan de ontwikkelaar van het spel. Assets van derden staan in de
  credits van het spel."

## The supporter pack

The DLC's own store page, in its own Edit Store Page, as the game's above: Dutch under Supported
languages, the words below with Dutch picked, its two headings from
`docs/description/supporter/dutch/` and its three screenshots from
`build/steam-art/supporter/screenshots/dutch/`, each dragged onto its English one.

**Its name**: under the DLC's General Application Settings (Steamworks Settings), Localized
Application Names, Dutch: `Jackpot Junction - Supporterspakket`, the pack's name in the game.

Short description:

> Een klein bedankje voor een gratis spel. Elf stukken kartaankleding die gloeien, draaien en
> reageren op je pot, drie kaartruggen en een ster voor je kenteken. Niets waarmee je een match
> wint: gewoon een manier om te laten zien dat je een duit in het zakje hebt gedaan.

The pictures, with their alt text:

| Picture | Alt text |
|---|---|
| `heading_supporter_thanks_dutch.png` | Een bedankje om te dragen |
| `picture_supporter_karts.png`, the English one | Vijf karts met het kaartenhuis, de gelukskat, de vuurtoren met zijn lichtbundel, het aureool en de fooienpot, met lantaarns, windmolentjes en de nachthemellak |
| `heading_supporter_pieces_dutch.png` | Alles in het pakket |
| `picture_supporter_backs.png`, the English one | Een hand van drie kaarten met de kaartruggen Baken, Sterrenbeeld en Noorderlicht |

About This Content:

```text
Jackpot Junction is gratis, en blijft gratis. Het Supporterspakket is voor wie graag iets terug wil doen, en dat aan tafel wil laten zien.

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_thanks_dutch.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_karts.png[/img]
Elk stuk gloeit, draait of reageert op je pot, zodat de tafel ziet wie een duit in het zakje heeft gedaan. Een kaartenhuis dat met je pot meegroeit en instort als jij eraan gaat, een gelukskat die sneller wenkt na fiches, een vuurtoren die over het vilt zwaait.

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_pieces_dutch.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_backs.png[/img]
[list]
[*][b]Vuurtoren[/b] (hoed): de lamp draait en zwaait een zachte lichtbundel over het vilt.
[*][b]Aureool[/b] (hoed): een ring van warm licht boven je helm.
[*][b]Kaartenhuis[/b] (hoed): een verdieping erbij als je pot groeit; het wiebelt als je rijdt en stort in als jij eraan gaat.
[*][b]Gelukskat[/b] (hoed): wenkt, sneller nadat je fiches oppakt, en juicht als je verzilvert.
[*][b]Fooienpot[/b] (hoed): vult zich met fiches naarmate je pot groeit.
[*][b]Lantaarn[/b] (vlag): een papieren lantaarn die in jouw kleur gloeit.
[*][b]Windmolentje[/b] (vlag): draait mee met je snelheid.
[*][b]Prisma[/b] (sliert): een lint van licht dat in een drift regenboogbogen achterlaat.
[*][b]Sterrenstof[/b] (sliert): fonkelingen die blijven hangen waar je bent geweest.
[*][b]Nachthemel[/b] (lak): jouw kleur als een sterrenhemel.
[*][b]Sterrenlicht[/b] (afwerking): zwevende sterren, voor elk stuk dat je draagt.
[*][b]Baken[/b], [b]Sterrenbeeld[/b] en [b]Noorderlicht[/b] (kaartruggen) voor je jokerdeck.
[*][b]Een ster[/b] voor je kenteken en een [b]Supporter[/b]-aantekening op je rijbewijs.
[/list]

Alles erin is voor de sier. Het verandert niets aan hoe een match gespeeld of gewonnen wordt, en elke joker, power-up en arena blijft gratis voor iedereen.
```
