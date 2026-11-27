#!/usr/bin/env python3
"""The game's words for translators, GAME.md 10.9.

Every word a player reads is written in English in the code and marked for translation where it is
written: inside tr(), tr_n(), Lang.t(), Lang.tn() or Lang.later(), or in a table of words, a const
or var whose comment above says it is shown through tr(). This reads them all, with the words the
data resources hold (a joker's name, an achievement's objective), into a gettext template, and
merges that into each language's .po file, keeping every translation already made.

    tools/strings.py update          write the template and bring every .po file up to it
    tools/strings.py check           fail if either is behind the code, or if text is not marked
    tools/strings.py loose [PATH..]  list what looks like text and is not marked, by file and line
    tools/strings.py stats           how much of each language is translated
    tools/strings.py add LOCALE      start a language: an empty .po file for LOCALE

What looks like text is a guess: a string with a word in it and a space, a capital or a full stop.
One that is not text after all, a node's name or a key, is left as it is; one the guess still takes
for text is marked with a `# NO_TRANSLATE` comment at the end of its line, or in the comment above
the statement or table it is in. A `# TRANSLATORS:` comment above a statement is handed to the
translator with the words in it.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCES = ("scenes", "scripts")
# Tools for making the store's pictures and trailers, never shown to a player, stay English.
LEFT_OUT = ("scenes/dev/",)
DATA = "data"
LOCALE = os.path.join("data", "locale")
TEMPLATE = os.path.join(LOCALE, "jackpot_junction.pot")
# The fields of the data resources that hold words a player reads.
DATA_FIELDS = (
    "title",
    "display_name",
    "description",
    "objective",
    "bet",
    "dress",
    "kit_line",
    "kit_back",
    "endorsement",
)
PLURAL_FORMS = {
    "nl": "nplurals=2; plural=(n != 1);",
    "zh_CN": "nplurals=1; plural=0;",
}

# The calls that translate, by name, and which of their arguments are words and which a context.
CALLS = {
    "tr": ((0,), 1),
    "atr": ((0,), 1),
    "tr_n": ((0, 1), 3),
    "atr_n": ((0, 1), 3),
    "Lang.t": ((0,), 1),
    "Lang.tn": ((0, 1), 3),
    "Lang.later": ((0,), 1),
    "TranslationServer.translate": ((0,), 1),
    "TranslationServer.translate_plural": ((0, 1), 3),
}
# Calls whose strings are never shown to a player: the log, node paths, metadata, theme names,
# signals and methods by name, files, settings keys.
QUIET_CALLS = {
    "print", "prints", "printt", "printerr", "print_rich", "print_debug", "push_warning",
    "push_error", "assert", "get_node", "get_node_or_null", "has_node", "find_child",
    "find_children", "set_meta", "get_meta", "has_meta", "remove_meta", "connect", "disconnect",
    "is_connected", "emit_signal", "call", "call_deferred", "callv", "has_method", "set", "get",
    "set_deferred", "get_indexed", "set_indexed", "tween_property", "tween_method", "load",
    "preload", "get_value", "set_value", "has_section_key", "has_section", "get_section_keys",
    "erase_section_key", "get_environment", "has_environment", "set_environment", "has_feature",
    "Callable", "StringName", "NodePath", "get_setting", "set_setting", "has_setting",
    "has_signal", "add_user_signal", "is_action_pressed", "is_action_just_pressed",
    "is_action_just_released", "is_action_released", "get_action_strength", "is_action",
    "get_singleton", "has_singleton", "class_exists", "open", "file_exists", "dir_exists",
    "add_to_group", "is_in_group", "remove_from_group", "get_nodes_in_group",
    "get_first_node_in_group", "call_group", "has_theme_color", "has_theme_constant",
    "has_theme_font", "has_theme_font_size", "has_theme_stylebox", "has_theme_icon",
    "load_threaded_request", "load_threaded_get", "load_threaded_get_status", "exists",
    "get_animation", "has_animation", "play", "match", "search", "compile", "RegEx",
    "create_from", "expect", "parse", "begins_with", "ends_with", "find", "rfind", "contains",
    "replace", "split", "get_slice", "trim_prefix", "trim_suffix", "count",
}
QUIET_PREFIXES = ("add_theme_", "get_theme_", "remove_theme_", "has_theme_")

DECLARATION = re.compile(r"^\s*(?:static\s+)?(?:const|var)\s+[A-Za-z_]\w*")
CALLEE = re.compile(r"([A-Za-z_][\w.]*)\s*$")
ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\", "0": "\0"}


class Literal:
    """A string in the code, where it is and what it is inside of."""

    def __init__(self, value, line, start, end, prefix):
        self.value = value
        self.line = line
        self.start = start
        self.end = end
        self.prefix = prefix
        self.frames = []
        self.key = False


def unescape(body, raw):
    if raw:
        return body
    out = []
    i = 0
    while i < len(body):
        c = body[i]
        if c == "\\" and i + 1 < len(body):
            n = body[i + 1]
            if n == "u" and i + 5 < len(body) + 1:
                out.append(chr(int(body[i + 2 : i + 6], 16)))
                i += 6
                continue
            if n == "\n":
                i += 2
                continue
            out.append(ESCAPES.get(n, n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def lex(source):
    """The strings in a script with the brackets they are in, and its comments by line."""
    literals = []
    comments = {}
    depth_at_line = {}
    frames = []
    line = 1
    depth_at_line[1] = 0
    i = 0
    n = len(source)
    while i < n:
        c = source[i]
        if c == "\n":
            line += 1
            depth_at_line[line] = len(frames)
            i += 1
            continue
        if c == "#":
            end = source.find("\n", i)
            end = n if end < 0 else end
            comments[line] = source[i + 1 : end]
            i = end
            continue
        if c in "\"'":
            prefix = source[i - 1] if i > 0 and source[i - 1] in "&^r" else ""
            if prefix == "r" and i > 1 and (source[i - 2].isalnum() or source[i - 2] == "_"):
                prefix = ""
            triple = source[i : i + 3] == c * 3
            quote = c * 3 if triple else c
            j = i + len(quote)
            start_line = line
            while j < n and source[j : j + len(quote)] != quote:
                if source[j] == "\\" and prefix != "r":
                    j += 1
                if j < n and source[j] == "\n":
                    line += 1
                    depth_at_line[line] = len(frames)
                j += 1
            body = source[i + len(quote) : j]
            lit = Literal(unescape(body, prefix == "r"), start_line, i, j + len(quote), prefix)
            lit.frames = [dict(f) for f in frames]
            rest = source[j + len(quote) :].lstrip(" \t")
            if rest.startswith(":") and not rest.startswith(":="):
                inside = frames[-1]["kind"] if frames else ""
                head = source[source.rfind("\n", 0, i) + 1 : i].strip()
                if inside == "{" or (not frames and head == ""):
                    lit.key = True
            literals.append(lit)
            i = j + len(quote)
            continue
        if c in "([{":
            callee = ""
            if c == "(":
                m = CALLEE.search(source[max(0, i - 80) : i])
                callee = m.group(1) if m else ""
            calls_made = len(literals) * 100000 + i
            frames.append({"kind": c, "callee": callee, "arg": 0, "id": calls_made})
            i += 1
            continue
        if c in ")]}":
            if frames:
                frames.pop()
            i += 1
            continue
        if c == "," and frames:
            frames[-1]["arg"] += 1
        i += 1
    return literals, comments, depth_at_line


def translating(callee):
    if callee in CALLS:
        return CALLS[callee]
    last = callee.rsplit(".", 1)[-1]
    if last in ("tr", "tr_n", "atr", "atr_n") and not callee.startswith("Lang."):
        return CALLS[last]
    return None


def quiet(callee):
    last = callee.rsplit(".", 1)[-1]
    return last in QUIET_CALLS or last.startswith(QUIET_PREFIXES)


def looks_like_text(s):
    """Whether a string reads as words to a player rather than a name the code goes by."""
    if "://" in s or s.startswith(("res:", "user:", "uid:", "http")):
        return False
    bare = re.sub(r"\{[^}]*\}", " ", s)
    bare = re.sub(r"%[-+ 0#]*\d*(?:\.\d+)?[sdifxXcv%]", " ", bare)
    bare = re.sub(r"\[/?[a-z_]+(?:=[^\]]*)?\]", " ", bare)
    words = re.findall(r"[A-Za-z]{2,}", bare)
    if not words:
        return False
    if re.fullmatch(r"[a-z0-9_./:#-]+", s):
        return False
    if re.fullmatch(r"[A-Za-z0-9_]+", s) and "_" in s:
        return False
    if re.fullmatch(r"(?:[A-Z][a-z0-9]+){2,}[A-Z]?", s):
        return False
    if re.fullmatch(r"[A-Z][A-Z0-9]?", s.strip()):
        return False
    return True


def table_word(s):
    """Whether a string in a table of words is one: anything with a letter but an identifier."""
    if "://" in s or s.startswith(("res:", "user:", "uid:")):
        return False
    if not re.search(r"[A-Za-z]", re.sub(r"\{[^}]*\}|%[-+ 0#]*\d*(?:\.\d+)?[sdifxXcv%]", "", s)):
        return False
    return not re.fullmatch(r"[a-z0-9]+(?:_[a-z0-9]+)+", s)


def statements(lines, depth_at_line):
    """Each statement's first and last line, with the comment block right above it."""
    found = []
    i = 0
    total = len(lines)
    while i < total:
        number = i + 1
        text = lines[i].strip()
        if not text or text.startswith("#") or depth_at_line.get(number, 0) > 0:
            i += 1
            continue
        if i > 0 and lines[i - 1].rstrip().endswith("\\"):
            i += 1
            continue
        last = number
        while last < total and (
            depth_at_line.get(last + 1, 0) > 0 or lines[last - 1].rstrip().endswith("\\")
        ):
            last += 1
        above = []
        k = i - 1
        while k >= 0 and (lines[k].strip().startswith("#") or lines[k].strip().startswith("@")):
            if lines[k].strip().startswith("#"):
                above.insert(0, lines[k].strip().lstrip("#").strip())
            k -= 1
        declares = bool(DECLARATION.match(lines[i]))
        # A run of declarations with nothing between them shares the comment over its first.
        if declares and not above and found and found[-1][3] and found[-1][1] == number - 1:
            above = found[-1][2]
        found.append((number, last, above, declares))
        i = last
    return found


