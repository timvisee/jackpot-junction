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
    tools/strings.py tables          list consts shown through tr() that are not marked as tables
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
# Nor a debug build's own page for moving the story along, nor a dedicated server's web page.
LEFT_OUT = ("scenes/dev/", "scenes/ui/story_debug_tab.gd", "scenes/server/server_web.gd")
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
    "is_connected", "emit_signal", "has_method", "set", "get", "export_group",
    "export_subgroup", "export_category",
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
    "create_from", "create_from_string", "expect", "parse", "begins_with", "ends_with", "find", "rfind", "contains",
    "replace", "split", "get_slice", "trim_prefix", "trim_suffix", "count",
}
QUIET_PREFIXES = ("add_theme_", "get_theme_", "remove_theme_", "has_theme_")
# Of these, only the arguments that name something are quiet: a value set beside a name may well be
# words. Every other quiet call is quiet in all its arguments.
QUIET_ARGS = {
    "set_meta": (0,),
    "get_meta": (0,),
    "has_meta": (0,),
    "remove_meta": (0,),
    "connect": (0,),
    "disconnect": (0,),
    "is_connected": (0,),
    "emit_signal": (0,),
    "has_method": (0,),
    "set": (0,),
    "get": (0,),
    "set_deferred": (0,),
    "get_indexed": (0,),
    "set_indexed": (0,),
    "tween_property": (1,),
    "tween_method": (),
    "Callable": (1,),
    "add_to_group": (0,),
    "is_in_group": (0,),
    "remove_from_group": (0,),
    "get_nodes_in_group": (0,),
    "get_first_node_in_group": (0,),
    "call_group": (0, 1),
}

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
        # A function written inside a call's brackets: what it says is not the call's argument.
        if (
            c == "f"
            and frames
            and source.startswith("func", i)
            and (i == 0 or not (source[i - 1].isalnum() or source[i - 1] == "_"))
            and not (source[i + 4 : i + 5].isalnum() or source[i + 4 : i + 5] == "_")
        ):
            frames[-1]["lambda"] = True
        i += 1
    return literals, comments, depth_at_line


def translating(callee):
    if callee in CALLS:
        return CALLS[callee]
    last = callee.rsplit(".", 1)[-1]
    if last in ("tr", "tr_n", "atr", "atr_n") and not callee.startswith("Lang."):
        return CALLS[last]
    return None


def quiet(frame):
    """Whether a string inside [frame], a call's brackets, is never shown: an argument of a call
    that only names things, but not one in a function written inside the call."""
    last = frame["callee"].rsplit(".", 1)[-1]
    if frame.get("lambda") or not (last in QUIET_CALLS or last.startswith(QUIET_PREFIXES)):
        return False
    return last not in QUIET_ARGS or frame["arg"] in QUIET_ARGS[last]


def looks_like_text(s):
    """Whether a string reads as words to a player rather than a name the code goes by."""
    if "://" in s or s.startswith(("res:", "user:", "uid:", "http")):
        return False
    if re.fullmatch(r"#[0-9A-Fa-f]{3,8}", s):
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
    """Whether a string in a table of words is one: anything with a letter but an identifier or a
    color."""
    if "://" in s or s.startswith(("res:", "user:", "uid:")):
        return False
    if re.fullmatch(r"#[0-9A-Fa-f]{3,8}", s):
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
        if mode == "quiet" or any(quiet(f) for f in calls):
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


def tool_entries():
    """The words the art tools draw into pictures, marked with _() as gettext's tools mark them,
    see baked_words.py."""
    found = []
    pattern = re.compile(r'\b_\(\s*"((?:[^"\\]|\\.)*)"\s*\)')
    folder = os.path.join(ROOT, "tools")
    for name in sorted(os.listdir(folder)):
        if not (name.startswith("make_") and name.endswith(".py")):
            continue
        rel = os.path.join("tools", name)
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            text = f.read()
        for m in pattern.finditer(text):
            note = "Drawn into a picture by %s." % rel
            found.append(("", unescape(m.group(1), False), None, note, rel))
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
    raw.extend(tool_entries())
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


# The header fields the template sets; any other a translator's tool adds is kept as it is.
OWN_HEADER = (
    "Project-Id-Version",
    "MIME-Version",
    "Content-Type",
    "Content-Transfer-Encoding",
    "Language",
    "Plural-Forms",
)
PLACEHOLDER = re.compile(r"\{[A-Za-z_][A-Za-z0-9_]*\}")
# No space flag: "20% faster" is a percentage before a word, never a code the game fills.
FORMAT = re.compile(r"%[-+0#]*\d*(?:\.\d+)?[sdifxXcv]")
TAG = re.compile(r"\[(/?[a-z_]+)(?:[= ][^\]]*)?\]")


