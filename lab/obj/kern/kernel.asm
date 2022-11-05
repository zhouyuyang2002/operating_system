
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 18 00       	mov    $0x18f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 c0 11 f0       	mov    $0xf011c000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 1b 01 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f010004c:	81 c3 d4 df 08 00    	add    $0x8dfd4,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c0 40 10 19 f0    	mov    $0xf0191040,%eax
f0100058:	c7 c2 40 01 19 f0    	mov    $0xf0190140,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 9b 55 00 00       	call   f0105604 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 20 7a f7 ff    	lea    -0x885e0(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 f0 3e 00 00       	call   f0103f72 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 e8 17 00 00       	call   f010186f <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 42 38 00 00       	call   f01038ce <env_init>
	trap_init();
f010008c:	e8 94 3f 00 00       	call   f0104025 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010009c:	e8 0f 3a 00 00       	call   f0103ab0 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 88 03 19 f0    	mov    $0xf0190388,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 c5 3d 00 00       	call   f0103e76 <env_run>

f01000b1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b1:	55                   	push   %ebp
f01000b2:	89 e5                	mov    %esp,%ebp
f01000b4:	57                   	push   %edi
f01000b5:	56                   	push   %esi
f01000b6:	53                   	push   %ebx
f01000b7:	83 ec 0c             	sub    $0xc,%esp
f01000ba:	e8 a8 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f01000bf:	81 c3 61 df 08 00    	add    $0x8df61,%ebx
f01000c5:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000c8:	c7 c0 44 10 19 f0    	mov    $0xf0191044,%eax
f01000ce:	83 38 00             	cmpl   $0x0,(%eax)
f01000d1:	74 0f                	je     f01000e2 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 ae 0c 00 00       	call   f0100d8b <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x22>
	panicstr = fmt;
f01000e2:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000e4:	fa                   	cli    
f01000e5:	fc                   	cld    
	va_start(ap, fmt);
f01000e6:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e9:	83 ec 04             	sub    $0x4,%esp
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	8d 83 3b 7a f7 ff    	lea    -0x885c5(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 74 3e 00 00       	call   f0103f72 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 33 3e 00 00       	call   f0103f3b <vcprintf>
	cprintf("\n");
f0100108:	8d 83 eb 7c f7 ff    	lea    -0x88315(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 5c 3e 00 00       	call   f0103f72 <cprintf>
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	eb b8                	jmp    f01000d3 <_panic+0x22>

f010011b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011b:	55                   	push   %ebp
f010011c:	89 e5                	mov    %esp,%ebp
f010011e:	56                   	push   %esi
f010011f:	53                   	push   %ebx
f0100120:	e8 42 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100125:	81 c3 fb de 08 00    	add    $0x8defb,%ebx
	va_list ap;

	va_start(ap, fmt);
f010012b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010012e:	83 ec 04             	sub    $0x4,%esp
f0100131:	ff 75 0c             	pushl  0xc(%ebp)
f0100134:	ff 75 08             	pushl  0x8(%ebp)
f0100137:	8d 83 53 7a f7 ff    	lea    -0x885ad(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 2f 3e 00 00       	call   f0103f72 <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 ec 3d 00 00       	call   f0103f3b <vcprintf>
	cprintf("\n");
f010014f:	8d 83 eb 7c f7 ff    	lea    -0x88315(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 15 3e 00 00       	call   f0103f72 <cprintf>
	va_end(ap);
}
f010015d:	83 c4 10             	add    $0x10,%esp
f0100160:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100163:	5b                   	pop    %ebx
f0100164:	5e                   	pop    %esi
f0100165:	5d                   	pop    %ebp
f0100166:	c3                   	ret    

f0100167 <__x86.get_pc_thunk.bx>:
f0100167:	8b 1c 24             	mov    (%esp),%ebx
f010016a:	c3                   	ret    

f010016b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016b:	55                   	push   %ebp
f010016c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010016e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100173:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100174:	a8 01                	test   $0x1,%al
f0100176:	74 0b                	je     f0100183 <serial_proc_data+0x18>
f0100178:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
}
f0100181:	5d                   	pop    %ebp
f0100182:	c3                   	ret    
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100188:	eb f7                	jmp    f0100181 <serial_proc_data+0x16>

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	56                   	push   %esi
f010018e:	53                   	push   %ebx
f010018f:	e8 d3 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100194:	81 c3 8c de 08 00    	add    $0x8de8c,%ebx
f010019a:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	ff d6                	call   *%esi
f010019e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a1:	74 2e                	je     f01001d1 <cons_intr+0x47>
		if (c == 0)
f01001a3:	85 c0                	test   %eax,%eax
f01001a5:	74 f5                	je     f010019c <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a7:	8b 8b 44 23 00 00    	mov    0x2344(%ebx),%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	89 93 44 23 00 00    	mov    %edx,0x2344(%ebx)
f01001b6:	88 84 0b 40 21 00 00 	mov    %al,0x2140(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c3:	75 d7                	jne    f010019c <cons_intr+0x12>
			cons.wpos = 0;
f01001c5:	c7 83 44 23 00 00 00 	movl   $0x0,0x2344(%ebx)
f01001cc:	00 00 00 
f01001cf:	eb cb                	jmp    f010019c <cons_intr+0x12>
	}
}
f01001d1:	5b                   	pop    %ebx
f01001d2:	5e                   	pop    %esi
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    

f01001d5 <kbd_proc_data>:
{
f01001d5:	55                   	push   %ebp
f01001d6:	89 e5                	mov    %esp,%ebp
f01001d8:	56                   	push   %esi
f01001d9:	53                   	push   %ebx
f01001da:	e8 88 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01001df:	81 c3 41 de 08 00    	add    $0x8de41,%ebx
f01001e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01001ea:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001eb:	a8 01                	test   $0x1,%al
f01001ed:	0f 84 06 01 00 00    	je     f01002f9 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001f3:	a8 20                	test   $0x20,%al
f01001f5:	0f 85 05 01 00 00    	jne    f0100300 <kbd_proc_data+0x12b>
f01001fb:	ba 60 00 00 00       	mov    $0x60,%edx
f0100200:	ec                   	in     (%dx),%al
f0100201:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100203:	3c e0                	cmp    $0xe0,%al
f0100205:	0f 84 93 00 00 00    	je     f010029e <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010020b:	84 c0                	test   %al,%al
f010020d:	0f 88 a0 00 00 00    	js     f01002b3 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100213:	8b 8b 20 21 00 00    	mov    0x2120(%ebx),%ecx
f0100219:	f6 c1 40             	test   $0x40,%cl
f010021c:	74 0e                	je     f010022c <kbd_proc_data+0x57>
		data |= 0x80;
f010021e:	83 c8 80             	or     $0xffffff80,%eax
f0100221:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100223:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100226:	89 8b 20 21 00 00    	mov    %ecx,0x2120(%ebx)
	shift |= shiftcode[data];
f010022c:	0f b6 d2             	movzbl %dl,%edx
f010022f:	0f b6 84 13 a0 7b f7 	movzbl -0x88460(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 20 21 00 00    	or     0x2120(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 a0 7a f7 	movzbl -0x88560(%ebx,%edx,1),%ecx
f0100244:	ff 
f0100245:	31 c8                	xor    %ecx,%eax
f0100247:	89 83 20 21 00 00    	mov    %eax,0x2120(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010024d:	89 c1                	mov    %eax,%ecx
f010024f:	83 e1 03             	and    $0x3,%ecx
f0100252:	8b 8c 8b 00 20 00 00 	mov    0x2000(%ebx,%ecx,4),%ecx
f0100259:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010025d:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100260:	a8 08                	test   $0x8,%al
f0100262:	74 0d                	je     f0100271 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f0100264:	89 f2                	mov    %esi,%edx
f0100266:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100269:	83 f9 19             	cmp    $0x19,%ecx
f010026c:	77 7a                	ja     f01002e8 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f010026e:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100271:	f7 d0                	not    %eax
f0100273:	a8 06                	test   $0x6,%al
f0100275:	75 33                	jne    f01002aa <kbd_proc_data+0xd5>
f0100277:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f010027d:	75 2b                	jne    f01002aa <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f010027f:	83 ec 0c             	sub    $0xc,%esp
f0100282:	8d 83 6d 7a f7 ff    	lea    -0x88593(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 e4 3c 00 00       	call   f0103f72 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100293:	ba 92 00 00 00       	mov    $0x92,%edx
f0100298:	ee                   	out    %al,(%dx)
f0100299:	83 c4 10             	add    $0x10,%esp
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd5>
		shift |= E0ESC;
f010029e:	83 8b 20 21 00 00 40 	orl    $0x40,0x2120(%ebx)
		return 0;
f01002a5:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002aa:	89 f0                	mov    %esi,%eax
f01002ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5e                   	pop    %esi
f01002b1:	5d                   	pop    %ebp
f01002b2:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002b3:	8b 8b 20 21 00 00    	mov    0x2120(%ebx),%ecx
f01002b9:	89 ce                	mov    %ecx,%esi
f01002bb:	83 e6 40             	and    $0x40,%esi
f01002be:	83 e0 7f             	and    $0x7f,%eax
f01002c1:	85 f6                	test   %esi,%esi
f01002c3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002c6:	0f b6 d2             	movzbl %dl,%edx
f01002c9:	0f b6 84 13 a0 7b f7 	movzbl -0x88460(%ebx,%edx,1),%eax
f01002d0:	ff 
f01002d1:	83 c8 40             	or     $0x40,%eax
f01002d4:	0f b6 c0             	movzbl %al,%eax
f01002d7:	f7 d0                	not    %eax
f01002d9:	21 c8                	and    %ecx,%eax
f01002db:	89 83 20 21 00 00    	mov    %eax,0x2120(%ebx)
		return 0;
f01002e1:	be 00 00 00 00       	mov    $0x0,%esi
f01002e6:	eb c2                	jmp    f01002aa <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002e8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002eb:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002ee:	83 fa 1a             	cmp    $0x1a,%edx
f01002f1:	0f 42 f1             	cmovb  %ecx,%esi
f01002f4:	e9 78 ff ff ff       	jmp    f0100271 <kbd_proc_data+0x9c>
		return -1;
f01002f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002fe:	eb aa                	jmp    f01002aa <kbd_proc_data+0xd5>
		return -1;
f0100300:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100305:	eb a3                	jmp    f01002aa <kbd_proc_data+0xd5>

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	e8 52 fe ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100315:	81 c3 0b dd 08 00    	add    $0x8dd0b,%ebx
f010031b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010031e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	eb 09                	jmp    f0100338 <cons_putc+0x31>
f010032f:	89 ca                	mov    %ecx,%edx
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
	     i++)
f0100335:	83 c6 01             	add    $0x1,%esi
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033b:	a8 20                	test   $0x20,%al
f010033d:	75 08                	jne    f0100347 <cons_putc+0x40>
f010033f:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100345:	7e e8                	jle    f010032f <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100347:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010034a:	89 f8                	mov    %edi,%eax
f010034c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100354:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010035a:	bf 79 03 00 00       	mov    $0x379,%edi
f010035f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100364:	eb 09                	jmp    f010036f <cons_putc+0x68>
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	ec                   	in     (%dx),%al
f010036b:	ec                   	in     (%dx),%al
f010036c:	83 c6 01             	add    $0x1,%esi
f010036f:	89 fa                	mov    %edi,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100378:	7f 04                	jg     f010037e <cons_putc+0x77>
f010037a:	84 c0                	test   %al,%al
f010037c:	79 e8                	jns    f0100366 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100383:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010038d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100392:	ee                   	out    %al,(%dx)
f0100393:	b8 08 00 00 00       	mov    $0x8,%eax
f0100398:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039c:	89 fa                	mov    %edi,%edx
f010039e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a4:	89 f8                	mov    %edi,%eax
f01003a6:	80 cc 07             	or     $0x7,%ah
f01003a9:	85 d2                	test   %edx,%edx
f01003ab:	0f 45 c7             	cmovne %edi,%eax
f01003ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	83 f8 09             	cmp    $0x9,%eax
f01003b7:	0f 84 b9 00 00 00    	je     f0100476 <cons_putc+0x16f>
f01003bd:	83 f8 09             	cmp    $0x9,%eax
f01003c0:	7e 74                	jle    f0100436 <cons_putc+0x12f>
f01003c2:	83 f8 0a             	cmp    $0xa,%eax
f01003c5:	0f 84 9e 00 00 00    	je     f0100469 <cons_putc+0x162>
f01003cb:	83 f8 0d             	cmp    $0xd,%eax
f01003ce:	0f 85 d9 00 00 00    	jne    f01004ad <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003d4:	0f b7 83 48 23 00 00 	movzwl 0x2348(%ebx),%eax
f01003db:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e1:	c1 e8 16             	shr    $0x16,%eax
f01003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e7:	c1 e0 04             	shl    $0x4,%eax
f01003ea:	66 89 83 48 23 00 00 	mov    %ax,0x2348(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003f1:	66 81 bb 48 23 00 00 	cmpw   $0x7cf,0x2348(%ebx)
f01003f8:	cf 07 
f01003fa:	0f 87 d4 00 00 00    	ja     f01004d4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100400:	8b 8b 50 23 00 00    	mov    0x2350(%ebx),%ecx
f0100406:	b8 0e 00 00 00       	mov    $0xe,%eax
f010040b:	89 ca                	mov    %ecx,%edx
f010040d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010040e:	0f b7 9b 48 23 00 00 	movzwl 0x2348(%ebx),%ebx
f0100415:	8d 71 01             	lea    0x1(%ecx),%esi
f0100418:	89 d8                	mov    %ebx,%eax
f010041a:	66 c1 e8 08          	shr    $0x8,%ax
f010041e:	89 f2                	mov    %esi,%edx
f0100420:	ee                   	out    %al,(%dx)
f0100421:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ee                   	out    %al,(%dx)
f0100429:	89 d8                	mov    %ebx,%eax
f010042b:	89 f2                	mov    %esi,%edx
f010042d:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010042e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100431:	5b                   	pop    %ebx
f0100432:	5e                   	pop    %esi
f0100433:	5f                   	pop    %edi
f0100434:	5d                   	pop    %ebp
f0100435:	c3                   	ret    
	switch (c & 0xff) {
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	75 72                	jne    f01004ad <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010043b:	0f b7 83 48 23 00 00 	movzwl 0x2348(%ebx),%eax
f0100442:	66 85 c0             	test   %ax,%ax
f0100445:	74 b9                	je     f0100400 <cons_putc+0xf9>
			crt_pos--;
f0100447:	83 e8 01             	sub    $0x1,%eax
f010044a:	66 89 83 48 23 00 00 	mov    %ax,0x2348(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100451:	0f b7 c0             	movzwl %ax,%eax
f0100454:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100458:	b2 00                	mov    $0x0,%dl
f010045a:	83 ca 20             	or     $0x20,%edx
f010045d:	8b 8b 4c 23 00 00    	mov    0x234c(%ebx),%ecx
f0100463:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100467:	eb 88                	jmp    f01003f1 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100469:	66 83 83 48 23 00 00 	addw   $0x50,0x2348(%ebx)
f0100470:	50 
f0100471:	e9 5e ff ff ff       	jmp    f01003d4 <cons_putc+0xcd>
		cons_putc(' ');
f0100476:	b8 20 00 00 00       	mov    $0x20,%eax
f010047b:	e8 87 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100480:	b8 20 00 00 00       	mov    $0x20,%eax
f0100485:	e8 7d fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010048a:	b8 20 00 00 00       	mov    $0x20,%eax
f010048f:	e8 73 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100494:	b8 20 00 00 00       	mov    $0x20,%eax
f0100499:	e8 69 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 5f fe ff ff       	call   f0100307 <cons_putc>
f01004a8:	e9 44 ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ad:	0f b7 83 48 23 00 00 	movzwl 0x2348(%ebx),%eax
f01004b4:	8d 50 01             	lea    0x1(%eax),%edx
f01004b7:	66 89 93 48 23 00 00 	mov    %dx,0x2348(%ebx)
f01004be:	0f b7 c0             	movzwl %ax,%eax
f01004c1:	8b 93 4c 23 00 00    	mov    0x234c(%ebx),%edx
f01004c7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cf:	e9 1d ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d4:	8b 83 4c 23 00 00    	mov    0x234c(%ebx),%eax
f01004da:	83 ec 04             	sub    $0x4,%esp
f01004dd:	68 00 0f 00 00       	push   $0xf00
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	52                   	push   %edx
f01004e9:	50                   	push   %eax
f01004ea:	e8 62 51 00 00       	call   f0105651 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004ef:	8b 93 4c 23 00 00    	mov    0x234c(%ebx),%edx
f01004f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100501:	83 c4 10             	add    $0x10,%esp
f0100504:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100509:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010050c:	39 d0                	cmp    %edx,%eax
f010050e:	75 f4                	jne    f0100504 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100510:	66 83 ab 48 23 00 00 	subw   $0x50,0x2348(%ebx)
f0100517:	50 
f0100518:	e9 e3 fe ff ff       	jmp    f0100400 <cons_putc+0xf9>

f010051d <serial_intr>:
{
f010051d:	e8 e7 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100522:	05 fe da 08 00       	add    $0x8dafe,%eax
	if (serial_exists)
f0100527:	80 b8 54 23 00 00 00 	cmpb   $0x0,0x2354(%eax)
f010052e:	75 02                	jne    f0100532 <serial_intr+0x15>
f0100530:	f3 c3                	repz ret 
{
f0100532:	55                   	push   %ebp
f0100533:	89 e5                	mov    %esp,%ebp
f0100535:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100538:	8d 80 4b 21 f7 ff    	lea    -0x8deb5(%eax),%eax
f010053e:	e8 47 fc ff ff       	call   f010018a <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <kbd_intr>:
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
f010054b:	e8 b9 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100550:	05 d0 da 08 00       	add    $0x8dad0,%eax
	cons_intr(kbd_proc_data);
f0100555:	8d 80 b5 21 f7 ff    	lea    -0x8de4b(%eax),%eax
f010055b:	e8 2a fc ff ff       	call   f010018a <cons_intr>
}
f0100560:	c9                   	leave  
f0100561:	c3                   	ret    

f0100562 <cons_getc>:
{
f0100562:	55                   	push   %ebp
f0100563:	89 e5                	mov    %esp,%ebp
f0100565:	53                   	push   %ebx
f0100566:	83 ec 04             	sub    $0x4,%esp
f0100569:	e8 f9 fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010056e:	81 c3 b2 da 08 00    	add    $0x8dab2,%ebx
	serial_intr();
f0100574:	e8 a4 ff ff ff       	call   f010051d <serial_intr>
	kbd_intr();
f0100579:	e8 c7 ff ff ff       	call   f0100545 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010057e:	8b 93 40 23 00 00    	mov    0x2340(%ebx),%edx
	return 0;
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100589:	3b 93 44 23 00 00    	cmp    0x2344(%ebx),%edx
f010058f:	74 19                	je     f01005aa <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100591:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100594:	89 8b 40 23 00 00    	mov    %ecx,0x2340(%ebx)
f010059a:	0f b6 84 13 40 21 00 	movzbl 0x2140(%ebx,%edx,1),%eax
f01005a1:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005a2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005a8:	74 06                	je     f01005b0 <cons_getc+0x4e>
}
f01005aa:	83 c4 04             	add    $0x4,%esp
f01005ad:	5b                   	pop    %ebx
f01005ae:	5d                   	pop    %ebp
f01005af:	c3                   	ret    
			cons.rpos = 0;
f01005b0:	c7 83 40 23 00 00 00 	movl   $0x0,0x2340(%ebx)
f01005b7:	00 00 00 
f01005ba:	eb ee                	jmp    f01005aa <cons_getc+0x48>

f01005bc <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005bc:	55                   	push   %ebp
f01005bd:	89 e5                	mov    %esp,%ebp
f01005bf:	57                   	push   %edi
f01005c0:	56                   	push   %esi
f01005c1:	53                   	push   %ebx
f01005c2:	83 ec 1c             	sub    $0x1c,%esp
f01005c5:	e8 9d fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01005ca:	81 c3 56 da 08 00    	add    $0x8da56,%ebx
	was = *cp;
f01005d0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005de:	5a a5 
	if (*cp != 0xA55A) {
f01005e0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005eb:	0f 84 bc 00 00 00    	je     f01006ad <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005f1:	c7 83 50 23 00 00 b4 	movl   $0x3b4,0x2350(%ebx)
f01005f8:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fb:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100602:	8b bb 50 23 00 00    	mov    0x2350(%ebx),%edi
f0100608:	b8 0e 00 00 00       	mov    $0xe,%eax
f010060d:	89 fa                	mov    %edi,%edx
f010060f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100610:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100613:	89 ca                	mov    %ecx,%edx
f0100615:	ec                   	in     (%dx),%al
f0100616:	0f b6 f0             	movzbl %al,%esi
f0100619:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100621:	89 fa                	mov    %edi,%edx
f0100623:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100624:	89 ca                	mov    %ecx,%edx
f0100626:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010062a:	89 bb 4c 23 00 00    	mov    %edi,0x234c(%ebx)
	pos |= inb(addr_6845 + 1);
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100635:	66 89 b3 48 23 00 00 	mov    %si,0x2348(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100641:	89 c8                	mov    %ecx,%eax
f0100643:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010064e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	b8 0c 00 00 00       	mov    $0xc,%eax
f010065b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100660:	ee                   	out    %al,(%dx)
f0100661:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100666:	89 c8                	mov    %ecx,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
f010066b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100670:	89 fa                	mov    %edi,%edx
f0100672:	ee                   	out    %al,(%dx)
f0100673:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100678:	89 c8                	mov    %ecx,%eax
f010067a:	ee                   	out    %al,(%dx)
f010067b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100680:	89 f2                	mov    %esi,%edx
f0100682:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100683:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100688:	ec                   	in     (%dx),%al
f0100689:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010068b:	3c ff                	cmp    $0xff,%al
f010068d:	0f 95 83 54 23 00 00 	setne  0x2354(%ebx)
f0100694:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100699:	ec                   	in     (%dx),%al
f010069a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069f:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006a0:	80 f9 ff             	cmp    $0xff,%cl
f01006a3:	74 25                	je     f01006ca <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a8:	5b                   	pop    %ebx
f01006a9:	5e                   	pop    %esi
f01006aa:	5f                   	pop    %edi
f01006ab:	5d                   	pop    %ebp
f01006ac:	c3                   	ret    
		*cp = was;
f01006ad:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006b4:	c7 83 50 23 00 00 d4 	movl   $0x3d4,0x2350(%ebx)
f01006bb:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006be:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c5:	e9 38 ff ff ff       	jmp    f0100602 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006ca:	83 ec 0c             	sub    $0xc,%esp
f01006cd:	8d 83 79 7a f7 ff    	lea    -0x88587(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 99 38 00 00       	call   f0103f72 <cprintf>
f01006d9:	83 c4 10             	add    $0x10,%esp
}
f01006dc:	eb c7                	jmp    f01006a5 <cons_init+0xe9>

f01006de <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006de:	55                   	push   %ebp
f01006df:	89 e5                	mov    %esp,%ebp
f01006e1:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01006e7:	e8 1b fc ff ff       	call   f0100307 <cons_putc>
}
f01006ec:	c9                   	leave  
f01006ed:	c3                   	ret    

f01006ee <getchar>:

int
getchar(void)
{
f01006ee:	55                   	push   %ebp
f01006ef:	89 e5                	mov    %esp,%ebp
f01006f1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006f4:	e8 69 fe ff ff       	call   f0100562 <cons_getc>
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	74 f7                	je     f01006f4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006fd:	c9                   	leave  
f01006fe:	c3                   	ret    

f01006ff <iscons>:

int
iscons(int fdnum)
{
f01006ff:	55                   	push   %ebp
f0100700:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100702:	b8 01 00 00 00       	mov    $0x1,%eax
f0100707:	5d                   	pop    %ebp
f0100708:	c3                   	ret    

f0100709 <__x86.get_pc_thunk.ax>:
f0100709:	8b 04 24             	mov    (%esp),%eax
f010070c:	c3                   	ret    

f010070d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010070d:	55                   	push   %ebp
f010070e:	89 e5                	mov    %esp,%ebp
f0100710:	57                   	push   %edi
f0100711:	56                   	push   %esi
f0100712:	53                   	push   %ebx
f0100713:	83 ec 1c             	sub    $0x1c,%esp
f0100716:	e8 4c fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010071b:	81 c3 05 d9 08 00    	add    $0x8d905,%ebx
f0100721:	8d b3 20 20 00 00    	lea    0x2020(%ebx),%esi
f0100727:	8d 83 8c 20 00 00    	lea    0x208c(%ebx),%eax
f010072d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100730:	8d bb a0 7c f7 ff    	lea    -0x88360(%ebx),%edi
f0100736:	83 ec 04             	sub    $0x4,%esp
f0100739:	ff 76 04             	pushl  0x4(%esi)
f010073c:	ff 36                	pushl  (%esi)
f010073e:	57                   	push   %edi
f010073f:	e8 2e 38 00 00       	call   f0103f72 <cprintf>
f0100744:	83 c6 0c             	add    $0xc,%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100747:	83 c4 10             	add    $0x10,%esp
f010074a:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010074d:	75 e7                	jne    f0100736 <mon_help+0x29>
	return 0;
}
f010074f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100754:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100757:	5b                   	pop    %ebx
f0100758:	5e                   	pop    %esi
f0100759:	5f                   	pop    %edi
f010075a:	5d                   	pop    %ebp
f010075b:	c3                   	ret    

f010075c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	57                   	push   %edi
f0100760:	56                   	push   %esi
f0100761:	53                   	push   %ebx
f0100762:	83 ec 18             	sub    $0x18,%esp
f0100765:	e8 fd f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010076a:	81 c3 b6 d8 08 00    	add    $0x8d8b6,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 a9 7c f7 ff    	lea    -0x88357(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 f6 37 00 00       	call   f0103f72 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 54 7e f7 ff    	lea    -0x881ac(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 e1 37 00 00       	call   f0103f72 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 7c 7e f7 ff    	lea    -0x88184(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 c4 37 00 00       	call   f0103f72 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 39 5a 10 f0    	mov    $0xf0105a39,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 a0 7e f7 ff    	lea    -0x88160(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 a7 37 00 00       	call   f0103f72 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 40 01 19 f0    	mov    $0xf0190140,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 c4 7e f7 ff    	lea    -0x8813c(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 8a 37 00 00       	call   f0103f72 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 40 10 19 f0    	mov    $0xf0191040,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 e8 7e f7 ff    	lea    -0x88118(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 6d 37 00 00       	call   f0103f72 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 0c 7f f7 ff    	lea    -0x880f4(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 52 37 00 00       	call   f0103f72 <cprintf>
	return 0;
}
f0100820:	b8 00 00 00 00       	mov    $0x0,%eax
f0100825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100828:	5b                   	pop    %ebx
f0100829:	5e                   	pop    %esi
f010082a:	5f                   	pop    %edi
f010082b:	5d                   	pop    %ebp
f010082c:	c3                   	ret    

f010082d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	57                   	push   %edi
f0100831:	56                   	push   %esi
f0100832:	53                   	push   %ebx
f0100833:	83 ec 48             	sub    $0x48,%esp
f0100836:	e8 2c f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010083b:	81 c3 e5 d7 08 00    	add    $0x8d7e5,%ebx
	cprintf("Stack backtrace\n");
f0100841:	8d 83 c2 7c f7 ff    	lea    -0x8833e(%ebx),%eax
f0100847:	50                   	push   %eax
f0100848:	e8 25 37 00 00       	call   f0103f72 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010084d:	89 e8                	mov    %ebp,%eax
f010084f:	83 c4 10             	add    $0x10,%esp
		uint32_t arg_2 = *((uint32_t*)pointer + 1 + 2);
		uint32_t arg_3 = *((uint32_t*)pointer + 1 + 3);
		uint32_t arg_4 = *((uint32_t*)pointer + 1 + 4);
		uint32_t arg_5 = *((uint32_t*)pointer + 1 + 5);
		//
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f0100852:	8d 93 38 7f f7 ff    	lea    -0x880c8(%ebx),%edx
f0100858:	89 55 c4             	mov    %edx,-0x3c(%ebp)
				ebp_val, ret_pos, arg_1, arg_2, arg_3, arg_4, arg_5);

		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f010085b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010085e:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100861:	eb 06                	jmp    f0100869 <mon_backtrace+0x3c>
				eip_info.eip_file, eip_info.eip_line, 
				eip_info.eip_fn_namelen, eip_info.eip_fn_name,
				ret_pos - eip_info.eip_fn_addr);
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
			break;
		ebp_val = new_ebp_val;
f0100863:	89 f8                	mov    %edi,%eax
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
f0100865:	85 ff                	test   %edi,%edi
f0100867:	74 55                	je     f01008be <mon_backtrace+0x91>
		uint32_t new_ebp_val = *((uint32_t*)pointer);
f0100869:	8b 38                	mov    (%eax),%edi
		uint32_t ret_pos = *((uint32_t*)pointer + 1);
f010086b:	8b 70 04             	mov    0x4(%eax),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f010086e:	ff 70 18             	pushl  0x18(%eax)
f0100871:	ff 70 14             	pushl  0x14(%eax)
f0100874:	ff 70 10             	pushl  0x10(%eax)
f0100877:	ff 70 0c             	pushl  0xc(%eax)
f010087a:	ff 70 08             	pushl  0x8(%eax)
f010087d:	56                   	push   %esi
f010087e:	50                   	push   %eax
f010087f:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100882:	e8 eb 36 00 00       	call   f0103f72 <cprintf>
		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f0100887:	83 c4 18             	add    $0x18,%esp
f010088a:	ff 75 c0             	pushl  -0x40(%ebp)
f010088d:	56                   	push   %esi
f010088e:	e8 ef 41 00 00       	call   f0104a82 <debuginfo_eip>
f0100893:	83 c4 10             	add    $0x10,%esp
f0100896:	85 c0                	test   %eax,%eax
f0100898:	75 c9                	jne    f0100863 <mon_backtrace+0x36>
			cprintf("         %s:%d: %.*s+%d\r\n",
f010089a:	83 ec 08             	sub    $0x8,%esp
f010089d:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01008a0:	56                   	push   %esi
f01008a1:	ff 75 d8             	pushl  -0x28(%ebp)
f01008a4:	ff 75 dc             	pushl  -0x24(%ebp)
f01008a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01008ad:	8d 83 d3 7c f7 ff    	lea    -0x8832d(%ebx),%eax
f01008b3:	50                   	push   %eax
f01008b4:	e8 b9 36 00 00       	call   f0103f72 <cprintf>
f01008b9:	83 c4 20             	add    $0x20,%esp
f01008bc:	eb a5                	jmp    f0100863 <mon_backtrace+0x36>
	}
	return 0;
}
f01008be:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c6:	5b                   	pop    %ebx
f01008c7:	5e                   	pop    %esi
f01008c8:	5f                   	pop    %edi
f01008c9:	5d                   	pop    %ebp
f01008ca:	c3                   	ret    

f01008cb <mon_showmappings>:

int mon_showmappings(int argc, char** argv, struct Trapframe *tf){
f01008cb:	55                   	push   %ebp
f01008cc:	89 e5                	mov    %esp,%ebp
f01008ce:	57                   	push   %edi
f01008cf:	56                   	push   %esi
f01008d0:	53                   	push   %ebx
f01008d1:	83 ec 1c             	sub    $0x1c,%esp
f01008d4:	e8 8e f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01008d9:	81 c3 47 d7 08 00    	add    $0x8d747,%ebx
f01008df:	8b 75 08             	mov    0x8(%ebp),%esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;
	if (argc != 2 && argc != 3){
f01008e2:	8d 46 fe             	lea    -0x2(%esi),%eax
f01008e5:	83 f8 01             	cmp    $0x1,%eax
f01008e8:	76 1f                	jbe    f0100909 <mon_showmappings+0x3e>
		cprintf("Usage: showmappings ADDR1 [ADDR2]\n");
f01008ea:	83 ec 0c             	sub    $0xc,%esp
f01008ed:	8d 83 70 7f f7 ff    	lea    -0x88090(%ebx),%eax
f01008f3:	50                   	push   %eax
f01008f4:	e8 79 36 00 00       	call   f0103f72 <cprintf>
		return 0;
f01008f9:	83 c4 10             	add    $0x10,%esp
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
		}
	}

	return 0;
}
f01008fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100901:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100904:	5b                   	pop    %ebx
f0100905:	5e                   	pop    %esi
f0100906:	5f                   	pop    %edi
f0100907:	5d                   	pop    %ebp
f0100908:	c3                   	ret    
	long begin_itr = strtol(argv[1], NULL, 16);
f0100909:	83 ec 04             	sub    $0x4,%esp
f010090c:	6a 10                	push   $0x10
f010090e:	6a 00                	push   $0x0
f0100910:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100913:	ff 70 04             	pushl  0x4(%eax)
f0100916:	e8 07 4e 00 00       	call   f0105722 <strtol>
f010091b:	89 c7                	mov    %eax,%edi
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f010091d:	83 c4 10             	add    $0x10,%esp
f0100920:	83 fe 03             	cmp    $0x3,%esi
f0100923:	74 2f                	je     f0100954 <mon_showmappings+0x89>
	begin_itr = ROUNDUP(begin_itr, PGSIZE);
f0100925:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f010092b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	end_itr = ROUNDUP(end_itr, PGSIZE);
f0100931:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0100937:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010093d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
f0100940:	8d 83 ed 7c f7 ff    	lea    -0x88313(%ebx),%eax
f0100946:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
f0100949:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010094f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f0100952:	eb 35                	jmp    f0100989 <mon_showmappings+0xbe>
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100954:	83 ec 04             	sub    $0x4,%esp
f0100957:	6a 10                	push   $0x10
f0100959:	6a 00                	push   $0x0
f010095b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010095e:	ff 70 08             	pushl  0x8(%eax)
f0100961:	e8 bc 4d 00 00       	call   f0105722 <strtol>
	if (begin_itr > end_itr){
f0100966:	83 c4 10             	add    $0x10,%esp
f0100969:	39 c7                	cmp    %eax,%edi
f010096b:	7f b8                	jg     f0100925 <mon_showmappings+0x5a>
f010096d:	89 c2                	mov    %eax,%edx
	long begin_itr = strtol(argv[1], NULL, 16);
f010096f:	89 f8                	mov    %edi,%eax
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100971:	89 d7                	mov    %edx,%edi
f0100973:	eb b0                	jmp    f0100925 <mon_showmappings+0x5a>
			cprintf("Page doesn't exist\n");
f0100975:	83 ec 0c             	sub    $0xc,%esp
f0100978:	8d 83 ff 7c f7 ff    	lea    -0x88301(%ebx),%eax
f010097e:	50                   	push   %eax
f010097f:	e8 ee 35 00 00       	call   f0103f72 <cprintf>
f0100984:	83 c4 10             	add    $0x10,%esp
	long begin_itr = strtol(argv[1], NULL, 16);
f0100987:	89 fe                	mov    %edi,%esi
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f0100989:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010098c:	0f 8f 6a ff ff ff    	jg     f01008fc <mon_showmappings+0x31>
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
f0100992:	8d be 00 10 00 00    	lea    0x1000(%esi),%edi
f0100998:	83 ec 04             	sub    $0x4,%esp
f010099b:	57                   	push   %edi
f010099c:	56                   	push   %esi
f010099d:	ff 75 e0             	pushl  -0x20(%ebp)
f01009a0:	e8 cd 35 00 00       	call   f0103f72 <cprintf>
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
f01009a5:	83 c4 0c             	add    $0xc,%esp
f01009a8:	6a 00                	push   $0x0
f01009aa:	56                   	push   %esi
f01009ab:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01009ae:	ff 30                	pushl  (%eax)
f01009b0:	e8 0e 0c 00 00       	call   f01015c3 <pgdir_walk>
f01009b5:	89 c6                	mov    %eax,%esi
		if (pte_itr == NULL)
f01009b7:	83 c4 10             	add    $0x10,%esp
f01009ba:	85 c0                	test   %eax,%eax
f01009bc:	74 b7                	je     f0100975 <mon_showmappings+0xaa>
			cprintf("ADDR = %08x, ", PTE_ADDR(*pte_itr));
f01009be:	83 ec 08             	sub    $0x8,%esp
f01009c1:	8b 00                	mov    (%eax),%eax
f01009c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c8:	50                   	push   %eax
f01009c9:	8d 83 13 7d f7 ff    	lea    -0x882ed(%ebx),%eax
f01009cf:	50                   	push   %eax
f01009d0:	e8 9d 35 00 00       	call   f0103f72 <cprintf>
			cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f01009d5:	83 c4 08             	add    $0x8,%esp
f01009d8:	0f b6 06             	movzbl (%esi),%eax
f01009db:	83 e0 01             	and    $0x1,%eax
f01009de:	50                   	push   %eax
f01009df:	8d 83 21 7d f7 ff    	lea    -0x882df(%ebx),%eax
f01009e5:	50                   	push   %eax
f01009e6:	e8 87 35 00 00       	call   f0103f72 <cprintf>
			cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f01009eb:	83 c4 08             	add    $0x8,%esp
f01009ee:	0f b6 06             	movzbl (%esi),%eax
f01009f1:	83 e0 02             	and    $0x2,%eax
f01009f4:	50                   	push   %eax
f01009f5:	8d 83 30 7d f7 ff    	lea    -0x882d0(%ebx),%eax
f01009fb:	50                   	push   %eax
f01009fc:	e8 71 35 00 00       	call   f0103f72 <cprintf>
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100a01:	83 c4 08             	add    $0x8,%esp
f0100a04:	0f b6 06             	movzbl (%esi),%eax
f0100a07:	83 e0 04             	and    $0x4,%eax
f0100a0a:	50                   	push   %eax
f0100a0b:	8d 83 3f 7d f7 ff    	lea    -0x882c1(%ebx),%eax
f0100a11:	50                   	push   %eax
f0100a12:	e8 5b 35 00 00       	call   f0103f72 <cprintf>
f0100a17:	83 c4 10             	add    $0x10,%esp
f0100a1a:	e9 68 ff ff ff       	jmp    f0100987 <mon_showmappings+0xbc>

f0100a1f <mon_setperm>:

int mon_setperm(int argc, char** argv, struct Trapframe *tf){
f0100a1f:	55                   	push   %ebp
f0100a20:	89 e5                	mov    %esp,%ebp
f0100a22:	57                   	push   %edi
f0100a23:	56                   	push   %esi
f0100a24:	53                   	push   %ebx
f0100a25:	83 ec 0c             	sub    $0xc,%esp
f0100a28:	e8 3a f7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100a2d:	81 c3 f3 d5 08 00    	add    $0x8d5f3,%ebx
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 4){
f0100a33:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100a37:	74 1f                	je     f0100a58 <mon_setperm+0x39>
		cprintf("usage: perm ADDR [add/clear] [U/W/P] or perm ADDR [set] perm_code");
f0100a39:	83 ec 0c             	sub    $0xc,%esp
f0100a3c:	8d 83 94 7f f7 ff    	lea    -0x8806c(%ebx),%eax
f0100a42:	50                   	push   %eax
f0100a43:	e8 2a 35 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100a48:	83 c4 10             	add    $0x10,%esp
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));

	return 0;
}
f0100a4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a50:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a53:	5b                   	pop    %ebx
f0100a54:	5e                   	pop    %esi
f0100a55:	5f                   	pop    %edi
f0100a56:	5d                   	pop    %ebp
f0100a57:	c3                   	ret    
	long addr = strtol(argv[1], NULL, 16);
f0100a58:	83 ec 04             	sub    $0x4,%esp
f0100a5b:	6a 10                	push   $0x10
f0100a5d:	6a 00                	push   $0x0
f0100a5f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a62:	ff 70 04             	pushl  0x4(%eax)
f0100a65:	e8 b8 4c 00 00       	call   f0105722 <strtol>
	pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*) addr, false);
f0100a6a:	83 c4 0c             	add    $0xc,%esp
f0100a6d:	6a 00                	push   $0x0
f0100a6f:	50                   	push   %eax
f0100a70:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0100a76:	ff 30                	pushl  (%eax)
f0100a78:	e8 46 0b 00 00       	call   f01015c3 <pgdir_walk>
f0100a7d:	89 c6                	mov    %eax,%esi
	if (pte_itr == NULL){
f0100a7f:	83 c4 10             	add    $0x10,%esp
f0100a82:	85 c0                	test   %eax,%eax
f0100a84:	0f 84 0e 01 00 00    	je     f0100b98 <mon_setperm+0x179>
	cprintf("Before:");
f0100a8a:	83 ec 0c             	sub    $0xc,%esp
f0100a8d:	8d 83 61 7d f7 ff    	lea    -0x8829f(%ebx),%eax
f0100a93:	50                   	push   %eax
f0100a94:	e8 d9 34 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100a99:	83 c4 08             	add    $0x8,%esp
f0100a9c:	0f b6 06             	movzbl (%esi),%eax
f0100a9f:	83 e0 01             	and    $0x1,%eax
f0100aa2:	50                   	push   %eax
f0100aa3:	8d 83 21 7d f7 ff    	lea    -0x882df(%ebx),%eax
f0100aa9:	50                   	push   %eax
f0100aaa:	e8 c3 34 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100aaf:	83 c4 08             	add    $0x8,%esp
f0100ab2:	0f b6 06             	movzbl (%esi),%eax
f0100ab5:	83 e0 02             	and    $0x2,%eax
f0100ab8:	50                   	push   %eax
f0100ab9:	8d 83 30 7d f7 ff    	lea    -0x882d0(%ebx),%eax
f0100abf:	50                   	push   %eax
f0100ac0:	e8 ad 34 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100ac5:	83 c4 08             	add    $0x8,%esp
f0100ac8:	0f b6 06             	movzbl (%esi),%eax
f0100acb:	83 e0 04             	and    $0x4,%eax
f0100ace:	50                   	push   %eax
f0100acf:	8d 83 3f 7d f7 ff    	lea    -0x882c1(%ebx),%eax
f0100ad5:	50                   	push   %eax
f0100ad6:	e8 97 34 00 00       	call   f0103f72 <cprintf>
	if (strcmp("set", argv[2]) == 0){
f0100adb:	83 c4 08             	add    $0x8,%esp
f0100ade:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ae1:	ff 70 08             	pushl  0x8(%eax)
f0100ae4:	8d 83 69 7d f7 ff    	lea    -0x88297(%ebx),%eax
f0100aea:	50                   	push   %eax
f0100aeb:	e8 79 4a 00 00       	call   f0105569 <strcmp>
f0100af0:	83 c4 10             	add    $0x10,%esp
f0100af3:	85 c0                	test   %eax,%eax
f0100af5:	0f 84 b4 00 00 00    	je     f0100baf <mon_setperm+0x190>
	if (strcmp("add", argv[2]) == 0){
f0100afb:	83 ec 08             	sub    $0x8,%esp
f0100afe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b01:	ff 70 08             	pushl  0x8(%eax)
f0100b04:	8d 83 6d 7d f7 ff    	lea    -0x88293(%ebx),%eax
f0100b0a:	50                   	push   %eax
f0100b0b:	e8 59 4a 00 00       	call   f0105569 <strcmp>
f0100b10:	89 c7                	mov    %eax,%edi
f0100b12:	83 c4 10             	add    $0x10,%esp
f0100b15:	85 c0                	test   %eax,%eax
f0100b17:	0f 84 b8 00 00 00    	je     f0100bd5 <mon_setperm+0x1b6>
	if (strcmp("clear", argv[2]) == 0){
f0100b1d:	83 ec 08             	sub    $0x8,%esp
f0100b20:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b23:	ff 70 08             	pushl  0x8(%eax)
f0100b26:	8d 83 71 7d f7 ff    	lea    -0x8828f(%ebx),%eax
f0100b2c:	50                   	push   %eax
f0100b2d:	e8 37 4a 00 00       	call   f0105569 <strcmp>
f0100b32:	89 c7                	mov    %eax,%edi
f0100b34:	83 c4 10             	add    $0x10,%esp
f0100b37:	85 c0                	test   %eax,%eax
f0100b39:	0f 84 f9 00 00 00    	je     f0100c38 <mon_setperm+0x219>
	cprintf("After:");
f0100b3f:	83 ec 0c             	sub    $0xc,%esp
f0100b42:	8d 83 77 7d f7 ff    	lea    -0x88289(%ebx),%eax
f0100b48:	50                   	push   %eax
f0100b49:	e8 24 34 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100b4e:	83 c4 08             	add    $0x8,%esp
f0100b51:	0f b6 06             	movzbl (%esi),%eax
f0100b54:	83 e0 01             	and    $0x1,%eax
f0100b57:	50                   	push   %eax
f0100b58:	8d 83 21 7d f7 ff    	lea    -0x882df(%ebx),%eax
f0100b5e:	50                   	push   %eax
f0100b5f:	e8 0e 34 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100b64:	83 c4 08             	add    $0x8,%esp
f0100b67:	0f b6 06             	movzbl (%esi),%eax
f0100b6a:	83 e0 02             	and    $0x2,%eax
f0100b6d:	50                   	push   %eax
f0100b6e:	8d 83 30 7d f7 ff    	lea    -0x882d0(%ebx),%eax
f0100b74:	50                   	push   %eax
f0100b75:	e8 f8 33 00 00       	call   f0103f72 <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100b7a:	83 c4 08             	add    $0x8,%esp
f0100b7d:	0f b6 06             	movzbl (%esi),%eax
f0100b80:	83 e0 04             	and    $0x4,%eax
f0100b83:	50                   	push   %eax
f0100b84:	8d 83 3f 7d f7 ff    	lea    -0x882c1(%ebx),%eax
f0100b8a:	50                   	push   %eax
f0100b8b:	e8 e2 33 00 00       	call   f0103f72 <cprintf>
	return 0;
f0100b90:	83 c4 10             	add    $0x10,%esp
f0100b93:	e9 b3 fe ff ff       	jmp    f0100a4b <mon_setperm+0x2c>
		cprintf("Page Doesn't Exist!");
f0100b98:	83 ec 0c             	sub    $0xc,%esp
f0100b9b:	8d 83 4d 7d f7 ff    	lea    -0x882b3(%ebx),%eax
f0100ba1:	50                   	push   %eax
f0100ba2:	e8 cb 33 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100ba7:	83 c4 10             	add    $0x10,%esp
f0100baa:	e9 9c fe ff ff       	jmp    f0100a4b <mon_setperm+0x2c>
		int perm_code = strtol(argv[3], NULL, 2);
f0100baf:	83 ec 04             	sub    $0x4,%esp
f0100bb2:	6a 02                	push   $0x2
f0100bb4:	6a 00                	push   $0x0
f0100bb6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bb9:	ff 70 0c             	pushl  0xc(%eax)
f0100bbc:	e8 61 4b 00 00       	call   f0105722 <strtol>
		*pte_itr = *pte_itr ^ (perm_code & 7) ^ (*pte_itr & 7);
f0100bc1:	8b 16                	mov    (%esi),%edx
f0100bc3:	83 e2 f8             	and    $0xfffffff8,%edx
f0100bc6:	83 e0 07             	and    $0x7,%eax
f0100bc9:	09 d0                	or     %edx,%eax
f0100bcb:	89 06                	mov    %eax,(%esi)
f0100bcd:	83 c4 10             	add    $0x10,%esp
f0100bd0:	e9 26 ff ff ff       	jmp    f0100afb <mon_setperm+0xdc>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100bd5:	83 ec 08             	sub    $0x8,%esp
f0100bd8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bdb:	ff 70 0c             	pushl  0xc(%eax)
f0100bde:	8d 83 b6 83 f7 ff    	lea    -0x87c4a(%ebx),%eax
f0100be4:	50                   	push   %eax
f0100be5:	e8 7f 49 00 00       	call   f0105569 <strcmp>
f0100bea:	83 c4 08             	add    $0x8,%esp
f0100bed:	85 c0                	test   %eax,%eax
f0100bef:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100bf3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bf6:	ff 70 0c             	pushl  0xc(%eax)
f0100bf9:	8d 83 63 84 f7 ff    	lea    -0x87b9d(%ebx),%eax
f0100bff:	50                   	push   %eax
f0100c00:	e8 64 49 00 00       	call   f0105569 <strcmp>
f0100c05:	83 c4 08             	add    $0x8,%esp
f0100c08:	85 c0                	test   %eax,%eax
f0100c0a:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c0f:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100c12:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c15:	ff 70 0c             	pushl  0xc(%eax)
f0100c18:	8d 83 74 84 f7 ff    	lea    -0x87b8c(%ebx),%eax
f0100c1e:	50                   	push   %eax
f0100c1f:	e8 45 49 00 00       	call   f0105569 <strcmp>
f0100c24:	83 c4 10             	add    $0x10,%esp
f0100c27:	85 c0                	test   %eax,%eax
f0100c29:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c2e:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr | perm_code;
f0100c31:	09 3e                	or     %edi,(%esi)
f0100c33:	e9 e5 fe ff ff       	jmp    f0100b1d <mon_setperm+0xfe>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100c38:	83 ec 08             	sub    $0x8,%esp
f0100c3b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c3e:	ff 70 0c             	pushl  0xc(%eax)
f0100c41:	8d 83 b6 83 f7 ff    	lea    -0x87c4a(%ebx),%eax
f0100c47:	50                   	push   %eax
f0100c48:	e8 1c 49 00 00       	call   f0105569 <strcmp>
f0100c4d:	83 c4 08             	add    $0x8,%esp
f0100c50:	85 c0                	test   %eax,%eax
f0100c52:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100c56:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c59:	ff 70 0c             	pushl  0xc(%eax)
f0100c5c:	8d 83 63 84 f7 ff    	lea    -0x87b9d(%ebx),%eax
f0100c62:	50                   	push   %eax
f0100c63:	e8 01 49 00 00       	call   f0105569 <strcmp>
f0100c68:	83 c4 08             	add    $0x8,%esp
f0100c6b:	85 c0                	test   %eax,%eax
f0100c6d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c72:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100c75:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c78:	ff 70 0c             	pushl  0xc(%eax)
f0100c7b:	8d 83 74 84 f7 ff    	lea    -0x87b8c(%ebx),%eax
f0100c81:	50                   	push   %eax
f0100c82:	e8 e2 48 00 00       	call   f0105569 <strcmp>
f0100c87:	83 c4 10             	add    $0x10,%esp
f0100c8a:	85 c0                	test   %eax,%eax
f0100c8c:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c91:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr & (~perm_code);
f0100c94:	f7 d7                	not    %edi
f0100c96:	21 3e                	and    %edi,(%esi)
f0100c98:	e9 a2 fe ff ff       	jmp    f0100b3f <mon_setperm+0x120>

f0100c9d <moniter_ci>:

int moniter_ci(int argc, char** argv, struct Trapframe *tf){
f0100c9d:	55                   	push   %ebp
f0100c9e:	89 e5                	mov    %esp,%ebp
f0100ca0:	57                   	push   %edi
f0100ca1:	56                   	push   %esi
f0100ca2:	53                   	push   %ebx
f0100ca3:	83 ec 0c             	sub    $0xc,%esp
f0100ca6:	e8 bc f4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100cab:	81 c3 75 d3 08 00    	add    $0x8d375,%ebx
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
f0100cb1:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100cb5:	75 25                	jne    f0100cdc <moniter_ci+0x3f>
		cprintf("usage: c\n continue\n");
		return 0;
	}
	if (tf == NULL){
f0100cb7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100cbb:	75 33                	jne    f0100cf0 <moniter_ci+0x53>
		cprintf("Not in backtrace mode\n");
f0100cbd:	83 ec 0c             	sub    $0xc,%esp
f0100cc0:	8d 83 92 7d f7 ff    	lea    -0x8826e(%ebx),%eax
f0100cc6:	50                   	push   %eax
f0100cc7:	e8 a6 32 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100ccc:	83 c4 10             	add    $0x10,%esp
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags &= ~0x100;
	env_run(curenv);
	return 0;
}
f0100ccf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd7:	5b                   	pop    %ebx
f0100cd8:	5e                   	pop    %esi
f0100cd9:	5f                   	pop    %edi
f0100cda:	5d                   	pop    %ebp
f0100cdb:	c3                   	ret    
		cprintf("usage: c\n continue\n");
f0100cdc:	83 ec 0c             	sub    $0xc,%esp
f0100cdf:	8d 83 7e 7d f7 ff    	lea    -0x88282(%ebx),%eax
f0100ce5:	50                   	push   %eax
f0100ce6:	e8 87 32 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100ceb:	83 c4 10             	add    $0x10,%esp
f0100cee:	eb df                	jmp    f0100ccf <moniter_ci+0x32>
	curenv->env_tf = *tf;
f0100cf0:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0100cf6:	b9 11 00 00 00       	mov    $0x11,%ecx
f0100cfb:	8b 38                	mov    (%eax),%edi
f0100cfd:	8b 75 10             	mov    0x10(%ebp),%esi
f0100d00:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	curenv->env_tf.tf_eflags &= ~0x100;
f0100d02:	8b 00                	mov    (%eax),%eax
f0100d04:	81 60 38 ff fe ff ff 	andl   $0xfffffeff,0x38(%eax)
	env_run(curenv);
f0100d0b:	83 ec 0c             	sub    $0xc,%esp
f0100d0e:	50                   	push   %eax
f0100d0f:	e8 62 31 00 00       	call   f0103e76 <env_run>

f0100d14 <moniter_si>:
int moniter_si(int argc, char** argv, struct Trapframe *tf){
f0100d14:	55                   	push   %ebp
f0100d15:	89 e5                	mov    %esp,%ebp
f0100d17:	57                   	push   %edi
f0100d18:	56                   	push   %esi
f0100d19:	53                   	push   %ebx
f0100d1a:	83 ec 0c             	sub    $0xc,%esp
f0100d1d:	e8 45 f4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100d22:	81 c3 fe d2 08 00    	add    $0x8d2fe,%ebx
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
f0100d28:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100d2c:	75 25                	jne    f0100d53 <moniter_si+0x3f>
		cprintf("usage: si\n stepi\n");
		return 0;
	}
	if (tf == NULL){
f0100d2e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d32:	75 33                	jne    f0100d67 <moniter_si+0x53>
		cprintf("Not in backtrace mode\n");
f0100d34:	83 ec 0c             	sub    $0xc,%esp
f0100d37:	8d 83 92 7d f7 ff    	lea    -0x8826e(%ebx),%eax
f0100d3d:	50                   	push   %eax
f0100d3e:	e8 2f 32 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100d43:	83 c4 10             	add    $0x10,%esp
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags |= 0x100;
	env_run(curenv);
	return 0;
}
f0100d46:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d4e:	5b                   	pop    %ebx
f0100d4f:	5e                   	pop    %esi
f0100d50:	5f                   	pop    %edi
f0100d51:	5d                   	pop    %ebp
f0100d52:	c3                   	ret    
		cprintf("usage: si\n stepi\n");
f0100d53:	83 ec 0c             	sub    $0xc,%esp
f0100d56:	8d 83 a9 7d f7 ff    	lea    -0x88257(%ebx),%eax
f0100d5c:	50                   	push   %eax
f0100d5d:	e8 10 32 00 00       	call   f0103f72 <cprintf>
		return 0;
f0100d62:	83 c4 10             	add    $0x10,%esp
f0100d65:	eb df                	jmp    f0100d46 <moniter_si+0x32>
	curenv->env_tf = *tf;
f0100d67:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0100d6d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0100d72:	8b 38                	mov    (%eax),%edi
f0100d74:	8b 75 10             	mov    0x10(%ebp),%esi
f0100d77:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	curenv->env_tf.tf_eflags |= 0x100;
f0100d79:	8b 00                	mov    (%eax),%eax
f0100d7b:	81 48 38 00 01 00 00 	orl    $0x100,0x38(%eax)
	env_run(curenv);
f0100d82:	83 ec 0c             	sub    $0xc,%esp
f0100d85:	50                   	push   %eax
f0100d86:	e8 eb 30 00 00       	call   f0103e76 <env_run>

f0100d8b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100d8b:	55                   	push   %ebp
f0100d8c:	89 e5                	mov    %esp,%ebp
f0100d8e:	57                   	push   %edi
f0100d8f:	56                   	push   %esi
f0100d90:	53                   	push   %ebx
f0100d91:	83 ec 68             	sub    $0x68,%esp
f0100d94:	e8 ce f3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100d99:	81 c3 87 d2 08 00    	add    $0x8d287,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100d9f:	8d 83 d8 7f f7 ff    	lea    -0x88028(%ebx),%eax
f0100da5:	50                   	push   %eax
f0100da6:	e8 c7 31 00 00       	call   f0103f72 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100dab:	8d 83 fc 7f f7 ff    	lea    -0x88004(%ebx),%eax
f0100db1:	89 04 24             	mov    %eax,(%esp)
f0100db4:	e8 b9 31 00 00       	call   f0103f72 <cprintf>

	if (tf != NULL)
f0100db9:	83 c4 10             	add    $0x10,%esp
f0100dbc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100dc0:	74 0e                	je     f0100dd0 <monitor+0x45>
		print_trapframe(tf);
f0100dc2:	83 ec 0c             	sub    $0xc,%esp
f0100dc5:	ff 75 08             	pushl  0x8(%ebp)
f0100dc8:	e8 b0 36 00 00       	call   f010447d <print_trapframe>
f0100dcd:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100dd0:	8d bb bf 7d f7 ff    	lea    -0x88241(%ebx),%edi
f0100dd6:	eb 4a                	jmp    f0100e22 <monitor+0x97>
f0100dd8:	83 ec 08             	sub    $0x8,%esp
f0100ddb:	0f be c0             	movsbl %al,%eax
f0100dde:	50                   	push   %eax
f0100ddf:	57                   	push   %edi
f0100de0:	e8 e2 47 00 00       	call   f01055c7 <strchr>
f0100de5:	83 c4 10             	add    $0x10,%esp
f0100de8:	85 c0                	test   %eax,%eax
f0100dea:	74 08                	je     f0100df4 <monitor+0x69>
			*buf++ = 0;
f0100dec:	c6 06 00             	movb   $0x0,(%esi)
f0100def:	8d 76 01             	lea    0x1(%esi),%esi
f0100df2:	eb 79                	jmp    f0100e6d <monitor+0xe2>
		if (*buf == 0)
f0100df4:	80 3e 00             	cmpb   $0x0,(%esi)
f0100df7:	74 7f                	je     f0100e78 <monitor+0xed>
		if (argc == MAXARGS - 1) {
f0100df9:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100dfd:	74 0f                	je     f0100e0e <monitor+0x83>
		argv[argc++] = buf;
f0100dff:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100e02:	8d 48 01             	lea    0x1(%eax),%ecx
f0100e05:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100e08:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100e0c:	eb 44                	jmp    f0100e52 <monitor+0xc7>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100e0e:	83 ec 08             	sub    $0x8,%esp
f0100e11:	6a 10                	push   $0x10
f0100e13:	8d 83 c4 7d f7 ff    	lea    -0x8823c(%ebx),%eax
f0100e19:	50                   	push   %eax
f0100e1a:	e8 53 31 00 00       	call   f0103f72 <cprintf>
f0100e1f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100e22:	8d 83 bb 7d f7 ff    	lea    -0x88245(%ebx),%eax
f0100e28:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100e2b:	83 ec 0c             	sub    $0xc,%esp
f0100e2e:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100e31:	e8 59 45 00 00       	call   f010538f <readline>
f0100e36:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100e38:	83 c4 10             	add    $0x10,%esp
f0100e3b:	85 c0                	test   %eax,%eax
f0100e3d:	74 ec                	je     f0100e2b <monitor+0xa0>
	argv[argc] = 0;
f0100e3f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100e46:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100e4d:	eb 1e                	jmp    f0100e6d <monitor+0xe2>
			buf++;
f0100e4f:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e52:	0f b6 06             	movzbl (%esi),%eax
f0100e55:	84 c0                	test   %al,%al
f0100e57:	74 14                	je     f0100e6d <monitor+0xe2>
f0100e59:	83 ec 08             	sub    $0x8,%esp
f0100e5c:	0f be c0             	movsbl %al,%eax
f0100e5f:	50                   	push   %eax
f0100e60:	57                   	push   %edi
f0100e61:	e8 61 47 00 00       	call   f01055c7 <strchr>
f0100e66:	83 c4 10             	add    $0x10,%esp
f0100e69:	85 c0                	test   %eax,%eax
f0100e6b:	74 e2                	je     f0100e4f <monitor+0xc4>
		while (*buf && strchr(WHITESPACE, *buf))
f0100e6d:	0f b6 06             	movzbl (%esi),%eax
f0100e70:	84 c0                	test   %al,%al
f0100e72:	0f 85 60 ff ff ff    	jne    f0100dd8 <monitor+0x4d>
	argv[argc] = 0;
f0100e78:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100e7b:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100e82:	00 
	if (argc == 0)
f0100e83:	85 c0                	test   %eax,%eax
f0100e85:	74 9b                	je     f0100e22 <monitor+0x97>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100e87:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e8c:	83 ec 08             	sub    $0x8,%esp
f0100e8f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100e92:	ff b4 83 20 20 00 00 	pushl  0x2020(%ebx,%eax,4)
f0100e99:	ff 75 a8             	pushl  -0x58(%ebp)
f0100e9c:	e8 c8 46 00 00       	call   f0105569 <strcmp>
f0100ea1:	83 c4 10             	add    $0x10,%esp
f0100ea4:	85 c0                	test   %eax,%eax
f0100ea6:	74 22                	je     f0100eca <monitor+0x13f>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100ea8:	83 c6 01             	add    $0x1,%esi
f0100eab:	83 fe 09             	cmp    $0x9,%esi
f0100eae:	75 dc                	jne    f0100e8c <monitor+0x101>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100eb0:	83 ec 08             	sub    $0x8,%esp
f0100eb3:	ff 75 a8             	pushl  -0x58(%ebp)
f0100eb6:	8d 83 e1 7d f7 ff    	lea    -0x8821f(%ebx),%eax
f0100ebc:	50                   	push   %eax
f0100ebd:	e8 b0 30 00 00       	call   f0103f72 <cprintf>
f0100ec2:	83 c4 10             	add    $0x10,%esp
f0100ec5:	e9 58 ff ff ff       	jmp    f0100e22 <monitor+0x97>
			return commands[i].func(argc, argv, tf);
f0100eca:	83 ec 04             	sub    $0x4,%esp
f0100ecd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100ed0:	ff 75 08             	pushl  0x8(%ebp)
f0100ed3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ed6:	52                   	push   %edx
f0100ed7:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100eda:	ff 94 83 28 20 00 00 	call   *0x2028(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ee1:	83 c4 10             	add    $0x10,%esp
f0100ee4:	85 c0                	test   %eax,%eax
f0100ee6:	0f 89 36 ff ff ff    	jns    f0100e22 <monitor+0x97>
				break;
	}
}
f0100eec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eef:	5b                   	pop    %ebx
f0100ef0:	5e                   	pop    %esi
f0100ef1:	5f                   	pop    %edi
f0100ef2:	5d                   	pop    %ebp
f0100ef3:	c3                   	ret    

f0100ef4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ef4:	55                   	push   %ebp
f0100ef5:	89 e5                	mov    %esp,%ebp
f0100ef7:	57                   	push   %edi
f0100ef8:	56                   	push   %esi
f0100ef9:	53                   	push   %ebx
f0100efa:	83 ec 18             	sub    $0x18,%esp
f0100efd:	e8 65 f2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100f02:	81 c3 1e d1 08 00    	add    $0x8d11e,%ebx
f0100f08:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100f0a:	50                   	push   %eax
f0100f0b:	e8 db 2f 00 00       	call   f0103eeb <mc146818_read>
f0100f10:	89 c6                	mov    %eax,%esi
f0100f12:	83 c7 01             	add    $0x1,%edi
f0100f15:	89 3c 24             	mov    %edi,(%esp)
f0100f18:	e8 ce 2f 00 00       	call   f0103eeb <mc146818_read>
f0100f1d:	c1 e0 08             	shl    $0x8,%eax
f0100f20:	09 f0                	or     %esi,%eax
}
f0100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f25:	5b                   	pop    %ebx
f0100f26:	5e                   	pop    %esi
f0100f27:	5f                   	pop    %edi
f0100f28:	5d                   	pop    %ebp
f0100f29:	c3                   	ret    

f0100f2a <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100f2a:	55                   	push   %ebp
f0100f2b:	89 e5                	mov    %esp,%ebp
f0100f2d:	56                   	push   %esi
f0100f2e:	53                   	push   %ebx
f0100f2f:	e8 27 28 00 00       	call   f010375b <__x86.get_pc_thunk.dx>
f0100f34:	81 c2 ec d0 08 00    	add    $0x8d0ec,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100f3a:	83 ba 58 23 00 00 00 	cmpl   $0x0,0x2358(%edx)
f0100f41:	74 3f                	je     f0100f82 <boot_alloc+0x58>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	if (!n)
f0100f43:	85 c0                	test   %eax,%eax
f0100f45:	74 55                	je     f0100f9c <boot_alloc+0x72>
		return nextfree;
	char* new_nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100f47:	8b b2 58 23 00 00    	mov    0x2358(%edx),%esi
f0100f4d:	8d 8c 06 ff 0f 00 00 	lea    0xfff(%esi,%eax,1),%ecx
f0100f54:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100f5a:	39 ce                	cmp    %ecx,%esi
f0100f5c:	73 46                	jae    f0100fa4 <boot_alloc+0x7a>
		((uintptr_t) new_nextfree <= (uintptr_t) KERNBASE + npages * PGSIZE)){
f0100f5e:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0100f64:	8b 18                	mov    (%eax),%ebx
f0100f66:	81 c3 00 00 0f 00    	add    $0xf0000,%ebx
f0100f6c:	c1 e3 0c             	shl    $0xc,%ebx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100f6f:	39 cb                	cmp    %ecx,%ebx
f0100f71:	72 31                	jb     f0100fa4 <boot_alloc+0x7a>
		//May Alloc too much memory, and the pinter excedded 2^32
		char* result = nextfree;
		nextfree = new_nextfree;
f0100f73:	89 8a 58 23 00 00    	mov    %ecx,0x2358(%edx)
		return (void*) result;
	}
	panic("Warning : bad alloc request");
	return NULL;
}
f0100f79:	89 f0                	mov    %esi,%eax
f0100f7b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f7e:	5b                   	pop    %ebx
f0100f7f:	5e                   	pop    %esi
f0100f80:	5d                   	pop    %ebp
f0100f81:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100f82:	c7 c1 40 10 19 f0    	mov    $0xf0191040,%ecx
f0100f88:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100f8e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100f94:	89 8a 58 23 00 00    	mov    %ecx,0x2358(%edx)
f0100f9a:	eb a7                	jmp    f0100f43 <boot_alloc+0x19>
		return nextfree;
f0100f9c:	8b b2 58 23 00 00    	mov    0x2358(%edx),%esi
f0100fa2:	eb d5                	jmp    f0100f79 <boot_alloc+0x4f>
	panic("Warning : bad alloc request");
f0100fa4:	83 ec 04             	sub    $0x4,%esp
f0100fa7:	8d 82 85 81 f7 ff    	lea    -0x87e7b(%edx),%eax
f0100fad:	50                   	push   %eax
f0100fae:	6a 75                	push   $0x75
f0100fb0:	8d 82 a1 81 f7 ff    	lea    -0x87e5f(%edx),%eax
f0100fb6:	50                   	push   %eax
f0100fb7:	89 d3                	mov    %edx,%ebx
f0100fb9:	e8 f3 f0 ff ff       	call   f01000b1 <_panic>

f0100fbe <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100fbe:	55                   	push   %ebp
f0100fbf:	89 e5                	mov    %esp,%ebp
f0100fc1:	56                   	push   %esi
f0100fc2:	53                   	push   %ebx
f0100fc3:	e8 97 27 00 00       	call   f010375f <__x86.get_pc_thunk.cx>
f0100fc8:	81 c1 58 d0 08 00    	add    $0x8d058,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100fce:	89 d3                	mov    %edx,%ebx
f0100fd0:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100fd3:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100fd6:	a8 01                	test   $0x1,%al
f0100fd8:	74 5a                	je     f0101034 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100fda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fdf:	89 c6                	mov    %eax,%esi
f0100fe1:	c1 ee 0c             	shr    $0xc,%esi
f0100fe4:	c7 c3 48 10 19 f0    	mov    $0xf0191048,%ebx
f0100fea:	3b 33                	cmp    (%ebx),%esi
f0100fec:	73 2b                	jae    f0101019 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100fee:	c1 ea 0c             	shr    $0xc,%edx
f0100ff1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ff7:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ffe:	89 c2                	mov    %eax,%edx
f0101000:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0101003:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101008:	85 d2                	test   %edx,%edx
f010100a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010100f:	0f 44 c2             	cmove  %edx,%eax
}
f0101012:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101015:	5b                   	pop    %ebx
f0101016:	5e                   	pop    %esi
f0101017:	5d                   	pop    %ebp
f0101018:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101019:	50                   	push   %eax
f010101a:	8d 81 84 84 f7 ff    	lea    -0x87b7c(%ecx),%eax
f0101020:	50                   	push   %eax
f0101021:	68 33 03 00 00       	push   $0x333
f0101026:	8d 81 a1 81 f7 ff    	lea    -0x87e5f(%ecx),%eax
f010102c:	50                   	push   %eax
f010102d:	89 cb                	mov    %ecx,%ebx
f010102f:	e8 7d f0 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0101034:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101039:	eb d7                	jmp    f0101012 <check_va2pa+0x54>

f010103b <check_page_free_list>:
{
f010103b:	55                   	push   %ebp
f010103c:	89 e5                	mov    %esp,%ebp
f010103e:	57                   	push   %edi
f010103f:	56                   	push   %esi
f0101040:	53                   	push   %ebx
f0101041:	83 ec 3c             	sub    $0x3c,%esp
f0101044:	e8 1e 27 00 00       	call   f0103767 <__x86.get_pc_thunk.di>
f0101049:	81 c7 d7 cf 08 00    	add    $0x8cfd7,%edi
f010104f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101052:	84 c0                	test   %al,%al
f0101054:	0f 85 dd 02 00 00    	jne    f0101337 <check_page_free_list+0x2fc>
	if (!page_free_list)
f010105a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010105d:	83 b8 60 23 00 00 00 	cmpl   $0x0,0x2360(%eax)
f0101064:	74 0c                	je     f0101072 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101066:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f010106d:	e9 2f 03 00 00       	jmp    f01013a1 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0101072:	83 ec 04             	sub    $0x4,%esp
f0101075:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101078:	8d 83 a8 84 f7 ff    	lea    -0x87b58(%ebx),%eax
f010107e:	50                   	push   %eax
f010107f:	68 6f 02 00 00       	push   $0x26f
f0101084:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010108a:	50                   	push   %eax
f010108b:	e8 21 f0 ff ff       	call   f01000b1 <_panic>
f0101090:	50                   	push   %eax
f0101091:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101094:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f010109a:	50                   	push   %eax
f010109b:	6a 56                	push   $0x56
f010109d:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f01010a3:	50                   	push   %eax
f01010a4:	e8 08 f0 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010a9:	8b 36                	mov    (%esi),%esi
f01010ab:	85 f6                	test   %esi,%esi
f01010ad:	74 40                	je     f01010ef <check_page_free_list+0xb4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010af:	89 f0                	mov    %esi,%eax
f01010b1:	2b 07                	sub    (%edi),%eax
f01010b3:	c1 f8 03             	sar    $0x3,%eax
f01010b6:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01010b9:	89 c2                	mov    %eax,%edx
f01010bb:	c1 ea 16             	shr    $0x16,%edx
f01010be:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f01010c1:	73 e6                	jae    f01010a9 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f01010c3:	89 c2                	mov    %eax,%edx
f01010c5:	c1 ea 0c             	shr    $0xc,%edx
f01010c8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01010cb:	3b 11                	cmp    (%ecx),%edx
f01010cd:	73 c1                	jae    f0101090 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f01010cf:	83 ec 04             	sub    $0x4,%esp
f01010d2:	68 80 00 00 00       	push   $0x80
f01010d7:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f01010dc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010e1:	50                   	push   %eax
f01010e2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01010e5:	e8 1a 45 00 00       	call   f0105604 <memset>
f01010ea:	83 c4 10             	add    $0x10,%esp
f01010ed:	eb ba                	jmp    f01010a9 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f01010ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f4:	e8 31 fe ff ff       	call   f0100f2a <boot_alloc>
f01010f9:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010fc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01010ff:	8b 97 60 23 00 00    	mov    0x2360(%edi),%edx
		assert(pp >= pages);
f0101105:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f010110b:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f010110d:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0101113:	8b 00                	mov    (%eax),%eax
f0101115:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101118:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010111b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f010111e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101123:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101126:	e9 08 01 00 00       	jmp    f0101233 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f010112b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010112e:	8d 83 bb 81 f7 ff    	lea    -0x87e45(%ebx),%eax
f0101134:	50                   	push   %eax
f0101135:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010113b:	50                   	push   %eax
f010113c:	68 89 02 00 00       	push   $0x289
f0101141:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101147:	50                   	push   %eax
f0101148:	e8 64 ef ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f010114d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101150:	8d 83 dc 81 f7 ff    	lea    -0x87e24(%ebx),%eax
f0101156:	50                   	push   %eax
f0101157:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010115d:	50                   	push   %eax
f010115e:	68 8a 02 00 00       	push   $0x28a
f0101163:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101169:	50                   	push   %eax
f010116a:	e8 42 ef ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010116f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101172:	8d 83 cc 84 f7 ff    	lea    -0x87b34(%ebx),%eax
f0101178:	50                   	push   %eax
f0101179:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010117f:	50                   	push   %eax
f0101180:	68 8b 02 00 00       	push   $0x28b
f0101185:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010118b:	50                   	push   %eax
f010118c:	e8 20 ef ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0101191:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101194:	8d 83 f0 81 f7 ff    	lea    -0x87e10(%ebx),%eax
f010119a:	50                   	push   %eax
f010119b:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01011a1:	50                   	push   %eax
f01011a2:	68 8e 02 00 00       	push   $0x28e
f01011a7:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01011ad:	50                   	push   %eax
f01011ae:	e8 fe ee ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011b3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011b6:	8d 83 01 82 f7 ff    	lea    -0x87dff(%ebx),%eax
f01011bc:	50                   	push   %eax
f01011bd:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01011c3:	50                   	push   %eax
f01011c4:	68 8f 02 00 00       	push   $0x28f
f01011c9:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01011cf:	50                   	push   %eax
f01011d0:	e8 dc ee ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011d5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011d8:	8d 83 00 85 f7 ff    	lea    -0x87b00(%ebx),%eax
f01011de:	50                   	push   %eax
f01011df:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01011e5:	50                   	push   %eax
f01011e6:	68 90 02 00 00       	push   $0x290
f01011eb:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01011f1:	50                   	push   %eax
f01011f2:	e8 ba ee ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011f7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011fa:	8d 83 1a 82 f7 ff    	lea    -0x87de6(%ebx),%eax
f0101200:	50                   	push   %eax
f0101201:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101207:	50                   	push   %eax
f0101208:	68 91 02 00 00       	push   $0x291
f010120d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101213:	50                   	push   %eax
f0101214:	e8 98 ee ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0101219:	89 c6                	mov    %eax,%esi
f010121b:	c1 ee 0c             	shr    $0xc,%esi
f010121e:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0101221:	76 70                	jbe    f0101293 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0101223:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101228:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f010122b:	77 7f                	ja     f01012ac <check_page_free_list+0x271>
			++nfree_extmem;
f010122d:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101231:	8b 12                	mov    (%edx),%edx
f0101233:	85 d2                	test   %edx,%edx
f0101235:	0f 84 93 00 00 00    	je     f01012ce <check_page_free_list+0x293>
		assert(pp >= pages);
f010123b:	39 d1                	cmp    %edx,%ecx
f010123d:	0f 87 e8 fe ff ff    	ja     f010112b <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0101243:	39 d3                	cmp    %edx,%ebx
f0101245:	0f 86 02 ff ff ff    	jbe    f010114d <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010124b:	89 d0                	mov    %edx,%eax
f010124d:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0101250:	a8 07                	test   $0x7,%al
f0101252:	0f 85 17 ff ff ff    	jne    f010116f <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0101258:	c1 f8 03             	sar    $0x3,%eax
f010125b:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f010125e:	85 c0                	test   %eax,%eax
f0101260:	0f 84 2b ff ff ff    	je     f0101191 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0101266:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010126b:	0f 84 42 ff ff ff    	je     f01011b3 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101271:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101276:	0f 84 59 ff ff ff    	je     f01011d5 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f010127c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101281:	0f 84 70 ff ff ff    	je     f01011f7 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101287:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010128c:	77 8b                	ja     f0101219 <check_page_free_list+0x1de>
			++nfree_basemem;
f010128e:	83 c7 01             	add    $0x1,%edi
f0101291:	eb 9e                	jmp    f0101231 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101293:	50                   	push   %eax
f0101294:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101297:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f010129d:	50                   	push   %eax
f010129e:	6a 56                	push   $0x56
f01012a0:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f01012a6:	50                   	push   %eax
f01012a7:	e8 05 ee ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01012ac:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01012af:	8d 83 24 85 f7 ff    	lea    -0x87adc(%ebx),%eax
f01012b5:	50                   	push   %eax
f01012b6:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01012bc:	50                   	push   %eax
f01012bd:	68 92 02 00 00       	push   $0x292
f01012c2:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01012c8:	50                   	push   %eax
f01012c9:	e8 e3 ed ff ff       	call   f01000b1 <_panic>
f01012ce:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f01012d1:	85 ff                	test   %edi,%edi
f01012d3:	7e 1e                	jle    f01012f3 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f01012d5:	85 f6                	test   %esi,%esi
f01012d7:	7e 3c                	jle    f0101315 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f01012d9:	83 ec 0c             	sub    $0xc,%esp
f01012dc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01012df:	8d 83 6c 85 f7 ff    	lea    -0x87a94(%ebx),%eax
f01012e5:	50                   	push   %eax
f01012e6:	e8 87 2c 00 00       	call   f0103f72 <cprintf>
}
f01012eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012ee:	5b                   	pop    %ebx
f01012ef:	5e                   	pop    %esi
f01012f0:	5f                   	pop    %edi
f01012f1:	5d                   	pop    %ebp
f01012f2:	c3                   	ret    
	assert(nfree_basemem > 0);
f01012f3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01012f6:	8d 83 34 82 f7 ff    	lea    -0x87dcc(%ebx),%eax
f01012fc:	50                   	push   %eax
f01012fd:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101303:	50                   	push   %eax
f0101304:	68 9a 02 00 00       	push   $0x29a
f0101309:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010130f:	50                   	push   %eax
f0101310:	e8 9c ed ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0101315:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101318:	8d 83 46 82 f7 ff    	lea    -0x87dba(%ebx),%eax
f010131e:	50                   	push   %eax
f010131f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101325:	50                   	push   %eax
f0101326:	68 9b 02 00 00       	push   $0x29b
f010132b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101331:	50                   	push   %eax
f0101332:	e8 7a ed ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0101337:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010133a:	8b 80 60 23 00 00    	mov    0x2360(%eax),%eax
f0101340:	85 c0                	test   %eax,%eax
f0101342:	0f 84 2a fd ff ff    	je     f0101072 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0101348:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010134b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010134e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101351:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0101354:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101357:	c7 c3 50 10 19 f0    	mov    $0xf0191050,%ebx
f010135d:	89 c2                	mov    %eax,%edx
f010135f:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101361:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0101367:	0f 95 c2             	setne  %dl
f010136a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010136d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101371:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101373:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101377:	8b 00                	mov    (%eax),%eax
f0101379:	85 c0                	test   %eax,%eax
f010137b:	75 e0                	jne    f010135d <check_page_free_list+0x322>
		*tp[1] = 0;
f010137d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101380:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101386:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101389:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010138c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f010138e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101391:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101394:	89 87 60 23 00 00    	mov    %eax,0x2360(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010139a:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01013a1:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01013a4:	8b b0 60 23 00 00    	mov    0x2360(%eax),%esi
f01013aa:	c7 c7 50 10 19 f0    	mov    $0xf0191050,%edi
	if (PGNUM(pa) >= npages)
f01013b0:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f01013b6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01013b9:	e9 ed fc ff ff       	jmp    f01010ab <check_page_free_list+0x70>

f01013be <page_init>:
{
f01013be:	55                   	push   %ebp
f01013bf:	89 e5                	mov    %esp,%ebp
f01013c1:	57                   	push   %edi
f01013c2:	56                   	push   %esi
f01013c3:	53                   	push   %ebx
f01013c4:	83 ec 1c             	sub    $0x1c,%esp
f01013c7:	e8 97 23 00 00       	call   f0103763 <__x86.get_pc_thunk.si>
f01013cc:	81 c6 54 cc 08 00    	add    $0x8cc54,%esi
	page_free_list = NULL;
f01013d2:	c7 86 60 23 00 00 00 	movl   $0x0,0x2360(%esi)
f01013d9:	00 00 00 
	for (i = 0; i < npages; i++) {
f01013dc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013e1:	c7 c7 48 10 19 f0    	mov    $0xf0191048,%edi
			pages[i].pp_ref = 0;
f01013e7:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01013ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++) {
f01013f0:	eb 26                	jmp    f0101418 <page_init+0x5a>
		else if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE){
f01013f2:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f01013f8:	83 f8 5f             	cmp    $0x5f,%eax
f01013fb:	77 3f                	ja     f010143c <page_init+0x7e>
			pages[i].pp_link = NULL;
f01013fd:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101403:	8b 10                	mov    (%eax),%edx
f0101405:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
			pages[i].pp_ref = 1;
f010140c:	8b 00                	mov    (%eax),%eax
f010140e:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = 0; i < npages; i++) {
f0101415:	83 c3 01             	add    $0x1,%ebx
f0101418:	39 1f                	cmp    %ebx,(%edi)
f010141a:	0f 86 80 00 00 00    	jbe    f01014a0 <page_init+0xe2>
		if (i == 0){
f0101420:	85 db                	test   %ebx,%ebx
f0101422:	75 ce                	jne    f01013f2 <page_init+0x34>
			pages[i].pp_link = NULL;
f0101424:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f010142a:	8b 10                	mov    (%eax),%edx
f010142c:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
			pages[i].pp_ref = 1;
f0101432:	8b 00                	mov    (%eax),%eax
f0101434:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f010143a:	eb d9                	jmp    f0101415 <page_init+0x57>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f010143c:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101442:	77 29                	ja     f010146d <page_init+0xaf>
f0101444:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f010144b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010144e:	89 c2                	mov    %eax,%edx
f0101450:	03 11                	add    (%ecx),%edx
f0101452:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0101458:	8b 8e 60 23 00 00    	mov    0x2360(%esi),%ecx
f010145e:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0101460:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101463:	03 01                	add    (%ecx),%eax
f0101465:	89 86 60 23 00 00    	mov    %eax,0x2360(%esi)
f010146b:	eb a8                	jmp    f0101415 <page_init+0x57>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f010146d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101472:	e8 b3 fa ff ff       	call   f0100f2a <boot_alloc>
f0101477:	05 00 00 00 10       	add    $0x10000000,%eax
f010147c:	c1 e8 0c             	shr    $0xc,%eax
f010147f:	39 d8                	cmp    %ebx,%eax
f0101481:	76 c1                	jbe    f0101444 <page_init+0x86>
			pages[i].pp_link = NULL;
f0101483:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101489:	8b 10                	mov    (%eax),%edx
f010148b:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
			pages[i].pp_ref = 1;
f0101492:	8b 00                	mov    (%eax),%eax
f0101494:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f010149b:	e9 75 ff ff ff       	jmp    f0101415 <page_init+0x57>
}
f01014a0:	83 c4 1c             	add    $0x1c,%esp
f01014a3:	5b                   	pop    %ebx
f01014a4:	5e                   	pop    %esi
f01014a5:	5f                   	pop    %edi
f01014a6:	5d                   	pop    %ebp
f01014a7:	c3                   	ret    

f01014a8 <page_alloc>:
{
f01014a8:	55                   	push   %ebp
f01014a9:	89 e5                	mov    %esp,%ebp
f01014ab:	56                   	push   %esi
f01014ac:	53                   	push   %ebx
f01014ad:	e8 b5 ec ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01014b2:	81 c3 6e cb 08 00    	add    $0x8cb6e,%ebx
	if (page_free_list == NULL)
f01014b8:	8b b3 60 23 00 00    	mov    0x2360(%ebx),%esi
f01014be:	85 f6                	test   %esi,%esi
f01014c0:	74 14                	je     f01014d6 <page_alloc+0x2e>
	page_free_list = page_free_list -> pp_link;
f01014c2:	8b 06                	mov    (%esi),%eax
f01014c4:	89 83 60 23 00 00    	mov    %eax,0x2360(%ebx)
	info -> pp_link = NULL;
f01014ca:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f01014d0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01014d4:	75 09                	jne    f01014df <page_alloc+0x37>
}
f01014d6:	89 f0                	mov    %esi,%eax
f01014d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01014db:	5b                   	pop    %ebx
f01014dc:	5e                   	pop    %esi
f01014dd:	5d                   	pop    %ebp
f01014de:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f01014df:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01014e5:	89 f2                	mov    %esi,%edx
f01014e7:	2b 10                	sub    (%eax),%edx
f01014e9:	89 d0                	mov    %edx,%eax
f01014eb:	c1 f8 03             	sar    $0x3,%eax
f01014ee:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01014f1:	89 c1                	mov    %eax,%ecx
f01014f3:	c1 e9 0c             	shr    $0xc,%ecx
f01014f6:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f01014fc:	3b 0a                	cmp    (%edx),%ecx
f01014fe:	73 1a                	jae    f010151a <page_alloc+0x72>
		memset(page2kva(info), 0, PGSIZE);
f0101500:	83 ec 04             	sub    $0x4,%esp
f0101503:	68 00 10 00 00       	push   $0x1000
f0101508:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010150a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010150f:	50                   	push   %eax
f0101510:	e8 ef 40 00 00       	call   f0105604 <memset>
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	eb bc                	jmp    f01014d6 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010151a:	50                   	push   %eax
f010151b:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0101521:	50                   	push   %eax
f0101522:	6a 56                	push   $0x56
f0101524:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f010152a:	50                   	push   %eax
f010152b:	e8 81 eb ff ff       	call   f01000b1 <_panic>

f0101530 <page_free>:
{
f0101530:	55                   	push   %ebp
f0101531:	89 e5                	mov    %esp,%ebp
f0101533:	53                   	push   %ebx
f0101534:	83 ec 04             	sub    $0x4,%esp
f0101537:	e8 2b ec ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010153c:	81 c3 e4 ca 08 00    	add    $0x8cae4,%ebx
f0101542:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0)
f0101545:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010154a:	75 18                	jne    f0101564 <page_free+0x34>
	if (pp->pp_link != NULL)
f010154c:	83 38 00             	cmpl   $0x0,(%eax)
f010154f:	75 2e                	jne    f010157f <page_free+0x4f>
	pp->pp_link = page_free_list;
f0101551:	8b 8b 60 23 00 00    	mov    0x2360(%ebx),%ecx
f0101557:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0101559:	89 83 60 23 00 00    	mov    %eax,0x2360(%ebx)
}
f010155f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101562:	c9                   	leave  
f0101563:	c3                   	ret    
		panic("page_free(): pp->pp_ref is not zero!");
f0101564:	83 ec 04             	sub    $0x4,%esp
f0101567:	8d 83 90 85 f7 ff    	lea    -0x87a70(%ebx),%eax
f010156d:	50                   	push   %eax
f010156e:	68 64 01 00 00       	push   $0x164
f0101573:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101579:	50                   	push   %eax
f010157a:	e8 32 eb ff ff       	call   f01000b1 <_panic>
		panic("page_free(): pp has already be freed!");
f010157f:	83 ec 04             	sub    $0x4,%esp
f0101582:	8d 83 b8 85 f7 ff    	lea    -0x87a48(%ebx),%eax
f0101588:	50                   	push   %eax
f0101589:	68 66 01 00 00       	push   $0x166
f010158e:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101594:	50                   	push   %eax
f0101595:	e8 17 eb ff ff       	call   f01000b1 <_panic>

f010159a <page_decref>:
{
f010159a:	55                   	push   %ebp
f010159b:	89 e5                	mov    %esp,%ebp
f010159d:	83 ec 08             	sub    $0x8,%esp
f01015a0:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01015a3:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01015a7:	83 e8 01             	sub    $0x1,%eax
f01015aa:	66 89 42 04          	mov    %ax,0x4(%edx)
f01015ae:	66 85 c0             	test   %ax,%ax
f01015b1:	74 02                	je     f01015b5 <page_decref+0x1b>
}
f01015b3:	c9                   	leave  
f01015b4:	c3                   	ret    
		page_free(pp);
f01015b5:	83 ec 0c             	sub    $0xc,%esp
f01015b8:	52                   	push   %edx
f01015b9:	e8 72 ff ff ff       	call   f0101530 <page_free>
f01015be:	83 c4 10             	add    $0x10,%esp
}
f01015c1:	eb f0                	jmp    f01015b3 <page_decref+0x19>

f01015c3 <pgdir_walk>:
{
f01015c3:	55                   	push   %ebp
f01015c4:	89 e5                	mov    %esp,%ebp
f01015c6:	57                   	push   %edi
f01015c7:	56                   	push   %esi
f01015c8:	53                   	push   %ebx
f01015c9:	83 ec 0c             	sub    $0xc,%esp
f01015cc:	e8 96 eb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01015d1:	81 c3 4f ca 08 00    	add    $0x8ca4f,%ebx
f01015d7:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t* dict_ptr = pgdir + PDX(va);
f01015da:	89 f7                	mov    %esi,%edi
f01015dc:	c1 ef 16             	shr    $0x16,%edi
f01015df:	c1 e7 02             	shl    $0x2,%edi
f01015e2:	03 7d 08             	add    0x8(%ebp),%edi
	if ((*dict_ptr) & PTE_P){
f01015e5:	8b 07                	mov    (%edi),%eax
f01015e7:	a8 01                	test   $0x1,%al
f01015e9:	74 45                	je     f0101630 <pgdir_walk+0x6d>
		return (pte_t*)(KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t));
f01015eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01015f0:	89 c2                	mov    %eax,%edx
f01015f2:	c1 ea 0c             	shr    $0xc,%edx
f01015f5:	c7 c1 48 10 19 f0    	mov    $0xf0191048,%ecx
f01015fb:	39 11                	cmp    %edx,(%ecx)
f01015fd:	76 18                	jbe    f0101617 <pgdir_walk+0x54>
f01015ff:	c1 ee 0a             	shr    $0xa,%esi
f0101602:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101608:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f010160f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101612:	5b                   	pop    %ebx
f0101613:	5e                   	pop    %esi
f0101614:	5f                   	pop    %edi
f0101615:	5d                   	pop    %ebp
f0101616:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101617:	50                   	push   %eax
f0101618:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f010161e:	50                   	push   %eax
f010161f:	68 93 01 00 00       	push   $0x193
f0101624:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010162a:	50                   	push   %eax
f010162b:	e8 81 ea ff ff       	call   f01000b1 <_panic>
		if (create == false)
f0101630:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101634:	74 65                	je     f010169b <pgdir_walk+0xd8>
		struct PageInfo* page_itr = page_alloc(ALLOC_ZERO);
f0101636:	83 ec 0c             	sub    $0xc,%esp
f0101639:	6a 01                	push   $0x1
f010163b:	e8 68 fe ff ff       	call   f01014a8 <page_alloc>
		if (page_itr == NULL)
f0101640:	83 c4 10             	add    $0x10,%esp
f0101643:	85 c0                	test   %eax,%eax
f0101645:	74 5e                	je     f01016a5 <pgdir_walk+0xe2>
		page_itr -> pp_ref++;
f0101647:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010164c:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0101652:	2b 02                	sub    (%edx),%eax
f0101654:	c1 f8 03             	sar    $0x3,%eax
f0101657:	c1 e0 0c             	shl    $0xc,%eax
		*dict_ptr = page2pa(page_itr) | PTE_P | PTE_W | PTE_U;
f010165a:	89 c2                	mov    %eax,%edx
f010165c:	83 ca 07             	or     $0x7,%edx
f010165f:	89 17                	mov    %edx,(%edi)
	if (PGNUM(pa) >= npages)
f0101661:	89 c1                	mov    %eax,%ecx
f0101663:	c1 e9 0c             	shr    $0xc,%ecx
f0101666:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f010166c:	3b 0a                	cmp    (%edx),%ecx
f010166e:	73 12                	jae    f0101682 <pgdir_walk+0xbf>
		return (pte_t*)(KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t));
f0101670:	c1 ee 0a             	shr    $0xa,%esi
f0101673:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101679:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101680:	eb 8d                	jmp    f010160f <pgdir_walk+0x4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101682:	50                   	push   %eax
f0101683:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0101689:	50                   	push   %eax
f010168a:	68 9f 01 00 00       	push   $0x19f
f010168f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101695:	50                   	push   %eax
f0101696:	e8 16 ea ff ff       	call   f01000b1 <_panic>
			return NULL;
f010169b:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a0:	e9 6a ff ff ff       	jmp    f010160f <pgdir_walk+0x4c>
			return NULL;
f01016a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01016aa:	e9 60 ff ff ff       	jmp    f010160f <pgdir_walk+0x4c>

f01016af <boot_map_region>:
{
f01016af:	55                   	push   %ebp
f01016b0:	89 e5                	mov    %esp,%ebp
f01016b2:	57                   	push   %edi
f01016b3:	56                   	push   %esi
f01016b4:	53                   	push   %ebx
f01016b5:	83 ec 1c             	sub    $0x1c,%esp
f01016b8:	e8 a6 20 00 00       	call   f0103763 <__x86.get_pc_thunk.si>
f01016bd:	81 c6 63 c9 08 00    	add    $0x8c963,%esi
f01016c3:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01016c6:	89 c7                	mov    %eax,%edi
f01016c8:	89 d6                	mov    %edx,%esi
f01016ca:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f01016cd:	bb 00 00 00 00       	mov    $0x0,%ebx
		*pte_itr = (pa + i) | perm | PTE_P;
f01016d2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016d5:	83 c8 01             	or     $0x1,%eax
f01016d8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f01016db:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016de:	73 46                	jae    f0101726 <boot_map_region+0x77>
		uintptr_t* pte_itr = pgdir_walk(pgdir, (void*)(va + i), true);
f01016e0:	83 ec 04             	sub    $0x4,%esp
f01016e3:	6a 01                	push   $0x1
f01016e5:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f01016e8:	50                   	push   %eax
f01016e9:	57                   	push   %edi
f01016ea:	e8 d4 fe ff ff       	call   f01015c3 <pgdir_walk>
		if (pte_itr == NULL)
f01016ef:	83 c4 10             	add    $0x10,%esp
f01016f2:	85 c0                	test   %eax,%eax
f01016f4:	74 12                	je     f0101708 <boot_map_region+0x59>
		*pte_itr = (pa + i) | perm | PTE_P;
f01016f6:	89 da                	mov    %ebx,%edx
f01016f8:	03 55 08             	add    0x8(%ebp),%edx
f01016fb:	0b 55 e0             	or     -0x20(%ebp),%edx
f01016fe:	89 10                	mov    %edx,(%eax)
	for (size_t i = 0; i < size; i += PGSIZE){
f0101700:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101706:	eb d3                	jmp    f01016db <boot_map_region+0x2c>
			panic("boot_map_region(): Map failed, bad virtual memory address");
f0101708:	83 ec 04             	sub    $0x4,%esp
f010170b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010170e:	8d 83 e0 85 f7 ff    	lea    -0x87a20(%ebx),%eax
f0101714:	50                   	push   %eax
f0101715:	68 b5 01 00 00       	push   $0x1b5
f010171a:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101720:	50                   	push   %eax
f0101721:	e8 8b e9 ff ff       	call   f01000b1 <_panic>
}
f0101726:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101729:	5b                   	pop    %ebx
f010172a:	5e                   	pop    %esi
f010172b:	5f                   	pop    %edi
f010172c:	5d                   	pop    %ebp
f010172d:	c3                   	ret    

f010172e <page_lookup>:
{
f010172e:	55                   	push   %ebp
f010172f:	89 e5                	mov    %esp,%ebp
f0101731:	56                   	push   %esi
f0101732:	53                   	push   %ebx
f0101733:	e8 2f ea ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101738:	81 c3 e8 c8 08 00    	add    $0x8c8e8,%ebx
f010173e:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t* pte_itr = pgdir_walk(pgdir, va, false);
f0101741:	83 ec 04             	sub    $0x4,%esp
f0101744:	6a 00                	push   $0x0
f0101746:	ff 75 0c             	pushl  0xc(%ebp)
f0101749:	ff 75 08             	pushl  0x8(%ebp)
f010174c:	e8 72 fe ff ff       	call   f01015c3 <pgdir_walk>
	if (pte_itr == NULL)
f0101751:	83 c4 10             	add    $0x10,%esp
f0101754:	85 c0                	test   %eax,%eax
f0101756:	74 44                	je     f010179c <page_lookup+0x6e>
	if ((*pte_itr) & PTE_P){
f0101758:	f6 00 01             	testb  $0x1,(%eax)
f010175b:	74 46                	je     f01017a3 <page_lookup+0x75>
		if (pte_store != NULL)
f010175d:	85 f6                	test   %esi,%esi
f010175f:	74 02                	je     f0101763 <page_lookup+0x35>
			*pte_store = pte_itr;
f0101761:	89 06                	mov    %eax,(%esi)
f0101763:	8b 00                	mov    (%eax),%eax
f0101765:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101768:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f010176e:	39 02                	cmp    %eax,(%edx)
f0101770:	76 12                	jbe    f0101784 <page_lookup+0x56>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101772:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0101778:	8b 12                	mov    (%edx),%edx
f010177a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010177d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101780:	5b                   	pop    %ebx
f0101781:	5e                   	pop    %esi
f0101782:	5d                   	pop    %ebp
f0101783:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101784:	83 ec 04             	sub    $0x4,%esp
f0101787:	8d 83 1c 86 f7 ff    	lea    -0x879e4(%ebx),%eax
f010178d:	50                   	push   %eax
f010178e:	6a 4f                	push   $0x4f
f0101790:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0101796:	50                   	push   %eax
f0101797:	e8 15 e9 ff ff       	call   f01000b1 <_panic>
		return NULL;
f010179c:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a1:	eb da                	jmp    f010177d <page_lookup+0x4f>
		return NULL;
f01017a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a8:	eb d3                	jmp    f010177d <page_lookup+0x4f>

f01017aa <page_remove>:
{
f01017aa:	55                   	push   %ebp
f01017ab:	89 e5                	mov    %esp,%ebp
f01017ad:	53                   	push   %ebx
f01017ae:	83 ec 18             	sub    $0x18,%esp
f01017b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo* page_itr = page_lookup(pgdir, va, &pte_itr);
f01017b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01017b7:	50                   	push   %eax
f01017b8:	53                   	push   %ebx
f01017b9:	ff 75 08             	pushl  0x8(%ebp)
f01017bc:	e8 6d ff ff ff       	call   f010172e <page_lookup>
	if (page_itr == NULL)
f01017c1:	83 c4 10             	add    $0x10,%esp
f01017c4:	85 c0                	test   %eax,%eax
f01017c6:	74 1c                	je     f01017e4 <page_remove+0x3a>
	page_decref(page_itr);
f01017c8:	83 ec 0c             	sub    $0xc,%esp
f01017cb:	50                   	push   %eax
f01017cc:	e8 c9 fd ff ff       	call   f010159a <page_decref>
	if (pte_itr != NULL)
f01017d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017d4:	83 c4 10             	add    $0x10,%esp
f01017d7:	85 c0                	test   %eax,%eax
f01017d9:	74 06                	je     f01017e1 <page_remove+0x37>
		*pte_itr = 0;
f01017db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01017e1:	0f 01 3b             	invlpg (%ebx)
}
f01017e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017e7:	c9                   	leave  
f01017e8:	c3                   	ret    

f01017e9 <page_insert>:
{
f01017e9:	55                   	push   %ebp
f01017ea:	89 e5                	mov    %esp,%ebp
f01017ec:	57                   	push   %edi
f01017ed:	56                   	push   %esi
f01017ee:	53                   	push   %ebx
f01017ef:	83 ec 10             	sub    $0x10,%esp
f01017f2:	e8 70 1f 00 00       	call   f0103767 <__x86.get_pc_thunk.di>
f01017f7:	81 c7 29 c8 08 00    	add    $0x8c829,%edi
f01017fd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	pte_t* pte_ptr = pgdir_walk(pgdir, va, true);
f0101800:	6a 01                	push   $0x1
f0101802:	ff 75 10             	pushl  0x10(%ebp)
f0101805:	53                   	push   %ebx
f0101806:	e8 b8 fd ff ff       	call   f01015c3 <pgdir_walk>
	if (pte_ptr == NULL)
f010180b:	83 c4 10             	add    $0x10,%esp
f010180e:	85 c0                	test   %eax,%eax
f0101810:	74 56                	je     f0101868 <page_insert+0x7f>
f0101812:	89 c6                	mov    %eax,%esi
	++pp->pp_ref;
f0101814:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101817:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*pte_ptr) & PTE_P)
f010181c:	f6 06 01             	testb  $0x1,(%esi)
f010181f:	75 36                	jne    f0101857 <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f0101821:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101827:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010182a:	2b 08                	sub    (%eax),%ecx
f010182c:	89 c8                	mov    %ecx,%eax
f010182e:	c1 f8 03             	sar    $0x3,%eax
f0101831:	c1 e0 0c             	shl    $0xc,%eax
	*pte_ptr = page2pa(pp) | perm | PTE_P;
f0101834:	8b 55 14             	mov    0x14(%ebp),%edx
f0101837:	83 ca 01             	or     $0x1,%edx
f010183a:	09 d0                	or     %edx,%eax
f010183c:	89 06                	mov    %eax,(%esi)
	pde_t* dict_ptr = pgdir + PDX(va);
f010183e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101841:	c1 e8 16             	shr    $0x16,%eax
	*dict_ptr |= perm;
f0101844:	8b 7d 14             	mov    0x14(%ebp),%edi
f0101847:	09 3c 83             	or     %edi,(%ebx,%eax,4)
	return 0;
f010184a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010184f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101852:	5b                   	pop    %ebx
f0101853:	5e                   	pop    %esi
f0101854:	5f                   	pop    %edi
f0101855:	5d                   	pop    %ebp
f0101856:	c3                   	ret    
		page_remove(pgdir, va);
f0101857:	83 ec 08             	sub    $0x8,%esp
f010185a:	ff 75 10             	pushl  0x10(%ebp)
f010185d:	53                   	push   %ebx
f010185e:	e8 47 ff ff ff       	call   f01017aa <page_remove>
f0101863:	83 c4 10             	add    $0x10,%esp
f0101866:	eb b9                	jmp    f0101821 <page_insert+0x38>
		return -E_NO_MEM;
f0101868:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010186d:	eb e0                	jmp    f010184f <page_insert+0x66>

f010186f <mem_init>:
{
f010186f:	55                   	push   %ebp
f0101870:	89 e5                	mov    %esp,%ebp
f0101872:	57                   	push   %edi
f0101873:	56                   	push   %esi
f0101874:	53                   	push   %ebx
f0101875:	83 ec 3c             	sub    $0x3c,%esp
f0101878:	e8 8c ee ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010187d:	05 a3 c7 08 00       	add    $0x8c7a3,%eax
f0101882:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101885:	b8 15 00 00 00       	mov    $0x15,%eax
f010188a:	e8 65 f6 ff ff       	call   f0100ef4 <nvram_read>
f010188f:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101891:	b8 17 00 00 00       	mov    $0x17,%eax
f0101896:	e8 59 f6 ff ff       	call   f0100ef4 <nvram_read>
f010189b:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010189d:	b8 34 00 00 00       	mov    $0x34,%eax
f01018a2:	e8 4d f6 ff ff       	call   f0100ef4 <nvram_read>
f01018a7:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01018aa:	85 c0                	test   %eax,%eax
f01018ac:	0f 85 f6 00 00 00    	jne    f01019a8 <mem_init+0x139>
		totalmem = 1 * 1024 + extmem;
f01018b2:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01018b8:	85 f6                	test   %esi,%esi
f01018ba:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01018bd:	89 c1                	mov    %eax,%ecx
f01018bf:	c1 e9 02             	shr    $0x2,%ecx
f01018c2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01018c5:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f01018cb:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01018cd:	89 c2                	mov    %eax,%edx
f01018cf:	29 da                	sub    %ebx,%edx
f01018d1:	52                   	push   %edx
f01018d2:	53                   	push   %ebx
f01018d3:	50                   	push   %eax
f01018d4:	8d 87 3c 86 f7 ff    	lea    -0x879c4(%edi),%eax
f01018da:	50                   	push   %eax
f01018db:	89 fb                	mov    %edi,%ebx
f01018dd:	e8 90 26 00 00       	call   f0103f72 <cprintf>
	pde_t* __useless__ = (pde_t *) boot_alloc(PGSIZE);
f01018e2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01018e7:	e8 3e f6 ff ff       	call   f0100f2a <boot_alloc>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01018ec:	b8 00 10 00 00       	mov    $0x1000,%eax
f01018f1:	e8 34 f6 ff ff       	call   f0100f2a <boot_alloc>
f01018f6:	c7 c6 4c 10 19 f0    	mov    $0xf019104c,%esi
f01018fc:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01018fe:	83 c4 0c             	add    $0xc,%esp
f0101901:	68 00 10 00 00       	push   $0x1000
f0101906:	6a 00                	push   $0x0
f0101908:	50                   	push   %eax
f0101909:	e8 f6 3c 00 00       	call   f0105604 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010190e:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101910:	83 c4 10             	add    $0x10,%esp
f0101913:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101918:	0f 86 94 00 00 00    	jbe    f01019b2 <mem_init+0x143>
	return (physaddr_t)kva - KERNBASE;
f010191e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101924:	83 ca 05             	or     $0x5,%edx
f0101927:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	size_t pagesize = npages * sizeof(struct PageInfo);
f010192d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101930:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0101936:	8b 00                	mov    (%eax),%eax
f0101938:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f010193f:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
	pages = (struct PageInfo*)boot_alloc(pagesize);
f0101942:	89 d8                	mov    %ebx,%eax
f0101944:	e8 e1 f5 ff ff       	call   f0100f2a <boot_alloc>
f0101949:	c7 c6 50 10 19 f0    	mov    $0xf0191050,%esi
f010194f:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, pagesize);
f0101951:	83 ec 04             	sub    $0x4,%esp
f0101954:	53                   	push   %ebx
f0101955:	6a 00                	push   $0x0
f0101957:	50                   	push   %eax
f0101958:	89 fb                	mov    %edi,%ebx
f010195a:	e8 a5 3c 00 00       	call   f0105604 <memset>
	envs = (struct Env*)boot_alloc(envsize);
f010195f:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101964:	e8 c1 f5 ff ff       	call   f0100f2a <boot_alloc>
f0101969:	c7 c2 88 03 19 f0    	mov    $0xf0190388,%edx
f010196f:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, envsize);
f0101971:	83 c4 0c             	add    $0xc,%esp
f0101974:	68 00 80 01 00       	push   $0x18000
f0101979:	6a 00                	push   $0x0
f010197b:	50                   	push   %eax
f010197c:	e8 83 3c 00 00       	call   f0105604 <memset>
	page_init();
f0101981:	e8 38 fa ff ff       	call   f01013be <page_init>
	check_page_free_list(1);
f0101986:	b8 01 00 00 00       	mov    $0x1,%eax
f010198b:	e8 ab f6 ff ff       	call   f010103b <check_page_free_list>
	if (!pages)
f0101990:	83 c4 10             	add    $0x10,%esp
f0101993:	83 3e 00             	cmpl   $0x0,(%esi)
f0101996:	74 36                	je     f01019ce <mem_init+0x15f>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101998:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010199b:	8b 80 60 23 00 00    	mov    0x2360(%eax),%eax
f01019a1:	be 00 00 00 00       	mov    $0x0,%esi
f01019a6:	eb 49                	jmp    f01019f1 <mem_init+0x182>
		totalmem = 16 * 1024 + ext16mem;
f01019a8:	05 00 40 00 00       	add    $0x4000,%eax
f01019ad:	e9 0b ff ff ff       	jmp    f01018bd <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01019b2:	50                   	push   %eax
f01019b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b6:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f01019bc:	50                   	push   %eax
f01019bd:	68 a0 00 00 00       	push   $0xa0
f01019c2:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01019c8:	50                   	push   %eax
f01019c9:	e8 e3 e6 ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f01019ce:	83 ec 04             	sub    $0x4,%esp
f01019d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019d4:	8d 83 57 82 f7 ff    	lea    -0x87da9(%ebx),%eax
f01019da:	50                   	push   %eax
f01019db:	68 ae 02 00 00       	push   $0x2ae
f01019e0:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01019e6:	50                   	push   %eax
f01019e7:	e8 c5 e6 ff ff       	call   f01000b1 <_panic>
		++nfree;
f01019ec:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01019ef:	8b 00                	mov    (%eax),%eax
f01019f1:	85 c0                	test   %eax,%eax
f01019f3:	75 f7                	jne    f01019ec <mem_init+0x17d>
	assert((pp0 = page_alloc(0)));
f01019f5:	83 ec 0c             	sub    $0xc,%esp
f01019f8:	6a 00                	push   $0x0
f01019fa:	e8 a9 fa ff ff       	call   f01014a8 <page_alloc>
f01019ff:	89 c3                	mov    %eax,%ebx
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	85 c0                	test   %eax,%eax
f0101a06:	0f 84 3b 02 00 00    	je     f0101c47 <mem_init+0x3d8>
	assert((pp1 = page_alloc(0)));
f0101a0c:	83 ec 0c             	sub    $0xc,%esp
f0101a0f:	6a 00                	push   $0x0
f0101a11:	e8 92 fa ff ff       	call   f01014a8 <page_alloc>
f0101a16:	89 c7                	mov    %eax,%edi
f0101a18:	83 c4 10             	add    $0x10,%esp
f0101a1b:	85 c0                	test   %eax,%eax
f0101a1d:	0f 84 46 02 00 00    	je     f0101c69 <mem_init+0x3fa>
	assert((pp2 = page_alloc(0)));
f0101a23:	83 ec 0c             	sub    $0xc,%esp
f0101a26:	6a 00                	push   $0x0
f0101a28:	e8 7b fa ff ff       	call   f01014a8 <page_alloc>
f0101a2d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a30:	83 c4 10             	add    $0x10,%esp
f0101a33:	85 c0                	test   %eax,%eax
f0101a35:	0f 84 50 02 00 00    	je     f0101c8b <mem_init+0x41c>
	assert(pp1 && pp1 != pp0);
f0101a3b:	39 fb                	cmp    %edi,%ebx
f0101a3d:	0f 84 6a 02 00 00    	je     f0101cad <mem_init+0x43e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a43:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a46:	39 c3                	cmp    %eax,%ebx
f0101a48:	0f 84 81 02 00 00    	je     f0101ccf <mem_init+0x460>
f0101a4e:	39 c7                	cmp    %eax,%edi
f0101a50:	0f 84 79 02 00 00    	je     f0101ccf <mem_init+0x460>
	return (pp - pages) << PGSHIFT;
f0101a56:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101a59:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101a5f:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101a61:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0101a67:	8b 10                	mov    (%eax),%edx
f0101a69:	c1 e2 0c             	shl    $0xc,%edx
f0101a6c:	89 d8                	mov    %ebx,%eax
f0101a6e:	29 c8                	sub    %ecx,%eax
f0101a70:	c1 f8 03             	sar    $0x3,%eax
f0101a73:	c1 e0 0c             	shl    $0xc,%eax
f0101a76:	39 d0                	cmp    %edx,%eax
f0101a78:	0f 83 73 02 00 00    	jae    f0101cf1 <mem_init+0x482>
f0101a7e:	89 f8                	mov    %edi,%eax
f0101a80:	29 c8                	sub    %ecx,%eax
f0101a82:	c1 f8 03             	sar    $0x3,%eax
f0101a85:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a88:	39 c2                	cmp    %eax,%edx
f0101a8a:	0f 86 83 02 00 00    	jbe    f0101d13 <mem_init+0x4a4>
f0101a90:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a93:	29 c8                	sub    %ecx,%eax
f0101a95:	c1 f8 03             	sar    $0x3,%eax
f0101a98:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101a9b:	39 c2                	cmp    %eax,%edx
f0101a9d:	0f 86 92 02 00 00    	jbe    f0101d35 <mem_init+0x4c6>
	fl = page_free_list;
f0101aa3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aa6:	8b 88 60 23 00 00    	mov    0x2360(%eax),%ecx
f0101aac:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101aaf:	c7 80 60 23 00 00 00 	movl   $0x0,0x2360(%eax)
f0101ab6:	00 00 00 
	assert(!page_alloc(0));
f0101ab9:	83 ec 0c             	sub    $0xc,%esp
f0101abc:	6a 00                	push   $0x0
f0101abe:	e8 e5 f9 ff ff       	call   f01014a8 <page_alloc>
f0101ac3:	83 c4 10             	add    $0x10,%esp
f0101ac6:	85 c0                	test   %eax,%eax
f0101ac8:	0f 85 89 02 00 00    	jne    f0101d57 <mem_init+0x4e8>
	page_free(pp0);
f0101ace:	83 ec 0c             	sub    $0xc,%esp
f0101ad1:	53                   	push   %ebx
f0101ad2:	e8 59 fa ff ff       	call   f0101530 <page_free>
	page_free(pp1);
f0101ad7:	89 3c 24             	mov    %edi,(%esp)
f0101ada:	e8 51 fa ff ff       	call   f0101530 <page_free>
	page_free(pp2);
f0101adf:	83 c4 04             	add    $0x4,%esp
f0101ae2:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ae5:	e8 46 fa ff ff       	call   f0101530 <page_free>
	assert((pp0 = page_alloc(0)));
f0101aea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101af1:	e8 b2 f9 ff ff       	call   f01014a8 <page_alloc>
f0101af6:	89 c7                	mov    %eax,%edi
f0101af8:	83 c4 10             	add    $0x10,%esp
f0101afb:	85 c0                	test   %eax,%eax
f0101afd:	0f 84 76 02 00 00    	je     f0101d79 <mem_init+0x50a>
	assert((pp1 = page_alloc(0)));
f0101b03:	83 ec 0c             	sub    $0xc,%esp
f0101b06:	6a 00                	push   $0x0
f0101b08:	e8 9b f9 ff ff       	call   f01014a8 <page_alloc>
f0101b0d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b10:	83 c4 10             	add    $0x10,%esp
f0101b13:	85 c0                	test   %eax,%eax
f0101b15:	0f 84 80 02 00 00    	je     f0101d9b <mem_init+0x52c>
	assert((pp2 = page_alloc(0)));
f0101b1b:	83 ec 0c             	sub    $0xc,%esp
f0101b1e:	6a 00                	push   $0x0
f0101b20:	e8 83 f9 ff ff       	call   f01014a8 <page_alloc>
f0101b25:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b28:	83 c4 10             	add    $0x10,%esp
f0101b2b:	85 c0                	test   %eax,%eax
f0101b2d:	0f 84 8a 02 00 00    	je     f0101dbd <mem_init+0x54e>
	assert(pp1 && pp1 != pp0);
f0101b33:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101b36:	0f 84 a3 02 00 00    	je     f0101ddf <mem_init+0x570>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b3c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b3f:	39 c7                	cmp    %eax,%edi
f0101b41:	0f 84 ba 02 00 00    	je     f0101e01 <mem_init+0x592>
f0101b47:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b4a:	0f 84 b1 02 00 00    	je     f0101e01 <mem_init+0x592>
	assert(!page_alloc(0));
f0101b50:	83 ec 0c             	sub    $0xc,%esp
f0101b53:	6a 00                	push   $0x0
f0101b55:	e8 4e f9 ff ff       	call   f01014a8 <page_alloc>
f0101b5a:	83 c4 10             	add    $0x10,%esp
f0101b5d:	85 c0                	test   %eax,%eax
f0101b5f:	0f 85 be 02 00 00    	jne    f0101e23 <mem_init+0x5b4>
f0101b65:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b68:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101b6e:	89 f9                	mov    %edi,%ecx
f0101b70:	2b 08                	sub    (%eax),%ecx
f0101b72:	89 c8                	mov    %ecx,%eax
f0101b74:	c1 f8 03             	sar    $0x3,%eax
f0101b77:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101b7a:	89 c1                	mov    %eax,%ecx
f0101b7c:	c1 e9 0c             	shr    $0xc,%ecx
f0101b7f:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f0101b85:	3b 0a                	cmp    (%edx),%ecx
f0101b87:	0f 83 b8 02 00 00    	jae    f0101e45 <mem_init+0x5d6>
	memset(page2kva(pp0), 1, PGSIZE);
f0101b8d:	83 ec 04             	sub    $0x4,%esp
f0101b90:	68 00 10 00 00       	push   $0x1000
f0101b95:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101b97:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b9c:	50                   	push   %eax
f0101b9d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ba0:	e8 5f 3a 00 00       	call   f0105604 <memset>
	page_free(pp0);
f0101ba5:	89 3c 24             	mov    %edi,(%esp)
f0101ba8:	e8 83 f9 ff ff       	call   f0101530 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101bad:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101bb4:	e8 ef f8 ff ff       	call   f01014a8 <page_alloc>
f0101bb9:	83 c4 10             	add    $0x10,%esp
f0101bbc:	85 c0                	test   %eax,%eax
f0101bbe:	0f 84 97 02 00 00    	je     f0101e5b <mem_init+0x5ec>
	assert(pp && pp0 == pp);
f0101bc4:	39 c7                	cmp    %eax,%edi
f0101bc6:	0f 85 b1 02 00 00    	jne    f0101e7d <mem_init+0x60e>
	return (pp - pages) << PGSHIFT;
f0101bcc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bcf:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0101bd5:	89 fa                	mov    %edi,%edx
f0101bd7:	2b 10                	sub    (%eax),%edx
f0101bd9:	c1 fa 03             	sar    $0x3,%edx
f0101bdc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101bdf:	89 d1                	mov    %edx,%ecx
f0101be1:	c1 e9 0c             	shr    $0xc,%ecx
f0101be4:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0101bea:	3b 08                	cmp    (%eax),%ecx
f0101bec:	0f 83 ad 02 00 00    	jae    f0101e9f <mem_init+0x630>
	return (void *)(pa + KERNBASE);
f0101bf2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101bf8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101bfe:	80 38 00             	cmpb   $0x0,(%eax)
f0101c01:	0f 85 ae 02 00 00    	jne    f0101eb5 <mem_init+0x646>
f0101c07:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101c0a:	39 d0                	cmp    %edx,%eax
f0101c0c:	75 f0                	jne    f0101bfe <mem_init+0x38f>
	page_free_list = fl;
f0101c0e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c11:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101c14:	89 8b 60 23 00 00    	mov    %ecx,0x2360(%ebx)
	page_free(pp0);
f0101c1a:	83 ec 0c             	sub    $0xc,%esp
f0101c1d:	57                   	push   %edi
f0101c1e:	e8 0d f9 ff ff       	call   f0101530 <page_free>
	page_free(pp1);
f0101c23:	83 c4 04             	add    $0x4,%esp
f0101c26:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c29:	e8 02 f9 ff ff       	call   f0101530 <page_free>
	page_free(pp2);
f0101c2e:	83 c4 04             	add    $0x4,%esp
f0101c31:	ff 75 cc             	pushl  -0x34(%ebp)
f0101c34:	e8 f7 f8 ff ff       	call   f0101530 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c39:	8b 83 60 23 00 00    	mov    0x2360(%ebx),%eax
f0101c3f:	83 c4 10             	add    $0x10,%esp
f0101c42:	e9 95 02 00 00       	jmp    f0101edc <mem_init+0x66d>
	assert((pp0 = page_alloc(0)));
f0101c47:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c4a:	8d 83 72 82 f7 ff    	lea    -0x87d8e(%ebx),%eax
f0101c50:	50                   	push   %eax
f0101c51:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101c57:	50                   	push   %eax
f0101c58:	68 b6 02 00 00       	push   $0x2b6
f0101c5d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101c63:	50                   	push   %eax
f0101c64:	e8 48 e4 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c69:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c6c:	8d 83 88 82 f7 ff    	lea    -0x87d78(%ebx),%eax
f0101c72:	50                   	push   %eax
f0101c73:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101c79:	50                   	push   %eax
f0101c7a:	68 b7 02 00 00       	push   $0x2b7
f0101c7f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101c85:	50                   	push   %eax
f0101c86:	e8 26 e4 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c8b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c8e:	8d 83 9e 82 f7 ff    	lea    -0x87d62(%ebx),%eax
f0101c94:	50                   	push   %eax
f0101c95:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101c9b:	50                   	push   %eax
f0101c9c:	68 b8 02 00 00       	push   $0x2b8
f0101ca1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101ca7:	50                   	push   %eax
f0101ca8:	e8 04 e4 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101cad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cb0:	8d 83 b4 82 f7 ff    	lea    -0x87d4c(%ebx),%eax
f0101cb6:	50                   	push   %eax
f0101cb7:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101cbd:	50                   	push   %eax
f0101cbe:	68 bb 02 00 00       	push   $0x2bb
f0101cc3:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101cc9:	50                   	push   %eax
f0101cca:	e8 e2 e3 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ccf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cd2:	8d 83 9c 86 f7 ff    	lea    -0x87964(%ebx),%eax
f0101cd8:	50                   	push   %eax
f0101cd9:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101cdf:	50                   	push   %eax
f0101ce0:	68 bc 02 00 00       	push   $0x2bc
f0101ce5:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101ceb:	50                   	push   %eax
f0101cec:	e8 c0 e3 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101cf1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cf4:	8d 83 c6 82 f7 ff    	lea    -0x87d3a(%ebx),%eax
f0101cfa:	50                   	push   %eax
f0101cfb:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101d01:	50                   	push   %eax
f0101d02:	68 bd 02 00 00       	push   $0x2bd
f0101d07:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101d0d:	50                   	push   %eax
f0101d0e:	e8 9e e3 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101d13:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d16:	8d 83 e3 82 f7 ff    	lea    -0x87d1d(%ebx),%eax
f0101d1c:	50                   	push   %eax
f0101d1d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101d23:	50                   	push   %eax
f0101d24:	68 be 02 00 00       	push   $0x2be
f0101d29:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101d2f:	50                   	push   %eax
f0101d30:	e8 7c e3 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101d35:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d38:	8d 83 00 83 f7 ff    	lea    -0x87d00(%ebx),%eax
f0101d3e:	50                   	push   %eax
f0101d3f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101d45:	50                   	push   %eax
f0101d46:	68 bf 02 00 00       	push   $0x2bf
f0101d4b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101d51:	50                   	push   %eax
f0101d52:	e8 5a e3 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101d57:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d5a:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f0101d60:	50                   	push   %eax
f0101d61:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101d67:	50                   	push   %eax
f0101d68:	68 c6 02 00 00       	push   $0x2c6
f0101d6d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101d73:	50                   	push   %eax
f0101d74:	e8 38 e3 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0101d79:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d7c:	8d 83 72 82 f7 ff    	lea    -0x87d8e(%ebx),%eax
f0101d82:	50                   	push   %eax
f0101d83:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101d89:	50                   	push   %eax
f0101d8a:	68 cd 02 00 00       	push   $0x2cd
f0101d8f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101d95:	50                   	push   %eax
f0101d96:	e8 16 e3 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101d9b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d9e:	8d 83 88 82 f7 ff    	lea    -0x87d78(%ebx),%eax
f0101da4:	50                   	push   %eax
f0101da5:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101dab:	50                   	push   %eax
f0101dac:	68 ce 02 00 00       	push   $0x2ce
f0101db1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101db7:	50                   	push   %eax
f0101db8:	e8 f4 e2 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101dbd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101dc0:	8d 83 9e 82 f7 ff    	lea    -0x87d62(%ebx),%eax
f0101dc6:	50                   	push   %eax
f0101dc7:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101dcd:	50                   	push   %eax
f0101dce:	68 cf 02 00 00       	push   $0x2cf
f0101dd3:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101dd9:	50                   	push   %eax
f0101dda:	e8 d2 e2 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101ddf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101de2:	8d 83 b4 82 f7 ff    	lea    -0x87d4c(%ebx),%eax
f0101de8:	50                   	push   %eax
f0101de9:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101def:	50                   	push   %eax
f0101df0:	68 d1 02 00 00       	push   $0x2d1
f0101df5:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101dfb:	50                   	push   %eax
f0101dfc:	e8 b0 e2 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101e01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e04:	8d 83 9c 86 f7 ff    	lea    -0x87964(%ebx),%eax
f0101e0a:	50                   	push   %eax
f0101e0b:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101e11:	50                   	push   %eax
f0101e12:	68 d2 02 00 00       	push   $0x2d2
f0101e17:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101e1d:	50                   	push   %eax
f0101e1e:	e8 8e e2 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101e23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e26:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f0101e2c:	50                   	push   %eax
f0101e2d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101e33:	50                   	push   %eax
f0101e34:	68 d3 02 00 00       	push   $0x2d3
f0101e39:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101e3f:	50                   	push   %eax
f0101e40:	e8 6c e2 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e45:	50                   	push   %eax
f0101e46:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0101e4c:	50                   	push   %eax
f0101e4d:	6a 56                	push   $0x56
f0101e4f:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0101e55:	50                   	push   %eax
f0101e56:	e8 56 e2 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101e5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e5e:	8d 83 2c 83 f7 ff    	lea    -0x87cd4(%ebx),%eax
f0101e64:	50                   	push   %eax
f0101e65:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101e6b:	50                   	push   %eax
f0101e6c:	68 d8 02 00 00       	push   $0x2d8
f0101e71:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101e77:	50                   	push   %eax
f0101e78:	e8 34 e2 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f0101e7d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e80:	8d 83 4a 83 f7 ff    	lea    -0x87cb6(%ebx),%eax
f0101e86:	50                   	push   %eax
f0101e87:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101e8d:	50                   	push   %eax
f0101e8e:	68 d9 02 00 00       	push   $0x2d9
f0101e93:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101e99:	50                   	push   %eax
f0101e9a:	e8 12 e2 ff ff       	call   f01000b1 <_panic>
f0101e9f:	52                   	push   %edx
f0101ea0:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0101ea6:	50                   	push   %eax
f0101ea7:	6a 56                	push   $0x56
f0101ea9:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0101eaf:	50                   	push   %eax
f0101eb0:	e8 fc e1 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f0101eb5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101eb8:	8d 83 5a 83 f7 ff    	lea    -0x87ca6(%ebx),%eax
f0101ebe:	50                   	push   %eax
f0101ebf:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0101ec5:	50                   	push   %eax
f0101ec6:	68 dc 02 00 00       	push   $0x2dc
f0101ecb:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0101ed1:	50                   	push   %eax
f0101ed2:	e8 da e1 ff ff       	call   f01000b1 <_panic>
		--nfree;
f0101ed7:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101eda:	8b 00                	mov    (%eax),%eax
f0101edc:	85 c0                	test   %eax,%eax
f0101ede:	75 f7                	jne    f0101ed7 <mem_init+0x668>
	assert(nfree == 0);
f0101ee0:	85 f6                	test   %esi,%esi
f0101ee2:	0f 85 5d 08 00 00    	jne    f0102745 <mem_init+0xed6>
	cprintf("check_page_alloc() succeeded!\n");
f0101ee8:	83 ec 0c             	sub    $0xc,%esp
f0101eeb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101eee:	8d 83 bc 86 f7 ff    	lea    -0x87944(%ebx),%eax
f0101ef4:	50                   	push   %eax
f0101ef5:	e8 78 20 00 00       	call   f0103f72 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101efa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f01:	e8 a2 f5 ff ff       	call   f01014a8 <page_alloc>
f0101f06:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f09:	83 c4 10             	add    $0x10,%esp
f0101f0c:	85 c0                	test   %eax,%eax
f0101f0e:	0f 84 53 08 00 00    	je     f0102767 <mem_init+0xef8>
	assert((pp1 = page_alloc(0)));
f0101f14:	83 ec 0c             	sub    $0xc,%esp
f0101f17:	6a 00                	push   $0x0
f0101f19:	e8 8a f5 ff ff       	call   f01014a8 <page_alloc>
f0101f1e:	89 c7                	mov    %eax,%edi
f0101f20:	83 c4 10             	add    $0x10,%esp
f0101f23:	85 c0                	test   %eax,%eax
f0101f25:	0f 84 5e 08 00 00    	je     f0102789 <mem_init+0xf1a>
	assert((pp2 = page_alloc(0)));
f0101f2b:	83 ec 0c             	sub    $0xc,%esp
f0101f2e:	6a 00                	push   $0x0
f0101f30:	e8 73 f5 ff ff       	call   f01014a8 <page_alloc>
f0101f35:	89 c6                	mov    %eax,%esi
f0101f37:	83 c4 10             	add    $0x10,%esp
f0101f3a:	85 c0                	test   %eax,%eax
f0101f3c:	0f 84 69 08 00 00    	je     f01027ab <mem_init+0xf3c>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101f42:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101f45:	0f 84 82 08 00 00    	je     f01027cd <mem_init+0xf5e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101f4b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f4e:	0f 84 9b 08 00 00    	je     f01027ef <mem_init+0xf80>
f0101f54:	39 c7                	cmp    %eax,%edi
f0101f56:	0f 84 93 08 00 00    	je     f01027ef <mem_init+0xf80>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5f:	8b 88 60 23 00 00    	mov    0x2360(%eax),%ecx
f0101f65:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101f68:	c7 80 60 23 00 00 00 	movl   $0x0,0x2360(%eax)
f0101f6f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f72:	83 ec 0c             	sub    $0xc,%esp
f0101f75:	6a 00                	push   $0x0
f0101f77:	e8 2c f5 ff ff       	call   f01014a8 <page_alloc>
f0101f7c:	83 c4 10             	add    $0x10,%esp
f0101f7f:	85 c0                	test   %eax,%eax
f0101f81:	0f 85 8a 08 00 00    	jne    f0102811 <mem_init+0xfa2>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f87:	83 ec 04             	sub    $0x4,%esp
f0101f8a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f8d:	50                   	push   %eax
f0101f8e:	6a 00                	push   $0x0
f0101f90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f93:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0101f99:	ff 30                	pushl  (%eax)
f0101f9b:	e8 8e f7 ff ff       	call   f010172e <page_lookup>
f0101fa0:	83 c4 10             	add    $0x10,%esp
f0101fa3:	85 c0                	test   %eax,%eax
f0101fa5:	0f 85 88 08 00 00    	jne    f0102833 <mem_init+0xfc4>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101fab:	6a 02                	push   $0x2
f0101fad:	6a 00                	push   $0x0
f0101faf:	57                   	push   %edi
f0101fb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb3:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0101fb9:	ff 30                	pushl  (%eax)
f0101fbb:	e8 29 f8 ff ff       	call   f01017e9 <page_insert>
f0101fc0:	83 c4 10             	add    $0x10,%esp
f0101fc3:	85 c0                	test   %eax,%eax
f0101fc5:	0f 89 8a 08 00 00    	jns    f0102855 <mem_init+0xfe6>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101fcb:	83 ec 0c             	sub    $0xc,%esp
f0101fce:	ff 75 d0             	pushl  -0x30(%ebp)
f0101fd1:	e8 5a f5 ff ff       	call   f0101530 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101fd6:	6a 02                	push   $0x2
f0101fd8:	6a 00                	push   $0x0
f0101fda:	57                   	push   %edi
f0101fdb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fde:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0101fe4:	ff 30                	pushl  (%eax)
f0101fe6:	e8 fe f7 ff ff       	call   f01017e9 <page_insert>
f0101feb:	83 c4 20             	add    $0x20,%esp
f0101fee:	85 c0                	test   %eax,%eax
f0101ff0:	0f 85 81 08 00 00    	jne    f0102877 <mem_init+0x1008>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ff6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ff9:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0101fff:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0102001:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0102007:	8b 08                	mov    (%eax),%ecx
f0102009:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010200c:	8b 13                	mov    (%ebx),%edx
f010200e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102014:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102017:	29 c8                	sub    %ecx,%eax
f0102019:	c1 f8 03             	sar    $0x3,%eax
f010201c:	c1 e0 0c             	shl    $0xc,%eax
f010201f:	39 c2                	cmp    %eax,%edx
f0102021:	0f 85 72 08 00 00    	jne    f0102899 <mem_init+0x102a>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102027:	ba 00 00 00 00       	mov    $0x0,%edx
f010202c:	89 d8                	mov    %ebx,%eax
f010202e:	e8 8b ef ff ff       	call   f0100fbe <check_va2pa>
f0102033:	89 fa                	mov    %edi,%edx
f0102035:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0102038:	c1 fa 03             	sar    $0x3,%edx
f010203b:	c1 e2 0c             	shl    $0xc,%edx
f010203e:	39 d0                	cmp    %edx,%eax
f0102040:	0f 85 75 08 00 00    	jne    f01028bb <mem_init+0x104c>
	assert(pp1->pp_ref == 1);
f0102046:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010204b:	0f 85 8c 08 00 00    	jne    f01028dd <mem_init+0x106e>
	assert(pp0->pp_ref == 1);
f0102051:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102054:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102059:	0f 85 a0 08 00 00    	jne    f01028ff <mem_init+0x1090>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010205f:	6a 02                	push   $0x2
f0102061:	68 00 10 00 00       	push   $0x1000
f0102066:	56                   	push   %esi
f0102067:	53                   	push   %ebx
f0102068:	e8 7c f7 ff ff       	call   f01017e9 <page_insert>
f010206d:	83 c4 10             	add    $0x10,%esp
f0102070:	85 c0                	test   %eax,%eax
f0102072:	0f 85 a9 08 00 00    	jne    f0102921 <mem_init+0x10b2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102078:	ba 00 10 00 00       	mov    $0x1000,%edx
f010207d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102080:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0102086:	8b 00                	mov    (%eax),%eax
f0102088:	e8 31 ef ff ff       	call   f0100fbe <check_va2pa>
f010208d:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0102093:	89 f1                	mov    %esi,%ecx
f0102095:	2b 0a                	sub    (%edx),%ecx
f0102097:	89 ca                	mov    %ecx,%edx
f0102099:	c1 fa 03             	sar    $0x3,%edx
f010209c:	c1 e2 0c             	shl    $0xc,%edx
f010209f:	39 d0                	cmp    %edx,%eax
f01020a1:	0f 85 9c 08 00 00    	jne    f0102943 <mem_init+0x10d4>
	assert(pp2->pp_ref == 1);
f01020a7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020ac:	0f 85 b3 08 00 00    	jne    f0102965 <mem_init+0x10f6>

	// should be no free memory
	assert(!page_alloc(0));
f01020b2:	83 ec 0c             	sub    $0xc,%esp
f01020b5:	6a 00                	push   $0x0
f01020b7:	e8 ec f3 ff ff       	call   f01014a8 <page_alloc>
f01020bc:	83 c4 10             	add    $0x10,%esp
f01020bf:	85 c0                	test   %eax,%eax
f01020c1:	0f 85 c0 08 00 00    	jne    f0102987 <mem_init+0x1118>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020c7:	6a 02                	push   $0x2
f01020c9:	68 00 10 00 00       	push   $0x1000
f01020ce:	56                   	push   %esi
f01020cf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d2:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01020d8:	ff 30                	pushl  (%eax)
f01020da:	e8 0a f7 ff ff       	call   f01017e9 <page_insert>
f01020df:	83 c4 10             	add    $0x10,%esp
f01020e2:	85 c0                	test   %eax,%eax
f01020e4:	0f 85 bf 08 00 00    	jne    f01029a9 <mem_init+0x113a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020ea:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020f2:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01020f8:	8b 00                	mov    (%eax),%eax
f01020fa:	e8 bf ee ff ff       	call   f0100fbe <check_va2pa>
f01020ff:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0102105:	89 f1                	mov    %esi,%ecx
f0102107:	2b 0a                	sub    (%edx),%ecx
f0102109:	89 ca                	mov    %ecx,%edx
f010210b:	c1 fa 03             	sar    $0x3,%edx
f010210e:	c1 e2 0c             	shl    $0xc,%edx
f0102111:	39 d0                	cmp    %edx,%eax
f0102113:	0f 85 b2 08 00 00    	jne    f01029cb <mem_init+0x115c>
	assert(pp2->pp_ref == 1);
f0102119:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010211e:	0f 85 c9 08 00 00    	jne    f01029ed <mem_init+0x117e>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102124:	83 ec 0c             	sub    $0xc,%esp
f0102127:	6a 00                	push   $0x0
f0102129:	e8 7a f3 ff ff       	call   f01014a8 <page_alloc>
f010212e:	83 c4 10             	add    $0x10,%esp
f0102131:	85 c0                	test   %eax,%eax
f0102133:	0f 85 d6 08 00 00    	jne    f0102a0f <mem_init+0x11a0>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102139:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010213c:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0102142:	8b 10                	mov    (%eax),%edx
f0102144:	8b 02                	mov    (%edx),%eax
f0102146:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010214b:	89 c3                	mov    %eax,%ebx
f010214d:	c1 eb 0c             	shr    $0xc,%ebx
f0102150:	c7 c1 48 10 19 f0    	mov    $0xf0191048,%ecx
f0102156:	3b 19                	cmp    (%ecx),%ebx
f0102158:	0f 83 d3 08 00 00    	jae    f0102a31 <mem_init+0x11c2>
	return (void *)(pa + KERNBASE);
f010215e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102163:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102166:	83 ec 04             	sub    $0x4,%esp
f0102169:	6a 00                	push   $0x0
f010216b:	68 00 10 00 00       	push   $0x1000
f0102170:	52                   	push   %edx
f0102171:	e8 4d f4 ff ff       	call   f01015c3 <pgdir_walk>
f0102176:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102179:	8d 51 04             	lea    0x4(%ecx),%edx
f010217c:	83 c4 10             	add    $0x10,%esp
f010217f:	39 d0                	cmp    %edx,%eax
f0102181:	0f 85 c6 08 00 00    	jne    f0102a4d <mem_init+0x11de>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102187:	6a 06                	push   $0x6
f0102189:	68 00 10 00 00       	push   $0x1000
f010218e:	56                   	push   %esi
f010218f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102192:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0102198:	ff 30                	pushl  (%eax)
f010219a:	e8 4a f6 ff ff       	call   f01017e9 <page_insert>
f010219f:	83 c4 10             	add    $0x10,%esp
f01021a2:	85 c0                	test   %eax,%eax
f01021a4:	0f 85 c5 08 00 00    	jne    f0102a6f <mem_init+0x1200>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ad:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01021b3:	8b 18                	mov    (%eax),%ebx
f01021b5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021ba:	89 d8                	mov    %ebx,%eax
f01021bc:	e8 fd ed ff ff       	call   f0100fbe <check_va2pa>
	return (pp - pages) << PGSHIFT;
f01021c1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021c4:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f01021ca:	89 f1                	mov    %esi,%ecx
f01021cc:	2b 0a                	sub    (%edx),%ecx
f01021ce:	89 ca                	mov    %ecx,%edx
f01021d0:	c1 fa 03             	sar    $0x3,%edx
f01021d3:	c1 e2 0c             	shl    $0xc,%edx
f01021d6:	39 d0                	cmp    %edx,%eax
f01021d8:	0f 85 b3 08 00 00    	jne    f0102a91 <mem_init+0x1222>
	assert(pp2->pp_ref == 1);
f01021de:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01021e3:	0f 85 ca 08 00 00    	jne    f0102ab3 <mem_init+0x1244>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01021e9:	83 ec 04             	sub    $0x4,%esp
f01021ec:	6a 00                	push   $0x0
f01021ee:	68 00 10 00 00       	push   $0x1000
f01021f3:	53                   	push   %ebx
f01021f4:	e8 ca f3 ff ff       	call   f01015c3 <pgdir_walk>
f01021f9:	83 c4 10             	add    $0x10,%esp
f01021fc:	f6 00 04             	testb  $0x4,(%eax)
f01021ff:	0f 84 d0 08 00 00    	je     f0102ad5 <mem_init+0x1266>
	assert(kern_pgdir[0] & PTE_U);
f0102205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102208:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010220e:	8b 00                	mov    (%eax),%eax
f0102210:	f6 00 04             	testb  $0x4,(%eax)
f0102213:	0f 84 de 08 00 00    	je     f0102af7 <mem_init+0x1288>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102219:	6a 02                	push   $0x2
f010221b:	68 00 10 00 00       	push   $0x1000
f0102220:	56                   	push   %esi
f0102221:	50                   	push   %eax
f0102222:	e8 c2 f5 ff ff       	call   f01017e9 <page_insert>
f0102227:	83 c4 10             	add    $0x10,%esp
f010222a:	85 c0                	test   %eax,%eax
f010222c:	0f 85 e7 08 00 00    	jne    f0102b19 <mem_init+0x12aa>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102232:	83 ec 04             	sub    $0x4,%esp
f0102235:	6a 00                	push   $0x0
f0102237:	68 00 10 00 00       	push   $0x1000
f010223c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010223f:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0102245:	ff 30                	pushl  (%eax)
f0102247:	e8 77 f3 ff ff       	call   f01015c3 <pgdir_walk>
f010224c:	83 c4 10             	add    $0x10,%esp
f010224f:	f6 00 02             	testb  $0x2,(%eax)
f0102252:	0f 84 e3 08 00 00    	je     f0102b3b <mem_init+0x12cc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102258:	83 ec 04             	sub    $0x4,%esp
f010225b:	6a 00                	push   $0x0
f010225d:	68 00 10 00 00       	push   $0x1000
f0102262:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102265:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010226b:	ff 30                	pushl  (%eax)
f010226d:	e8 51 f3 ff ff       	call   f01015c3 <pgdir_walk>
f0102272:	83 c4 10             	add    $0x10,%esp
f0102275:	f6 00 04             	testb  $0x4,(%eax)
f0102278:	0f 85 df 08 00 00    	jne    f0102b5d <mem_init+0x12ee>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010227e:	6a 02                	push   $0x2
f0102280:	68 00 00 40 00       	push   $0x400000
f0102285:	ff 75 d0             	pushl  -0x30(%ebp)
f0102288:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010228b:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0102291:	ff 30                	pushl  (%eax)
f0102293:	e8 51 f5 ff ff       	call   f01017e9 <page_insert>
f0102298:	83 c4 10             	add    $0x10,%esp
f010229b:	85 c0                	test   %eax,%eax
f010229d:	0f 89 dc 08 00 00    	jns    f0102b7f <mem_init+0x1310>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01022a3:	6a 02                	push   $0x2
f01022a5:	68 00 10 00 00       	push   $0x1000
f01022aa:	57                   	push   %edi
f01022ab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ae:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01022b4:	ff 30                	pushl  (%eax)
f01022b6:	e8 2e f5 ff ff       	call   f01017e9 <page_insert>
f01022bb:	83 c4 10             	add    $0x10,%esp
f01022be:	85 c0                	test   %eax,%eax
f01022c0:	0f 85 db 08 00 00    	jne    f0102ba1 <mem_init+0x1332>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022c6:	83 ec 04             	sub    $0x4,%esp
f01022c9:	6a 00                	push   $0x0
f01022cb:	68 00 10 00 00       	push   $0x1000
f01022d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022d3:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01022d9:	ff 30                	pushl  (%eax)
f01022db:	e8 e3 f2 ff ff       	call   f01015c3 <pgdir_walk>
f01022e0:	83 c4 10             	add    $0x10,%esp
f01022e3:	f6 00 04             	testb  $0x4,(%eax)
f01022e6:	0f 85 d7 08 00 00    	jne    f0102bc3 <mem_init+0x1354>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022ef:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01022f5:	8b 18                	mov    (%eax),%ebx
f01022f7:	ba 00 00 00 00       	mov    $0x0,%edx
f01022fc:	89 d8                	mov    %ebx,%eax
f01022fe:	e8 bb ec ff ff       	call   f0100fbe <check_va2pa>
f0102303:	89 c2                	mov    %eax,%edx
f0102305:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102308:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010230b:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0102311:	89 f9                	mov    %edi,%ecx
f0102313:	2b 08                	sub    (%eax),%ecx
f0102315:	89 c8                	mov    %ecx,%eax
f0102317:	c1 f8 03             	sar    $0x3,%eax
f010231a:	c1 e0 0c             	shl    $0xc,%eax
f010231d:	39 c2                	cmp    %eax,%edx
f010231f:	0f 85 c0 08 00 00    	jne    f0102be5 <mem_init+0x1376>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102325:	ba 00 10 00 00       	mov    $0x1000,%edx
f010232a:	89 d8                	mov    %ebx,%eax
f010232c:	e8 8d ec ff ff       	call   f0100fbe <check_va2pa>
f0102331:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102334:	0f 85 cd 08 00 00    	jne    f0102c07 <mem_init+0x1398>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010233a:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010233f:	0f 85 e4 08 00 00    	jne    f0102c29 <mem_init+0x13ba>
	assert(pp2->pp_ref == 0);
f0102345:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010234a:	0f 85 fb 08 00 00    	jne    f0102c4b <mem_init+0x13dc>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102350:	83 ec 0c             	sub    $0xc,%esp
f0102353:	6a 00                	push   $0x0
f0102355:	e8 4e f1 ff ff       	call   f01014a8 <page_alloc>
f010235a:	83 c4 10             	add    $0x10,%esp
f010235d:	39 c6                	cmp    %eax,%esi
f010235f:	0f 85 08 09 00 00    	jne    f0102c6d <mem_init+0x13fe>
f0102365:	85 c0                	test   %eax,%eax
f0102367:	0f 84 00 09 00 00    	je     f0102c6d <mem_init+0x13fe>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010236d:	83 ec 08             	sub    $0x8,%esp
f0102370:	6a 00                	push   $0x0
f0102372:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102375:	c7 c3 4c 10 19 f0    	mov    $0xf019104c,%ebx
f010237b:	ff 33                	pushl  (%ebx)
f010237d:	e8 28 f4 ff ff       	call   f01017aa <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102382:	8b 1b                	mov    (%ebx),%ebx
f0102384:	ba 00 00 00 00       	mov    $0x0,%edx
f0102389:	89 d8                	mov    %ebx,%eax
f010238b:	e8 2e ec ff ff       	call   f0100fbe <check_va2pa>
f0102390:	83 c4 10             	add    $0x10,%esp
f0102393:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102396:	0f 85 f3 08 00 00    	jne    f0102c8f <mem_init+0x1420>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010239c:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023a1:	89 d8                	mov    %ebx,%eax
f01023a3:	e8 16 ec ff ff       	call   f0100fbe <check_va2pa>
f01023a8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01023ab:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f01023b1:	89 f9                	mov    %edi,%ecx
f01023b3:	2b 0a                	sub    (%edx),%ecx
f01023b5:	89 ca                	mov    %ecx,%edx
f01023b7:	c1 fa 03             	sar    $0x3,%edx
f01023ba:	c1 e2 0c             	shl    $0xc,%edx
f01023bd:	39 d0                	cmp    %edx,%eax
f01023bf:	0f 85 ec 08 00 00    	jne    f0102cb1 <mem_init+0x1442>
	assert(pp1->pp_ref == 1);
f01023c5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023ca:	0f 85 03 09 00 00    	jne    f0102cd3 <mem_init+0x1464>
	assert(pp2->pp_ref == 0);
f01023d0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023d5:	0f 85 1a 09 00 00    	jne    f0102cf5 <mem_init+0x1486>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01023db:	6a 00                	push   $0x0
f01023dd:	68 00 10 00 00       	push   $0x1000
f01023e2:	57                   	push   %edi
f01023e3:	53                   	push   %ebx
f01023e4:	e8 00 f4 ff ff       	call   f01017e9 <page_insert>
f01023e9:	83 c4 10             	add    $0x10,%esp
f01023ec:	85 c0                	test   %eax,%eax
f01023ee:	0f 85 23 09 00 00    	jne    f0102d17 <mem_init+0x14a8>
	assert(pp1->pp_ref);
f01023f4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01023f9:	0f 84 3a 09 00 00    	je     f0102d39 <mem_init+0x14ca>
	assert(pp1->pp_link == NULL);
f01023ff:	83 3f 00             	cmpl   $0x0,(%edi)
f0102402:	0f 85 53 09 00 00    	jne    f0102d5b <mem_init+0x14ec>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102408:	83 ec 08             	sub    $0x8,%esp
f010240b:	68 00 10 00 00       	push   $0x1000
f0102410:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102413:	c7 c3 4c 10 19 f0    	mov    $0xf019104c,%ebx
f0102419:	ff 33                	pushl  (%ebx)
f010241b:	e8 8a f3 ff ff       	call   f01017aa <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102420:	8b 1b                	mov    (%ebx),%ebx
f0102422:	ba 00 00 00 00       	mov    $0x0,%edx
f0102427:	89 d8                	mov    %ebx,%eax
f0102429:	e8 90 eb ff ff       	call   f0100fbe <check_va2pa>
f010242e:	83 c4 10             	add    $0x10,%esp
f0102431:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102434:	0f 85 43 09 00 00    	jne    f0102d7d <mem_init+0x150e>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010243a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010243f:	89 d8                	mov    %ebx,%eax
f0102441:	e8 78 eb ff ff       	call   f0100fbe <check_va2pa>
f0102446:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102449:	0f 85 50 09 00 00    	jne    f0102d9f <mem_init+0x1530>
	assert(pp1->pp_ref == 0);
f010244f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102454:	0f 85 67 09 00 00    	jne    f0102dc1 <mem_init+0x1552>
	assert(pp2->pp_ref == 0);
f010245a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010245f:	0f 85 7e 09 00 00    	jne    f0102de3 <mem_init+0x1574>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102465:	83 ec 0c             	sub    $0xc,%esp
f0102468:	6a 00                	push   $0x0
f010246a:	e8 39 f0 ff ff       	call   f01014a8 <page_alloc>
f010246f:	83 c4 10             	add    $0x10,%esp
f0102472:	39 c7                	cmp    %eax,%edi
f0102474:	0f 85 8b 09 00 00    	jne    f0102e05 <mem_init+0x1596>
f010247a:	85 c0                	test   %eax,%eax
f010247c:	0f 84 83 09 00 00    	je     f0102e05 <mem_init+0x1596>

	// should be no free memory
	assert(!page_alloc(0));
f0102482:	83 ec 0c             	sub    $0xc,%esp
f0102485:	6a 00                	push   $0x0
f0102487:	e8 1c f0 ff ff       	call   f01014a8 <page_alloc>
f010248c:	83 c4 10             	add    $0x10,%esp
f010248f:	85 c0                	test   %eax,%eax
f0102491:	0f 85 90 09 00 00    	jne    f0102e27 <mem_init+0x15b8>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102497:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010249a:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01024a0:	8b 08                	mov    (%eax),%ecx
f01024a2:	8b 11                	mov    (%ecx),%edx
f01024a4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01024aa:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01024b0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01024b3:	2b 18                	sub    (%eax),%ebx
f01024b5:	89 d8                	mov    %ebx,%eax
f01024b7:	c1 f8 03             	sar    $0x3,%eax
f01024ba:	c1 e0 0c             	shl    $0xc,%eax
f01024bd:	39 c2                	cmp    %eax,%edx
f01024bf:	0f 85 84 09 00 00    	jne    f0102e49 <mem_init+0x15da>
	kern_pgdir[0] = 0;
f01024c5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01024cb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024ce:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01024d3:	0f 85 92 09 00 00    	jne    f0102e6b <mem_init+0x15fc>
	pp0->pp_ref = 0;
f01024d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024dc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024e2:	83 ec 0c             	sub    $0xc,%esp
f01024e5:	50                   	push   %eax
f01024e6:	e8 45 f0 ff ff       	call   f0101530 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024eb:	83 c4 0c             	add    $0xc,%esp
f01024ee:	6a 01                	push   $0x1
f01024f0:	68 00 10 40 00       	push   $0x401000
f01024f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024f8:	c7 c3 4c 10 19 f0    	mov    $0xf019104c,%ebx
f01024fe:	ff 33                	pushl  (%ebx)
f0102500:	e8 be f0 ff ff       	call   f01015c3 <pgdir_walk>
f0102505:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102508:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010250b:	8b 1b                	mov    (%ebx),%ebx
f010250d:	8b 53 04             	mov    0x4(%ebx),%edx
f0102510:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0102516:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102519:	c7 c1 48 10 19 f0    	mov    $0xf0191048,%ecx
f010251f:	8b 09                	mov    (%ecx),%ecx
f0102521:	89 d0                	mov    %edx,%eax
f0102523:	c1 e8 0c             	shr    $0xc,%eax
f0102526:	83 c4 10             	add    $0x10,%esp
f0102529:	39 c8                	cmp    %ecx,%eax
f010252b:	0f 83 5c 09 00 00    	jae    f0102e8d <mem_init+0x161e>
	assert(ptep == ptep1 + PTX(va));
f0102531:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102537:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f010253a:	0f 85 69 09 00 00    	jne    f0102ea9 <mem_init+0x163a>
	kern_pgdir[PDX(va)] = 0;
f0102540:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102547:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010254a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102550:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102553:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0102559:	2b 18                	sub    (%eax),%ebx
f010255b:	89 d8                	mov    %ebx,%eax
f010255d:	c1 f8 03             	sar    $0x3,%eax
f0102560:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102563:	89 c2                	mov    %eax,%edx
f0102565:	c1 ea 0c             	shr    $0xc,%edx
f0102568:	39 d1                	cmp    %edx,%ecx
f010256a:	0f 86 5b 09 00 00    	jbe    f0102ecb <mem_init+0x165c>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102570:	83 ec 04             	sub    $0x4,%esp
f0102573:	68 00 10 00 00       	push   $0x1000
f0102578:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010257d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102582:	50                   	push   %eax
f0102583:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102586:	e8 79 30 00 00       	call   f0105604 <memset>
	page_free(pp0);
f010258b:	83 c4 04             	add    $0x4,%esp
f010258e:	ff 75 d0             	pushl  -0x30(%ebp)
f0102591:	e8 9a ef ff ff       	call   f0101530 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102596:	83 c4 0c             	add    $0xc,%esp
f0102599:	6a 01                	push   $0x1
f010259b:	6a 00                	push   $0x0
f010259d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025a0:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01025a6:	ff 30                	pushl  (%eax)
f01025a8:	e8 16 f0 ff ff       	call   f01015c3 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01025ad:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01025b3:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01025b6:	2b 10                	sub    (%eax),%edx
f01025b8:	c1 fa 03             	sar    $0x3,%edx
f01025bb:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01025be:	89 d1                	mov    %edx,%ecx
f01025c0:	c1 e9 0c             	shr    $0xc,%ecx
f01025c3:	83 c4 10             	add    $0x10,%esp
f01025c6:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f01025cc:	3b 08                	cmp    (%eax),%ecx
f01025ce:	0f 83 10 09 00 00    	jae    f0102ee4 <mem_init+0x1675>
	return (void *)(pa + KERNBASE);
f01025d4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01025dd:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025e3:	f6 00 01             	testb  $0x1,(%eax)
f01025e6:	0f 85 11 09 00 00    	jne    f0102efd <mem_init+0x168e>
f01025ec:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01025ef:	39 d0                	cmp    %edx,%eax
f01025f1:	75 f0                	jne    f01025e3 <mem_init+0xd74>
	kern_pgdir[0] = 0;
f01025f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f6:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01025fc:	8b 00                	mov    (%eax),%eax
f01025fe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102604:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102607:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010260d:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102610:	89 93 60 23 00 00    	mov    %edx,0x2360(%ebx)

	// free the pages we took
	page_free(pp0);
f0102616:	83 ec 0c             	sub    $0xc,%esp
f0102619:	50                   	push   %eax
f010261a:	e8 11 ef ff ff       	call   f0101530 <page_free>
	page_free(pp1);
f010261f:	89 3c 24             	mov    %edi,(%esp)
f0102622:	e8 09 ef ff ff       	call   f0101530 <page_free>
	page_free(pp2);
f0102627:	89 34 24             	mov    %esi,(%esp)
f010262a:	e8 01 ef ff ff       	call   f0101530 <page_free>

	cprintf("check_page() succeeded!\n");
f010262f:	8d 83 3b 84 f7 ff    	lea    -0x87bc5(%ebx),%eax
f0102635:	89 04 24             	mov    %eax,(%esp)
f0102638:	e8 35 19 00 00       	call   f0103f72 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, pagesize, PADDR(pages), PTE_P | PTE_U);
f010263d:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0102643:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102645:	83 c4 10             	add    $0x10,%esp
f0102648:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010264d:	0f 86 cc 08 00 00    	jbe    f0102f1f <mem_init+0x16b0>
f0102653:	83 ec 08             	sub    $0x8,%esp
f0102656:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102658:	05 00 00 00 10       	add    $0x10000000,%eax
f010265d:	50                   	push   %eax
f010265e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102661:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102666:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102669:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010266f:	8b 00                	mov    (%eax),%eax
f0102671:	e8 39 f0 ff ff       	call   f01016af <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, envsize, PADDR(envs), PTE_U | PTE_P);
f0102676:	c7 c0 88 03 19 f0    	mov    $0xf0190388,%eax
f010267c:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010267e:	83 c4 10             	add    $0x10,%esp
f0102681:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102686:	0f 86 af 08 00 00    	jbe    f0102f3b <mem_init+0x16cc>
f010268c:	83 ec 08             	sub    $0x8,%esp
f010268f:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102691:	05 00 00 00 10       	add    $0x10000000,%eax
f0102696:	50                   	push   %eax
f0102697:	b9 00 80 01 00       	mov    $0x18000,%ecx
f010269c:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026a1:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01026a4:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01026aa:	8b 00                	mov    (%eax),%eax
f01026ac:	e8 fe ef ff ff       	call   f01016af <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01026b1:	c7 c0 00 40 11 f0    	mov    $0xf0114000,%eax
f01026b7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01026ba:	83 c4 10             	add    $0x10,%esp
f01026bd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026c2:	0f 86 8f 08 00 00    	jbe    f0102f57 <mem_init+0x16e8>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01026c8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01026cb:	c7 c3 4c 10 19 f0    	mov    $0xf019104c,%ebx
f01026d1:	83 ec 08             	sub    $0x8,%esp
f01026d4:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01026d6:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01026d9:	05 00 00 00 10       	add    $0x10000000,%eax
f01026de:	50                   	push   %eax
f01026df:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026e4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026e9:	8b 03                	mov    (%ebx),%eax
f01026eb:	e8 bf ef ff ff       	call   f01016af <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01026f0:	83 c4 08             	add    $0x8,%esp
f01026f3:	6a 02                	push   $0x2
f01026f5:	6a 00                	push   $0x0
f01026f7:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01026fc:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102701:	8b 03                	mov    (%ebx),%eax
f0102703:	e8 a7 ef ff ff       	call   f01016af <boot_map_region>
	pgdir = kern_pgdir;
f0102708:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010270a:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0102710:	8b 00                	mov    (%eax),%eax
f0102712:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102715:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010271c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102721:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102724:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f010272a:	8b 00                	mov    (%eax),%eax
f010272c:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010272f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102732:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f0102738:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010273b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102740:	e9 57 08 00 00       	jmp    f0102f9c <mem_init+0x172d>
	assert(nfree == 0);
f0102745:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102748:	8d 83 64 83 f7 ff    	lea    -0x87c9c(%ebx),%eax
f010274e:	50                   	push   %eax
f010274f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102755:	50                   	push   %eax
f0102756:	68 e9 02 00 00       	push   $0x2e9
f010275b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102761:	50                   	push   %eax
f0102762:	e8 4a d9 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102767:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010276a:	8d 83 72 82 f7 ff    	lea    -0x87d8e(%ebx),%eax
f0102770:	50                   	push   %eax
f0102771:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102777:	50                   	push   %eax
f0102778:	68 47 03 00 00       	push   $0x347
f010277d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102783:	50                   	push   %eax
f0102784:	e8 28 d9 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0102789:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010278c:	8d 83 88 82 f7 ff    	lea    -0x87d78(%ebx),%eax
f0102792:	50                   	push   %eax
f0102793:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102799:	50                   	push   %eax
f010279a:	68 48 03 00 00       	push   $0x348
f010279f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01027a5:	50                   	push   %eax
f01027a6:	e8 06 d9 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01027ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ae:	8d 83 9e 82 f7 ff    	lea    -0x87d62(%ebx),%eax
f01027b4:	50                   	push   %eax
f01027b5:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01027bb:	50                   	push   %eax
f01027bc:	68 49 03 00 00       	push   $0x349
f01027c1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01027c7:	50                   	push   %eax
f01027c8:	e8 e4 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01027cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d0:	8d 83 b4 82 f7 ff    	lea    -0x87d4c(%ebx),%eax
f01027d6:	50                   	push   %eax
f01027d7:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01027dd:	50                   	push   %eax
f01027de:	68 4c 03 00 00       	push   $0x34c
f01027e3:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01027e9:	50                   	push   %eax
f01027ea:	e8 c2 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01027ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f2:	8d 83 9c 86 f7 ff    	lea    -0x87964(%ebx),%eax
f01027f8:	50                   	push   %eax
f01027f9:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01027ff:	50                   	push   %eax
f0102800:	68 4d 03 00 00       	push   $0x34d
f0102805:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010280b:	50                   	push   %eax
f010280c:	e8 a0 d8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102811:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102814:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f010281a:	50                   	push   %eax
f010281b:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102821:	50                   	push   %eax
f0102822:	68 54 03 00 00       	push   $0x354
f0102827:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010282d:	50                   	push   %eax
f010282e:	e8 7e d8 ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102833:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102836:	8d 83 dc 86 f7 ff    	lea    -0x87924(%ebx),%eax
f010283c:	50                   	push   %eax
f010283d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102843:	50                   	push   %eax
f0102844:	68 57 03 00 00       	push   $0x357
f0102849:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010284f:	50                   	push   %eax
f0102850:	e8 5c d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102855:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102858:	8d 83 14 87 f7 ff    	lea    -0x878ec(%ebx),%eax
f010285e:	50                   	push   %eax
f010285f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102865:	50                   	push   %eax
f0102866:	68 5a 03 00 00       	push   $0x35a
f010286b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102871:	50                   	push   %eax
f0102872:	e8 3a d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102877:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010287a:	8d 83 44 87 f7 ff    	lea    -0x878bc(%ebx),%eax
f0102880:	50                   	push   %eax
f0102881:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102887:	50                   	push   %eax
f0102888:	68 5e 03 00 00       	push   $0x35e
f010288d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102893:	50                   	push   %eax
f0102894:	e8 18 d8 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102899:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010289c:	8d 83 74 87 f7 ff    	lea    -0x8788c(%ebx),%eax
f01028a2:	50                   	push   %eax
f01028a3:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01028a9:	50                   	push   %eax
f01028aa:	68 5f 03 00 00       	push   $0x35f
f01028af:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01028b5:	50                   	push   %eax
f01028b6:	e8 f6 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01028bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028be:	8d 83 9c 87 f7 ff    	lea    -0x87864(%ebx),%eax
f01028c4:	50                   	push   %eax
f01028c5:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01028cb:	50                   	push   %eax
f01028cc:	68 60 03 00 00       	push   $0x360
f01028d1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	e8 d4 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01028dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e0:	8d 83 6f 83 f7 ff    	lea    -0x87c91(%ebx),%eax
f01028e6:	50                   	push   %eax
f01028e7:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01028ed:	50                   	push   %eax
f01028ee:	68 61 03 00 00       	push   $0x361
f01028f3:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01028f9:	50                   	push   %eax
f01028fa:	e8 b2 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01028ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102902:	8d 83 80 83 f7 ff    	lea    -0x87c80(%ebx),%eax
f0102908:	50                   	push   %eax
f0102909:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010290f:	50                   	push   %eax
f0102910:	68 62 03 00 00       	push   $0x362
f0102915:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010291b:	50                   	push   %eax
f010291c:	e8 90 d7 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102921:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102924:	8d 83 cc 87 f7 ff    	lea    -0x87834(%ebx),%eax
f010292a:	50                   	push   %eax
f010292b:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102931:	50                   	push   %eax
f0102932:	68 65 03 00 00       	push   $0x365
f0102937:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010293d:	50                   	push   %eax
f010293e:	e8 6e d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102943:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102946:	8d 83 08 88 f7 ff    	lea    -0x877f8(%ebx),%eax
f010294c:	50                   	push   %eax
f010294d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102953:	50                   	push   %eax
f0102954:	68 66 03 00 00       	push   $0x366
f0102959:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010295f:	50                   	push   %eax
f0102960:	e8 4c d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102965:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102968:	8d 83 91 83 f7 ff    	lea    -0x87c6f(%ebx),%eax
f010296e:	50                   	push   %eax
f010296f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102975:	50                   	push   %eax
f0102976:	68 67 03 00 00       	push   $0x367
f010297b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102981:	50                   	push   %eax
f0102982:	e8 2a d7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102987:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298a:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f0102990:	50                   	push   %eax
f0102991:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102997:	50                   	push   %eax
f0102998:	68 6a 03 00 00       	push   $0x36a
f010299d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01029a3:	50                   	push   %eax
f01029a4:	e8 08 d7 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01029a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ac:	8d 83 cc 87 f7 ff    	lea    -0x87834(%ebx),%eax
f01029b2:	50                   	push   %eax
f01029b3:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01029b9:	50                   	push   %eax
f01029ba:	68 6d 03 00 00       	push   $0x36d
f01029bf:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01029c5:	50                   	push   %eax
f01029c6:	e8 e6 d6 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01029cb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ce:	8d 83 08 88 f7 ff    	lea    -0x877f8(%ebx),%eax
f01029d4:	50                   	push   %eax
f01029d5:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01029db:	50                   	push   %eax
f01029dc:	68 6e 03 00 00       	push   $0x36e
f01029e1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01029e7:	50                   	push   %eax
f01029e8:	e8 c4 d6 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01029ed:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f0:	8d 83 91 83 f7 ff    	lea    -0x87c6f(%ebx),%eax
f01029f6:	50                   	push   %eax
f01029f7:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01029fd:	50                   	push   %eax
f01029fe:	68 6f 03 00 00       	push   $0x36f
f0102a03:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102a09:	50                   	push   %eax
f0102a0a:	e8 a2 d6 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102a0f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a12:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f0102a18:	50                   	push   %eax
f0102a19:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102a1f:	50                   	push   %eax
f0102a20:	68 73 03 00 00       	push   $0x373
f0102a25:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102a2b:	50                   	push   %eax
f0102a2c:	e8 80 d6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a31:	50                   	push   %eax
f0102a32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a35:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0102a3b:	50                   	push   %eax
f0102a3c:	68 76 03 00 00       	push   $0x376
f0102a41:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102a47:	50                   	push   %eax
f0102a48:	e8 64 d6 ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102a4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a50:	8d 83 38 88 f7 ff    	lea    -0x877c8(%ebx),%eax
f0102a56:	50                   	push   %eax
f0102a57:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102a5d:	50                   	push   %eax
f0102a5e:	68 77 03 00 00       	push   $0x377
f0102a63:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102a69:	50                   	push   %eax
f0102a6a:	e8 42 d6 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102a6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a72:	8d 83 78 88 f7 ff    	lea    -0x87788(%ebx),%eax
f0102a78:	50                   	push   %eax
f0102a79:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102a7f:	50                   	push   %eax
f0102a80:	68 7a 03 00 00       	push   $0x37a
f0102a85:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102a8b:	50                   	push   %eax
f0102a8c:	e8 20 d6 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102a91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a94:	8d 83 08 88 f7 ff    	lea    -0x877f8(%ebx),%eax
f0102a9a:	50                   	push   %eax
f0102a9b:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102aa1:	50                   	push   %eax
f0102aa2:	68 7b 03 00 00       	push   $0x37b
f0102aa7:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102aad:	50                   	push   %eax
f0102aae:	e8 fe d5 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102ab3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab6:	8d 83 91 83 f7 ff    	lea    -0x87c6f(%ebx),%eax
f0102abc:	50                   	push   %eax
f0102abd:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102ac3:	50                   	push   %eax
f0102ac4:	68 7c 03 00 00       	push   $0x37c
f0102ac9:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102acf:	50                   	push   %eax
f0102ad0:	e8 dc d5 ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102ad5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ad8:	8d 83 b8 88 f7 ff    	lea    -0x87748(%ebx),%eax
f0102ade:	50                   	push   %eax
f0102adf:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102ae5:	50                   	push   %eax
f0102ae6:	68 7d 03 00 00       	push   $0x37d
f0102aeb:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102af1:	50                   	push   %eax
f0102af2:	e8 ba d5 ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102af7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102afa:	8d 83 a2 83 f7 ff    	lea    -0x87c5e(%ebx),%eax
f0102b00:	50                   	push   %eax
f0102b01:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102b07:	50                   	push   %eax
f0102b08:	68 7e 03 00 00       	push   $0x37e
f0102b0d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102b13:	50                   	push   %eax
f0102b14:	e8 98 d5 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102b19:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1c:	8d 83 cc 87 f7 ff    	lea    -0x87834(%ebx),%eax
f0102b22:	50                   	push   %eax
f0102b23:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102b29:	50                   	push   %eax
f0102b2a:	68 81 03 00 00       	push   $0x381
f0102b2f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102b35:	50                   	push   %eax
f0102b36:	e8 76 d5 ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102b3b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b3e:	8d 83 ec 88 f7 ff    	lea    -0x87714(%ebx),%eax
f0102b44:	50                   	push   %eax
f0102b45:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102b4b:	50                   	push   %eax
f0102b4c:	68 82 03 00 00       	push   $0x382
f0102b51:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102b57:	50                   	push   %eax
f0102b58:	e8 54 d5 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102b5d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b60:	8d 83 20 89 f7 ff    	lea    -0x876e0(%ebx),%eax
f0102b66:	50                   	push   %eax
f0102b67:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102b6d:	50                   	push   %eax
f0102b6e:	68 83 03 00 00       	push   $0x383
f0102b73:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102b79:	50                   	push   %eax
f0102b7a:	e8 32 d5 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102b7f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b82:	8d 83 58 89 f7 ff    	lea    -0x876a8(%ebx),%eax
f0102b88:	50                   	push   %eax
f0102b89:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102b8f:	50                   	push   %eax
f0102b90:	68 86 03 00 00       	push   $0x386
f0102b95:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102b9b:	50                   	push   %eax
f0102b9c:	e8 10 d5 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102ba1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ba4:	8d 83 90 89 f7 ff    	lea    -0x87670(%ebx),%eax
f0102baa:	50                   	push   %eax
f0102bab:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102bb1:	50                   	push   %eax
f0102bb2:	68 89 03 00 00       	push   $0x389
f0102bb7:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102bbd:	50                   	push   %eax
f0102bbe:	e8 ee d4 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102bc3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc6:	8d 83 20 89 f7 ff    	lea    -0x876e0(%ebx),%eax
f0102bcc:	50                   	push   %eax
f0102bcd:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102bd3:	50                   	push   %eax
f0102bd4:	68 8a 03 00 00       	push   $0x38a
f0102bd9:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102bdf:	50                   	push   %eax
f0102be0:	e8 cc d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102be5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be8:	8d 83 cc 89 f7 ff    	lea    -0x87634(%ebx),%eax
f0102bee:	50                   	push   %eax
f0102bef:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102bf5:	50                   	push   %eax
f0102bf6:	68 8d 03 00 00       	push   $0x38d
f0102bfb:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102c01:	50                   	push   %eax
f0102c02:	e8 aa d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102c07:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c0a:	8d 83 f8 89 f7 ff    	lea    -0x87608(%ebx),%eax
f0102c10:	50                   	push   %eax
f0102c11:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102c17:	50                   	push   %eax
f0102c18:	68 8e 03 00 00       	push   $0x38e
f0102c1d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102c23:	50                   	push   %eax
f0102c24:	e8 88 d4 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f0102c29:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2c:	8d 83 b8 83 f7 ff    	lea    -0x87c48(%ebx),%eax
f0102c32:	50                   	push   %eax
f0102c33:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102c39:	50                   	push   %eax
f0102c3a:	68 90 03 00 00       	push   $0x390
f0102c3f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102c45:	50                   	push   %eax
f0102c46:	e8 66 d4 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102c4b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c4e:	8d 83 c9 83 f7 ff    	lea    -0x87c37(%ebx),%eax
f0102c54:	50                   	push   %eax
f0102c55:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102c5b:	50                   	push   %eax
f0102c5c:	68 91 03 00 00       	push   $0x391
f0102c61:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102c67:	50                   	push   %eax
f0102c68:	e8 44 d4 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102c6d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c70:	8d 83 28 8a f7 ff    	lea    -0x875d8(%ebx),%eax
f0102c76:	50                   	push   %eax
f0102c77:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102c7d:	50                   	push   %eax
f0102c7e:	68 94 03 00 00       	push   $0x394
f0102c83:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102c89:	50                   	push   %eax
f0102c8a:	e8 22 d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102c8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c92:	8d 83 4c 8a f7 ff    	lea    -0x875b4(%ebx),%eax
f0102c98:	50                   	push   %eax
f0102c99:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102c9f:	50                   	push   %eax
f0102ca0:	68 98 03 00 00       	push   $0x398
f0102ca5:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102cab:	50                   	push   %eax
f0102cac:	e8 00 d4 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102cb1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb4:	8d 83 f8 89 f7 ff    	lea    -0x87608(%ebx),%eax
f0102cba:	50                   	push   %eax
f0102cbb:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102cc1:	50                   	push   %eax
f0102cc2:	68 99 03 00 00       	push   $0x399
f0102cc7:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102ccd:	50                   	push   %eax
f0102cce:	e8 de d3 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102cd3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cd6:	8d 83 6f 83 f7 ff    	lea    -0x87c91(%ebx),%eax
f0102cdc:	50                   	push   %eax
f0102cdd:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102ce3:	50                   	push   %eax
f0102ce4:	68 9a 03 00 00       	push   $0x39a
f0102ce9:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102cef:	50                   	push   %eax
f0102cf0:	e8 bc d3 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102cf5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cf8:	8d 83 c9 83 f7 ff    	lea    -0x87c37(%ebx),%eax
f0102cfe:	50                   	push   %eax
f0102cff:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102d05:	50                   	push   %eax
f0102d06:	68 9b 03 00 00       	push   $0x39b
f0102d0b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102d11:	50                   	push   %eax
f0102d12:	e8 9a d3 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102d17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d1a:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f0102d20:	50                   	push   %eax
f0102d21:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102d27:	50                   	push   %eax
f0102d28:	68 9e 03 00 00       	push   $0x39e
f0102d2d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102d33:	50                   	push   %eax
f0102d34:	e8 78 d3 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f0102d39:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d3c:	8d 83 da 83 f7 ff    	lea    -0x87c26(%ebx),%eax
f0102d42:	50                   	push   %eax
f0102d43:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102d49:	50                   	push   %eax
f0102d4a:	68 9f 03 00 00       	push   $0x39f
f0102d4f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102d55:	50                   	push   %eax
f0102d56:	e8 56 d3 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f0102d5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d5e:	8d 83 e6 83 f7 ff    	lea    -0x87c1a(%ebx),%eax
f0102d64:	50                   	push   %eax
f0102d65:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102d6b:	50                   	push   %eax
f0102d6c:	68 a0 03 00 00       	push   $0x3a0
f0102d71:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102d77:	50                   	push   %eax
f0102d78:	e8 34 d3 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102d7d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d80:	8d 83 4c 8a f7 ff    	lea    -0x875b4(%ebx),%eax
f0102d86:	50                   	push   %eax
f0102d87:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102d8d:	50                   	push   %eax
f0102d8e:	68 a4 03 00 00       	push   $0x3a4
f0102d93:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102d99:	50                   	push   %eax
f0102d9a:	e8 12 d3 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102d9f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102da2:	8d 83 a8 8a f7 ff    	lea    -0x87558(%ebx),%eax
f0102da8:	50                   	push   %eax
f0102da9:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102daf:	50                   	push   %eax
f0102db0:	68 a5 03 00 00       	push   $0x3a5
f0102db5:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102dbb:	50                   	push   %eax
f0102dbc:	e8 f0 d2 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0102dc1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dc4:	8d 83 fb 83 f7 ff    	lea    -0x87c05(%ebx),%eax
f0102dca:	50                   	push   %eax
f0102dcb:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102dd1:	50                   	push   %eax
f0102dd2:	68 a6 03 00 00       	push   $0x3a6
f0102dd7:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102ddd:	50                   	push   %eax
f0102dde:	e8 ce d2 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102de3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102de6:	8d 83 c9 83 f7 ff    	lea    -0x87c37(%ebx),%eax
f0102dec:	50                   	push   %eax
f0102ded:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102df3:	50                   	push   %eax
f0102df4:	68 a7 03 00 00       	push   $0x3a7
f0102df9:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102dff:	50                   	push   %eax
f0102e00:	e8 ac d2 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102e05:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e08:	8d 83 d0 8a f7 ff    	lea    -0x87530(%ebx),%eax
f0102e0e:	50                   	push   %eax
f0102e0f:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102e15:	50                   	push   %eax
f0102e16:	68 aa 03 00 00       	push   $0x3aa
f0102e1b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102e21:	50                   	push   %eax
f0102e22:	e8 8a d2 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102e27:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e2a:	8d 83 1d 83 f7 ff    	lea    -0x87ce3(%ebx),%eax
f0102e30:	50                   	push   %eax
f0102e31:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102e37:	50                   	push   %eax
f0102e38:	68 ad 03 00 00       	push   $0x3ad
f0102e3d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102e43:	50                   	push   %eax
f0102e44:	e8 68 d2 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e4c:	8d 83 74 87 f7 ff    	lea    -0x8788c(%ebx),%eax
f0102e52:	50                   	push   %eax
f0102e53:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102e59:	50                   	push   %eax
f0102e5a:	68 b0 03 00 00       	push   $0x3b0
f0102e5f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102e65:	50                   	push   %eax
f0102e66:	e8 46 d2 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102e6b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e6e:	8d 83 80 83 f7 ff    	lea    -0x87c80(%ebx),%eax
f0102e74:	50                   	push   %eax
f0102e75:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102e7b:	50                   	push   %eax
f0102e7c:	68 b2 03 00 00       	push   $0x3b2
f0102e81:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102e87:	50                   	push   %eax
f0102e88:	e8 24 d2 ff ff       	call   f01000b1 <_panic>
f0102e8d:	52                   	push   %edx
f0102e8e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e91:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0102e97:	50                   	push   %eax
f0102e98:	68 b9 03 00 00       	push   $0x3b9
f0102e9d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102ea3:	50                   	push   %eax
f0102ea4:	e8 08 d2 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102ea9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eac:	8d 83 0c 84 f7 ff    	lea    -0x87bf4(%ebx),%eax
f0102eb2:	50                   	push   %eax
f0102eb3:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102eb9:	50                   	push   %eax
f0102eba:	68 ba 03 00 00       	push   $0x3ba
f0102ebf:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102ec5:	50                   	push   %eax
f0102ec6:	e8 e6 d1 ff ff       	call   f01000b1 <_panic>
f0102ecb:	50                   	push   %eax
f0102ecc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ecf:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0102ed5:	50                   	push   %eax
f0102ed6:	6a 56                	push   $0x56
f0102ed8:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0102ede:	50                   	push   %eax
f0102edf:	e8 cd d1 ff ff       	call   f01000b1 <_panic>
f0102ee4:	52                   	push   %edx
f0102ee5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ee8:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0102eee:	50                   	push   %eax
f0102eef:	6a 56                	push   $0x56
f0102ef1:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0102ef7:	50                   	push   %eax
f0102ef8:	e8 b4 d1 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102efd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f00:	8d 83 24 84 f7 ff    	lea    -0x87bdc(%ebx),%eax
f0102f06:	50                   	push   %eax
f0102f07:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102f0d:	50                   	push   %eax
f0102f0e:	68 c4 03 00 00       	push   $0x3c4
f0102f13:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102f19:	50                   	push   %eax
f0102f1a:	e8 92 d1 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f1f:	50                   	push   %eax
f0102f20:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f23:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0102f29:	50                   	push   %eax
f0102f2a:	68 ca 00 00 00       	push   $0xca
f0102f2f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102f35:	50                   	push   %eax
f0102f36:	e8 76 d1 ff ff       	call   f01000b1 <_panic>
f0102f3b:	50                   	push   %eax
f0102f3c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f3f:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0102f45:	50                   	push   %eax
f0102f46:	68 d2 00 00 00       	push   $0xd2
f0102f4b:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102f51:	50                   	push   %eax
f0102f52:	e8 5a d1 ff ff       	call   f01000b1 <_panic>
f0102f57:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f5a:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102f60:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0102f66:	50                   	push   %eax
f0102f67:	68 df 00 00 00       	push   $0xdf
f0102f6c:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102f72:	50                   	push   %eax
f0102f73:	e8 39 d1 ff ff       	call   f01000b1 <_panic>
f0102f78:	ff 75 c0             	pushl  -0x40(%ebp)
f0102f7b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f7e:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0102f84:	50                   	push   %eax
f0102f85:	68 01 03 00 00       	push   $0x301
f0102f8a:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102f90:	50                   	push   %eax
f0102f91:	e8 1b d1 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102f96:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f9c:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102f9f:	76 3f                	jbe    f0102fe0 <mem_init+0x1771>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102fa1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102fa7:	89 f0                	mov    %esi,%eax
f0102fa9:	e8 10 e0 ff ff       	call   f0100fbe <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102fae:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102fb5:	76 c1                	jbe    f0102f78 <mem_init+0x1709>
f0102fb7:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102fba:	39 d0                	cmp    %edx,%eax
f0102fbc:	74 d8                	je     f0102f96 <mem_init+0x1727>
f0102fbe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc1:	8d 83 f4 8a f7 ff    	lea    -0x8750c(%ebx),%eax
f0102fc7:	50                   	push   %eax
f0102fc8:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0102fce:	50                   	push   %eax
f0102fcf:	68 01 03 00 00       	push   $0x301
f0102fd4:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0102fda:	50                   	push   %eax
f0102fdb:	e8 d1 d0 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fe0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fe3:	c7 c0 88 03 19 f0    	mov    $0xf0190388,%eax
f0102fe9:	8b 00                	mov    (%eax),%eax
f0102feb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102fee:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102ff1:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102ff6:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102ffc:	89 fa                	mov    %edi,%edx
f0102ffe:	89 f0                	mov    %esi,%eax
f0103000:	e8 b9 df ff ff       	call   f0100fbe <check_va2pa>
f0103005:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010300c:	76 3d                	jbe    f010304b <mem_init+0x17dc>
f010300e:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0103011:	39 d0                	cmp    %edx,%eax
f0103013:	75 54                	jne    f0103069 <mem_init+0x17fa>
f0103015:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f010301b:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0103021:	75 d9                	jne    f0102ffc <mem_init+0x178d>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103023:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103026:	c1 e7 0c             	shl    $0xc,%edi
f0103029:	bb 00 00 00 00       	mov    $0x0,%ebx
f010302e:	39 fb                	cmp    %edi,%ebx
f0103030:	73 7b                	jae    f01030ad <mem_init+0x183e>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0103032:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0103038:	89 f0                	mov    %esi,%eax
f010303a:	e8 7f df ff ff       	call   f0100fbe <check_va2pa>
f010303f:	39 c3                	cmp    %eax,%ebx
f0103041:	75 48                	jne    f010308b <mem_init+0x181c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103043:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103049:	eb e3                	jmp    f010302e <mem_init+0x17bf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010304b:	ff 75 cc             	pushl  -0x34(%ebp)
f010304e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103051:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103057:	50                   	push   %eax
f0103058:	68 06 03 00 00       	push   $0x306
f010305d:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103063:	50                   	push   %eax
f0103064:	e8 48 d0 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0103069:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010306c:	8d 83 28 8b f7 ff    	lea    -0x874d8(%ebx),%eax
f0103072:	50                   	push   %eax
f0103073:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103079:	50                   	push   %eax
f010307a:	68 06 03 00 00       	push   $0x306
f010307f:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103085:	50                   	push   %eax
f0103086:	e8 26 d0 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010308b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010308e:	8d 83 5c 8b f7 ff    	lea    -0x874a4(%ebx),%eax
f0103094:	50                   	push   %eax
f0103095:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010309b:	50                   	push   %eax
f010309c:	68 0a 03 00 00       	push   $0x30a
f01030a1:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01030a7:	50                   	push   %eax
f01030a8:	e8 04 d0 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01030ad:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01030b2:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01030b5:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f01030bb:	89 da                	mov    %ebx,%edx
f01030bd:	89 f0                	mov    %esi,%eax
f01030bf:	e8 fa de ff ff       	call   f0100fbe <check_va2pa>
f01030c4:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f01030c7:	39 c2                	cmp    %eax,%edx
f01030c9:	75 26                	jne    f01030f1 <mem_init+0x1882>
f01030cb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01030d1:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01030d7:	75 e2                	jne    f01030bb <mem_init+0x184c>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01030d9:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01030de:	89 f0                	mov    %esi,%eax
f01030e0:	e8 d9 de ff ff       	call   f0100fbe <check_va2pa>
f01030e5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01030e8:	75 29                	jne    f0103113 <mem_init+0x18a4>
	for (i = 0; i < NPDENTRIES; i++) {
f01030ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01030ef:	eb 6d                	jmp    f010315e <mem_init+0x18ef>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01030f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030f4:	8d 83 84 8b f7 ff    	lea    -0x8747c(%ebx),%eax
f01030fa:	50                   	push   %eax
f01030fb:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103101:	50                   	push   %eax
f0103102:	68 0e 03 00 00       	push   $0x30e
f0103107:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010310d:	50                   	push   %eax
f010310e:	e8 9e cf ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0103113:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103116:	8d 83 cc 8b f7 ff    	lea    -0x87434(%ebx),%eax
f010311c:	50                   	push   %eax
f010311d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103123:	50                   	push   %eax
f0103124:	68 0f 03 00 00       	push   $0x30f
f0103129:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010312f:	50                   	push   %eax
f0103130:	e8 7c cf ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0103135:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0103139:	74 52                	je     f010318d <mem_init+0x191e>
	for (i = 0; i < NPDENTRIES; i++) {
f010313b:	83 c0 01             	add    $0x1,%eax
f010313e:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0103143:	0f 87 bb 00 00 00    	ja     f0103204 <mem_init+0x1995>
		switch (i) {
f0103149:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010314e:	72 0e                	jb     f010315e <mem_init+0x18ef>
f0103150:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0103155:	76 de                	jbe    f0103135 <mem_init+0x18c6>
f0103157:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010315c:	74 d7                	je     f0103135 <mem_init+0x18c6>
			if (i >= PDX(KERNBASE)) {
f010315e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103163:	77 4a                	ja     f01031af <mem_init+0x1940>
				assert(pgdir[i] == 0);
f0103165:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0103169:	74 d0                	je     f010313b <mem_init+0x18cc>
f010316b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010316e:	8d 83 76 84 f7 ff    	lea    -0x87b8a(%ebx),%eax
f0103174:	50                   	push   %eax
f0103175:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010317b:	50                   	push   %eax
f010317c:	68 1f 03 00 00       	push   $0x31f
f0103181:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103187:	50                   	push   %eax
f0103188:	e8 24 cf ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f010318d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103190:	8d 83 54 84 f7 ff    	lea    -0x87bac(%ebx),%eax
f0103196:	50                   	push   %eax
f0103197:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010319d:	50                   	push   %eax
f010319e:	68 18 03 00 00       	push   $0x318
f01031a3:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01031a9:	50                   	push   %eax
f01031aa:	e8 02 cf ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f01031af:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01031b2:	f6 c2 01             	test   $0x1,%dl
f01031b5:	74 2b                	je     f01031e2 <mem_init+0x1973>
				assert(pgdir[i] & PTE_W);
f01031b7:	f6 c2 02             	test   $0x2,%dl
f01031ba:	0f 85 7b ff ff ff    	jne    f010313b <mem_init+0x18cc>
f01031c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031c3:	8d 83 65 84 f7 ff    	lea    -0x87b9b(%ebx),%eax
f01031c9:	50                   	push   %eax
f01031ca:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01031d0:	50                   	push   %eax
f01031d1:	68 1d 03 00 00       	push   $0x31d
f01031d6:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01031dc:	50                   	push   %eax
f01031dd:	e8 cf ce ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f01031e2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031e5:	8d 83 54 84 f7 ff    	lea    -0x87bac(%ebx),%eax
f01031eb:	50                   	push   %eax
f01031ec:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01031f2:	50                   	push   %eax
f01031f3:	68 1c 03 00 00       	push   $0x31c
f01031f8:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01031fe:	50                   	push   %eax
f01031ff:	e8 ad ce ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0103204:	83 ec 0c             	sub    $0xc,%esp
f0103207:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010320a:	8d 87 fc 8b f7 ff    	lea    -0x87404(%edi),%eax
f0103210:	50                   	push   %eax
f0103211:	89 fb                	mov    %edi,%ebx
f0103213:	e8 5a 0d 00 00       	call   f0103f72 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0103218:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010321e:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103220:	83 c4 10             	add    $0x10,%esp
f0103223:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103228:	0f 86 44 02 00 00    	jbe    f0103472 <mem_init+0x1c03>
	return (physaddr_t)kva - KERNBASE;
f010322e:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103233:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0103236:	b8 00 00 00 00       	mov    $0x0,%eax
f010323b:	e8 fb dd ff ff       	call   f010103b <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0103240:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0103243:	83 e0 f3             	and    $0xfffffff3,%eax
f0103246:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010324b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010324e:	83 ec 0c             	sub    $0xc,%esp
f0103251:	6a 00                	push   $0x0
f0103253:	e8 50 e2 ff ff       	call   f01014a8 <page_alloc>
f0103258:	89 c6                	mov    %eax,%esi
f010325a:	83 c4 10             	add    $0x10,%esp
f010325d:	85 c0                	test   %eax,%eax
f010325f:	0f 84 29 02 00 00    	je     f010348e <mem_init+0x1c1f>
	assert((pp1 = page_alloc(0)));
f0103265:	83 ec 0c             	sub    $0xc,%esp
f0103268:	6a 00                	push   $0x0
f010326a:	e8 39 e2 ff ff       	call   f01014a8 <page_alloc>
f010326f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103272:	83 c4 10             	add    $0x10,%esp
f0103275:	85 c0                	test   %eax,%eax
f0103277:	0f 84 33 02 00 00    	je     f01034b0 <mem_init+0x1c41>
	assert((pp2 = page_alloc(0)));
f010327d:	83 ec 0c             	sub    $0xc,%esp
f0103280:	6a 00                	push   $0x0
f0103282:	e8 21 e2 ff ff       	call   f01014a8 <page_alloc>
f0103287:	89 c7                	mov    %eax,%edi
f0103289:	83 c4 10             	add    $0x10,%esp
f010328c:	85 c0                	test   %eax,%eax
f010328e:	0f 84 3e 02 00 00    	je     f01034d2 <mem_init+0x1c63>
	page_free(pp0);
f0103294:	83 ec 0c             	sub    $0xc,%esp
f0103297:	56                   	push   %esi
f0103298:	e8 93 e2 ff ff       	call   f0101530 <page_free>
	return (pp - pages) << PGSHIFT;
f010329d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032a0:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01032a6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01032a9:	2b 08                	sub    (%eax),%ecx
f01032ab:	89 c8                	mov    %ecx,%eax
f01032ad:	c1 f8 03             	sar    $0x3,%eax
f01032b0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01032b3:	89 c1                	mov    %eax,%ecx
f01032b5:	c1 e9 0c             	shr    $0xc,%ecx
f01032b8:	83 c4 10             	add    $0x10,%esp
f01032bb:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f01032c1:	3b 0a                	cmp    (%edx),%ecx
f01032c3:	0f 83 2b 02 00 00    	jae    f01034f4 <mem_init+0x1c85>
	memset(page2kva(pp1), 1, PGSIZE);
f01032c9:	83 ec 04             	sub    $0x4,%esp
f01032cc:	68 00 10 00 00       	push   $0x1000
f01032d1:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01032d3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01032d8:	50                   	push   %eax
f01032d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032dc:	e8 23 23 00 00       	call   f0105604 <memset>
	return (pp - pages) << PGSHIFT;
f01032e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032e4:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01032ea:	89 f9                	mov    %edi,%ecx
f01032ec:	2b 08                	sub    (%eax),%ecx
f01032ee:	89 c8                	mov    %ecx,%eax
f01032f0:	c1 f8 03             	sar    $0x3,%eax
f01032f3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01032f6:	89 c1                	mov    %eax,%ecx
f01032f8:	c1 e9 0c             	shr    $0xc,%ecx
f01032fb:	83 c4 10             	add    $0x10,%esp
f01032fe:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f0103304:	3b 0a                	cmp    (%edx),%ecx
f0103306:	0f 83 fe 01 00 00    	jae    f010350a <mem_init+0x1c9b>
	memset(page2kva(pp2), 2, PGSIZE);
f010330c:	83 ec 04             	sub    $0x4,%esp
f010330f:	68 00 10 00 00       	push   $0x1000
f0103314:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0103316:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010331b:	50                   	push   %eax
f010331c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010331f:	e8 e0 22 00 00       	call   f0105604 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103324:	6a 02                	push   $0x2
f0103326:	68 00 10 00 00       	push   $0x1000
f010332b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010332e:	53                   	push   %ebx
f010332f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103332:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0103338:	ff 30                	pushl  (%eax)
f010333a:	e8 aa e4 ff ff       	call   f01017e9 <page_insert>
	assert(pp1->pp_ref == 1);
f010333f:	83 c4 20             	add    $0x20,%esp
f0103342:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103347:	0f 85 d3 01 00 00    	jne    f0103520 <mem_init+0x1cb1>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010334d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103354:	01 01 01 
f0103357:	0f 85 e5 01 00 00    	jne    f0103542 <mem_init+0x1cd3>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010335d:	6a 02                	push   $0x2
f010335f:	68 00 10 00 00       	push   $0x1000
f0103364:	57                   	push   %edi
f0103365:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103368:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f010336e:	ff 30                	pushl  (%eax)
f0103370:	e8 74 e4 ff ff       	call   f01017e9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103375:	83 c4 10             	add    $0x10,%esp
f0103378:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010337f:	02 02 02 
f0103382:	0f 85 dc 01 00 00    	jne    f0103564 <mem_init+0x1cf5>
	assert(pp2->pp_ref == 1);
f0103388:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010338d:	0f 85 f3 01 00 00    	jne    f0103586 <mem_init+0x1d17>
	assert(pp1->pp_ref == 0);
f0103393:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103396:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010339b:	0f 85 07 02 00 00    	jne    f01035a8 <mem_init+0x1d39>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01033a1:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01033a8:	03 03 03 
	return (pp - pages) << PGSHIFT;
f01033ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033ae:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f01033b4:	89 f9                	mov    %edi,%ecx
f01033b6:	2b 08                	sub    (%eax),%ecx
f01033b8:	89 c8                	mov    %ecx,%eax
f01033ba:	c1 f8 03             	sar    $0x3,%eax
f01033bd:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01033c0:	89 c1                	mov    %eax,%ecx
f01033c2:	c1 e9 0c             	shr    $0xc,%ecx
f01033c5:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f01033cb:	3b 0a                	cmp    (%edx),%ecx
f01033cd:	0f 83 f7 01 00 00    	jae    f01035ca <mem_init+0x1d5b>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033d3:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01033da:	03 03 03 
f01033dd:	0f 85 fd 01 00 00    	jne    f01035e0 <mem_init+0x1d71>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01033e3:	83 ec 08             	sub    $0x8,%esp
f01033e6:	68 00 10 00 00       	push   $0x1000
f01033eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033ee:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f01033f4:	ff 30                	pushl  (%eax)
f01033f6:	e8 af e3 ff ff       	call   f01017aa <page_remove>
	assert(pp2->pp_ref == 0);
f01033fb:	83 c4 10             	add    $0x10,%esp
f01033fe:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103403:	0f 85 f9 01 00 00    	jne    f0103602 <mem_init+0x1d93>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103409:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010340c:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0103412:	8b 08                	mov    (%eax),%ecx
f0103414:	8b 11                	mov    (%ecx),%edx
f0103416:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f010341c:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0103422:	89 f7                	mov    %esi,%edi
f0103424:	2b 38                	sub    (%eax),%edi
f0103426:	89 f8                	mov    %edi,%eax
f0103428:	c1 f8 03             	sar    $0x3,%eax
f010342b:	c1 e0 0c             	shl    $0xc,%eax
f010342e:	39 c2                	cmp    %eax,%edx
f0103430:	0f 85 ee 01 00 00    	jne    f0103624 <mem_init+0x1db5>
	kern_pgdir[0] = 0;
f0103436:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010343c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103441:	0f 85 ff 01 00 00    	jne    f0103646 <mem_init+0x1dd7>
	pp0->pp_ref = 0;
f0103447:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f010344d:	83 ec 0c             	sub    $0xc,%esp
f0103450:	56                   	push   %esi
f0103451:	e8 da e0 ff ff       	call   f0101530 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103456:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103459:	8d 83 90 8c f7 ff    	lea    -0x87370(%ebx),%eax
f010345f:	89 04 24             	mov    %eax,(%esp)
f0103462:	e8 0b 0b 00 00       	call   f0103f72 <cprintf>
}
f0103467:	83 c4 10             	add    $0x10,%esp
f010346a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010346d:	5b                   	pop    %ebx
f010346e:	5e                   	pop    %esi
f010346f:	5f                   	pop    %edi
f0103470:	5d                   	pop    %ebp
f0103471:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103472:	50                   	push   %eax
f0103473:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103476:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f010347c:	50                   	push   %eax
f010347d:	68 f4 00 00 00       	push   $0xf4
f0103482:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103488:	50                   	push   %eax
f0103489:	e8 23 cc ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010348e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103491:	8d 83 72 82 f7 ff    	lea    -0x87d8e(%ebx),%eax
f0103497:	50                   	push   %eax
f0103498:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f010349e:	50                   	push   %eax
f010349f:	68 df 03 00 00       	push   $0x3df
f01034a4:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01034aa:	50                   	push   %eax
f01034ab:	e8 01 cc ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01034b0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034b3:	8d 83 88 82 f7 ff    	lea    -0x87d78(%ebx),%eax
f01034b9:	50                   	push   %eax
f01034ba:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01034c0:	50                   	push   %eax
f01034c1:	68 e0 03 00 00       	push   $0x3e0
f01034c6:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01034cc:	50                   	push   %eax
f01034cd:	e8 df cb ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01034d2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01034d5:	8d 83 9e 82 f7 ff    	lea    -0x87d62(%ebx),%eax
f01034db:	50                   	push   %eax
f01034dc:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01034e2:	50                   	push   %eax
f01034e3:	68 e1 03 00 00       	push   $0x3e1
f01034e8:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01034ee:	50                   	push   %eax
f01034ef:	e8 bd cb ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01034f4:	50                   	push   %eax
f01034f5:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f01034fb:	50                   	push   %eax
f01034fc:	6a 56                	push   $0x56
f01034fe:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0103504:	50                   	push   %eax
f0103505:	e8 a7 cb ff ff       	call   f01000b1 <_panic>
f010350a:	50                   	push   %eax
f010350b:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0103511:	50                   	push   %eax
f0103512:	6a 56                	push   $0x56
f0103514:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f010351a:	50                   	push   %eax
f010351b:	e8 91 cb ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0103520:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103523:	8d 83 6f 83 f7 ff    	lea    -0x87c91(%ebx),%eax
f0103529:	50                   	push   %eax
f010352a:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103530:	50                   	push   %eax
f0103531:	68 e6 03 00 00       	push   $0x3e6
f0103536:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010353c:	50                   	push   %eax
f010353d:	e8 6f cb ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103542:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103545:	8d 83 1c 8c f7 ff    	lea    -0x873e4(%ebx),%eax
f010354b:	50                   	push   %eax
f010354c:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103552:	50                   	push   %eax
f0103553:	68 e7 03 00 00       	push   $0x3e7
f0103558:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010355e:	50                   	push   %eax
f010355f:	e8 4d cb ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103564:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103567:	8d 83 40 8c f7 ff    	lea    -0x873c0(%ebx),%eax
f010356d:	50                   	push   %eax
f010356e:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103574:	50                   	push   %eax
f0103575:	68 e9 03 00 00       	push   $0x3e9
f010357a:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103580:	50                   	push   %eax
f0103581:	e8 2b cb ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103586:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103589:	8d 83 91 83 f7 ff    	lea    -0x87c6f(%ebx),%eax
f010358f:	50                   	push   %eax
f0103590:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103596:	50                   	push   %eax
f0103597:	68 ea 03 00 00       	push   $0x3ea
f010359c:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01035a2:	50                   	push   %eax
f01035a3:	e8 09 cb ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f01035a8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01035ab:	8d 83 fb 83 f7 ff    	lea    -0x87c05(%ebx),%eax
f01035b1:	50                   	push   %eax
f01035b2:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01035b8:	50                   	push   %eax
f01035b9:	68 eb 03 00 00       	push   $0x3eb
f01035be:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01035c4:	50                   	push   %eax
f01035c5:	e8 e7 ca ff ff       	call   f01000b1 <_panic>
f01035ca:	50                   	push   %eax
f01035cb:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f01035d1:	50                   	push   %eax
f01035d2:	6a 56                	push   $0x56
f01035d4:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f01035da:	50                   	push   %eax
f01035db:	e8 d1 ca ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01035e0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01035e3:	8d 83 64 8c f7 ff    	lea    -0x8739c(%ebx),%eax
f01035e9:	50                   	push   %eax
f01035ea:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01035f0:	50                   	push   %eax
f01035f1:	68 ed 03 00 00       	push   $0x3ed
f01035f6:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f01035fc:	50                   	push   %eax
f01035fd:	e8 af ca ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0103602:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103605:	8d 83 c9 83 f7 ff    	lea    -0x87c37(%ebx),%eax
f010360b:	50                   	push   %eax
f010360c:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103612:	50                   	push   %eax
f0103613:	68 ef 03 00 00       	push   $0x3ef
f0103618:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f010361e:	50                   	push   %eax
f010361f:	e8 8d ca ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103624:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103627:	8d 83 74 87 f7 ff    	lea    -0x8788c(%ebx),%eax
f010362d:	50                   	push   %eax
f010362e:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103634:	50                   	push   %eax
f0103635:	68 f2 03 00 00       	push   $0x3f2
f010363a:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103640:	50                   	push   %eax
f0103641:	e8 6b ca ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103646:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103649:	8d 83 80 83 f7 ff    	lea    -0x87c80(%ebx),%eax
f010364f:	50                   	push   %eax
f0103650:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0103656:	50                   	push   %eax
f0103657:	68 f4 03 00 00       	push   $0x3f4
f010365c:	8d 83 a1 81 f7 ff    	lea    -0x87e5f(%ebx),%eax
f0103662:	50                   	push   %eax
f0103663:	e8 49 ca ff ff       	call   f01000b1 <_panic>

f0103668 <tlb_invalidate>:
{
f0103668:	55                   	push   %ebp
f0103669:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010366b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010366e:	0f 01 38             	invlpg (%eax)
}
f0103671:	5d                   	pop    %ebp
f0103672:	c3                   	ret    

f0103673 <user_mem_check>:
{
f0103673:	55                   	push   %ebp
f0103674:	89 e5                	mov    %esp,%ebp
f0103676:	57                   	push   %edi
f0103677:	56                   	push   %esi
f0103678:	53                   	push   %ebx
f0103679:	83 ec 1c             	sub    $0x1c,%esp
f010367c:	e8 88 d0 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103681:	05 9f a9 08 00       	add    $0x8a99f,%eax
f0103686:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uintptr_t beg = ROUNDDOWN((uint32_t)(va), PGSIZE);
f0103689:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010368c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t fin = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0103692:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103695:	03 7d 10             	add    0x10(%ebp),%edi
f0103698:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f010369e:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
		if (p == NULL || (*p & (perm | PTE_P)) != (perm | PTE_P) || beg >= ULIM){
f01036a4:	8b 75 14             	mov    0x14(%ebp),%esi
f01036a7:	83 ce 01             	or     $0x1,%esi
	for (; beg < fin; beg += PGSIZE){
f01036aa:	39 fb                	cmp    %edi,%ebx
f01036ac:	73 4d                	jae    f01036fb <user_mem_check+0x88>
		pte_t * p = pgdir_walk(env -> env_pgdir, (void *)beg, 0);
f01036ae:	83 ec 04             	sub    $0x4,%esp
f01036b1:	6a 00                	push   $0x0
f01036b3:	53                   	push   %ebx
f01036b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b7:	ff 70 5c             	pushl  0x5c(%eax)
f01036ba:	e8 04 df ff ff       	call   f01015c3 <pgdir_walk>
		if (p == NULL || (*p & (perm | PTE_P)) != (perm | PTE_P) || beg >= ULIM){
f01036bf:	83 c4 10             	add    $0x10,%esp
f01036c2:	85 c0                	test   %eax,%eax
f01036c4:	74 18                	je     f01036de <user_mem_check+0x6b>
f01036c6:	89 f2                	mov    %esi,%edx
f01036c8:	23 10                	and    (%eax),%edx
f01036ca:	39 f2                	cmp    %esi,%edx
f01036cc:	75 10                	jne    f01036de <user_mem_check+0x6b>
f01036ce:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01036d4:	77 08                	ja     f01036de <user_mem_check+0x6b>
	for (; beg < fin; beg += PGSIZE){
f01036d6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01036dc:	eb cc                	jmp    f01036aa <user_mem_check+0x37>
			user_mem_check_addr = (beg < (uintptr_t)va ? (uintptr_t)va : beg);
f01036de:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f01036e1:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f01036e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01036e8:	89 98 5c 23 00 00    	mov    %ebx,0x235c(%eax)
			return -E_FAULT;
f01036ee:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f01036f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01036f6:	5b                   	pop    %ebx
f01036f7:	5e                   	pop    %esi
f01036f8:	5f                   	pop    %edi
f01036f9:	5d                   	pop    %ebp
f01036fa:	c3                   	ret    
	return 0;
f01036fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103700:	eb f1                	jmp    f01036f3 <user_mem_check+0x80>

f0103702 <user_mem_assert>:
{
f0103702:	55                   	push   %ebp
f0103703:	89 e5                	mov    %esp,%ebp
f0103705:	56                   	push   %esi
f0103706:	53                   	push   %ebx
f0103707:	e8 5b ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010370c:	81 c3 14 a9 08 00    	add    $0x8a914,%ebx
f0103712:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103715:	8b 45 14             	mov    0x14(%ebp),%eax
f0103718:	83 c8 04             	or     $0x4,%eax
f010371b:	50                   	push   %eax
f010371c:	ff 75 10             	pushl  0x10(%ebp)
f010371f:	ff 75 0c             	pushl  0xc(%ebp)
f0103722:	56                   	push   %esi
f0103723:	e8 4b ff ff ff       	call   f0103673 <user_mem_check>
f0103728:	83 c4 10             	add    $0x10,%esp
f010372b:	85 c0                	test   %eax,%eax
f010372d:	78 07                	js     f0103736 <user_mem_assert+0x34>
}
f010372f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103732:	5b                   	pop    %ebx
f0103733:	5e                   	pop    %esi
f0103734:	5d                   	pop    %ebp
f0103735:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103736:	83 ec 04             	sub    $0x4,%esp
f0103739:	ff b3 5c 23 00 00    	pushl  0x235c(%ebx)
f010373f:	ff 76 48             	pushl  0x48(%esi)
f0103742:	8d 83 bc 8c f7 ff    	lea    -0x87344(%ebx),%eax
f0103748:	50                   	push   %eax
f0103749:	e8 24 08 00 00       	call   f0103f72 <cprintf>
		env_destroy(env);	// may not return
f010374e:	89 34 24             	mov    %esi,(%esp)
f0103751:	e8 b2 06 00 00       	call   f0103e08 <env_destroy>
f0103756:	83 c4 10             	add    $0x10,%esp
}
f0103759:	eb d4                	jmp    f010372f <user_mem_assert+0x2d>

f010375b <__x86.get_pc_thunk.dx>:
f010375b:	8b 14 24             	mov    (%esp),%edx
f010375e:	c3                   	ret    

f010375f <__x86.get_pc_thunk.cx>:
f010375f:	8b 0c 24             	mov    (%esp),%ecx
f0103762:	c3                   	ret    

f0103763 <__x86.get_pc_thunk.si>:
f0103763:	8b 34 24             	mov    (%esp),%esi
f0103766:	c3                   	ret    

f0103767 <__x86.get_pc_thunk.di>:
f0103767:	8b 3c 24             	mov    (%esp),%edi
f010376a:	c3                   	ret    

f010376b <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010376b:	55                   	push   %ebp
f010376c:	89 e5                	mov    %esp,%ebp
f010376e:	57                   	push   %edi
f010376f:	56                   	push   %esi
f0103770:	53                   	push   %ebx
f0103771:	83 ec 1c             	sub    $0x1c,%esp
f0103774:	e8 ee c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103779:	81 c3 a7 a8 08 00    	add    $0x8a8a7,%ebx
f010377f:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* beg = (void*)ROUNDDOWN((uint32_t)va, PGSIZE);
f0103781:	89 d6                	mov    %edx,%esi
f0103783:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	void* fin = (void*)ROUNDUP((uint32_t)(va + len), PGSIZE);
f0103789:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0103790:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103795:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (;beg < fin;beg += PGSIZE){
f0103798:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010379b:	73 62                	jae    f01037ff <region_alloc+0x94>
		struct PageInfo* page;
		if (!(page = page_alloc(ALLOC_ZERO)))
f010379d:	83 ec 0c             	sub    $0xc,%esp
f01037a0:	6a 01                	push   $0x1
f01037a2:	e8 01 dd ff ff       	call   f01014a8 <page_alloc>
f01037a7:	83 c4 10             	add    $0x10,%esp
f01037aa:	85 c0                	test   %eax,%eax
f01037ac:	74 1b                	je     f01037c9 <region_alloc+0x5e>
			panic("allocation failed");
		if (page_insert(e -> env_pgdir, page, (void*)beg, PTE_U | PTE_W))
f01037ae:	6a 06                	push   $0x6
f01037b0:	56                   	push   %esi
f01037b1:	50                   	push   %eax
f01037b2:	ff 77 5c             	pushl  0x5c(%edi)
f01037b5:	e8 2f e0 ff ff       	call   f01017e9 <page_insert>
f01037ba:	83 c4 10             	add    $0x10,%esp
f01037bd:	85 c0                	test   %eax,%eax
f01037bf:	75 23                	jne    f01037e4 <region_alloc+0x79>
	for (;beg < fin;beg += PGSIZE){
f01037c1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01037c7:	eb cf                	jmp    f0103798 <region_alloc+0x2d>
			panic("allocation failed");
f01037c9:	83 ec 04             	sub    $0x4,%esp
f01037cc:	8d 83 f1 8c f7 ff    	lea    -0x8730f(%ebx),%eax
f01037d2:	50                   	push   %eax
f01037d3:	68 1d 01 00 00       	push   $0x11d
f01037d8:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f01037de:	50                   	push   %eax
f01037df:	e8 cd c8 ff ff       	call   f01000b1 <_panic>
			panic("mapping failed");
f01037e4:	83 ec 04             	sub    $0x4,%esp
f01037e7:	8d 83 0e 8d f7 ff    	lea    -0x872f2(%ebx),%eax
f01037ed:	50                   	push   %eax
f01037ee:	68 1f 01 00 00       	push   $0x11f
f01037f3:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f01037f9:	50                   	push   %eax
f01037fa:	e8 b2 c8 ff ff       	call   f01000b1 <_panic>
	}
}
f01037ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103802:	5b                   	pop    %ebx
f0103803:	5e                   	pop    %esi
f0103804:	5f                   	pop    %edi
f0103805:	5d                   	pop    %ebp
f0103806:	c3                   	ret    

f0103807 <envid2env>:
{
f0103807:	55                   	push   %ebp
f0103808:	89 e5                	mov    %esp,%ebp
f010380a:	53                   	push   %ebx
f010380b:	e8 4f ff ff ff       	call   f010375f <__x86.get_pc_thunk.cx>
f0103810:	81 c1 10 a8 08 00    	add    $0x8a810,%ecx
f0103816:	8b 55 08             	mov    0x8(%ebp),%edx
f0103819:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f010381c:	85 d2                	test   %edx,%edx
f010381e:	74 41                	je     f0103861 <envid2env+0x5a>
	e = &envs[ENVX(envid)];
f0103820:	89 d0                	mov    %edx,%eax
f0103822:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103827:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010382a:	c1 e0 05             	shl    $0x5,%eax
f010382d:	03 81 68 23 00 00    	add    0x2368(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103833:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0103837:	74 3a                	je     f0103873 <envid2env+0x6c>
f0103839:	39 50 48             	cmp    %edx,0x48(%eax)
f010383c:	75 35                	jne    f0103873 <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010383e:	84 db                	test   %bl,%bl
f0103840:	74 12                	je     f0103854 <envid2env+0x4d>
f0103842:	8b 91 64 23 00 00    	mov    0x2364(%ecx),%edx
f0103848:	39 c2                	cmp    %eax,%edx
f010384a:	74 08                	je     f0103854 <envid2env+0x4d>
f010384c:	8b 5a 48             	mov    0x48(%edx),%ebx
f010384f:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f0103852:	75 2f                	jne    f0103883 <envid2env+0x7c>
	*env_store = e;
f0103854:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103857:	89 03                	mov    %eax,(%ebx)
	return 0;
f0103859:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010385e:	5b                   	pop    %ebx
f010385f:	5d                   	pop    %ebp
f0103860:	c3                   	ret    
		*env_store = curenv;
f0103861:	8b 81 64 23 00 00    	mov    0x2364(%ecx),%eax
f0103867:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010386a:	89 01                	mov    %eax,(%ecx)
		return 0;
f010386c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103871:	eb eb                	jmp    f010385e <envid2env+0x57>
		*env_store = 0;
f0103873:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103876:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010387c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103881:	eb db                	jmp    f010385e <envid2env+0x57>
		*env_store = 0;
f0103883:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103886:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010388c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103891:	eb cb                	jmp    f010385e <envid2env+0x57>

f0103893 <env_init_percpu>:
{
f0103893:	55                   	push   %ebp
f0103894:	89 e5                	mov    %esp,%ebp
f0103896:	e8 6e ce ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010389b:	05 85 a7 08 00       	add    $0x8a785,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f01038a0:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f01038a6:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01038a9:	b8 23 00 00 00       	mov    $0x23,%eax
f01038ae:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01038b0:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01038b2:	b8 10 00 00 00       	mov    $0x10,%eax
f01038b7:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01038b9:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01038bb:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01038bd:	ea c4 38 10 f0 08 00 	ljmp   $0x8,$0xf01038c4
	asm volatile("lldt %0" : : "r" (sel));
f01038c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01038c9:	0f 00 d0             	lldt   %ax
}
f01038cc:	5d                   	pop    %ebp
f01038cd:	c3                   	ret    

f01038ce <env_init>:
{
f01038ce:	55                   	push   %ebp
f01038cf:	89 e5                	mov    %esp,%ebp
f01038d1:	57                   	push   %edi
f01038d2:	56                   	push   %esi
f01038d3:	53                   	push   %ebx
f01038d4:	e8 8e fe ff ff       	call   f0103767 <__x86.get_pc_thunk.di>
f01038d9:	81 c7 47 a7 08 00    	add    $0x8a747,%edi
		envs[i].env_link = env_free_list;
f01038df:	8b b7 68 23 00 00    	mov    0x2368(%edi),%esi
f01038e5:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01038eb:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01038ee:	ba 00 00 00 00       	mov    $0x0,%edx
f01038f3:	89 c1                	mov    %eax,%ecx
f01038f5:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f01038f8:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f01038ff:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f0103902:	89 ca                	mov    %ecx,%edx
	for (int i = NENV - 1; i >= 0; i --){
f0103904:	39 d8                	cmp    %ebx,%eax
f0103906:	75 eb                	jne    f01038f3 <env_init+0x25>
f0103908:	89 b7 6c 23 00 00    	mov    %esi,0x236c(%edi)
	env_init_percpu();
f010390e:	e8 80 ff ff ff       	call   f0103893 <env_init_percpu>
}
f0103913:	5b                   	pop    %ebx
f0103914:	5e                   	pop    %esi
f0103915:	5f                   	pop    %edi
f0103916:	5d                   	pop    %ebp
f0103917:	c3                   	ret    

f0103918 <env_alloc>:
{
f0103918:	55                   	push   %ebp
f0103919:	89 e5                	mov    %esp,%ebp
f010391b:	57                   	push   %edi
f010391c:	56                   	push   %esi
f010391d:	53                   	push   %ebx
f010391e:	83 ec 0c             	sub    $0xc,%esp
f0103921:	e8 41 c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103926:	81 c3 fa a6 08 00    	add    $0x8a6fa,%ebx
	if (!(e = env_free_list))
f010392c:	8b b3 6c 23 00 00    	mov    0x236c(%ebx),%esi
f0103932:	85 f6                	test   %esi,%esi
f0103934:	0f 84 68 01 00 00    	je     f0103aa2 <env_alloc+0x18a>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010393a:	83 ec 0c             	sub    $0xc,%esp
f010393d:	6a 01                	push   $0x1
f010393f:	e8 64 db ff ff       	call   f01014a8 <page_alloc>
f0103944:	83 c4 10             	add    $0x10,%esp
f0103947:	85 c0                	test   %eax,%eax
f0103949:	0f 84 5a 01 00 00    	je     f0103aa9 <env_alloc+0x191>
	return (pp - pages) << PGSHIFT;
f010394f:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0103955:	89 c7                	mov    %eax,%edi
f0103957:	2b 3a                	sub    (%edx),%edi
f0103959:	89 fa                	mov    %edi,%edx
f010395b:	c1 fa 03             	sar    $0x3,%edx
f010395e:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0103961:	89 d7                	mov    %edx,%edi
f0103963:	c1 ef 0c             	shr    $0xc,%edi
f0103966:	c7 c1 48 10 19 f0    	mov    $0xf0191048,%ecx
f010396c:	3b 39                	cmp    (%ecx),%edi
f010396e:	0f 83 ff 00 00 00    	jae    f0103a73 <env_alloc+0x15b>
	return (void *)(pa + KERNBASE);
f0103974:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010397a:	89 56 5c             	mov    %edx,0x5c(%esi)
	p -> pp_ref ++;
f010397d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e -> env_pgdir, kern_pgdir, PGSIZE); 
f0103982:	83 ec 04             	sub    $0x4,%esp
f0103985:	68 00 10 00 00       	push   $0x1000
f010398a:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0103990:	ff 30                	pushl  (%eax)
f0103992:	ff 76 5c             	pushl  0x5c(%esi)
f0103995:	e8 1f 1d 00 00       	call   f01056b9 <memcpy>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010399a:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010399d:	83 c4 10             	add    $0x10,%esp
f01039a0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01039a5:	0f 86 de 00 00 00    	jbe    f0103a89 <env_alloc+0x171>
	return (physaddr_t)kva - KERNBASE;
f01039ab:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01039b1:	83 ca 05             	or     $0x5,%edx
f01039b4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01039ba:	8b 46 48             	mov    0x48(%esi),%eax
f01039bd:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01039c2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01039c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01039cc:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01039cf:	89 f2                	mov    %esi,%edx
f01039d1:	2b 93 68 23 00 00    	sub    0x2368(%ebx),%edx
f01039d7:	c1 fa 05             	sar    $0x5,%edx
f01039da:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01039e0:	09 d0                	or     %edx,%eax
f01039e2:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f01039e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039e8:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01039eb:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01039f2:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01039f9:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103a00:	83 ec 04             	sub    $0x4,%esp
f0103a03:	6a 44                	push   $0x44
f0103a05:	6a 00                	push   $0x0
f0103a07:	56                   	push   %esi
f0103a08:	e8 f7 1b 00 00       	call   f0105604 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103a0d:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f0103a13:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103a19:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103a1f:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103a26:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f0103a2c:	8b 46 44             	mov    0x44(%esi),%eax
f0103a2f:	89 83 6c 23 00 00    	mov    %eax,0x236c(%ebx)
	*newenv_store = e;
f0103a35:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a38:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103a3a:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103a3d:	8b 83 64 23 00 00    	mov    0x2364(%ebx),%eax
f0103a43:	83 c4 10             	add    $0x10,%esp
f0103a46:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a4b:	85 c0                	test   %eax,%eax
f0103a4d:	74 03                	je     f0103a52 <env_alloc+0x13a>
f0103a4f:	8b 50 48             	mov    0x48(%eax),%edx
f0103a52:	83 ec 04             	sub    $0x4,%esp
f0103a55:	51                   	push   %ecx
f0103a56:	52                   	push   %edx
f0103a57:	8d 83 1d 8d f7 ff    	lea    -0x872e3(%ebx),%eax
f0103a5d:	50                   	push   %eax
f0103a5e:	e8 0f 05 00 00       	call   f0103f72 <cprintf>
	return 0;
f0103a63:	83 c4 10             	add    $0x10,%esp
f0103a66:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a6e:	5b                   	pop    %ebx
f0103a6f:	5e                   	pop    %esi
f0103a70:	5f                   	pop    %edi
f0103a71:	5d                   	pop    %ebp
f0103a72:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103a73:	52                   	push   %edx
f0103a74:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0103a7a:	50                   	push   %eax
f0103a7b:	6a 56                	push   $0x56
f0103a7d:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0103a83:	50                   	push   %eax
f0103a84:	e8 28 c6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a89:	50                   	push   %eax
f0103a8a:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103a90:	50                   	push   %eax
f0103a91:	68 c3 00 00 00       	push   $0xc3
f0103a96:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103a9c:	50                   	push   %eax
f0103a9d:	e8 0f c6 ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f0103aa2:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103aa7:	eb c2                	jmp    f0103a6b <env_alloc+0x153>
		return -E_NO_MEM;
f0103aa9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103aae:	eb bb                	jmp    f0103a6b <env_alloc+0x153>

f0103ab0 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103ab0:	55                   	push   %ebp
f0103ab1:	89 e5                	mov    %esp,%ebp
f0103ab3:	57                   	push   %edi
f0103ab4:	56                   	push   %esi
f0103ab5:	53                   	push   %ebx
f0103ab6:	83 ec 34             	sub    $0x34,%esp
f0103ab9:	e8 a9 c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103abe:	81 c3 62 a5 08 00    	add    $0x8a562,%ebx
	// LAB 3: Your code here.
	struct Env* e;
	int result = env_alloc(&e, 0);
f0103ac4:	6a 00                	push   $0x0
f0103ac6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103ac9:	50                   	push   %eax
f0103aca:	e8 49 fe ff ff       	call   f0103918 <env_alloc>
f0103acf:	89 c7                	mov    %eax,%edi
	if (result != 0)
f0103ad1:	83 c4 10             	add    $0x10,%esp
f0103ad4:	85 c0                	test   %eax,%eax
f0103ad6:	75 30                	jne    f0103b08 <env_create+0x58>
		panic("error while creating environment: %e", result);
	load_icode(e, binary);
f0103ad8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103adb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (ElfHeader -> e_magic != ELF_MAGIC)
f0103ade:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ae1:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f0103ae7:	75 38                	jne    f0103b21 <env_create+0x71>
	lcr3(PADDR(e -> env_pgdir));
f0103ae9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103aec:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103aef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103af4:	76 46                	jbe    f0103b3c <env_create+0x8c>
	return (physaddr_t)kva - KERNBASE;
f0103af6:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103afb:	0f 22 d8             	mov    %eax,%cr3
f0103afe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b01:	89 c6                	mov    %eax,%esi
f0103b03:	03 70 1c             	add    0x1c(%eax),%esi
f0103b06:	eb 53                	jmp    f0103b5b <env_create+0xab>
		panic("error while creating environment: %e", result);
f0103b08:	50                   	push   %eax
f0103b09:	8d 83 54 8d f7 ff    	lea    -0x872ac(%ebx),%eax
f0103b0f:	50                   	push   %eax
f0103b10:	68 80 01 00 00       	push   $0x180
f0103b15:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103b1b:	50                   	push   %eax
f0103b1c:	e8 90 c5 ff ff       	call   f01000b1 <_panic>
		panic("Wrong magic number in elf header");
f0103b21:	83 ec 04             	sub    $0x4,%esp
f0103b24:	8d 83 7c 8d f7 ff    	lea    -0x87284(%ebx),%eax
f0103b2a:	50                   	push   %eax
f0103b2b:	68 5c 01 00 00       	push   $0x15c
f0103b30:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103b36:	50                   	push   %eax
f0103b37:	e8 75 c5 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b3c:	50                   	push   %eax
f0103b3d:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103b43:	50                   	push   %eax
f0103b44:	68 5e 01 00 00       	push   $0x15e
f0103b49:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103b4f:	50                   	push   %eax
f0103b50:	e8 5c c5 ff ff       	call   f01000b1 <_panic>
	for (int i = 0; i < ElfHeader -> e_phnum; i++)
f0103b55:	83 c7 01             	add    $0x1,%edi
f0103b58:	83 c6 20             	add    $0x20,%esi
f0103b5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b5e:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
f0103b62:	39 c7                	cmp    %eax,%edi
f0103b64:	7d 3d                	jge    f0103ba3 <env_create+0xf3>
		if (ProgHeader[i].p_type == ELF_PROG_LOAD){
f0103b66:	83 3e 01             	cmpl   $0x1,(%esi)
f0103b69:	75 ea                	jne    f0103b55 <env_create+0xa5>
			region_alloc(e, (void*)ph -> p_va, ph ->p_memsz);
f0103b6b:	8b 4e 14             	mov    0x14(%esi),%ecx
f0103b6e:	8b 56 08             	mov    0x8(%esi),%edx
f0103b71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b74:	e8 f2 fb ff ff       	call   f010376b <region_alloc>
			memset((void*) ph -> p_va, 0, ph -> p_memsz);
f0103b79:	83 ec 04             	sub    $0x4,%esp
f0103b7c:	ff 76 14             	pushl  0x14(%esi)
f0103b7f:	6a 00                	push   $0x0
f0103b81:	ff 76 08             	pushl  0x8(%esi)
f0103b84:	e8 7b 1a 00 00       	call   f0105604 <memset>
			memcpy((void*) ph -> p_va, (void*) binary + ph -> p_offset, ph -> p_filesz);
f0103b89:	83 c4 0c             	add    $0xc,%esp
f0103b8c:	ff 76 10             	pushl  0x10(%esi)
f0103b8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b92:	03 46 04             	add    0x4(%esi),%eax
f0103b95:	50                   	push   %eax
f0103b96:	ff 76 08             	pushl  0x8(%esi)
f0103b99:	e8 1b 1b 00 00       	call   f01056b9 <memcpy>
f0103b9e:	83 c4 10             	add    $0x10,%esp
f0103ba1:	eb b2                	jmp    f0103b55 <env_create+0xa5>
	lcr3(PADDR(kern_pgdir));
f0103ba3:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0103ba9:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103bab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103bb0:	76 36                	jbe    f0103be8 <env_create+0x138>
	return (physaddr_t)kva - KERNBASE;
f0103bb2:	05 00 00 00 10       	add    $0x10000000,%eax
f0103bb7:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = ElfHeader -> e_entry;
f0103bba:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bbd:	8b 40 18             	mov    0x18(%eax),%eax
f0103bc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103bc3:	89 43 30             	mov    %eax,0x30(%ebx)
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f0103bc6:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103bcb:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103bd0:	89 d8                	mov    %ebx,%eax
f0103bd2:	e8 94 fb ff ff       	call   f010376b <region_alloc>
	e -> env_type = type;
f0103bd7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103bda:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bdd:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103be0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103be3:	5b                   	pop    %ebx
f0103be4:	5e                   	pop    %esi
f0103be5:	5f                   	pop    %edi
f0103be6:	5d                   	pop    %ebp
f0103be7:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103be8:	50                   	push   %eax
f0103be9:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103bef:	50                   	push   %eax
f0103bf0:	68 68 01 00 00       	push   $0x168
f0103bf5:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103bfb:	50                   	push   %eax
f0103bfc:	e8 b0 c4 ff ff       	call   f01000b1 <_panic>

f0103c01 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103c01:	55                   	push   %ebp
f0103c02:	89 e5                	mov    %esp,%ebp
f0103c04:	57                   	push   %edi
f0103c05:	56                   	push   %esi
f0103c06:	53                   	push   %ebx
f0103c07:	83 ec 2c             	sub    $0x2c,%esp
f0103c0a:	e8 58 c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103c0f:	81 c3 11 a4 08 00    	add    $0x8a411,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103c15:	8b 93 64 23 00 00    	mov    0x2364(%ebx),%edx
f0103c1b:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103c1e:	75 17                	jne    f0103c37 <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103c20:	c7 c0 4c 10 19 f0    	mov    $0xf019104c,%eax
f0103c26:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103c28:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c2d:	76 46                	jbe    f0103c75 <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103c2f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c34:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103c37:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c3a:	8b 48 48             	mov    0x48(%eax),%ecx
f0103c3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c42:	85 d2                	test   %edx,%edx
f0103c44:	74 03                	je     f0103c49 <env_free+0x48>
f0103c46:	8b 42 48             	mov    0x48(%edx),%eax
f0103c49:	83 ec 04             	sub    $0x4,%esp
f0103c4c:	51                   	push   %ecx
f0103c4d:	50                   	push   %eax
f0103c4e:	8d 83 32 8d f7 ff    	lea    -0x872ce(%ebx),%eax
f0103c54:	50                   	push   %eax
f0103c55:	e8 18 03 00 00       	call   f0103f72 <cprintf>
f0103c5a:	83 c4 10             	add    $0x10,%esp
f0103c5d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f0103c64:	c7 c0 48 10 19 f0    	mov    $0xf0191048,%eax
f0103c6a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f0103c6d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103c70:	e9 9f 00 00 00       	jmp    f0103d14 <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c75:	50                   	push   %eax
f0103c76:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103c7c:	50                   	push   %eax
f0103c7d:	68 93 01 00 00       	push   $0x193
f0103c82:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103c88:	50                   	push   %eax
f0103c89:	e8 23 c4 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103c8e:	50                   	push   %eax
f0103c8f:	8d 83 84 84 f7 ff    	lea    -0x87b7c(%ebx),%eax
f0103c95:	50                   	push   %eax
f0103c96:	68 a2 01 00 00       	push   $0x1a2
f0103c9b:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103ca1:	50                   	push   %eax
f0103ca2:	e8 0a c4 ff ff       	call   f01000b1 <_panic>
f0103ca7:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103caa:	39 fe                	cmp    %edi,%esi
f0103cac:	74 24                	je     f0103cd2 <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103cae:	f6 06 01             	testb  $0x1,(%esi)
f0103cb1:	74 f4                	je     f0103ca7 <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103cb3:	83 ec 08             	sub    $0x8,%esp
f0103cb6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cb9:	01 f0                	add    %esi,%eax
f0103cbb:	c1 e0 0a             	shl    $0xa,%eax
f0103cbe:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103cc1:	50                   	push   %eax
f0103cc2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc5:	ff 70 5c             	pushl  0x5c(%eax)
f0103cc8:	e8 dd da ff ff       	call   f01017aa <page_remove>
f0103ccd:	83 c4 10             	add    $0x10,%esp
f0103cd0:	eb d5                	jmp    f0103ca7 <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103cd2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cd5:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103cd8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103cdb:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103ce2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103ce5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ce8:	3b 10                	cmp    (%eax),%edx
f0103cea:	73 6f                	jae    f0103d5b <env_free+0x15a>
		page_decref(pa2page(pa));
f0103cec:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103cef:	c7 c0 50 10 19 f0    	mov    $0xf0191050,%eax
f0103cf5:	8b 00                	mov    (%eax),%eax
f0103cf7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103cfa:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103cfd:	50                   	push   %eax
f0103cfe:	e8 97 d8 ff ff       	call   f010159a <page_decref>
f0103d03:	83 c4 10             	add    $0x10,%esp
f0103d06:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f0103d0a:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103d0d:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103d12:	74 5f                	je     f0103d73 <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103d14:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d17:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103d1a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d1d:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103d20:	a8 01                	test   $0x1,%al
f0103d22:	74 e2                	je     f0103d06 <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103d24:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0103d29:	89 c2                	mov    %eax,%edx
f0103d2b:	c1 ea 0c             	shr    $0xc,%edx
f0103d2e:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103d31:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103d34:	39 11                	cmp    %edx,(%ecx)
f0103d36:	0f 86 52 ff ff ff    	jbe    f0103c8e <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f0103d3c:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103d42:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d45:	c1 e2 14             	shl    $0x14,%edx
f0103d48:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103d4b:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103d51:	f7 d8                	neg    %eax
f0103d53:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d56:	e9 53 ff ff ff       	jmp    f0103cae <env_free+0xad>
		panic("pa2page called with invalid pa");
f0103d5b:	83 ec 04             	sub    $0x4,%esp
f0103d5e:	8d 83 1c 86 f7 ff    	lea    -0x879e4(%ebx),%eax
f0103d64:	50                   	push   %eax
f0103d65:	6a 4f                	push   $0x4f
f0103d67:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0103d6d:	50                   	push   %eax
f0103d6e:	e8 3e c3 ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103d73:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d76:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103d79:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d7e:	76 57                	jbe    f0103dd7 <env_free+0x1d6>
	e->env_pgdir = 0;
f0103d80:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d83:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103d8a:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103d8f:	c1 e8 0c             	shr    $0xc,%eax
f0103d92:	c7 c2 48 10 19 f0    	mov    $0xf0191048,%edx
f0103d98:	3b 02                	cmp    (%edx),%eax
f0103d9a:	73 54                	jae    f0103df0 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103d9c:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103d9f:	c7 c2 50 10 19 f0    	mov    $0xf0191050,%edx
f0103da5:	8b 12                	mov    (%edx),%edx
f0103da7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103daa:	50                   	push   %eax
f0103dab:	e8 ea d7 ff ff       	call   f010159a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103db0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103db3:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103dba:	8b 83 6c 23 00 00    	mov    0x236c(%ebx),%eax
f0103dc0:	8b 55 08             	mov    0x8(%ebp),%edx
f0103dc3:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103dc6:	89 93 6c 23 00 00    	mov    %edx,0x236c(%ebx)
}
f0103dcc:	83 c4 10             	add    $0x10,%esp
f0103dcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103dd2:	5b                   	pop    %ebx
f0103dd3:	5e                   	pop    %esi
f0103dd4:	5f                   	pop    %edi
f0103dd5:	5d                   	pop    %ebp
f0103dd6:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103dd7:	50                   	push   %eax
f0103dd8:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103dde:	50                   	push   %eax
f0103ddf:	68 b0 01 00 00       	push   $0x1b0
f0103de4:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103dea:	50                   	push   %eax
f0103deb:	e8 c1 c2 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f0103df0:	83 ec 04             	sub    $0x4,%esp
f0103df3:	8d 83 1c 86 f7 ff    	lea    -0x879e4(%ebx),%eax
f0103df9:	50                   	push   %eax
f0103dfa:	6a 4f                	push   $0x4f
f0103dfc:	8d 83 ad 81 f7 ff    	lea    -0x87e53(%ebx),%eax
f0103e02:	50                   	push   %eax
f0103e03:	e8 a9 c2 ff ff       	call   f01000b1 <_panic>

f0103e08 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103e08:	55                   	push   %ebp
f0103e09:	89 e5                	mov    %esp,%ebp
f0103e0b:	53                   	push   %ebx
f0103e0c:	83 ec 10             	sub    $0x10,%esp
f0103e0f:	e8 53 c3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103e14:	81 c3 0c a2 08 00    	add    $0x8a20c,%ebx
	env_free(e);
f0103e1a:	ff 75 08             	pushl  0x8(%ebp)
f0103e1d:	e8 df fd ff ff       	call   f0103c01 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103e22:	8d 83 a0 8d f7 ff    	lea    -0x87260(%ebx),%eax
f0103e28:	89 04 24             	mov    %eax,(%esp)
f0103e2b:	e8 42 01 00 00       	call   f0103f72 <cprintf>
f0103e30:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103e33:	83 ec 0c             	sub    $0xc,%esp
f0103e36:	6a 00                	push   $0x0
f0103e38:	e8 4e cf ff ff       	call   f0100d8b <monitor>
f0103e3d:	83 c4 10             	add    $0x10,%esp
f0103e40:	eb f1                	jmp    f0103e33 <env_destroy+0x2b>

f0103e42 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103e42:	55                   	push   %ebp
f0103e43:	89 e5                	mov    %esp,%ebp
f0103e45:	53                   	push   %ebx
f0103e46:	83 ec 08             	sub    $0x8,%esp
f0103e49:	e8 19 c3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103e4e:	81 c3 d2 a1 08 00    	add    $0x8a1d2,%ebx
	asm volatile(
f0103e54:	8b 65 08             	mov    0x8(%ebp),%esp
f0103e57:	61                   	popa   
f0103e58:	07                   	pop    %es
f0103e59:	1f                   	pop    %ds
f0103e5a:	83 c4 08             	add    $0x8,%esp
f0103e5d:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103e5e:	8d 83 48 8d f7 ff    	lea    -0x872b8(%ebx),%eax
f0103e64:	50                   	push   %eax
f0103e65:	68 d9 01 00 00       	push   $0x1d9
f0103e6a:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103e70:	50                   	push   %eax
f0103e71:	e8 3b c2 ff ff       	call   f01000b1 <_panic>

f0103e76 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103e76:	55                   	push   %ebp
f0103e77:	89 e5                	mov    %esp,%ebp
f0103e79:	53                   	push   %ebx
f0103e7a:	83 ec 04             	sub    $0x4,%esp
f0103e7d:	e8 e5 c2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103e82:	81 c3 9e a1 08 00    	add    $0x8a19e,%ebx
f0103e88:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL){
f0103e8b:	8b 93 64 23 00 00    	mov    0x2364(%ebx),%edx
f0103e91:	85 d2                	test   %edx,%edx
f0103e93:	74 06                	je     f0103e9b <env_run+0x25>
		if (curenv -> env_status == ENV_RUNNING)
f0103e95:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103e99:	74 35                	je     f0103ed0 <env_run+0x5a>
			curenv -> env_status = ENV_RUNNABLE;
	}
	curenv = e;
f0103e9b:	89 83 64 23 00 00    	mov    %eax,0x2364(%ebx)
	curenv -> env_status = ENV_RUNNING;
f0103ea1:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv -> env_runs ++;
f0103ea8:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv -> env_pgdir));
f0103eac:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103eaf:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103eb5:	77 22                	ja     f0103ed9 <env_run+0x63>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103eb7:	52                   	push   %edx
f0103eb8:	8d 83 78 86 f7 ff    	lea    -0x87988(%ebx),%eax
f0103ebe:	50                   	push   %eax
f0103ebf:	68 fe 01 00 00       	push   $0x1fe
f0103ec4:	8d 83 03 8d f7 ff    	lea    -0x872fd(%ebx),%eax
f0103eca:	50                   	push   %eax
f0103ecb:	e8 e1 c1 ff ff       	call   f01000b1 <_panic>
			curenv -> env_status = ENV_RUNNABLE;
f0103ed0:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103ed7:	eb c2                	jmp    f0103e9b <env_run+0x25>
	return (physaddr_t)kva - KERNBASE;
f0103ed9:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103edf:	0f 22 da             	mov    %edx,%cr3

	//cprintf("info : %08x\n", curenv -> env_tf.tf_eip);
	env_pop_tf(&(curenv -> env_tf));
f0103ee2:	83 ec 0c             	sub    $0xc,%esp
f0103ee5:	50                   	push   %eax
f0103ee6:	e8 57 ff ff ff       	call   f0103e42 <env_pop_tf>

f0103eeb <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103eeb:	55                   	push   %ebp
f0103eec:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103eee:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ef1:	ba 70 00 00 00       	mov    $0x70,%edx
f0103ef6:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103ef7:	ba 71 00 00 00       	mov    $0x71,%edx
f0103efc:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103efd:	0f b6 c0             	movzbl %al,%eax
}
f0103f00:	5d                   	pop    %ebp
f0103f01:	c3                   	ret    

f0103f02 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103f02:	55                   	push   %ebp
f0103f03:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f05:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f08:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f0d:	ee                   	out    %al,(%dx)
f0103f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f11:	ba 71 00 00 00       	mov    $0x71,%edx
f0103f16:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103f17:	5d                   	pop    %ebp
f0103f18:	c3                   	ret    

f0103f19 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103f19:	55                   	push   %ebp
f0103f1a:	89 e5                	mov    %esp,%ebp
f0103f1c:	53                   	push   %ebx
f0103f1d:	83 ec 10             	sub    $0x10,%esp
f0103f20:	e8 42 c2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103f25:	81 c3 fb a0 08 00    	add    $0x8a0fb,%ebx
	cputchar(ch);
f0103f2b:	ff 75 08             	pushl  0x8(%ebp)
f0103f2e:	e8 ab c7 ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f0103f33:	83 c4 10             	add    $0x10,%esp
f0103f36:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103f39:	c9                   	leave  
f0103f3a:	c3                   	ret    

f0103f3b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103f3b:	55                   	push   %ebp
f0103f3c:	89 e5                	mov    %esp,%ebp
f0103f3e:	53                   	push   %ebx
f0103f3f:	83 ec 14             	sub    $0x14,%esp
f0103f42:	e8 20 c2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103f47:	81 c3 d9 a0 08 00    	add    $0x8a0d9,%ebx
	int cnt = 0;
f0103f4d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103f54:	ff 75 0c             	pushl  0xc(%ebp)
f0103f57:	ff 75 08             	pushl  0x8(%ebp)
f0103f5a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103f5d:	50                   	push   %eax
f0103f5e:	8d 83 f9 5e f7 ff    	lea    -0x8a107(%ebx),%eax
f0103f64:	50                   	push   %eax
f0103f65:	e8 19 0f 00 00       	call   f0104e83 <vprintfmt>
	return cnt;
}
f0103f6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f6d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103f70:	c9                   	leave  
f0103f71:	c3                   	ret    

f0103f72 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103f72:	55                   	push   %ebp
f0103f73:	89 e5                	mov    %esp,%ebp
f0103f75:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103f78:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103f7b:	50                   	push   %eax
f0103f7c:	ff 75 08             	pushl  0x8(%ebp)
f0103f7f:	e8 b7 ff ff ff       	call   f0103f3b <vcprintf>
	va_end(ap);

	return cnt;
}
f0103f84:	c9                   	leave  
f0103f85:	c3                   	ret    

f0103f86 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103f86:	55                   	push   %ebp
f0103f87:	89 e5                	mov    %esp,%ebp
f0103f89:	57                   	push   %edi
f0103f8a:	56                   	push   %esi
f0103f8b:	53                   	push   %ebx
f0103f8c:	83 ec 04             	sub    $0x4,%esp
f0103f8f:	e8 d3 c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103f94:	81 c3 8c a0 08 00    	add    $0x8a08c,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103f9a:	c7 83 a4 2b 00 00 00 	movl   $0xf0000000,0x2ba4(%ebx)
f0103fa1:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103fa4:	66 c7 83 a8 2b 00 00 	movw   $0x10,0x2ba8(%ebx)
f0103fab:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103fad:	66 c7 83 06 2c 00 00 	movw   $0x68,0x2c06(%ebx)
f0103fb4:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103fb6:	c7 c0 00 d3 11 f0    	mov    $0xf011d300,%eax
f0103fbc:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103fc2:	8d b3 a0 2b 00 00    	lea    0x2ba0(%ebx),%esi
f0103fc8:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103fcc:	89 f2                	mov    %esi,%edx
f0103fce:	c1 ea 10             	shr    $0x10,%edx
f0103fd1:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103fd4:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103fd8:	83 e2 f0             	and    $0xfffffff0,%edx
f0103fdb:	83 ca 09             	or     $0x9,%edx
f0103fde:	83 e2 9f             	and    $0xffffff9f,%edx
f0103fe1:	83 ca 80             	or     $0xffffff80,%edx
f0103fe4:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103fe7:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103fea:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103fee:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103ff1:	83 c9 40             	or     $0x40,%ecx
f0103ff4:	83 e1 7f             	and    $0x7f,%ecx
f0103ff7:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103ffa:	c1 ee 18             	shr    $0x18,%esi
f0103ffd:	89 f1                	mov    %esi,%ecx
f0103fff:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0104002:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0104006:	83 e2 ef             	and    $0xffffffef,%edx
f0104009:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f010400c:	b8 28 00 00 00       	mov    $0x28,%eax
f0104011:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0104014:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f010401a:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010401d:	83 c4 04             	add    $0x4,%esp
f0104020:	5b                   	pop    %ebx
f0104021:	5e                   	pop    %esi
f0104022:	5f                   	pop    %edi
f0104023:	5d                   	pop    %ebp
f0104024:	c3                   	ret    

f0104025 <trap_init>:
{
f0104025:	55                   	push   %ebp
f0104026:	89 e5                	mov    %esp,%ebp
f0104028:	e8 dc c6 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010402d:	05 f3 9f 08 00       	add    $0x89ff3,%eax
	SETGATE(idt[T_DIVIDE], 0, GD_KT, T_DIVIDE_H, 0);
f0104032:	c7 c2 42 48 10 f0    	mov    $0xf0104842,%edx
f0104038:	66 89 90 80 23 00 00 	mov    %dx,0x2380(%eax)
f010403f:	66 c7 80 82 23 00 00 	movw   $0x8,0x2382(%eax)
f0104046:	08 00 
f0104048:	c6 80 84 23 00 00 00 	movb   $0x0,0x2384(%eax)
f010404f:	c6 80 85 23 00 00 8e 	movb   $0x8e,0x2385(%eax)
f0104056:	c1 ea 10             	shr    $0x10,%edx
f0104059:	66 89 90 86 23 00 00 	mov    %dx,0x2386(%eax)
	SETGATE(idt[T_DEBUG], 0, GD_KT, T_DEBUG_H, 0);
f0104060:	c7 c2 48 48 10 f0    	mov    $0xf0104848,%edx
f0104066:	66 89 90 88 23 00 00 	mov    %dx,0x2388(%eax)
f010406d:	66 c7 80 8a 23 00 00 	movw   $0x8,0x238a(%eax)
f0104074:	08 00 
f0104076:	c6 80 8c 23 00 00 00 	movb   $0x0,0x238c(%eax)
f010407d:	c6 80 8d 23 00 00 8e 	movb   $0x8e,0x238d(%eax)
f0104084:	c1 ea 10             	shr    $0x10,%edx
f0104087:	66 89 90 8e 23 00 00 	mov    %dx,0x238e(%eax)
	SETGATE(idt[T_NMI], 0, GD_KT, T_NMI_H, 0);
f010408e:	c7 c2 4e 48 10 f0    	mov    $0xf010484e,%edx
f0104094:	66 89 90 90 23 00 00 	mov    %dx,0x2390(%eax)
f010409b:	66 c7 80 92 23 00 00 	movw   $0x8,0x2392(%eax)
f01040a2:	08 00 
f01040a4:	c6 80 94 23 00 00 00 	movb   $0x0,0x2394(%eax)
f01040ab:	c6 80 95 23 00 00 8e 	movb   $0x8e,0x2395(%eax)
f01040b2:	c1 ea 10             	shr    $0x10,%edx
f01040b5:	66 89 90 96 23 00 00 	mov    %dx,0x2396(%eax)
	SETGATE(idt[T_BRKPT], 0, GD_KT, T_BRKPT_H, 3);
f01040bc:	c7 c2 54 48 10 f0    	mov    $0xf0104854,%edx
f01040c2:	66 89 90 98 23 00 00 	mov    %dx,0x2398(%eax)
f01040c9:	66 c7 80 9a 23 00 00 	movw   $0x8,0x239a(%eax)
f01040d0:	08 00 
f01040d2:	c6 80 9c 23 00 00 00 	movb   $0x0,0x239c(%eax)
f01040d9:	c6 80 9d 23 00 00 ee 	movb   $0xee,0x239d(%eax)
f01040e0:	c1 ea 10             	shr    $0x10,%edx
f01040e3:	66 89 90 9e 23 00 00 	mov    %dx,0x239e(%eax)
	SETGATE(idt[T_OFLOW], 0, GD_KT, T_OFLOW_H, 0);
f01040ea:	c7 c2 5a 48 10 f0    	mov    $0xf010485a,%edx
f01040f0:	66 89 90 a0 23 00 00 	mov    %dx,0x23a0(%eax)
f01040f7:	66 c7 80 a2 23 00 00 	movw   $0x8,0x23a2(%eax)
f01040fe:	08 00 
f0104100:	c6 80 a4 23 00 00 00 	movb   $0x0,0x23a4(%eax)
f0104107:	c6 80 a5 23 00 00 8e 	movb   $0x8e,0x23a5(%eax)
f010410e:	c1 ea 10             	shr    $0x10,%edx
f0104111:	66 89 90 a6 23 00 00 	mov    %dx,0x23a6(%eax)
	SETGATE(idt[T_BOUND], 0, GD_KT, T_BOUND_H, 0);
f0104118:	c7 c2 60 48 10 f0    	mov    $0xf0104860,%edx
f010411e:	66 89 90 a8 23 00 00 	mov    %dx,0x23a8(%eax)
f0104125:	66 c7 80 aa 23 00 00 	movw   $0x8,0x23aa(%eax)
f010412c:	08 00 
f010412e:	c6 80 ac 23 00 00 00 	movb   $0x0,0x23ac(%eax)
f0104135:	c6 80 ad 23 00 00 8e 	movb   $0x8e,0x23ad(%eax)
f010413c:	c1 ea 10             	shr    $0x10,%edx
f010413f:	66 89 90 ae 23 00 00 	mov    %dx,0x23ae(%eax)
	SETGATE(idt[T_ILLOP], 0, GD_KT, T_ILLOP_H, 0);
f0104146:	c7 c2 6c 48 10 f0    	mov    $0xf010486c,%edx
f010414c:	66 89 90 b0 23 00 00 	mov    %dx,0x23b0(%eax)
f0104153:	66 c7 80 b2 23 00 00 	movw   $0x8,0x23b2(%eax)
f010415a:	08 00 
f010415c:	c6 80 b4 23 00 00 00 	movb   $0x0,0x23b4(%eax)
f0104163:	c6 80 b5 23 00 00 8e 	movb   $0x8e,0x23b5(%eax)
f010416a:	c1 ea 10             	shr    $0x10,%edx
f010416d:	66 89 90 b6 23 00 00 	mov    %dx,0x23b6(%eax)
	SETGATE(idt[T_DEVICE], 0, GD_KT, T_DEVICE_H, 0);
f0104174:	c7 c2 66 48 10 f0    	mov    $0xf0104866,%edx
f010417a:	66 89 90 b8 23 00 00 	mov    %dx,0x23b8(%eax)
f0104181:	66 c7 80 ba 23 00 00 	movw   $0x8,0x23ba(%eax)
f0104188:	08 00 
f010418a:	c6 80 bc 23 00 00 00 	movb   $0x0,0x23bc(%eax)
f0104191:	c6 80 bd 23 00 00 8e 	movb   $0x8e,0x23bd(%eax)
f0104198:	c1 ea 10             	shr    $0x10,%edx
f010419b:	66 89 90 be 23 00 00 	mov    %dx,0x23be(%eax)
	SETGATE(idt[T_DBLFLT], 0, GD_KT, T_DBLFLT_H, 0);
f01041a2:	c7 c2 26 48 10 f0    	mov    $0xf0104826,%edx
f01041a8:	66 89 90 c0 23 00 00 	mov    %dx,0x23c0(%eax)
f01041af:	66 c7 80 c2 23 00 00 	movw   $0x8,0x23c2(%eax)
f01041b6:	08 00 
f01041b8:	c6 80 c4 23 00 00 00 	movb   $0x0,0x23c4(%eax)
f01041bf:	c6 80 c5 23 00 00 8e 	movb   $0x8e,0x23c5(%eax)
f01041c6:	c1 ea 10             	shr    $0x10,%edx
f01041c9:	66 89 90 c6 23 00 00 	mov    %dx,0x23c6(%eax)
	SETGATE(idt[T_TSS], 0, GD_KT, T_TSS_H, 0);
f01041d0:	c7 c2 2a 48 10 f0    	mov    $0xf010482a,%edx
f01041d6:	66 89 90 d0 23 00 00 	mov    %dx,0x23d0(%eax)
f01041dd:	66 c7 80 d2 23 00 00 	movw   $0x8,0x23d2(%eax)
f01041e4:	08 00 
f01041e6:	c6 80 d4 23 00 00 00 	movb   $0x0,0x23d4(%eax)
f01041ed:	c6 80 d5 23 00 00 8e 	movb   $0x8e,0x23d5(%eax)
f01041f4:	c1 ea 10             	shr    $0x10,%edx
f01041f7:	66 89 90 d6 23 00 00 	mov    %dx,0x23d6(%eax)
	SETGATE(idt[T_SEGNP], 0, GD_KT, T_SEGNP_H, 0);
f01041fe:	c7 c2 2e 48 10 f0    	mov    $0xf010482e,%edx
f0104204:	66 89 90 d8 23 00 00 	mov    %dx,0x23d8(%eax)
f010420b:	66 c7 80 da 23 00 00 	movw   $0x8,0x23da(%eax)
f0104212:	08 00 
f0104214:	c6 80 dc 23 00 00 00 	movb   $0x0,0x23dc(%eax)
f010421b:	c6 80 dd 23 00 00 8e 	movb   $0x8e,0x23dd(%eax)
f0104222:	c1 ea 10             	shr    $0x10,%edx
f0104225:	66 89 90 de 23 00 00 	mov    %dx,0x23de(%eax)
	SETGATE(idt[T_STACK], 0, GD_KT, T_STACK_H, 0);
f010422c:	c7 c2 32 48 10 f0    	mov    $0xf0104832,%edx
f0104232:	66 89 90 e0 23 00 00 	mov    %dx,0x23e0(%eax)
f0104239:	66 c7 80 e2 23 00 00 	movw   $0x8,0x23e2(%eax)
f0104240:	08 00 
f0104242:	c6 80 e4 23 00 00 00 	movb   $0x0,0x23e4(%eax)
f0104249:	c6 80 e5 23 00 00 8e 	movb   $0x8e,0x23e5(%eax)
f0104250:	c1 ea 10             	shr    $0x10,%edx
f0104253:	66 89 90 e6 23 00 00 	mov    %dx,0x23e6(%eax)
	SETGATE(idt[T_GPFLT], 0, GD_KT, T_GPFLT_H, 0);
f010425a:	c7 c2 36 48 10 f0    	mov    $0xf0104836,%edx
f0104260:	66 89 90 e8 23 00 00 	mov    %dx,0x23e8(%eax)
f0104267:	66 c7 80 ea 23 00 00 	movw   $0x8,0x23ea(%eax)
f010426e:	08 00 
f0104270:	c6 80 ec 23 00 00 00 	movb   $0x0,0x23ec(%eax)
f0104277:	c6 80 ed 23 00 00 8e 	movb   $0x8e,0x23ed(%eax)
f010427e:	c1 ea 10             	shr    $0x10,%edx
f0104281:	66 89 90 ee 23 00 00 	mov    %dx,0x23ee(%eax)
	SETGATE(idt[T_PGFLT], 0, GD_KT, T_PGFLT_H, 0);
f0104288:	c7 c2 3a 48 10 f0    	mov    $0xf010483a,%edx
f010428e:	66 89 90 f0 23 00 00 	mov    %dx,0x23f0(%eax)
f0104295:	66 c7 80 f2 23 00 00 	movw   $0x8,0x23f2(%eax)
f010429c:	08 00 
f010429e:	c6 80 f4 23 00 00 00 	movb   $0x0,0x23f4(%eax)
f01042a5:	c6 80 f5 23 00 00 8e 	movb   $0x8e,0x23f5(%eax)
f01042ac:	c1 ea 10             	shr    $0x10,%edx
f01042af:	66 89 90 f6 23 00 00 	mov    %dx,0x23f6(%eax)
	SETGATE(idt[T_FPERR], 0, GD_KT, T_FPERR_H, 0);
f01042b6:	c7 c2 72 48 10 f0    	mov    $0xf0104872,%edx
f01042bc:	66 89 90 00 24 00 00 	mov    %dx,0x2400(%eax)
f01042c3:	66 c7 80 02 24 00 00 	movw   $0x8,0x2402(%eax)
f01042ca:	08 00 
f01042cc:	c6 80 04 24 00 00 00 	movb   $0x0,0x2404(%eax)
f01042d3:	c6 80 05 24 00 00 8e 	movb   $0x8e,0x2405(%eax)
f01042da:	c1 ea 10             	shr    $0x10,%edx
f01042dd:	66 89 90 06 24 00 00 	mov    %dx,0x2406(%eax)
	SETGATE(idt[T_ALIGN], 0, GD_KT, T_ALIGN_H, 0);
f01042e4:	c7 c2 3e 48 10 f0    	mov    $0xf010483e,%edx
f01042ea:	66 89 90 08 24 00 00 	mov    %dx,0x2408(%eax)
f01042f1:	66 c7 80 0a 24 00 00 	movw   $0x8,0x240a(%eax)
f01042f8:	08 00 
f01042fa:	c6 80 0c 24 00 00 00 	movb   $0x0,0x240c(%eax)
f0104301:	c6 80 0d 24 00 00 8e 	movb   $0x8e,0x240d(%eax)
f0104308:	c1 ea 10             	shr    $0x10,%edx
f010430b:	66 89 90 0e 24 00 00 	mov    %dx,0x240e(%eax)
	SETGATE(idt[T_MCHK], 0, GD_KT, T_MCHK_H, 0);
f0104312:	c7 c2 78 48 10 f0    	mov    $0xf0104878,%edx
f0104318:	66 89 90 10 24 00 00 	mov    %dx,0x2410(%eax)
f010431f:	66 c7 80 12 24 00 00 	movw   $0x8,0x2412(%eax)
f0104326:	08 00 
f0104328:	c6 80 14 24 00 00 00 	movb   $0x0,0x2414(%eax)
f010432f:	c6 80 15 24 00 00 8e 	movb   $0x8e,0x2415(%eax)
f0104336:	c1 ea 10             	shr    $0x10,%edx
f0104339:	66 89 90 16 24 00 00 	mov    %dx,0x2416(%eax)
	SETGATE(idt[T_SIMDERR], 0, GD_KT, T_SIMDERR_H, 0);
f0104340:	c7 c2 7e 48 10 f0    	mov    $0xf010487e,%edx
f0104346:	66 89 90 18 24 00 00 	mov    %dx,0x2418(%eax)
f010434d:	66 c7 80 1a 24 00 00 	movw   $0x8,0x241a(%eax)
f0104354:	08 00 
f0104356:	c6 80 1c 24 00 00 00 	movb   $0x0,0x241c(%eax)
f010435d:	c6 80 1d 24 00 00 8e 	movb   $0x8e,0x241d(%eax)
f0104364:	c1 ea 10             	shr    $0x10,%edx
f0104367:	66 89 90 1e 24 00 00 	mov    %dx,0x241e(%eax)
	SETGATE(idt[T_SYSCALL], 0, GD_KT, T_SYSCALL_H, 3);
f010436e:	c7 c2 84 48 10 f0    	mov    $0xf0104884,%edx
f0104374:	66 89 90 00 25 00 00 	mov    %dx,0x2500(%eax)
f010437b:	66 c7 80 02 25 00 00 	movw   $0x8,0x2502(%eax)
f0104382:	08 00 
f0104384:	c6 80 04 25 00 00 00 	movb   $0x0,0x2504(%eax)
f010438b:	c6 80 05 25 00 00 ee 	movb   $0xee,0x2505(%eax)
f0104392:	c1 ea 10             	shr    $0x10,%edx
f0104395:	66 89 90 06 25 00 00 	mov    %dx,0x2506(%eax)
	SETGATE(idt[T_DEFAULT], 0, GD_KT, T_DEFAULT_H, 0);
f010439c:	c7 c2 8a 48 10 f0    	mov    $0xf010488a,%edx
f01043a2:	66 89 90 20 33 00 00 	mov    %dx,0x3320(%eax)
f01043a9:	66 c7 80 22 33 00 00 	movw   $0x8,0x3322(%eax)
f01043b0:	08 00 
f01043b2:	c6 80 24 33 00 00 00 	movb   $0x0,0x3324(%eax)
f01043b9:	c6 80 25 33 00 00 8e 	movb   $0x8e,0x3325(%eax)
f01043c0:	c1 ea 10             	shr    $0x10,%edx
f01043c3:	66 89 90 26 33 00 00 	mov    %dx,0x3326(%eax)
	trap_init_percpu();
f01043ca:	e8 b7 fb ff ff       	call   f0103f86 <trap_init_percpu>
}
f01043cf:	5d                   	pop    %ebp
f01043d0:	c3                   	ret    

f01043d1 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01043d1:	55                   	push   %ebp
f01043d2:	89 e5                	mov    %esp,%ebp
f01043d4:	56                   	push   %esi
f01043d5:	53                   	push   %ebx
f01043d6:	e8 8c bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01043db:	81 c3 45 9c 08 00    	add    $0x89c45,%ebx
f01043e1:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01043e4:	83 ec 08             	sub    $0x8,%esp
f01043e7:	ff 36                	pushl  (%esi)
f01043e9:	8d 83 d6 8d f7 ff    	lea    -0x8722a(%ebx),%eax
f01043ef:	50                   	push   %eax
f01043f0:	e8 7d fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01043f5:	83 c4 08             	add    $0x8,%esp
f01043f8:	ff 76 04             	pushl  0x4(%esi)
f01043fb:	8d 83 e5 8d f7 ff    	lea    -0x8721b(%ebx),%eax
f0104401:	50                   	push   %eax
f0104402:	e8 6b fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104407:	83 c4 08             	add    $0x8,%esp
f010440a:	ff 76 08             	pushl  0x8(%esi)
f010440d:	8d 83 f4 8d f7 ff    	lea    -0x8720c(%ebx),%eax
f0104413:	50                   	push   %eax
f0104414:	e8 59 fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104419:	83 c4 08             	add    $0x8,%esp
f010441c:	ff 76 0c             	pushl  0xc(%esi)
f010441f:	8d 83 03 8e f7 ff    	lea    -0x871fd(%ebx),%eax
f0104425:	50                   	push   %eax
f0104426:	e8 47 fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010442b:	83 c4 08             	add    $0x8,%esp
f010442e:	ff 76 10             	pushl  0x10(%esi)
f0104431:	8d 83 12 8e f7 ff    	lea    -0x871ee(%ebx),%eax
f0104437:	50                   	push   %eax
f0104438:	e8 35 fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010443d:	83 c4 08             	add    $0x8,%esp
f0104440:	ff 76 14             	pushl  0x14(%esi)
f0104443:	8d 83 21 8e f7 ff    	lea    -0x871df(%ebx),%eax
f0104449:	50                   	push   %eax
f010444a:	e8 23 fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010444f:	83 c4 08             	add    $0x8,%esp
f0104452:	ff 76 18             	pushl  0x18(%esi)
f0104455:	8d 83 30 8e f7 ff    	lea    -0x871d0(%ebx),%eax
f010445b:	50                   	push   %eax
f010445c:	e8 11 fb ff ff       	call   f0103f72 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104461:	83 c4 08             	add    $0x8,%esp
f0104464:	ff 76 1c             	pushl  0x1c(%esi)
f0104467:	8d 83 3f 8e f7 ff    	lea    -0x871c1(%ebx),%eax
f010446d:	50                   	push   %eax
f010446e:	e8 ff fa ff ff       	call   f0103f72 <cprintf>
}
f0104473:	83 c4 10             	add    $0x10,%esp
f0104476:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104479:	5b                   	pop    %ebx
f010447a:	5e                   	pop    %esi
f010447b:	5d                   	pop    %ebp
f010447c:	c3                   	ret    

f010447d <print_trapframe>:
{
f010447d:	55                   	push   %ebp
f010447e:	89 e5                	mov    %esp,%ebp
f0104480:	57                   	push   %edi
f0104481:	56                   	push   %esi
f0104482:	53                   	push   %ebx
f0104483:	83 ec 14             	sub    $0x14,%esp
f0104486:	e8 dc bc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010448b:	81 c3 95 9b 08 00    	add    $0x89b95,%ebx
f0104491:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0104494:	56                   	push   %esi
f0104495:	8d 83 90 8f f7 ff    	lea    -0x87070(%ebx),%eax
f010449b:	50                   	push   %eax
f010449c:	e8 d1 fa ff ff       	call   f0103f72 <cprintf>
	print_regs(&tf->tf_regs);
f01044a1:	89 34 24             	mov    %esi,(%esp)
f01044a4:	e8 28 ff ff ff       	call   f01043d1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01044a9:	83 c4 08             	add    $0x8,%esp
f01044ac:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f01044b0:	50                   	push   %eax
f01044b1:	8d 83 90 8e f7 ff    	lea    -0x87170(%ebx),%eax
f01044b7:	50                   	push   %eax
f01044b8:	e8 b5 fa ff ff       	call   f0103f72 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01044bd:	83 c4 08             	add    $0x8,%esp
f01044c0:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f01044c4:	50                   	push   %eax
f01044c5:	8d 83 a3 8e f7 ff    	lea    -0x8715d(%ebx),%eax
f01044cb:	50                   	push   %eax
f01044cc:	e8 a1 fa ff ff       	call   f0103f72 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01044d1:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f01044d4:	83 c4 10             	add    $0x10,%esp
f01044d7:	83 fa 13             	cmp    $0x13,%edx
f01044da:	0f 86 e9 00 00 00    	jbe    f01045c9 <print_trapframe+0x14c>
	return "(unknown trap)";
f01044e0:	83 fa 30             	cmp    $0x30,%edx
f01044e3:	8d 83 4e 8e f7 ff    	lea    -0x871b2(%ebx),%eax
f01044e9:	8d 8b 5a 8e f7 ff    	lea    -0x871a6(%ebx),%ecx
f01044ef:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01044f2:	83 ec 04             	sub    $0x4,%esp
f01044f5:	50                   	push   %eax
f01044f6:	52                   	push   %edx
f01044f7:	8d 83 b6 8e f7 ff    	lea    -0x8714a(%ebx),%eax
f01044fd:	50                   	push   %eax
f01044fe:	e8 6f fa ff ff       	call   f0103f72 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104503:	83 c4 10             	add    $0x10,%esp
f0104506:	39 b3 80 2b 00 00    	cmp    %esi,0x2b80(%ebx)
f010450c:	0f 84 c3 00 00 00    	je     f01045d5 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f0104512:	83 ec 08             	sub    $0x8,%esp
f0104515:	ff 76 2c             	pushl  0x2c(%esi)
f0104518:	8d 83 d7 8e f7 ff    	lea    -0x87129(%ebx),%eax
f010451e:	50                   	push   %eax
f010451f:	e8 4e fa ff ff       	call   f0103f72 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104524:	83 c4 10             	add    $0x10,%esp
f0104527:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f010452b:	0f 85 c9 00 00 00    	jne    f01045fa <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f0104531:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0104534:	89 c2                	mov    %eax,%edx
f0104536:	83 e2 01             	and    $0x1,%edx
f0104539:	8d 8b 69 8e f7 ff    	lea    -0x87197(%ebx),%ecx
f010453f:	8d 93 74 8e f7 ff    	lea    -0x8718c(%ebx),%edx
f0104545:	0f 44 ca             	cmove  %edx,%ecx
f0104548:	89 c2                	mov    %eax,%edx
f010454a:	83 e2 02             	and    $0x2,%edx
f010454d:	8d 93 80 8e f7 ff    	lea    -0x87180(%ebx),%edx
f0104553:	8d bb 86 8e f7 ff    	lea    -0x8717a(%ebx),%edi
f0104559:	0f 44 d7             	cmove  %edi,%edx
f010455c:	83 e0 04             	and    $0x4,%eax
f010455f:	8d 83 8b 8e f7 ff    	lea    -0x87175(%ebx),%eax
f0104565:	8d bb bb 8f f7 ff    	lea    -0x87045(%ebx),%edi
f010456b:	0f 44 c7             	cmove  %edi,%eax
f010456e:	51                   	push   %ecx
f010456f:	52                   	push   %edx
f0104570:	50                   	push   %eax
f0104571:	8d 83 e5 8e f7 ff    	lea    -0x8711b(%ebx),%eax
f0104577:	50                   	push   %eax
f0104578:	e8 f5 f9 ff ff       	call   f0103f72 <cprintf>
f010457d:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104580:	83 ec 08             	sub    $0x8,%esp
f0104583:	ff 76 30             	pushl  0x30(%esi)
f0104586:	8d 83 f4 8e f7 ff    	lea    -0x8710c(%ebx),%eax
f010458c:	50                   	push   %eax
f010458d:	e8 e0 f9 ff ff       	call   f0103f72 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104592:	83 c4 08             	add    $0x8,%esp
f0104595:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104599:	50                   	push   %eax
f010459a:	8d 83 03 8f f7 ff    	lea    -0x870fd(%ebx),%eax
f01045a0:	50                   	push   %eax
f01045a1:	e8 cc f9 ff ff       	call   f0103f72 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01045a6:	83 c4 08             	add    $0x8,%esp
f01045a9:	ff 76 38             	pushl  0x38(%esi)
f01045ac:	8d 83 16 8f f7 ff    	lea    -0x870ea(%ebx),%eax
f01045b2:	50                   	push   %eax
f01045b3:	e8 ba f9 ff ff       	call   f0103f72 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01045b8:	83 c4 10             	add    $0x10,%esp
f01045bb:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f01045bf:	75 50                	jne    f0104611 <print_trapframe+0x194>
}
f01045c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045c4:	5b                   	pop    %ebx
f01045c5:	5e                   	pop    %esi
f01045c6:	5f                   	pop    %edi
f01045c7:	5d                   	pop    %ebp
f01045c8:	c3                   	ret    
		return excnames[trapno];
f01045c9:	8b 84 93 a0 20 00 00 	mov    0x20a0(%ebx,%edx,4),%eax
f01045d0:	e9 1d ff ff ff       	jmp    f01044f2 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01045d5:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f01045d9:	0f 85 33 ff ff ff    	jne    f0104512 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01045df:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01045e2:	83 ec 08             	sub    $0x8,%esp
f01045e5:	50                   	push   %eax
f01045e6:	8d 83 c8 8e f7 ff    	lea    -0x87138(%ebx),%eax
f01045ec:	50                   	push   %eax
f01045ed:	e8 80 f9 ff ff       	call   f0103f72 <cprintf>
f01045f2:	83 c4 10             	add    $0x10,%esp
f01045f5:	e9 18 ff ff ff       	jmp    f0104512 <print_trapframe+0x95>
		cprintf("\n");
f01045fa:	83 ec 0c             	sub    $0xc,%esp
f01045fd:	8d 83 eb 7c f7 ff    	lea    -0x88315(%ebx),%eax
f0104603:	50                   	push   %eax
f0104604:	e8 69 f9 ff ff       	call   f0103f72 <cprintf>
f0104609:	83 c4 10             	add    $0x10,%esp
f010460c:	e9 6f ff ff ff       	jmp    f0104580 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104611:	83 ec 08             	sub    $0x8,%esp
f0104614:	ff 76 3c             	pushl  0x3c(%esi)
f0104617:	8d 83 25 8f f7 ff    	lea    -0x870db(%ebx),%eax
f010461d:	50                   	push   %eax
f010461e:	e8 4f f9 ff ff       	call   f0103f72 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104623:	83 c4 08             	add    $0x8,%esp
f0104626:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f010462a:	50                   	push   %eax
f010462b:	8d 83 34 8f f7 ff    	lea    -0x870cc(%ebx),%eax
f0104631:	50                   	push   %eax
f0104632:	e8 3b f9 ff ff       	call   f0103f72 <cprintf>
f0104637:	83 c4 10             	add    $0x10,%esp
}
f010463a:	eb 85                	jmp    f01045c1 <print_trapframe+0x144>

f010463c <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010463c:	55                   	push   %ebp
f010463d:	89 e5                	mov    %esp,%ebp
f010463f:	57                   	push   %edi
f0104640:	56                   	push   %esi
f0104641:	53                   	push   %ebx
f0104642:	83 ec 0c             	sub    $0xc,%esp
f0104645:	e8 1d bb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010464a:	81 c3 d6 99 08 00    	add    $0x899d6,%ebx
f0104650:	8b 75 08             	mov    0x8(%ebp),%esi
f0104653:	0f 20 d0             	mov    %cr2,%eax

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.

	if ((tf -> tf_cs & 3) == 0)
f0104656:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f010465a:	74 38                	je     f0104694 <page_fault_handler+0x58>
		panic("page fault in kernel mode!");
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010465c:	ff 76 30             	pushl  0x30(%esi)
f010465f:	50                   	push   %eax
f0104660:	c7 c7 84 03 19 f0    	mov    $0xf0190384,%edi
f0104666:	8b 07                	mov    (%edi),%eax
f0104668:	ff 70 48             	pushl  0x48(%eax)
f010466b:	8d 83 08 91 f7 ff    	lea    -0x86ef8(%ebx),%eax
f0104671:	50                   	push   %eax
f0104672:	e8 fb f8 ff ff       	call   f0103f72 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104677:	89 34 24             	mov    %esi,(%esp)
f010467a:	e8 fe fd ff ff       	call   f010447d <print_trapframe>
	env_destroy(curenv);
f010467f:	83 c4 04             	add    $0x4,%esp
f0104682:	ff 37                	pushl  (%edi)
f0104684:	e8 7f f7 ff ff       	call   f0103e08 <env_destroy>
}
f0104689:	83 c4 10             	add    $0x10,%esp
f010468c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010468f:	5b                   	pop    %ebx
f0104690:	5e                   	pop    %esi
f0104691:	5f                   	pop    %edi
f0104692:	5d                   	pop    %ebp
f0104693:	c3                   	ret    
		panic("page fault in kernel mode!");
f0104694:	83 ec 04             	sub    $0x4,%esp
f0104697:	8d 83 47 8f f7 ff    	lea    -0x870b9(%ebx),%eax
f010469d:	50                   	push   %eax
f010469e:	68 0a 01 00 00       	push   $0x10a
f01046a3:	8d 83 62 8f f7 ff    	lea    -0x8709e(%ebx),%eax
f01046a9:	50                   	push   %eax
f01046aa:	e8 02 ba ff ff       	call   f01000b1 <_panic>

f01046af <trap>:
{
f01046af:	55                   	push   %ebp
f01046b0:	89 e5                	mov    %esp,%ebp
f01046b2:	57                   	push   %edi
f01046b3:	56                   	push   %esi
f01046b4:	53                   	push   %ebx
f01046b5:	83 ec 0c             	sub    $0xc,%esp
f01046b8:	e8 aa ba ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01046bd:	81 c3 63 99 08 00    	add    $0x89963,%ebx
f01046c3:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f01046c6:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01046c7:	9c                   	pushf  
f01046c8:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01046c9:	f6 c4 02             	test   $0x2,%ah
f01046cc:	74 1f                	je     f01046ed <trap+0x3e>
f01046ce:	8d 83 6e 8f f7 ff    	lea    -0x87092(%ebx),%eax
f01046d4:	50                   	push   %eax
f01046d5:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01046db:	50                   	push   %eax
f01046dc:	68 e0 00 00 00       	push   $0xe0
f01046e1:	8d 83 62 8f f7 ff    	lea    -0x8709e(%ebx),%eax
f01046e7:	50                   	push   %eax
f01046e8:	e8 c4 b9 ff ff       	call   f01000b1 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f01046ed:	83 ec 08             	sub    $0x8,%esp
f01046f0:	56                   	push   %esi
f01046f1:	8d 83 87 8f f7 ff    	lea    -0x87079(%ebx),%eax
f01046f7:	50                   	push   %eax
f01046f8:	e8 75 f8 ff ff       	call   f0103f72 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f01046fd:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104701:	83 e0 03             	and    $0x3,%eax
f0104704:	83 c4 10             	add    $0x10,%esp
f0104707:	66 83 f8 03          	cmp    $0x3,%ax
f010470b:	75 1d                	jne    f010472a <trap+0x7b>
		assert(curenv);
f010470d:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104713:	8b 00                	mov    (%eax),%eax
f0104715:	85 c0                	test   %eax,%eax
f0104717:	74 5d                	je     f0104776 <trap+0xc7>
		curenv->env_tf = *tf;
f0104719:	b9 11 00 00 00       	mov    $0x11,%ecx
f010471e:	89 c7                	mov    %eax,%edi
f0104720:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104722:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104728:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f010472a:	89 b3 80 2b 00 00    	mov    %esi,0x2b80(%ebx)
	switch (tf -> tf_trapno){
f0104730:	8b 46 28             	mov    0x28(%esi),%eax
f0104733:	83 f8 0e             	cmp    $0xe,%eax
f0104736:	74 5d                	je     f0104795 <trap+0xe6>
f0104738:	83 f8 30             	cmp    $0x30,%eax
f010473b:	0f 84 9f 00 00 00    	je     f01047e0 <trap+0x131>
f0104741:	83 f8 03             	cmp    $0x3,%eax
f0104744:	0f 84 88 00 00 00    	je     f01047d2 <trap+0x123>
	print_trapframe(tf);
f010474a:	83 ec 0c             	sub    $0xc,%esp
f010474d:	56                   	push   %esi
f010474e:	e8 2a fd ff ff       	call   f010447d <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104753:	83 c4 10             	add    $0x10,%esp
f0104756:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010475b:	0f 84 a0 00 00 00    	je     f0104801 <trap+0x152>
		env_destroy(curenv);
f0104761:	83 ec 0c             	sub    $0xc,%esp
f0104764:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f010476a:	ff 30                	pushl  (%eax)
f010476c:	e8 97 f6 ff ff       	call   f0103e08 <env_destroy>
f0104771:	83 c4 10             	add    $0x10,%esp
f0104774:	eb 2b                	jmp    f01047a1 <trap+0xf2>
		assert(curenv);
f0104776:	8d 83 a2 8f f7 ff    	lea    -0x8705e(%ebx),%eax
f010477c:	50                   	push   %eax
f010477d:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f0104783:	50                   	push   %eax
f0104784:	68 e6 00 00 00       	push   $0xe6
f0104789:	8d 83 62 8f f7 ff    	lea    -0x8709e(%ebx),%eax
f010478f:	50                   	push   %eax
f0104790:	e8 1c b9 ff ff       	call   f01000b1 <_panic>
			page_fault_handler(tf);
f0104795:	83 ec 0c             	sub    $0xc,%esp
f0104798:	56                   	push   %esi
f0104799:	e8 9e fe ff ff       	call   f010463c <page_fault_handler>
f010479e:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01047a1:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f01047a7:	8b 00                	mov    (%eax),%eax
f01047a9:	85 c0                	test   %eax,%eax
f01047ab:	74 06                	je     f01047b3 <trap+0x104>
f01047ad:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01047b1:	74 69                	je     f010481c <trap+0x16d>
f01047b3:	8d 83 2c 91 f7 ff    	lea    -0x86ed4(%ebx),%eax
f01047b9:	50                   	push   %eax
f01047ba:	8d 83 c7 81 f7 ff    	lea    -0x87e39(%ebx),%eax
f01047c0:	50                   	push   %eax
f01047c1:	68 f8 00 00 00       	push   $0xf8
f01047c6:	8d 83 62 8f f7 ff    	lea    -0x8709e(%ebx),%eax
f01047cc:	50                   	push   %eax
f01047cd:	e8 df b8 ff ff       	call   f01000b1 <_panic>
			monitor(tf);
f01047d2:	83 ec 0c             	sub    $0xc,%esp
f01047d5:	56                   	push   %esi
f01047d6:	e8 b0 c5 ff ff       	call   f0100d8b <monitor>
f01047db:	83 c4 10             	add    $0x10,%esp
f01047de:	eb c1                	jmp    f01047a1 <trap+0xf2>
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f01047e0:	83 ec 08             	sub    $0x8,%esp
f01047e3:	ff 76 04             	pushl  0x4(%esi)
f01047e6:	ff 36                	pushl  (%esi)
f01047e8:	ff 76 10             	pushl  0x10(%esi)
f01047eb:	ff 76 18             	pushl  0x18(%esi)
f01047ee:	ff 76 14             	pushl  0x14(%esi)
f01047f1:	ff 76 1c             	pushl  0x1c(%esi)
f01047f4:	e8 ab 00 00 00       	call   f01048a4 <syscall>
f01047f9:	89 46 1c             	mov    %eax,0x1c(%esi)
f01047fc:	83 c4 20             	add    $0x20,%esp
f01047ff:	eb a0                	jmp    f01047a1 <trap+0xf2>
		panic("unhandled trap in kernel");
f0104801:	83 ec 04             	sub    $0x4,%esp
f0104804:	8d 83 a9 8f f7 ff    	lea    -0x87057(%ebx),%eax
f010480a:	50                   	push   %eax
f010480b:	68 cf 00 00 00       	push   $0xcf
f0104810:	8d 83 62 8f f7 ff    	lea    -0x8709e(%ebx),%eax
f0104816:	50                   	push   %eax
f0104817:	e8 95 b8 ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f010481c:	83 ec 0c             	sub    $0xc,%esp
f010481f:	50                   	push   %eax
f0104820:	e8 51 f6 ff ff       	call   f0103e76 <env_run>
f0104825:	90                   	nop

f0104826 <T_DBLFLT_H>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(T_DBLFLT_H, T_DBLFLT)
f0104826:	6a 08                	push   $0x8
f0104828:	eb 69                	jmp    f0104893 <_alltraps>

f010482a <T_TSS_H>:
TRAPHANDLER(T_TSS_H, T_TSS)
f010482a:	6a 0a                	push   $0xa
f010482c:	eb 65                	jmp    f0104893 <_alltraps>

f010482e <T_SEGNP_H>:
TRAPHANDLER(T_SEGNP_H, T_SEGNP)
f010482e:	6a 0b                	push   $0xb
f0104830:	eb 61                	jmp    f0104893 <_alltraps>

f0104832 <T_STACK_H>:
TRAPHANDLER(T_STACK_H, T_STACK)
f0104832:	6a 0c                	push   $0xc
f0104834:	eb 5d                	jmp    f0104893 <_alltraps>

f0104836 <T_GPFLT_H>:
TRAPHANDLER(T_GPFLT_H, T_GPFLT)
f0104836:	6a 0d                	push   $0xd
f0104838:	eb 59                	jmp    f0104893 <_alltraps>

f010483a <T_PGFLT_H>:
TRAPHANDLER(T_PGFLT_H, T_PGFLT)
f010483a:	6a 0e                	push   $0xe
f010483c:	eb 55                	jmp    f0104893 <_alltraps>

f010483e <T_ALIGN_H>:
TRAPHANDLER(T_ALIGN_H, T_ALIGN)
f010483e:	6a 11                	push   $0x11
f0104840:	eb 51                	jmp    f0104893 <_alltraps>

f0104842 <T_DIVIDE_H>:

TRAPHANDLER_NOEC(T_DIVIDE_H, T_DIVIDE)
f0104842:	6a 00                	push   $0x0
f0104844:	6a 00                	push   $0x0
f0104846:	eb 4b                	jmp    f0104893 <_alltraps>

f0104848 <T_DEBUG_H>:
TRAPHANDLER_NOEC(T_DEBUG_H, T_DEBUG)
f0104848:	6a 00                	push   $0x0
f010484a:	6a 01                	push   $0x1
f010484c:	eb 45                	jmp    f0104893 <_alltraps>

f010484e <T_NMI_H>:
TRAPHANDLER_NOEC(T_NMI_H, T_NMI)
f010484e:	6a 00                	push   $0x0
f0104850:	6a 02                	push   $0x2
f0104852:	eb 3f                	jmp    f0104893 <_alltraps>

f0104854 <T_BRKPT_H>:
TRAPHANDLER_NOEC(T_BRKPT_H, T_BRKPT)
f0104854:	6a 00                	push   $0x0
f0104856:	6a 03                	push   $0x3
f0104858:	eb 39                	jmp    f0104893 <_alltraps>

f010485a <T_OFLOW_H>:
TRAPHANDLER_NOEC(T_OFLOW_H, T_OFLOW)
f010485a:	6a 00                	push   $0x0
f010485c:	6a 04                	push   $0x4
f010485e:	eb 33                	jmp    f0104893 <_alltraps>

f0104860 <T_BOUND_H>:
TRAPHANDLER_NOEC(T_BOUND_H, T_BOUND)
f0104860:	6a 00                	push   $0x0
f0104862:	6a 05                	push   $0x5
f0104864:	eb 2d                	jmp    f0104893 <_alltraps>

f0104866 <T_DEVICE_H>:
TRAPHANDLER_NOEC(T_DEVICE_H, T_DEVICE)
f0104866:	6a 00                	push   $0x0
f0104868:	6a 07                	push   $0x7
f010486a:	eb 27                	jmp    f0104893 <_alltraps>

f010486c <T_ILLOP_H>:
TRAPHANDLER_NOEC(T_ILLOP_H, T_ILLOP)
f010486c:	6a 00                	push   $0x0
f010486e:	6a 06                	push   $0x6
f0104870:	eb 21                	jmp    f0104893 <_alltraps>

f0104872 <T_FPERR_H>:
TRAPHANDLER_NOEC(T_FPERR_H, T_FPERR)
f0104872:	6a 00                	push   $0x0
f0104874:	6a 10                	push   $0x10
f0104876:	eb 1b                	jmp    f0104893 <_alltraps>

f0104878 <T_MCHK_H>:
TRAPHANDLER_NOEC(T_MCHK_H, T_MCHK)
f0104878:	6a 00                	push   $0x0
f010487a:	6a 12                	push   $0x12
f010487c:	eb 15                	jmp    f0104893 <_alltraps>

f010487e <T_SIMDERR_H>:
TRAPHANDLER_NOEC(T_SIMDERR_H, T_SIMDERR)
f010487e:	6a 00                	push   $0x0
f0104880:	6a 13                	push   $0x13
f0104882:	eb 0f                	jmp    f0104893 <_alltraps>

f0104884 <T_SYSCALL_H>:
TRAPHANDLER_NOEC(T_SYSCALL_H, T_SYSCALL)
f0104884:	6a 00                	push   $0x0
f0104886:	6a 30                	push   $0x30
f0104888:	eb 09                	jmp    f0104893 <_alltraps>

f010488a <T_DEFAULT_H>:
TRAPHANDLER_NOEC(T_DEFAULT_H, T_DEFAULT)
f010488a:	6a 00                	push   $0x0
f010488c:	68 f4 01 00 00       	push   $0x1f4
f0104891:	eb 00                	jmp    f0104893 <_alltraps>

f0104893 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

_alltraps:

	pushl %ds
f0104893:	1e                   	push   %ds
	pushl %es
f0104894:	06                   	push   %es
	pushal    # push all registers
f0104895:	60                   	pusha  

	movw $GD_KD, %ax
f0104896:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010489a:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010489c:	8e c0                	mov    %eax,%es

	pushl %esp
f010489e:	54                   	push   %esp
f010489f:	e8 0b fe ff ff       	call   f01046af <trap>

f01048a4 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01048a4:	55                   	push   %ebp
f01048a5:	89 e5                	mov    %esp,%ebp
f01048a7:	53                   	push   %ebx
f01048a8:	83 ec 14             	sub    $0x14,%esp
f01048ab:	e8 b7 b8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01048b0:	81 c3 70 97 08 00    	add    $0x89770,%ebx
f01048b6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f01048b9:	83 f8 01             	cmp    $0x1,%eax
f01048bc:	74 4d                	je     f010490b <syscall+0x67>
f01048be:	83 f8 01             	cmp    $0x1,%eax
f01048c1:	72 11                	jb     f01048d4 <syscall+0x30>
f01048c3:	83 f8 02             	cmp    $0x2,%eax
f01048c6:	74 4a                	je     f0104912 <syscall+0x6e>
f01048c8:	83 f8 03             	cmp    $0x3,%eax
f01048cb:	74 52                	je     f010491f <syscall+0x7b>
	case SYS_getenvid:
		return sys_getenvid();
	case SYS_env_destroy:
		return sys_env_destroy(sys_getenvid());
	default:
		return -E_INVAL;
f01048cd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01048d2:	eb 32                	jmp    f0104906 <syscall+0x62>
	user_mem_assert(curenv, (void*) s, len, PTE_U);
f01048d4:	6a 04                	push   $0x4
f01048d6:	ff 75 10             	pushl  0x10(%ebp)
f01048d9:	ff 75 0c             	pushl  0xc(%ebp)
f01048dc:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f01048e2:	ff 30                	pushl  (%eax)
f01048e4:	e8 19 ee ff ff       	call   f0103702 <user_mem_assert>
	cprintf("%.*s", len, s);
f01048e9:	83 c4 0c             	add    $0xc,%esp
f01048ec:	ff 75 0c             	pushl  0xc(%ebp)
f01048ef:	ff 75 10             	pushl  0x10(%ebp)
f01048f2:	8d 83 58 91 f7 ff    	lea    -0x86ea8(%ebx),%eax
f01048f8:	50                   	push   %eax
f01048f9:	e8 74 f6 ff ff       	call   f0103f72 <cprintf>
f01048fe:	83 c4 10             	add    $0x10,%esp
		return 0;
f0104901:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0104906:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104909:	c9                   	leave  
f010490a:	c3                   	ret    
	return cons_getc();
f010490b:	e8 52 bc ff ff       	call   f0100562 <cons_getc>
		return sys_cgetc();
f0104910:	eb f4                	jmp    f0104906 <syscall+0x62>
	return curenv->env_id;
f0104912:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104918:	8b 00                	mov    (%eax),%eax
f010491a:	8b 40 48             	mov    0x48(%eax),%eax
		return sys_getenvid();
f010491d:	eb e7                	jmp    f0104906 <syscall+0x62>
	if ((r = envid2env(envid, &e, 1)) < 0)
f010491f:	83 ec 04             	sub    $0x4,%esp
f0104922:	6a 01                	push   $0x1
f0104924:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104927:	50                   	push   %eax
	return curenv->env_id;
f0104928:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f010492e:	8b 00                	mov    (%eax),%eax
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104930:	ff 70 48             	pushl  0x48(%eax)
f0104933:	e8 cf ee ff ff       	call   f0103807 <envid2env>
f0104938:	83 c4 10             	add    $0x10,%esp
f010493b:	85 c0                	test   %eax,%eax
f010493d:	78 c7                	js     f0104906 <syscall+0x62>
	if (e == curenv)
f010493f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104942:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104948:	8b 00                	mov    (%eax),%eax
f010494a:	39 c2                	cmp    %eax,%edx
f010494c:	74 2d                	je     f010497b <syscall+0xd7>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010494e:	83 ec 04             	sub    $0x4,%esp
f0104951:	ff 72 48             	pushl  0x48(%edx)
f0104954:	ff 70 48             	pushl  0x48(%eax)
f0104957:	8d 83 78 91 f7 ff    	lea    -0x86e88(%ebx),%eax
f010495d:	50                   	push   %eax
f010495e:	e8 0f f6 ff ff       	call   f0103f72 <cprintf>
f0104963:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104966:	83 ec 0c             	sub    $0xc,%esp
f0104969:	ff 75 f4             	pushl  -0xc(%ebp)
f010496c:	e8 97 f4 ff ff       	call   f0103e08 <env_destroy>
f0104971:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104974:	b8 00 00 00 00       	mov    $0x0,%eax
		return sys_env_destroy(sys_getenvid());
f0104979:	eb 8b                	jmp    f0104906 <syscall+0x62>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010497b:	83 ec 08             	sub    $0x8,%esp
f010497e:	ff 70 48             	pushl  0x48(%eax)
f0104981:	8d 83 5d 91 f7 ff    	lea    -0x86ea3(%ebx),%eax
f0104987:	50                   	push   %eax
f0104988:	e8 e5 f5 ff ff       	call   f0103f72 <cprintf>
f010498d:	83 c4 10             	add    $0x10,%esp
f0104990:	eb d4                	jmp    f0104966 <syscall+0xc2>

f0104992 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104992:	55                   	push   %ebp
f0104993:	89 e5                	mov    %esp,%ebp
f0104995:	57                   	push   %edi
f0104996:	56                   	push   %esi
f0104997:	53                   	push   %ebx
f0104998:	83 ec 14             	sub    $0x14,%esp
f010499b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010499e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01049a1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01049a4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01049a7:	8b 32                	mov    (%edx),%esi
f01049a9:	8b 01                	mov    (%ecx),%eax
f01049ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01049ae:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01049b5:	eb 2f                	jmp    f01049e6 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01049b7:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01049ba:	39 c6                	cmp    %eax,%esi
f01049bc:	7f 49                	jg     f0104a07 <stab_binsearch+0x75>
f01049be:	0f b6 0a             	movzbl (%edx),%ecx
f01049c1:	83 ea 0c             	sub    $0xc,%edx
f01049c4:	39 f9                	cmp    %edi,%ecx
f01049c6:	75 ef                	jne    f01049b7 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01049c8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01049cb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01049ce:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01049d2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01049d5:	73 35                	jae    f0104a0c <stab_binsearch+0x7a>
			*region_left = m;
f01049d7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01049da:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01049dc:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01049df:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01049e6:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01049e9:	7f 4e                	jg     f0104a39 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01049eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01049ee:	01 f0                	add    %esi,%eax
f01049f0:	89 c3                	mov    %eax,%ebx
f01049f2:	c1 eb 1f             	shr    $0x1f,%ebx
f01049f5:	01 c3                	add    %eax,%ebx
f01049f7:	d1 fb                	sar    %ebx
f01049f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01049fc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01049ff:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104a03:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0104a05:	eb b3                	jmp    f01049ba <stab_binsearch+0x28>
			l = true_m + 1;
f0104a07:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0104a0a:	eb da                	jmp    f01049e6 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0104a0c:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104a0f:	76 14                	jbe    f0104a25 <stab_binsearch+0x93>
			*region_right = m - 1;
f0104a11:	83 e8 01             	sub    $0x1,%eax
f0104a14:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104a17:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104a1a:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0104a1c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104a23:	eb c1                	jmp    f01049e6 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104a25:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104a28:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104a2a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104a2e:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0104a30:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104a37:	eb ad                	jmp    f01049e6 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0104a39:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104a3d:	74 16                	je     f0104a55 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104a3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a42:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104a44:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104a47:	8b 0e                	mov    (%esi),%ecx
f0104a49:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a4c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104a4f:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0104a53:	eb 12                	jmp    f0104a67 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0104a55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a58:	8b 00                	mov    (%eax),%eax
f0104a5a:	83 e8 01             	sub    $0x1,%eax
f0104a5d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104a60:	89 07                	mov    %eax,(%edi)
f0104a62:	eb 16                	jmp    f0104a7a <stab_binsearch+0xe8>
		     l--)
f0104a64:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104a67:	39 c1                	cmp    %eax,%ecx
f0104a69:	7d 0a                	jge    f0104a75 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0104a6b:	0f b6 1a             	movzbl (%edx),%ebx
f0104a6e:	83 ea 0c             	sub    $0xc,%edx
f0104a71:	39 fb                	cmp    %edi,%ebx
f0104a73:	75 ef                	jne    f0104a64 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0104a75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a78:	89 07                	mov    %eax,(%edi)
	}
}
f0104a7a:	83 c4 14             	add    $0x14,%esp
f0104a7d:	5b                   	pop    %ebx
f0104a7e:	5e                   	pop    %esi
f0104a7f:	5f                   	pop    %edi
f0104a80:	5d                   	pop    %ebp
f0104a81:	c3                   	ret    

f0104a82 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104a82:	55                   	push   %ebp
f0104a83:	89 e5                	mov    %esp,%ebp
f0104a85:	57                   	push   %edi
f0104a86:	56                   	push   %esi
f0104a87:	53                   	push   %ebx
f0104a88:	83 ec 4c             	sub    $0x4c,%esp
f0104a8b:	e8 d7 b6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104a90:	81 c3 90 95 08 00    	add    $0x89590,%ebx
f0104a96:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104a99:	8d 83 90 91 f7 ff    	lea    -0x86e70(%ebx),%eax
f0104a9f:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0104aa1:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104aa8:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104aab:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104ab2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab5:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f0104ab8:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104abf:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104ac4:	0f 86 34 01 00 00    	jbe    f0104bfe <debuginfo_eip+0x17c>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104aca:	c7 c0 53 30 11 f0    	mov    $0xf0113053,%eax
f0104ad0:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104ad3:	c7 c0 91 04 11 f0    	mov    $0xf0110491,%eax
f0104ad9:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0104adc:	c7 c6 90 04 11 f0    	mov    $0xf0110490,%esi
		stabs = __STAB_BEGIN__;
f0104ae2:	c7 c0 ac 73 10 f0    	mov    $0xf01073ac,%eax
f0104ae8:	89 45 bc             	mov    %eax,-0x44(%ebp)
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
		if (user_mem_check(curenv, usd -> stabstr, sizeof(usd -> stabstr), PTE_P) < 0) return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104aeb:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104aee:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0104af1:	0f 83 5f 02 00 00    	jae    f0104d56 <debuginfo_eip+0x2d4>
f0104af7:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104afb:	0f 85 5c 02 00 00    	jne    f0104d5d <debuginfo_eip+0x2db>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104b01:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104b08:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0104b0b:	c1 fe 02             	sar    $0x2,%esi
f0104b0e:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104b14:	83 e8 01             	sub    $0x1,%eax
f0104b17:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104b1a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104b1d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104b20:	83 ec 08             	sub    $0x8,%esp
f0104b23:	ff 75 08             	pushl  0x8(%ebp)
f0104b26:	6a 64                	push   $0x64
f0104b28:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104b2b:	89 f0                	mov    %esi,%eax
f0104b2d:	e8 60 fe ff ff       	call   f0104992 <stab_binsearch>
	if (lfile == 0)
f0104b32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b35:	83 c4 10             	add    $0x10,%esp
f0104b38:	85 c0                	test   %eax,%eax
f0104b3a:	0f 84 24 02 00 00    	je     f0104d64 <debuginfo_eip+0x2e2>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104b40:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104b43:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b46:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104b49:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104b4c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104b4f:	83 ec 08             	sub    $0x8,%esp
f0104b52:	ff 75 08             	pushl  0x8(%ebp)
f0104b55:	6a 24                	push   $0x24
f0104b57:	89 f0                	mov    %esi,%eax
f0104b59:	e8 34 fe ff ff       	call   f0104992 <stab_binsearch>

	if (lfun <= rfun) {
f0104b5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104b61:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b64:	83 c4 10             	add    $0x10,%esp
f0104b67:	39 d0                	cmp    %edx,%eax
f0104b69:	0f 8f 19 01 00 00    	jg     f0104c88 <debuginfo_eip+0x206>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b6f:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104b72:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104b75:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104b78:	8b 36                	mov    (%esi),%esi
f0104b7a:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104b7d:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f0104b80:	39 ce                	cmp    %ecx,%esi
f0104b82:	73 06                	jae    f0104b8a <debuginfo_eip+0x108>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b84:	03 75 b4             	add    -0x4c(%ebp),%esi
f0104b87:	89 77 08             	mov    %esi,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b8a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104b8d:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104b90:	89 4f 10             	mov    %ecx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104b93:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0104b96:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b99:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b9c:	83 ec 08             	sub    $0x8,%esp
f0104b9f:	6a 3a                	push   $0x3a
f0104ba1:	ff 77 08             	pushl  0x8(%edi)
f0104ba4:	e8 3f 0a 00 00       	call   f01055e8 <strfind>
f0104ba9:	2b 47 08             	sub    0x8(%edi),%eax
f0104bac:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular c
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104baf:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104bb2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104bb5:	83 c4 08             	add    $0x8,%esp
f0104bb8:	ff 75 08             	pushl  0x8(%ebp)
f0104bbb:	6a 44                	push   $0x44
f0104bbd:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0104bc0:	89 d8                	mov    %ebx,%eax
f0104bc2:	e8 cb fd ff ff       	call   f0104992 <stab_binsearch>
	if (lline <= rline)
f0104bc7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104bca:	83 c4 10             	add    $0x10,%esp
f0104bcd:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0104bd0:	0f 8f 95 01 00 00    	jg     f0104d6b <debuginfo_eip+0x2e9>
		info->eip_line = stabs[lline].n_desc;
f0104bd6:	89 d0                	mov    %edx,%eax
f0104bd8:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104bdb:	c1 e2 02             	shl    $0x2,%edx
f0104bde:	0f b7 4c 13 06       	movzwl 0x6(%ebx,%edx,1),%ecx
f0104be3:	89 4f 04             	mov    %ecx,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104be6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104be9:	8d 54 13 04          	lea    0x4(%ebx,%edx,1),%edx
f0104bed:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104bf1:	bb 01 00 00 00       	mov    $0x1,%ebx
f0104bf6:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104bf9:	e9 aa 00 00 00       	jmp    f0104ca8 <debuginfo_eip+0x226>
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_P) < 0) return -1;
f0104bfe:	6a 01                	push   $0x1
f0104c00:	6a 04                	push   $0x4
f0104c02:	68 00 00 20 00       	push   $0x200000
f0104c07:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104c0d:	ff 30                	pushl  (%eax)
f0104c0f:	e8 5f ea ff ff       	call   f0103673 <user_mem_check>
f0104c14:	83 c4 10             	add    $0x10,%esp
f0104c17:	85 c0                	test   %eax,%eax
f0104c19:	0f 88 29 01 00 00    	js     f0104d48 <debuginfo_eip+0x2c6>
		stabs = usd->stabs;
f0104c1f:	a1 00 00 20 00       	mov    0x200000,%eax
f0104c24:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f0104c27:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104c2d:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104c33:	89 4d b4             	mov    %ecx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0104c36:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f0104c3c:	89 4d b8             	mov    %ecx,-0x48(%ebp)
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
f0104c3f:	6a 01                	push   $0x1
f0104c41:	6a 04                	push   $0x4
f0104c43:	50                   	push   %eax
f0104c44:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104c4a:	ff 30                	pushl  (%eax)
f0104c4c:	e8 22 ea ff ff       	call   f0103673 <user_mem_check>
f0104c51:	83 c4 10             	add    $0x10,%esp
f0104c54:	85 c0                	test   %eax,%eax
f0104c56:	0f 88 f3 00 00 00    	js     f0104d4f <debuginfo_eip+0x2cd>
		if (user_mem_check(curenv, usd -> stabstr, sizeof(usd -> stabstr), PTE_P) < 0) return -1;
f0104c5c:	6a 01                	push   $0x1
f0104c5e:	6a 04                	push   $0x4
f0104c60:	ff 35 08 00 20 00    	pushl  0x200008
f0104c66:	c7 c0 84 03 19 f0    	mov    $0xf0190384,%eax
f0104c6c:	ff 30                	pushl  (%eax)
f0104c6e:	e8 00 ea ff ff       	call   f0103673 <user_mem_check>
f0104c73:	83 c4 10             	add    $0x10,%esp
f0104c76:	85 c0                	test   %eax,%eax
f0104c78:	0f 89 6d fe ff ff    	jns    f0104aeb <debuginfo_eip+0x69>
f0104c7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c83:	e9 ef 00 00 00       	jmp    f0104d77 <debuginfo_eip+0x2f5>
		info->eip_fn_addr = addr;
f0104c88:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c8b:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f0104c8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104c94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c97:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104c9a:	e9 fd fe ff ff       	jmp    f0104b9c <debuginfo_eip+0x11a>
f0104c9f:	83 e8 01             	sub    $0x1,%eax
f0104ca2:	83 ea 0c             	sub    $0xc,%edx
f0104ca5:	88 5d c4             	mov    %bl,-0x3c(%ebp)
f0104ca8:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0104cab:	39 c6                	cmp    %eax,%esi
f0104cad:	7f 24                	jg     f0104cd3 <debuginfo_eip+0x251>
	       && stabs[lline].n_type != N_SOL
f0104caf:	0f b6 0a             	movzbl (%edx),%ecx
f0104cb2:	80 f9 84             	cmp    $0x84,%cl
f0104cb5:	74 46                	je     f0104cfd <debuginfo_eip+0x27b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104cb7:	80 f9 64             	cmp    $0x64,%cl
f0104cba:	75 e3                	jne    f0104c9f <debuginfo_eip+0x21d>
f0104cbc:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0104cc0:	74 dd                	je     f0104c9f <debuginfo_eip+0x21d>
f0104cc2:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104cc5:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104cc9:	74 3b                	je     f0104d06 <debuginfo_eip+0x284>
f0104ccb:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104cce:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0104cd1:	eb 33                	jmp    f0104d06 <debuginfo_eip+0x284>
f0104cd3:	8b 7d 0c             	mov    0xc(%ebp),%edi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104cd6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104cd9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104cdc:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0104ce1:	39 da                	cmp    %ebx,%edx
f0104ce3:	0f 8d 8e 00 00 00    	jge    f0104d77 <debuginfo_eip+0x2f5>
		for (lline = lfun + 1;
f0104ce9:	83 c2 01             	add    $0x1,%edx
f0104cec:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104cef:	89 d0                	mov    %edx,%eax
f0104cf1:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104cf4:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104cf7:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0104cfb:	eb 32                	jmp    f0104d2f <debuginfo_eip+0x2ad>
f0104cfd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104d00:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104d04:	75 1d                	jne    f0104d23 <debuginfo_eip+0x2a1>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104d06:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104d09:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104d0c:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0104d0f:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0104d12:	8b 75 b4             	mov    -0x4c(%ebp),%esi
f0104d15:	29 f0                	sub    %esi,%eax
f0104d17:	39 c2                	cmp    %eax,%edx
f0104d19:	73 bb                	jae    f0104cd6 <debuginfo_eip+0x254>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104d1b:	89 f0                	mov    %esi,%eax
f0104d1d:	01 d0                	add    %edx,%eax
f0104d1f:	89 07                	mov    %eax,(%edi)
f0104d21:	eb b3                	jmp    f0104cd6 <debuginfo_eip+0x254>
f0104d23:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104d26:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0104d29:	eb db                	jmp    f0104d06 <debuginfo_eip+0x284>
			info->eip_fn_narg++;
f0104d2b:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f0104d2f:	39 c3                	cmp    %eax,%ebx
f0104d31:	7e 3f                	jle    f0104d72 <debuginfo_eip+0x2f0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104d33:	0f b6 0a             	movzbl (%edx),%ecx
f0104d36:	83 c0 01             	add    $0x1,%eax
f0104d39:	83 c2 0c             	add    $0xc,%edx
f0104d3c:	80 f9 a0             	cmp    $0xa0,%cl
f0104d3f:	74 ea                	je     f0104d2b <debuginfo_eip+0x2a9>
	return 0;
f0104d41:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d46:	eb 2f                	jmp    f0104d77 <debuginfo_eip+0x2f5>
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_P) < 0) return -1;
f0104d48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d4d:	eb 28                	jmp    f0104d77 <debuginfo_eip+0x2f5>
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
f0104d4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d54:	eb 21                	jmp    f0104d77 <debuginfo_eip+0x2f5>
		return -1;
f0104d56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d5b:	eb 1a                	jmp    f0104d77 <debuginfo_eip+0x2f5>
f0104d5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d62:	eb 13                	jmp    f0104d77 <debuginfo_eip+0x2f5>
		return -1;
f0104d64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d69:	eb 0c                	jmp    f0104d77 <debuginfo_eip+0x2f5>
		return -1;
f0104d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104d70:	eb 05                	jmp    f0104d77 <debuginfo_eip+0x2f5>
	return 0;
f0104d72:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d77:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d7a:	5b                   	pop    %ebx
f0104d7b:	5e                   	pop    %esi
f0104d7c:	5f                   	pop    %edi
f0104d7d:	5d                   	pop    %ebp
f0104d7e:	c3                   	ret    

f0104d7f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104d7f:	55                   	push   %ebp
f0104d80:	89 e5                	mov    %esp,%ebp
f0104d82:	57                   	push   %edi
f0104d83:	56                   	push   %esi
f0104d84:	53                   	push   %ebx
f0104d85:	83 ec 2c             	sub    $0x2c,%esp
f0104d88:	e8 d2 e9 ff ff       	call   f010375f <__x86.get_pc_thunk.cx>
f0104d8d:	81 c1 93 92 08 00    	add    $0x89293,%ecx
f0104d93:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104d96:	89 c7                	mov    %eax,%edi
f0104d98:	89 d6                	mov    %edx,%esi
f0104d9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d9d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104da0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104da3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104da6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104da9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104dae:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0104db1:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104db4:	39 d3                	cmp    %edx,%ebx
f0104db6:	72 09                	jb     f0104dc1 <printnum+0x42>
f0104db8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104dbb:	0f 87 83 00 00 00    	ja     f0104e44 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104dc1:	83 ec 0c             	sub    $0xc,%esp
f0104dc4:	ff 75 18             	pushl  0x18(%ebp)
f0104dc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dca:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104dcd:	53                   	push   %ebx
f0104dce:	ff 75 10             	pushl  0x10(%ebp)
f0104dd1:	83 ec 08             	sub    $0x8,%esp
f0104dd4:	ff 75 dc             	pushl  -0x24(%ebp)
f0104dd7:	ff 75 d8             	pushl  -0x28(%ebp)
f0104dda:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104ddd:	ff 75 d0             	pushl  -0x30(%ebp)
f0104de0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104de3:	e8 18 0a 00 00       	call   f0105800 <__udivdi3>
f0104de8:	83 c4 18             	add    $0x18,%esp
f0104deb:	52                   	push   %edx
f0104dec:	50                   	push   %eax
f0104ded:	89 f2                	mov    %esi,%edx
f0104def:	89 f8                	mov    %edi,%eax
f0104df1:	e8 89 ff ff ff       	call   f0104d7f <printnum>
f0104df6:	83 c4 20             	add    $0x20,%esp
f0104df9:	eb 13                	jmp    f0104e0e <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104dfb:	83 ec 08             	sub    $0x8,%esp
f0104dfe:	56                   	push   %esi
f0104dff:	ff 75 18             	pushl  0x18(%ebp)
f0104e02:	ff d7                	call   *%edi
f0104e04:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104e07:	83 eb 01             	sub    $0x1,%ebx
f0104e0a:	85 db                	test   %ebx,%ebx
f0104e0c:	7f ed                	jg     f0104dfb <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104e0e:	83 ec 08             	sub    $0x8,%esp
f0104e11:	56                   	push   %esi
f0104e12:	83 ec 04             	sub    $0x4,%esp
f0104e15:	ff 75 dc             	pushl  -0x24(%ebp)
f0104e18:	ff 75 d8             	pushl  -0x28(%ebp)
f0104e1b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104e1e:	ff 75 d0             	pushl  -0x30(%ebp)
f0104e21:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104e24:	89 f3                	mov    %esi,%ebx
f0104e26:	e8 f5 0a 00 00       	call   f0105920 <__umoddi3>
f0104e2b:	83 c4 14             	add    $0x14,%esp
f0104e2e:	0f be 84 06 9a 91 f7 	movsbl -0x86e66(%esi,%eax,1),%eax
f0104e35:	ff 
f0104e36:	50                   	push   %eax
f0104e37:	ff d7                	call   *%edi
}
f0104e39:	83 c4 10             	add    $0x10,%esp
f0104e3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e3f:	5b                   	pop    %ebx
f0104e40:	5e                   	pop    %esi
f0104e41:	5f                   	pop    %edi
f0104e42:	5d                   	pop    %ebp
f0104e43:	c3                   	ret    
f0104e44:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104e47:	eb be                	jmp    f0104e07 <printnum+0x88>

f0104e49 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104e49:	55                   	push   %ebp
f0104e4a:	89 e5                	mov    %esp,%ebp
f0104e4c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104e4f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104e53:	8b 10                	mov    (%eax),%edx
f0104e55:	3b 50 04             	cmp    0x4(%eax),%edx
f0104e58:	73 0a                	jae    f0104e64 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104e5a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104e5d:	89 08                	mov    %ecx,(%eax)
f0104e5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e62:	88 02                	mov    %al,(%edx)
}
f0104e64:	5d                   	pop    %ebp
f0104e65:	c3                   	ret    

f0104e66 <printfmt>:
{
f0104e66:	55                   	push   %ebp
f0104e67:	89 e5                	mov    %esp,%ebp
f0104e69:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104e6c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104e6f:	50                   	push   %eax
f0104e70:	ff 75 10             	pushl  0x10(%ebp)
f0104e73:	ff 75 0c             	pushl  0xc(%ebp)
f0104e76:	ff 75 08             	pushl  0x8(%ebp)
f0104e79:	e8 05 00 00 00       	call   f0104e83 <vprintfmt>
}
f0104e7e:	83 c4 10             	add    $0x10,%esp
f0104e81:	c9                   	leave  
f0104e82:	c3                   	ret    

f0104e83 <vprintfmt>:
{
f0104e83:	55                   	push   %ebp
f0104e84:	89 e5                	mov    %esp,%ebp
f0104e86:	57                   	push   %edi
f0104e87:	56                   	push   %esi
f0104e88:	53                   	push   %ebx
f0104e89:	83 ec 2c             	sub    $0x2c,%esp
f0104e8c:	e8 d6 b2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104e91:	81 c3 8f 91 08 00    	add    $0x8918f,%ebx
f0104e97:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e9a:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104e9d:	e9 c3 03 00 00       	jmp    f0105265 <.L35+0x48>
		padc = ' ';
f0104ea2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0104ea6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0104ead:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0104eb4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104ebb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ec0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104ec3:	8d 47 01             	lea    0x1(%edi),%eax
f0104ec6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104ec9:	0f b6 17             	movzbl (%edi),%edx
f0104ecc:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104ecf:	3c 55                	cmp    $0x55,%al
f0104ed1:	0f 87 16 04 00 00    	ja     f01052ed <.L22>
f0104ed7:	0f b6 c0             	movzbl %al,%eax
f0104eda:	89 d9                	mov    %ebx,%ecx
f0104edc:	03 8c 83 24 92 f7 ff 	add    -0x86ddc(%ebx,%eax,4),%ecx
f0104ee3:	ff e1                	jmp    *%ecx

f0104ee5 <.L69>:
f0104ee5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104ee8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0104eec:	eb d5                	jmp    f0104ec3 <vprintfmt+0x40>

f0104eee <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0104eee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0104ef1:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104ef5:	eb cc                	jmp    f0104ec3 <vprintfmt+0x40>

f0104ef7 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0104ef7:	0f b6 d2             	movzbl %dl,%edx
f0104efa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104efd:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0104f02:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104f05:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104f09:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104f0c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104f0f:	83 f9 09             	cmp    $0x9,%ecx
f0104f12:	77 55                	ja     f0104f69 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0104f14:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104f17:	eb e9                	jmp    f0104f02 <.L29+0xb>

f0104f19 <.L26>:
			precision = va_arg(ap, int);
f0104f19:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f1c:	8b 00                	mov    (%eax),%eax
f0104f1e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104f21:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f24:	8d 40 04             	lea    0x4(%eax),%eax
f0104f27:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104f2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104f2d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f31:	79 90                	jns    f0104ec3 <vprintfmt+0x40>
				width = precision, precision = -1;
f0104f33:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104f36:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f39:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0104f40:	eb 81                	jmp    f0104ec3 <vprintfmt+0x40>

f0104f42 <.L27>:
f0104f42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f45:	85 c0                	test   %eax,%eax
f0104f47:	ba 00 00 00 00       	mov    $0x0,%edx
f0104f4c:	0f 49 d0             	cmovns %eax,%edx
f0104f4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104f52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f55:	e9 69 ff ff ff       	jmp    f0104ec3 <vprintfmt+0x40>

f0104f5a <.L23>:
f0104f5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104f5d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104f64:	e9 5a ff ff ff       	jmp    f0104ec3 <vprintfmt+0x40>
f0104f69:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104f6c:	eb bf                	jmp    f0104f2d <.L26+0x14>

f0104f6e <.L33>:
			lflag++;
f0104f6e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104f72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104f75:	e9 49 ff ff ff       	jmp    f0104ec3 <vprintfmt+0x40>

f0104f7a <.L30>:
			putch(va_arg(ap, int), putdat);
f0104f7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f7d:	8d 78 04             	lea    0x4(%eax),%edi
f0104f80:	83 ec 08             	sub    $0x8,%esp
f0104f83:	56                   	push   %esi
f0104f84:	ff 30                	pushl  (%eax)
f0104f86:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104f89:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104f8c:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104f8f:	e9 ce 02 00 00       	jmp    f0105262 <.L35+0x45>

f0104f94 <.L32>:
			err = va_arg(ap, int);
f0104f94:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f97:	8d 78 04             	lea    0x4(%eax),%edi
f0104f9a:	8b 00                	mov    (%eax),%eax
f0104f9c:	99                   	cltd   
f0104f9d:	31 d0                	xor    %edx,%eax
f0104f9f:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104fa1:	83 f8 06             	cmp    $0x6,%eax
f0104fa4:	7f 27                	jg     f0104fcd <.L32+0x39>
f0104fa6:	8b 94 83 f0 20 00 00 	mov    0x20f0(%ebx,%eax,4),%edx
f0104fad:	85 d2                	test   %edx,%edx
f0104faf:	74 1c                	je     f0104fcd <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0104fb1:	52                   	push   %edx
f0104fb2:	8d 83 d9 81 f7 ff    	lea    -0x87e27(%ebx),%eax
f0104fb8:	50                   	push   %eax
f0104fb9:	56                   	push   %esi
f0104fba:	ff 75 08             	pushl  0x8(%ebp)
f0104fbd:	e8 a4 fe ff ff       	call   f0104e66 <printfmt>
f0104fc2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104fc5:	89 7d 14             	mov    %edi,0x14(%ebp)
f0104fc8:	e9 95 02 00 00       	jmp    f0105262 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104fcd:	50                   	push   %eax
f0104fce:	8d 83 b2 91 f7 ff    	lea    -0x86e4e(%ebx),%eax
f0104fd4:	50                   	push   %eax
f0104fd5:	56                   	push   %esi
f0104fd6:	ff 75 08             	pushl  0x8(%ebp)
f0104fd9:	e8 88 fe ff ff       	call   f0104e66 <printfmt>
f0104fde:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104fe1:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104fe4:	e9 79 02 00 00       	jmp    f0105262 <.L35+0x45>

f0104fe9 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104fe9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fec:	83 c0 04             	add    $0x4,%eax
f0104fef:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104ff2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ff5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104ff7:	85 ff                	test   %edi,%edi
f0104ff9:	8d 83 ab 91 f7 ff    	lea    -0x86e55(%ebx),%eax
f0104fff:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0105002:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105006:	0f 8e b5 00 00 00    	jle    f01050c1 <.L36+0xd8>
f010500c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0105010:	75 08                	jne    f010501a <.L36+0x31>
f0105012:	89 75 0c             	mov    %esi,0xc(%ebp)
f0105015:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0105018:	eb 6d                	jmp    f0105087 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010501a:	83 ec 08             	sub    $0x8,%esp
f010501d:	ff 75 cc             	pushl  -0x34(%ebp)
f0105020:	57                   	push   %edi
f0105021:	e8 7e 04 00 00       	call   f01054a4 <strnlen>
f0105026:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105029:	29 c2                	sub    %eax,%edx
f010502b:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010502e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0105031:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0105035:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105038:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010503b:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010503d:	eb 10                	jmp    f010504f <.L36+0x66>
					putch(padc, putdat);
f010503f:	83 ec 08             	sub    $0x8,%esp
f0105042:	56                   	push   %esi
f0105043:	ff 75 e0             	pushl  -0x20(%ebp)
f0105046:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0105049:	83 ef 01             	sub    $0x1,%edi
f010504c:	83 c4 10             	add    $0x10,%esp
f010504f:	85 ff                	test   %edi,%edi
f0105051:	7f ec                	jg     f010503f <.L36+0x56>
f0105053:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0105056:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0105059:	85 d2                	test   %edx,%edx
f010505b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105060:	0f 49 c2             	cmovns %edx,%eax
f0105063:	29 c2                	sub    %eax,%edx
f0105065:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0105068:	89 75 0c             	mov    %esi,0xc(%ebp)
f010506b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010506e:	eb 17                	jmp    f0105087 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0105070:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105074:	75 30                	jne    f01050a6 <.L36+0xbd>
					putch(ch, putdat);
f0105076:	83 ec 08             	sub    $0x8,%esp
f0105079:	ff 75 0c             	pushl  0xc(%ebp)
f010507c:	50                   	push   %eax
f010507d:	ff 55 08             	call   *0x8(%ebp)
f0105080:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105083:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0105087:	83 c7 01             	add    $0x1,%edi
f010508a:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010508e:	0f be c2             	movsbl %dl,%eax
f0105091:	85 c0                	test   %eax,%eax
f0105093:	74 52                	je     f01050e7 <.L36+0xfe>
f0105095:	85 f6                	test   %esi,%esi
f0105097:	78 d7                	js     f0105070 <.L36+0x87>
f0105099:	83 ee 01             	sub    $0x1,%esi
f010509c:	79 d2                	jns    f0105070 <.L36+0x87>
f010509e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050a1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01050a4:	eb 32                	jmp    f01050d8 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01050a6:	0f be d2             	movsbl %dl,%edx
f01050a9:	83 ea 20             	sub    $0x20,%edx
f01050ac:	83 fa 5e             	cmp    $0x5e,%edx
f01050af:	76 c5                	jbe    f0105076 <.L36+0x8d>
					putch('?', putdat);
f01050b1:	83 ec 08             	sub    $0x8,%esp
f01050b4:	ff 75 0c             	pushl  0xc(%ebp)
f01050b7:	6a 3f                	push   $0x3f
f01050b9:	ff 55 08             	call   *0x8(%ebp)
f01050bc:	83 c4 10             	add    $0x10,%esp
f01050bf:	eb c2                	jmp    f0105083 <.L36+0x9a>
f01050c1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01050c4:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01050c7:	eb be                	jmp    f0105087 <.L36+0x9e>
				putch(' ', putdat);
f01050c9:	83 ec 08             	sub    $0x8,%esp
f01050cc:	56                   	push   %esi
f01050cd:	6a 20                	push   $0x20
f01050cf:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01050d2:	83 ef 01             	sub    $0x1,%edi
f01050d5:	83 c4 10             	add    $0x10,%esp
f01050d8:	85 ff                	test   %edi,%edi
f01050da:	7f ed                	jg     f01050c9 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01050dc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01050df:	89 45 14             	mov    %eax,0x14(%ebp)
f01050e2:	e9 7b 01 00 00       	jmp    f0105262 <.L35+0x45>
f01050e7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01050ea:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050ed:	eb e9                	jmp    f01050d8 <.L36+0xef>

f01050ef <.L31>:
f01050ef:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01050f2:	83 f9 01             	cmp    $0x1,%ecx
f01050f5:	7e 40                	jle    f0105137 <.L31+0x48>
		return va_arg(*ap, long long);
f01050f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01050fa:	8b 50 04             	mov    0x4(%eax),%edx
f01050fd:	8b 00                	mov    (%eax),%eax
f01050ff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105102:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105105:	8b 45 14             	mov    0x14(%ebp),%eax
f0105108:	8d 40 08             	lea    0x8(%eax),%eax
f010510b:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010510e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105112:	79 55                	jns    f0105169 <.L31+0x7a>
				putch('-', putdat);
f0105114:	83 ec 08             	sub    $0x8,%esp
f0105117:	56                   	push   %esi
f0105118:	6a 2d                	push   $0x2d
f010511a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010511d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105120:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0105123:	f7 da                	neg    %edx
f0105125:	83 d1 00             	adc    $0x0,%ecx
f0105128:	f7 d9                	neg    %ecx
f010512a:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010512d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105132:	e9 10 01 00 00       	jmp    f0105247 <.L35+0x2a>
	else if (lflag)
f0105137:	85 c9                	test   %ecx,%ecx
f0105139:	75 17                	jne    f0105152 <.L31+0x63>
		return va_arg(*ap, int);
f010513b:	8b 45 14             	mov    0x14(%ebp),%eax
f010513e:	8b 00                	mov    (%eax),%eax
f0105140:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105143:	99                   	cltd   
f0105144:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105147:	8b 45 14             	mov    0x14(%ebp),%eax
f010514a:	8d 40 04             	lea    0x4(%eax),%eax
f010514d:	89 45 14             	mov    %eax,0x14(%ebp)
f0105150:	eb bc                	jmp    f010510e <.L31+0x1f>
		return va_arg(*ap, long);
f0105152:	8b 45 14             	mov    0x14(%ebp),%eax
f0105155:	8b 00                	mov    (%eax),%eax
f0105157:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010515a:	99                   	cltd   
f010515b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010515e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105161:	8d 40 04             	lea    0x4(%eax),%eax
f0105164:	89 45 14             	mov    %eax,0x14(%ebp)
f0105167:	eb a5                	jmp    f010510e <.L31+0x1f>
			num = getint(&ap, lflag);
f0105169:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010516c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010516f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105174:	e9 ce 00 00 00       	jmp    f0105247 <.L35+0x2a>

f0105179 <.L37>:
f0105179:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010517c:	83 f9 01             	cmp    $0x1,%ecx
f010517f:	7e 18                	jle    f0105199 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0105181:	8b 45 14             	mov    0x14(%ebp),%eax
f0105184:	8b 10                	mov    (%eax),%edx
f0105186:	8b 48 04             	mov    0x4(%eax),%ecx
f0105189:	8d 40 08             	lea    0x8(%eax),%eax
f010518c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010518f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105194:	e9 ae 00 00 00       	jmp    f0105247 <.L35+0x2a>
	else if (lflag)
f0105199:	85 c9                	test   %ecx,%ecx
f010519b:	75 1a                	jne    f01051b7 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f010519d:	8b 45 14             	mov    0x14(%ebp),%eax
f01051a0:	8b 10                	mov    (%eax),%edx
f01051a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051a7:	8d 40 04             	lea    0x4(%eax),%eax
f01051aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01051ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01051b2:	e9 90 00 00 00       	jmp    f0105247 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01051b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ba:	8b 10                	mov    (%eax),%edx
f01051bc:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051c1:	8d 40 04             	lea    0x4(%eax),%eax
f01051c4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01051c7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01051cc:	eb 79                	jmp    f0105247 <.L35+0x2a>

f01051ce <.L34>:
f01051ce:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01051d1:	83 f9 01             	cmp    $0x1,%ecx
f01051d4:	7e 15                	jle    f01051eb <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01051d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01051d9:	8b 10                	mov    (%eax),%edx
f01051db:	8b 48 04             	mov    0x4(%eax),%ecx
f01051de:	8d 40 08             	lea    0x8(%eax),%eax
f01051e1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01051e4:	b8 08 00 00 00       	mov    $0x8,%eax
f01051e9:	eb 5c                	jmp    f0105247 <.L35+0x2a>
	else if (lflag)
f01051eb:	85 c9                	test   %ecx,%ecx
f01051ed:	75 17                	jne    f0105206 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f01051ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01051f2:	8b 10                	mov    (%eax),%edx
f01051f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01051f9:	8d 40 04             	lea    0x4(%eax),%eax
f01051fc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01051ff:	b8 08 00 00 00       	mov    $0x8,%eax
f0105204:	eb 41                	jmp    f0105247 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0105206:	8b 45 14             	mov    0x14(%ebp),%eax
f0105209:	8b 10                	mov    (%eax),%edx
f010520b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105210:	8d 40 04             	lea    0x4(%eax),%eax
f0105213:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105216:	b8 08 00 00 00       	mov    $0x8,%eax
f010521b:	eb 2a                	jmp    f0105247 <.L35+0x2a>

f010521d <.L35>:
			putch('0', putdat);
f010521d:	83 ec 08             	sub    $0x8,%esp
f0105220:	56                   	push   %esi
f0105221:	6a 30                	push   $0x30
f0105223:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105226:	83 c4 08             	add    $0x8,%esp
f0105229:	56                   	push   %esi
f010522a:	6a 78                	push   $0x78
f010522c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010522f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105232:	8b 10                	mov    (%eax),%edx
f0105234:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0105239:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010523c:	8d 40 04             	lea    0x4(%eax),%eax
f010523f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105242:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105247:	83 ec 0c             	sub    $0xc,%esp
f010524a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010524e:	57                   	push   %edi
f010524f:	ff 75 e0             	pushl  -0x20(%ebp)
f0105252:	50                   	push   %eax
f0105253:	51                   	push   %ecx
f0105254:	52                   	push   %edx
f0105255:	89 f2                	mov    %esi,%edx
f0105257:	8b 45 08             	mov    0x8(%ebp),%eax
f010525a:	e8 20 fb ff ff       	call   f0104d7f <printnum>
			break;
f010525f:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0105262:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105265:	83 c7 01             	add    $0x1,%edi
f0105268:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010526c:	83 f8 25             	cmp    $0x25,%eax
f010526f:	0f 84 2d fc ff ff    	je     f0104ea2 <vprintfmt+0x1f>
			if (ch == '\0')
f0105275:	85 c0                	test   %eax,%eax
f0105277:	0f 84 91 00 00 00    	je     f010530e <.L22+0x21>
			putch(ch, putdat);
f010527d:	83 ec 08             	sub    $0x8,%esp
f0105280:	56                   	push   %esi
f0105281:	50                   	push   %eax
f0105282:	ff 55 08             	call   *0x8(%ebp)
f0105285:	83 c4 10             	add    $0x10,%esp
f0105288:	eb db                	jmp    f0105265 <.L35+0x48>

f010528a <.L38>:
f010528a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010528d:	83 f9 01             	cmp    $0x1,%ecx
f0105290:	7e 15                	jle    f01052a7 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0105292:	8b 45 14             	mov    0x14(%ebp),%eax
f0105295:	8b 10                	mov    (%eax),%edx
f0105297:	8b 48 04             	mov    0x4(%eax),%ecx
f010529a:	8d 40 08             	lea    0x8(%eax),%eax
f010529d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052a0:	b8 10 00 00 00       	mov    $0x10,%eax
f01052a5:	eb a0                	jmp    f0105247 <.L35+0x2a>
	else if (lflag)
f01052a7:	85 c9                	test   %ecx,%ecx
f01052a9:	75 17                	jne    f01052c2 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01052ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01052ae:	8b 10                	mov    (%eax),%edx
f01052b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01052b5:	8d 40 04             	lea    0x4(%eax),%eax
f01052b8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052bb:	b8 10 00 00 00       	mov    $0x10,%eax
f01052c0:	eb 85                	jmp    f0105247 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01052c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01052c5:	8b 10                	mov    (%eax),%edx
f01052c7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01052cc:	8d 40 04             	lea    0x4(%eax),%eax
f01052cf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01052d2:	b8 10 00 00 00       	mov    $0x10,%eax
f01052d7:	e9 6b ff ff ff       	jmp    f0105247 <.L35+0x2a>

f01052dc <.L25>:
			putch(ch, putdat);
f01052dc:	83 ec 08             	sub    $0x8,%esp
f01052df:	56                   	push   %esi
f01052e0:	6a 25                	push   $0x25
f01052e2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01052e5:	83 c4 10             	add    $0x10,%esp
f01052e8:	e9 75 ff ff ff       	jmp    f0105262 <.L35+0x45>

f01052ed <.L22>:
			putch('%', putdat);
f01052ed:	83 ec 08             	sub    $0x8,%esp
f01052f0:	56                   	push   %esi
f01052f1:	6a 25                	push   $0x25
f01052f3:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01052f6:	83 c4 10             	add    $0x10,%esp
f01052f9:	89 f8                	mov    %edi,%eax
f01052fb:	eb 03                	jmp    f0105300 <.L22+0x13>
f01052fd:	83 e8 01             	sub    $0x1,%eax
f0105300:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0105304:	75 f7                	jne    f01052fd <.L22+0x10>
f0105306:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105309:	e9 54 ff ff ff       	jmp    f0105262 <.L35+0x45>
}
f010530e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105311:	5b                   	pop    %ebx
f0105312:	5e                   	pop    %esi
f0105313:	5f                   	pop    %edi
f0105314:	5d                   	pop    %ebp
f0105315:	c3                   	ret    

f0105316 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105316:	55                   	push   %ebp
f0105317:	89 e5                	mov    %esp,%ebp
f0105319:	53                   	push   %ebx
f010531a:	83 ec 14             	sub    $0x14,%esp
f010531d:	e8 45 ae ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0105322:	81 c3 fe 8c 08 00    	add    $0x88cfe,%ebx
f0105328:	8b 45 08             	mov    0x8(%ebp),%eax
f010532b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010532e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105331:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105335:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105338:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010533f:	85 c0                	test   %eax,%eax
f0105341:	74 2b                	je     f010536e <vsnprintf+0x58>
f0105343:	85 d2                	test   %edx,%edx
f0105345:	7e 27                	jle    f010536e <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105347:	ff 75 14             	pushl  0x14(%ebp)
f010534a:	ff 75 10             	pushl  0x10(%ebp)
f010534d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105350:	50                   	push   %eax
f0105351:	8d 83 29 6e f7 ff    	lea    -0x891d7(%ebx),%eax
f0105357:	50                   	push   %eax
f0105358:	e8 26 fb ff ff       	call   f0104e83 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010535d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105360:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105363:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105366:	83 c4 10             	add    $0x10,%esp
}
f0105369:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010536c:	c9                   	leave  
f010536d:	c3                   	ret    
		return -E_INVAL;
f010536e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105373:	eb f4                	jmp    f0105369 <vsnprintf+0x53>

f0105375 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105375:	55                   	push   %ebp
f0105376:	89 e5                	mov    %esp,%ebp
f0105378:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010537b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010537e:	50                   	push   %eax
f010537f:	ff 75 10             	pushl  0x10(%ebp)
f0105382:	ff 75 0c             	pushl  0xc(%ebp)
f0105385:	ff 75 08             	pushl  0x8(%ebp)
f0105388:	e8 89 ff ff ff       	call   f0105316 <vsnprintf>
	va_end(ap);

	return rc;
}
f010538d:	c9                   	leave  
f010538e:	c3                   	ret    

f010538f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010538f:	55                   	push   %ebp
f0105390:	89 e5                	mov    %esp,%ebp
f0105392:	57                   	push   %edi
f0105393:	56                   	push   %esi
f0105394:	53                   	push   %ebx
f0105395:	83 ec 1c             	sub    $0x1c,%esp
f0105398:	e8 ca ad ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010539d:	81 c3 83 8c 08 00    	add    $0x88c83,%ebx
f01053a3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01053a6:	85 c0                	test   %eax,%eax
f01053a8:	74 13                	je     f01053bd <readline+0x2e>
		cprintf("%s", prompt);
f01053aa:	83 ec 08             	sub    $0x8,%esp
f01053ad:	50                   	push   %eax
f01053ae:	8d 83 d9 81 f7 ff    	lea    -0x87e27(%ebx),%eax
f01053b4:	50                   	push   %eax
f01053b5:	e8 b8 eb ff ff       	call   f0103f72 <cprintf>
f01053ba:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01053bd:	83 ec 0c             	sub    $0xc,%esp
f01053c0:	6a 00                	push   $0x0
f01053c2:	e8 38 b3 ff ff       	call   f01006ff <iscons>
f01053c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01053ca:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01053cd:	bf 00 00 00 00       	mov    $0x0,%edi
f01053d2:	eb 46                	jmp    f010541a <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01053d4:	83 ec 08             	sub    $0x8,%esp
f01053d7:	50                   	push   %eax
f01053d8:	8d 83 7c 93 f7 ff    	lea    -0x86c84(%ebx),%eax
f01053de:	50                   	push   %eax
f01053df:	e8 8e eb ff ff       	call   f0103f72 <cprintf>
			return NULL;
f01053e4:	83 c4 10             	add    $0x10,%esp
f01053e7:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01053ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01053ef:	5b                   	pop    %ebx
f01053f0:	5e                   	pop    %esi
f01053f1:	5f                   	pop    %edi
f01053f2:	5d                   	pop    %ebp
f01053f3:	c3                   	ret    
			if (echoing)
f01053f4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01053f8:	75 05                	jne    f01053ff <readline+0x70>
			i--;
f01053fa:	83 ef 01             	sub    $0x1,%edi
f01053fd:	eb 1b                	jmp    f010541a <readline+0x8b>
				cputchar('\b');
f01053ff:	83 ec 0c             	sub    $0xc,%esp
f0105402:	6a 08                	push   $0x8
f0105404:	e8 d5 b2 ff ff       	call   f01006de <cputchar>
f0105409:	83 c4 10             	add    $0x10,%esp
f010540c:	eb ec                	jmp    f01053fa <readline+0x6b>
			buf[i++] = c;
f010540e:	89 f0                	mov    %esi,%eax
f0105410:	88 84 3b 20 2c 00 00 	mov    %al,0x2c20(%ebx,%edi,1)
f0105417:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010541a:	e8 cf b2 ff ff       	call   f01006ee <getchar>
f010541f:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0105421:	85 c0                	test   %eax,%eax
f0105423:	78 af                	js     f01053d4 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105425:	83 f8 08             	cmp    $0x8,%eax
f0105428:	0f 94 c2             	sete   %dl
f010542b:	83 f8 7f             	cmp    $0x7f,%eax
f010542e:	0f 94 c0             	sete   %al
f0105431:	08 c2                	or     %al,%dl
f0105433:	74 04                	je     f0105439 <readline+0xaa>
f0105435:	85 ff                	test   %edi,%edi
f0105437:	7f bb                	jg     f01053f4 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105439:	83 fe 1f             	cmp    $0x1f,%esi
f010543c:	7e 1c                	jle    f010545a <readline+0xcb>
f010543e:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0105444:	7f 14                	jg     f010545a <readline+0xcb>
			if (echoing)
f0105446:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010544a:	74 c2                	je     f010540e <readline+0x7f>
				cputchar(c);
f010544c:	83 ec 0c             	sub    $0xc,%esp
f010544f:	56                   	push   %esi
f0105450:	e8 89 b2 ff ff       	call   f01006de <cputchar>
f0105455:	83 c4 10             	add    $0x10,%esp
f0105458:	eb b4                	jmp    f010540e <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010545a:	83 fe 0a             	cmp    $0xa,%esi
f010545d:	74 05                	je     f0105464 <readline+0xd5>
f010545f:	83 fe 0d             	cmp    $0xd,%esi
f0105462:	75 b6                	jne    f010541a <readline+0x8b>
			if (echoing)
f0105464:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105468:	75 13                	jne    f010547d <readline+0xee>
			buf[i] = 0;
f010546a:	c6 84 3b 20 2c 00 00 	movb   $0x0,0x2c20(%ebx,%edi,1)
f0105471:	00 
			return buf;
f0105472:	8d 83 20 2c 00 00    	lea    0x2c20(%ebx),%eax
f0105478:	e9 6f ff ff ff       	jmp    f01053ec <readline+0x5d>
				cputchar('\n');
f010547d:	83 ec 0c             	sub    $0xc,%esp
f0105480:	6a 0a                	push   $0xa
f0105482:	e8 57 b2 ff ff       	call   f01006de <cputchar>
f0105487:	83 c4 10             	add    $0x10,%esp
f010548a:	eb de                	jmp    f010546a <readline+0xdb>

f010548c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010548c:	55                   	push   %ebp
f010548d:	89 e5                	mov    %esp,%ebp
f010548f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105492:	b8 00 00 00 00       	mov    $0x0,%eax
f0105497:	eb 03                	jmp    f010549c <strlen+0x10>
		n++;
f0105499:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010549c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01054a0:	75 f7                	jne    f0105499 <strlen+0xd>
	return n;
}
f01054a2:	5d                   	pop    %ebp
f01054a3:	c3                   	ret    

f01054a4 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01054a4:	55                   	push   %ebp
f01054a5:	89 e5                	mov    %esp,%ebp
f01054a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054aa:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01054b2:	eb 03                	jmp    f01054b7 <strnlen+0x13>
		n++;
f01054b4:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01054b7:	39 d0                	cmp    %edx,%eax
f01054b9:	74 06                	je     f01054c1 <strnlen+0x1d>
f01054bb:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01054bf:	75 f3                	jne    f01054b4 <strnlen+0x10>
	return n;
}
f01054c1:	5d                   	pop    %ebp
f01054c2:	c3                   	ret    

f01054c3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01054c3:	55                   	push   %ebp
f01054c4:	89 e5                	mov    %esp,%ebp
f01054c6:	53                   	push   %ebx
f01054c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01054ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01054cd:	89 c2                	mov    %eax,%edx
f01054cf:	83 c1 01             	add    $0x1,%ecx
f01054d2:	83 c2 01             	add    $0x1,%edx
f01054d5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01054d9:	88 5a ff             	mov    %bl,-0x1(%edx)
f01054dc:	84 db                	test   %bl,%bl
f01054de:	75 ef                	jne    f01054cf <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01054e0:	5b                   	pop    %ebx
f01054e1:	5d                   	pop    %ebp
f01054e2:	c3                   	ret    

f01054e3 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01054e3:	55                   	push   %ebp
f01054e4:	89 e5                	mov    %esp,%ebp
f01054e6:	53                   	push   %ebx
f01054e7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01054ea:	53                   	push   %ebx
f01054eb:	e8 9c ff ff ff       	call   f010548c <strlen>
f01054f0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01054f3:	ff 75 0c             	pushl  0xc(%ebp)
f01054f6:	01 d8                	add    %ebx,%eax
f01054f8:	50                   	push   %eax
f01054f9:	e8 c5 ff ff ff       	call   f01054c3 <strcpy>
	return dst;
}
f01054fe:	89 d8                	mov    %ebx,%eax
f0105500:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105503:	c9                   	leave  
f0105504:	c3                   	ret    

f0105505 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105505:	55                   	push   %ebp
f0105506:	89 e5                	mov    %esp,%ebp
f0105508:	56                   	push   %esi
f0105509:	53                   	push   %ebx
f010550a:	8b 75 08             	mov    0x8(%ebp),%esi
f010550d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105510:	89 f3                	mov    %esi,%ebx
f0105512:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105515:	89 f2                	mov    %esi,%edx
f0105517:	eb 0f                	jmp    f0105528 <strncpy+0x23>
		*dst++ = *src;
f0105519:	83 c2 01             	add    $0x1,%edx
f010551c:	0f b6 01             	movzbl (%ecx),%eax
f010551f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105522:	80 39 01             	cmpb   $0x1,(%ecx)
f0105525:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0105528:	39 da                	cmp    %ebx,%edx
f010552a:	75 ed                	jne    f0105519 <strncpy+0x14>
	}
	return ret;
}
f010552c:	89 f0                	mov    %esi,%eax
f010552e:	5b                   	pop    %ebx
f010552f:	5e                   	pop    %esi
f0105530:	5d                   	pop    %ebp
f0105531:	c3                   	ret    

f0105532 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105532:	55                   	push   %ebp
f0105533:	89 e5                	mov    %esp,%ebp
f0105535:	56                   	push   %esi
f0105536:	53                   	push   %ebx
f0105537:	8b 75 08             	mov    0x8(%ebp),%esi
f010553a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010553d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105540:	89 f0                	mov    %esi,%eax
f0105542:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105546:	85 c9                	test   %ecx,%ecx
f0105548:	75 0b                	jne    f0105555 <strlcpy+0x23>
f010554a:	eb 17                	jmp    f0105563 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010554c:	83 c2 01             	add    $0x1,%edx
f010554f:	83 c0 01             	add    $0x1,%eax
f0105552:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0105555:	39 d8                	cmp    %ebx,%eax
f0105557:	74 07                	je     f0105560 <strlcpy+0x2e>
f0105559:	0f b6 0a             	movzbl (%edx),%ecx
f010555c:	84 c9                	test   %cl,%cl
f010555e:	75 ec                	jne    f010554c <strlcpy+0x1a>
		*dst = '\0';
f0105560:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105563:	29 f0                	sub    %esi,%eax
}
f0105565:	5b                   	pop    %ebx
f0105566:	5e                   	pop    %esi
f0105567:	5d                   	pop    %ebp
f0105568:	c3                   	ret    

f0105569 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105569:	55                   	push   %ebp
f010556a:	89 e5                	mov    %esp,%ebp
f010556c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010556f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105572:	eb 06                	jmp    f010557a <strcmp+0x11>
		p++, q++;
f0105574:	83 c1 01             	add    $0x1,%ecx
f0105577:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010557a:	0f b6 01             	movzbl (%ecx),%eax
f010557d:	84 c0                	test   %al,%al
f010557f:	74 04                	je     f0105585 <strcmp+0x1c>
f0105581:	3a 02                	cmp    (%edx),%al
f0105583:	74 ef                	je     f0105574 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105585:	0f b6 c0             	movzbl %al,%eax
f0105588:	0f b6 12             	movzbl (%edx),%edx
f010558b:	29 d0                	sub    %edx,%eax
}
f010558d:	5d                   	pop    %ebp
f010558e:	c3                   	ret    

f010558f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010558f:	55                   	push   %ebp
f0105590:	89 e5                	mov    %esp,%ebp
f0105592:	53                   	push   %ebx
f0105593:	8b 45 08             	mov    0x8(%ebp),%eax
f0105596:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105599:	89 c3                	mov    %eax,%ebx
f010559b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010559e:	eb 06                	jmp    f01055a6 <strncmp+0x17>
		n--, p++, q++;
f01055a0:	83 c0 01             	add    $0x1,%eax
f01055a3:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01055a6:	39 d8                	cmp    %ebx,%eax
f01055a8:	74 16                	je     f01055c0 <strncmp+0x31>
f01055aa:	0f b6 08             	movzbl (%eax),%ecx
f01055ad:	84 c9                	test   %cl,%cl
f01055af:	74 04                	je     f01055b5 <strncmp+0x26>
f01055b1:	3a 0a                	cmp    (%edx),%cl
f01055b3:	74 eb                	je     f01055a0 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01055b5:	0f b6 00             	movzbl (%eax),%eax
f01055b8:	0f b6 12             	movzbl (%edx),%edx
f01055bb:	29 d0                	sub    %edx,%eax
}
f01055bd:	5b                   	pop    %ebx
f01055be:	5d                   	pop    %ebp
f01055bf:	c3                   	ret    
		return 0;
f01055c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01055c5:	eb f6                	jmp    f01055bd <strncmp+0x2e>

f01055c7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01055c7:	55                   	push   %ebp
f01055c8:	89 e5                	mov    %esp,%ebp
f01055ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01055cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01055d1:	0f b6 10             	movzbl (%eax),%edx
f01055d4:	84 d2                	test   %dl,%dl
f01055d6:	74 09                	je     f01055e1 <strchr+0x1a>
		if (*s == c)
f01055d8:	38 ca                	cmp    %cl,%dl
f01055da:	74 0a                	je     f01055e6 <strchr+0x1f>
	for (; *s; s++)
f01055dc:	83 c0 01             	add    $0x1,%eax
f01055df:	eb f0                	jmp    f01055d1 <strchr+0xa>
			return (char *) s;
	return 0;
f01055e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01055e6:	5d                   	pop    %ebp
f01055e7:	c3                   	ret    

f01055e8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01055e8:	55                   	push   %ebp
f01055e9:	89 e5                	mov    %esp,%ebp
f01055eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01055ee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01055f2:	eb 03                	jmp    f01055f7 <strfind+0xf>
f01055f4:	83 c0 01             	add    $0x1,%eax
f01055f7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01055fa:	38 ca                	cmp    %cl,%dl
f01055fc:	74 04                	je     f0105602 <strfind+0x1a>
f01055fe:	84 d2                	test   %dl,%dl
f0105600:	75 f2                	jne    f01055f4 <strfind+0xc>
			break;
	return (char *) s;
}
f0105602:	5d                   	pop    %ebp
f0105603:	c3                   	ret    

f0105604 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105604:	55                   	push   %ebp
f0105605:	89 e5                	mov    %esp,%ebp
f0105607:	57                   	push   %edi
f0105608:	56                   	push   %esi
f0105609:	53                   	push   %ebx
f010560a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010560d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105610:	85 c9                	test   %ecx,%ecx
f0105612:	74 13                	je     f0105627 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105614:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010561a:	75 05                	jne    f0105621 <memset+0x1d>
f010561c:	f6 c1 03             	test   $0x3,%cl
f010561f:	74 0d                	je     f010562e <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105621:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105624:	fc                   	cld    
f0105625:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105627:	89 f8                	mov    %edi,%eax
f0105629:	5b                   	pop    %ebx
f010562a:	5e                   	pop    %esi
f010562b:	5f                   	pop    %edi
f010562c:	5d                   	pop    %ebp
f010562d:	c3                   	ret    
		c &= 0xFF;
f010562e:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105632:	89 d3                	mov    %edx,%ebx
f0105634:	c1 e3 08             	shl    $0x8,%ebx
f0105637:	89 d0                	mov    %edx,%eax
f0105639:	c1 e0 18             	shl    $0x18,%eax
f010563c:	89 d6                	mov    %edx,%esi
f010563e:	c1 e6 10             	shl    $0x10,%esi
f0105641:	09 f0                	or     %esi,%eax
f0105643:	09 c2                	or     %eax,%edx
f0105645:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0105647:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010564a:	89 d0                	mov    %edx,%eax
f010564c:	fc                   	cld    
f010564d:	f3 ab                	rep stos %eax,%es:(%edi)
f010564f:	eb d6                	jmp    f0105627 <memset+0x23>

f0105651 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105651:	55                   	push   %ebp
f0105652:	89 e5                	mov    %esp,%ebp
f0105654:	57                   	push   %edi
f0105655:	56                   	push   %esi
f0105656:	8b 45 08             	mov    0x8(%ebp),%eax
f0105659:	8b 75 0c             	mov    0xc(%ebp),%esi
f010565c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010565f:	39 c6                	cmp    %eax,%esi
f0105661:	73 35                	jae    f0105698 <memmove+0x47>
f0105663:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105666:	39 c2                	cmp    %eax,%edx
f0105668:	76 2e                	jbe    f0105698 <memmove+0x47>
		s += n;
		d += n;
f010566a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010566d:	89 d6                	mov    %edx,%esi
f010566f:	09 fe                	or     %edi,%esi
f0105671:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105677:	74 0c                	je     f0105685 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105679:	83 ef 01             	sub    $0x1,%edi
f010567c:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010567f:	fd                   	std    
f0105680:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105682:	fc                   	cld    
f0105683:	eb 21                	jmp    f01056a6 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105685:	f6 c1 03             	test   $0x3,%cl
f0105688:	75 ef                	jne    f0105679 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010568a:	83 ef 04             	sub    $0x4,%edi
f010568d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105690:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105693:	fd                   	std    
f0105694:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105696:	eb ea                	jmp    f0105682 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105698:	89 f2                	mov    %esi,%edx
f010569a:	09 c2                	or     %eax,%edx
f010569c:	f6 c2 03             	test   $0x3,%dl
f010569f:	74 09                	je     f01056aa <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01056a1:	89 c7                	mov    %eax,%edi
f01056a3:	fc                   	cld    
f01056a4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01056a6:	5e                   	pop    %esi
f01056a7:	5f                   	pop    %edi
f01056a8:	5d                   	pop    %ebp
f01056a9:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056aa:	f6 c1 03             	test   $0x3,%cl
f01056ad:	75 f2                	jne    f01056a1 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01056af:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01056b2:	89 c7                	mov    %eax,%edi
f01056b4:	fc                   	cld    
f01056b5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01056b7:	eb ed                	jmp    f01056a6 <memmove+0x55>

f01056b9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01056b9:	55                   	push   %ebp
f01056ba:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01056bc:	ff 75 10             	pushl  0x10(%ebp)
f01056bf:	ff 75 0c             	pushl  0xc(%ebp)
f01056c2:	ff 75 08             	pushl  0x8(%ebp)
f01056c5:	e8 87 ff ff ff       	call   f0105651 <memmove>
}
f01056ca:	c9                   	leave  
f01056cb:	c3                   	ret    

f01056cc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01056cc:	55                   	push   %ebp
f01056cd:	89 e5                	mov    %esp,%ebp
f01056cf:	56                   	push   %esi
f01056d0:	53                   	push   %ebx
f01056d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01056d4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01056d7:	89 c6                	mov    %eax,%esi
f01056d9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01056dc:	39 f0                	cmp    %esi,%eax
f01056de:	74 1c                	je     f01056fc <memcmp+0x30>
		if (*s1 != *s2)
f01056e0:	0f b6 08             	movzbl (%eax),%ecx
f01056e3:	0f b6 1a             	movzbl (%edx),%ebx
f01056e6:	38 d9                	cmp    %bl,%cl
f01056e8:	75 08                	jne    f01056f2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01056ea:	83 c0 01             	add    $0x1,%eax
f01056ed:	83 c2 01             	add    $0x1,%edx
f01056f0:	eb ea                	jmp    f01056dc <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01056f2:	0f b6 c1             	movzbl %cl,%eax
f01056f5:	0f b6 db             	movzbl %bl,%ebx
f01056f8:	29 d8                	sub    %ebx,%eax
f01056fa:	eb 05                	jmp    f0105701 <memcmp+0x35>
	}

	return 0;
f01056fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105701:	5b                   	pop    %ebx
f0105702:	5e                   	pop    %esi
f0105703:	5d                   	pop    %ebp
f0105704:	c3                   	ret    

f0105705 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105705:	55                   	push   %ebp
f0105706:	89 e5                	mov    %esp,%ebp
f0105708:	8b 45 08             	mov    0x8(%ebp),%eax
f010570b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010570e:	89 c2                	mov    %eax,%edx
f0105710:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105713:	39 d0                	cmp    %edx,%eax
f0105715:	73 09                	jae    f0105720 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105717:	38 08                	cmp    %cl,(%eax)
f0105719:	74 05                	je     f0105720 <memfind+0x1b>
	for (; s < ends; s++)
f010571b:	83 c0 01             	add    $0x1,%eax
f010571e:	eb f3                	jmp    f0105713 <memfind+0xe>
			break;
	return (void *) s;
}
f0105720:	5d                   	pop    %ebp
f0105721:	c3                   	ret    

f0105722 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105722:	55                   	push   %ebp
f0105723:	89 e5                	mov    %esp,%ebp
f0105725:	57                   	push   %edi
f0105726:	56                   	push   %esi
f0105727:	53                   	push   %ebx
f0105728:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010572b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010572e:	eb 03                	jmp    f0105733 <strtol+0x11>
		s++;
f0105730:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105733:	0f b6 01             	movzbl (%ecx),%eax
f0105736:	3c 20                	cmp    $0x20,%al
f0105738:	74 f6                	je     f0105730 <strtol+0xe>
f010573a:	3c 09                	cmp    $0x9,%al
f010573c:	74 f2                	je     f0105730 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010573e:	3c 2b                	cmp    $0x2b,%al
f0105740:	74 2e                	je     f0105770 <strtol+0x4e>
	int neg = 0;
f0105742:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105747:	3c 2d                	cmp    $0x2d,%al
f0105749:	74 2f                	je     f010577a <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010574b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105751:	75 05                	jne    f0105758 <strtol+0x36>
f0105753:	80 39 30             	cmpb   $0x30,(%ecx)
f0105756:	74 2c                	je     f0105784 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105758:	85 db                	test   %ebx,%ebx
f010575a:	75 0a                	jne    f0105766 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010575c:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0105761:	80 39 30             	cmpb   $0x30,(%ecx)
f0105764:	74 28                	je     f010578e <strtol+0x6c>
		base = 10;
f0105766:	b8 00 00 00 00       	mov    $0x0,%eax
f010576b:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010576e:	eb 50                	jmp    f01057c0 <strtol+0x9e>
		s++;
f0105770:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105773:	bf 00 00 00 00       	mov    $0x0,%edi
f0105778:	eb d1                	jmp    f010574b <strtol+0x29>
		s++, neg = 1;
f010577a:	83 c1 01             	add    $0x1,%ecx
f010577d:	bf 01 00 00 00       	mov    $0x1,%edi
f0105782:	eb c7                	jmp    f010574b <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105784:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105788:	74 0e                	je     f0105798 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010578a:	85 db                	test   %ebx,%ebx
f010578c:	75 d8                	jne    f0105766 <strtol+0x44>
		s++, base = 8;
f010578e:	83 c1 01             	add    $0x1,%ecx
f0105791:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105796:	eb ce                	jmp    f0105766 <strtol+0x44>
		s += 2, base = 16;
f0105798:	83 c1 02             	add    $0x2,%ecx
f010579b:	bb 10 00 00 00       	mov    $0x10,%ebx
f01057a0:	eb c4                	jmp    f0105766 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01057a2:	8d 72 9f             	lea    -0x61(%edx),%esi
f01057a5:	89 f3                	mov    %esi,%ebx
f01057a7:	80 fb 19             	cmp    $0x19,%bl
f01057aa:	77 29                	ja     f01057d5 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01057ac:	0f be d2             	movsbl %dl,%edx
f01057af:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01057b2:	3b 55 10             	cmp    0x10(%ebp),%edx
f01057b5:	7d 30                	jge    f01057e7 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01057b7:	83 c1 01             	add    $0x1,%ecx
f01057ba:	0f af 45 10          	imul   0x10(%ebp),%eax
f01057be:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01057c0:	0f b6 11             	movzbl (%ecx),%edx
f01057c3:	8d 72 d0             	lea    -0x30(%edx),%esi
f01057c6:	89 f3                	mov    %esi,%ebx
f01057c8:	80 fb 09             	cmp    $0x9,%bl
f01057cb:	77 d5                	ja     f01057a2 <strtol+0x80>
			dig = *s - '0';
f01057cd:	0f be d2             	movsbl %dl,%edx
f01057d0:	83 ea 30             	sub    $0x30,%edx
f01057d3:	eb dd                	jmp    f01057b2 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01057d5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01057d8:	89 f3                	mov    %esi,%ebx
f01057da:	80 fb 19             	cmp    $0x19,%bl
f01057dd:	77 08                	ja     f01057e7 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01057df:	0f be d2             	movsbl %dl,%edx
f01057e2:	83 ea 37             	sub    $0x37,%edx
f01057e5:	eb cb                	jmp    f01057b2 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01057e7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01057eb:	74 05                	je     f01057f2 <strtol+0xd0>
		*endptr = (char *) s;
f01057ed:	8b 75 0c             	mov    0xc(%ebp),%esi
f01057f0:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01057f2:	89 c2                	mov    %eax,%edx
f01057f4:	f7 da                	neg    %edx
f01057f6:	85 ff                	test   %edi,%edi
f01057f8:	0f 45 c2             	cmovne %edx,%eax
}
f01057fb:	5b                   	pop    %ebx
f01057fc:	5e                   	pop    %esi
f01057fd:	5f                   	pop    %edi
f01057fe:	5d                   	pop    %ebp
f01057ff:	c3                   	ret    

f0105800 <__udivdi3>:
f0105800:	55                   	push   %ebp
f0105801:	57                   	push   %edi
f0105802:	56                   	push   %esi
f0105803:	53                   	push   %ebx
f0105804:	83 ec 1c             	sub    $0x1c,%esp
f0105807:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010580b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010580f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105813:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0105817:	85 d2                	test   %edx,%edx
f0105819:	75 35                	jne    f0105850 <__udivdi3+0x50>
f010581b:	39 f3                	cmp    %esi,%ebx
f010581d:	0f 87 bd 00 00 00    	ja     f01058e0 <__udivdi3+0xe0>
f0105823:	85 db                	test   %ebx,%ebx
f0105825:	89 d9                	mov    %ebx,%ecx
f0105827:	75 0b                	jne    f0105834 <__udivdi3+0x34>
f0105829:	b8 01 00 00 00       	mov    $0x1,%eax
f010582e:	31 d2                	xor    %edx,%edx
f0105830:	f7 f3                	div    %ebx
f0105832:	89 c1                	mov    %eax,%ecx
f0105834:	31 d2                	xor    %edx,%edx
f0105836:	89 f0                	mov    %esi,%eax
f0105838:	f7 f1                	div    %ecx
f010583a:	89 c6                	mov    %eax,%esi
f010583c:	89 e8                	mov    %ebp,%eax
f010583e:	89 f7                	mov    %esi,%edi
f0105840:	f7 f1                	div    %ecx
f0105842:	89 fa                	mov    %edi,%edx
f0105844:	83 c4 1c             	add    $0x1c,%esp
f0105847:	5b                   	pop    %ebx
f0105848:	5e                   	pop    %esi
f0105849:	5f                   	pop    %edi
f010584a:	5d                   	pop    %ebp
f010584b:	c3                   	ret    
f010584c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105850:	39 f2                	cmp    %esi,%edx
f0105852:	77 7c                	ja     f01058d0 <__udivdi3+0xd0>
f0105854:	0f bd fa             	bsr    %edx,%edi
f0105857:	83 f7 1f             	xor    $0x1f,%edi
f010585a:	0f 84 98 00 00 00    	je     f01058f8 <__udivdi3+0xf8>
f0105860:	89 f9                	mov    %edi,%ecx
f0105862:	b8 20 00 00 00       	mov    $0x20,%eax
f0105867:	29 f8                	sub    %edi,%eax
f0105869:	d3 e2                	shl    %cl,%edx
f010586b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010586f:	89 c1                	mov    %eax,%ecx
f0105871:	89 da                	mov    %ebx,%edx
f0105873:	d3 ea                	shr    %cl,%edx
f0105875:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105879:	09 d1                	or     %edx,%ecx
f010587b:	89 f2                	mov    %esi,%edx
f010587d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105881:	89 f9                	mov    %edi,%ecx
f0105883:	d3 e3                	shl    %cl,%ebx
f0105885:	89 c1                	mov    %eax,%ecx
f0105887:	d3 ea                	shr    %cl,%edx
f0105889:	89 f9                	mov    %edi,%ecx
f010588b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010588f:	d3 e6                	shl    %cl,%esi
f0105891:	89 eb                	mov    %ebp,%ebx
f0105893:	89 c1                	mov    %eax,%ecx
f0105895:	d3 eb                	shr    %cl,%ebx
f0105897:	09 de                	or     %ebx,%esi
f0105899:	89 f0                	mov    %esi,%eax
f010589b:	f7 74 24 08          	divl   0x8(%esp)
f010589f:	89 d6                	mov    %edx,%esi
f01058a1:	89 c3                	mov    %eax,%ebx
f01058a3:	f7 64 24 0c          	mull   0xc(%esp)
f01058a7:	39 d6                	cmp    %edx,%esi
f01058a9:	72 0c                	jb     f01058b7 <__udivdi3+0xb7>
f01058ab:	89 f9                	mov    %edi,%ecx
f01058ad:	d3 e5                	shl    %cl,%ebp
f01058af:	39 c5                	cmp    %eax,%ebp
f01058b1:	73 5d                	jae    f0105910 <__udivdi3+0x110>
f01058b3:	39 d6                	cmp    %edx,%esi
f01058b5:	75 59                	jne    f0105910 <__udivdi3+0x110>
f01058b7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01058ba:	31 ff                	xor    %edi,%edi
f01058bc:	89 fa                	mov    %edi,%edx
f01058be:	83 c4 1c             	add    $0x1c,%esp
f01058c1:	5b                   	pop    %ebx
f01058c2:	5e                   	pop    %esi
f01058c3:	5f                   	pop    %edi
f01058c4:	5d                   	pop    %ebp
f01058c5:	c3                   	ret    
f01058c6:	8d 76 00             	lea    0x0(%esi),%esi
f01058c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01058d0:	31 ff                	xor    %edi,%edi
f01058d2:	31 c0                	xor    %eax,%eax
f01058d4:	89 fa                	mov    %edi,%edx
f01058d6:	83 c4 1c             	add    $0x1c,%esp
f01058d9:	5b                   	pop    %ebx
f01058da:	5e                   	pop    %esi
f01058db:	5f                   	pop    %edi
f01058dc:	5d                   	pop    %ebp
f01058dd:	c3                   	ret    
f01058de:	66 90                	xchg   %ax,%ax
f01058e0:	31 ff                	xor    %edi,%edi
f01058e2:	89 e8                	mov    %ebp,%eax
f01058e4:	89 f2                	mov    %esi,%edx
f01058e6:	f7 f3                	div    %ebx
f01058e8:	89 fa                	mov    %edi,%edx
f01058ea:	83 c4 1c             	add    $0x1c,%esp
f01058ed:	5b                   	pop    %ebx
f01058ee:	5e                   	pop    %esi
f01058ef:	5f                   	pop    %edi
f01058f0:	5d                   	pop    %ebp
f01058f1:	c3                   	ret    
f01058f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01058f8:	39 f2                	cmp    %esi,%edx
f01058fa:	72 06                	jb     f0105902 <__udivdi3+0x102>
f01058fc:	31 c0                	xor    %eax,%eax
f01058fe:	39 eb                	cmp    %ebp,%ebx
f0105900:	77 d2                	ja     f01058d4 <__udivdi3+0xd4>
f0105902:	b8 01 00 00 00       	mov    $0x1,%eax
f0105907:	eb cb                	jmp    f01058d4 <__udivdi3+0xd4>
f0105909:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105910:	89 d8                	mov    %ebx,%eax
f0105912:	31 ff                	xor    %edi,%edi
f0105914:	eb be                	jmp    f01058d4 <__udivdi3+0xd4>
f0105916:	66 90                	xchg   %ax,%ax
f0105918:	66 90                	xchg   %ax,%ax
f010591a:	66 90                	xchg   %ax,%ax
f010591c:	66 90                	xchg   %ax,%ax
f010591e:	66 90                	xchg   %ax,%ax

f0105920 <__umoddi3>:
f0105920:	55                   	push   %ebp
f0105921:	57                   	push   %edi
f0105922:	56                   	push   %esi
f0105923:	53                   	push   %ebx
f0105924:	83 ec 1c             	sub    $0x1c,%esp
f0105927:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010592b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010592f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105933:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105937:	85 ed                	test   %ebp,%ebp
f0105939:	89 f0                	mov    %esi,%eax
f010593b:	89 da                	mov    %ebx,%edx
f010593d:	75 19                	jne    f0105958 <__umoddi3+0x38>
f010593f:	39 df                	cmp    %ebx,%edi
f0105941:	0f 86 b1 00 00 00    	jbe    f01059f8 <__umoddi3+0xd8>
f0105947:	f7 f7                	div    %edi
f0105949:	89 d0                	mov    %edx,%eax
f010594b:	31 d2                	xor    %edx,%edx
f010594d:	83 c4 1c             	add    $0x1c,%esp
f0105950:	5b                   	pop    %ebx
f0105951:	5e                   	pop    %esi
f0105952:	5f                   	pop    %edi
f0105953:	5d                   	pop    %ebp
f0105954:	c3                   	ret    
f0105955:	8d 76 00             	lea    0x0(%esi),%esi
f0105958:	39 dd                	cmp    %ebx,%ebp
f010595a:	77 f1                	ja     f010594d <__umoddi3+0x2d>
f010595c:	0f bd cd             	bsr    %ebp,%ecx
f010595f:	83 f1 1f             	xor    $0x1f,%ecx
f0105962:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105966:	0f 84 b4 00 00 00    	je     f0105a20 <__umoddi3+0x100>
f010596c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105971:	89 c2                	mov    %eax,%edx
f0105973:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105977:	29 c2                	sub    %eax,%edx
f0105979:	89 c1                	mov    %eax,%ecx
f010597b:	89 f8                	mov    %edi,%eax
f010597d:	d3 e5                	shl    %cl,%ebp
f010597f:	89 d1                	mov    %edx,%ecx
f0105981:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105985:	d3 e8                	shr    %cl,%eax
f0105987:	09 c5                	or     %eax,%ebp
f0105989:	8b 44 24 04          	mov    0x4(%esp),%eax
f010598d:	89 c1                	mov    %eax,%ecx
f010598f:	d3 e7                	shl    %cl,%edi
f0105991:	89 d1                	mov    %edx,%ecx
f0105993:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105997:	89 df                	mov    %ebx,%edi
f0105999:	d3 ef                	shr    %cl,%edi
f010599b:	89 c1                	mov    %eax,%ecx
f010599d:	89 f0                	mov    %esi,%eax
f010599f:	d3 e3                	shl    %cl,%ebx
f01059a1:	89 d1                	mov    %edx,%ecx
f01059a3:	89 fa                	mov    %edi,%edx
f01059a5:	d3 e8                	shr    %cl,%eax
f01059a7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01059ac:	09 d8                	or     %ebx,%eax
f01059ae:	f7 f5                	div    %ebp
f01059b0:	d3 e6                	shl    %cl,%esi
f01059b2:	89 d1                	mov    %edx,%ecx
f01059b4:	f7 64 24 08          	mull   0x8(%esp)
f01059b8:	39 d1                	cmp    %edx,%ecx
f01059ba:	89 c3                	mov    %eax,%ebx
f01059bc:	89 d7                	mov    %edx,%edi
f01059be:	72 06                	jb     f01059c6 <__umoddi3+0xa6>
f01059c0:	75 0e                	jne    f01059d0 <__umoddi3+0xb0>
f01059c2:	39 c6                	cmp    %eax,%esi
f01059c4:	73 0a                	jae    f01059d0 <__umoddi3+0xb0>
f01059c6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01059ca:	19 ea                	sbb    %ebp,%edx
f01059cc:	89 d7                	mov    %edx,%edi
f01059ce:	89 c3                	mov    %eax,%ebx
f01059d0:	89 ca                	mov    %ecx,%edx
f01059d2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01059d7:	29 de                	sub    %ebx,%esi
f01059d9:	19 fa                	sbb    %edi,%edx
f01059db:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01059df:	89 d0                	mov    %edx,%eax
f01059e1:	d3 e0                	shl    %cl,%eax
f01059e3:	89 d9                	mov    %ebx,%ecx
f01059e5:	d3 ee                	shr    %cl,%esi
f01059e7:	d3 ea                	shr    %cl,%edx
f01059e9:	09 f0                	or     %esi,%eax
f01059eb:	83 c4 1c             	add    $0x1c,%esp
f01059ee:	5b                   	pop    %ebx
f01059ef:	5e                   	pop    %esi
f01059f0:	5f                   	pop    %edi
f01059f1:	5d                   	pop    %ebp
f01059f2:	c3                   	ret    
f01059f3:	90                   	nop
f01059f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01059f8:	85 ff                	test   %edi,%edi
f01059fa:	89 f9                	mov    %edi,%ecx
f01059fc:	75 0b                	jne    f0105a09 <__umoddi3+0xe9>
f01059fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0105a03:	31 d2                	xor    %edx,%edx
f0105a05:	f7 f7                	div    %edi
f0105a07:	89 c1                	mov    %eax,%ecx
f0105a09:	89 d8                	mov    %ebx,%eax
f0105a0b:	31 d2                	xor    %edx,%edx
f0105a0d:	f7 f1                	div    %ecx
f0105a0f:	89 f0                	mov    %esi,%eax
f0105a11:	f7 f1                	div    %ecx
f0105a13:	e9 31 ff ff ff       	jmp    f0105949 <__umoddi3+0x29>
f0105a18:	90                   	nop
f0105a19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105a20:	39 dd                	cmp    %ebx,%ebp
f0105a22:	72 08                	jb     f0105a2c <__umoddi3+0x10c>
f0105a24:	39 f7                	cmp    %esi,%edi
f0105a26:	0f 87 21 ff ff ff    	ja     f010594d <__umoddi3+0x2d>
f0105a2c:	89 da                	mov    %ebx,%edx
f0105a2e:	89 f0                	mov    %esi,%eax
f0105a30:	29 f8                	sub    %edi,%eax
f0105a32:	19 ea                	sbb    %ebp,%edx
f0105a34:	e9 14 ff ff ff       	jmp    f010594d <__umoddi3+0x2d>