def scan(path):
    """The words marked in a script, and what looks like text in it and is not."""
    with open(path, encoding="utf-8") as f:
        source = f.read()
    literals, comments, depth_at_line = lex(source)
    lines = source.split("\n")
    by_line = {}
    for first, last, above, declares in statements(lines, depth_at_line):
        joined = " ".join(above)
        notes = [a.split("TRANSLATORS:", 1)[1].strip() for a in above if "TRANSLATORS:" in a]
        mode = ""
        if "NO_TRANSLATE" in joined:
            mode = "quiet"
        elif declares and "tr()" in joined:
            mode = "table"
        for number in range(first, last + 1):
            by_line[number] = (mode, notes)
    words = []
    loose = []
    for lit in literals:
        if lit.prefix in ("&", "^"):
            continue
        mode, notes = by_line.get(lit.line, ("", []))
        trailing = comments.get(lit.line, "")
        if "NO_TRANSLATE" in trailing:
            continue
        calls = [f for f in lit.frames if f["kind"] == "("]
        inner = lit.frames[-1] if lit.frames else None
        slots = translating(inner["callee"]) if inner and inner["kind"] == "(" else None
        if slots is not None:
            texts, context_at = slots
            if inner["arg"] in texts:
                words.append((lit, notes, inner, texts, context_at))
            continue
        if mode == "quiet" or any(quiet(f["callee"]) for f in calls):
            continue
        if mode == "table":
            if table_word(lit.value) and not lit.key:
                words.append((lit, notes, None, None, None))
            continue
        if lit.key or not looks_like_text(lit.value):
            continue
        before = source[source.rfind("\n", 0, lit.start) + 1 : lit.start]
        after = source[lit.end : source.find("\n", lit.end)]
        if re.search(r"(?:==|!=|\bin|\bnot in)\s*$", before) or re.match(r"\s*(?:==|!=)", after):
            continue
        if re.search(r"(?:^|\.|\s)name\s*=\s*$", before) or before.rstrip().endswith("$"):
            continue
        loose.append(lit)
    return words, literals, loose


