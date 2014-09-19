module util.sound;

import std.string;
import std.conv;
import std.file;
import allegro;
import util.config;

enum Playmode {
  once  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE,
  loop  = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP,
  bidir = ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_BIDIR
}

class SoundSample {
  this(string key) {
    assert(key in _soundData.entries, "could not find sound data for " ~ key);
    auto data = _soundData.entries[key];
    auto path = toStringz(_soundDir ~ data["file"]);
    assert(path.to!string.exists, "no sound file at " ~ path.to!string);
    _sample = al_load_sample(path);
    assert(_sample !is null, "failed to load sound " ~ path.to!string);
    _gain   = to!float(data.get("gain", "1"));
    _speed  = to!float(data.get("speed", "1"));
    _pan    = to!float(data.get("pan", "0"));
    _loop   = to!Playmode(data.get("loop", "once"));
  }

  void play() {
    bool ok = al_play_sample(_sample, _gain, _pan, _speed, _loop, &_id);
    assert(ok, "a sound sample failed to play");
  }

  void stop() {
    al_stop_sample(&_id);
  }

  static void stopAll() {
    al_stop_samples();
  }

  private:
  ALLEGRO_SAMPLE* _sample;
  ALLEGRO_SAMPLE_ID _id;
  float _gain, _speed, _pan;
  Playmode _loop;
}

private:
ConfigData _soundData;
string _soundDir;

static this() {
  _soundData = loadConfigFile(Paths.soundData);
  _soundDir = _soundData.globals["soundDir"];
}
