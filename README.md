# Evolution Mod

Allows zombies to evolve various attributes over time.

Make zombies change their speed, strength, toughness, cognition, ability to crawl under cars, memory, sight, hearing, and virus transmission as a function of time, using individually adjustable settings in the sandbox options.

## Customization

### Evolution Factor

- The main "Evolution Factor" setting determines the overall pace of evolution. Setting it to 1 makes evolution take place over the course of about a month.
- Individual attribute factors can be customized using multipliers. 
- A multiplier of 0 means the attribute never changes. >0 means zombies become better at it. <0 means zombies become worse at it. 
- If the number is between -1 and 1, zombies evolve this attribute slower than usual. If the number is >1 or <-1, they evolve faster.

### Evolution Deviation

- The main "Evolution Deviation" setting determines how strongly most zombies are affected by evolution.
- Individual attribute deviation can be customized using multipliers.
- If the deviation is at 100%, all zombies are maximally affected by evolution. If the deviation is at 0%, no zombies are affected by evolution at all.
- For any value <50%, evolved zombies are progressively more rare. For any value >50%, unevolved zombies are progressively more rare. A value of 50% has an even distribution.

### Evolution Cap

- All vanilla zombie lore settings are treated as baseline attributes. When the evolution of your world is 0 (usually at the beginning), they will behave according to those settings.
- Attribute caps indicate how much stronger or weaker zombies can become compared to their baseline.
- If the main evolution factor or attribute factor are below 0, zombies get weaker. Therefore the cap should be weaker than your zombie lore setting, or zombies won't change. If they're both below 0, the minus signs cancel out.
- Transmission evolves from "None" -> "Blood" -> "Blood + Saliva". It does not progress towards "Everyone's Infected."

### Misc.

- Any zombie lore settings that are set to "Random" are unaffected by evolution.
- The "Evolution Delay" setting will start a countdown of however many days are entered there and start evolution after that. This number can be negative to make evolution begin before the game starts.
- The "Starting Progression" setting will preemptively apply the given number of days worth of evolution as a baseline. This number can be negative to make zombies start "devolved" compared to the provided settings.

## Contribute

If you want to contribute translations, please fork the repo, commit your translation, and open a pull request.

Your translation needs to go in `ZedEvolution/Contents/mods/ZedEvolution/media/lua/shared/Translate/LANGUAGE_NAME/`.

## Support

This mod is in an experimental state, so be aware that you may run into issues. Please report issues with the mod so I can look into them!

### Known Incompatible Mods

The mods listed below may cause issues or unpredictable behaviour when used in combination with the Evolution mod.

- Xeph Zombie Modifications [Official].
- A harder zombie mod.
- Customizable Zombies.

## Links

[Mod on Steam  Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2729417044)
