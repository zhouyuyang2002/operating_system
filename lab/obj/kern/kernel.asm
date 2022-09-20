
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 72 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 58 08 ff ff    	lea    -0xf7a8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 8d 0a 00 00       	call   f0100af0 <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7f 2b                	jg     f0100095 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 22 08 00 00       	call   f010089a <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 74 08 ff ff    	lea    -0xf78c(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 65 0a 00 00       	call   f0100af0 <cprintf>
}
f010008b:	83 c4 10             	add    $0x10,%esp
f010008e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100091:	5b                   	pop    %ebx
f0100092:	5e                   	pop    %esi
f0100093:	5d                   	pop    %ebp
f0100094:	c3                   	ret    
		test_backtrace(x-1);
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d5                	jmp    f010007b <test_backtrace+0x3b>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 0a 01 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 a0 36 11 f0    	mov    $0xf01136a0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 36 16 00 00       	call   f0101705 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 3d 05 00 00       	call   f0100611 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 8f 08 ff ff    	lea    -0xf771(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 08 0a 00 00       	call   f0100af0 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ef:	e8 4c ff ff ff       	call   f0100040 <test_backtrace>
f01000f4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f7:	83 ec 0c             	sub    $0xc,%esp
f01000fa:	6a 00                	push   $0x0
f01000fc:	e8 37 08 00 00       	call   f0100938 <monitor>
f0100101:	83 c4 10             	add    $0x10,%esp
f0100104:	eb f1                	jmp    f01000f7 <i386_init+0x51>

f0100106 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100106:	55                   	push   %ebp
f0100107:	89 e5                	mov    %esp,%ebp
f0100109:	57                   	push   %edi
f010010a:	56                   	push   %esi
f010010b:	53                   	push   %ebx
f010010c:	83 ec 0c             	sub    $0xc,%esp
f010010f:	e8 a8 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100114:	81 c3 f4 11 01 00    	add    $0x111f4,%ebx
f010011a:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010011d:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100123:	83 38 00             	cmpl   $0x0,(%eax)
f0100126:	74 0f                	je     f0100137 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100128:	83 ec 0c             	sub    $0xc,%esp
f010012b:	6a 00                	push   $0x0
f010012d:	e8 06 08 00 00       	call   f0100938 <monitor>
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	eb f1                	jmp    f0100128 <_panic+0x22>
	panicstr = fmt;
f0100137:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100139:	fa                   	cli    
f010013a:	fc                   	cld    
	va_start(ap, fmt);
f010013b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010013e:	83 ec 04             	sub    $0x4,%esp
f0100141:	ff 75 0c             	pushl  0xc(%ebp)
f0100144:	ff 75 08             	pushl  0x8(%ebp)
f0100147:	8d 83 aa 08 ff ff    	lea    -0xf756(%ebx),%eax
f010014d:	50                   	push   %eax
f010014e:	e8 9d 09 00 00       	call   f0100af0 <cprintf>
	vcprintf(fmt, ap);
f0100153:	83 c4 08             	add    $0x8,%esp
f0100156:	56                   	push   %esi
f0100157:	57                   	push   %edi
f0100158:	e8 5c 09 00 00       	call   f0100ab9 <vcprintf>
	cprintf("\n");
f010015d:	8d 83 99 0b ff ff    	lea    -0xf467(%ebx),%eax
f0100163:	89 04 24             	mov    %eax,(%esp)
f0100166:	e8 85 09 00 00       	call   f0100af0 <cprintf>
f010016b:	83 c4 10             	add    $0x10,%esp
f010016e:	eb b8                	jmp    f0100128 <_panic+0x22>

f0100170 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp
f0100173:	56                   	push   %esi
f0100174:	53                   	push   %ebx
f0100175:	e8 42 00 00 00       	call   f01001bc <__x86.get_pc_thunk.bx>
f010017a:	81 c3 8e 11 01 00    	add    $0x1118e,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100180:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100183:	83 ec 04             	sub    $0x4,%esp
f0100186:	ff 75 0c             	pushl  0xc(%ebp)
f0100189:	ff 75 08             	pushl  0x8(%ebp)
f010018c:	8d 83 c2 08 ff ff    	lea    -0xf73e(%ebx),%eax
f0100192:	50                   	push   %eax
f0100193:	e8 58 09 00 00       	call   f0100af0 <cprintf>
	vcprintf(fmt, ap);
f0100198:	83 c4 08             	add    $0x8,%esp
f010019b:	56                   	push   %esi
f010019c:	ff 75 10             	pushl  0x10(%ebp)
f010019f:	e8 15 09 00 00       	call   f0100ab9 <vcprintf>
	cprintf("\n");
f01001a4:	8d 83 99 0b ff ff    	lea    -0xf467(%ebx),%eax
f01001aa:	89 04 24             	mov    %eax,(%esp)
f01001ad:	e8 3e 09 00 00       	call   f0100af0 <cprintf>
	va_end(ap);
}
f01001b2:	83 c4 10             	add    $0x10,%esp
f01001b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001b8:	5b                   	pop    %ebx
f01001b9:	5e                   	pop    %esi
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <__x86.get_pc_thunk.bx>:
f01001bc:	8b 1c 24             	mov    (%esp),%ebx
f01001bf:	c3                   	ret    

f01001c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001c0:	55                   	push   %ebp
f01001c1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001c9:	a8 01                	test   $0x1,%al
f01001cb:	74 0b                	je     f01001d8 <serial_proc_data+0x18>
f01001cd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001d3:	0f b6 c0             	movzbl %al,%eax
}
f01001d6:	5d                   	pop    %ebp
f01001d7:	c3                   	ret    
		return -1;
f01001d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001dd:	eb f7                	jmp    f01001d6 <serial_proc_data+0x16>

f01001df <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001df:	55                   	push   %ebp
f01001e0:	89 e5                	mov    %esp,%ebp
f01001e2:	56                   	push   %esi
f01001e3:	53                   	push   %ebx
f01001e4:	e8 d3 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01001e9:	81 c3 1f 11 01 00    	add    $0x1111f,%ebx
f01001ef:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d6                	call   *%esi
f01001f3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f6:	74 2e                	je     f0100226 <cons_intr+0x47>
		if (c == 0)
f01001f8:	85 c0                	test   %eax,%eax
f01001fa:	74 f5                	je     f01001f1 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001fc:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100202:	8d 51 01             	lea    0x1(%ecx),%edx
f0100205:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010020b:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100212:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100218:	75 d7                	jne    f01001f1 <cons_intr+0x12>
			cons.wpos = 0;
f010021a:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100221:	00 00 00 
f0100224:	eb cb                	jmp    f01001f1 <cons_intr+0x12>
	}
}
f0100226:	5b                   	pop    %ebx
f0100227:	5e                   	pop    %esi
f0100228:	5d                   	pop    %ebp
f0100229:	c3                   	ret    

f010022a <kbd_proc_data>:
{
f010022a:	55                   	push   %ebp
f010022b:	89 e5                	mov    %esp,%ebp
f010022d:	56                   	push   %esi
f010022e:	53                   	push   %ebx
f010022f:	e8 88 ff ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100234:	81 c3 d4 10 01 00    	add    $0x110d4,%ebx
f010023a:	ba 64 00 00 00       	mov    $0x64,%edx
f010023f:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100240:	a8 01                	test   $0x1,%al
f0100242:	0f 84 06 01 00 00    	je     f010034e <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100248:	a8 20                	test   $0x20,%al
f010024a:	0f 85 05 01 00 00    	jne    f0100355 <kbd_proc_data+0x12b>
f0100250:	ba 60 00 00 00       	mov    $0x60,%edx
f0100255:	ec                   	in     (%dx),%al
f0100256:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100258:	3c e0                	cmp    $0xe0,%al
f010025a:	0f 84 93 00 00 00    	je     f01002f3 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100260:	84 c0                	test   %al,%al
f0100262:	0f 88 a0 00 00 00    	js     f0100308 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100268:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010026e:	f6 c1 40             	test   $0x40,%cl
f0100271:	74 0e                	je     f0100281 <kbd_proc_data+0x57>
		data |= 0x80;
f0100273:	83 c8 80             	or     $0xffffff80,%eax
f0100276:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100278:	83 e1 bf             	and    $0xffffffbf,%ecx
f010027b:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100281:	0f b6 d2             	movzbl %dl,%edx
f0100284:	0f b6 84 13 18 0a ff 	movzbl -0xf5e8(%ebx,%edx,1),%eax
f010028b:	ff 
f010028c:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100292:	0f b6 8c 13 18 09 ff 	movzbl -0xf6e8(%ebx,%edx,1),%ecx
f0100299:	ff 
f010029a:	31 c8                	xor    %ecx,%eax
f010029c:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002a2:	89 c1                	mov    %eax,%ecx
f01002a4:	83 e1 03             	and    $0x3,%ecx
f01002a7:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002ae:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b2:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002b5:	a8 08                	test   $0x8,%al
f01002b7:	74 0d                	je     f01002c6 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002b9:	89 f2                	mov    %esi,%edx
f01002bb:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002be:	83 f9 19             	cmp    $0x19,%ecx
f01002c1:	77 7a                	ja     f010033d <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002c3:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002c6:	f7 d0                	not    %eax
f01002c8:	a8 06                	test   $0x6,%al
f01002ca:	75 33                	jne    f01002ff <kbd_proc_data+0xd5>
f01002cc:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002d2:	75 2b                	jne    f01002ff <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002d4:	83 ec 0c             	sub    $0xc,%esp
f01002d7:	8d 83 dc 08 ff ff    	lea    -0xf724(%ebx),%eax
f01002dd:	50                   	push   %eax
f01002de:	e8 0d 08 00 00       	call   f0100af0 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002e8:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ed:	ee                   	out    %al,(%dx)
f01002ee:	83 c4 10             	add    $0x10,%esp
f01002f1:	eb 0c                	jmp    f01002ff <kbd_proc_data+0xd5>
		shift |= E0ESC;
f01002f3:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f01002fa:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002ff:	89 f0                	mov    %esi,%eax
f0100301:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100304:	5b                   	pop    %ebx
f0100305:	5e                   	pop    %esi
f0100306:	5d                   	pop    %ebp
f0100307:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100308:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010030e:	89 ce                	mov    %ecx,%esi
f0100310:	83 e6 40             	and    $0x40,%esi
f0100313:	83 e0 7f             	and    $0x7f,%eax
f0100316:	85 f6                	test   %esi,%esi
f0100318:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010031b:	0f b6 d2             	movzbl %dl,%edx
f010031e:	0f b6 84 13 18 0a ff 	movzbl -0xf5e8(%ebx,%edx,1),%eax
f0100325:	ff 
f0100326:	83 c8 40             	or     $0x40,%eax
f0100329:	0f b6 c0             	movzbl %al,%eax
f010032c:	f7 d0                	not    %eax
f010032e:	21 c8                	and    %ecx,%eax
f0100330:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100336:	be 00 00 00 00       	mov    $0x0,%esi
f010033b:	eb c2                	jmp    f01002ff <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010033d:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100340:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100343:	83 fa 1a             	cmp    $0x1a,%edx
f0100346:	0f 42 f1             	cmovb  %ecx,%esi
f0100349:	e9 78 ff ff ff       	jmp    f01002c6 <kbd_proc_data+0x9c>
		return -1;
f010034e:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100353:	eb aa                	jmp    f01002ff <kbd_proc_data+0xd5>
		return -1;
f0100355:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010035a:	eb a3                	jmp    f01002ff <kbd_proc_data+0xd5>

f010035c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010035c:	55                   	push   %ebp
f010035d:	89 e5                	mov    %esp,%ebp
f010035f:	57                   	push   %edi
f0100360:	56                   	push   %esi
f0100361:	53                   	push   %ebx
f0100362:	83 ec 1c             	sub    $0x1c,%esp
f0100365:	e8 52 fe ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010036a:	81 c3 9e 0f 01 00    	add    $0x10f9e,%ebx
f0100370:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100373:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100378:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010037d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100382:	eb 09                	jmp    f010038d <cons_putc+0x31>
f0100384:	89 ca                	mov    %ecx,%edx
f0100386:	ec                   	in     (%dx),%al
f0100387:	ec                   	in     (%dx),%al
f0100388:	ec                   	in     (%dx),%al
f0100389:	ec                   	in     (%dx),%al
	     i++)
