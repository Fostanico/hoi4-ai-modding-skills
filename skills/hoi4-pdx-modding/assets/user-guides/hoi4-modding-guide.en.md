# User Guide: HOI4 Mod Development and Visual Effects

[简体中文](hoi4-modding-guide.zh-CN.md) | English

These skills help an AI turn your ideas into a Hearts of Iron IV mod. Describe what players should see, what should happen when they click, and what existing content must stay. You do not need to learn PDX scripting or shader programming first.

## What can you make?

| Your idea | Work you can ask the AI to do |
|---|---|
| Countries and stories | Countries, characters, events, decisions, focuses, national spirits, and the conditions and effects connecting them |
| Character systems | Recruitment, route choices, affection rules, character profiles, leaders, and generals |
| Gameplay systems | Minigames with defined rules, collections and unlocks, multistage tasks, resource tracking, and persistent state |
| Custom interfaces | Startup screens, character cards, recruitment windows, guides, buttons, dynamic text, and multilingual layouts |
| Visual effects | Animated portraits, light beams and petals, scans and signal interference, holographic cards, decorative globes, and button feedback |
| Asset integration | Registering and adapting images, frame animations, models, sound effects, and music |
| Existing-mod maintenance | Investigating errors, tracing connections between files, diagnosing compatibility problems, maintaining documentation, and preparing releases |

The implementation depends on your game version, project, and the interfaces the engine exposes. The AI should check those first and choose an approach that can actually be integrated.

## What do shaders add?

A shader can make a static image change over time in the game. It calculates the appearance from time, image data, and interface state, so you do not need to produce a video for every moving light or particle.

| Effect | What players see | Suitable uses |
|---|---|---|
| Soft beams and light particles | Light passes across the image while small particles drift slowly | Recruitment reveals, weddings, birthdays, and anniversary events |
| Window light and petals | Light enters through a window pattern while petals fall across the picture | Story illustrations and animated super events |
| Memory scans | Scan bands, subtle color separation, data fragments, and signal distortion | PARQUET themes, memory transfers, and communication terminals |
| Holographic character cards | A card tilts in perspective, with iridescence and glitter that change with its angle | Character collections, recruitment presentations, and achievement cards |
| Animated startup screens | Subtle portrait motion, lighting on titles and buttons, and reading pages that give text room | Welcome screens and update pages that fit the mod's style |
| Hover feedback | Text changes color, a border lights up, or a small character jumps when hovered | Choice buttons, navigation, and small interactive decorations |
| Decorative globes | A flat map appears as a rotating sphere inside a window | War rooms, story briefings, and worldbuilding displays |

**A startup-UI build in the test project passed user testing in the game on October 10, 2026.** Existing handoff records also report successful user trials of the animated super-event and holographic-card examples. Changing assets, layout, or game version calls for checks appropriate to those changes. One accepted example does not establish that every effect or later revision works.

## Ideas for the Yuzusoft Generals Pack

- Give each character an appropriate entrance: warm shrine light, a technological scan, or an archival ink-and-paper reveal.
- Add restrained motion to relationship stories and commemorative super events, using light, petals, or particles over existing illustrations.
- Present a character collection as a holographic card album. Hovering gives feedback; clicking opens a profile or recruitment interface.
- Use a startup screen with separate pages for updates, gameplay guidance, and credits, keeping the reading area quiet and legible.
- Build a multistage memory-restoration interface for PARQUET. Scripts manage the rules and outcomes while the visuals reflect each stage.

A card that looks like a gacha reveal does not automatically implement probabilities, a pity system, or recruitment. Describe the presentation and the actual rules together so the AI can connect the button to the intended behavior.

## Which ideas need further checks?

**A spherical world map and a globe inside a window are different features.** A window globe is suitable for display. Reshaping the playable world map also affects province selection and command input. In the Globe Mod studied here, user testing found click inaccuracies that increased with camera height and distance from the screen center. The visual transformation alone does not fix that mismatch.

**A tilted card may still have a fixed clickable area.** If you need its angle to follow the exact pointer position, or clicks outside its visible outline to be rejected, state those interaction requirements explicitly so the AI can verify engine support.

**A looping animation does not necessarily restart when the window opens.** Mention any need for a one-time reveal, precise audio synchronization, or replay. Those require timing behavior beyond a continuously drifting background.

**Frosted glass may use an image that was blurred in advance.** This works for a fixed backdrop. Blurring the live game map behind a window requires a separate check of engine support.

Effects also have a performance cost. For a gentle atmosphere, ask for fewer particles, low intensity, and a static fallback or an option to turn the effect off.

## How to describe your request

These details are usually enough:

1. **Project and game version:** which mod to edit, and whether it is a test project or a production release.
2. **Player experience:** how to open it, what appears, and what each click does.
3. **Available assets and boundaries:** which images may be used, which directories are off limits, and which originals must be preserved.
4. **Style and intensity:** gentle, technological, vintage, or another direction; subtle atmosphere or a prominent reveal.
5. **Actual rules:** recruitment, costs, unlocks, saved progress, or presentation only.
6. **Testing:** whether you will test in the game yourself, or an authorized AI with native application control should do it.

Adapt these examples to your own assets and content:

> Make a character introduction window in my test mod using an existing portrait, soft warm light, and a few drifting particles. Keep button positions fixed. Include an original-image comparison and a close button. Confirm should only close the window; it must not recruit anyone or charge anything. Preserve the source assets.

> Give the startup interface a home page and reading pages. Emphasize the character on the home page and the text on reading pages. Add subtle light effects on button hover. Keep decorations clear of the face and body text, and preserve the existing three languages and functions.

> Design three memory-repair interface concepts for PARQUET, choose one, and implement it in the test mod. Specify the choice rules, success and failure conditions, and what happens when the interface is reopened. Use scanning and reconstruction effects to show stage changes. Deliver the working interface, not just shader code.

> Add a red-text hover effect to the existing recruitment choices while keeping the background and border as they are. Check the longest Chinese, Japanese, and English options, and preserve the existing route logic.

## What should you receive?

A complete example should have an accessible entry point, all required files, valid asset references, buttons and text, a way to close it, and brief usage instructions. The AI should explain what changed, how to try it, and which checks it completed.

Distinguish three kinds of evidence: code checks passed, a browser or other offline preview looked correct, and the feature actually worked in the game. The first two can catch problems but cannot replace the third. An in-game check can be brief: open the interface, inspect the effect, use the buttons, close and reopen it, and check the behavior affected by the change.

If you only want to understand the possibilities, share this guide with other developers. When you are ready to build, ask the AI to use the technical guides and examples inside the skills. You do not need to read or organize those implementation details yourself.
