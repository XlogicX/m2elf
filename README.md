m2elf
=====

Converts Machine Code to x86 (32-bit) Linux executable (auto-wrapping with ELF headers)

Command Usage
=====
Options:<br>
--in (input file)<br>
--out (output file)<br>
--binary (if the input is already binary form)<br>
--mem (bytes)<br>
--entry (This changes the entry point, it adds to the offset whichever decimal number is provided)

m2elf --in source_file.m --out executable_file --mem 100<br>
(chmod 755 executable_file)

Example Source Files
=====
* hello.m - written in machine code, prints hello world. Use --mem 16
* hello.b - same as above, but written in pure 1's and 0's :)
* Spawnshell.m - shellcode from: http://phrack.org/issues/49/14.html#article, the difference with this .m file is that each instruction is commented. To get this to actually run, the p_flags byte for the .text section header needs to be changed from a 5 (read/execute) to 6 (read/write/execute). I just did this with a hex editor, but I may add this ability as a command line option (as it allows the cool feature of self modifying code).

Source File Syntax
=====
The source file can include ascii hex and binary byte by byte. Spacing between hex bytes not a requirment, but could reduce bugs (4 hex bytes could look like binary to m2elf if the hex is only 1's and 0's). In order for a binary byte to be interpreted as such, it needs to be consecutive 1's and 0's with no 1's or 0's surrounding it.

Valid comments include #, //, ', and --