f010038a:	83 c6 01             	add    $0x1,%esi
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100390:	a8 20                	test   $0x20,%al
f0100392:	75 08                	jne    f010039c <cons_putc+0x40>
f0100394:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010039a:	7e e8                	jle    f0100384 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010039c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003a9:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003aa:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003af:	bf 79 03 00 00       	mov    $0x379,%edi
f01003b4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b9:	eb 09                	jmp    f01003c4 <cons_putc+0x68>
f01003bb:	89 ca                	mov    %ecx,%edx
f01003bd:	ec                   	in     (%dx),%al
f01003be:	ec                   	in     (%dx),%al
f01003bf:	ec                   	in     (%dx),%al
f01003c0:	ec                   	in     (%dx),%al
f01003c1:	83 c6 01             	add    $0x1,%esi
f01003c4:	89 fa                	mov    %edi,%edx
f01003c6:	ec                   	in     (%dx),%al
f01003c7:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003cd:	7f 04                	jg     f01003d3 <cons_putc+0x77>
f01003cf:	84 c0                	test   %al,%al
f01003d1:	79 e8                	jns    f01003bb <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d3:	ba 78 03 00 00       	mov    $0x378,%edx
f01003d8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003dc:	ee                   	out    %al,(%dx)
f01003dd:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003e2:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003e7:	ee                   	out    %al,(%dx)
f01003e8:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ed:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003f1:	89 fa                	mov    %edi,%edx
f01003f3:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003f9:	89 f8                	mov    %edi,%eax
f01003fb:	80 cc 07             	or     $0x7,%ah
f01003fe:	85 d2                	test   %edx,%edx
f0100400:	0f 45 c7             	cmovne %edi,%eax
f0100403:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100406:	0f b6 c0             	movzbl %al,%eax
f0100409:	83 f8 09             	cmp    $0x9,%eax
f010040c:	0f 84 b9 00 00 00    	je     f01004cb <cons_putc+0x16f>
f0100412:	83 f8 09             	cmp    $0x9,%eax
f0100415:	7e 74                	jle    f010048b <cons_putc+0x12f>
f0100417:	83 f8 0a             	cmp    $0xa,%eax
f010041a:	0f 84 9e 00 00 00    	je     f01004be <cons_putc+0x162>
f0100420:	83 f8 0d             	cmp    $0xd,%eax
f0100423:	0f 85 d9 00 00 00    	jne    f0100502 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100429:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100430:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100436:	c1 e8 16             	shr    $0x16,%eax
f0100439:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010043c:	c1 e0 04             	shl    $0x4,%eax
f010043f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010044d:	cf 07 
f010044f:	0f 87 d4 00 00 00    	ja     f0100529 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100455:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010045b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100460:	89 ca                	mov    %ecx,%edx
f0100462:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100463:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010046a:	8d 71 01             	lea    0x1(%ecx),%esi
f010046d:	89 d8                	mov    %ebx,%eax
f010046f:	66 c1 e8 08          	shr    $0x8,%ax
f0100473:	89 f2                	mov    %esi,%edx
f0100475:	ee                   	out    %al,(%dx)
f0100476:	b8 0f 00 00 00       	mov    $0xf,%eax
f010047b:	89 ca                	mov    %ecx,%edx
f010047d:	ee                   	out    %al,(%dx)
f010047e:	89 d8                	mov    %ebx,%eax
f0100480:	89 f2                	mov    %esi,%edx
f0100482:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100483:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100486:	5b                   	pop    %ebx
f0100487:	5e                   	pop    %esi
f0100488:	5f                   	pop    %edi
f0100489:	5d                   	pop    %ebp
f010048a:	c3                   	ret    
	switch (c & 0xff) {
f010048b:	83 f8 08             	cmp    $0x8,%eax
f010048e:	75 72                	jne    f0100502 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100490:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100497:	66 85 c0             	test   %ax,%ax
f010049a:	74 b9                	je     f0100455 <cons_putc+0xf9>
			crt_pos--;
f010049c:	83 e8 01             	sub    $0x1,%eax
f010049f:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004ad:	b2 00                	mov    $0x0,%dl
f01004af:	83 ca 20             	or     $0x20,%edx
f01004b2:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004b8:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004bc:	eb 88                	jmp    f0100446 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004be:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004c5:	50 
f01004c6:	e9 5e ff ff ff       	jmp    f0100429 <cons_putc+0xcd>
		cons_putc(' ');
f01004cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d0:	e8 87 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01004da:	e8 7d fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004df:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e4:	e8 73 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004e9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ee:	e8 69 fe ff ff       	call   f010035c <cons_putc>
		cons_putc(' ');
f01004f3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f8:	e8 5f fe ff ff       	call   f010035c <cons_putc>
f01004fd:	e9 44 ff ff ff       	jmp    f0100446 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100502:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100509:	8d 50 01             	lea    0x1(%eax),%edx
f010050c:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100513:	0f b7 c0             	movzwl %ax,%eax
f0100516:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010051c:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100520:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100524:	e9 1d ff ff ff       	jmp    f0100446 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100529:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f010052f:	83 ec 04             	sub    $0x4,%esp
f0100532:	68 00 0f 00 00       	push   $0xf00
f0100537:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010053d:	52                   	push   %edx
f010053e:	50                   	push   %eax
f010053f:	e8 0e 12 00 00       	call   f0101752 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100544:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010054a:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100550:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100556:	83 c4 10             	add    $0x10,%esp
f0100559:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010055e:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100561:	39 d0                	cmp    %edx,%eax
f0100563:	75 f4                	jne    f0100559 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100565:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010056c:	50 
f010056d:	e9 e3 fe ff ff       	jmp    f0100455 <cons_putc+0xf9>

f0100572 <serial_intr>:
{
f0100572:	e8 e7 01 00 00       	call   f010075e <__x86.get_pc_thunk.ax>
f0100577:	05 91 0d 01 00       	add    $0x10d91,%eax
	if (serial_exists)
f010057c:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100583:	75 02                	jne    f0100587 <serial_intr+0x15>
f0100585:	f3 c3                	repz ret 
{
f0100587:	55                   	push   %ebp
f0100588:	89 e5                	mov    %esp,%ebp
f010058a:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010058d:	8d 80 b8 ee fe ff    	lea    -0x11148(%eax),%eax
f0100593:	e8 47 fc ff ff       	call   f01001df <cons_intr>
}
f0100598:	c9                   	leave  
f0100599:	c3                   	ret    

f010059a <kbd_intr>:
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	83 ec 08             	sub    $0x8,%esp
f01005a0:	e8 b9 01 00 00       	call   f010075e <__x86.get_pc_thunk.ax>
f01005a5:	05 63 0d 01 00       	add    $0x10d63,%eax
	cons_intr(kbd_proc_data);
f01005aa:	8d 80 22 ef fe ff    	lea    -0x110de(%eax),%eax
f01005b0:	e8 2a fc ff ff       	call   f01001df <cons_intr>
}
f01005b5:	c9                   	leave  
f01005b6:	c3                   	ret    

f01005b7 <cons_getc>:
{
f01005b7:	55                   	push   %ebp
f01005b8:	89 e5                	mov    %esp,%ebp
f01005ba:	53                   	push   %ebx
f01005bb:	83 ec 04             	sub    $0x4,%esp
f01005be:	e8 f9 fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01005c3:	81 c3 45 0d 01 00    	add    $0x10d45,%ebx
	serial_intr();
f01005c9:	e8 a4 ff ff ff       	call   f0100572 <serial_intr>
	kbd_intr();
f01005ce:	e8 c7 ff ff ff       	call   f010059a <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005d3:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f01005d9:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005de:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f01005e4:	74 19                	je     f01005ff <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005e6:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005e9:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f01005ef:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f01005f6:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005f7:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005fd:	74 06                	je     f0100605 <cons_getc+0x4e>
}
f01005ff:	83 c4 04             	add    $0x4,%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5d                   	pop    %ebp
f0100604:	c3                   	ret    
			cons.rpos = 0;
f0100605:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010060c:	00 00 00 
f010060f:	eb ee                	jmp    f01005ff <cons_getc+0x48>

f0100611 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	57                   	push   %edi
f0100615:	56                   	push   %esi
f0100616:	53                   	push   %ebx
f0100617:	83 ec 1c             	sub    $0x1c,%esp
f010061a:	e8 9d fb ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010061f:	81 c3 e9 0c 01 00    	add    $0x10ce9,%ebx
	was = *cp;
f0100625:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010062c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100633:	5a a5 
	if (*cp != 0xA55A) {
f0100635:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010063c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100640:	0f 84 bc 00 00 00    	je     f0100702 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100646:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010064d:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100650:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100657:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010065d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100662:	89 fa                	mov    %edi,%edx
f0100664:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100665:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100668:	89 ca                	mov    %ecx,%edx
f010066a:	ec                   	in     (%dx),%al
f010066b:	0f b6 f0             	movzbl %al,%esi
f010066e:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100671:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100676:	89 fa                	mov    %edi,%edx
f0100678:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100679:	89 ca                	mov    %ecx,%edx
f010067b:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010067c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010067f:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100685:	0f b6 c0             	movzbl %al,%eax
f0100688:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010068a:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100691:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100696:	89 c8                	mov    %ecx,%eax
f0100698:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010069d:	ee                   	out    %al,(%dx)
f010069e:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006a3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006a8:	89 fa                	mov    %edi,%edx
f01006aa:	ee                   	out    %al,(%dx)
f01006ab:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006b0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006b5:	ee                   	out    %al,(%dx)
f01006b6:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006bb:	89 c8                	mov    %ecx,%eax
f01006bd:	89 f2                	mov    %esi,%edx
f01006bf:	ee                   	out    %al,(%dx)
f01006c0:	b8 03 00 00 00       	mov    $0x3,%eax
f01006c5:	89 fa                	mov    %edi,%edx
f01006c7:	ee                   	out    %al,(%dx)
f01006c8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006cd:	89 c8                	mov    %ecx,%eax
f01006cf:	ee                   	out    %al,(%dx)
f01006d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01006d5:	89 f2                	mov    %esi,%edx
f01006d7:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006d8:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006dd:	ec                   	in     (%dx),%al
f01006de:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006e0:	3c ff                	cmp    $0xff,%al
f01006e2:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f01006e9:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006ee:	ec                   	in     (%dx),%al
f01006ef:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006f4:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006f5:	80 f9 ff             	cmp    $0xff,%cl
f01006f8:	74 25                	je     f010071f <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006fd:	5b                   	pop    %ebx
f01006fe:	5e                   	pop    %esi
f01006ff:	5f                   	pop    %edi
f0100700:	5d                   	pop    %ebp
f0100701:	c3                   	ret    
		*cp = was;
f0100702:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100709:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f0100710:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100713:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f010071a:	e9 38 ff ff ff       	jmp    f0100657 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f010071f:	83 ec 0c             	sub    $0xc,%esp
f0100722:	8d 83 e8 08 ff ff    	lea    -0xf718(%ebx),%eax
f0100728:	50                   	push   %eax
f0100729:	e8 c2 03 00 00       	call   f0100af0 <cprintf>
f010072e:	83 c4 10             	add    $0x10,%esp
}
f0100731:	eb c7                	jmp    f01006fa <cons_init+0xe9>

f0100733 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100739:	8b 45 08             	mov    0x8(%ebp),%eax
f010073c:	e8 1b fc ff ff       	call   f010035c <cons_putc>
}
f0100741:	c9                   	leave  
f0100742:	c3                   	ret    

f0100743 <getchar>:

int
getchar(void)
{
f0100743:	55                   	push   %ebp
f0100744:	89 e5                	mov    %esp,%ebp
f0100746:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100749:	e8 69 fe ff ff       	call   f01005b7 <cons_getc>
f010074e:	85 c0                	test   %eax,%eax
f0100750:	74 f7                	je     f0100749 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100752:	c9                   	leave  
f0100753:	c3                   	ret    

f0100754 <iscons>:

int
iscons(int fdnum)
{
f0100754:	55                   	push   %ebp
f0100755:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100757:	b8 01 00 00 00       	mov    $0x1,%eax
f010075c:	5d                   	pop    %ebp
f010075d:	c3                   	ret    

f010075e <__x86.get_pc_thunk.ax>:
f010075e:	8b 04 24             	mov    (%esp),%eax
f0100761:	c3                   	ret    

f0100762 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100762:	55                   	push   %ebp
f0100763:	89 e5                	mov    %esp,%ebp
f0100765:	56                   	push   %esi
f0100766:	53                   	push   %ebx
f0100767:	e8 50 fa ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010076c:	81 c3 9c 0b 01 00    	add    $0x10b9c,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100772:	83 ec 04             	sub    $0x4,%esp
f0100775:	8d 83 18 0b ff ff    	lea    -0xf4e8(%ebx),%eax
f010077b:	50                   	push   %eax
f010077c:	8d 83 36 0b ff ff    	lea    -0xf4ca(%ebx),%eax
f0100782:	50                   	push   %eax
f0100783:	8d b3 3b 0b ff ff    	lea    -0xf4c5(%ebx),%esi
f0100789:	56                   	push   %esi
f010078a:	e8 61 03 00 00       	call   f0100af0 <cprintf>
f010078f:	83 c4 0c             	add    $0xc,%esp
f0100792:	8d 83 d8 0b ff ff    	lea    -0xf428(%ebx),%eax
f0100798:	50                   	push   %eax
f0100799:	8d 83 44 0b ff ff    	lea    -0xf4bc(%ebx),%eax
f010079f:	50                   	push   %eax
f01007a0:	56                   	push   %esi
f01007a1:	e8 4a 03 00 00       	call   f0100af0 <cprintf>
f01007a6:	83 c4 0c             	add    $0xc,%esp
f01007a9:	8d 83 00 0c ff ff    	lea    -0xf400(%ebx),%eax
f01007af:	50                   	push   %eax
f01007b0:	8d 83 4d 0b ff ff    	lea    -0xf4b3(%ebx),%eax
f01007b6:	50                   	push   %eax
f01007b7:	56                   	push   %esi
f01007b8:	e8 33 03 00 00       	call   f0100af0 <cprintf>
	return 0;
}
f01007bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007c5:	5b                   	pop    %ebx
f01007c6:	5e                   	pop    %esi
f01007c7:	5d                   	pop    %ebp
f01007c8:	c3                   	ret    

f01007c9 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c9:	55                   	push   %ebp
f01007ca:	89 e5                	mov    %esp,%ebp
f01007cc:	57                   	push   %edi
f01007cd:	56                   	push   %esi
f01007ce:	53                   	push   %ebx
f01007cf:	83 ec 18             	sub    $0x18,%esp
f01007d2:	e8 e5 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01007d7:	81 c3 31 0b 01 00    	add    $0x10b31,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007dd:	8d 83 57 0b ff ff    	lea    -0xf4a9(%ebx),%eax
f01007e3:	50                   	push   %eax
f01007e4:	e8 07 03 00 00       	call   f0100af0 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e9:	83 c4 08             	add    $0x8,%esp
f01007ec:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007f2:	8d 83 2c 0c ff ff    	lea    -0xf3d4(%ebx),%eax
f01007f8:	50                   	push   %eax
f01007f9:	e8 f2 02 00 00       	call   f0100af0 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007fe:	83 c4 0c             	add    $0xc,%esp
f0100801:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100807:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010080d:	50                   	push   %eax
f010080e:	57                   	push   %edi
f010080f:	8d 83 54 0c ff ff    	lea    -0xf3ac(%ebx),%eax
f0100815:	50                   	push   %eax
f0100816:	e8 d5 02 00 00       	call   f0100af0 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010081b:	83 c4 0c             	add    $0xc,%esp
f010081e:	c7 c0 49 1b 10 f0    	mov    $0xf0101b49,%eax
f0100824:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010082a:	52                   	push   %edx
f010082b:	50                   	push   %eax
f010082c:	8d 83 78 0c ff ff    	lea    -0xf388(%ebx),%eax
f0100832:	50                   	push   %eax
f0100833:	e8 b8 02 00 00       	call   f0100af0 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100838:	83 c4 0c             	add    $0xc,%esp
f010083b:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100841:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100847:	52                   	push   %edx
f0100848:	50                   	push   %eax
f0100849:	8d 83 9c 0c ff ff    	lea    -0xf364(%ebx),%eax
f010084f:	50                   	push   %eax
f0100850:	e8 9b 02 00 00       	call   f0100af0 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100855:	83 c4 0c             	add    $0xc,%esp
f0100858:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f010085e:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100864:	50                   	push   %eax
f0100865:	56                   	push   %esi
f0100866:	8d 83 c0 0c ff ff    	lea    -0xf340(%ebx),%eax
f010086c:	50                   	push   %eax
f010086d:	e8 7e 02 00 00       	call   f0100af0 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100872:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100875:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010087b:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010087d:	c1 fe 0a             	sar    $0xa,%esi
f0100880:	56                   	push   %esi
f0100881:	8d 83 e4 0c ff ff    	lea    -0xf31c(%ebx),%eax
f0100887:	50                   	push   %eax
f0100888:	e8 63 02 00 00       	call   f0100af0 <cprintf>
	return 0;
}
f010088d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100892:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100895:	5b                   	pop    %ebx
f0100896:	5e                   	pop    %esi
f0100897:	5f                   	pop    %edi
f0100898:	5d                   	pop    %ebp
f0100899:	c3                   	ret    

