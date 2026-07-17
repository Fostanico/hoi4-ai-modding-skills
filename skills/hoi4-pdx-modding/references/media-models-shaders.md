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
