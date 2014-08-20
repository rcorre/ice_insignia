module gui.selection_view;

import std.algorithm : max;
import graphics.all;
import geometry.all;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

class SelectionView {
  alias Action = void delegate();
  this(Vector2i pos, Action[string] selections) {
    auto selectionArea = Rect2i(pos.x, pos.y, 0, 0);
    auto totalArea     = Rect2i(pos.x, pos.y, 0, 0);
    foreach(text, action; selections) {
      selectionArea.width  = _font.widthOf(text);
      selectionArea.height = _font.heightOf(text);

      Selection sel;
      sel.onClick = action;
      sel.text = text;
      sel.clickArea = selectionArea;
      sel.drawPos = selectionArea.topLeft;
      _selections ~= sel;

      int offset = selectionArea.height + spacingY;
      selectionArea.y += offset;
      totalArea.height += offset;
      totalArea.width = max(totalArea.width, selectionArea.width);
    }
    _totalArea = totalArea;
  }

  void draw() {
    _totalArea.draw();
    foreach(selection ; _selections) {
      selection.draw();
    }
  }

  private:
  Rect2i _totalArea;
  Selection[] _selections;

  struct Selection {
    Action onClick;
    string text;
    Rect2i clickArea;
    Vector2i drawPos;

    void draw() {
      _font.draw(text, drawPos);
    }
  }

  static Font _font;
  static this() {
    _font = getFont(fontName);
  }
}