def entries_of(path, rel):
    """The template's entries for one script: (context, word, plural, note, file)."""
    found = []
    words, literals, _ = scan(path)
    by_call = {}
    for other in literals:
        if other.frames and other.frames[-1]["kind"] == "(":
            by_call.setdefault(other.frames[-1]["id"], []).append(other)
    for lit, notes, call, texts, context_at in words:
        note = " ".join(notes)
        if call is None:
            if lit.value:
                found.append(("", lit.value, None, note, rel))
            continue
        # The plural's word and the context are the same call's other strings.
        if len(texts) == 2 and call["arg"] == 1:
            continue
        context = ""
        plural = None
        for other in by_call.get(call["id"], []):
            arg = other.frames[-1]["arg"]
            if arg == context_at:
                context = other.value
            elif len(texts) == 2 and arg == 1:
                plural = other.value
        if lit.value:
            found.append((context, lit.value, plural, note, rel))
    return found


def data_entries():
    found = []
    pattern = re.compile(
        r'^(%s) = "((?:[^"\\]|\\.)*)"' % "|".join(DATA_FIELDS), re.MULTILINE | re.DOTALL
    )
    for folder, _, files in sorted(os.walk(os.path.join(ROOT, DATA))):
        for name in sorted(files):
            if not name.endswith(".tres"):
                continue
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, ROOT)
            with open(path, encoding="utf-8") as f:
                text = f.read()
            for m in pattern.finditer(text):
                value = unescape(m.group(2), False)
                if value.strip():
                    found.append(("", value, None, m.group(1).replace("_", " "), rel))
    return found


