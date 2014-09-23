module graphics.font;

import std.string;
import std.conv;
import std.range;
import std.algorithm;
import allegro;
import geometry.all;
import graphics.color;
import util.config;

/// Wrapper around ALLEGRO_FONT
class Font {
  /// return the size the passed string would have if rendered in this font
  Rect2i textSize(string text) {
    int bbx, bby, bbw, bbh, ascent, descent;
    al_get_text_dimensions(_font, toStringz(to!string(text)), &bbx, &bby, &bbw, &bbh, &ascent, &descent);
    return Rect2i(bbx, bby, bbw, bbh);
  }

  int widthOf(string[] text) {
    return reduce!((a, b) => a + widthOf(b))(0, text);
  }

  int heightOf(string[] text) {
    return reduce!((a, b) => max(a, heightOf(b)))(0, text);
  }

  /// return the width the passed string would have if rendered in this font
  int widthOf(string text) {
    return al_get_text_width(_font, toStringz(text));
  }

  /// return the height the passed string would have if rendered in this font
  int heightOf(string text) {
    return textSize(text).height;
  }

  /// draw text at the given vector position in the given color
  void draw(T)(T text, Vector2i pos, Color color = Color.black) if (is(typeof(to!string(T.init)) : string)) {
    al_draw_text(_font, color, pos.x, pos.y, 0, toStringz(to!string(text)));
  }

  void drawCentered(T)(T text, Vector2i pos, Color color = Color.black) if (is(typeof(to!string(T.init)) : string)) {
    auto s = to!string(text);
    auto textArea = Rect2i.CenteredAt(pos, widthOf(s), heightOf(s));
    al_draw_text(_font, color, textArea.x, textArea.y, 0, toStringz(s));
  }

  /// draw multiple lines of text at position pos
  void draw(string[] lines, Vector2i pos, Color color = Color.black) {
    foreach(line ; lines) {
      draw(line, pos, color);
      pos.y += heightOf(line);
    }
  }

  void drawCentered(string[] lines, Vector2i pos, Color color = Color.black) {
    foreach(line ; lines) {
      auto textArea = Rect2i.CenteredAt(pos, widthOf(line), heightOf(line));
      al_draw_text(_font, color, textArea.x, textArea.y, 0, toStringz(line));
      pos.y += textArea.height;
    }
  }

  /// return an array of text lines wrapped at the specified width (in pixels). Split text elements on whitespace
  string[] wrapText(string text, int maxLineWidth) {
    string currentLine;
    string[] lines;
    foreach(word ; filter!(s => !s.empty)(splitter(text))) {
      if (widthOf(currentLine ~ word) > maxLineWidth) {
        lines ~= stripRight(currentLine);
        currentLine = word ~ " ";
      }
      else {
        currentLine ~= (word ~ " ");
      }
    }
    return lines ~ currentLine; // make sure to append last line
  }

  ~this() {
    al_destroy_font(_font);
  }

  private:
  ALLEGRO_FONT* _font;

  this (ALLEGRO_FONT* font) {
    _font = font;
  }
}

private Font[string] _fontStore;

Font getFont(string name) {
  assert(name in _fontStore, "font named " ~ name ~ " has not been loaded");
  return _fontStore[name];
}

static this() {
  auto fontData = loadConfigFile(Paths.fontData);
  auto fontDir = fontData.globals["font_dir"];
  foreach (fontName, fontInfo; fontData.entries) {
    auto path = toStringz(fontDir ~ "/" ~ fontInfo["filename"]);
    auto size = to!int(fontInfo["size"]);
    auto font = al_load_font(path, size, 0);
    assert(font, "could not load font from file " ~ to!string(path));
    _fontStore[fontName] = new Font(font);
  }
}
