"""Words the art tools draw into pictures, in every language there is a translation into, GAME.md 10.9.

A tool marks each word it draws with _(), as gettext's own tools do, which `make strings` reads into
the template with the game's words. It draws its picture once in English, and again as
<name>.<locale>.png beside it for each language whose file translates any of the picture's words;
`remap()` lists those in the project's translation remaps, so the engine loads the picture in the
language spoken instead.
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import strings  # noqa: E402

PROJECT = os.path.join(strings.ROOT, "project.godot")


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


def res(path):
    return "res://" + os.path.relpath(path, strings.ROOT).replace(os.sep, "/")


def remap(original, variants):
    """Lists [variants], {locale: path}, as [original]'s pictures in those languages in the
    project's translation remaps, and nothing else for it."""
    with open(PROJECT, encoding="utf-8") as f:
        text = f.read()
    block = re.search(r"^locale/translation_remaps=\{\n(.*?)^\}\n", text, re.M | re.S)
    remaps = {}
    if block:
        for m in re.finditer(r'^"([^"]+)": PackedStringArray\((.*)\)$', block.group(1), re.M):
            remaps[m.group(1)] = re.findall(r'"([^"]+)"', m.group(2))
    if variants:
        remaps[res(original)] = [
            "%s:%s" % (res(path), locale) for locale, path in sorted(variants.items())
        ]
    else:
        remaps.pop(res(original), None)
    lines = [
        '"%s": PackedStringArray(%s)' % (key, ", ".join('"%s"' % v for v in remaps[key]))
        for key in sorted(remaps)
    ]
    wanted = "locale/translation_remaps={\n%s\n}\n" % ",\n".join(lines) if lines else ""
    if block:
        text = text[: block.start()] + wanted + text[block.end() :]
    elif wanted:
        anchor = re.search(r"^locale/translations=.*\n", text, re.M)
        at = anchor.end() if anchor else text.index("[internationalization]\n") + 24
        text = text[:at] + wanted + text[at:]
    with open(PROJECT, "w", encoding="utf-8") as f:
        f.write(text)
