Exercise 3:

Answer 1:

boot/boot.S, Line 55, 
  ljmp    $PROT_MODE_CSEG, $protcseg
After that, the program jump to Line 59, which set the protect mode;

boot/boot.S, Line 28~42
In 16 bit devices, memory greater than 1MB if set 0 by default. This piece deactivate it.

Answer 2:

obj/boot/boot.asm, Line 306, code 0x7d6b. call   *0x10018

0x10000c:	movw   $0x1234,0x472

Answer 3:
0x10000c:	movw   $0x1234,0x472

Answer 4:
By reading the ELF header of the kernel. THe code length of each sector is contained in it.



Exercise 6:

Before loading
0x100000:	0x00000000	0x00000000	0x00000000	0x00000000
0x100010:	0x00000000	0x00000000	0x00000000	0x00000000
0x100020:	0x00000000	0x00000000	0x00000000	0x00000000
0x100030:	0x00000000	0x00000000	0x00000000	0x00000000

After loading
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x2000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0068e8f0	0xfeeb0000

Exercise 7:

Happended: Instruction from 0x00100000 is copied to 0xf0100000

The start of machine codes of the kernel(actually located in 0x10000c, kern/entry.S).

if the line is comment out, then the first instruction is add    %al,(%eax), which has 000000 in binary code.

Exercise 8:

console.c provide a interface to put a char in multiple modes(includeing parallelized, delayed, and now)
print.c use it by calling printfmt.c, and it use the interface to put a char.

The output is too large and it could not be displayed in the screen(command prompt).
So the most top line is deleted, in order to refresh a new line to print chars.

fmt: "x = %d,....", the first arg in the function call
ap: for multiplt args follow(VA_ARGS)

List: Guuuu

Exercise 9:

Initize the stack in kern/entry.S, line 69~80.  ANd the structure of the stack is defined in the end of 
kern/entry.S, line 86~95. 
Initially %esp = 0xf0110000, and the space which system stack used is 8pages, 32KB