f010089a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089a:	55                   	push   %ebp
f010089b:	89 e5                	mov    %esp,%ebp
f010089d:	57                   	push   %edi
f010089e:	56                   	push   %esi
f010089f:	53                   	push   %ebx
f01008a0:	83 ec 48             	sub    $0x48,%esp
f01008a3:	e8 14 f9 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f01008a8:	81 c3 60 0a 01 00    	add    $0x10a60,%ebx
	cprintf("Stack backtrace\n");
f01008ae:	8d 83 70 0b ff ff    	lea    -0xf490(%ebx),%eax
f01008b4:	50                   	push   %eax
f01008b5:	e8 36 02 00 00       	call   f0100af0 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008ba:	89 e8                	mov    %ebp,%eax
f01008bc:	83 c4 10             	add    $0x10,%esp
		uint32_t arg_2 = *((uint32_t*)pointer + 1 + 2);
		uint32_t arg_3 = *((uint32_t*)pointer + 1 + 3);
		uint32_t arg_4 = *((uint32_t*)pointer + 1 + 4);
		uint32_t arg_5 = *((uint32_t*)pointer + 1 + 5);
		//
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f01008bf:	8d 93 10 0d ff ff    	lea    -0xf2f0(%ebx),%edx
f01008c5:	89 55 c4             	mov    %edx,-0x3c(%ebp)
				ebp_val, ret_pos, arg_1, arg_2, arg_3, arg_4, arg_5);

		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f01008c8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01008cb:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f01008ce:	eb 06                	jmp    f01008d6 <mon_backtrace+0x3c>
				eip_info.eip_file, eip_info.eip_line, 
				eip_info.eip_fn_namelen, eip_info.eip_fn_name,
				ret_pos - eip_info.eip_fn_addr);
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
			break;
		ebp_val = new_ebp_val;
f01008d0:	89 f8                	mov    %edi,%eax
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
f01008d2:	85 ff                	test   %edi,%edi
f01008d4:	74 55                	je     f010092b <mon_backtrace+0x91>
		uint32_t new_ebp_val = *((uint32_t*)pointer);
f01008d6:	8b 38                	mov    (%eax),%edi
		uint32_t ret_pos = *((uint32_t*)pointer + 1);
f01008d8:	8b 70 04             	mov    0x4(%eax),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f01008db:	ff 70 18             	pushl  0x18(%eax)
f01008de:	ff 70 14             	pushl  0x14(%eax)
f01008e1:	ff 70 10             	pushl  0x10(%eax)
f01008e4:	ff 70 0c             	pushl  0xc(%eax)
f01008e7:	ff 70 08             	pushl  0x8(%eax)
f01008ea:	56                   	push   %esi
f01008eb:	50                   	push   %eax
f01008ec:	ff 75 c4             	pushl  -0x3c(%ebp)
f01008ef:	e8 fc 01 00 00       	call   f0100af0 <cprintf>
		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f01008f4:	83 c4 18             	add    $0x18,%esp
f01008f7:	ff 75 c0             	pushl  -0x40(%ebp)
f01008fa:	56                   	push   %esi
f01008fb:	e8 f4 02 00 00       	call   f0100bf4 <debuginfo_eip>
f0100900:	83 c4 10             	add    $0x10,%esp
f0100903:	85 c0                	test   %eax,%eax
f0100905:	75 c9                	jne    f01008d0 <mon_backtrace+0x36>
			cprintf("         %s:%d: %.*s+%d\r\n",
f0100907:	83 ec 08             	sub    $0x8,%esp
f010090a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010090d:	56                   	push   %esi
f010090e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100911:	ff 75 dc             	pushl  -0x24(%ebp)
f0100914:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100917:	ff 75 d0             	pushl  -0x30(%ebp)
f010091a:	8d 83 81 0b ff ff    	lea    -0xf47f(%ebx),%eax
f0100920:	50                   	push   %eax
f0100921:	e8 ca 01 00 00       	call   f0100af0 <cprintf>
f0100926:	83 c4 20             	add    $0x20,%esp
f0100929:	eb a5                	jmp    f01008d0 <mon_backtrace+0x36>
	//  ebp f0109e58  eip f0100a62  args 00000001 f0109e80 f0109e98 f0100ed2 00000031
	//         kern/monitor.c:143: monitor+106

	// Your code here.
	return 0;
}
f010092b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100930:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100933:	5b                   	pop    %ebx
f0100934:	5e                   	pop    %esi
f0100935:	5f                   	pop    %edi
f0100936:	5d                   	pop    %ebp
f0100937:	c3                   	ret    

f0100938 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	57                   	push   %edi
f010093c:	56                   	push   %esi
f010093d:	53                   	push   %ebx
f010093e:	83 ec 68             	sub    $0x68,%esp
f0100941:	e8 76 f8 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100946:	81 c3 c2 09 01 00    	add    $0x109c2,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010094c:	8d 83 48 0d ff ff    	lea    -0xf2b8(%ebx),%eax
f0100952:	50                   	push   %eax
f0100953:	e8 98 01 00 00       	call   f0100af0 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100958:	8d 83 6c 0d ff ff    	lea    -0xf294(%ebx),%eax
f010095e:	89 04 24             	mov    %eax,(%esp)
f0100961:	e8 8a 01 00 00       	call   f0100af0 <cprintf>
f0100966:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100969:	8d bb 9f 0b ff ff    	lea    -0xf461(%ebx),%edi
f010096f:	eb 4a                	jmp    f01009bb <monitor+0x83>
f0100971:	83 ec 08             	sub    $0x8,%esp
f0100974:	0f be c0             	movsbl %al,%eax
f0100977:	50                   	push   %eax
f0100978:	57                   	push   %edi
f0100979:	e8 4a 0d 00 00       	call   f01016c8 <strchr>
f010097e:	83 c4 10             	add    $0x10,%esp
f0100981:	85 c0                	test   %eax,%eax
f0100983:	74 08                	je     f010098d <monitor+0x55>
			*buf++ = 0;
f0100985:	c6 06 00             	movb   $0x0,(%esi)
f0100988:	8d 76 01             	lea    0x1(%esi),%esi
f010098b:	eb 79                	jmp    f0100a06 <monitor+0xce>
		if (*buf == 0)
f010098d:	80 3e 00             	cmpb   $0x0,(%esi)
f0100990:	74 7f                	je     f0100a11 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100992:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100996:	74 0f                	je     f01009a7 <monitor+0x6f>
		argv[argc++] = buf;
f0100998:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010099b:	8d 48 01             	lea    0x1(%eax),%ecx
f010099e:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009a1:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009a5:	eb 44                	jmp    f01009eb <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009a7:	83 ec 08             	sub    $0x8,%esp
f01009aa:	6a 10                	push   $0x10
f01009ac:	8d 83 a4 0b ff ff    	lea    -0xf45c(%ebx),%eax
f01009b2:	50                   	push   %eax
f01009b3:	e8 38 01 00 00       	call   f0100af0 <cprintf>
f01009b8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009bb:	8d 83 9b 0b ff ff    	lea    -0xf465(%ebx),%eax
f01009c1:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009c4:	83 ec 0c             	sub    $0xc,%esp
f01009c7:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009ca:	e8 c1 0a 00 00       	call   f0101490 <readline>
f01009cf:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009d1:	83 c4 10             	add    $0x10,%esp
f01009d4:	85 c0                	test   %eax,%eax
f01009d6:	74 ec                	je     f01009c4 <monitor+0x8c>
	argv[argc] = 0;
f01009d8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009df:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009e6:	eb 1e                	jmp    f0100a06 <monitor+0xce>
			buf++;
f01009e8:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009eb:	0f b6 06             	movzbl (%esi),%eax
f01009ee:	84 c0                	test   %al,%al
f01009f0:	74 14                	je     f0100a06 <monitor+0xce>
f01009f2:	83 ec 08             	sub    $0x8,%esp
f01009f5:	0f be c0             	movsbl %al,%eax
f01009f8:	50                   	push   %eax
f01009f9:	57                   	push   %edi
f01009fa:	e8 c9 0c 00 00       	call   f01016c8 <strchr>
f01009ff:	83 c4 10             	add    $0x10,%esp
f0100a02:	85 c0                	test   %eax,%eax
f0100a04:	74 e2                	je     f01009e8 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a06:	0f b6 06             	movzbl (%esi),%eax
f0100a09:	84 c0                	test   %al,%al
f0100a0b:	0f 85 60 ff ff ff    	jne    f0100971 <monitor+0x39>
	argv[argc] = 0;
f0100a11:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a14:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a1b:	00 
	if (argc == 0)
f0100a1c:	85 c0                	test   %eax,%eax
f0100a1e:	74 9b                	je     f01009bb <monitor+0x83>
f0100a20:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a26:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a2d:	83 ec 08             	sub    $0x8,%esp
f0100a30:	ff 36                	pushl  (%esi)
f0100a32:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a35:	e8 30 0c 00 00       	call   f010166a <strcmp>
f0100a3a:	83 c4 10             	add    $0x10,%esp
f0100a3d:	85 c0                	test   %eax,%eax
f0100a3f:	74 29                	je     f0100a6a <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a41:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100a45:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a48:	83 c6 0c             	add    $0xc,%esi
f0100a4b:	83 f8 03             	cmp    $0x3,%eax
f0100a4e:	75 dd                	jne    f0100a2d <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a50:	83 ec 08             	sub    $0x8,%esp
f0100a53:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a56:	8d 83 c1 0b ff ff    	lea    -0xf43f(%ebx),%eax
f0100a5c:	50                   	push   %eax
f0100a5d:	e8 8e 00 00 00       	call   f0100af0 <cprintf>
f0100a62:	83 c4 10             	add    $0x10,%esp
f0100a65:	e9 51 ff ff ff       	jmp    f01009bb <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a6a:	83 ec 04             	sub    $0x4,%esp
f0100a6d:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a70:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a73:	ff 75 08             	pushl  0x8(%ebp)
f0100a76:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a79:	52                   	push   %edx
f0100a7a:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a7d:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a84:	83 c4 10             	add    $0x10,%esp
f0100a87:	85 c0                	test   %eax,%eax
f0100a89:	0f 89 2c ff ff ff    	jns    f01009bb <monitor+0x83>
				break;
	}
}
f0100a8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a92:	5b                   	pop    %ebx
f0100a93:	5e                   	pop    %esi
f0100a94:	5f                   	pop    %edi
f0100a95:	5d                   	pop    %ebp
f0100a96:	c3                   	ret    

f0100a97 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a97:	55                   	push   %ebp
f0100a98:	89 e5                	mov    %esp,%ebp
f0100a9a:	53                   	push   %ebx
f0100a9b:	83 ec 10             	sub    $0x10,%esp
f0100a9e:	e8 19 f7 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100aa3:	81 c3 65 08 01 00    	add    $0x10865,%ebx
	cputchar(ch);
f0100aa9:	ff 75 08             	pushl  0x8(%ebp)
f0100aac:	e8 82 fc ff ff       	call   f0100733 <cputchar>
	*cnt++;
}
f0100ab1:	83 c4 10             	add    $0x10,%esp
f0100ab4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ab7:	c9                   	leave  
f0100ab8:	c3                   	ret    

f0100ab9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100ab9:	55                   	push   %ebp
f0100aba:	89 e5                	mov    %esp,%ebp
f0100abc:	53                   	push   %ebx
f0100abd:	83 ec 14             	sub    $0x14,%esp
f0100ac0:	e8 f7 f6 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100ac5:	81 c3 43 08 01 00    	add    $0x10843,%ebx
	int cnt = 0;
f0100acb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100ad2:	ff 75 0c             	pushl  0xc(%ebp)
f0100ad5:	ff 75 08             	pushl  0x8(%ebp)
f0100ad8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100adb:	50                   	push   %eax
f0100adc:	8d 83 8f f7 fe ff    	lea    -0x10871(%ebx),%eax
f0100ae2:	50                   	push   %eax
f0100ae3:	e8 98 04 00 00       	call   f0100f80 <vprintfmt>
	return cnt;
}
f0100ae8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100aeb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aee:	c9                   	leave  
f0100aef:	c3                   	ret    

f0100af0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100af0:	55                   	push   %ebp
f0100af1:	89 e5                	mov    %esp,%ebp
f0100af3:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100af6:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100af9:	50                   	push   %eax
f0100afa:	ff 75 08             	pushl  0x8(%ebp)
f0100afd:	e8 b7 ff ff ff       	call   f0100ab9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b02:	c9                   	leave  
f0100b03:	c3                   	ret    

f0100b04 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b04:	55                   	push   %ebp
f0100b05:	89 e5                	mov    %esp,%ebp
f0100b07:	57                   	push   %edi
f0100b08:	56                   	push   %esi
f0100b09:	53                   	push   %ebx
f0100b0a:	83 ec 14             	sub    $0x14,%esp
f0100b0d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b10:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b13:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b16:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b19:	8b 32                	mov    (%edx),%esi
f0100b1b:	8b 01                	mov    (%ecx),%eax
f0100b1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b20:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b27:	eb 2f                	jmp    f0100b58 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b29:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b2c:	39 c6                	cmp    %eax,%esi
f0100b2e:	7f 49                	jg     f0100b79 <stab_binsearch+0x75>
f0100b30:	0f b6 0a             	movzbl (%edx),%ecx
f0100b33:	83 ea 0c             	sub    $0xc,%edx
f0100b36:	39 f9                	cmp    %edi,%ecx
f0100b38:	75 ef                	jne    f0100b29 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b3a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b3d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b40:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b44:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b47:	73 35                	jae    f0100b7e <stab_binsearch+0x7a>
			*region_left = m;
f0100b49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b4c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100b4e:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100b51:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b58:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100b5b:	7f 4e                	jg     f0100bab <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100b5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b60:	01 f0                	add    %esi,%eax
f0100b62:	89 c3                	mov    %eax,%ebx
f0100b64:	c1 eb 1f             	shr    $0x1f,%ebx
f0100b67:	01 c3                	add    %eax,%ebx
f0100b69:	d1 fb                	sar    %ebx
f0100b6b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b6e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b71:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100b75:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b77:	eb b3                	jmp    f0100b2c <stab_binsearch+0x28>
			l = true_m + 1;
f0100b79:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100b7c:	eb da                	jmp    f0100b58 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b7e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b81:	76 14                	jbe    f0100b97 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100b83:	83 e8 01             	sub    $0x1,%eax
f0100b86:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b89:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100b8c:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100b8e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b95:	eb c1                	jmp    f0100b58 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b97:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b9a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b9c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100ba0:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100ba2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ba9:	eb ad                	jmp    f0100b58 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100bab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100baf:	74 16                	je     f0100bc7 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bb1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb4:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bb6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bb9:	8b 0e                	mov    (%esi),%ecx
f0100bbb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bbe:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100bc1:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100bc5:	eb 12                	jmp    f0100bd9 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100bc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bca:	8b 00                	mov    (%eax),%eax
f0100bcc:	83 e8 01             	sub    $0x1,%eax
f0100bcf:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100bd2:	89 07                	mov    %eax,(%edi)
f0100bd4:	eb 16                	jmp    f0100bec <stab_binsearch+0xe8>
		     l--)
