b8	21 0a 00 00			#moving "!\n" into eax
a3	0c 10 00 06			#moving eax into first memory location
b8 	6f 72 6c 64			#moving "orld" into eax
a3	08 10 00 06			#moving eax into next memory location
b8 	6f 2c 20 57			#moving "o, W" into eax
a3	04 10 00 06			#moving eax into next memory location
b8 	48 65 6c 6c			#moving "Hell" into eax
a3	00 10 00 06			#moving eax into next memory location

b9  	00 10 00 06			#moving pointer to start of memory location into ecx
ba  	10 00 00 00			#moving string size into edx
bb  	01 00 00 00			#moving "stdout" number to ebx
b8  	04 00 00 00			#moving "print out" syscall number to eax
cd  	80			            #calling the linux kernel to execute our print to stdout
            
b8	01 00 00 00			#moving "sys_exit" call number to eax
cd	80			            #executing it via linux sys_call
