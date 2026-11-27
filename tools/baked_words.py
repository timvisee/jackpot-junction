"""Words the art tools draw into pictures, in every language there is a translation into, GAME.md 10.9.

A tool marks each word it draws with _(), as gettext's own tools do, which `make strings` reads into
the template with the game's words. It draws its picture once in English, and again as
<name>.<locale>.png beside it for each language whose file translates any of the picture's words,
which the game's Lang.picture() shows instead in that language.
"""

import os
import sys

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