f0100bd6:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100bd9:	39 c1                	cmp    %eax,%ecx
f0100bdb:	7d 0a                	jge    f0100be7 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100bdd:	0f b6 1a             	movzbl (%edx),%ebx
f0100be0:	83 ea 0c             	sub    $0xc,%edx
f0100be3:	39 fb                	cmp    %edi,%ebx
f0100be5:	75 ef                	jne    f0100bd6 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100be7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bea:	89 07                	mov    %eax,(%edi)
	}
}
f0100bec:	83 c4 14             	add    $0x14,%esp
f0100bef:	5b                   	pop    %ebx
f0100bf0:	5e                   	pop    %esi
f0100bf1:	5f                   	pop    %edi
f0100bf2:	5d                   	pop    %ebp
f0100bf3:	c3                   	ret    

f0100bf4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100bf4:	55                   	push   %ebp
f0100bf5:	89 e5                	mov    %esp,%ebp
f0100bf7:	57                   	push   %edi
f0100bf8:	56                   	push   %esi
f0100bf9:	53                   	push   %ebx
f0100bfa:	83 ec 3c             	sub    $0x3c,%esp
f0100bfd:	e8 ba f5 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100c02:	81 c3 06 07 01 00    	add    $0x10706,%ebx
f0100c08:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100c0b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c0e:	8d 83 94 0d ff ff    	lea    -0xf26c(%ebx),%eax
f0100c14:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100c16:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100c1d:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100c20:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100c27:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100c2a:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c31:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100c37:	0f 86 37 01 00 00    	jbe    f0100d74 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c3d:	c7 c0 f1 5f 10 f0    	mov    $0xf0105ff1,%eax
f0100c43:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100c49:	0f 86 04 02 00 00    	jbe    f0100e53 <debuginfo_eip+0x25f>
f0100c4f:	c7 c0 9b 79 10 f0    	mov    $0xf010799b,%eax
f0100c55:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c59:	0f 85 fb 01 00 00    	jne    f0100e5a <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c5f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c66:	c7 c0 b8 22 10 f0    	mov    $0xf01022b8,%eax
f0100c6c:	c7 c2 f0 5f 10 f0    	mov    $0xf0105ff0,%edx
f0100c72:	29 c2                	sub    %eax,%edx
f0100c74:	c1 fa 02             	sar    $0x2,%edx
f0100c77:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c7d:	83 ea 01             	sub    $0x1,%edx
f0100c80:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c83:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c86:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c89:	83 ec 08             	sub    $0x8,%esp
f0100c8c:	57                   	push   %edi
f0100c8d:	6a 64                	push   $0x64
f0100c8f:	e8 70 fe ff ff       	call   f0100b04 <stab_binsearch>
	if (lfile == 0)
f0100c94:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c97:	83 c4 10             	add    $0x10,%esp
f0100c9a:	85 c0                	test   %eax,%eax
f0100c9c:	0f 84 bf 01 00 00    	je     f0100e61 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ca2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ca5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cab:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100cae:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cb1:	83 ec 08             	sub    $0x8,%esp
f0100cb4:	57                   	push   %edi
f0100cb5:	6a 24                	push   $0x24
f0100cb7:	c7 c0 b8 22 10 f0    	mov    $0xf01022b8,%eax
f0100cbd:	e8 42 fe ff ff       	call   f0100b04 <stab_binsearch>

	if (lfun <= rfun) {
f0100cc2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cc5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100cc8:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100ccb:	83 c4 10             	add    $0x10,%esp
f0100cce:	39 c8                	cmp    %ecx,%eax
f0100cd0:	0f 8f b6 00 00 00    	jg     f0100d8c <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100cd6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cd9:	c7 c1 b8 22 10 f0    	mov    $0xf01022b8,%ecx
f0100cdf:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100ce2:	8b 11                	mov    (%ecx),%edx
f0100ce4:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100ce7:	c7 c2 9b 79 10 f0    	mov    $0xf010799b,%edx
f0100ced:	81 ea f1 5f 10 f0    	sub    $0xf0105ff1,%edx
f0100cf3:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100cf6:	73 0c                	jae    f0100d04 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cf8:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100cfb:	81 c2 f1 5f 10 f0    	add    $0xf0105ff1,%edx
f0100d01:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d04:	8b 51 08             	mov    0x8(%ecx),%edx
f0100d07:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100d0a:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100d0c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100d0f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d12:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d15:	83 ec 08             	sub    $0x8,%esp
f0100d18:	6a 3a                	push   $0x3a
f0100d1a:	ff 76 08             	pushl  0x8(%esi)
f0100d1d:	e8 c7 09 00 00       	call   f01016e9 <strfind>
f0100d22:	2b 46 08             	sub    0x8(%esi),%eax
f0100d25:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular c
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d28:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d2b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d2e:	83 c4 08             	add    $0x8,%esp
f0100d31:	57                   	push   %edi
f0100d32:	6a 44                	push   $0x44
f0100d34:	c7 c0 b8 22 10 f0    	mov    $0xf01022b8,%eax
f0100d3a:	e8 c5 fd ff ff       	call   f0100b04 <stab_binsearch>
	if (lline <= rline)
f0100d3f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100d42:	83 c4 10             	add    $0x10,%esp
f0100d45:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d48:	0f 8f 1a 01 00 00    	jg     f0100e68 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f0100d4e:	89 d0                	mov    %edx,%eax
f0100d50:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d53:	c1 e2 02             	shl    $0x2,%edx
f0100d56:	c7 c1 b8 22 10 f0    	mov    $0xf01022b8,%ecx
f0100d5c:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0100d61:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d67:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0100d6b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0100d6f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100d72:	eb 36                	jmp    f0100daa <debuginfo_eip+0x1b6>
  	        panic("User address");
f0100d74:	83 ec 04             	sub    $0x4,%esp
f0100d77:	8d 83 9e 0d ff ff    	lea    -0xf262(%ebx),%eax
f0100d7d:	50                   	push   %eax
f0100d7e:	6a 7f                	push   $0x7f
f0100d80:	8d 83 ab 0d ff ff    	lea    -0xf255(%ebx),%eax
f0100d86:	50                   	push   %eax
f0100d87:	e8 7a f3 ff ff       	call   f0100106 <_panic>
		info->eip_fn_addr = addr;
f0100d8c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100d8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d92:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100d95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d98:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d9b:	e9 75 ff ff ff       	jmp    f0100d15 <debuginfo_eip+0x121>
f0100da0:	83 e8 01             	sub    $0x1,%eax
f0100da3:	83 ea 0c             	sub    $0xc,%edx
f0100da6:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0100daa:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0100dad:	39 c7                	cmp    %eax,%edi
f0100daf:	7f 24                	jg     f0100dd5 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100db1:	0f b6 0a             	movzbl (%edx),%ecx
f0100db4:	80 f9 84             	cmp    $0x84,%cl
f0100db7:	74 46                	je     f0100dff <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100db9:	80 f9 64             	cmp    $0x64,%cl
f0100dbc:	75 e2                	jne    f0100da0 <debuginfo_eip+0x1ac>
f0100dbe:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0100dc2:	74 dc                	je     f0100da0 <debuginfo_eip+0x1ac>
f0100dc4:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100dc7:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100dcb:	74 3b                	je     f0100e08 <debuginfo_eip+0x214>
f0100dcd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100dd0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100dd3:	eb 33                	jmp    f0100e08 <debuginfo_eip+0x214>
f0100dd5:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100dd8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ddb:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dde:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100de3:	39 fa                	cmp    %edi,%edx
f0100de5:	0f 8d 89 00 00 00    	jge    f0100e74 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0100deb:	83 c2 01             	add    $0x1,%edx
f0100dee:	89 d0                	mov    %edx,%eax
f0100df0:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0100df3:	c7 c2 b8 22 10 f0    	mov    $0xf01022b8,%edx
f0100df9:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100dfd:	eb 3b                	jmp    f0100e3a <debuginfo_eip+0x246>
f0100dff:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e02:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100e06:	75 26                	jne    f0100e2e <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100e08:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e0b:	c7 c0 b8 22 10 f0    	mov    $0xf01022b8,%eax
f0100e11:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100e14:	c7 c0 9b 79 10 f0    	mov    $0xf010799b,%eax
f0100e1a:	81 e8 f1 5f 10 f0    	sub    $0xf0105ff1,%eax
f0100e20:	39 c2                	cmp    %eax,%edx
f0100e22:	73 b4                	jae    f0100dd8 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100e24:	81 c2 f1 5f 10 f0    	add    $0xf0105ff1,%edx
f0100e2a:	89 16                	mov    %edx,(%esi)
f0100e2c:	eb aa                	jmp    f0100dd8 <debuginfo_eip+0x1e4>
f0100e2e:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100e31:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e34:	eb d2                	jmp    f0100e08 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0100e36:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100e3a:	39 c7                	cmp    %eax,%edi
f0100e3c:	7e 31                	jle    f0100e6f <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e3e:	0f b6 0a             	movzbl (%edx),%ecx
f0100e41:	83 c0 01             	add    $0x1,%eax
f0100e44:	83 c2 0c             	add    $0xc,%edx
f0100e47:	80 f9 a0             	cmp    $0xa0,%cl
f0100e4a:	74 ea                	je     f0100e36 <debuginfo_eip+0x242>
	return 0;
f0100e4c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e51:	eb 21                	jmp    f0100e74 <debuginfo_eip+0x280>
		return -1;
f0100e53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e58:	eb 1a                	jmp    f0100e74 <debuginfo_eip+0x280>
f0100e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e5f:	eb 13                	jmp    f0100e74 <debuginfo_eip+0x280>
		return -1;
f0100e61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e66:	eb 0c                	jmp    f0100e74 <debuginfo_eip+0x280>
		return -1;
f0100e68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e6d:	eb 05                	jmp    f0100e74 <debuginfo_eip+0x280>
	return 0;
f0100e6f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e74:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e77:	5b                   	pop    %ebx
f0100e78:	5e                   	pop    %esi
f0100e79:	5f                   	pop    %edi
f0100e7a:	5d                   	pop    %ebp
f0100e7b:	c3                   	ret    

f0100e7c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e7c:	55                   	push   %ebp
f0100e7d:	89 e5                	mov    %esp,%ebp
f0100e7f:	57                   	push   %edi
f0100e80:	56                   	push   %esi
f0100e81:	53                   	push   %ebx
f0100e82:	83 ec 2c             	sub    $0x2c,%esp
f0100e85:	e8 02 06 00 00       	call   f010148c <__x86.get_pc_thunk.cx>
f0100e8a:	81 c1 7e 04 01 00    	add    $0x1047e,%ecx
f0100e90:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e93:	89 c7                	mov    %eax,%edi
f0100e95:	89 d6                	mov    %edx,%esi
f0100e97:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e9a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e9d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ea0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ea3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100ea6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100eab:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100eae:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100eb1:	39 d3                	cmp    %edx,%ebx
f0100eb3:	72 09                	jb     f0100ebe <printnum+0x42>
f0100eb5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100eb8:	0f 87 83 00 00 00    	ja     f0100f41 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ebe:	83 ec 0c             	sub    $0xc,%esp
f0100ec1:	ff 75 18             	pushl  0x18(%ebp)
f0100ec4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100eca:	53                   	push   %ebx
f0100ecb:	ff 75 10             	pushl  0x10(%ebp)
f0100ece:	83 ec 08             	sub    $0x8,%esp
f0100ed1:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ed4:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ed7:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100eda:	ff 75 d0             	pushl  -0x30(%ebp)
f0100edd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ee0:	e8 2b 0a 00 00       	call   f0101910 <__udivdi3>
f0100ee5:	83 c4 18             	add    $0x18,%esp
f0100ee8:	52                   	push   %edx
f0100ee9:	50                   	push   %eax
f0100eea:	89 f2                	mov    %esi,%edx
f0100eec:	89 f8                	mov    %edi,%eax
f0100eee:	e8 89 ff ff ff       	call   f0100e7c <printnum>
f0100ef3:	83 c4 20             	add    $0x20,%esp
f0100ef6:	eb 13                	jmp    f0100f0b <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ef8:	83 ec 08             	sub    $0x8,%esp
f0100efb:	56                   	push   %esi
f0100efc:	ff 75 18             	pushl  0x18(%ebp)
f0100eff:	ff d7                	call   *%edi
f0100f01:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100f04:	83 eb 01             	sub    $0x1,%ebx
f0100f07:	85 db                	test   %ebx,%ebx
f0100f09:	7f ed                	jg     f0100ef8 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f0b:	83 ec 08             	sub    $0x8,%esp
f0100f0e:	56                   	push   %esi
f0100f0f:	83 ec 04             	sub    $0x4,%esp
f0100f12:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f15:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f18:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f1b:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f1e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100f21:	89 f3                	mov    %esi,%ebx
f0100f23:	e8 08 0b 00 00       	call   f0101a30 <__umoddi3>
f0100f28:	83 c4 14             	add    $0x14,%esp
f0100f2b:	0f be 84 06 b9 0d ff 	movsbl -0xf247(%esi,%eax,1),%eax
f0100f32:	ff 
f0100f33:	50                   	push   %eax
f0100f34:	ff d7                	call   *%edi
}
f0100f36:	83 c4 10             	add    $0x10,%esp
f0100f39:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f3c:	5b                   	pop    %ebx
f0100f3d:	5e                   	pop    %esi
f0100f3e:	5f                   	pop    %edi
f0100f3f:	5d                   	pop    %ebp
f0100f40:	c3                   	ret    
f0100f41:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100f44:	eb be                	jmp    f0100f04 <printnum+0x88>

f0100f46 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f4c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f50:	8b 10                	mov    (%eax),%edx
f0100f52:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f55:	73 0a                	jae    f0100f61 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f57:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f5a:	89 08                	mov    %ecx,(%eax)
f0100f5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f5f:	88 02                	mov    %al,(%edx)
}
f0100f61:	5d                   	pop    %ebp
f0100f62:	c3                   	ret    

f0100f63 <printfmt>:
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
f0100f66:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f69:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f6c:	50                   	push   %eax
f0100f6d:	ff 75 10             	pushl  0x10(%ebp)
f0100f70:	ff 75 0c             	pushl  0xc(%ebp)
f0100f73:	ff 75 08             	pushl  0x8(%ebp)
f0100f76:	e8 05 00 00 00       	call   f0100f80 <vprintfmt>
}
f0100f7b:	83 c4 10             	add    $0x10,%esp
f0100f7e:	c9                   	leave  
f0100f7f:	c3                   	ret    

