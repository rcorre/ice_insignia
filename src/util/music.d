module util.music;

import std.conv;
import std.string;
import allegro;
import util.config;

alias Sample = ALLEGRO_SAMPLE*;
alias SampleInstance = ALLEGRO_SAMPLE_INSTANCE*;

void setMusicMute(bool mute) {
  _muted = mute;
  if (mute && _musicSample !is null) {
    al_stop_sample(&_id);
  }
  else if (!mute && _musicSample !is null) {
    al_play_sample(_musicSample, _gain, 0f, 1f, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP, &_id);
  }
}

// TODO: use audio streams?
void playBgMusic(string key) {
  if (_muted) { return; }
  if (_instance !is null) {
    al_destroy_sample_instance(_instance);
  }
  if (_musicSample !is null) {
    al_destroy_sample(_musicSample);  // also stops playing the sample
  }
  assert(key in _musicPaths, "no music for key " ~ key);
  _musicSample = al_load_sample(_musicPaths[key].toStringz);
  assert(_musicSample !is null, "failed to load music sample " ~ key);
  _instance = al_create_sample_instance(_musicSample);
  assert(_instance !is null, "failed to load music instance for " ~ key);
  al_set_sample_instance_playmode(_instance, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
  al_attach_sample_instance_to_mixer(_instance, al_get_default_mixer());
  al_play_sample_instance(_instance);
  //al_play_sample_instance(_musicSample, _gain, 0f, 1f, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP, &_id);
}

private:
Sample _musicSample;
SampleInstance _instance;
string[string] _musicPaths;
float _gain;
bool _muted;
ALLEGRO_SAMPLE_ID _id;

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
  if (_instance !is null) {
    al_destroy_sample_instance(_instance);
  }
}
