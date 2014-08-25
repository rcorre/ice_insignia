module gui.progress_bar;

import std.string : format;
import util.math : lerp;
import graphics.all;
import geometry.all;

class ProgressBar(T : real) {
  this(Rect2i area, T currentVal, T maxVal, Color fgColor, Color bgColor = Color.clear, Color textColor = Color.black,
      Font font = defaultFont, string fmt = "%d/%d")
  {
    _area = area;
    _filledArea = _area;
    _maxVal = maxVal;
    _font = font;
    _format = fmt;
    _fgColor = fgColor;
    _bgColor = bgColor;
    _textColor = textColor;
    val = currentVal;
  }

  @property {
    T val() { return _val; }
    void val(T val) {
      _val = val;
      _filledArea.width = cast(int) (_area.width * cast(float)val / _maxVal);
      _text = format(_format, val, _maxVal);
    }
    bool isTransitioning() { return _totalTransitionTime != 0; }
  }

  void update(float time) {
    if (_totalTransitionTime != 0) {
      _transitionTimer += time;
      val = _transitionStart.lerp(_transitionTarget, _transitionTimer * _totalTransitionTime);
      if (_transitionTimer > _totalTransitionTime) {
        _totalTransitionTime = 0;
      }
    }
  }

  void transition(T start, T end, float time) {
    _transitionStart = start;
    _transitionTarget = end;
    _transitionTimer = 0;
    _totalTransitionTime = time;
  }

  void draw() {
    _area.drawFilled(_bgColor);
    _filledArea.drawFilled(_fgColor);
    _font.draw(_text, _area.topLeft, _textColor);
  }

  private:
  Rect2i _area;       /// total bar
  T _maxVal, _val;
  string _format;
  Font _font;
  Color _bgColor, _fgColor, _textColor;

  Rect2i _filledArea; /// area filled in
  string _text;

  // for transition effect
  T _transitionStart, _transitionTarget;
  float _transitionTimer, _totalTransitionTime = 0;

  static Font defaultFont() {
    return getFont("default_progress_bar_font");
  }
}
