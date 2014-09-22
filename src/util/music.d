module util.music;

import std.conv;
import std.string;
import allegro;
import util.config;

alias Sample = ALLEGRO_SAMPLE*;

// TODO: use audio streams?
void playBgMusic(string key) {
  if (_musicSample !is null) {
    al_destroy_sample(_musicSample);  // also stops playing the sample
  }
  assert(key in _musicPaths, "no music for key " ~ key);
  _musicSample = al_load_sample(_musicPaths[key].toStringz);
  assert(_musicSample !is null, "failed to load music sample " ~ key);
  ALLEGRO_SAMPLE_ID id;
  al_play_sample(_musicSample, _gain, 0f, 1f, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP, &id);
}

private:
Sample _musicSample;
string[string] _musicPaths;
float _gain;

static this() {
  auto musicData = loadConfigFile(Paths.musicData);
  string musicDir = musicData.globals["musicDir"];
  foreach(key , data ; musicData.entries) {
    auto path = musicDir ~ data["file"];
    assert(path, "no music file at " ~ path);
    _musicPaths[key] = path;
  }
  _gain = musicData.globals.get("gain", "1").to!float;
}

static ~this() {
  if (_musicSample !is null) {
    al_destroy_sample(_musicSample);
  }
}