f0100f80 <vprintfmt>:
{
f0100f80:	55                   	push   %ebp
f0100f81:	89 e5                	mov    %esp,%ebp
f0100f83:	57                   	push   %edi
f0100f84:	56                   	push   %esi
f0100f85:	53                   	push   %ebx
f0100f86:	83 ec 2c             	sub    $0x2c,%esp
f0100f89:	e8 2e f2 ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f0100f8e:	81 c3 7a 03 01 00    	add    $0x1037a,%ebx
f0100f94:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f97:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f9a:	e9 c3 03 00 00       	jmp    f0101362 <.L35+0x48>
		padc = ' ';
f0100f9f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100fa3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100faa:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0100fb1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100fb8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fbd:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fc0:	8d 47 01             	lea    0x1(%edi),%eax
f0100fc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fc6:	0f b6 17             	movzbl (%edi),%edx
f0100fc9:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100fcc:	3c 55                	cmp    $0x55,%al
f0100fce:	0f 87 16 04 00 00    	ja     f01013ea <.L22>
f0100fd4:	0f b6 c0             	movzbl %al,%eax
f0100fd7:	89 d9                	mov    %ebx,%ecx
f0100fd9:	03 8c 83 48 0e ff ff 	add    -0xf1b8(%ebx,%eax,4),%ecx
f0100fe0:	ff e1                	jmp    *%ecx

f0100fe2 <.L69>:
f0100fe2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100fe5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100fe9:	eb d5                	jmp    f0100fc0 <vprintfmt+0x40>

f0100feb <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100feb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100fee:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ff2:	eb cc                	jmp    f0100fc0 <vprintfmt+0x40>

f0100ff4 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff4:	0f b6 d2             	movzbl %dl,%edx
f0100ff7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100ffa:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100fff:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101002:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101006:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101009:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010100c:	83 f9 09             	cmp    $0x9,%ecx
f010100f:	77 55                	ja     f0101066 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0101011:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101014:	eb e9                	jmp    f0100fff <.L29+0xb>

f0101016 <.L26>:
			precision = va_arg(ap, int);
f0101016:	8b 45 14             	mov    0x14(%ebp),%eax
f0101019:	8b 00                	mov    (%eax),%eax
f010101b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010101e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101021:	8d 40 04             	lea    0x4(%eax),%eax
f0101024:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101027:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010102a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010102e:	79 90                	jns    f0100fc0 <vprintfmt+0x40>
				width = precision, precision = -1;
f0101030:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101033:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101036:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f010103d:	eb 81                	jmp    f0100fc0 <vprintfmt+0x40>

f010103f <.L27>:
f010103f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101042:	85 c0                	test   %eax,%eax
f0101044:	ba 00 00 00 00       	mov    $0x0,%edx
f0101049:	0f 49 d0             	cmovns %eax,%edx
f010104c:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010104f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101052:	e9 69 ff ff ff       	jmp    f0100fc0 <vprintfmt+0x40>

f0101057 <.L23>:
f0101057:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010105a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101061:	e9 5a ff ff ff       	jmp    f0100fc0 <vprintfmt+0x40>
f0101066:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101069:	eb bf                	jmp    f010102a <.L26+0x14>

f010106b <.L33>:
			lflag++;
f010106b:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010106f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101072:	e9 49 ff ff ff       	jmp    f0100fc0 <vprintfmt+0x40>

f0101077 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101077:	8b 45 14             	mov    0x14(%ebp),%eax
f010107a:	8d 78 04             	lea    0x4(%eax),%edi
f010107d:	83 ec 08             	sub    $0x8,%esp
f0101080:	56                   	push   %esi
f0101081:	ff 30                	pushl  (%eax)
f0101083:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101086:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101089:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010108c:	e9 ce 02 00 00       	jmp    f010135f <.L35+0x45>

f0101091 <.L32>:
			err = va_arg(ap, int);
f0101091:	8b 45 14             	mov    0x14(%ebp),%eax
f0101094:	8d 78 04             	lea    0x4(%eax),%edi
f0101097:	8b 00                	mov    (%eax),%eax
f0101099:	99                   	cltd   
f010109a:	31 d0                	xor    %edx,%eax
f010109c:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010109e:	83 f8 06             	cmp    $0x6,%eax
f01010a1:	7f 27                	jg     f01010ca <.L32+0x39>
f01010a3:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f01010aa:	85 d2                	test   %edx,%edx
f01010ac:	74 1c                	je     f01010ca <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01010ae:	52                   	push   %edx
f01010af:	8d 83 da 0d ff ff    	lea    -0xf226(%ebx),%eax
f01010b5:	50                   	push   %eax
f01010b6:	56                   	push   %esi
f01010b7:	ff 75 08             	pushl  0x8(%ebp)
f01010ba:	e8 a4 fe ff ff       	call   f0100f63 <printfmt>
f01010bf:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010c2:	89 7d 14             	mov    %edi,0x14(%ebp)
f01010c5:	e9 95 02 00 00       	jmp    f010135f <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01010ca:	50                   	push   %eax
f01010cb:	8d 83 d1 0d ff ff    	lea    -0xf22f(%ebx),%eax
f01010d1:	50                   	push   %eax
f01010d2:	56                   	push   %esi
f01010d3:	ff 75 08             	pushl  0x8(%ebp)
f01010d6:	e8 88 fe ff ff       	call   f0100f63 <printfmt>
f01010db:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010de:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010e1:	e9 79 02 00 00       	jmp    f010135f <.L35+0x45>

f01010e6 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01010e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e9:	83 c0 04             	add    $0x4,%eax
f01010ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01010f4:	85 ff                	test   %edi,%edi
f01010f6:	8d 83 ca 0d ff ff    	lea    -0xf236(%ebx),%eax
f01010fc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01010ff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101103:	0f 8e b5 00 00 00    	jle    f01011be <.L36+0xd8>
f0101109:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010110d:	75 08                	jne    f0101117 <.L36+0x31>
f010110f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101112:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101115:	eb 6d                	jmp    f0101184 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101117:	83 ec 08             	sub    $0x8,%esp
f010111a:	ff 75 cc             	pushl  -0x34(%ebp)
f010111d:	57                   	push   %edi
f010111e:	e8 82 04 00 00       	call   f01015a5 <strnlen>
f0101123:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101126:	29 c2                	sub    %eax,%edx
f0101128:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010112b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010112e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101132:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101135:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101138:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010113a:	eb 10                	jmp    f010114c <.L36+0x66>
					putch(padc, putdat);
f010113c:	83 ec 08             	sub    $0x8,%esp
f010113f:	56                   	push   %esi
f0101140:	ff 75 e0             	pushl  -0x20(%ebp)
f0101143:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101146:	83 ef 01             	sub    $0x1,%edi
f0101149:	83 c4 10             	add    $0x10,%esp
f010114c:	85 ff                	test   %edi,%edi
f010114e:	7f ec                	jg     f010113c <.L36+0x56>
f0101150:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101153:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101156:	85 d2                	test   %edx,%edx
f0101158:	b8 00 00 00 00       	mov    $0x0,%eax
f010115d:	0f 49 c2             	cmovns %edx,%eax
f0101160:	29 c2                	sub    %eax,%edx
f0101162:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101165:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101168:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010116b:	eb 17                	jmp    f0101184 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010116d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101171:	75 30                	jne    f01011a3 <.L36+0xbd>
					putch(ch, putdat);
f0101173:	83 ec 08             	sub    $0x8,%esp
f0101176:	ff 75 0c             	pushl  0xc(%ebp)
f0101179:	50                   	push   %eax
f010117a:	ff 55 08             	call   *0x8(%ebp)
f010117d:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101180:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101184:	83 c7 01             	add    $0x1,%edi
f0101187:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010118b:	0f be c2             	movsbl %dl,%eax
f010118e:	85 c0                	test   %eax,%eax
f0101190:	74 52                	je     f01011e4 <.L36+0xfe>
f0101192:	85 f6                	test   %esi,%esi
f0101194:	78 d7                	js     f010116d <.L36+0x87>
f0101196:	83 ee 01             	sub    $0x1,%esi
f0101199:	79 d2                	jns    f010116d <.L36+0x87>
f010119b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010119e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011a1:	eb 32                	jmp    f01011d5 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01011a3:	0f be d2             	movsbl %dl,%edx
f01011a6:	83 ea 20             	sub    $0x20,%edx
f01011a9:	83 fa 5e             	cmp    $0x5e,%edx
f01011ac:	76 c5                	jbe    f0101173 <.L36+0x8d>
					putch('?', putdat);
f01011ae:	83 ec 08             	sub    $0x8,%esp
f01011b1:	ff 75 0c             	pushl  0xc(%ebp)
f01011b4:	6a 3f                	push   $0x3f
f01011b6:	ff 55 08             	call   *0x8(%ebp)
f01011b9:	83 c4 10             	add    $0x10,%esp
f01011bc:	eb c2                	jmp    f0101180 <.L36+0x9a>
f01011be:	89 75 0c             	mov    %esi,0xc(%ebp)
f01011c1:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01011c4:	eb be                	jmp    f0101184 <.L36+0x9e>
				putch(' ', putdat);
f01011c6:	83 ec 08             	sub    $0x8,%esp
f01011c9:	56                   	push   %esi
f01011ca:	6a 20                	push   $0x20
f01011cc:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01011cf:	83 ef 01             	sub    $0x1,%edi
f01011d2:	83 c4 10             	add    $0x10,%esp
f01011d5:	85 ff                	test   %edi,%edi
f01011d7:	7f ed                	jg     f01011c6 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01011d9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011dc:	89 45 14             	mov    %eax,0x14(%ebp)
f01011df:	e9 7b 01 00 00       	jmp    f010135f <.L35+0x45>
f01011e4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011ea:	eb e9                	jmp    f01011d5 <.L36+0xef>

f01011ec <.L31>:
f01011ec:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01011ef:	83 f9 01             	cmp    $0x1,%ecx
f01011f2:	7e 40                	jle    f0101234 <.L31+0x48>
		return va_arg(*ap, long long);
f01011f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f7:	8b 50 04             	mov    0x4(%eax),%edx
f01011fa:	8b 00                	mov    (%eax),%eax
f01011fc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011ff:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101202:	8b 45 14             	mov    0x14(%ebp),%eax
f0101205:	8d 40 08             	lea    0x8(%eax),%eax
f0101208:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010120b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010120f:	79 55                	jns    f0101266 <.L31+0x7a>
				putch('-', putdat);
f0101211:	83 ec 08             	sub    $0x8,%esp
f0101214:	56                   	push   %esi
f0101215:	6a 2d                	push   $0x2d
f0101217:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010121a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010121d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101220:	f7 da                	neg    %edx
f0101222:	83 d1 00             	adc    $0x0,%ecx
f0101225:	f7 d9                	neg    %ecx
f0101227:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010122a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010122f:	e9 10 01 00 00       	jmp    f0101344 <.L35+0x2a>
	else if (lflag)
f0101234:	85 c9                	test   %ecx,%ecx
f0101236:	75 17                	jne    f010124f <.L31+0x63>
		return va_arg(*ap, int);
f0101238:	8b 45 14             	mov    0x14(%ebp),%eax
f010123b:	8b 00                	mov    (%eax),%eax
f010123d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101240:	99                   	cltd   
f0101241:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101244:	8b 45 14             	mov    0x14(%ebp),%eax
f0101247:	8d 40 04             	lea    0x4(%eax),%eax
f010124a:	89 45 14             	mov    %eax,0x14(%ebp)
f010124d:	eb bc                	jmp    f010120b <.L31+0x1f>
		return va_arg(*ap, long);
f010124f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101252:	8b 00                	mov    (%eax),%eax
f0101254:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101257:	99                   	cltd   
f0101258:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010125b:	8b 45 14             	mov    0x14(%ebp),%eax
f010125e:	8d 40 04             	lea    0x4(%eax),%eax
f0101261:	89 45 14             	mov    %eax,0x14(%ebp)
f0101264:	eb a5                	jmp    f010120b <.L31+0x1f>
			num = getint(&ap, lflag);
f0101266:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101269:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010126c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101271:	e9 ce 00 00 00       	jmp    f0101344 <.L35+0x2a>

f0101276 <.L37>:
f0101276:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101279:	83 f9 01             	cmp    $0x1,%ecx
f010127c:	7e 18                	jle    f0101296 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f010127e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101281:	8b 10                	mov    (%eax),%edx
f0101283:	8b 48 04             	mov    0x4(%eax),%ecx
f0101286:	8d 40 08             	lea    0x8(%eax),%eax
f0101289:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010128c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101291:	e9 ae 00 00 00       	jmp    f0101344 <.L35+0x2a>
	else if (lflag)
f0101296:	85 c9                	test   %ecx,%ecx
f0101298:	75 1a                	jne    f01012b4 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f010129a:	8b 45 14             	mov    0x14(%ebp),%eax
f010129d:	8b 10                	mov    (%eax),%edx
f010129f:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012a4:	8d 40 04             	lea    0x4(%eax),%eax
f01012a7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012aa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012af:	e9 90 00 00 00       	jmp    f0101344 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01012b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b7:	8b 10                	mov    (%eax),%edx
f01012b9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012be:	8d 40 04             	lea    0x4(%eax),%eax
f01012c1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01012c4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012c9:	eb 79                	jmp    f0101344 <.L35+0x2a>

f01012cb <.L34>:
f01012cb:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01012ce:	83 f9 01             	cmp    $0x1,%ecx
f01012d1:	7e 15                	jle    f01012e8 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f01012d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d6:	8b 10                	mov    (%eax),%edx
f01012d8:	8b 48 04             	mov    0x4(%eax),%ecx
f01012db:	8d 40 08             	lea    0x8(%eax),%eax
f01012de:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012e1:	b8 08 00 00 00       	mov    $0x8,%eax
f01012e6:	eb 5c                	jmp    f0101344 <.L35+0x2a>
	else if (lflag)
f01012e8:	85 c9                	test   %ecx,%ecx
f01012ea:	75 17                	jne    f0101303 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f01012ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ef:	8b 10                	mov    (%eax),%edx
f01012f1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012f6:	8d 40 04             	lea    0x4(%eax),%eax
f01012f9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f01012fc:	b8 08 00 00 00       	mov    $0x8,%eax
f0101301:	eb 41                	jmp    f0101344 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101303:	8b 45 14             	mov    0x14(%ebp),%eax
f0101306:	8b 10                	mov    (%eax),%edx
f0101308:	b9 00 00 00 00       	mov    $0x0,%ecx
f010130d:	8d 40 04             	lea    0x4(%eax),%eax
f0101310:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0101313:	b8 08 00 00 00       	mov    $0x8,%eax
f0101318:	eb 2a                	jmp    f0101344 <.L35+0x2a>

f010131a <.L35>:
			putch('0', putdat);
f010131a:	83 ec 08             	sub    $0x8,%esp
f010131d:	56                   	push   %esi
f010131e:	6a 30                	push   $0x30
f0101320:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101323:	83 c4 08             	add    $0x8,%esp
f0101326:	56                   	push   %esi
f0101327:	6a 78                	push   $0x78
f0101329:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010132c:	8b 45 14             	mov    0x14(%ebp),%eax
f010132f:	8b 10                	mov    (%eax),%edx
f0101331:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101336:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101339:	8d 40 04             	lea    0x4(%eax),%eax
f010133c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010133f:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101344:	83 ec 0c             	sub    $0xc,%esp
f0101347:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010134b:	57                   	push   %edi
f010134c:	ff 75 e0             	pushl  -0x20(%ebp)
f010134f:	50                   	push   %eax
f0101350:	51                   	push   %ecx
f0101351:	52                   	push   %edx
f0101352:	89 f2                	mov    %esi,%edx
f0101354:	8b 45 08             	mov    0x8(%ebp),%eax
f0101357:	e8 20 fb ff ff       	call   f0100e7c <printnum>
			break;
f010135c:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010135f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101362:	83 c7 01             	add    $0x1,%edi
f0101365:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101369:	83 f8 25             	cmp    $0x25,%eax
f010136c:	0f 84 2d fc ff ff    	je     f0100f9f <vprintfmt+0x1f>
			if (ch == '\0')
f0101372:	85 c0                	test   %eax,%eax
f0101374:	0f 84 91 00 00 00    	je     f010140b <.L22+0x21>
			putch(ch, putdat);
f010137a:	83 ec 08             	sub    $0x8,%esp
f010137d:	56                   	push   %esi
f010137e:	50                   	push   %eax
f010137f:	ff 55 08             	call   *0x8(%ebp)
f0101382:	83 c4 10             	add    $0x10,%esp
f0101385:	eb db                	jmp    f0101362 <.L35+0x48>

f0101387 <.L38>:
f0101387:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010138a:	83 f9 01             	cmp    $0x1,%ecx
f010138d:	7e 15                	jle    f01013a4 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010138f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101392:	8b 10                	mov    (%eax),%edx
f0101394:	8b 48 04             	mov    0x4(%eax),%ecx
f0101397:	8d 40 08             	lea    0x8(%eax),%eax
f010139a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010139d:	b8 10 00 00 00       	mov    $0x10,%eax
f01013a2:	eb a0                	jmp    f0101344 <.L35+0x2a>
	else if (lflag)
f01013a4:	85 c9                	test   %ecx,%ecx
f01013a6:	75 17                	jne    f01013bf <.L38+0x38>
		return va_arg(*ap, unsigned int);
f01013a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ab:	8b 10                	mov    (%eax),%edx
f01013ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013b2:	8d 40 04             	lea    0x4(%eax),%eax
f01013b5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013b8:	b8 10 00 00 00       	mov    $0x10,%eax
f01013bd:	eb 85                	jmp    f0101344 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01013bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01013c2:	8b 10                	mov    (%eax),%edx
f01013c4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013c9:	8d 40 04             	lea    0x4(%eax),%eax
f01013cc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01013cf:	b8 10 00 00 00       	mov    $0x10,%eax
f01013d4:	e9 6b ff ff ff       	jmp    f0101344 <.L35+0x2a>

f01013d9 <.L25>:
			putch(ch, putdat);
f01013d9:	83 ec 08             	sub    $0x8,%esp
f01013dc:	56                   	push   %esi
f01013dd:	6a 25                	push   $0x25
f01013df:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	e9 75 ff ff ff       	jmp    f010135f <.L35+0x45>

f01013ea <.L22>:
			putch('%', putdat);
f01013ea:	83 ec 08             	sub    $0x8,%esp
f01013ed:	56                   	push   %esi
f01013ee:	6a 25                	push   $0x25
f01013f0:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013f3:	83 c4 10             	add    $0x10,%esp
f01013f6:	89 f8                	mov    %edi,%eax
f01013f8:	eb 03                	jmp    f01013fd <.L22+0x13>
f01013fa:	83 e8 01             	sub    $0x1,%eax
f01013fd:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101401:	75 f7                	jne    f01013fa <.L22+0x10>
f0101403:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101406:	e9 54 ff ff ff       	jmp    f010135f <.L35+0x45>
}
f010140b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010140e:	5b                   	pop    %ebx
f010140f:	5e                   	pop    %esi
f0101410:	5f                   	pop    %edi
f0101411:	5d                   	pop    %ebp
f0101412:	c3                   	ret    

