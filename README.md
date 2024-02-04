# CC:Tweaked Player Tracker
This is a small project i made for ComputerCraft, it uses the mod Advanced Peripherals to find the location and direction of players.

# Installation
To install just run this command on your CC device.
```
wget run https://raw.githubusercontent.com/BeastWalnut/CC-PlayerTracker/master/install.lua
```
I recomment adding this line at the start of your startup.lua file.
```lua
shell.setAlias("tracker", ".tracker/app.lua")
```
If you want it to run on start then you can add this after.
```lua
shell.run(".tracker/app.lua")
```
