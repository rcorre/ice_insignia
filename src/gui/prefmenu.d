module gui.prefmenu;

import graphics.all;
import geometry.all;
import util.all;
import gui.all;

class PreferencesMenu : StringMenu {
  this(Vector2i pos) {
    string[] selections = [
      "Music Volume: %1.1f",
      "Sound Volume: %1.1f",
      "Control Hints: on",
    ];
    super(pos, selections, &onChoose, null, null, true, true);
  }

  void onChoose(string entry) {
    if (entry == "showInputIcons") {
    }
  }

  protected override:
  void drawEntry(string entry, Rect2i rect, bool isSelected) {
    _font.draw(entry, rect.topLeft);
  }
}
