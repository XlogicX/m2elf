m2elf
=====

Converts Machine Code to x86 (32-bit) Linux executable (auto-wrapping with ELF headers)

Command Usage
=====
Options:<br>
--in (input file)<br>
--out (output file)<br>
--binary (if the input is already binary form)<br>
--mem (bytes)

m2elf --in source_file.m --out executable_file --mem 100

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

Hello World Example
=====
b8		21 0a 00 00			#moving "!\n" into eax<br>
a3		0c 10 00 06			#moving eax into first memory location<br>
b8 		6f 72 6c 64			#moving "orld" into eax<br>
a3		08 10 00 06			#moving eax into next memory location<br>
b8 		6f 2c 20 57			#moving "o, W" into eax<br>
a3		04 10 00 06			#moving eax into next memory location<br>
b8 		48 65 6c 6c			#moving "Hell" into eax<br>
a3		00 10 00 06			#moving eax into next memory location<br>
<br>
b9  	00 10 00 06			#moving pointer to start of memory location into ecx<br>
ba  	10 00 00 00			#moving string size into edx<br>
bb  	01 00 00 00			#moving "stdout" number to ebx<br>
b8  	04 00 00 00			#moving "print out" syscall number to eax<br>
cd  	80					    #calling the linux kernel to execute our print to stdout<br>
            <br>
b8		01 00 00 00			#moving "sys_exit" call number to eax<br>
cd		80					    #executing it via linux sys_call<br>
