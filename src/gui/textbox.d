module gui.textbox;

import graphics.all;
import geometry.all;

class Textbox {
  this(Vector2i pos, string text, string fontName, Color textColor = Color.black, 
      Color bgColor = Color.clear) 
  {
    _font = getFont(fontName);
    _text = text;
    _area = Rect2i.CenteredAt(pos, _font.widthOf(text), _font.heightOf(text));
    _textColor = textColor;
    _bgColor = bgColor;
  }

  @property {
    string text() { return _text; }
    void text(string s) { 
      _text = s;
      _area = Rect2i.CenteredAt(_area.center, _font.widthOf(s), _font.heightOf(s));
    }
  }

  void draw() {
    _area.drawFilled(_bgColor);
    _font.drawCentered(_text, _area.topLeft, _textColor);
  }

  private:
  Font _font;
  string _text;
  Rect2i _area;
  Color _textColor, _bgColor;
}
