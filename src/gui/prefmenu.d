module gui.prefmenu;

import graphics.all;
import geometry.all;
import util.all;
import gui.all;

class PreferencesMenu : StringMenu {
  this(Vector2i pos) {
    string[] selections = [ "musicVolume", "soundVolume", "showInputIcons" ];
    super(pos, selections, &onChoose, null, null, true, true);
  }

  void onChoose(string entry) {
    if (entry == "showInputIcons") {
      userPreferences.showInputIcons = !userPreferences.showInputIcons;
    }
  }

  override void handleSideMovement(string entry, int direction) {
    if (entry == "musicVolume") {
      musicVolume = musicVolume + 10 * direction;
    }
    else if (entry == "soundVolume") {
      userPreferences.soundVolume += 10 * direction;
    }
    else if (entry == "showInputIcons") {
      userPreferences.showInputIcons = !userPreferences.showInputIcons;
    }
  }

  protected override:
    void drawEntry(string entry, Rect2i rect, bool isSelected) {
      string text;
      switch (entry) {
        case "musicVolume":
          text = "Music: %3d".format(userPreferences.musicVolume);
          break;
        case "soundVolume":
          text = "Sound: %3d".format(userPreferences.soundVolume);
          break;
        case "showInputIcons":
          text = "Hints: %s".format(userPreferences.showInputIcons ? "on" : "off");
          break;
        default:
      }
      _font.draw(text, rect.topLeft);
    }
}
