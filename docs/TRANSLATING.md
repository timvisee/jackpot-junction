# Translating Jackpot Junction

Jackpot Junction is written in English and can be played in any language there is a translation
into. Translations are plain [gettext](https://www.gnu.org/software/gettext/) files, so any tool
that edits `.po` files works: [Poedit](https://poedit.net/), [Weblate](https://weblate.org/),
Crowdin, Transifex, or a text editor. How the game handles languages is described in
[GAME.md 10.9](GAME.md).

## The files

- `data/locale/jackpot_junction.pot`: the template, every word the game shows, in English.
- `data/locale/<locale>.po`: one file per language, named by its locale: `nl.po` for Dutch,
  `de.po` for German, `pt_BR.po` for Brazilian Portuguese, `zh_CN.po` for Simplified Chinese.

Each entry says where its words show (`#:`, the source file), and some carry a note for
translators (`#.`): read them, they say what the words are for and how much room they have.

## Starting a language

```sh
python3 tools/strings.py add <locale>
```

This makes `data/locale/<locale>.po` with every entry empty and lists it in `project.godot`. Then
add the language to `NAMES` in `scripts/lang.gd`, named in its own language ("Deutsch", not
"German"), and to `STEAM_NAMES` by Steam's name for it, so the settings offer it and Steam players
get it automatically. Or open an issue, and we'll set it up.

Languages written in another script, such as Chinese, Japanese, Korean, Arabic or Thai, also need
typefaces that have it: none of the game's do yet. Open an issue before starting one.

## The rules

A translation that breaks one of these shows wrongly, or not at all, and `make strings-check`
fails on it:

- **Placeholders** stay as they are. `{name}`, `{count}` and the like may move within the sentence,
  but keep their names. `%d`, `%s` and `%.1f` must stay **in the same order** as the English; if
  your language needs another order, rephrase. A plural's singular form keeps its `%d` too.
- **The lessons' words.** In the driving school's lines a game word in braces, `{chips}` or
  `{Royal Flush}`, is drawn in its color. Translate the word inside the braces, using the same
  translation as the word's own entry (`chips` and the like, noted as the lessons' words), or it is
  drawn plain.
- **Markup** such as `[b]`, `[/b]` or `[color=#ffd700]` stays, with every tag the English has.
- **Line breaks** (`\n`) stay roughly where the English has them.

And to fit the game:

- **Room is tight.** HUD words, buttons, tabs, stamps and signs have about the length of the
  English. Prefer the shorter natural word.
- **Capitals** stay capitals: the House prints in them. Sentence case stays sentence case.
- **Contexts.** An entry with a `msgctxt` is one English word with more than one meaning: the
  context says which.
- **Numbers.** Three entries set how numbers are written: context `thousands` (English `,`),
  context `decimal` (English `.`) and context `list` (English `, `, between items of a list).
  Places such as 1ST and 2ND are the context `ordinal` entries.
- **Names** stay as they are: Jackpot Junction, Steam, people's names, K. (who signs the notes),
  and the buttons of a controller.
- **Fuzzy** entries, the ones a tool marks as needing review, are not shown in the game. Clear the
  flag once the translation is right.

## The voice

The game is a casino. The House, its management, speaks in a dry, polite, faintly ominous
corporate voice: memos, stamps, small print and billboards full of puns. K., a driver, leaves
handwritten notes. Translate the joke rather than the words, and keep the deadpan.

## Trying it

Pick the language on the Accessibility page of the settings, or leave it on Automatic, which
follows the language Steam has the game in, or else your system's.

## When the game changes

`make strings` brings the template and every `.po` file up to the code. New words arrive as empty
entries; a translation whose English is gone is kept at the end of the file (`#~`), and comes back
marked fuzzy if the English returns. Translators' comments and a tool's header fields are kept.

Words drawn into pictures, the House rail's microprint and Kit's chalkboard, are in the template
too. After translating them, run `python3 tools/make_house_prints.py` and
`python3 tools/make_workbench_prints.py` to draw that language's pictures (they need Pillow and
numpy).

Some words are Steam's too: the names Steam shows for the game's controls in its controller
settings, what the friends list says a player is doing, and the achievements' names and objectives
on Steam, which are the game's own. They are in the template as the rest are; `make steam-input`,
`make steam-presence` and `make steam-achievement-art` write them into Steam's files in every
language that translates them.

## Notes per language

### Dutch (`nl`)

Informal: *je* and *jij*, never *u*, the House included. Common English game words stay
(map, kart, joker, power-up, boost, drift, nitro, jackpot, host, lobby). The terms used:

| English | Dutch |
|---|---|
| the House | het Huis |
| chip(s) | fiche(s) |
| cash out / cash-out | verzilveren / verzilvering |
| payout slip | uitbetalingsbon |
| room (an arena's theme) | zaal |
| table | tafel |
| lap, round | ronde |
| overtime | verlenging |
| suit(s) | kleur(en) |
| Four of a Kind / Two Pair | Carré / Twee paar |
| bounty | premie |
| pit | kuil |
| license / driving school / driving test | rijbewijs / rijschool / rijexamen |
| Highway Code | Verkeersreglement |
| endorsement | aantekening |
| loyalty program / loyalty card | loyaliteitsprogramma / klantenkaart |
| achievement | prestatie |
| note(s), K.'s | briefje(s) |
| Human Oversight | Menselijk Toezicht |