def sources():
    for top in SOURCES:
        for folder, dirs, files in os.walk(os.path.join(ROOT, top)):
            dirs.sort()
            for name in sorted(files):
                if not name.endswith(".gd"):
                    continue
                path = os.path.join(folder, name)
                rel = os.path.relpath(path, ROOT)
                if rel.startswith(LEFT_OUT):
                    continue
                yield path, rel


def collect():
    """Every entry of the template, in the order first met, references and notes gathered."""
    merged = {}
    order = []
    raw = []
    for path, rel in sources():
        raw.extend(entries_of(path, rel))
    raw.extend(data_entries())
    for context, word, plural, note, rel in raw:
        key = (context, word)
        if key not in merged:
            merged[key] = {"plural": plural, "notes": [], "files": []}
            order.append(key)
        entry = merged[key]
        if plural and not entry["plural"]:
            entry["plural"] = plural
        if note and note not in entry["notes"]:
            entry["notes"].append(note)
        if rel not in entry["files"]:
            entry["files"].append(rel)
    return [(key, merged[key]) for key in order]


def quoted(text):
    escaped = text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t")
    escaped = escaped.replace("\r", "\\r")
    if "\n" not in escaped:
        return '"%s"' % escaped
    parts = escaped.split("\n")
    pieces = ['""'] + ['"%s\\n"' % p for p in parts[:-1]]
    if parts[-1]:
        pieces.append('"%s"' % parts[-1])
    return "\n".join(pieces)


def header(locale):
    lines = [
        "Project-Id-Version: Jackpot Junction",
        "MIME-Version: 1.0",
        "Content-Type: text/plain; charset=UTF-8",
        "Content-Transfer-Encoding: 8bit",
        "Language: %s" % locale,
        "Plural-Forms: %s" % PLURAL_FORMS.get(locale, "nplurals=2; plural=(n != 1);"),
    ]
    out = ['msgid ""', 'msgstr ""']
    out += ['"%s\\n"' % line for line in lines]
    return "\n".join(out)


def write_entry(out, key, entry, strings, obsolete=False):
    context, word = key
    lead = "#~ " if obsolete else ""
    block = []
    if not obsolete:
        for note in entry.get("notes", []):
            block.append("#. " + note)
        if entry.get("files"):
            block.append("#: " + " ".join(entry["files"]))
    if entry.get("fuzzy"):
        block.append("#, fuzzy")
    body = []
    if context:
        body.append("msgctxt " + quoted(context))
    body.append("msgid " + quoted(word))
    if entry.get("plural"):
        body.append("msgid_plural " + quoted(entry["plural"]))
        forms = strings if strings else ["", ""]
        for i, form in enumerate(forms):
            body.append("msgstr[%d] %s" % (i, quoted(form)))
    else:
        body.append("msgstr " + quoted(strings[0] if strings else ""))
    for line in "\n".join(body).split("\n"):
        block.append(lead + line)
    out.append("\n".join(block))


def template(entries):
    out = [header("")]
    for key, entry in entries:
        write_entry(out, key, entry, None)
    return "\n\n".join(out) + "\n"