f0101413 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101413:	55                   	push   %ebp
f0101414:	89 e5                	mov    %esp,%ebp
f0101416:	53                   	push   %ebx
f0101417:	83 ec 14             	sub    $0x14,%esp
f010141a:	e8 9d ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010141f:	81 c3 e9 fe 00 00    	add    $0xfee9,%ebx
f0101425:	8b 45 08             	mov    0x8(%ebp),%eax
f0101428:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010142b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010142e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101432:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101435:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010143c:	85 c0                	test   %eax,%eax
f010143e:	74 2b                	je     f010146b <vsnprintf+0x58>
f0101440:	85 d2                	test   %edx,%edx
f0101442:	7e 27                	jle    f010146b <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101444:	ff 75 14             	pushl  0x14(%ebp)
f0101447:	ff 75 10             	pushl  0x10(%ebp)
f010144a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010144d:	50                   	push   %eax
f010144e:	8d 83 3e fc fe ff    	lea    -0x103c2(%ebx),%eax
f0101454:	50                   	push   %eax
f0101455:	e8 26 fb ff ff       	call   f0100f80 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010145a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010145d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101460:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101463:	83 c4 10             	add    $0x10,%esp
}
f0101466:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101469:	c9                   	leave  
f010146a:	c3                   	ret    
		return -E_INVAL;
f010146b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101470:	eb f4                	jmp    f0101466 <vsnprintf+0x53>

f0101472 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101472:	55                   	push   %ebp
f0101473:	89 e5                	mov    %esp,%ebp
f0101475:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101478:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010147b:	50                   	push   %eax
f010147c:	ff 75 10             	pushl  0x10(%ebp)
f010147f:	ff 75 0c             	pushl  0xc(%ebp)
f0101482:	ff 75 08             	pushl  0x8(%ebp)
f0101485:	e8 89 ff ff ff       	call   f0101413 <vsnprintf>
	va_end(ap);

	return rc;
}
f010148a:	c9                   	leave  
f010148b:	c3                   	ret    

f010148c <__x86.get_pc_thunk.cx>:
f010148c:	8b 0c 24             	mov    (%esp),%ecx
f010148f:	c3                   	ret    

f0101490 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101490:	55                   	push   %ebp
f0101491:	89 e5                	mov    %esp,%ebp
f0101493:	57                   	push   %edi
f0101494:	56                   	push   %esi
f0101495:	53                   	push   %ebx
f0101496:	83 ec 1c             	sub    $0x1c,%esp
f0101499:	e8 1e ed ff ff       	call   f01001bc <__x86.get_pc_thunk.bx>
f010149e:	81 c3 6a fe 00 00    	add    $0xfe6a,%ebx
f01014a4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01014a7:	85 c0                	test   %eax,%eax
f01014a9:	74 13                	je     f01014be <readline+0x2e>
		cprintf("%s", prompt);
f01014ab:	83 ec 08             	sub    $0x8,%esp
f01014ae:	50                   	push   %eax
f01014af:	8d 83 da 0d ff ff    	lea    -0xf226(%ebx),%eax
f01014b5:	50                   	push   %eax
f01014b6:	e8 35 f6 ff ff       	call   f0100af0 <cprintf>
f01014bb:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01014be:	83 ec 0c             	sub    $0xc,%esp
f01014c1:	6a 00                	push   $0x0
f01014c3:	e8 8c f2 ff ff       	call   f0100754 <iscons>
f01014c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014cb:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01014ce:	bf 00 00 00 00       	mov    $0x0,%edi
f01014d3:	eb 46                	jmp    f010151b <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01014d5:	83 ec 08             	sub    $0x8,%esp
f01014d8:	50                   	push   %eax
f01014d9:	8d 83 a0 0f ff ff    	lea    -0xf060(%ebx),%eax
f01014df:	50                   	push   %eax
f01014e0:	e8 0b f6 ff ff       	call   f0100af0 <cprintf>
			return NULL;
f01014e5:	83 c4 10             	add    $0x10,%esp
f01014e8:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01014ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014f0:	5b                   	pop    %ebx
f01014f1:	5e                   	pop    %esi
f01014f2:	5f                   	pop    %edi
f01014f3:	5d                   	pop    %ebp
f01014f4:	c3                   	ret    
			if (echoing)
f01014f5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014f9:	75 05                	jne    f0101500 <readline+0x70>
			i--;
f01014fb:	83 ef 01             	sub    $0x1,%edi
f01014fe:	eb 1b                	jmp    f010151b <readline+0x8b>
				cputchar('\b');
f0101500:	83 ec 0c             	sub    $0xc,%esp
f0101503:	6a 08                	push   $0x8
f0101505:	e8 29 f2 ff ff       	call   f0100733 <cputchar>
f010150a:	83 c4 10             	add    $0x10,%esp
f010150d:	eb ec                	jmp    f01014fb <readline+0x6b>
			buf[i++] = c;
f010150f:	89 f0                	mov    %esi,%eax
f0101511:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101518:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010151b:	e8 23 f2 ff ff       	call   f0100743 <getchar>
f0101520:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101522:	85 c0                	test   %eax,%eax
f0101524:	78 af                	js     f01014d5 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101526:	83 f8 08             	cmp    $0x8,%eax
f0101529:	0f 94 c2             	sete   %dl
f010152c:	83 f8 7f             	cmp    $0x7f,%eax
f010152f:	0f 94 c0             	sete   %al
f0101532:	08 c2                	or     %al,%dl
f0101534:	74 04                	je     f010153a <readline+0xaa>
f0101536:	85 ff                	test   %edi,%edi
f0101538:	7f bb                	jg     f01014f5 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010153a:	83 fe 1f             	cmp    $0x1f,%esi
f010153d:	7e 1c                	jle    f010155b <readline+0xcb>
f010153f:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101545:	7f 14                	jg     f010155b <readline+0xcb>
			if (echoing)
f0101547:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010154b:	74 c2                	je     f010150f <readline+0x7f>
				cputchar(c);
f010154d:	83 ec 0c             	sub    $0xc,%esp
f0101550:	56                   	push   %esi
f0101551:	e8 dd f1 ff ff       	call   f0100733 <cputchar>
f0101556:	83 c4 10             	add    $0x10,%esp
f0101559:	eb b4                	jmp    f010150f <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010155b:	83 fe 0a             	cmp    $0xa,%esi
f010155e:	74 05                	je     f0101565 <readline+0xd5>
f0101560:	83 fe 0d             	cmp    $0xd,%esi
f0101563:	75 b6                	jne    f010151b <readline+0x8b>
			if (echoing)
f0101565:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101569:	75 13                	jne    f010157e <readline+0xee>
			buf[i] = 0;
f010156b:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f0101572:	00 
			return buf;
f0101573:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101579:	e9 6f ff ff ff       	jmp    f01014ed <readline+0x5d>
				cputchar('\n');
f010157e:	83 ec 0c             	sub    $0xc,%esp
f0101581:	6a 0a                	push   $0xa
f0101583:	e8 ab f1 ff ff       	call   f0100733 <cputchar>
f0101588:	83 c4 10             	add    $0x10,%esp
f010158b:	eb de                	jmp    f010156b <readline+0xdb>

f010158d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010158d:	55                   	push   %ebp
f010158e:	89 e5                	mov    %esp,%ebp
f0101590:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101593:	b8 00 00 00 00       	mov    $0x0,%eax
f0101598:	eb 03                	jmp    f010159d <strlen+0x10>
		n++;
f010159a:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010159d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01015a1:	75 f7                	jne    f010159a <strlen+0xd>
	return n;
}
f01015a3:	5d                   	pop    %ebp
f01015a4:	c3                   	ret    

f01015a5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01015a5:	55                   	push   %ebp
f01015a6:	89 e5                	mov    %esp,%ebp
f01015a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b3:	eb 03                	jmp    f01015b8 <strnlen+0x13>
		n++;
f01015b5:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01015b8:	39 d0                	cmp    %edx,%eax
f01015ba:	74 06                	je     f01015c2 <strnlen+0x1d>
f01015bc:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01015c0:	75 f3                	jne    f01015b5 <strnlen+0x10>
	return n;
}
f01015c2:	5d                   	pop    %ebp
f01015c3:	c3                   	ret    

f01015c4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01015c4:	55                   	push   %ebp
f01015c5:	89 e5                	mov    %esp,%ebp
f01015c7:	53                   	push   %ebx
f01015c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01015ce:	89 c2                	mov    %eax,%edx
f01015d0:	83 c1 01             	add    $0x1,%ecx
f01015d3:	83 c2 01             	add    $0x1,%edx
f01015d6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01015da:	88 5a ff             	mov    %bl,-0x1(%edx)
f01015dd:	84 db                	test   %bl,%bl
f01015df:	75 ef                	jne    f01015d0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01015e1:	5b                   	pop    %ebx
f01015e2:	5d                   	pop    %ebp
f01015e3:	c3                   	ret    

f01015e4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015e4:	55                   	push   %ebp
f01015e5:	89 e5                	mov    %esp,%ebp
f01015e7:	53                   	push   %ebx
f01015e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015eb:	53                   	push   %ebx
f01015ec:	e8 9c ff ff ff       	call   f010158d <strlen>
f01015f1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01015f4:	ff 75 0c             	pushl  0xc(%ebp)
f01015f7:	01 d8                	add    %ebx,%eax
f01015f9:	50                   	push   %eax
f01015fa:	e8 c5 ff ff ff       	call   f01015c4 <strcpy>
	return dst;
}
f01015ff:	89 d8                	mov    %ebx,%eax
f0101601:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101604:	c9                   	leave  
f0101605:	c3                   	ret    

f0101606 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101606:	55                   	push   %ebp
f0101607:	89 e5                	mov    %esp,%ebp
f0101609:	56                   	push   %esi
f010160a:	53                   	push   %ebx
f010160b:	8b 75 08             	mov    0x8(%ebp),%esi
f010160e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101611:	89 f3                	mov    %esi,%ebx
f0101613:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101616:	89 f2                	mov    %esi,%edx
f0101618:	eb 0f                	jmp    f0101629 <strncpy+0x23>
		*dst++ = *src;
f010161a:	83 c2 01             	add    $0x1,%edx
f010161d:	0f b6 01             	movzbl (%ecx),%eax
f0101620:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101623:	80 39 01             	cmpb   $0x1,(%ecx)
f0101626:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101629:	39 da                	cmp    %ebx,%edx
f010162b:	75 ed                	jne    f010161a <strncpy+0x14>
	}
	return ret;
}
f010162d:	89 f0                	mov    %esi,%eax
f010162f:	5b                   	pop    %ebx
f0101630:	5e                   	pop    %esi
f0101631:	5d                   	pop    %ebp
f0101632:	c3                   	ret    

