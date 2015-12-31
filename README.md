m2elf
=====

Converts Machine Code to x86 (32-bit) Linux executable (auto-wrapping with ELF headers). This script comes included in Remnux v6

Command Usage
=====
Options:<br>
--in (input file)<br>
--out (output file)<br>
--binary (if the input is already binary form)<br>
--mem (bytes)<br>
--entry (This changes the entry point, it adds to the offset whichever decimal number is provided) <br>
--writeover - changes the r-x of the .text to rwx; now you can have self modifying codes

m2elf --in source_file.m --out executable_file --mem 100<br>

Example Source Files
=====
* hello.m - written in machine code, prints hello world. Use --mem 16
* hello.b - same as above, but written in pure 1's and 0's :)
* Spawnshell.m - shellcode from: http://phrack.org/issues/49/14.html#article, the difference with this .m file is that each instruction is commented. To get this to actually run, the --writeover argument must be used.

Source File Syntax
=====
The source file can include ascii hex and binary byte by byte. Spacing between hex bytes not a requirment, but could reduce bugs (4 hex bytes could look like binary to m2elf if the hex is only 1's and 0's). In order for a binary byte to be interpreted as such, it needs to be a series of 8 1's and 0's preceded by an underscore, i.e. _01011000

Valid comments include #, //, ', and --
