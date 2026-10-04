# Third-party assets and code

Every asset and library in this repository that we did not make ourselves is
listed here, so licensing can be arranged properly before release. Add a row
when you add a file. Remove the row when the file is gone. Keep the license
text next to the files when the license requires it.

| Asset or library | Author | Source | License | Files in repo | Modifications |
|------------------|--------|--------|---------|---------------|---------------|
| gdUnit4 6.2.1 | Mike Schulze | https://github.com/MikeSchulze/gdUnit4 | MIT | addons/gdUnit4/ | none |
| Inter 4 (Regular, SemiBold, Black) | Rasmus Andersson | https://rsms.me/inter | SIL Open Font License 1.1, text in assets/fonts/LICENSE-inter-ofl.txt | assets/fonts/Inter-*.ttf | none |
| Kenney Car Kit 3.1 | Kenney Vleugels | https://kenney.nl/assets/car-kit | CC0 1.0 | assets/models/car-kit/ (kart-*.glb, Textures/colormap.png) | none |
| Kenney Casino Audio 1.1 | Kenney Vleugels | https://kenney.nl/assets/casino-audio | CC0 1.0 | assets/audio/sfx/chip-*, chips-*, dice-*, card-* | none |
| Kenney Impact Sounds | Kenney Vleugels | https://kenney.nl/assets/impact-sounds | CC0 1.0 | assets/audio/sfx/impact* | none |
| Kenney Interface Sounds | Kenney Vleugels | https://kenney.nl/assets/interface-sounds | CC0 1.0 | assets/audio/sfx/click_*, confirmation_*, bong_*, glass_*, drop_*, maximize_*, open_*, select_*, switch_*, tick_*, error_*, pluck_*, back_*, question_* | none |
| "Electronic Vol8 Deceased Rodent" Intensity 1, Intensity 2, Main (Electronic Music Pack Vol. 8) | Ovani Sound | https://ovanisound.com | Ovani Sound terms of service, https://ovanisound.com/policies/terms-of-service; licensed to the developer, not covered by the project licenses, check redistribution before publishing the repository | assets/audio/music/deceased_rodent/*.ogg | transcoded from WAV to OGG Vorbis 160 kbit/s, cut to the 88 s loop (44 bars at 120 BPM) with the 4 s decay tail mixed under the start so the loop is seamless |
| "Electronic Vol8 Ginger Bread" Intensity 1, Intensity 2, Main (Electronic Music Pack Vol. 8) | Ovani Sound | https://ovanisound.com | Ovani Sound terms of service, https://ovanisound.com/policies/terms-of-service; licensed to the developer, not covered by the project licenses, check redistribution before publishing the repository | assets/audio/music/ginger_bread/*.ogg | transcoded from WAV to OGG Vorbis 160 kbit/s; the pack's own 93.75 s loop (50 bars at 128 BPM) used as delivered |
| "Electronic Vol8 Let It Breathe" Intensity 1, Intensity 2, Main (Electronic Music Pack Vol. 8) | Ovani Sound | https://ovanisound.com | Ovani Sound terms of service, https://ovanisound.com/policies/terms-of-service; licensed to the developer, not covered by the project licenses, check redistribution before publishing the repository | assets/audio/music/let_it_breathe/*.ogg | transcoded from WAV to OGG Vorbis 160 kbit/s; the pack's own 88.24 s loop (50 bars at 136 BPM) used as delivered |
| Racing Sound Pack | Cascadia Games | https://cascadiagames.itch.io/racing-sound-pack | "These sounds may be used in your game projects, but may not be resold as assets or included in other asset packs"; licensed to the developer, not covered by the project licenses, check redistribution before publishing the repository | assets/audio/kart/*.ogg | the twelve files we use, downmixed to mono for positional playback and peak normalized; the engine and tire loops have their tail folded under their head so they loop without a seam; nitro_swell.ogg is crash_end.ogg reversed. Rebuilt from the pack by tools/make_kart_audio |
| Material Symbols "touch_app" (Rounded, filled) | Google | https://github.com/google/material-design-icons | Apache License 2.0, text in assets/icons/LICENSE-material-symbols-apache.txt | assets/icons/touch_app.svg | fill set to white, so the game tints it to the hint's ink |
