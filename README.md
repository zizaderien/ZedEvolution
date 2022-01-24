# Evolution Mod

Allows zombies to evolve various attributes over time.

Make zombies change their speed, strength, toughness, cognition, ability to crawl under cars, memory, sight, hearing, and virus transmission as a function of time, using individually adjustable settings in the sandbox options.

## Customization

- The "Evolution Factor" setting determines the overall pace of evolution. Setting it to 1 makes evolution take place over the course of about a month.
- The "Evolution Delay" setting will start a countdown of however many days are entered there and start evolution after that. This number can be negative to make evolution begin before the game starts.
- The "Starting Progression" setting will preemptively apply the given number of days worth of evolution as a baseline. This number can be negative to make zombies start "devolved" compared to the provided settings.
- Individual attributes can be customized using their multipliers. A multiplier of 0 means the attribute never changes. >0 means zombies become better at it. <0 means zombies become worse at it. The greater the number, the quicker they evolve.
- Any settings that are set to "Random" are unaffected by evolution.
- Transmission evolves from "None" -> "Blood" -> "Blood + Saliva". It does not progress towards "Everyone's Infected."
- All vanilla zombie lore settings are treated as baseline attributes. When the evolution of your world is 0 (usually at the beginning), they will behave according to those settings.
- Zombie population growth is already possible using the vanilla settings, so this mod does not have any custom settings for it.

## Contribute

If you want to contribute translations, please fork the repo, commit your translation, and open a pull request.

Your translation needs to go in `ZedEvolution/Contents/mods/ZedEvolution/media/lua/shared/Translate/LANGUAGE_NAME/`.

## Links

[Mod on Steam  Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2729417044)
