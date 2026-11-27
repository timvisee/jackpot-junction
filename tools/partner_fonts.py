"""The Chinese partner of every typeface the game is set in, GAME.md 10.9.

None of the game's faces draws Chinese. Each gets a partner that does, which the game hangs behind
it as a fallback (Type.dress): a letter the face has is drawn in the face, a Chinese character in
its partner. A partner is cut from an open Chinese font, fetched pinned and checksummed into
build/fonts, never kept whole in the repository:

- down to the characters the game needs: whatever the Chinese translation uses, and for a face that
  draws players' names the characters of GB 2312 as well, so a name typed in Chinese shows;
- to its face's size: scaled so that a Chinese character stands as tall beside the face's lowercase
  as one of Noto Sans SC beside Barlow's, so a hand set bigger for its small letters, as Kit's is,
  does not set its Chinese bigger too; or, behind a face set in capitals, the display cuts and the
  marker, a little taller than its capitals and seated on their baseline, so a heading's Chinese
  takes the room its capitals did and no line set close under it is run into;
- to its faces' line: no taller over the baseline nor deeper under it than any face it stands
  behind. The engine sets a line by its face and by every fallback a character of it is drawn in,
  and measures a face with its fallbacks too, so a line with Chinese in it, and the face itself,
  measure as they did without;
- under a name of its own, as the SIL Open Font License asks of a font changed, since some of them
  reserve their names for the fonts as they are.

It writes the cut fonts, each one's license and partners.json, which says which faces each stands
behind, into assets/fonts/chinese. Run it whenever
the Chinese translation uses a character a partner lacks; a test says when (tests/test_type.gd).

Usage: python3 tools/partner_fonts.py [--po <file.po>]
Needs fontTools, so `make fonts` runs it through uv. --po cuts from another translation file than
data/locale/zh_CN.po, to try one out; `make fonts` cuts them back. The same translation always
cuts the same files.
"""

import argparse
import hashlib
import json
import math
import os
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import strings  # noqa: E402
from fontTools import subset  # noqa: E402
from fontTools.pens.boundsPen import BoundsPen  # noqa: E402
from fontTools.ttLib import TTFont  # noqa: E402
from fontTools.varLib import instancer  # noqa: E402

ROOT = strings.ROOT
FACES = os.path.join(ROOT, "assets", "fonts")
OUT = os.path.join(FACES, "chinese")
CACHE = os.path.join(ROOT, "build", "fonts")
CHINESE = "zh_CN"

GOOGLE = (
    "https://raw.githubusercontent.com/google/fonts/5026800714d07231937d92eb4cceabf06e05d74e/ofl/"
)
WENKAI = "https://github.com/lxgw/LxgwWenKai/"
XIAOLAI = "https://github.com/lxgw/kose-font/"

# Each upstream font: where it is fetched from and its SHA-256, and its license's.
SOURCES = {
    "noto-sans-sc": (
        GOOGLE + "notosanssc/NotoSansSC%5Bwght%5D.ttf",
        "a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da",
        GOOGLE + "notosanssc/OFL.txt",
        "1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9",
    ),
    "noto-serif-sc": (
        GOOGLE + "notoserifsc/NotoSerifSC%5Bwght%5D.ttf",
        "050080d9255a86808f2945bffac582b31ef32bc36411ce29563b4961670c66f9",
        GOOGLE + "notoserifsc/OFL.txt",
        "5e0da210fb04058a8c0087985d2d456b931c2579811a49655721d3cf0c36b6d6",
    ),
    "wenkai": (
        WENKAI + "releases/download/v1.530/LXGWWenKai-Regular.ttf",
        "2d73eea94ad808999d90c0000c239a84a33b09d4bc6ab6c5b8bbf1eda8a7fc8b",
        "https://raw.githubusercontent.com/lxgw/LxgwWenKai/v1.530/OFL.txt",
        "1a25e35da1031c6c3436fde545bb9cb5aca954e9873afe510c834b8b79bd21a0",
    ),
    "xiaolai": (
        XIAOLAI + "releases/download/v3.126/Xiaolai-Regular.ttf",
        "e2f68daf0e72777a8cf58bc83de1b98634b251e537ddbfca24b0ae50d1802da2",
        "https://raw.githubusercontent.com/lxgw/kose-font/v3.126/OFL.txt",
        "0df7e09be4c2c850a48bd8beb9cd64b343aad49cd5d3f6cfb2ad2e3d28a56ca4",
    ),
    "long-cang": (
        GOOGLE + "longcang/LongCang-Regular.ttf",
        "e5bf2c3f24ef2327c6f136d8f73e2f9dfdf44896fdbeb35a9515f44777bb91bc",
        GOOGLE + "longcang/OFL.txt",
        "603546b7219a94bb59bf8294458194a5010119486354092b66a09a3fd61aeacc",
    ),
    "zhi-mang-xing": (
        GOOGLE + "zhimangxing/ZhiMangXing-Regular.ttf",
        "644e0cae9b40f0b10ab729a01bd32032e3973bac22be3dccae01bf6ae7fde969",
        GOOGLE + "zhimangxing/OFL.txt",
        "10947328199e369a3e6b4a67e8e5507ed99d5bbb264a1f156415aa9b665e4d15",
    ),
    "zcool-kuaile": (
        GOOGLE + "zcoolkuaile/ZCOOLKuaiLe-Regular.ttf",
        "812a6fc1fe54b6d73a419245c32dfeba8aa33104d5be90d1cf6af082007cb71d",
        GOOGLE + "zcoolkuaile/OFL.txt",
        "538078469839b4a2e7ad22bef4ebe41681a4e53749bb2a072144024f1d6d703d",
    ),
}

