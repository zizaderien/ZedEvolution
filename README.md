# Evolution Mod

Allows zombies to evolve various attributes over time.

Make zombies change their speed, strength, toughness, cognition, ability to crawl under cars, memory, sight, hearing, and virus transmission as a function of time, using individually adjustable settings in the sandbox options.

## Customization

### General Settings

- Turn evolution on or off.
- Set how many days you have before evolutions begins. A negative value means evolution has already begun.
- Set how evolved zombies are from the start. A negative value means zombies start "devolved".

### Evolution Function

- Set the way in which evolution progresses to be either linear, asymptotic or cyclic.
- For a linear function, you can specify how long it takes to reach 100% evolution.
- For an asymptotic function, you can specify the base value, the limit, and how long it takes to reach 50% evolution.
- For a cyclic function, you can specify how often it repeats, and between which numbers evolution fluctuates.
- [See this page for visual examples for each setting.](https://github.com/Kayliii/ZedEvolution/wiki/Functions)

### Evolution Limits

- Set how strong or weak zombies can get compared to the zombie lore settings.
- Transmission is hard capped at "Blood + Saliva" and cannot become "Everyone's Infected".

### Evolution Factor

- Set how quickly zombies evolve certain attributes compared to others.
- Set the factor to a negative number to make zombies weaker.
- Set the factor to 0 to stop zombies from evolving this attribute.

### Deviation Factor

- Set how evolution of certain attributes is distributed across the zombie population.
- Half of zombies will be affected less than the given percentage, and half will be affected more.
- As the percentage approaches 0% or 100%, zombies become more similar.
- As the percentage approaches 50%, zombies become more diverse.

### Zombie Lore

- Any attributes set to "Random" are unaffected by evolution.
- Transmission is unaffected by evolution if set to "Everyone's Infected".

## Contribute

If you want to contribute translations, please fork the repo, commit your translation, and open a pull request.

Your translation needs to go in `ZedEvolution/Contents/mods/ZedEvolution/media/lua/shared/Translate/LANGUAGE_NAME/`.

## Support

**This mod is in an experimental state!** Be aware that you may run into issues. If you report issues with the mod I can try to fix them!

### Known Incompatible Mods

[Full compatibility list](https://github.com/Kayliii/ZedEvolution/wiki/Compatibility-with-other-mods)

Any mod not on this list that you're curious about? Let me know!

## Links

[Mod on Steam  Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2729417044)
