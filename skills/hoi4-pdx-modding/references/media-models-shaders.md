# Media, models, and shaders

These rules were rechecked against installed HOI4 1.19.2 on 2026-07-17. The
content-builder skill contains copyable `.asset` and music skeletons.

## Music

The minimal current chain is:

```text
music/<file>.asset: music name -> .ogg file
music/<file>.txt: song name -> music station and chance
localisation/<language>/<file>.yml: song name -> visible title
```

Current `music/music.asset` uses `music = { name file volume }`; current
`music/_songs.txt` sets `music_station = "base_music"` and registers each
`music = { song chance = { modifier = { factor ... } } }`. Use the
`assets/kits/music-track` kit when a separate station is unnecessary. A custom
station additionally needs station localisation and current music-player GUI
faceplate/entry resources, so it is not a rename-only extension of the track
kit.

Verify the actual OGG decodes, the relative path and case match, chance
conditions have the intended country scope, the song appears in the player,
and both peace/war paths are audible as designed.

### Ogg container and codec contract

`.ogg` names the container, not the audio codec. Probe every candidate with a
tool such as `ffprobe` and record `codec_name`, sample rate, channel layout,
duration, stream count, and attached-picture/data streams. Renaming an Opus
stream to `.ogg` does not make it Vorbis.

Runtime evidence for HOI4 1.19.2 establishes a consumer split:

- Ogg Opus reached the frontend and played when used as main-menu/loading
  music;
- the same codec did not play through the in-game music player/station;
- therefore frontend success does not prove station compatibility.

For portable release music that appears in the in-game player, use Ogg Vorbis.
Use `44100 Hz` unless an exact current consumer proves another rate; current
game logs recommend 44.1 kHz for music. Treat Opus as an exact-consumer
experiment, never as a blanket replacement for a Vorbis music library.

Prefer a purchased or otherwise lawful lossless source such as FLAC and encode
once. Re-encoding an existing MP3 or Vorbis file cannot restore quality and
adds generation loss. Map only the intended audio stream and strip covers,
video, subtitles, data, chapters, and source metadata. A representative
conversion shape is:

```text
ffmpeg -i source.flac -map 0:a:0 -vn -sn -dn -map_metadata -1 -map_chapters -1 -c:a libvorbis -q:a <measured-quality> -ar 44100 output.ogg
```

Preserve the intended mono/stereo layout. Fully decode the result and confirm
that the container has one audio stream and no attached picture or other
payload. Vorbis quality levels are quality controls, not promised bitrates or
file sizes: a q5/q6 encode may be larger than an existing aggressively
compressed file. Compare duration, audible quality, actual bytes, and the
complete library budget before accepting a batch.

Test main-menu music and the in-game station as separate consumers. For a
station change, enter a campaign, open the player, play the changed track,
advance to and from it, let it finish or loop as designed, and inspect a fresh
log. Preserve originals and a source-to-output manifest outside the release
mod so a failed batch can be restored without another lossy encode.

## Models, animations, and entities

The minimal current shapes are:

```pdx
animation = {
	name = "MOD_idle_animation"
	file = "MOD_idle.anim"
}

entity = {
	name = "MOD_entity"
	pdxmesh = "MOD_mesh"
}
```

An entity state may bind a named animation, but the names available to the mesh
depend on the exported asset. Do not add guessed state names, locators, particle
nodes, or animation aliases to the generic template. Trace:

```text
.mesh/.anim export -> animation registration -> entity -> graphical culture,
equipment, building, landmark, or GUI consumer
```

Check mesh/material texture paths, animation names, locator names, entity
fallbacks, DLC gates, and the exact consumer. Static text validation cannot
prove that a mesh renders or an animation rig matches.

## Shaders

Current `gfx/FX/*.shader` files are complete programs with includes, sampler
bindings, vertex structures, constant buffers, vertex/pixel shader code,
blend/depth/rasterizer state, and engine-specific compile declarations. There
is no safe universal shader skeleton.

When a shader change is necessary:

1. Start from the smallest current vanilla shader with the same render pass and
   vertex input, not an old tutorial shader with a similar visual result.
2. Keep include names, sampler slots, semantics, compile targets, and render
   state aligned with that consumer. Rename only symbols whose callers are also
   updated.
3. Compare the complete file after every game update. Inspect `error.log` and
   graphics logs, then exercise every UI/map state that selects the shader.
4. Treat a successful HLSL syntax check as partial evidence; only the game can
   prove Clausewitz/Jomini bindings and runtime permutations.

## Texture and codec gate

Do not repeat fixed format folklore from community guides. Verify the format
used by the current adjacent vanilla asset, preserve alpha and mipmap needs,
check dimensions expected by the consumer, and inspect the rendered result in
game. Frontend background and thumbnail filenames are fixed by their database
and GFX registrations even when the image authoring tool is flexible.

Loading screens are a confirmed exception to general PNG-capable GFX paths:
keep `gfx/loadingscreens` full-size backgrounds and thumbnails as DDS. In a
1.19.2 in-game test, pixel-identical RGBA PNG replacements failed even after
the explicit `.gfx` texture paths were updated. Do not propose PNG conversion
as a loading-screen size optimization; optimize a DDS using the compression,
alpha, mipmap, and quality contract verified for the target consumer instead.