# How much of Chinese a partner holds, besides what the translation uses: none more, the 3,755
# common characters of GB 2312's first level, or all 6,763 of it, for a face that draws names.
WORDS, COMMON, NAMES = "words", "common", "names"

# Each partner: its file, the upstream font and the weight it is cut at where it has more than
# one, how much it holds, the name it goes by, and the faces it stands behind, the first of which
# it is cut to the size of.
CUTS = [
    ("NotoSansSC-Medium.ttf", "noto-sans-sc", 500, NAMES, "Noto Sans SC JJ", "Medium",
     ["Barlow-Medium.ttf"]),
    ("NotoSansSC-Bold.ttf", "noto-sans-sc", 700, NAMES, "Noto Sans SC JJ", "Bold",
     ["BarlowSemiCondensed-SemiBold.ttf"]),
    ("NotoSansSC-Black.ttf", "noto-sans-sc", 900, NAMES, "Noto Sans SC JJ", "Black",
     ["BarlowCondensed-ExtraBold.ttf", "BarlowCondensed-Black.ttf"]),
    ("NotoSerifSC-Regular.ttf", "noto-serif-sc", 400, WORDS, "Noto Serif SC JJ", "Regular",
     ["CourierPrime-Regular.ttf"]),
    ("NotoSerifSC-SemiBold.ttf", "noto-serif-sc", 600, WORDS, "Noto Serif SC JJ", "SemiBold",
     ["IMFellEnglish-Regular.ttf"]),
    ("WenKai-Regular.ttf", "wenkai", None, WORDS, "WenKai JJ", "Regular",
     ["Caveat-Variable.ttf"]),
    ("Xiaolai-Regular.ttf", "xiaolai", None, WORDS, "Xiaolai JJ", "Regular",
     ["Kalam-Regular.ttf"]),
    ("LongCang-Regular.ttf", "long-cang", None, WORDS, "Long Cang JJ", "Regular",
     ["PatrickHand-Regular.ttf", "ReenieBeanie-Regular.ttf"]),
    ("ZhiMangXing-Regular.ttf", "zhi-mang-xing", None, COMMON, "Zhi Mang Xing JJ", "Regular",
     ["HomemadeApple-Regular.ttf"]),
    ("ZCOOLKuaiLe-Regular.ttf", "zcool-kuaile", None, WORDS, "ZCOOL KuaiLe JJ", "Regular",
     ["PermanentMarker-Regular.ttf"]),
]
# The partners behind faces set in capitals, and how much taller than the capitals their Chinese
# stands, and how far below the baseline it reaches, in ems.
CAPITALS = ["NotoSansSC-Black.ttf", "ZCOOLKuaiLe-Regular.ttf"]
OVER_CAPITALS = 1.12
SEATED = 0.02
# The partner a hand falls back on for a character its own lacks, a name's say: the text face's,
# which so stands behind every face.
LAST = "NotoSansSC-Medium.ttf"
# Where every size is measured from: a Chinese character of Noto Sans SC at its Medium weight stands
# as tall beside Barlow Medium's lowercase as it should, so every partner stands as tall beside its
# own face's.
REFERENCE = ("noto-sans-sc", 500, "Barlow-Medium.ttf")
# The character whose height says how big a font draws Chinese.
MEASURE = "国"
# Punctuation every partner has, translated yet or not: CJK symbols and punctuation, and the
# full-width forms.
PUNCTUATION = [chr(c) for c in range(0x3000, 0x3040)] + [chr(c) for c in range(0xFF01, 0xFF5F)]