def header(locale, kept=None):
    """A file's header: the template's own fields, then whatever else [kept] had."""
    kept = dict(kept or {})
    plural = kept.get("Plural-Forms") or PLURAL_FORMS.get(locale, "nplurals=2; plural=(n != 1);")
    fields = [
        ("Project-Id-Version", "Jackpot Junction"),
        ("MIME-Version", "1.0"),
        ("Content-Type", "text/plain; charset=UTF-8"),
        ("Content-Transfer-Encoding", "8bit"),
        ("Language", locale),
        ("Plural-Forms", plural),
    ]
    fields += [(name, value) for name, value in kept.items() if name not in OWN_HEADER]
    out = ['msgid ""', 'msgstr ""']
    out += [quoted("%s: %s\n" % field).split("\n")[-1] for field in fields]
    return "\n".join(out)


def write_entry(out, key, entry, strings, obsolete=False):
    """One entry as gettext orders its parts: the translator's comments, the notes for them, where
    the words are, the flags, then the words."""
    context, word = key
    lead = "#~ " if obsolete else ""
    block = []
    for comment in entry.get("comments", []):
        block.append(("# " + comment).rstrip())
    if not obsolete:
        for note in entry.get("notes", []):
            block.append("#. " + note)
        if entry.get("files"):
            block.append("#: " + " ".join(entry["files"]))
    flags = list(entry.get("flags", []))
    if entry.get("fuzzy") and "fuzzy" not in flags:
        flags.insert(0, "fuzzy")
    if flags:
        block.append("#, " + ", ".join(flags))
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


def parse_po(text):
    """A .po or .pot file read as gettext reads it, however a tool wrapped or ordered it: its
    header's fields, and each entry by (context, word) with its translations, notes, references,
    flags and the translator's own comments, and whether it is set aside."""
    found = {}
    head = {}
    for block in re.split(r"\n\s*\n", text.strip()):
        lines = [line for line in block.split("\n") if line.strip()]
        if not lines:
            continue
        obsolete = all(line.startswith("#") for line in lines) and any(
            line.startswith("#~") for line in lines
        )
        fields = {}
        current = None
        entry = {"comments": [], "notes": [], "files": [], "flags": []}
        for line in lines:
            if line.startswith("#~"):
                line = line[2:].lstrip()
            elif line.startswith("#."):
                entry["notes"].append(line[2:].strip())
                continue
            elif line.startswith("#:"):
                entry["files"] += line[2:].split()
                continue
            elif line.startswith("#,"):
                entry["flags"] += [f.strip() for f in line[2:].split(",") if f.strip()]
                continue
            elif line.startswith("#|"):
                continue
            elif line.startswith("#"):
                entry["comments"].append(line[1:].strip())
                continue
            m = re.match(r"(msgctxt|msgid_plural|msgid|msgstr(?:\[\d+\])?)\s+(\".*\")$", line)
            if m:
                current = m.group(1)
                fields[current] = _unquote(m.group(2))
            elif line.startswith('"') and current:
                fields[current] += _unquote(line)
        if "msgid" not in fields:
            continue
        if fields["msgid"] == "" and "msgctxt" not in fields:
            for line in fields.get("msgstr", "").split("\n"):
                if ":" in line:
                    name, value = line.split(":", 1)
                    head[name.strip()] = value.strip()
            continue
        names = sorted(
            (k for k in fields if k.startswith("msgstr")),
            key=lambda k: int(k[7:-1]) if "[" in k else 0,
        )
        key = (fields.get("msgctxt", ""), fields["msgid"])
        entry.update(
            {
                "strings": [fields[k] for k in names],
                "fuzzy": "fuzzy" in entry["flags"],
                "obsolete": obsolete,
                "plural": fields.get("msgid_plural"),
            }
        )
        entry["flags"] = [f for f in entry["flags"] if f != "fuzzy"]
        found[key] = entry
    return head, found


def read_po(path):
    """A .po file's translations, by (context, word), with the ones no longer in the game."""
    with open(path, encoding="utf-8") as f:
        return parse_po(f.read())[1]


def _unquote(text):
    body = text.strip()[1:-1]
    return unescape(body, False)


def plural_count(forms):
    m = re.search(r"nplurals\s*=\s*(\d+)", forms or "")
    return int(m.group(1)) if m else 2