f0101633 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101633:	55                   	push   %ebp
f0101634:	89 e5                	mov    %esp,%ebp
f0101636:	56                   	push   %esi
f0101637:	53                   	push   %ebx
f0101638:	8b 75 08             	mov    0x8(%ebp),%esi
f010163b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010163e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101641:	89 f0                	mov    %esi,%eax
f0101643:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101647:	85 c9                	test   %ecx,%ecx
f0101649:	75 0b                	jne    f0101656 <strlcpy+0x23>
f010164b:	eb 17                	jmp    f0101664 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010164d:	83 c2 01             	add    $0x1,%edx
f0101650:	83 c0 01             	add    $0x1,%eax
f0101653:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101656:	39 d8                	cmp    %ebx,%eax
f0101658:	74 07                	je     f0101661 <strlcpy+0x2e>
f010165a:	0f b6 0a             	movzbl (%edx),%ecx
f010165d:	84 c9                	test   %cl,%cl
f010165f:	75 ec                	jne    f010164d <strlcpy+0x1a>
		*dst = '\0';
f0101661:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101664:	29 f0                	sub    %esi,%eax
}
f0101666:	5b                   	pop    %ebx
f0101667:	5e                   	pop    %esi
f0101668:	5d                   	pop    %ebp
f0101669:	c3                   	ret    

f010166a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010166a:	55                   	push   %ebp
f010166b:	89 e5                	mov    %esp,%ebp
f010166d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101670:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101673:	eb 06                	jmp    f010167b <strcmp+0x11>
		p++, q++;
f0101675:	83 c1 01             	add    $0x1,%ecx
f0101678:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010167b:	0f b6 01             	movzbl (%ecx),%eax
f010167e:	84 c0                	test   %al,%al
f0101680:	74 04                	je     f0101686 <strcmp+0x1c>
f0101682:	3a 02                	cmp    (%edx),%al
f0101684:	74 ef                	je     f0101675 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101686:	0f b6 c0             	movzbl %al,%eax
f0101689:	0f b6 12             	movzbl (%edx),%edx
f010168c:	29 d0                	sub    %edx,%eax
}
f010168e:	5d                   	pop    %ebp
f010168f:	c3                   	ret    

f0101690 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101690:	55                   	push   %ebp
f0101691:	89 e5                	mov    %esp,%ebp
f0101693:	53                   	push   %ebx
f0101694:	8b 45 08             	mov    0x8(%ebp),%eax
f0101697:	8b 55 0c             	mov    0xc(%ebp),%edx
f010169a:	89 c3                	mov    %eax,%ebx
f010169c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010169f:	eb 06                	jmp    f01016a7 <strncmp+0x17>
		n--, p++, q++;
f01016a1:	83 c0 01             	add    $0x1,%eax
f01016a4:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01016a7:	39 d8                	cmp    %ebx,%eax
f01016a9:	74 16                	je     f01016c1 <strncmp+0x31>
f01016ab:	0f b6 08             	movzbl (%eax),%ecx
f01016ae:	84 c9                	test   %cl,%cl
f01016b0:	74 04                	je     f01016b6 <strncmp+0x26>
f01016b2:	3a 0a                	cmp    (%edx),%cl
f01016b4:	74 eb                	je     f01016a1 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01016b6:	0f b6 00             	movzbl (%eax),%eax
f01016b9:	0f b6 12             	movzbl (%edx),%edx
f01016bc:	29 d0                	sub    %edx,%eax
}
f01016be:	5b                   	pop    %ebx
f01016bf:	5d                   	pop    %ebp
f01016c0:	c3                   	ret    
		return 0;
f01016c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01016c6:	eb f6                	jmp    f01016be <strncmp+0x2e>

f01016c8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01016c8:	55                   	push   %ebp
f01016c9:	89 e5                	mov    %esp,%ebp
f01016cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016d2:	0f b6 10             	movzbl (%eax),%edx
f01016d5:	84 d2                	test   %dl,%dl
f01016d7:	74 09                	je     f01016e2 <strchr+0x1a>
		if (*s == c)
f01016d9:	38 ca                	cmp    %cl,%dl
f01016db:	74 0a                	je     f01016e7 <strchr+0x1f>
	for (; *s; s++)
f01016dd:	83 c0 01             	add    $0x1,%eax
f01016e0:	eb f0                	jmp    f01016d2 <strchr+0xa>
			return (char *) s;
	return 0;
f01016e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016e7:	5d                   	pop    %ebp
f01016e8:	c3                   	ret    

f01016e9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016e9:	55                   	push   %ebp
f01016ea:	89 e5                	mov    %esp,%ebp
f01016ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ef:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016f3:	eb 03                	jmp    f01016f8 <strfind+0xf>
f01016f5:	83 c0 01             	add    $0x1,%eax
f01016f8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01016fb:	38 ca                	cmp    %cl,%dl
f01016fd:	74 04                	je     f0101703 <strfind+0x1a>
f01016ff:	84 d2                	test   %dl,%dl
f0101701:	75 f2                	jne    f01016f5 <strfind+0xc>
			break;
	return (char *) s;
}
f0101703:	5d                   	pop    %ebp
f0101704:	c3                   	ret    

f0101705 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101705:	55                   	push   %ebp
f0101706:	89 e5                	mov    %esp,%ebp
f0101708:	57                   	push   %edi
f0101709:	56                   	push   %esi
f010170a:	53                   	push   %ebx
f010170b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010170e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101711:	85 c9                	test   %ecx,%ecx
f0101713:	74 13                	je     f0101728 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101715:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010171b:	75 05                	jne    f0101722 <memset+0x1d>
f010171d:	f6 c1 03             	test   $0x3,%cl
f0101720:	74 0d                	je     f010172f <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101722:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101725:	fc                   	cld    
f0101726:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101728:	89 f8                	mov    %edi,%eax
f010172a:	5b                   	pop    %ebx
f010172b:	5e                   	pop    %esi
f010172c:	5f                   	pop    %edi
f010172d:	5d                   	pop    %ebp
f010172e:	c3                   	ret    
		c &= 0xFF;
f010172f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101733:	89 d3                	mov    %edx,%ebx
f0101735:	c1 e3 08             	shl    $0x8,%ebx
f0101738:	89 d0                	mov    %edx,%eax
f010173a:	c1 e0 18             	shl    $0x18,%eax
f010173d:	89 d6                	mov    %edx,%esi
f010173f:	c1 e6 10             	shl    $0x10,%esi
f0101742:	09 f0                	or     %esi,%eax
f0101744:	09 c2                	or     %eax,%edx
f0101746:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101748:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010174b:	89 d0                	mov    %edx,%eax
f010174d:	fc                   	cld    
f010174e:	f3 ab                	rep stos %eax,%es:(%edi)
f0101750:	eb d6                	jmp    f0101728 <memset+0x23>

f0101752 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101752:	55                   	push   %ebp
f0101753:	89 e5                	mov    %esp,%ebp
f0101755:	57                   	push   %edi
f0101756:	56                   	push   %esi
f0101757:	8b 45 08             	mov    0x8(%ebp),%eax
f010175a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010175d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101760:	39 c6                	cmp    %eax,%esi
f0101762:	73 35                	jae    f0101799 <memmove+0x47>
f0101764:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101767:	39 c2                	cmp    %eax,%edx
f0101769:	76 2e                	jbe    f0101799 <memmove+0x47>
		s += n;
		d += n;
f010176b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010176e:	89 d6                	mov    %edx,%esi
f0101770:	09 fe                	or     %edi,%esi
f0101772:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101778:	74 0c                	je     f0101786 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010177a:	83 ef 01             	sub    $0x1,%edi
f010177d:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101780:	fd                   	std    
f0101781:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101783:	fc                   	cld    
f0101784:	eb 21                	jmp    f01017a7 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101786:	f6 c1 03             	test   $0x3,%cl
f0101789:	75 ef                	jne    f010177a <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010178b:	83 ef 04             	sub    $0x4,%edi
f010178e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101791:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101794:	fd                   	std    
f0101795:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101797:	eb ea                	jmp    f0101783 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101799:	89 f2                	mov    %esi,%edx
f010179b:	09 c2                	or     %eax,%edx
f010179d:	f6 c2 03             	test   $0x3,%dl
f01017a0:	74 09                	je     f01017ab <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01017a2:	89 c7                	mov    %eax,%edi
f01017a4:	fc                   	cld    
f01017a5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01017a7:	5e                   	pop    %esi
f01017a8:	5f                   	pop    %edi
f01017a9:	5d                   	pop    %ebp
f01017aa:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01017ab:	f6 c1 03             	test   $0x3,%cl
f01017ae:	75 f2                	jne    f01017a2 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01017b0:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01017b3:	89 c7                	mov    %eax,%edi
f01017b5:	fc                   	cld    
f01017b6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01017b8:	eb ed                	jmp    f01017a7 <memmove+0x55>

f01017ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01017ba:	55                   	push   %ebp
f01017bb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01017bd:	ff 75 10             	pushl  0x10(%ebp)
f01017c0:	ff 75 0c             	pushl  0xc(%ebp)
f01017c3:	ff 75 08             	pushl  0x8(%ebp)
f01017c6:	e8 87 ff ff ff       	call   f0101752 <memmove>
}
f01017cb:	c9                   	leave  
f01017cc:	c3                   	ret    

f01017cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01017cd:	55                   	push   %ebp
f01017ce:	89 e5                	mov    %esp,%ebp
f01017d0:	56                   	push   %esi
f01017d1:	53                   	push   %ebx
f01017d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01017d5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017d8:	89 c6                	mov    %eax,%esi
f01017da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017dd:	39 f0                	cmp    %esi,%eax
f01017df:	74 1c                	je     f01017fd <memcmp+0x30>
		if (*s1 != *s2)
f01017e1:	0f b6 08             	movzbl (%eax),%ecx
f01017e4:	0f b6 1a             	movzbl (%edx),%ebx
f01017e7:	38 d9                	cmp    %bl,%cl
f01017e9:	75 08                	jne    f01017f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01017eb:	83 c0 01             	add    $0x1,%eax
f01017ee:	83 c2 01             	add    $0x1,%edx
f01017f1:	eb ea                	jmp    f01017dd <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01017f3:	0f b6 c1             	movzbl %cl,%eax
f01017f6:	0f b6 db             	movzbl %bl,%ebx
f01017f9:	29 d8                	sub    %ebx,%eax
f01017fb:	eb 05                	jmp    f0101802 <memcmp+0x35>
	}

	return 0;
f01017fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101802:	5b                   	pop    %ebx
f0101803:	5e                   	pop    %esi
f0101804:	5d                   	pop    %ebp
f0101805:	c3                   	ret    

f0101806 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101806:	55                   	push   %ebp
f0101807:	89 e5                	mov    %esp,%ebp
f0101809:	8b 45 08             	mov    0x8(%ebp),%eax
f010180c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010180f:	89 c2                	mov    %eax,%edx
f0101811:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101814:	39 d0                	cmp    %edx,%eax
f0101816:	73 09                	jae    f0101821 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101818:	38 08                	cmp    %cl,(%eax)
f010181a:	74 05                	je     f0101821 <memfind+0x1b>
	for (; s < ends; s++)
f010181c:	83 c0 01             	add    $0x1,%eax
f010181f:	eb f3                	jmp    f0101814 <memfind+0xe>
			break;
	return (void *) s;
}
f0101821:	5d                   	pop    %ebp
f0101822:	c3                   	ret    

f0101823 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101823:	55                   	push   %ebp
f0101824:	89 e5                	mov    %esp,%ebp
f0101826:	57                   	push   %edi
f0101827:	56                   	push   %esi
f0101828:	53                   	push   %ebx
f0101829:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010182c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010182f:	eb 03                	jmp    f0101834 <strtol+0x11>
		s++;
f0101831:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101834:	0f b6 01             	movzbl (%ecx),%eax
f0101837:	3c 20                	cmp    $0x20,%al
f0101839:	74 f6                	je     f0101831 <strtol+0xe>
f010183b:	3c 09                	cmp    $0x9,%al
f010183d:	74 f2                	je     f0101831 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010183f:	3c 2b                	cmp    $0x2b,%al
f0101841:	74 2e                	je     f0101871 <strtol+0x4e>
	int neg = 0;
f0101843:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101848:	3c 2d                	cmp    $0x2d,%al
f010184a:	74 2f                	je     f010187b <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010184c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101852:	75 05                	jne    f0101859 <strtol+0x36>
f0101854:	80 39 30             	cmpb   $0x30,(%ecx)
f0101857:	74 2c                	je     f0101885 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101859:	85 db                	test   %ebx,%ebx
f010185b:	75 0a                	jne    f0101867 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010185d:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101862:	80 39 30             	cmpb   $0x30,(%ecx)
f0101865:	74 28                	je     f010188f <strtol+0x6c>
		base = 10;
f0101867:	b8 00 00 00 00       	mov    $0x0,%eax
f010186c:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010186f:	eb 50                	jmp    f01018c1 <strtol+0x9e>
		s++;
f0101871:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101874:	bf 00 00 00 00       	mov    $0x0,%edi
f0101879:	eb d1                	jmp    f010184c <strtol+0x29>
		s++, neg = 1;
f010187b:	83 c1 01             	add    $0x1,%ecx
f010187e:	bf 01 00 00 00       	mov    $0x1,%edi
f0101883:	eb c7                	jmp    f010184c <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101885:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101889:	74 0e                	je     f0101899 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010188b:	85 db                	test   %ebx,%ebx
f010188d:	75 d8                	jne    f0101867 <strtol+0x44>
		s++, base = 8;
f010188f:	83 c1 01             	add    $0x1,%ecx
f0101892:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101897:	eb ce                	jmp    f0101867 <strtol+0x44>
		s += 2, base = 16;
f0101899:	83 c1 02             	add    $0x2,%ecx
f010189c:	bb 10 00 00 00       	mov    $0x10,%ebx
f01018a1:	eb c4                	jmp    f0101867 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01018a3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01018a6:	89 f3                	mov    %esi,%ebx
f01018a8:	80 fb 19             	cmp    $0x19,%bl
f01018ab:	77 29                	ja     f01018d6 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01018ad:	0f be d2             	movsbl %dl,%edx
f01018b0:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018b3:	3b 55 10             	cmp    0x10(%ebp),%edx
f01018b6:	7d 30                	jge    f01018e8 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01018b8:	83 c1 01             	add    $0x1,%ecx
f01018bb:	0f af 45 10          	imul   0x10(%ebp),%eax
f01018bf:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01018c1:	0f b6 11             	movzbl (%ecx),%edx
f01018c4:	8d 72 d0             	lea    -0x30(%edx),%esi
f01018c7:	89 f3                	mov    %esi,%ebx
f01018c9:	80 fb 09             	cmp    $0x9,%bl
f01018cc:	77 d5                	ja     f01018a3 <strtol+0x80>
			dig = *s - '0';
