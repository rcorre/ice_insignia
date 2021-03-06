module gui.string_menu;

import graphics.all;
import geometry.all;
import gui.selection_menu;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

/// display a list of string options
class StringMenu : SelectionMenu!string {
  this(Vector2i pos, string[] selections, Action onChoose, HoverAction onHover = null, 
      InputString inputString = null, bool focus = true, bool showCancel = true) 
  {
    super(pos, selections, onChoose, onHover, inputString, focus, showCancel);
  }

  protected override:
  void drawEntry(string entry, Rect2i rect, bool isSelected) {
    _font.draw(entry, rect.topLeft);
  }

  int entryWidth(string entry) { return _font.widthOf(entry); }
  int entryHeight(string entry) { return _font.heightOf(entry); }
}
