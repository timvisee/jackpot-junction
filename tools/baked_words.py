"""Words the art tools draw into pictures, in every language there is a translation into, GAME.md 10.9.

A tool marks each word it draws with _(), as gettext's own tools do, which `make strings` reads into
the template with the game's words. It draws its picture once in English, and again as
<name>.<locale>.png beside it for each language whose file translates any of the picture's words,
which the game's Lang.picture() shows instead in that language.

Pillow has no fallback fonts, so a tool draws words with text() and measures them with length():
a Chinese character in the face's Chinese partner, as the game draws it (Type.dress), and every
other letter in the face.
"""

import json
import os
import sys

from PIL import ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import strings  # noqa: E402


def _(text):
    """[text] as it is, marked as words for translators."""
    return text


def languages():
    """The locales there is a translation into."""
    return strings.languages()


def translator(locale):
    """A function that says English in [locale], or the English itself for a word it lacks."""
    path = os.path.join(strings.ROOT, strings.LOCALE, locale + ".po")
    with open(path, encoding="utf-8") as f:
        _, entries = strings.parse_po(f.read())
    said = {
        word: entry["strings"][0]
        for (context, word), entry in entries.items()
        if not context and not entry["fuzzy"] and not entry["obsolete"] and entry["strings"][0]
    }
    return lambda text: said.get(text, text)


def translates_any(locale, words):
    """Whether [locale]'s file has a word for any of [words]."""
    tr = translator(locale)
    return any(tr(word) != word for word in words)


PARTNERS = os.path.join(strings.ROOT, "assets", "fonts", "chinese")


def wide(character):
    """Whether [character] is one no face of the game's draws itself: Chinese and the scripts after
    it, which its partner draws."""
    return ord(character) >= 0x2E80


def partner(font):
    """[font]'s Chinese partner at its size, see tools/partner_fonts.py, or [font] itself."""
    with open(os.path.join(PARTNERS, "partners.json"), encoding="utf-8") as f:
        faces = json.load(f)["faces"]
    file = faces.get(os.path.basename(font.path))
    return ImageFont.truetype(os.path.join(PARTNERS, file), font.size) if file else font


def runs(said, font):
    """[said] in pieces, each with the font it is drawn in: [font], or its partner."""
    other = partner(font)
    pieces = []
    for character in said:
        face = other if wide(character) else font
        if pieces and pieces[-1][0] is face:
            pieces[-1][1] += character
        else:
            pieces.append([face, character])
    return pieces


def length(d, said, font):
    """How wide [said] is drawn in [font] on [d], its Chinese in the partner."""
    if not any(wide(c) for c in said):
        return d.textlength(said, font=font)
    return sum(d.textlength(piece, font=face) for face, piece in runs(said, font))


def text(d, xy, said, font, fill, anchor="la"):
    """Draws [said] on [d] at [xy] in [font] as ImageDraw.text does, its Chinese in the partner:
    every piece on the face's baseline, placed by [anchor] as the whole line."""
    if not any(wide(c) for c in said):
        d.text(xy, said, font=font, fill=fill, anchor=anchor)
        return
    across, up = anchor[0], anchor[1]
    x = xy[0] - {"l": 0.0, "m": 0.5, "r": 1.0}[across] * length(d, said, font)
    ascent, descent = font.getmetrics()
    y = xy[1] + {"a": ascent, "m": (ascent - descent) / 2, "s": 0, "d": -descent}[up]
    for face, piece in runs(said, font):
        d.text((x, y), piece, font=face, fill=fill, anchor="ls")
        x += d.textlength(piece, font=face)