def read_po(path):
    """A .po file's translations, by (context, word), with the ones no longer in the game."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    found = {}
    for block in re.split(r"\n\s*\n", text.strip()):
        lines = block.split("\n")
        obsolete = all(line.startswith("#~") for line in lines if not line.startswith("#."))
        fields = {}
        current = None
        fuzzy = False
        for line in lines:
            if line.startswith("#~"):
                line = line[2:].lstrip()
            elif line.startswith("#"):
                if line.startswith("#,") and "fuzzy" in line:
                    fuzzy = True
                continue
            m = re.match(r"(msgctxt|msgid_plural|msgid|msgstr(?:\[\d+\])?)\s+(\".*\")$", line)
            if m:
                current = m.group(1)
                fields[current] = _unquote(m.group(2))
            elif line.startswith('"') and current:
                fields[current] += _unquote(line)
        if "msgid" not in fields or fields["msgid"] == "":
            continue
        strings = [fields[k] for k in sorted(k for k in fields if k.startswith("msgstr"))]
        key = (fields.get("msgctxt", ""), fields["msgid"])
        found[key] = {"strings": strings, "fuzzy": fuzzy, "obsolete": obsolete,
                      "plural": fields.get("msgid_plural")}
    return found


def _unquote(text):
    body = text.strip()[1:-1]
    return unescape(body, False)


def merged_po(locale, entries, old):
    out = [header(locale)]
    plurals = 1 if "nplurals=1" in PLURAL_FORMS.get(locale, "") else 2
    for key, entry in entries:
        kept = old.get(key)
        strings = kept["strings"] if kept else None
        if entry["plural"]:
            strings = (strings or []) + [""] * plurals
            strings = strings[:plurals]
        shown = dict(entry)
        shown["fuzzy"] = bool(kept and kept["fuzzy"])
        write_entry(out, key, shown, strings)
    live = {key for key, _ in entries}
    for key, kept in old.items():
        if key in live or not any(s for s in kept["strings"]):
            continue
        write_entry(out, key, {"plural": kept["plural"]}, kept["strings"], obsolete=True)
    return "\n\n".join(out) + "\n"


def languages():
    folder = os.path.join(ROOT, LOCALE)
    if not os.path.isdir(folder):
        return []
    return sorted(name[:-3] for name in os.listdir(folder) if name.endswith(".po"))


def wanted_files():
    entries = collect()
    files = {TEMPLATE: template(entries)}
    for locale in languages():
        path = os.path.join(LOCALE, locale + ".po")
        old = read_po(os.path.join(ROOT, path))
        files[path] = merged_po(locale, entries, old)
    return files, entries


def loose_in(paths):
    found = []
    targets = []
    if paths:
        for given in paths:
            full = os.path.join(ROOT, given) if not os.path.isabs(given) else given
            if os.path.isdir(full):
                for folder, dirs, files in os.walk(full):
                    dirs.sort()
                    targets += [os.path.join(folder, f) for f in sorted(files) if f.endswith(".gd")]
            else:
                targets.append(full)
    else:
        targets = [path for path, _ in sources()]
    for path in targets:
        rel = os.path.relpath(path, ROOT)
        if rel.startswith(LEFT_OUT):
            continue
        _, _, loose = scan(path)
        found += [(rel, lit) for lit in loose]
    return found


def main(args):
    command = args[0] if args else "check"
    if command == "update":
        files, entries = wanted_files()
        os.makedirs(os.path.join(ROOT, LOCALE), exist_ok=True)
        for path, text in files.items():
            with open(os.path.join(ROOT, path), "w", encoding="utf-8") as f:
                f.write(text)
        print("%d strings, %d languages" % (len(entries), len(languages())))
        return 0
    if command == "add":
        path = os.path.join(ROOT, LOCALE, args[1] + ".po")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if not os.path.exists(path):
            with open(path, "w", encoding="utf-8") as f:
                f.write(header(args[1]) + "\n")
        return main(["update"])
    if command == "loose":
        found = loose_in(args[1:])
        for rel, lit in found:
            print("%s:%d: %s" % (rel, lit.line, lit.value[:100].replace("\n", "\\n")))
        print("%d strings look like text and are not marked" % len(found), file=sys.stderr)
        return 0
    if command == "stats":
        _, entries = wanted_files()
        for locale in languages():
            old = read_po(os.path.join(ROOT, LOCALE, locale + ".po"))
            done = sum(1 for key, _ in entries if key in old and all(old[key]["strings"]))
            print("%s: %d of %d translated" % (locale, done, len(entries)))
        return 0
    if command == "check":
        failed = False
        files, _ = wanted_files()
        for path, text in files.items():
            full = os.path.join(ROOT, path)
            have = open(full, encoding="utf-8").read() if os.path.exists(full) else None
            if have != text:
                print("%s is behind the code: run make strings" % path)
                failed = True
        found = loose_in([])
        for rel, lit in found:
            print("%s:%d: not marked for translation: %s" % (rel, lit.line, lit.value[:80]))
        if found:
            print(
                "Mark each with tr() where it is written, or # NO_TRANSLATE where it is not "
                "text, GAME.md 10.9"
            )
            failed = True
        return 1 if failed else 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