def fetch(url, sha):
    """The file at [url], from the cache once fetched, checked against [sha] where given."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, hashlib.sha256(url.encode()).hexdigest()[:16] + "-"
                        + os.path.basename(url).replace("%5B", "[").replace("%5D", "]"))
    if not os.path.exists(path):
        print("fetching %s" % url)
        with urllib.request.urlopen(url) as response:
            data = response.read()
        with open(path + ".part", "wb") as f:
            f.write(data)
        os.replace(path + ".part", path)
    with open(path, "rb") as f:
        found = hashlib.sha256(f.read()).hexdigest()
    if sha and found != sha:
        sys.exit("%s is not the file pinned: sha256 %s, not %s" % (url, found, sha))
    if not sha:
        print("unpinned %s: sha256 %s" % (url, found))
    return path


def gb2312(levels):
    """The characters of GB 2312: its symbols' rows (0), its first level (1), its second (2)."""
    rows = {0: range(0xA1, 0xAA), 1: range(0xB0, 0xD8), 2: range(0xD8, 0xF8)}
    found = []
    for level in levels:
        for high in rows[level]:
            for low in range(0xA1, 0xFF):
                try:
                    found.append(bytes([high, low]).decode("gb2312"))
                except UnicodeDecodeError:
                    pass
    return found


def translated(po):
    """Every character the translation in [po] uses."""
    with open(po, encoding="utf-8") as f:
        _, entries = strings.parse_po(f.read())
    used = set()
    for entry in entries.values():
        if entry["obsolete"]:
            continue
        for said in entry["strings"]:
            used.update(said)
    return used


def characters(cover, words):
    """What a partner holding [cover] keeps, the translation's [words] among it."""
    wanted = set(words) | set(PUNCTUATION)
    if cover in (COMMON, NAMES):
        wanted.update(gb2312([0, 1]))
    if cover == NAMES:
        wanted.update(gb2312([2]))
    return sorted(ord(c) for c in wanted if ord(c) > 0x7F)


def opened(source, weight):
    """The upstream [source], instanced at [weight] where it is a variable font."""
    url, sha, _, _ = SOURCES[source]
    font = TTFont(fetch(url, sha))
    if "fvar" in font:
        font = instancer.instantiateVariableFont(font, {"wght": weight})
    # The upstream's own date kept, so the same translation cuts the same files.
    font.recalcTimestamp = False
    return font


def measured(font):
    """How tall [font] draws [MEASURE], in ems."""
    low, high = reach(font)
    return (high - low) / font["head"].unitsPerEm


def reach(font):
    """How far under the baseline and over it [font] draws [MEASURE], in its units."""
    glyphs = font.getGlyphSet()
    pen = BoundsPen(glyphs)
    glyphs[font.getBestCmap()[ord(MEASURE)]].draw(pen)
    return pen.bounds[1], pen.bounds[3]


def capitals(face):
    """How tall [face]'s capitals stand, in ems."""
    return face["OS/2"].sCapHeight / face["head"].unitsPerEm


def seat(font, low, depth):
    """Moves every outline of [font] up or down so [MEASURE], reaching [low] units under the
    baseline, reaches [depth] ems under it."""
    rise = round(-depth * font["head"].unitsPerEm - low)
    glyf = font["glyf"]
    for name in font.getGlyphOrder():
        glyph = glyf[name]
        if not glyph.isComposite() and glyph.numberOfContours > 0:
            glyph.coordinates.translate((0, rise))
    # A composite is moved with the glyphs it is made of.
    for name in font.getGlyphOrder():
        glyf[name].recalcBounds(glyf)


def lowercase(face):
    """How tall [face]'s lowercase stands, in ems."""
    return face["OS/2"].sxHeight / face["head"].unitsPerEm


