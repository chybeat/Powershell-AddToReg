# Powershell-AddToReg
Funtion to add on Windows registry data passing a "@={path;name;value;type}" object, or "[HKCU_things]" string like .reg file structure, using Powershell

Just copy, use, modify, download, pirate, or make anything with this code. The file (addtoreg.psm1) can be used with next command from a .ps1 File:

```Powershell
Import-Module -DisableNameChecking "D:\rive\and\wherever-the-file-is\addToReg.psm1"
```

The "_-DisableNameChecking_" paramter is because all functions called from other files needs to be started with a verb and hyphen... and I don't like a function called like "add-on-Windows-Registry-from-object-or-string" and other (for delete) called "remove-on-Windows-Registry-from-object-or-string" :pray: . At last if parameter not writed the console will you alert about the function name.



## To know:
Function to insert or delete on Windows registry data or a lot of very much data from *"like .reg file"* string

### Passing Object:
Function receives an object like:

    @{
        path = "HKEY_CURRENT_USER\Control Panel\Quick Actions\Control Center\Unpinned"
        name = "Microsoft.QuickAction.AllSettings"
        val  = "hex(0)"
        type = "None"
    }
 
**Path**: Is the: a). short or complete root key path and: b). the entire path of the key

`Path=HKEY_CURRENT_USER\Control Panel\Quick Actions\Control Center\Unpinned`

or

`Path=HKCU\Control Panel\Quick Actions\Control Center\Unpinned`

In a .reg file line like: 'binario=hex:e0'

**Name**: The value to create or change

`name="binario"` in object

**Val**: "stringed" Value as exported in .reg file

`val="e0"` in object

**Type**: The type of the value

`type="binary"` in object
  
> The other types are string, expandstring, dword, binary, none, multistring, qword, unknown or del

**About "del" in type**

If you pass "del" as type take care about name:

**If name is empty string, the function will delete the entire path recursively. Be carefully you may damage your computer... Like me 
:weary:**

Name represents a value in the path, if you pass a name this function will try to delete the value in key not the key/path

### Passing String:

The function can receive a string like the exported on Windows registry files (.reg)

You need to know:
* Use single quotes ` ' ` to avoid escape the doble quote on multiline strings
* Use the same parameters and syntax that are used in .reg files check at [Microsoft page](https://support.microsoft.com/en-us/help/310516/how-to-add-modify-or-delete-registry-subkeys-and-values-by-using-a-reg)
* To delete a path you can write a hyphen before the path ie: `-[HKEY_CURRENT_USER\test_types\binarios]`
* To delete a value you need to write _ONLY_ a hyphen after equal ie: `binario=-`

This will help you
* The multiline strings like the long binary data exported from a regfile can be used as Windows resitry exported (77 chars long and end with slash) 
* If you use a .reg file, read entire file to string, *not* line by line,

String Example:

    $string = '
      [HKEY_CURRENT_USER\test_types\binarios] 
      AnInt64=hex(b):ff,ff,ff,ff,ff,ff,ff,7f
      binario=hex:e0
      binario=-
      Dword32=dword:00007e57
      Qword64=hex(b):75,7e,00,00,00,00,00,00

      [HKEY_CURRENT_USER\test_types]
      @=""
      cadenamultiple=hex(7):74,00,65,00,73,00,74,00,00,00,00,00
      cadenaMultipleExpandible=-
      cadenaMultipleExpandible=hex(2):25,00,63,00,61,00,64,00,65,00,6e,00,61,00,45,\
        00,78,00,70,00,6c,00,61,00,6e,00,64,00,69,00,62,00,6c,00,65,00,25,00,00,00
    '
