module gui.progress_bar;

import std.string : format;
import graphics.all;
import geometry.all;

class ProgressBar(T : real) {
  this(Rect2i area, T maxVal, Color bgColor, Color fgColor, Color textColor = Color.black, Font font = defaultFont,
      string fmt = "%d/%d")
  {
    _area = area;
    _filledArea = _area;
    _maxVal = maxVal;
    _font = font;
    _format = fmt;
    _bgColor = bgColor;
    _fgColor = fgColor;
    _textColor = _textColor;
    val = 0;
  }

  @property {
    void val(T val) {
      _filledArea.width = _area.width * val / _maxVal;
      _text = format(_format, val, _maxVal);
    }
  }

  void draw() {
    _area.drawFilled(_bgColor);
    _filledArea.drawFilled(_fgColor);
    _font.draw(_text, _area.center, _textColor);
  }

  private:
  Rect2i _area;       /// total bar
  T _maxVal;
  string _format;
  Font _font;
  Color _bgColor, _fgColor, _textColor;

  Rect2i _filledArea; /// area filled in
  string _text;

  static Font defaultFont() {
    return getFont("default_progress_bar_font");
  }
}