def cut(font, keep, faces, scale, family, style, seated=None):
    """[font] cut down to [keep], drawn [scale] times its size, seated [seated] ems under the
    baseline where given, in a line no taller over the baseline nor deeper under it than any of
    [faces], named [family] [style]."""
    # Measured before the cut, which may leave no [MEASURE] to measure.
    low, _ = reach(font)
    options = subset.Options()
    options.hinting = False
    options.notdef_outline = True
    options.name_IDs = ["*"]
    options.drop_tables += ["vhea", "vmtx", "VORG", "STAT", "DSIG"]
    cutter = subset.Subsetter(options)
    cutter.populate(unicodes=keep)
    cutter.subset(font)
    # Drawn smaller by being drawn in more units to the em, every outline and advance as it is.
    upm = round(font["head"].unitsPerEm / scale)
    font["head"].unitsPerEm = upm
    if seated is not None:
        seat(font, low, seated)
    # Rounded in, so that rounded to pixels it is never a pixel over.
    ascent = math.floor(min(f["hhea"].ascent / f["head"].unitsPerEm for f in faces) * upm)
    descent = math.ceil(max(f["hhea"].descent / f["head"].unitsPerEm for f in faces) * upm)
    gap = 0
    font["hhea"].ascent, font["hhea"].descent, font["hhea"].lineGap = ascent, descent, gap
    os2 = font["OS/2"]
    os2.sTypoAscender, os2.sTypoDescender, os2.sTypoLineGap = ascent, descent, gap
    os2.usWinAscent, os2.usWinDescent = max(ascent, 0), max(-descent, 0)
    os2.version = max(os2.version, 4)
    os2.fsSelection |= 1 << 7
    rename(font, family, style)
    return font


def rename(font, family, style):
    """Names [font] [family] [style], keeping its copyright and license."""
    name = font["name"]
    full = "%s %s" % (family, style)
    postscript = full.replace(" ", "")
    for record in list(name.names):
        if record.nameID in (1, 2, 3, 4, 6, 16, 17, 18, 21, 22, 25):
            name.removeNames(nameID=record.nameID)
    for number, said in ((1, family), (2, style), (3, postscript), (4, full), (6, postscript)):
        name.setName(said, number, 3, 1, 0x409)
        name.setName(said, number, 1, 0, 0)
    if "CFF " in font:
        font["CFF "].cff.fontNames = [postscript]


def main(args):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--po", default=os.path.join(ROOT, strings.LOCALE, CHINESE + ".po"))
    wanted = parser.parse_args(args)
    words = translated(wanted.po)
    source, weight, face = REFERENCE
    reference = measured(opened(source, weight)) / lowercase(TTFont(os.path.join(FACES, face)))
    os.makedirs(OUT, exist_ok=True)
    partners = {}
    written = set()
    # The last stands behind every face, the others' partners too.
    others = [face for each in CUTS if each[0] != LAST for face in each[6]]
    for file, source, weight, cover, family, style, faces in CUTS:
        named = faces + (others if file == LAST else [])
        behind = [TTFont(os.path.join(FACES, each)) for each in named]
        font = opened(source, weight)
        keep = characters(cover, words)
        if file in CAPITALS:
            scale = capitals(behind[0]) * OVER_CAPITALS / measured(font)
            cut(font, keep, behind, scale, family, style, SEATED).save(os.path.join(OUT, file))
        else:
            scale = lowercase(behind[0]) * reference / measured(font)
            cut(font, keep, behind, scale, family, style).save(os.path.join(OUT, file))
        print("%-26s %5d characters, %.2f times its size, %4d KB" % (
            file, len(keep), scale, os.path.getsize(os.path.join(OUT, file)) // 1024))
        for each in faces:
            partners[each] = file
        if source not in written:
            _, _, license_url, license_sha = SOURCES[source]
            with open(fetch(license_url, license_sha), encoding="utf-8") as f:
                text = f.read()
            with open(os.path.join(OUT, "LICENSE-%s-ofl.txt" % source), "w", encoding="utf-8") as f:
                f.write(text)
            written.add(source)
    with open(os.path.join(OUT, "partners.json"), "w", encoding="utf-8") as f:
        said = {"faces": partners, "last": LAST}
        json.dump(said, f, indent="\t", sort_keys=True)
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
