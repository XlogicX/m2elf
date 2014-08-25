m2elf
=====

Converts Machine Code to x86 (32-bit) Linux executable (auto-wrapping with ELF headers)

Command Usage
=====
Options:
--in (input file)
--out (output file)
--binary (if the input is already binary form)

m2elf --in source_file.m --out executable_file

Source File Syntax
=====
The source file can include ascii hex and binary byte by byte. Spacing between hex bytes not a requirment, but could reduce bugs (4 hex bytes could look like binary to m2elf if the hex is only 1's and 0's). In order for a binary byte to be interpreted as such, it needs to be consecutive 1's and 0's with no 1's or 0's surrounding it.

Valid comments include #, //, ', and --

Example Source File
=====
--opcode   operands  #commends<br>
b8        55555555  #Move hex 55555555 into EAX<br>
34        10101010  #XOR al with hex AA (or 10101010)<br>
--EAX will now contain 555555FF

Same Source File without Comments
=====
b8        55555555<br>
34        10101010<br>

Upcoming Features / BugFixes
=====
This code is super fresh, so it has some issues and lacks some critical features
* (Bug) some of the offsets in the ELF headers aren't dynamic yet (although execution of code still works just fine regardless)
* (Feature) This currently does not support memory allocation for program (.bss). This is a fairly critical feature that will eventually be added
* (Feature) 64-bit...maybe. I might not care enough about this.