def merged_po(locale, entries, old, kept_header=None):
    out = [header(locale, kept_header)]
    forms = (kept_header or {}).get("Plural-Forms") or PLURAL_FORMS.get(locale, "")
    plurals = plural_count(forms)
    for key, entry in entries:
        kept = old.get(key)
        if kept and kept["obsolete"]:
            # Words back in the game have their old translation back, to be looked over.
            kept = dict(kept, fuzzy=any(kept["strings"]))
        strings = kept["strings"] if kept else None
        if entry["plural"]:
            strings = (strings or []) + [""] * plurals
            strings = strings[:plurals]
        shown = dict(entry)
        shown["fuzzy"] = bool(kept and kept["fuzzy"])
        shown["comments"] = kept["comments"] if kept else []
        shown["flags"] = kept["flags"] if kept else []
        write_entry(out, key, shown, strings)
    live = {key for key, _ in entries}
    for key, kept in old.items():
        if key in live or not any(s for s in kept["strings"]):
            continue
        gone = {"plural": kept["plural"], "comments": kept["comments"]}
        write_entry(out, key, gone, kept["strings"], obsolete=True)
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
        with open(os.path.join(ROOT, path), encoding="utf-8") as f:
            head, old = parse_po(f.read())
        files[path] = merged_po(locale, entries, old, head)
    return files, entries


def same_po(a, b):
    """Whether two .po files say the same, however each is wrapped or ordered."""
    head_a, entries_a = parse_po(a)
    head_b, entries_b = parse_po(b)
    for name in ("Language", "Plural-Forms"):
        if head_a.get(name, "") != head_b.get(name, ""):
            return False
    if entries_a.keys() != entries_b.keys():
        return False
    for key, entry in entries_a.items():
        other = entries_b[key]
        for part in ("strings", "plural", "fuzzy", "obsolete", "notes", "comments"):
            if entry[part] != other[part]:
                return False
        if sorted(entry["files"]) != sorted(other["files"]):
            return False
    return True


# The lessons' words drawn in their colors, marked with braces as a placeholder is: a translation
# puts its own word for each in the braces, see scenes/ui/terms.gd.
TERMS_FILE = os.path.join("scenes", "ui", "terms.gd")


def terms():
    """The English of the words a lesson marks with braces, lowered, from Terms.WORDS."""
    with open(os.path.join(ROOT, TERMS_FILE), encoding="utf-8") as f:
        m = re.search(r"^const WORDS: Array\[String\] = \[(.*?)\]", f.read(), re.M | re.S)
    return {word.lower() for word in re.findall(r'"([^"]+)"', m.group(1))} if m else set()


def broken_translations(locale, path):
    """Translations whose placeholders, format codes or markup differ from their English, which
    the game would show wrongly or fail to fill: (word, what is wrong)."""
    with open(path, encoding="utf-8") as f:
        _, entries = parse_po(f.read())
    english_terms = terms()
    said_terms = set(english_terms)
    for term in english_terms:
        entry = entries.get(("", term))
        if entry and entry["strings"] and entry["strings"][0]:
            said_terms.add(entry["strings"][0].lower())

    found = []
    for (context, word), entry in entries.items():
        if entry["obsolete"] or entry["fuzzy"]:
            continue
        englishes = [word] + ([entry["plural"]] if entry["plural"] else [])
        braced = {b[1:-1].lower() for e in englishes for b in re.findall(r"\{[^{}]+\}", e)}
        # A lesson's line marks only the lessons' words; a line with any other braces is filled
        # by the code, and keeps every one of them as they are.
        lesson = bool(braced) and braced <= english_terms
        for i, text in enumerate(entry["strings"]):
            if not text:
                continue
            english = word
            if entry["plural"] and (i > 0 or len(entry["strings"]) == 1):
                english = entry["plural"]
            if lesson:
                wrong = [t for t in re.findall(r"\{([^{}]+)\}", text) if t.lower() not in said_terms]
                found += [(word, "{%s} is none of the lessons' words here" % t) for t in wrong]
            elif sorted(PLACEHOLDER.findall(text)) != sorted(PLACEHOLDER.findall(english)):
                found.append((word, "the {placeholders} differ from the English"))
                continue
            codes = FORMAT.findall(text.replace("%%", ""))
            # A count's forms say the number as the English do; where the English says one
            # without it, "once", a form may leave it out, its code filling only what has one.
            allowed = [FORMAT.findall(e.replace("%%", "")) for e in englishes]
            if entry["plural"] and not allowed[0]:
                allowed.append([])
            if codes not in allowed if entry["plural"] else codes != allowed[0]:
                found.append((word, "the % codes differ from the English, or their order"))
            elif sorted(TAG.findall(text)) != sorted(TAG.findall(english)):
                found.append((word, "the [tags] differ from the English"))
    return found


