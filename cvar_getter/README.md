# Console variable getter script
It is not normally possible to get ConVars with VScripts in CS:GO as there are no functions for it available.
This method uses a very roundabout way to make it possible to do so.

WARNING: This script creates a file each time you acquire a convar in the cfg directory, it might get messy quickly! It is safe to delete them. (can't do it within game unfortunately)

### Setup
Compile the vmf file and merge the scripts directory relative to your csgo gamedir.

### Usage
To Acquire a ConVar (need to be done before to be able to get it's value)
<br/>
<code>
::AcquireCvar(convar)
</code><br/>
where 'convar' is the convar name as a string.

After Acquiring the ConVar you can get its value with:
<br/>
<code>
::GetConVar(convar)
</code>

### Example
Test it out by running the following in console:
<br/>
```
script ::AcquireCvar("mp_warmuptime")
script printl(::GetConVar("mp_warmuptime"))
```
  
 
