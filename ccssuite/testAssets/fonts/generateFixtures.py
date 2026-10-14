from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen


def create_fixture(kind, family, postscript_name):
    builder = FontBuilder(1000, isTTF=True)
    builder.setupGlyphOrder([".notdef", "A"])
    builder.setupCharacterMap({65: "A"})
    empty_pen = TTGlyphPen(None)
    glyph_pen = TTGlyphPen(None)
    glyph_pen.moveTo((100, 0))
    glyph_pen.lineTo((300, 700))
    glyph_pen.lineTo((500, 0))
    glyph_pen.closePath()
    builder.setupGlyf({".notdef": empty_pen.glyph(), "A": glyph_pen.glyph()})
    builder.setupHorizontalMetrics({".notdef": (600, 0), "A": (600, 0)})
    builder.setupHorizontalHeader(ascent=800, descent=-200)
    builder.setupNameTable(
        {
            "familyName": family,
            "styleName": "Regular",
            "uniqueFontIdentifier": postscript_name,
            "fullName": family + " Regular",
            "psName": postscript_name,
            "version": "Version 1.0",
        }
    )
    builder.setupOS2(
        sTypoAscender=800, sTypoDescender=-200, usWinAscent=800, usWinDescent=200
    )
    builder.setupPost()
    builder.setupMaxp()
    builder.font["head"].created = 2082844800
    builder.font["head"].modified = 2082844800
    destination = Path(__file__).parent / kind / (postscript_name + ".ttf")
    destination.parent.mkdir(parents=True, exist_ok=True)
    builder.save(destination)


if __name__ == "__main__":
    create_fixture("file", "CCSSuite Font File", "CCSSuiteFontFile-Regular")
    create_fixture("directory", "CCSSuite Font Directory", "CCSSuiteFontDirectory-Regular")