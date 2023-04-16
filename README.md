# mpv-osc-crimson

This is an mpv script as the osc replacement.

This work is done with my [oscf](https://github.com/maoiscat/mpv-osc-framework) tool.

# Preview
![img](https://github.com/maoiscat/mpv-osc-crimson/Blob/main/preview.jpg)

# Install

1. Make a new folder in ''\~\~/scripts/'', such as ''\~\~/scripts/mpv-osc-crimson''.
2. Place all the 4 lua files into that folder.
3. Put the ''material-design-iconic-font.ttf'' into ''\~\~/fonts''. You can also download it [here](https://zavoloklom.github.io/material-design-iconic-font/).
4. Remove or disable other osc scripts. The built-in osc will be disabled by this script automatically.
5. Run mpv to test if it works.

# Controls

There are tow lines of controller, some of which accepts multiple mouse actions.
(MBL = mouse button left, MBR = mouse button right)

Top line:
1. Seekbar slider: MBL - seek to chosen position, MBR - seek to chosen chapter
2. Mute button
3. Volume slider

Bottom line:
1. Play pause
2. Skip back: MBL - 10 second, MBR - 30 seconds
3. Skip forward: MBL - 10 seconds, MBR - 30 seconds
4. Subtitle: MBL - next subtitle, MBR - previous subtitle
5. Audio track: MBL - next audio track, MBR - previous track
7. Playlist: MBL - next file, MBR - previous file
8. Info
9. Minimize
10. Fullscree
11. Exit

# Options

There a a few user options, which can be found in the ''opts'' section of the main.lua file

```
opts = {
  scale = 1,          -- osc render scale
	fixedHeight = false,-- true to allow osc scale with window
	hideTimeout = 1,    -- seconds untile osc hides, negative means never
	fadeDuration = 0.5, -- seconds during fade out, negative means never
	border = 1,         -- border width
	size = 26,          -- button size
	remainingTime = false,	-- true to display remaining time instead of duration in the seekbar
	maxVolume = 100,		-- maximum volume allowed by the volume slider
	}
```