def registered():
    """The translations the project loads, from project.godot."""
    with open(os.path.join(ROOT, "project.godot"), encoding="utf-8") as f:
        m = re.search(r"^locale/translations=PackedStringArray\((.*)\)$", f.read(), re.M)
    return re.findall(r'"res://([^"]+)"', m.group(1)) if m else []


def register(locale):
    """Lists [locale]'s file among the project's translations, so the engine loads it."""
    path = os.path.join(ROOT, "project.godot")
    with open(path, encoding="utf-8") as f:
        text = f.read()
    files = registered()
    wanted = "%s/%s.po" % (LOCALE, locale)
    if wanted in files:
        return
    files = sorted(files + [wanted])
    line = "locale/translations=PackedStringArray(%s)" % ", ".join(
        '"res://%s"' % name for name in files
    )
    if re.search(r"^locale/translations=", text, re.M):
        text = re.sub(r"^locale/translations=.*$", line, text, flags=re.M)
    elif "[internationalization]" in text:
        text = text.replace("[internationalization]\n", "[internationalization]\n\n" + line + "\n", 1)
    else:
        text = text.rstrip("\n") + "\n\n[internationalization]\n\n" + line + "\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def named_in_game(locale):
    """Whether scripts/lang.gd names [locale], as the settings list it."""
    with open(os.path.join(ROOT, "scripts", "lang.gd"), encoding="utf-8") as f:
        return re.search(r'^\s*"%s": "' % re.escape(locale), f.read(), re.M) is not None


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


SHOWN = re.compile(
    r"\b(?:tr|tr_n|atr|Lang\.t|Lang\.tn)\(\s*(?:([A-Z][A-Za-z0-9]*)\.)?([A-Z][A-Z0-9_]+)\b"
)


def unmarked_tables():
    """Consts shown through tr() whose words the template never gets, since the comment over the
    table does not say it is shown through tr(): (where it is shown, the const's file, its name)."""
    classes = {}
    tables = {}
    for path, rel in sources():
        with open(path, encoding="utf-8") as f:
            source = f.read()
        m = re.search(r"^class_name\s+(\w+)", source, re.M)
        if m:
            classes[m.group(1)] = rel
        _, _, depth_at_line = lex(source)
        lines = source.split("\n")
        found = {}
        for first, _, above, declares in statements(lines, depth_at_line):
            m = DECLARATION.match(lines[first - 1])
            if not declares or not m:
                continue
            name = m.group(0).split()[-1]
            joined = " ".join(above)
            found[name] = "tr()" in joined or "NO_TRANSLATE" in joined
        tables[rel] = found
    wrong = []
    for path, rel in sources():
        with open(path, encoding="utf-8") as f:
            for number, line in enumerate(f, 1):
                code = line.split("#", 1)[0] if '"' not in line else line
                for m in SHOWN.finditer(code):
                    owner = classes.get(m.group(1), "") if m.group(1) else rel
                    marked = tables.get(owner, {}).get(m.group(2))
                    if marked is False:
                        wrong.append(("%s:%d" % (rel, number), owner, m.group(2)))
    return wrong


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
        locale = args[1]
        path = os.path.join(ROOT, LOCALE, locale + ".po")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if not os.path.exists(path):
            with open(path, "w", encoding="utf-8") as f:
                f.write(header(locale) + "\n")
        register(locale)
        if not named_in_game(locale):
            print("Name %s in Lang.NAMES (and Lang.STEAM_NAMES) in scripts/lang.gd" % locale)
        return main(["update"])
    if command == "loose":
        found = loose_in(args[1:])
        for rel, lit in found:
            print("%s:%d: %s" % (rel, lit.line, lit.value[:100].replace("\n", "\\n")))
        print("%d strings look like text and are not marked" % len(found), file=sys.stderr)
        return 0
    if command == "tables":
        for where, owner, name in unmarked_tables():
            print("%s: %s of %s" % (where, name, owner))
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
            if have is None or not same_po(have, text):
                print("%s is behind the code: run make strings" % path)
                failed = True
        for locale in languages():
            path = os.path.join(LOCALE, locale + ".po")
            if path not in registered():
                print("%s is not among the project's translations: tools/strings.py add" % path)
                failed = True
            if not named_in_game(locale):
                print("%s is not named in Lang.NAMES in scripts/lang.gd" % locale)
                failed = True
            for word, wrong in broken_translations(locale, os.path.join(ROOT, path)):
                print("%s: %s: %s" % (path, word[:60].replace("\n", "\\n"), wrong))
                failed = True
        for where, owner, name in unmarked_tables():
            print("%s: shows %s of %s through tr(), not marked as shown so" % (where, name, owner))
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
