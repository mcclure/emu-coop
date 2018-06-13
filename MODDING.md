Emu-coop works currently with Zelda 1 and 3, but it's designed as a general system for describing the memory layout of a game and synchronizing memory accordingly. In principle, it should be possible to add support for any emulated game to emu-coop. You can do this by editing the ".lua" text files that come with it.

# Basics

## Mode files

Emu-coop comes with a `modes` directory. Each file in this directory contains one "game mode". If you want to add support for a new game, add a new "game mode" file.

You can install multiple modes for the same game; if you do, emu-coop will ask you which mode you want to use.

## Lua

The mode files, and emu-coop itself, are written in a programming language called "Lua". It will help if you know Lua, but even if you can't program you can still edit the Lua files. All you need to know is that Lua files contain three main types of values: **numbers**, **strings** and **tables**.

* **Numbers** are just numbers written in the normal way, like `3`. If you need to write a [hexadecimal](https://en.wikipedia.org/wiki/Hexadecimal) number, put `0x` first, like `0xA`.
* **Strings** are between quotation marks, like `"Blah"`.
* **Tables** are lists of things in between {brackets} and separated by commas.
    * Tables can be lists, like `{1, 2, "three", 4}`.
    * Tables can also be dictionaries that map "keys" to "values": 
        * `{one=1, two=2, three=3}` would map the key "one" to 1, the key "two" to 2, and the key "three" to 3.
        * If you need a key to be a number, you put it in [brackets]. So `{[1]="one", [2]="two", [0x3]="three"}` would map the key 1 to the string "one", the key 2 to the string "two", and the key 3 to the string "three".

Lua files are **programs**, like a .exe file. If you install a mode file, or copypaste Lua into emu-coop, **make sure you know and trust the person you got it from**.

## Debugging

Normally you run emu-coop by running the file `coop.lua`. But if instead you run `debug.lua`, It will print extra information and error messages. This can be helpful if you are making a new mode.

# Making a game mode

## Installing a new game mode

To add support for a new game, you will need a "mode file". Put the mode file in the `modes/` directory, then edit `the index.lua` file in `modes/` to add your new mode to the table there. For example if you added a file named `noahs_ark_3d.lua`, you would need to add a line saying `require "modes.noahs_ark_3d",`.

Yes, this part is really inconvenient. Sorry.

## Creating a mode: The easy version

The quick way to make a mode is to just make a copy of `lttp.lua` and change a few things.

Set the "guid" key to a new GUID generated with [this website](https://www.guidgenerator.com/online-guid-generator.aspx). Set the "name" to whatever your new game/mode is. You'll see a "match" line; replace the letters `ZELDANODENSETSU` with the tag from your game's ROM header. (Every SNES game has a string containing the name of the game at `0xFFC0` which contains the game's name; on the NES, this still works, but you'll need to change `0xFFC0` to `0xFFEB`). Remove the "running" line for now. (You can use "running" to set a condition so the game only syncs while you're playing and not during menus and stuff, but you might not need that for your game.)

Now you just need to set up the sync table. The sync table is a list of memory addresses to sync, and a rule for each one describing what to do when the sync happens. The simplest example of a rule would be a line that says

    [0x7EF34A] = {},

This means, when the memory address `0x7EF34A` changes, send it to your partner and they will change `0x7EF34A` on their side to match, no questions asked.

Probably you want a message displayed on your partner's side when this happens, so add a "name" key to the rule:

    [0x7EF34A] = {name="Lantern"},

This will make it print "Partner got the Lantern" on the screen when it syncs.

There's one more thing, which is that you probably don't **always** want to sync. For example, say there's a memory address that's always supposed to only go up (experience points, maybe). Say player A sets this to 3 at the same time player B sets this to 4. You want to ignore the 3 and set both values to 4. You can arrange this by setting the sync "kind":

    [0x7EF34A] = {name="Lantern", kind="high"},

The "high" kind will always take the higher value and ignore the lower one. Other "kinds" include "bitOr", which always takes the bitwise-OR of values (this is good for bit flags), or "delta", which is what you should use if changes should be "added" or "subtracted" (for example, if player A goes from 0 to 3 and player B goes from 0 to 4, the final value will be 7; if player A goes from 8 to 6 and player B goes from 8 to 12, the final value will be 10).

Just setting these basic keys will let you do a lot of things. If you need to do something more complicated, see the full list of keys and values below.

## Mode table

Each mode file will end with the word `return` followed by a table.

The value returned by the mode file is a mode table. The mode table has the following **required** keys:

* **guid** *type: string*

    This is a unique string that identifies the contents of the current mode file. When two copies of emu-coop connect, they will compare the mode GUIDs; if the GUIDs differ, they will refuse to connect. **Any time you change a mode file**, you should go to [this online GUID generator](https://www.guidgenerator.com/online-guid-generator.aspx) and insert a new GUID.

* **format** *type: string*

    This is the version of the mode file format you are using. Use "1.2", which is the version described in this document.

* **name** *type: string*

    This is the name of the mode. Normally this should just be the name of the game, but if you install multiple mode files for one game, you should make sure they have different names.

And the following **optional** keys:

* **match** *type: cond table (see below)*

    This describes whether the current ROM "matches" this mode file. When emu-coop boots it decides which mode to use by checking the "match" for each installed mode file to see if it can be run with the game.

* **running** *type: cond table (see below)*

    This describes whether the current ROM is "running"-- I.E. are you "playing the game" or are you in a pause menu or the title screen or something. Syncing does not occur when the "running" condition is false. This is important because some games set memory to garbage values when they are at the title screen.

* **sync** *type: sync table (see below)*

* **custom** *type: custom message table (see below)*

* **startup** *type: function*

    This is a function that gets called once, on the first frame that the **running** condition is true. The function takes one argument, `forceSend`. This is `true` if the user checked the "restarting after a crash" box.

* **tick** *type: function*

    This is a function that gets called once per vertical blank (but only if **running** condition is true).

## Sync table

The sync table is a mapping of memory addresses to sync rules. Each sync rule is a table, and that table has the following keys (all optional):

* **kind** is really important because it tells emu-coop "how to sync". It can be any of:
    * *nil*

        If "kind" is absent, emu-coop will just sync this memory address directly-- it will always be sent, and when a sync request is received it will always be honored.

        This is nice and easy, but it can behave badly if both players ever change the memory value at the same time. So it's better to use one of these instead:

    * *type: string* Any of these strings are recognized:

        * "high": This means "always take the higher value". If the current value is 4, and you write 3, a sync request will not be sent. If your partner sends a message to write the value to 3, and the current value is 4, it will be ignored.
        * "bitOr": This means that the value is a bit field, and you should always take the binary OR of values. If the current value is 3, and your partner says to set the value to 9, the new value will be 11.
        * "delta": I described this earlier in the document, but, this should be used for "quantities". If you raise from 500 to 600, emu-coop will send "+100" to your partner, and your partner will add 100 to their current memory value, whatever that is. If you drop from 600 to 500, it will send "-100", and your partner's value will drop by 100. If you use this you should probably set the "deltaMin" and "deltaMax" keys also (see below).
        * "trigger": This means that no message is sent when the value is written, and if a value is received from the other side, it will not be written to memory. The only reason to use this is if you're using `receiveTrigger`/`writeTrigger` (see below), which will still be called when appropriate.

    * *type: function*
        
        If the "kind" key is a function, then the function will be called whenever the program needs to make a sync decision. The function will be called at two times: When the watched memory address changes; and when a message is received from the other computer saying that *their* memory address changed. The function should take 3 arguments:

        * **value**: If your memory changed, this will be the new value. If your partner's memory changed, this will be the new value they sent. 
        * **previousValue**: If your memory changed, this will be the value it was before it changed. If your partner's memory changed, this will be your current value.
        * **receiving**: If your memory changed, this is `false`. Otherwise it is `true`.
        
        ...And return 2 values:
        
        * **allow**: This should be a boolean. If your memory changed, `true` will mean "send the value to your partner" and `false` will mean "do nothing". If your partner's memory changed, `true` will mean accept the received value and write it to memory, and `false` will mean "do nothing"
        * **value**: If your memory changed, this will be the value sent over the wire to your partner (the value returned here will not be written to your own memory). If your partner's memory changed, this will be the value to . (In either case, if you returned `false` for "allow", this returned value will be discarded.) If `nil` is returned here, the value originally passed in as the "value' argument will be used.
    
        So for example here's a sample function which emulates `kind="high"`:
    
                kind=function(value, previousValue, receiving)
                    return value > previousValue, value
                end

* **size** *type: number*

    This should be 1, 2, or 4. It's the byte size of the memory value you are syncing. If you don't include this the default is 1.

* **mask** *type: number*

    It is undefined behavior what happens if you set a mask but "kind" is a function. Don't do that.

* **name** *type: string*
    
    When you receive a new value from your partner, if "name" is present, the words "Partner got [name]" will be displayed to the screen. Or...

* **verb**

    ...if "verb" is present, it will display "Partner [verb] [name]".

* **nameMap** *type: list of strings*

    This works like "name", but instead of printing a fixed string the "nameMap" is treated as a table of values to names. So if you set:

        nameMap={"Shovel", "Flute", "Bird"}

    then if the value 1 is written to memory it will print you got Shovel, if 2 is written it will print you got Flute, if 3 is written it will print you got Bird.

* **nameBitmap** *type: list of strings*

    This works like "name", but instead of printing a fixed string the "nameMap" is treated as a table of **bits** to names, with 1 mapped to the least significant bit and 8 mapped to the most significant bit. So if you set:

        nameBitmap={"Wave", "Ice", "Spazer"}

    then if the bit 0x1 is added to the field, it will print you got Wave, if 0x2 is added it will print you got Ice, if 0x4 is added it will print you got Spazer.

    This makes the most sense with the "bitOr" kind.

* **cond** *type: cond table (see below)*

    This adds an additional condition for syncing the address. for example, if your condition is lte=5 (see below), then any value above 5 will be ignored and not synced.

    The condition is tested after any changes that the "kind" forces. For example for "bitOr" the value tested against the condition will be the post-OR value, for "delta" the value tested against the condition will be the post-sum value, for a function kind the value tested will be the value returned by the function.

* **writeTrigger** *type: function*

    When a value is written to the address, this function is called. It has three arguments, **value**, **previousValue** and **forceSend**, which are the new value about to be written to memory; the value the memory had beforehand; and `true` if the trigger is being called because the user checked the "restarting after a crash" box. Note this function gets called even if the value did not change.

* **receiveTrigger** *type: function*

    If a new value is received from your partner, and the "kind" (string or function) concludes that the value has been accepted, this function will be called. It has two arguments, **value** and **previousValue**, which are the new value about to be written to memory and the value the memory had beforehand.

* **deltaMin**
* **deltaMax**

    If you are using `kind="delta"`, this sets maximum and minimum values to use when summing-- a clamp. If the current value is 10, and your partner sends a delta of +33, and "deltaMax" is 20, then the value written to memory will be 20.

    If you use "deltaMin"/"deltaMax" with "mask", the minimum/maximum comparison will be done against masked versions of the numbers. So for example if the value was 0x3F, and your partner sends a delta of +0x10, deltaMin/deltaMax will be tested against the value 0x40, not 0x4F.

    If you are using "delta", you will almost always want to set the minimum and maximum values for the value size as "deltaMin"/"deltaMax", because otherwise you could get underflow/overflow and unintentional negative numbers. For example:

        {kind="delta", deltaMin=0, deltaMax=0xFF}

    Or if the number is signed:

        {kind="delta", deltaMin=0, deltaMax=0x7F}

    Or if the value is a short:

        {kind="delta", size=2, deltaMin=0, deltaMax=0xFFFF}

## Cond table

This is used in a few places above when you need to describe a "condition". It can take one of three forms:

    {"stringtest", addr=0xFFC0, value="ZELDANODENSETSU"}

This will test true if the string given by "value" is found at the address "addr".

    {"test", addr = 0x7E0010, gte = 0x6, lte = 0x13}

This will test true if the value at address "addr" is greater than or equal to "gte" AND less than or equal to "lte".

Optionally for this version you can add a "size" key, which can be 1, 2 or 4. This is the byte size of the value at address "addr" (if you don't use a "size" key it will assume 1). The addr and size keys are both ignored for sync rules.

    (A function)

Anywhere a cond table can be passed in, a function can be passed instead. The function will take two arguments, **value** (the tested value for sync rules, or nil otherwise) and **size** (the byte size of the tested value for sync rules, or nil otherwise).

## Custom message table

This is an advanced feature for if you need to send information between partners outside of the basic memory syncing. It's a table of custom message "name"s to functions; when a custom message with name "name" is received the corresponding function gets called. So if player A has this in their mode file:

    custom = {
        hello = function (payload)
            message("Hello from " .. payload)
        end
    }

Then if player B's code calls:

    send("hello", "Susan")

Then player A will see "Hello from Susan" displayed on their screen.

## Functions

The following functions are available to code written in a mode file.

* `memoryRead(addr, size)`

    Reads a value of byte size `size` from address `addr` and returns it. If `size` is left out, a size of 1 will be assumed.

* `memoryWrite(addr, value, size)`

    Writes a value of byte size `size` to address `addr`. If `size` is left out, a size of 1 will be assumed.

    Note that because of requirements of the syncing system, you cannot call `memoryWrite` different times with different `size`s, or call `memoryWrite` with a size that disagrees with the size listed for that address (if any) in the Sync table.

* `message(x)`

    `x` must be a string. Displays `x` at the bottom of the screen, in the same fashion as the "Partner got whatever" messages.

* `send(name, payload)`

    Sends a custom message (processed by the custom message table, see above) to your partner. `payload` will be passed to the message handler as an argument. `payload` can be a number, string, table, or nil.

    Warning, if you send a sufficiently long or complicated string or table as payload, it might get cut off by the IRC server and then everything will break.

* `AND(x, y)`, `OR(x, y)`, `XOR(x, y)`, `SHIFT(a, b)`, `BIT(n)`, `BNOT(x)`

    Bit operation functions.

In addition, you can probably expect the [snes9x-rr](https://github.com/TASVideos/snes9x-rr/wiki) functions are available. Unless you're running in FCEUX, maybe? Life is an adventure.

# Are you stuck?

If you have problems or this guide didn't explain well enough, bother mcc#7322 on Discord or @mcclure111 on Twitter and I'll help you.