f01018ce:	0f be d2             	movsbl %dl,%edx
f01018d1:	83 ea 30             	sub    $0x30,%edx
f01018d4:	eb dd                	jmp    f01018b3 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01018d6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01018d9:	89 f3                	mov    %esi,%ebx
f01018db:	80 fb 19             	cmp    $0x19,%bl
f01018de:	77 08                	ja     f01018e8 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01018e0:	0f be d2             	movsbl %dl,%edx
f01018e3:	83 ea 37             	sub    $0x37,%edx
f01018e6:	eb cb                	jmp    f01018b3 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01018e8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018ec:	74 05                	je     f01018f3 <strtol+0xd0>
		*endptr = (char *) s;
f01018ee:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018f1:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01018f3:	89 c2                	mov    %eax,%edx
f01018f5:	f7 da                	neg    %edx
f01018f7:	85 ff                	test   %edi,%edi
f01018f9:	0f 45 c2             	cmovne %edx,%eax
}
f01018fc:	5b                   	pop    %ebx
f01018fd:	5e                   	pop    %esi
f01018fe:	5f                   	pop    %edi
f01018ff:	5d                   	pop    %ebp
f0101900:	c3                   	ret    
f0101901:	66 90                	xchg   %ax,%ax
f0101903:	66 90                	xchg   %ax,%ax
f0101905:	66 90                	xchg   %ax,%ax
f0101907:	66 90                	xchg   %ax,%ax
f0101909:	66 90                	xchg   %ax,%ax
f010190b:	66 90                	xchg   %ax,%ax
f010190d:	66 90                	xchg   %ax,%ax
f010190f:	90                   	nop

f0101910 <__udivdi3>:
f0101910:	55                   	push   %ebp
f0101911:	57                   	push   %edi
f0101912:	56                   	push   %esi
f0101913:	53                   	push   %ebx
f0101914:	83 ec 1c             	sub    $0x1c,%esp
f0101917:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010191b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010191f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101923:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101927:	85 d2                	test   %edx,%edx
f0101929:	75 35                	jne    f0101960 <__udivdi3+0x50>
f010192b:	39 f3                	cmp    %esi,%ebx
f010192d:	0f 87 bd 00 00 00    	ja     f01019f0 <__udivdi3+0xe0>
f0101933:	85 db                	test   %ebx,%ebx
f0101935:	89 d9                	mov    %ebx,%ecx
f0101937:	75 0b                	jne    f0101944 <__udivdi3+0x34>
f0101939:	b8 01 00 00 00       	mov    $0x1,%eax
f010193e:	31 d2                	xor    %edx,%edx
f0101940:	f7 f3                	div    %ebx
f0101942:	89 c1                	mov    %eax,%ecx
f0101944:	31 d2                	xor    %edx,%edx
f0101946:	89 f0                	mov    %esi,%eax
f0101948:	f7 f1                	div    %ecx
f010194a:	89 c6                	mov    %eax,%esi
f010194c:	89 e8                	mov    %ebp,%eax
f010194e:	89 f7                	mov    %esi,%edi
f0101950:	f7 f1                	div    %ecx
f0101952:	89 fa                	mov    %edi,%edx
f0101954:	83 c4 1c             	add    $0x1c,%esp
f0101957:	5b                   	pop    %ebx
f0101958:	5e                   	pop    %esi
f0101959:	5f                   	pop    %edi
f010195a:	5d                   	pop    %ebp
f010195b:	c3                   	ret    
f010195c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101960:	39 f2                	cmp    %esi,%edx
f0101962:	77 7c                	ja     f01019e0 <__udivdi3+0xd0>
f0101964:	0f bd fa             	bsr    %edx,%edi
f0101967:	83 f7 1f             	xor    $0x1f,%edi
f010196a:	0f 84 98 00 00 00    	je     f0101a08 <__udivdi3+0xf8>
f0101970:	89 f9                	mov    %edi,%ecx
f0101972:	b8 20 00 00 00       	mov    $0x20,%eax
f0101977:	29 f8                	sub    %edi,%eax
f0101979:	d3 e2                	shl    %cl,%edx
f010197b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010197f:	89 c1                	mov    %eax,%ecx
f0101981:	89 da                	mov    %ebx,%edx
f0101983:	d3 ea                	shr    %cl,%edx
f0101985:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101989:	09 d1                	or     %edx,%ecx
f010198b:	89 f2                	mov    %esi,%edx
f010198d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101991:	89 f9                	mov    %edi,%ecx
f0101993:	d3 e3                	shl    %cl,%ebx
f0101995:	89 c1                	mov    %eax,%ecx
f0101997:	d3 ea                	shr    %cl,%edx
f0101999:	89 f9                	mov    %edi,%ecx
f010199b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010199f:	d3 e6                	shl    %cl,%esi
f01019a1:	89 eb                	mov    %ebp,%ebx
f01019a3:	89 c1                	mov    %eax,%ecx
f01019a5:	d3 eb                	shr    %cl,%ebx
f01019a7:	09 de                	or     %ebx,%esi
f01019a9:	89 f0                	mov    %esi,%eax
f01019ab:	f7 74 24 08          	divl   0x8(%esp)
f01019af:	89 d6                	mov    %edx,%esi
f01019b1:	89 c3                	mov    %eax,%ebx
f01019b3:	f7 64 24 0c          	mull   0xc(%esp)
f01019b7:	39 d6                	cmp    %edx,%esi
f01019b9:	72 0c                	jb     f01019c7 <__udivdi3+0xb7>
f01019bb:	89 f9                	mov    %edi,%ecx
f01019bd:	d3 e5                	shl    %cl,%ebp
f01019bf:	39 c5                	cmp    %eax,%ebp
f01019c1:	73 5d                	jae    f0101a20 <__udivdi3+0x110>
f01019c3:	39 d6                	cmp    %edx,%esi
f01019c5:	75 59                	jne    f0101a20 <__udivdi3+0x110>
f01019c7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01019ca:	31 ff                	xor    %edi,%edi
f01019cc:	89 fa                	mov    %edi,%edx
f01019ce:	83 c4 1c             	add    $0x1c,%esp
f01019d1:	5b                   	pop    %ebx
f01019d2:	5e                   	pop    %esi
f01019d3:	5f                   	pop    %edi
f01019d4:	5d                   	pop    %ebp
f01019d5:	c3                   	ret    
f01019d6:	8d 76 00             	lea    0x0(%esi),%esi
f01019d9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01019e0:	31 ff                	xor    %edi,%edi
f01019e2:	31 c0                	xor    %eax,%eax
f01019e4:	89 fa                	mov    %edi,%edx
f01019e6:	83 c4 1c             	add    $0x1c,%esp
f01019e9:	5b                   	pop    %ebx
f01019ea:	5e                   	pop    %esi
f01019eb:	5f                   	pop    %edi
f01019ec:	5d                   	pop    %ebp
f01019ed:	c3                   	ret    
f01019ee:	66 90                	xchg   %ax,%ax
f01019f0:	31 ff                	xor    %edi,%edi
f01019f2:	89 e8                	mov    %ebp,%eax
f01019f4:	89 f2                	mov    %esi,%edx
f01019f6:	f7 f3                	div    %ebx
f01019f8:	89 fa                	mov    %edi,%edx
f01019fa:	83 c4 1c             	add    $0x1c,%esp
f01019fd:	5b                   	pop    %ebx
f01019fe:	5e                   	pop    %esi
f01019ff:	5f                   	pop    %edi
f0101a00:	5d                   	pop    %ebp
f0101a01:	c3                   	ret    
f0101a02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a08:	39 f2                	cmp    %esi,%edx
f0101a0a:	72 06                	jb     f0101a12 <__udivdi3+0x102>
f0101a0c:	31 c0                	xor    %eax,%eax
f0101a0e:	39 eb                	cmp    %ebp,%ebx
f0101a10:	77 d2                	ja     f01019e4 <__udivdi3+0xd4>
f0101a12:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a17:	eb cb                	jmp    f01019e4 <__udivdi3+0xd4>
f0101a19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a20:	89 d8                	mov    %ebx,%eax
f0101a22:	31 ff                	xor    %edi,%edi
f0101a24:	eb be                	jmp    f01019e4 <__udivdi3+0xd4>
f0101a26:	66 90                	xchg   %ax,%ax
f0101a28:	66 90                	xchg   %ax,%ax
f0101a2a:	66 90                	xchg   %ax,%ax
f0101a2c:	66 90                	xchg   %ax,%ax
f0101a2e:	66 90                	xchg   %ax,%ax

f0101a30 <__umoddi3>:
f0101a30:	55                   	push   %ebp
f0101a31:	57                   	push   %edi
f0101a32:	56                   	push   %esi
f0101a33:	53                   	push   %ebx
f0101a34:	83 ec 1c             	sub    $0x1c,%esp
f0101a37:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101a3b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101a3f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101a43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a47:	85 ed                	test   %ebp,%ebp
f0101a49:	89 f0                	mov    %esi,%eax
f0101a4b:	89 da                	mov    %ebx,%edx
f0101a4d:	75 19                	jne    f0101a68 <__umoddi3+0x38>
f0101a4f:	39 df                	cmp    %ebx,%edi
f0101a51:	0f 86 b1 00 00 00    	jbe    f0101b08 <__umoddi3+0xd8>
f0101a57:	f7 f7                	div    %edi
f0101a59:	89 d0                	mov    %edx,%eax
f0101a5b:	31 d2                	xor    %edx,%edx
f0101a5d:	83 c4 1c             	add    $0x1c,%esp
f0101a60:	5b                   	pop    %ebx
f0101a61:	5e                   	pop    %esi
f0101a62:	5f                   	pop    %edi
f0101a63:	5d                   	pop    %ebp
f0101a64:	c3                   	ret    
f0101a65:	8d 76 00             	lea    0x0(%esi),%esi
f0101a68:	39 dd                	cmp    %ebx,%ebp
f0101a6a:	77 f1                	ja     f0101a5d <__umoddi3+0x2d>
f0101a6c:	0f bd cd             	bsr    %ebp,%ecx
f0101a6f:	83 f1 1f             	xor    $0x1f,%ecx
f0101a72:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a76:	0f 84 b4 00 00 00    	je     f0101b30 <__umoddi3+0x100>
f0101a7c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a81:	89 c2                	mov    %eax,%edx
f0101a83:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a87:	29 c2                	sub    %eax,%edx
f0101a89:	89 c1                	mov    %eax,%ecx
f0101a8b:	89 f8                	mov    %edi,%eax
f0101a8d:	d3 e5                	shl    %cl,%ebp
f0101a8f:	89 d1                	mov    %edx,%ecx
f0101a91:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a95:	d3 e8                	shr    %cl,%eax
f0101a97:	09 c5                	or     %eax,%ebp
f0101a99:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a9d:	89 c1                	mov    %eax,%ecx
f0101a9f:	d3 e7                	shl    %cl,%edi
f0101aa1:	89 d1                	mov    %edx,%ecx
f0101aa3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101aa7:	89 df                	mov    %ebx,%edi
f0101aa9:	d3 ef                	shr    %cl,%edi
f0101aab:	89 c1                	mov    %eax,%ecx
f0101aad:	89 f0                	mov    %esi,%eax
f0101aaf:	d3 e3                	shl    %cl,%ebx
f0101ab1:	89 d1                	mov    %edx,%ecx
f0101ab3:	89 fa                	mov    %edi,%edx
f0101ab5:	d3 e8                	shr    %cl,%eax
f0101ab7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101abc:	09 d8                	or     %ebx,%eax
f0101abe:	f7 f5                	div    %ebp
f0101ac0:	d3 e6                	shl    %cl,%esi
f0101ac2:	89 d1                	mov    %edx,%ecx
f0101ac4:	f7 64 24 08          	mull   0x8(%esp)
f0101ac8:	39 d1                	cmp    %edx,%ecx
f0101aca:	89 c3                	mov    %eax,%ebx
f0101acc:	89 d7                	mov    %edx,%edi
f0101ace:	72 06                	jb     f0101ad6 <__umoddi3+0xa6>
f0101ad0:	75 0e                	jne    f0101ae0 <__umoddi3+0xb0>
f0101ad2:	39 c6                	cmp    %eax,%esi
f0101ad4:	73 0a                	jae    f0101ae0 <__umoddi3+0xb0>
f0101ad6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101ada:	19 ea                	sbb    %ebp,%edx
f0101adc:	89 d7                	mov    %edx,%edi
f0101ade:	89 c3                	mov    %eax,%ebx
f0101ae0:	89 ca                	mov    %ecx,%edx
f0101ae2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101ae7:	29 de                	sub    %ebx,%esi
f0101ae9:	19 fa                	sbb    %edi,%edx
f0101aeb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101aef:	89 d0                	mov    %edx,%eax
f0101af1:	d3 e0                	shl    %cl,%eax
f0101af3:	89 d9                	mov    %ebx,%ecx
f0101af5:	d3 ee                	shr    %cl,%esi
f0101af7:	d3 ea                	shr    %cl,%edx
f0101af9:	09 f0                	or     %esi,%eax
f0101afb:	83 c4 1c             	add    $0x1c,%esp
f0101afe:	5b                   	pop    %ebx
f0101aff:	5e                   	pop    %esi
f0101b00:	5f                   	pop    %edi
f0101b01:	5d                   	pop    %ebp
f0101b02:	c3                   	ret    
f0101b03:	90                   	nop
f0101b04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b08:	85 ff                	test   %edi,%edi
f0101b0a:	89 f9                	mov    %edi,%ecx
f0101b0c:	75 0b                	jne    f0101b19 <__umoddi3+0xe9>
f0101b0e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b13:	31 d2                	xor    %edx,%edx
f0101b15:	f7 f7                	div    %edi
f0101b17:	89 c1                	mov    %eax,%ecx
f0101b19:	89 d8                	mov    %ebx,%eax
f0101b1b:	31 d2                	xor    %edx,%edx
f0101b1d:	f7 f1                	div    %ecx
f0101b1f:	89 f0                	mov    %esi,%eax
f0101b21:	f7 f1                	div    %ecx
f0101b23:	e9 31 ff ff ff       	jmp    f0101a59 <__umoddi3+0x29>
f0101b28:	90                   	nop
f0101b29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b30:	39 dd                	cmp    %ebx,%ebp
f0101b32:	72 08                	jb     f0101b3c <__umoddi3+0x10c>
f0101b34:	39 f7                	cmp    %esi,%edi
f0101b36:	0f 87 21 ff ff ff    	ja     f0101a5d <__umoddi3+0x2d>
f0101b3c:	89 da                	mov    %ebx,%edx
f0101b3e:	89 f0                	mov    %esi,%eax
f0101b40:	29 f8                	sub    %edi,%eax
f0101b42:	19 ea                	sbb    %ebp,%edx
f0101b44:	e9 14 ff ff ff       	jmp    f0101a5d <__umoddi3+0x2d>
