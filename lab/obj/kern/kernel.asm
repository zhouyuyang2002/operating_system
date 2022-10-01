
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 82 01 00    	add    $0x182c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 80 a0 11 f0    	mov    $0xf011a080,%edx
f0100058:	c7 c0 c0 a6 11 f0    	mov    $0xf011a6c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 99 40 00 00       	call   f0104102 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 34 c2 fe ff    	lea    -0x13dcc(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 6f 34 00 00       	call   f01034f1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 cd 16 00 00       	call   f0101754 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 f0 0b 00 00       	call   f0100c84 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 65 82 01 00    	add    $0x18265,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 a6 11 f0    	mov    $0xf011a6c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 bf 0b 00 00       	call   f0100c84 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 4f c2 fe ff    	lea    -0x13db1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 0b 34 00 00       	call   f01034f1 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 ca 33 00 00       	call   f01034ba <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 ff c4 fe ff    	lea    -0x13b01(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 f3 33 00 00       	call   f01034f1 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 81 01 00    	add    $0x181ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 67 c2 fe ff    	lea    -0x13d99(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 c6 33 00 00       	call   f01034f1 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 83 33 00 00       	call   f01034ba <vcprintf>
	cprintf("\n");
f0100137:	8d 83 ff c4 fe ff    	lea    -0x13b01(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 ac 33 00 00       	call   f01034f1 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 90 81 01 00    	add    $0x18190,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 98 1f 00 00    	mov    0x1f98(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
f010019e:	88 84 0b 94 1d 00 00 	mov    %al,0x1d94(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 98 1f 00 00 00 	movl   $0x0,0x1f98(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 45 81 01 00    	add    $0x18145,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 74 1d 00 00    	mov    %ecx,0x1d74(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 b4 c3 fe 	movzbl -0x13c4c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 74 1d 00 00    	or     0x1d74(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 b4 c2 fe 	movzbl -0x13d4c(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 81 c2 fe ff    	lea    -0x13d7f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 7b 32 00 00       	call   f01034f1 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 74 1d 00 00 40 	orl    $0x40,0x1d74(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 b4 c3 fe 	movzbl -0x13c4c(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0f 80 01 00    	add    $0x1800f,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 9c 1f 00 00 	cmpw   $0x7cf,0x1f9c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b a0 1f 00 00    	mov    0x1fa0(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 9c 1f 00 00 	addw   $0x50,0x1f9c(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 9c 1f 00 00 	mov    %dx,0x1f9c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 a0 1f 00 00    	mov    0x1fa0(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 78 3c 00 00       	call   f010414f <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 9c 1f 00 00 	subw   $0x50,0x1f9c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 7e 01 00       	add    $0x17e02,%eax
	if (serial_exists)
f010050f:	80 b8 a8 1f 00 00 00 	cmpb   $0x0,0x1fa8(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 47 7e fe ff    	lea    -0x181b9(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d4 7d 01 00       	add    $0x17dd4,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b1 7e fe ff    	lea    -0x1814f(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b6 7d 01 00    	add    $0x17db6,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 98 1f 00 00    	cmp    0x1f98(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 94 1f 00 00    	mov    %ecx,0x1f94(%ebx)
f0100582:	0f b6 84 13 94 1d 00 	movzbl 0x1d94(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 5a 7d 01 00    	add    $0x17d5a,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 a4 1f 00 00 b4 	movl   $0x3b4,0x1fa4(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb a4 1f 00 00    	mov    0x1fa4(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb a0 1f 00 00    	mov    %edi,0x1fa0(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 9c 1f 00 00 	mov    %si,0x1f9c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 a8 1f 00 00 	setne  0x1fa8(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 a4 1f 00 00 d4 	movl   $0x3d4,0x1fa4(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 8d c2 fe ff    	lea    -0x13d73(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 30 2e 00 00       	call   f01034f1 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	57                   	push   %edi
f01006f9:	56                   	push   %esi
f01006fa:	53                   	push   %ebx
f01006fb:	83 ec 0c             	sub    $0xc,%esp
f01006fe:	e8 4c fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100703:	81 c3 09 7c 01 00    	add    $0x17c09,%ebx
f0100709:	be 00 00 00 00       	mov    $0x0,%esi
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010070e:	8d bb b4 c4 fe ff    	lea    -0x13b4c(%ebx),%edi
f0100714:	83 ec 04             	sub    $0x4,%esp
f0100717:	ff b4 1e 18 1d 00 00 	pushl  0x1d18(%esi,%ebx,1)
f010071e:	ff b4 1e 14 1d 00 00 	pushl  0x1d14(%esi,%ebx,1)
f0100725:	57                   	push   %edi
f0100726:	e8 c6 2d 00 00       	call   f01034f1 <cprintf>
f010072b:	83 c6 0c             	add    $0xc,%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f010072e:	83 c4 10             	add    $0x10,%esp
f0100731:	83 fe 3c             	cmp    $0x3c,%esi
f0100734:	75 de                	jne    f0100714 <mon_help+0x1f>
	return 0;
}
f0100736:	b8 00 00 00 00       	mov    $0x0,%eax
f010073b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010073e:	5b                   	pop    %ebx
f010073f:	5e                   	pop    %esi
f0100740:	5f                   	pop    %edi
f0100741:	5d                   	pop    %ebp
f0100742:	c3                   	ret    

f0100743 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100743:	55                   	push   %ebp
f0100744:	89 e5                	mov    %esp,%ebp
f0100746:	57                   	push   %edi
f0100747:	56                   	push   %esi
f0100748:	53                   	push   %ebx
f0100749:	83 ec 18             	sub    $0x18,%esp
f010074c:	e8 fe f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100751:	81 c3 bb 7b 01 00    	add    $0x17bbb,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100757:	8d 83 bd c4 fe ff    	lea    -0x13b43(%ebx),%eax
f010075d:	50                   	push   %eax
f010075e:	e8 8e 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100763:	83 c4 08             	add    $0x8,%esp
f0100766:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010076c:	8d 83 18 c6 fe ff    	lea    -0x139e8(%ebx),%eax
f0100772:	50                   	push   %eax
f0100773:	e8 79 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100778:	83 c4 0c             	add    $0xc,%esp
f010077b:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100781:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100787:	50                   	push   %eax
f0100788:	57                   	push   %edi
f0100789:	8d 83 40 c6 fe ff    	lea    -0x139c0(%ebx),%eax
f010078f:	50                   	push   %eax
f0100790:	e8 5c 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100795:	83 c4 0c             	add    $0xc,%esp
f0100798:	c7 c0 39 45 10 f0    	mov    $0xf0104539,%eax
f010079e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a4:	52                   	push   %edx
f01007a5:	50                   	push   %eax
f01007a6:	8d 83 64 c6 fe ff    	lea    -0x1399c(%ebx),%eax
f01007ac:	50                   	push   %eax
f01007ad:	e8 3f 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b2:	83 c4 0c             	add    $0xc,%esp
f01007b5:	c7 c0 80 a0 11 f0    	mov    $0xf011a080,%eax
f01007bb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c1:	52                   	push   %edx
f01007c2:	50                   	push   %eax
f01007c3:	8d 83 88 c6 fe ff    	lea    -0x13978(%ebx),%eax
f01007c9:	50                   	push   %eax
f01007ca:	e8 22 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	c7 c6 c0 a6 11 f0    	mov    $0xf011a6c0,%esi
f01007d8:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007de:	50                   	push   %eax
f01007df:	56                   	push   %esi
f01007e0:	8d 83 ac c6 fe ff    	lea    -0x13954(%ebx),%eax
f01007e6:	50                   	push   %eax
f01007e7:	e8 05 2d 00 00       	call   f01034f1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ec:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007ef:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f5:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f7:	c1 fe 0a             	sar    $0xa,%esi
f01007fa:	56                   	push   %esi
f01007fb:	8d 83 d0 c6 fe ff    	lea    -0x13930(%ebx),%eax
f0100801:	50                   	push   %eax
f0100802:	e8 ea 2c 00 00       	call   f01034f1 <cprintf>
	return 0;
}
f0100807:	b8 00 00 00 00       	mov    $0x0,%eax
f010080c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010080f:	5b                   	pop    %ebx
f0100810:	5e                   	pop    %esi
f0100811:	5f                   	pop    %edi
f0100812:	5d                   	pop    %ebp
f0100813:	c3                   	ret    

f0100814 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100814:	55                   	push   %ebp
f0100815:	89 e5                	mov    %esp,%ebp
f0100817:	57                   	push   %edi
f0100818:	56                   	push   %esi
f0100819:	53                   	push   %ebx
f010081a:	83 ec 48             	sub    $0x48,%esp
f010081d:	e8 2d f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100822:	81 c3 ea 7a 01 00    	add    $0x17aea,%ebx
	cprintf("Stack backtrace\n");
f0100828:	8d 83 d6 c4 fe ff    	lea    -0x13b2a(%ebx),%eax
f010082e:	50                   	push   %eax
f010082f:	e8 bd 2c 00 00       	call   f01034f1 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100834:	89 e8                	mov    %ebp,%eax
f0100836:	83 c4 10             	add    $0x10,%esp
		uint32_t arg_2 = *((uint32_t*)pointer + 1 + 2);
		uint32_t arg_3 = *((uint32_t*)pointer + 1 + 3);
		uint32_t arg_4 = *((uint32_t*)pointer + 1 + 4);
		uint32_t arg_5 = *((uint32_t*)pointer + 1 + 5);
		//
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f0100839:	8d 93 fc c6 fe ff    	lea    -0x13904(%ebx),%edx
f010083f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
				ebp_val, ret_pos, arg_1, arg_2, arg_3, arg_4, arg_5);

		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f0100842:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100845:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100848:	eb 06                	jmp    f0100850 <mon_backtrace+0x3c>
				eip_info.eip_file, eip_info.eip_line, 
				eip_info.eip_fn_namelen, eip_info.eip_fn_name,
				ret_pos - eip_info.eip_fn_addr);
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
			break;
		ebp_val = new_ebp_val;
f010084a:	89 f8                	mov    %edi,%eax
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
f010084c:	85 ff                	test   %edi,%edi
f010084e:	74 55                	je     f01008a5 <mon_backtrace+0x91>
		uint32_t new_ebp_val = *((uint32_t*)pointer);
f0100850:	8b 38                	mov    (%eax),%edi
		uint32_t ret_pos = *((uint32_t*)pointer + 1);
f0100852:	8b 70 04             	mov    0x4(%eax),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f0100855:	ff 70 18             	pushl  0x18(%eax)
f0100858:	ff 70 14             	pushl  0x14(%eax)
f010085b:	ff 70 10             	pushl  0x10(%eax)
f010085e:	ff 70 0c             	pushl  0xc(%eax)
f0100861:	ff 70 08             	pushl  0x8(%eax)
f0100864:	56                   	push   %esi
f0100865:	50                   	push   %eax
f0100866:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100869:	e8 83 2c 00 00       	call   f01034f1 <cprintf>
		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f010086e:	83 c4 18             	add    $0x18,%esp
f0100871:	ff 75 c0             	pushl  -0x40(%ebp)
f0100874:	56                   	push   %esi
f0100875:	e8 7b 2d 00 00       	call   f01035f5 <debuginfo_eip>
f010087a:	83 c4 10             	add    $0x10,%esp
f010087d:	85 c0                	test   %eax,%eax
f010087f:	75 c9                	jne    f010084a <mon_backtrace+0x36>
			cprintf("         %s:%d: %.*s+%d\r\n",
f0100881:	83 ec 08             	sub    $0x8,%esp
f0100884:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100887:	56                   	push   %esi
f0100888:	ff 75 d8             	pushl  -0x28(%ebp)
f010088b:	ff 75 dc             	pushl  -0x24(%ebp)
f010088e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100891:	ff 75 d0             	pushl  -0x30(%ebp)
f0100894:	8d 83 e7 c4 fe ff    	lea    -0x13b19(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 51 2c 00 00       	call   f01034f1 <cprintf>
f01008a0:	83 c4 20             	add    $0x20,%esp
f01008a3:	eb a5                	jmp    f010084a <mon_backtrace+0x36>
	}
	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ad:	5b                   	pop    %ebx
f01008ae:	5e                   	pop    %esi
f01008af:	5f                   	pop    %edi
f01008b0:	5d                   	pop    %ebp
f01008b1:	c3                   	ret    

f01008b2 <mon_showmappings>:

int mon_showmappings(int argc, char** argv, struct Trapframe *tf){
f01008b2:	55                   	push   %ebp
f01008b3:	89 e5                	mov    %esp,%ebp
f01008b5:	57                   	push   %edi
f01008b6:	56                   	push   %esi
f01008b7:	53                   	push   %ebx
f01008b8:	83 ec 1c             	sub    $0x1c,%esp
f01008bb:	e8 8f f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01008c0:	81 c3 4c 7a 01 00    	add    $0x17a4c,%ebx
f01008c6:	8b 75 08             	mov    0x8(%ebp),%esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;
	if (argc != 2 && argc != 3){
f01008c9:	8d 46 fe             	lea    -0x2(%esi),%eax
f01008cc:	83 f8 01             	cmp    $0x1,%eax
f01008cf:	76 1f                	jbe    f01008f0 <mon_showmappings+0x3e>
		cprintf("Usage: showmappings ADDR1 [ADDR2]\n");
f01008d1:	83 ec 0c             	sub    $0xc,%esp
f01008d4:	8d 83 34 c7 fe ff    	lea    -0x138cc(%ebx),%eax
f01008da:	50                   	push   %eax
f01008db:	e8 11 2c 00 00       	call   f01034f1 <cprintf>
		return 0;
f01008e0:	83 c4 10             	add    $0x10,%esp
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
		}
	}

	return 0;
}
f01008e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008eb:	5b                   	pop    %ebx
f01008ec:	5e                   	pop    %esi
f01008ed:	5f                   	pop    %edi
f01008ee:	5d                   	pop    %ebp
f01008ef:	c3                   	ret    
	long begin_itr = strtol(argv[1], NULL, 16);
f01008f0:	83 ec 04             	sub    $0x4,%esp
f01008f3:	6a 10                	push   $0x10
f01008f5:	6a 00                	push   $0x0
f01008f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008fa:	ff 70 04             	pushl  0x4(%eax)
f01008fd:	e8 1e 39 00 00       	call   f0104220 <strtol>
f0100902:	89 c7                	mov    %eax,%edi
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100904:	83 c4 10             	add    $0x10,%esp
f0100907:	83 fe 03             	cmp    $0x3,%esi
f010090a:	74 2f                	je     f010093b <mon_showmappings+0x89>
	begin_itr = ROUNDUP(begin_itr, PGSIZE);
f010090c:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f0100912:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	end_itr = ROUNDUP(end_itr, PGSIZE);
f0100918:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f010091e:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0100924:	89 7d e4             	mov    %edi,-0x1c(%ebp)
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
f0100927:	8d 83 01 c5 fe ff    	lea    -0x13aff(%ebx),%eax
f010092d:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
f0100930:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0100936:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f0100939:	eb 35                	jmp    f0100970 <mon_showmappings+0xbe>
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f010093b:	83 ec 04             	sub    $0x4,%esp
f010093e:	6a 10                	push   $0x10
f0100940:	6a 00                	push   $0x0
f0100942:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100945:	ff 70 08             	pushl  0x8(%eax)
f0100948:	e8 d3 38 00 00       	call   f0104220 <strtol>
	if (begin_itr > end_itr){
f010094d:	83 c4 10             	add    $0x10,%esp
f0100950:	39 c7                	cmp    %eax,%edi
f0100952:	7f b8                	jg     f010090c <mon_showmappings+0x5a>
f0100954:	89 c2                	mov    %eax,%edx
	long begin_itr = strtol(argv[1], NULL, 16);
f0100956:	89 f8                	mov    %edi,%eax
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100958:	89 d7                	mov    %edx,%edi
f010095a:	eb b0                	jmp    f010090c <mon_showmappings+0x5a>
			cprintf("Page doesn't exist\n");
f010095c:	83 ec 0c             	sub    $0xc,%esp
f010095f:	8d 83 13 c5 fe ff    	lea    -0x13aed(%ebx),%eax
f0100965:	50                   	push   %eax
f0100966:	e8 86 2b 00 00       	call   f01034f1 <cprintf>
f010096b:	83 c4 10             	add    $0x10,%esp
	long begin_itr = strtol(argv[1], NULL, 16);
f010096e:	89 fe                	mov    %edi,%esi
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f0100970:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100973:	0f 8f 6a ff ff ff    	jg     f01008e3 <mon_showmappings+0x31>
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
f0100979:	8d be 00 10 00 00    	lea    0x1000(%esi),%edi
f010097f:	83 ec 04             	sub    $0x4,%esp
f0100982:	57                   	push   %edi
f0100983:	56                   	push   %esi
f0100984:	ff 75 e0             	pushl  -0x20(%ebp)
f0100987:	e8 65 2b 00 00       	call   f01034f1 <cprintf>
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
f010098c:	83 c4 0c             	add    $0xc,%esp
f010098f:	6a 00                	push   $0x0
f0100991:	56                   	push   %esi
f0100992:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100995:	ff 30                	pushl  (%eax)
f0100997:	e8 0c 0b 00 00       	call   f01014a8 <pgdir_walk>
f010099c:	89 c6                	mov    %eax,%esi
		if (pte_itr == NULL)
f010099e:	83 c4 10             	add    $0x10,%esp
f01009a1:	85 c0                	test   %eax,%eax
f01009a3:	74 b7                	je     f010095c <mon_showmappings+0xaa>
			cprintf("ADDR = %08x, ", PTE_ADDR(*pte_itr));
f01009a5:	83 ec 08             	sub    $0x8,%esp
f01009a8:	8b 00                	mov    (%eax),%eax
f01009aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009af:	50                   	push   %eax
f01009b0:	8d 83 27 c5 fe ff    	lea    -0x13ad9(%ebx),%eax
f01009b6:	50                   	push   %eax
f01009b7:	e8 35 2b 00 00       	call   f01034f1 <cprintf>
			cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f01009bc:	83 c4 08             	add    $0x8,%esp
f01009bf:	0f b6 06             	movzbl (%esi),%eax
f01009c2:	83 e0 01             	and    $0x1,%eax
f01009c5:	50                   	push   %eax
f01009c6:	8d 83 35 c5 fe ff    	lea    -0x13acb(%ebx),%eax
f01009cc:	50                   	push   %eax
f01009cd:	e8 1f 2b 00 00       	call   f01034f1 <cprintf>
			cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f01009d2:	83 c4 08             	add    $0x8,%esp
f01009d5:	0f b6 06             	movzbl (%esi),%eax
f01009d8:	83 e0 02             	and    $0x2,%eax
f01009db:	50                   	push   %eax
f01009dc:	8d 83 44 c5 fe ff    	lea    -0x13abc(%ebx),%eax
f01009e2:	50                   	push   %eax
f01009e3:	e8 09 2b 00 00       	call   f01034f1 <cprintf>
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f01009e8:	83 c4 08             	add    $0x8,%esp
f01009eb:	0f b6 06             	movzbl (%esi),%eax
f01009ee:	83 e0 04             	and    $0x4,%eax
f01009f1:	50                   	push   %eax
f01009f2:	8d 83 53 c5 fe ff    	lea    -0x13aad(%ebx),%eax
f01009f8:	50                   	push   %eax
f01009f9:	e8 f3 2a 00 00       	call   f01034f1 <cprintf>
f01009fe:	83 c4 10             	add    $0x10,%esp
f0100a01:	e9 68 ff ff ff       	jmp    f010096e <mon_showmappings+0xbc>

f0100a06 <mon_setperm>:

int mon_setperm(int argc, char** argv, struct Trapframe *tf){
f0100a06:	55                   	push   %ebp
f0100a07:	89 e5                	mov    %esp,%ebp
f0100a09:	57                   	push   %edi
f0100a0a:	56                   	push   %esi
f0100a0b:	53                   	push   %ebx
f0100a0c:	83 ec 0c             	sub    $0xc,%esp
f0100a0f:	e8 3b f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a14:	81 c3 f8 78 01 00    	add    $0x178f8,%ebx
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 4){
f0100a1a:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100a1e:	74 1f                	je     f0100a3f <mon_setperm+0x39>
		cprintf("usage: perm ADDR [add/clear] [U/W/P] or perm ADDR [set] perm_code");
f0100a20:	83 ec 0c             	sub    $0xc,%esp
f0100a23:	8d 83 58 c7 fe ff    	lea    -0x138a8(%ebx),%eax
f0100a29:	50                   	push   %eax
f0100a2a:	e8 c2 2a 00 00       	call   f01034f1 <cprintf>
		return 0;
f0100a2f:	83 c4 10             	add    $0x10,%esp
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));

	return 0;
}
f0100a32:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a3a:	5b                   	pop    %ebx
f0100a3b:	5e                   	pop    %esi
f0100a3c:	5f                   	pop    %edi
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    
	long addr = strtol(argv[1], NULL, 16);
f0100a3f:	83 ec 04             	sub    $0x4,%esp
f0100a42:	6a 10                	push   $0x10
f0100a44:	6a 00                	push   $0x0
f0100a46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a49:	ff 70 04             	pushl  0x4(%eax)
f0100a4c:	e8 cf 37 00 00       	call   f0104220 <strtol>
	pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*) addr, false);
f0100a51:	83 c4 0c             	add    $0xc,%esp
f0100a54:	6a 00                	push   $0x0
f0100a56:	50                   	push   %eax
f0100a57:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0100a5d:	ff 30                	pushl  (%eax)
f0100a5f:	e8 44 0a 00 00       	call   f01014a8 <pgdir_walk>
f0100a64:	89 c6                	mov    %eax,%esi
	if (pte_itr == NULL){
f0100a66:	83 c4 10             	add    $0x10,%esp
f0100a69:	85 c0                	test   %eax,%eax
f0100a6b:	0f 84 0e 01 00 00    	je     f0100b7f <mon_setperm+0x179>
	cprintf("Before:");
f0100a71:	83 ec 0c             	sub    $0xc,%esp
f0100a74:	8d 83 75 c5 fe ff    	lea    -0x13a8b(%ebx),%eax
f0100a7a:	50                   	push   %eax
f0100a7b:	e8 71 2a 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100a80:	83 c4 08             	add    $0x8,%esp
f0100a83:	0f b6 06             	movzbl (%esi),%eax
f0100a86:	83 e0 01             	and    $0x1,%eax
f0100a89:	50                   	push   %eax
f0100a8a:	8d 83 35 c5 fe ff    	lea    -0x13acb(%ebx),%eax
f0100a90:	50                   	push   %eax
f0100a91:	e8 5b 2a 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100a96:	83 c4 08             	add    $0x8,%esp
f0100a99:	0f b6 06             	movzbl (%esi),%eax
f0100a9c:	83 e0 02             	and    $0x2,%eax
f0100a9f:	50                   	push   %eax
f0100aa0:	8d 83 44 c5 fe ff    	lea    -0x13abc(%ebx),%eax
f0100aa6:	50                   	push   %eax
f0100aa7:	e8 45 2a 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100aac:	83 c4 08             	add    $0x8,%esp
f0100aaf:	0f b6 06             	movzbl (%esi),%eax
f0100ab2:	83 e0 04             	and    $0x4,%eax
f0100ab5:	50                   	push   %eax
f0100ab6:	8d 83 53 c5 fe ff    	lea    -0x13aad(%ebx),%eax
f0100abc:	50                   	push   %eax
f0100abd:	e8 2f 2a 00 00       	call   f01034f1 <cprintf>
	if (strcmp("set", argv[2]) == 0){
f0100ac2:	83 c4 08             	add    $0x8,%esp
f0100ac5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ac8:	ff 70 08             	pushl  0x8(%eax)
f0100acb:	8d 83 7d c5 fe ff    	lea    -0x13a83(%ebx),%eax
f0100ad1:	50                   	push   %eax
f0100ad2:	e8 90 35 00 00       	call   f0104067 <strcmp>
f0100ad7:	83 c4 10             	add    $0x10,%esp
f0100ada:	85 c0                	test   %eax,%eax
f0100adc:	0f 84 b4 00 00 00    	je     f0100b96 <mon_setperm+0x190>
	if (strcmp("add", argv[2]) == 0){
f0100ae2:	83 ec 08             	sub    $0x8,%esp
f0100ae5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ae8:	ff 70 08             	pushl  0x8(%eax)
f0100aeb:	8d 83 81 c5 fe ff    	lea    -0x13a7f(%ebx),%eax
f0100af1:	50                   	push   %eax
f0100af2:	e8 70 35 00 00       	call   f0104067 <strcmp>
f0100af7:	89 c7                	mov    %eax,%edi
f0100af9:	83 c4 10             	add    $0x10,%esp
f0100afc:	85 c0                	test   %eax,%eax
f0100afe:	0f 84 b8 00 00 00    	je     f0100bbc <mon_setperm+0x1b6>
	if (strcmp("clear", argv[2]) == 0){
f0100b04:	83 ec 08             	sub    $0x8,%esp
f0100b07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b0a:	ff 70 08             	pushl  0x8(%eax)
f0100b0d:	8d 83 85 c5 fe ff    	lea    -0x13a7b(%ebx),%eax
f0100b13:	50                   	push   %eax
f0100b14:	e8 4e 35 00 00       	call   f0104067 <strcmp>
f0100b19:	89 c7                	mov    %eax,%edi
f0100b1b:	83 c4 10             	add    $0x10,%esp
f0100b1e:	85 c0                	test   %eax,%eax
f0100b20:	0f 84 f9 00 00 00    	je     f0100c1f <mon_setperm+0x219>
	cprintf("After:");
f0100b26:	83 ec 0c             	sub    $0xc,%esp
f0100b29:	8d 83 8b c5 fe ff    	lea    -0x13a75(%ebx),%eax
f0100b2f:	50                   	push   %eax
f0100b30:	e8 bc 29 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100b35:	83 c4 08             	add    $0x8,%esp
f0100b38:	0f b6 06             	movzbl (%esi),%eax
f0100b3b:	83 e0 01             	and    $0x1,%eax
f0100b3e:	50                   	push   %eax
f0100b3f:	8d 83 35 c5 fe ff    	lea    -0x13acb(%ebx),%eax
f0100b45:	50                   	push   %eax
f0100b46:	e8 a6 29 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100b4b:	83 c4 08             	add    $0x8,%esp
f0100b4e:	0f b6 06             	movzbl (%esi),%eax
f0100b51:	83 e0 02             	and    $0x2,%eax
f0100b54:	50                   	push   %eax
f0100b55:	8d 83 44 c5 fe ff    	lea    -0x13abc(%ebx),%eax
f0100b5b:	50                   	push   %eax
f0100b5c:	e8 90 29 00 00       	call   f01034f1 <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100b61:	83 c4 08             	add    $0x8,%esp
f0100b64:	0f b6 06             	movzbl (%esi),%eax
f0100b67:	83 e0 04             	and    $0x4,%eax
f0100b6a:	50                   	push   %eax
f0100b6b:	8d 83 53 c5 fe ff    	lea    -0x13aad(%ebx),%eax
f0100b71:	50                   	push   %eax
f0100b72:	e8 7a 29 00 00       	call   f01034f1 <cprintf>
	return 0;
f0100b77:	83 c4 10             	add    $0x10,%esp
f0100b7a:	e9 b3 fe ff ff       	jmp    f0100a32 <mon_setperm+0x2c>
		cprintf("Page Doesn't Exist!");
f0100b7f:	83 ec 0c             	sub    $0xc,%esp
f0100b82:	8d 83 61 c5 fe ff    	lea    -0x13a9f(%ebx),%eax
f0100b88:	50                   	push   %eax
f0100b89:	e8 63 29 00 00       	call   f01034f1 <cprintf>
		return 0;
f0100b8e:	83 c4 10             	add    $0x10,%esp
f0100b91:	e9 9c fe ff ff       	jmp    f0100a32 <mon_setperm+0x2c>
		int perm_code = strtol(argv[3], NULL, 2);
f0100b96:	83 ec 04             	sub    $0x4,%esp
f0100b99:	6a 02                	push   $0x2
f0100b9b:	6a 00                	push   $0x0
f0100b9d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ba0:	ff 70 0c             	pushl  0xc(%eax)
f0100ba3:	e8 78 36 00 00       	call   f0104220 <strtol>
		*pte_itr = *pte_itr ^ (perm_code & 7) ^ (*pte_itr & 7);
f0100ba8:	8b 16                	mov    (%esi),%edx
f0100baa:	83 e2 f8             	and    $0xfffffff8,%edx
f0100bad:	83 e0 07             	and    $0x7,%eax
f0100bb0:	09 d0                	or     %edx,%eax
f0100bb2:	89 06                	mov    %eax,(%esi)
f0100bb4:	83 c4 10             	add    $0x10,%esp
f0100bb7:	e9 26 ff ff ff       	jmp    f0100ae2 <mon_setperm+0xdc>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100bbc:	83 ec 08             	sub    $0x8,%esp
f0100bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bc2:	ff 70 0c             	pushl  0xc(%eax)
f0100bc5:	8d 83 d9 ca fe ff    	lea    -0x13527(%ebx),%eax
f0100bcb:	50                   	push   %eax
f0100bcc:	e8 96 34 00 00       	call   f0104067 <strcmp>
f0100bd1:	83 c4 08             	add    $0x8,%esp
f0100bd4:	85 c0                	test   %eax,%eax
f0100bd6:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100bda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bdd:	ff 70 0c             	pushl  0xc(%eax)
f0100be0:	8d 83 86 cb fe ff    	lea    -0x1347a(%ebx),%eax
f0100be6:	50                   	push   %eax
f0100be7:	e8 7b 34 00 00       	call   f0104067 <strcmp>
f0100bec:	83 c4 08             	add    $0x8,%esp
f0100bef:	85 c0                	test   %eax,%eax
f0100bf1:	b8 01 00 00 00       	mov    $0x1,%eax
f0100bf6:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100bf9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bfc:	ff 70 0c             	pushl  0xc(%eax)
f0100bff:	8d 83 97 cb fe ff    	lea    -0x13469(%ebx),%eax
f0100c05:	50                   	push   %eax
f0100c06:	e8 5c 34 00 00       	call   f0104067 <strcmp>
f0100c0b:	83 c4 10             	add    $0x10,%esp
f0100c0e:	85 c0                	test   %eax,%eax
f0100c10:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c15:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr | perm_code;
f0100c18:	09 3e                	or     %edi,(%esi)
f0100c1a:	e9 e5 fe ff ff       	jmp    f0100b04 <mon_setperm+0xfe>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100c1f:	83 ec 08             	sub    $0x8,%esp
f0100c22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c25:	ff 70 0c             	pushl  0xc(%eax)
f0100c28:	8d 83 d9 ca fe ff    	lea    -0x13527(%ebx),%eax
f0100c2e:	50                   	push   %eax
f0100c2f:	e8 33 34 00 00       	call   f0104067 <strcmp>
f0100c34:	83 c4 08             	add    $0x8,%esp
f0100c37:	85 c0                	test   %eax,%eax
f0100c39:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100c3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c40:	ff 70 0c             	pushl  0xc(%eax)
f0100c43:	8d 83 86 cb fe ff    	lea    -0x1347a(%ebx),%eax
f0100c49:	50                   	push   %eax
f0100c4a:	e8 18 34 00 00       	call   f0104067 <strcmp>
f0100c4f:	83 c4 08             	add    $0x8,%esp
f0100c52:	85 c0                	test   %eax,%eax
f0100c54:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c59:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100c5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c5f:	ff 70 0c             	pushl  0xc(%eax)
f0100c62:	8d 83 97 cb fe ff    	lea    -0x13469(%ebx),%eax
f0100c68:	50                   	push   %eax
f0100c69:	e8 f9 33 00 00       	call   f0104067 <strcmp>
f0100c6e:	83 c4 10             	add    $0x10,%esp
f0100c71:	85 c0                	test   %eax,%eax
f0100c73:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c78:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr & (~perm_code);
f0100c7b:	f7 d7                	not    %edi
f0100c7d:	21 3e                	and    %edi,(%esi)
f0100c7f:	e9 a2 fe ff ff       	jmp    f0100b26 <mon_setperm+0x120>

f0100c84 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100c84:	55                   	push   %ebp
f0100c85:	89 e5                	mov    %esp,%ebp
f0100c87:	57                   	push   %edi
f0100c88:	56                   	push   %esi
f0100c89:	53                   	push   %ebx
f0100c8a:	83 ec 68             	sub    $0x68,%esp
f0100c8d:	e8 bd f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c92:	81 c3 7a 76 01 00    	add    $0x1767a,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100c98:	8d 83 9c c7 fe ff    	lea    -0x13864(%ebx),%eax
f0100c9e:	50                   	push   %eax
f0100c9f:	e8 4d 28 00 00       	call   f01034f1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ca4:	8d 83 c0 c7 fe ff    	lea    -0x13840(%ebx),%eax
f0100caa:	89 04 24             	mov    %eax,(%esp)
f0100cad:	e8 3f 28 00 00       	call   f01034f1 <cprintf>
f0100cb2:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100cb5:	8d bb 96 c5 fe ff    	lea    -0x13a6a(%ebx),%edi
f0100cbb:	eb 4a                	jmp    f0100d07 <monitor+0x83>
f0100cbd:	83 ec 08             	sub    $0x8,%esp
f0100cc0:	0f be c0             	movsbl %al,%eax
f0100cc3:	50                   	push   %eax
f0100cc4:	57                   	push   %edi
f0100cc5:	e8 fb 33 00 00       	call   f01040c5 <strchr>
f0100cca:	83 c4 10             	add    $0x10,%esp
f0100ccd:	85 c0                	test   %eax,%eax
f0100ccf:	74 08                	je     f0100cd9 <monitor+0x55>
			*buf++ = 0;
f0100cd1:	c6 06 00             	movb   $0x0,(%esi)
f0100cd4:	8d 76 01             	lea    0x1(%esi),%esi
f0100cd7:	eb 79                	jmp    f0100d52 <monitor+0xce>
		if (*buf == 0)
f0100cd9:	80 3e 00             	cmpb   $0x0,(%esi)
f0100cdc:	74 7f                	je     f0100d5d <monitor+0xd9>
		if (argc == MAXARGS - 1) {
f0100cde:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100ce2:	74 0f                	je     f0100cf3 <monitor+0x6f>
		argv[argc++] = buf;
f0100ce4:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100ce7:	8d 48 01             	lea    0x1(%eax),%ecx
f0100cea:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100ced:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100cf1:	eb 44                	jmp    f0100d37 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100cf3:	83 ec 08             	sub    $0x8,%esp
f0100cf6:	6a 10                	push   $0x10
f0100cf8:	8d 83 9b c5 fe ff    	lea    -0x13a65(%ebx),%eax
f0100cfe:	50                   	push   %eax
f0100cff:	e8 ed 27 00 00       	call   f01034f1 <cprintf>
f0100d04:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100d07:	8d 83 92 c5 fe ff    	lea    -0x13a6e(%ebx),%eax
f0100d0d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100d10:	83 ec 0c             	sub    $0xc,%esp
f0100d13:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100d16:	e8 72 31 00 00       	call   f0103e8d <readline>
f0100d1b:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100d1d:	83 c4 10             	add    $0x10,%esp
f0100d20:	85 c0                	test   %eax,%eax
f0100d22:	74 ec                	je     f0100d10 <monitor+0x8c>
	argv[argc] = 0;
f0100d24:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100d2b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100d32:	eb 1e                	jmp    f0100d52 <monitor+0xce>
			buf++;
f0100d34:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100d37:	0f b6 06             	movzbl (%esi),%eax
f0100d3a:	84 c0                	test   %al,%al
f0100d3c:	74 14                	je     f0100d52 <monitor+0xce>
f0100d3e:	83 ec 08             	sub    $0x8,%esp
f0100d41:	0f be c0             	movsbl %al,%eax
f0100d44:	50                   	push   %eax
f0100d45:	57                   	push   %edi
f0100d46:	e8 7a 33 00 00       	call   f01040c5 <strchr>
f0100d4b:	83 c4 10             	add    $0x10,%esp
f0100d4e:	85 c0                	test   %eax,%eax
f0100d50:	74 e2                	je     f0100d34 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100d52:	0f b6 06             	movzbl (%esi),%eax
f0100d55:	84 c0                	test   %al,%al
f0100d57:	0f 85 60 ff ff ff    	jne    f0100cbd <monitor+0x39>
	argv[argc] = 0;
f0100d5d:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100d60:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100d67:	00 
	if (argc == 0)
f0100d68:	85 c0                	test   %eax,%eax
f0100d6a:	74 9b                	je     f0100d07 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100d6c:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100d71:	83 ec 08             	sub    $0x8,%esp
f0100d74:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d77:	ff b4 83 14 1d 00 00 	pushl  0x1d14(%ebx,%eax,4)
f0100d7e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100d81:	e8 e1 32 00 00       	call   f0104067 <strcmp>
f0100d86:	83 c4 10             	add    $0x10,%esp
f0100d89:	85 c0                	test   %eax,%eax
f0100d8b:	74 22                	je     f0100daf <monitor+0x12b>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100d8d:	83 c6 01             	add    $0x1,%esi
f0100d90:	83 fe 05             	cmp    $0x5,%esi
f0100d93:	75 dc                	jne    f0100d71 <monitor+0xed>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100d95:	83 ec 08             	sub    $0x8,%esp
f0100d98:	ff 75 a8             	pushl  -0x58(%ebp)
f0100d9b:	8d 83 b8 c5 fe ff    	lea    -0x13a48(%ebx),%eax
f0100da1:	50                   	push   %eax
f0100da2:	e8 4a 27 00 00       	call   f01034f1 <cprintf>
f0100da7:	83 c4 10             	add    $0x10,%esp
f0100daa:	e9 58 ff ff ff       	jmp    f0100d07 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100daf:	83 ec 04             	sub    $0x4,%esp
f0100db2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100db5:	ff 75 08             	pushl  0x8(%ebp)
f0100db8:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100dbb:	52                   	push   %edx
f0100dbc:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100dbf:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100dc6:	83 c4 10             	add    $0x10,%esp
f0100dc9:	85 c0                	test   %eax,%eax
f0100dcb:	0f 89 36 ff ff ff    	jns    f0100d07 <monitor+0x83>
				break;
	}
}
f0100dd1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dd4:	5b                   	pop    %ebx
f0100dd5:	5e                   	pop    %esi
f0100dd6:	5f                   	pop    %edi
f0100dd7:	5d                   	pop    %ebp
f0100dd8:	c3                   	ret    

f0100dd9 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100dd9:	55                   	push   %ebp
f0100dda:	89 e5                	mov    %esp,%ebp
f0100ddc:	57                   	push   %edi
f0100ddd:	56                   	push   %esi
f0100dde:	53                   	push   %ebx
f0100ddf:	83 ec 18             	sub    $0x18,%esp
f0100de2:	e8 68 f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100de7:	81 c3 25 75 01 00    	add    $0x17525,%ebx
f0100ded:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100def:	50                   	push   %eax
f0100df0:	e8 75 26 00 00       	call   f010346a <mc146818_read>
f0100df5:	89 c6                	mov    %eax,%esi
f0100df7:	83 c7 01             	add    $0x1,%edi
f0100dfa:	89 3c 24             	mov    %edi,(%esp)
f0100dfd:	e8 68 26 00 00       	call   f010346a <mc146818_read>
f0100e02:	c1 e0 08             	shl    $0x8,%eax
f0100e05:	09 f0                	or     %esi,%eax
}
f0100e07:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0a:	5b                   	pop    %ebx
f0100e0b:	5e                   	pop    %esi
f0100e0c:	5f                   	pop    %edi
f0100e0d:	5d                   	pop    %ebp
f0100e0e:	c3                   	ret    

f0100e0f <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100e0f:	55                   	push   %ebp
f0100e10:	89 e5                	mov    %esp,%ebp
f0100e12:	56                   	push   %esi
f0100e13:	53                   	push   %ebx
f0100e14:	e8 41 26 00 00       	call   f010345a <__x86.get_pc_thunk.dx>
f0100e19:	81 c2 f3 74 01 00    	add    $0x174f3,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100e1f:	83 ba ac 1f 00 00 00 	cmpl   $0x0,0x1fac(%edx)
f0100e26:	74 3f                	je     f0100e67 <boot_alloc+0x58>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	if (!n)
f0100e28:	85 c0                	test   %eax,%eax
f0100e2a:	74 55                	je     f0100e81 <boot_alloc+0x72>
		return nextfree;
	char* new_nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100e2c:	8b b2 ac 1f 00 00    	mov    0x1fac(%edx),%esi
f0100e32:	8d 8c 06 ff 0f 00 00 	lea    0xfff(%esi,%eax,1),%ecx
f0100e39:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100e3f:	39 ce                	cmp    %ecx,%esi
f0100e41:	73 46                	jae    f0100e89 <boot_alloc+0x7a>
		((uintptr_t) new_nextfree <= (uintptr_t) KERNBASE + npages * PGSIZE)){
f0100e43:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0100e49:	8b 18                	mov    (%eax),%ebx
f0100e4b:	81 c3 00 00 0f 00    	add    $0xf0000,%ebx
f0100e51:	c1 e3 0c             	shl    $0xc,%ebx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100e54:	39 cb                	cmp    %ecx,%ebx
f0100e56:	72 31                	jb     f0100e89 <boot_alloc+0x7a>
		//May Alloc too much memory, and the pinter excedded 2^32
		char* result = nextfree;
		nextfree = new_nextfree;
f0100e58:	89 8a ac 1f 00 00    	mov    %ecx,0x1fac(%edx)
		return (void*) result;
	}
	panic("Warning : bad alloc request");
	return NULL;
}
f0100e5e:	89 f0                	mov    %esi,%eax
f0100e60:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e63:	5b                   	pop    %ebx
f0100e64:	5e                   	pop    %esi
f0100e65:	5d                   	pop    %ebp
f0100e66:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100e67:	c7 c1 c0 a6 11 f0    	mov    $0xf011a6c0,%ecx
f0100e6d:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100e73:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100e79:	89 8a ac 1f 00 00    	mov    %ecx,0x1fac(%edx)
f0100e7f:	eb a7                	jmp    f0100e28 <boot_alloc+0x19>
		return nextfree;
f0100e81:	8b b2 ac 1f 00 00    	mov    0x1fac(%edx),%esi
f0100e87:	eb d5                	jmp    f0100e5e <boot_alloc+0x4f>
	panic("Warning : bad alloc request");
f0100e89:	83 ec 04             	sub    $0x4,%esp
f0100e8c:	8d 82 a8 c8 fe ff    	lea    -0x13758(%edx),%eax
f0100e92:	50                   	push   %eax
f0100e93:	6a 74                	push   $0x74
f0100e95:	8d 82 c4 c8 fe ff    	lea    -0x1373c(%edx),%eax
f0100e9b:	50                   	push   %eax
f0100e9c:	89 d3                	mov    %edx,%ebx
f0100e9e:	e8 f6 f1 ff ff       	call   f0100099 <_panic>

f0100ea3 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ea3:	55                   	push   %ebp
f0100ea4:	89 e5                	mov    %esp,%ebp
f0100ea6:	56                   	push   %esi
f0100ea7:	53                   	push   %ebx
f0100ea8:	e8 b1 25 00 00       	call   f010345e <__x86.get_pc_thunk.cx>
f0100ead:	81 c1 5f 74 01 00    	add    $0x1745f,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100eb3:	89 d3                	mov    %edx,%ebx
f0100eb5:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100eb8:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100ebb:	a8 01                	test   $0x1,%al
f0100ebd:	74 5a                	je     f0100f19 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ebf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec4:	89 c6                	mov    %eax,%esi
f0100ec6:	c1 ee 0c             	shr    $0xc,%esi
f0100ec9:	c7 c3 c8 a6 11 f0    	mov    $0xf011a6c8,%ebx
f0100ecf:	3b 33                	cmp    (%ebx),%esi
f0100ed1:	73 2b                	jae    f0100efe <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100ed3:	c1 ea 0c             	shr    $0xc,%edx
f0100ed6:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100edc:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ee3:	89 c2                	mov    %eax,%edx
f0100ee5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ee8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100eed:	85 d2                	test   %edx,%edx
f0100eef:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ef4:	0f 44 c2             	cmove  %edx,%eax
}
f0100ef7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100efa:	5b                   	pop    %ebx
f0100efb:	5e                   	pop    %esi
f0100efc:	5d                   	pop    %ebp
f0100efd:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100efe:	50                   	push   %eax
f0100eff:	8d 81 a8 cb fe ff    	lea    -0x13458(%ecx),%eax
f0100f05:	50                   	push   %eax
f0100f06:	68 e3 02 00 00       	push   $0x2e3
f0100f0b:	8d 81 c4 c8 fe ff    	lea    -0x1373c(%ecx),%eax
f0100f11:	50                   	push   %eax
f0100f12:	89 cb                	mov    %ecx,%ebx
f0100f14:	e8 80 f1 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100f19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f1e:	eb d7                	jmp    f0100ef7 <check_va2pa+0x54>

f0100f20 <check_page_free_list>:
{
f0100f20:	55                   	push   %ebp
f0100f21:	89 e5                	mov    %esp,%ebp
f0100f23:	57                   	push   %edi
f0100f24:	56                   	push   %esi
f0100f25:	53                   	push   %ebx
f0100f26:	83 ec 3c             	sub    $0x3c,%esp
f0100f29:	e8 38 25 00 00       	call   f0103466 <__x86.get_pc_thunk.di>
f0100f2e:	81 c7 de 73 01 00    	add    $0x173de,%edi
f0100f34:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f37:	84 c0                	test   %al,%al
f0100f39:	0f 85 dd 02 00 00    	jne    f010121c <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100f3f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f42:	83 b8 b0 1f 00 00 00 	cmpl   $0x0,0x1fb0(%eax)
f0100f49:	74 0c                	je     f0100f57 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f4b:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100f52:	e9 2f 03 00 00       	jmp    f0101286 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100f57:	83 ec 04             	sub    $0x4,%esp
f0100f5a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100f5d:	8d 83 cc cb fe ff    	lea    -0x13434(%ebx),%eax
f0100f63:	50                   	push   %eax
f0100f64:	68 24 02 00 00       	push   $0x224
f0100f69:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0100f6f:	50                   	push   %eax
f0100f70:	e8 24 f1 ff ff       	call   f0100099 <_panic>
f0100f75:	50                   	push   %eax
f0100f76:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100f79:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0100f7f:	50                   	push   %eax
f0100f80:	6a 52                	push   $0x52
f0100f82:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0100f88:	50                   	push   %eax
f0100f89:	e8 0b f1 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f8e:	8b 36                	mov    (%esi),%esi
f0100f90:	85 f6                	test   %esi,%esi
f0100f92:	74 40                	je     f0100fd4 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f94:	89 f0                	mov    %esi,%eax
f0100f96:	2b 07                	sub    (%edi),%eax
f0100f98:	c1 f8 03             	sar    $0x3,%eax
f0100f9b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100f9e:	89 c2                	mov    %eax,%edx
f0100fa0:	c1 ea 16             	shr    $0x16,%edx
f0100fa3:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100fa6:	73 e6                	jae    f0100f8e <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100fa8:	89 c2                	mov    %eax,%edx
f0100faa:	c1 ea 0c             	shr    $0xc,%edx
f0100fad:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100fb0:	3b 11                	cmp    (%ecx),%edx
f0100fb2:	73 c1                	jae    f0100f75 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100fb4:	83 ec 04             	sub    $0x4,%esp
f0100fb7:	68 80 00 00 00       	push   $0x80
f0100fbc:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100fc1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100fca:	e8 33 31 00 00       	call   f0104102 <memset>
f0100fcf:	83 c4 10             	add    $0x10,%esp
f0100fd2:	eb ba                	jmp    f0100f8e <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100fd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd9:	e8 31 fe ff ff       	call   f0100e0f <boot_alloc>
f0100fde:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fe1:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100fe4:	8b 97 b0 1f 00 00    	mov    0x1fb0(%edi),%edx
		assert(pp >= pages);
f0100fea:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0100ff0:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100ff2:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0100ff8:	8b 00                	mov    (%eax),%eax
f0100ffa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ffd:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101000:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0101003:	bf 00 00 00 00       	mov    $0x0,%edi
f0101008:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010100b:	e9 08 01 00 00       	jmp    f0101118 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0101010:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101013:	8d 83 de c8 fe ff    	lea    -0x13722(%ebx),%eax
f0101019:	50                   	push   %eax
f010101a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101020:	50                   	push   %eax
f0101021:	68 3e 02 00 00       	push   $0x23e
f0101026:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010102c:	50                   	push   %eax
f010102d:	e8 67 f0 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0101032:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101035:	8d 83 ff c8 fe ff    	lea    -0x13701(%ebx),%eax
f010103b:	50                   	push   %eax
f010103c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101042:	50                   	push   %eax
f0101043:	68 3f 02 00 00       	push   $0x23f
f0101048:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010104e:	50                   	push   %eax
f010104f:	e8 45 f0 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101054:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101057:	8d 83 f0 cb fe ff    	lea    -0x13410(%ebx),%eax
f010105d:	50                   	push   %eax
f010105e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101064:	50                   	push   %eax
f0101065:	68 40 02 00 00       	push   $0x240
f010106a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101070:	50                   	push   %eax
f0101071:	e8 23 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0101076:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101079:	8d 83 13 c9 fe ff    	lea    -0x136ed(%ebx),%eax
f010107f:	50                   	push   %eax
f0101080:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101086:	50                   	push   %eax
f0101087:	68 43 02 00 00       	push   $0x243
f010108c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101092:	50                   	push   %eax
f0101093:	e8 01 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101098:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010109b:	8d 83 24 c9 fe ff    	lea    -0x136dc(%ebx),%eax
f01010a1:	50                   	push   %eax
f01010a2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01010a8:	50                   	push   %eax
f01010a9:	68 44 02 00 00       	push   $0x244
f01010ae:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01010b4:	50                   	push   %eax
f01010b5:	e8 df ef ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01010ba:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01010bd:	8d 83 24 cc fe ff    	lea    -0x133dc(%ebx),%eax
f01010c3:	50                   	push   %eax
f01010c4:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01010ca:	50                   	push   %eax
f01010cb:	68 45 02 00 00       	push   $0x245
f01010d0:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01010d6:	50                   	push   %eax
f01010d7:	e8 bd ef ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01010dc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01010df:	8d 83 3d c9 fe ff    	lea    -0x136c3(%ebx),%eax
f01010e5:	50                   	push   %eax
f01010e6:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01010ec:	50                   	push   %eax
f01010ed:	68 46 02 00 00       	push   $0x246
f01010f2:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01010f8:	50                   	push   %eax
f01010f9:	e8 9b ef ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f01010fe:	89 c6                	mov    %eax,%esi
f0101100:	c1 ee 0c             	shr    $0xc,%esi
f0101103:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0101106:	76 70                	jbe    f0101178 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0101108:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010110d:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101110:	77 7f                	ja     f0101191 <check_page_free_list+0x271>
			++nfree_extmem;
f0101112:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101116:	8b 12                	mov    (%edx),%edx
f0101118:	85 d2                	test   %edx,%edx
f010111a:	0f 84 93 00 00 00    	je     f01011b3 <check_page_free_list+0x293>
		assert(pp >= pages);
f0101120:	39 d1                	cmp    %edx,%ecx
f0101122:	0f 87 e8 fe ff ff    	ja     f0101010 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0101128:	39 d3                	cmp    %edx,%ebx
f010112a:	0f 86 02 ff ff ff    	jbe    f0101032 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101130:	89 d0                	mov    %edx,%eax
f0101132:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0101135:	a8 07                	test   $0x7,%al
f0101137:	0f 85 17 ff ff ff    	jne    f0101054 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f010113d:	c1 f8 03             	sar    $0x3,%eax
f0101140:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0101143:	85 c0                	test   %eax,%eax
f0101145:	0f 84 2b ff ff ff    	je     f0101076 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f010114b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101150:	0f 84 42 ff ff ff    	je     f0101098 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101156:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f010115b:	0f 84 59 ff ff ff    	je     f01010ba <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101161:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101166:	0f 84 70 ff ff ff    	je     f01010dc <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010116c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101171:	77 8b                	ja     f01010fe <check_page_free_list+0x1de>
			++nfree_basemem;
f0101173:	83 c7 01             	add    $0x1,%edi
f0101176:	eb 9e                	jmp    f0101116 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101178:	50                   	push   %eax
f0101179:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010117c:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0101182:	50                   	push   %eax
f0101183:	6a 52                	push   $0x52
f0101185:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f010118b:	50                   	push   %eax
f010118c:	e8 08 ef ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101191:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0101194:	8d 83 48 cc fe ff    	lea    -0x133b8(%ebx),%eax
f010119a:	50                   	push   %eax
f010119b:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01011a1:	50                   	push   %eax
f01011a2:	68 47 02 00 00       	push   $0x247
f01011a7:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01011ad:	50                   	push   %eax
f01011ae:	e8 e6 ee ff ff       	call   f0100099 <_panic>
f01011b3:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f01011b6:	85 ff                	test   %edi,%edi
f01011b8:	7e 1e                	jle    f01011d8 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f01011ba:	85 f6                	test   %esi,%esi
f01011bc:	7e 3c                	jle    f01011fa <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f01011be:	83 ec 0c             	sub    $0xc,%esp
f01011c1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011c4:	8d 83 90 cc fe ff    	lea    -0x13370(%ebx),%eax
f01011ca:	50                   	push   %eax
f01011cb:	e8 21 23 00 00       	call   f01034f1 <cprintf>
}
f01011d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011d3:	5b                   	pop    %ebx
f01011d4:	5e                   	pop    %esi
f01011d5:	5f                   	pop    %edi
f01011d6:	5d                   	pop    %ebp
f01011d7:	c3                   	ret    
	assert(nfree_basemem > 0);
f01011d8:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011db:	8d 83 57 c9 fe ff    	lea    -0x136a9(%ebx),%eax
f01011e1:	50                   	push   %eax
f01011e2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01011e8:	50                   	push   %eax
f01011e9:	68 4f 02 00 00       	push   $0x24f
f01011ee:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01011f4:	50                   	push   %eax
f01011f5:	e8 9f ee ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f01011fa:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01011fd:	8d 83 69 c9 fe ff    	lea    -0x13697(%ebx),%eax
f0101203:	50                   	push   %eax
f0101204:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010120a:	50                   	push   %eax
f010120b:	68 50 02 00 00       	push   $0x250
f0101210:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101216:	50                   	push   %eax
f0101217:	e8 7d ee ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f010121c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010121f:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0101225:	85 c0                	test   %eax,%eax
f0101227:	0f 84 2a fd ff ff    	je     f0100f57 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010122d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0101230:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101233:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101236:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0101239:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010123c:	c7 c3 d0 a6 11 f0    	mov    $0xf011a6d0,%ebx
f0101242:	89 c2                	mov    %eax,%edx
f0101244:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101246:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f010124c:	0f 95 c2             	setne  %dl
f010124f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0101252:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101256:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101258:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010125c:	8b 00                	mov    (%eax),%eax
f010125e:	85 c0                	test   %eax,%eax
f0101260:	75 e0                	jne    f0101242 <check_page_free_list+0x322>
		*tp[1] = 0;
f0101262:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101265:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010126b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010126e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101271:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101273:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101276:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101279:	89 87 b0 1f 00 00    	mov    %eax,0x1fb0(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010127f:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101286:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0101289:	8b b0 b0 1f 00 00    	mov    0x1fb0(%eax),%esi
f010128f:	c7 c7 d0 a6 11 f0    	mov    $0xf011a6d0,%edi
	if (PGNUM(pa) >= npages)
f0101295:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010129b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010129e:	e9 ed fc ff ff       	jmp    f0100f90 <check_page_free_list+0x70>

f01012a3 <page_init>:
{
f01012a3:	55                   	push   %ebp
f01012a4:	89 e5                	mov    %esp,%ebp
f01012a6:	57                   	push   %edi
f01012a7:	56                   	push   %esi
f01012a8:	53                   	push   %ebx
f01012a9:	83 ec 1c             	sub    $0x1c,%esp
f01012ac:	e8 b1 21 00 00       	call   f0103462 <__x86.get_pc_thunk.si>
f01012b1:	81 c6 5b 70 01 00    	add    $0x1705b,%esi
	page_free_list = NULL;
f01012b7:	c7 86 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%esi)
f01012be:	00 00 00 
	for (i = 0; i < npages; i++) {
f01012c1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012c6:	c7 c7 c8 a6 11 f0    	mov    $0xf011a6c8,%edi
			pages[i].pp_ref = 0;
f01012cc:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01012d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < npages; i++) {
f01012d5:	eb 26                	jmp    f01012fd <page_init+0x5a>
		else if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE){
f01012d7:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f01012dd:	83 f8 5f             	cmp    $0x5f,%eax
f01012e0:	77 3f                	ja     f0101321 <page_init+0x7e>
			pages[i].pp_link = NULL;
f01012e2:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01012e8:	8b 10                	mov    (%eax),%edx
f01012ea:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
			pages[i].pp_ref = 1;
f01012f1:	8b 00                	mov    (%eax),%eax
f01012f3:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = 0; i < npages; i++) {
f01012fa:	83 c3 01             	add    $0x1,%ebx
f01012fd:	39 1f                	cmp    %ebx,(%edi)
f01012ff:	0f 86 80 00 00 00    	jbe    f0101385 <page_init+0xe2>
		if (i == 0){
f0101305:	85 db                	test   %ebx,%ebx
f0101307:	75 ce                	jne    f01012d7 <page_init+0x34>
			pages[i].pp_link = NULL;
f0101309:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010130f:	8b 10                	mov    (%eax),%edx
f0101311:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
			pages[i].pp_ref = 1;
f0101317:	8b 00                	mov    (%eax),%eax
f0101319:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f010131f:	eb d9                	jmp    f01012fa <page_init+0x57>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f0101321:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101327:	77 29                	ja     f0101352 <page_init+0xaf>
f0101329:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0101330:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101333:	89 c2                	mov    %eax,%edx
f0101335:	03 11                	add    (%ecx),%edx
f0101337:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f010133d:	8b 8e b0 1f 00 00    	mov    0x1fb0(%esi),%ecx
f0101343:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0101345:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101348:	03 01                	add    (%ecx),%eax
f010134a:	89 86 b0 1f 00 00    	mov    %eax,0x1fb0(%esi)
f0101350:	eb a8                	jmp    f01012fa <page_init+0x57>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f0101352:	b8 00 00 00 00       	mov    $0x0,%eax
f0101357:	e8 b3 fa ff ff       	call   f0100e0f <boot_alloc>
f010135c:	05 00 00 00 10       	add    $0x10000000,%eax
f0101361:	c1 e8 0c             	shr    $0xc,%eax
f0101364:	39 d8                	cmp    %ebx,%eax
f0101366:	76 c1                	jbe    f0101329 <page_init+0x86>
			pages[i].pp_link = NULL;
f0101368:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010136e:	8b 10                	mov    (%eax),%edx
f0101370:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
			pages[i].pp_ref = 1;
f0101377:	8b 00                	mov    (%eax),%eax
f0101379:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f0101380:	e9 75 ff ff ff       	jmp    f01012fa <page_init+0x57>
}
f0101385:	83 c4 1c             	add    $0x1c,%esp
f0101388:	5b                   	pop    %ebx
f0101389:	5e                   	pop    %esi
f010138a:	5f                   	pop    %edi
f010138b:	5d                   	pop    %ebp
f010138c:	c3                   	ret    

f010138d <page_alloc>:
{
f010138d:	55                   	push   %ebp
f010138e:	89 e5                	mov    %esp,%ebp
f0101390:	56                   	push   %esi
f0101391:	53                   	push   %ebx
f0101392:	e8 b8 ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101397:	81 c3 75 6f 01 00    	add    $0x16f75,%ebx
	if (page_free_list == NULL)
f010139d:	8b b3 b0 1f 00 00    	mov    0x1fb0(%ebx),%esi
f01013a3:	85 f6                	test   %esi,%esi
f01013a5:	74 14                	je     f01013bb <page_alloc+0x2e>
	page_free_list = page_free_list -> pp_link;
f01013a7:	8b 06                	mov    (%esi),%eax
f01013a9:	89 83 b0 1f 00 00    	mov    %eax,0x1fb0(%ebx)
	info -> pp_link = NULL;
f01013af:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO)
f01013b5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01013b9:	75 09                	jne    f01013c4 <page_alloc+0x37>
}
f01013bb:	89 f0                	mov    %esi,%eax
f01013bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013c0:	5b                   	pop    %ebx
f01013c1:	5e                   	pop    %esi
f01013c2:	5d                   	pop    %ebp
f01013c3:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f01013c4:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01013ca:	89 f2                	mov    %esi,%edx
f01013cc:	2b 10                	sub    (%eax),%edx
f01013ce:	89 d0                	mov    %edx,%eax
f01013d0:	c1 f8 03             	sar    $0x3,%eax
f01013d3:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01013d6:	89 c1                	mov    %eax,%ecx
f01013d8:	c1 e9 0c             	shr    $0xc,%ecx
f01013db:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01013e1:	3b 0a                	cmp    (%edx),%ecx
f01013e3:	73 1a                	jae    f01013ff <page_alloc+0x72>
		memset(page2kva(info), 0, PGSIZE);
f01013e5:	83 ec 04             	sub    $0x4,%esp
f01013e8:	68 00 10 00 00       	push   $0x1000
f01013ed:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01013ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013f4:	50                   	push   %eax
f01013f5:	e8 08 2d 00 00       	call   f0104102 <memset>
f01013fa:	83 c4 10             	add    $0x10,%esp
f01013fd:	eb bc                	jmp    f01013bb <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013ff:	50                   	push   %eax
f0101400:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0101406:	50                   	push   %eax
f0101407:	6a 52                	push   $0x52
f0101409:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f010140f:	50                   	push   %eax
f0101410:	e8 84 ec ff ff       	call   f0100099 <_panic>

f0101415 <page_free>:
{
f0101415:	55                   	push   %ebp
f0101416:	89 e5                	mov    %esp,%ebp
f0101418:	53                   	push   %ebx
f0101419:	83 ec 04             	sub    $0x4,%esp
f010141c:	e8 2e ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101421:	81 c3 eb 6e 01 00    	add    $0x16eeb,%ebx
f0101427:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0)
f010142a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010142f:	75 18                	jne    f0101449 <page_free+0x34>
	if (pp->pp_link != NULL)
f0101431:	83 38 00             	cmpl   $0x0,(%eax)
f0101434:	75 2e                	jne    f0101464 <page_free+0x4f>
	pp->pp_link = page_free_list;
f0101436:	8b 8b b0 1f 00 00    	mov    0x1fb0(%ebx),%ecx
f010143c:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010143e:	89 83 b0 1f 00 00    	mov    %eax,0x1fb0(%ebx)
}
f0101444:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101447:	c9                   	leave  
f0101448:	c3                   	ret    
		panic("page_free(): pp->pp_ref is not zero!");
f0101449:	83 ec 04             	sub    $0x4,%esp
f010144c:	8d 83 b4 cc fe ff    	lea    -0x1334c(%ebx),%eax
f0101452:	50                   	push   %eax
f0101453:	68 4e 01 00 00       	push   $0x14e
f0101458:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010145e:	50                   	push   %eax
f010145f:	e8 35 ec ff ff       	call   f0100099 <_panic>
		panic("page_free(): pp has already be freed!");
f0101464:	83 ec 04             	sub    $0x4,%esp
f0101467:	8d 83 dc cc fe ff    	lea    -0x13324(%ebx),%eax
f010146d:	50                   	push   %eax
f010146e:	68 50 01 00 00       	push   $0x150
f0101473:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101479:	50                   	push   %eax
f010147a:	e8 1a ec ff ff       	call   f0100099 <_panic>

f010147f <page_decref>:
{
f010147f:	55                   	push   %ebp
f0101480:	89 e5                	mov    %esp,%ebp
f0101482:	83 ec 08             	sub    $0x8,%esp
f0101485:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101488:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010148c:	83 e8 01             	sub    $0x1,%eax
f010148f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101493:	66 85 c0             	test   %ax,%ax
f0101496:	74 02                	je     f010149a <page_decref+0x1b>
}
f0101498:	c9                   	leave  
f0101499:	c3                   	ret    
		page_free(pp);
f010149a:	83 ec 0c             	sub    $0xc,%esp
f010149d:	52                   	push   %edx
f010149e:	e8 72 ff ff ff       	call   f0101415 <page_free>
f01014a3:	83 c4 10             	add    $0x10,%esp
}
f01014a6:	eb f0                	jmp    f0101498 <page_decref+0x19>

f01014a8 <pgdir_walk>:
{
f01014a8:	55                   	push   %ebp
f01014a9:	89 e5                	mov    %esp,%ebp
f01014ab:	57                   	push   %edi
f01014ac:	56                   	push   %esi
f01014ad:	53                   	push   %ebx
f01014ae:	83 ec 0c             	sub    $0xc,%esp
f01014b1:	e8 99 ec ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01014b6:	81 c3 56 6e 01 00    	add    $0x16e56,%ebx
f01014bc:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t* dict_ptr = pgdir + PDX(va);
f01014bf:	89 f7                	mov    %esi,%edi
f01014c1:	c1 ef 16             	shr    $0x16,%edi
f01014c4:	c1 e7 02             	shl    $0x2,%edi
f01014c7:	03 7d 08             	add    0x8(%ebp),%edi
	if ((*dict_ptr) & PTE_P){
f01014ca:	8b 07                	mov    (%edi),%eax
f01014cc:	a8 01                	test   $0x1,%al
f01014ce:	74 45                	je     f0101515 <pgdir_walk+0x6d>
		return (pte_t*)(KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t));
f01014d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01014d5:	89 c2                	mov    %eax,%edx
f01014d7:	c1 ea 0c             	shr    $0xc,%edx
f01014da:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f01014e0:	39 11                	cmp    %edx,(%ecx)
f01014e2:	76 18                	jbe    f01014fc <pgdir_walk+0x54>
f01014e4:	c1 ee 0a             	shr    $0xa,%esi
f01014e7:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01014ed:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f01014f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014f7:	5b                   	pop    %ebx
f01014f8:	5e                   	pop    %esi
f01014f9:	5f                   	pop    %edi
f01014fa:	5d                   	pop    %ebp
f01014fb:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014fc:	50                   	push   %eax
f01014fd:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0101503:	50                   	push   %eax
f0101504:	68 7d 01 00 00       	push   $0x17d
f0101509:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010150f:	50                   	push   %eax
f0101510:	e8 84 eb ff ff       	call   f0100099 <_panic>
		if (create == false)
f0101515:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101519:	74 65                	je     f0101580 <pgdir_walk+0xd8>
		struct PageInfo* page_itr = page_alloc(ALLOC_ZERO);
f010151b:	83 ec 0c             	sub    $0xc,%esp
f010151e:	6a 01                	push   $0x1
f0101520:	e8 68 fe ff ff       	call   f010138d <page_alloc>
		if (page_itr == NULL)
f0101525:	83 c4 10             	add    $0x10,%esp
f0101528:	85 c0                	test   %eax,%eax
f010152a:	74 5e                	je     f010158a <pgdir_walk+0xe2>
		page_itr -> pp_ref++;
f010152c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101531:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101537:	2b 02                	sub    (%edx),%eax
f0101539:	c1 f8 03             	sar    $0x3,%eax
f010153c:	c1 e0 0c             	shl    $0xc,%eax
		*dict_ptr = page2pa(page_itr) | PTE_P | PTE_W | PTE_U;
f010153f:	89 c2                	mov    %eax,%edx
f0101541:	83 ca 07             	or     $0x7,%edx
f0101544:	89 17                	mov    %edx,(%edi)
	if (PGNUM(pa) >= npages)
f0101546:	89 c1                	mov    %eax,%ecx
f0101548:	c1 e9 0c             	shr    $0xc,%ecx
f010154b:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0101551:	3b 0a                	cmp    (%edx),%ecx
f0101553:	73 12                	jae    f0101567 <pgdir_walk+0xbf>
		return KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t);
f0101555:	c1 ee 0a             	shr    $0xa,%esi
f0101558:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010155e:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101565:	eb 8d                	jmp    f01014f4 <pgdir_walk+0x4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101567:	50                   	push   %eax
f0101568:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f010156e:	50                   	push   %eax
f010156f:	68 89 01 00 00       	push   $0x189
f0101574:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010157a:	50                   	push   %eax
f010157b:	e8 19 eb ff ff       	call   f0100099 <_panic>
			return NULL;
f0101580:	b8 00 00 00 00       	mov    $0x0,%eax
f0101585:	e9 6a ff ff ff       	jmp    f01014f4 <pgdir_walk+0x4c>
			return NULL;
f010158a:	b8 00 00 00 00       	mov    $0x0,%eax
f010158f:	e9 60 ff ff ff       	jmp    f01014f4 <pgdir_walk+0x4c>

f0101594 <boot_map_region>:
{
f0101594:	55                   	push   %ebp
f0101595:	89 e5                	mov    %esp,%ebp
f0101597:	57                   	push   %edi
f0101598:	56                   	push   %esi
f0101599:	53                   	push   %ebx
f010159a:	83 ec 1c             	sub    $0x1c,%esp
f010159d:	e8 c0 1e 00 00       	call   f0103462 <__x86.get_pc_thunk.si>
f01015a2:	81 c6 6a 6d 01 00    	add    $0x16d6a,%esi
f01015a8:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01015ab:	89 c7                	mov    %eax,%edi
f01015ad:	89 d6                	mov    %edx,%esi
f01015af:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f01015b2:	bb 00 00 00 00       	mov    $0x0,%ebx
		*pte_itr = (pa + i) | perm | PTE_P;
f01015b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ba:	83 c8 01             	or     $0x1,%eax
f01015bd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f01015c0:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01015c3:	73 46                	jae    f010160b <boot_map_region+0x77>
		uintptr_t* pte_itr = pgdir_walk(pgdir, (void*)(va + i), true);
f01015c5:	83 ec 04             	sub    $0x4,%esp
f01015c8:	6a 01                	push   $0x1
f01015ca:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f01015cd:	50                   	push   %eax
f01015ce:	57                   	push   %edi
f01015cf:	e8 d4 fe ff ff       	call   f01014a8 <pgdir_walk>
		if (pte_itr == NULL)
f01015d4:	83 c4 10             	add    $0x10,%esp
f01015d7:	85 c0                	test   %eax,%eax
f01015d9:	74 12                	je     f01015ed <boot_map_region+0x59>
		*pte_itr = (pa + i) | perm | PTE_P;
f01015db:	89 da                	mov    %ebx,%edx
f01015dd:	03 55 08             	add    0x8(%ebp),%edx
f01015e0:	0b 55 e0             	or     -0x20(%ebp),%edx
f01015e3:	89 10                	mov    %edx,(%eax)
	for (size_t i = 0; i < size; i += PGSIZE){
f01015e5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01015eb:	eb d3                	jmp    f01015c0 <boot_map_region+0x2c>
			panic("boot_map_region(): Map failed, bad virtual memory address");
f01015ed:	83 ec 04             	sub    $0x4,%esp
f01015f0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01015f3:	8d 83 04 cd fe ff    	lea    -0x132fc(%ebx),%eax
f01015f9:	50                   	push   %eax
f01015fa:	68 9f 01 00 00       	push   $0x19f
f01015ff:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101605:	50                   	push   %eax
f0101606:	e8 8e ea ff ff       	call   f0100099 <_panic>
}
f010160b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010160e:	5b                   	pop    %ebx
f010160f:	5e                   	pop    %esi
f0101610:	5f                   	pop    %edi
f0101611:	5d                   	pop    %ebp
f0101612:	c3                   	ret    

f0101613 <page_lookup>:
{
f0101613:	55                   	push   %ebp
f0101614:	89 e5                	mov    %esp,%ebp
f0101616:	56                   	push   %esi
f0101617:	53                   	push   %ebx
f0101618:	e8 32 eb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010161d:	81 c3 ef 6c 01 00    	add    $0x16cef,%ebx
f0101623:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t* pte_itr = pgdir_walk(pgdir, va, false);
f0101626:	83 ec 04             	sub    $0x4,%esp
f0101629:	6a 00                	push   $0x0
f010162b:	ff 75 0c             	pushl  0xc(%ebp)
f010162e:	ff 75 08             	pushl  0x8(%ebp)
f0101631:	e8 72 fe ff ff       	call   f01014a8 <pgdir_walk>
	if (pte_itr == NULL)
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	85 c0                	test   %eax,%eax
f010163b:	74 44                	je     f0101681 <page_lookup+0x6e>
	if ((*pte_itr) & PTE_P){
f010163d:	f6 00 01             	testb  $0x1,(%eax)
f0101640:	74 46                	je     f0101688 <page_lookup+0x75>
		if (pte_store != NULL)
f0101642:	85 f6                	test   %esi,%esi
f0101644:	74 02                	je     f0101648 <page_lookup+0x35>
			*pte_store = pte_itr;
f0101646:	89 06                	mov    %eax,(%esi)
f0101648:	8b 00                	mov    (%eax),%eax
f010164a:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010164d:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0101653:	39 02                	cmp    %eax,(%edx)
f0101655:	76 12                	jbe    f0101669 <page_lookup+0x56>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101657:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f010165d:	8b 12                	mov    (%edx),%edx
f010165f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101662:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101665:	5b                   	pop    %ebx
f0101666:	5e                   	pop    %esi
f0101667:	5d                   	pop    %ebp
f0101668:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101669:	83 ec 04             	sub    $0x4,%esp
f010166c:	8d 83 40 cd fe ff    	lea    -0x132c0(%ebx),%eax
f0101672:	50                   	push   %eax
f0101673:	6a 4b                	push   $0x4b
f0101675:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f010167b:	50                   	push   %eax
f010167c:	e8 18 ea ff ff       	call   f0100099 <_panic>
		return NULL;
f0101681:	b8 00 00 00 00       	mov    $0x0,%eax
f0101686:	eb da                	jmp    f0101662 <page_lookup+0x4f>
		return NULL;
f0101688:	b8 00 00 00 00       	mov    $0x0,%eax
f010168d:	eb d3                	jmp    f0101662 <page_lookup+0x4f>

f010168f <page_remove>:
{
f010168f:	55                   	push   %ebp
f0101690:	89 e5                	mov    %esp,%ebp
f0101692:	53                   	push   %ebx
f0101693:	83 ec 18             	sub    $0x18,%esp
f0101696:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo* page_itr = page_lookup(pgdir, va, &pte_itr);
f0101699:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010169c:	50                   	push   %eax
f010169d:	53                   	push   %ebx
f010169e:	ff 75 08             	pushl  0x8(%ebp)
f01016a1:	e8 6d ff ff ff       	call   f0101613 <page_lookup>
	if (page_itr == NULL)
f01016a6:	83 c4 10             	add    $0x10,%esp
f01016a9:	85 c0                	test   %eax,%eax
f01016ab:	74 1c                	je     f01016c9 <page_remove+0x3a>
	page_decref(page_itr);
f01016ad:	83 ec 0c             	sub    $0xc,%esp
f01016b0:	50                   	push   %eax
f01016b1:	e8 c9 fd ff ff       	call   f010147f <page_decref>
	if (pte_itr != NULL)
f01016b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016b9:	83 c4 10             	add    $0x10,%esp
f01016bc:	85 c0                	test   %eax,%eax
f01016be:	74 06                	je     f01016c6 <page_remove+0x37>
		*pte_itr = 0;
f01016c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01016c6:	0f 01 3b             	invlpg (%ebx)
}
f01016c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016cc:	c9                   	leave  
f01016cd:	c3                   	ret    

f01016ce <page_insert>:
{
f01016ce:	55                   	push   %ebp
f01016cf:	89 e5                	mov    %esp,%ebp
f01016d1:	57                   	push   %edi
f01016d2:	56                   	push   %esi
f01016d3:	53                   	push   %ebx
f01016d4:	83 ec 10             	sub    $0x10,%esp
f01016d7:	e8 8a 1d 00 00       	call   f0103466 <__x86.get_pc_thunk.di>
f01016dc:	81 c7 30 6c 01 00    	add    $0x16c30,%edi
f01016e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	pte_t* pte_ptr = pgdir_walk(pgdir, va, true);
f01016e5:	6a 01                	push   $0x1
f01016e7:	ff 75 10             	pushl  0x10(%ebp)
f01016ea:	53                   	push   %ebx
f01016eb:	e8 b8 fd ff ff       	call   f01014a8 <pgdir_walk>
	if (pte_ptr == NULL)
f01016f0:	83 c4 10             	add    $0x10,%esp
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	74 56                	je     f010174d <page_insert+0x7f>
f01016f7:	89 c6                	mov    %eax,%esi
	++pp->pp_ref;
f01016f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016fc:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*pte_ptr) & PTE_P)
f0101701:	f6 06 01             	testb  $0x1,(%esi)
f0101704:	75 36                	jne    f010173c <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f0101706:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010170c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010170f:	2b 08                	sub    (%eax),%ecx
f0101711:	89 c8                	mov    %ecx,%eax
f0101713:	c1 f8 03             	sar    $0x3,%eax
f0101716:	c1 e0 0c             	shl    $0xc,%eax
	*pte_ptr = page2pa(pp) | perm | PTE_P;
f0101719:	8b 55 14             	mov    0x14(%ebp),%edx
f010171c:	83 ca 01             	or     $0x1,%edx
f010171f:	09 d0                	or     %edx,%eax
f0101721:	89 06                	mov    %eax,(%esi)
	pde_t* dict_ptr = pgdir + PDX(va);
f0101723:	8b 45 10             	mov    0x10(%ebp),%eax
f0101726:	c1 e8 16             	shr    $0x16,%eax
	*dict_ptr |= perm;
f0101729:	8b 7d 14             	mov    0x14(%ebp),%edi
f010172c:	09 3c 83             	or     %edi,(%ebx,%eax,4)
	return 0;
f010172f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101734:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101737:	5b                   	pop    %ebx
f0101738:	5e                   	pop    %esi
f0101739:	5f                   	pop    %edi
f010173a:	5d                   	pop    %ebp
f010173b:	c3                   	ret    
		page_remove(pgdir, va);
f010173c:	83 ec 08             	sub    $0x8,%esp
f010173f:	ff 75 10             	pushl  0x10(%ebp)
f0101742:	53                   	push   %ebx
f0101743:	e8 47 ff ff ff       	call   f010168f <page_remove>
f0101748:	83 c4 10             	add    $0x10,%esp
f010174b:	eb b9                	jmp    f0101706 <page_insert+0x38>
		return -E_NO_MEM;
f010174d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101752:	eb e0                	jmp    f0101734 <page_insert+0x66>

f0101754 <mem_init>:
{
f0101754:	55                   	push   %ebp
f0101755:	89 e5                	mov    %esp,%ebp
f0101757:	57                   	push   %edi
f0101758:	56                   	push   %esi
f0101759:	53                   	push   %ebx
f010175a:	83 ec 3c             	sub    $0x3c,%esp
f010175d:	e8 8f ef ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0101762:	05 aa 6b 01 00       	add    $0x16baa,%eax
f0101767:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f010176a:	b8 15 00 00 00       	mov    $0x15,%eax
f010176f:	e8 65 f6 ff ff       	call   f0100dd9 <nvram_read>
f0101774:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101776:	b8 17 00 00 00       	mov    $0x17,%eax
f010177b:	e8 59 f6 ff ff       	call   f0100dd9 <nvram_read>
f0101780:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101782:	b8 34 00 00 00       	mov    $0x34,%eax
f0101787:	e8 4d f6 ff ff       	call   f0100dd9 <nvram_read>
f010178c:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f010178f:	85 c0                	test   %eax,%eax
f0101791:	0f 85 c6 00 00 00    	jne    f010185d <mem_init+0x109>
		totalmem = 1 * 1024 + extmem;
f0101797:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010179d:	85 f6                	test   %esi,%esi
f010179f:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01017a2:	89 c1                	mov    %eax,%ecx
f01017a4:	c1 e9 02             	shr    $0x2,%ecx
f01017a7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01017aa:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01017b0:	89 0a                	mov    %ecx,(%edx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017b2:	89 c2                	mov    %eax,%edx
f01017b4:	29 da                	sub    %ebx,%edx
f01017b6:	52                   	push   %edx
f01017b7:	53                   	push   %ebx
f01017b8:	50                   	push   %eax
f01017b9:	8d 87 60 cd fe ff    	lea    -0x132a0(%edi),%eax
f01017bf:	50                   	push   %eax
f01017c0:	89 fb                	mov    %edi,%ebx
f01017c2:	e8 2a 1d 00 00       	call   f01034f1 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01017c7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01017cc:	e8 3e f6 ff ff       	call   f0100e0f <boot_alloc>
f01017d1:	c7 c6 cc a6 11 f0    	mov    $0xf011a6cc,%esi
f01017d7:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01017d9:	83 c4 0c             	add    $0xc,%esp
f01017dc:	68 00 10 00 00       	push   $0x1000
f01017e1:	6a 00                	push   $0x0
f01017e3:	50                   	push   %eax
f01017e4:	e8 19 29 00 00       	call   f0104102 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01017e9:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01017eb:	83 c4 10             	add    $0x10,%esp
f01017ee:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01017f3:	76 72                	jbe    f0101867 <mem_init+0x113>
	return (physaddr_t)kva - KERNBASE;
f01017f5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01017fb:	83 ca 05             	or     $0x5,%edx
f01017fe:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	size_t pagesize = npages * sizeof(struct PageInfo);
f0101804:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101807:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010180d:	8b 00                	mov    (%eax),%eax
f010180f:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f0101816:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
	pages = (struct PageInfo*)boot_alloc(pagesize);
f0101819:	89 d8                	mov    %ebx,%eax
f010181b:	e8 ef f5 ff ff       	call   f0100e0f <boot_alloc>
f0101820:	c7 c6 d0 a6 11 f0    	mov    $0xf011a6d0,%esi
f0101826:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, pagesize);
f0101828:	83 ec 04             	sub    $0x4,%esp
f010182b:	53                   	push   %ebx
f010182c:	6a 00                	push   $0x0
f010182e:	50                   	push   %eax
f010182f:	89 fb                	mov    %edi,%ebx
f0101831:	e8 cc 28 00 00       	call   f0104102 <memset>
	page_init();
f0101836:	e8 68 fa ff ff       	call   f01012a3 <page_init>
	check_page_free_list(1);
f010183b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101840:	e8 db f6 ff ff       	call   f0100f20 <check_page_free_list>
	if (!pages)
f0101845:	83 c4 10             	add    $0x10,%esp
f0101848:	83 3e 00             	cmpl   $0x0,(%esi)
f010184b:	74 36                	je     f0101883 <mem_init+0x12f>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010184d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101850:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0101856:	be 00 00 00 00       	mov    $0x0,%esi
f010185b:	eb 49                	jmp    f01018a6 <mem_init+0x152>
		totalmem = 16 * 1024 + ext16mem;
f010185d:	05 00 40 00 00       	add    $0x4000,%eax
f0101862:	e9 3b ff ff ff       	jmp    f01017a2 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101867:	50                   	push   %eax
f0101868:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010186b:	8d 83 9c cd fe ff    	lea    -0x13264(%ebx),%eax
f0101871:	50                   	push   %eax
f0101872:	68 99 00 00 00       	push   $0x99
f0101877:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010187d:	50                   	push   %eax
f010187e:	e8 16 e8 ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101883:	83 ec 04             	sub    $0x4,%esp
f0101886:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101889:	8d 83 7a c9 fe ff    	lea    -0x13686(%ebx),%eax
f010188f:	50                   	push   %eax
f0101890:	68 63 02 00 00       	push   $0x263
f0101895:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010189b:	50                   	push   %eax
f010189c:	e8 f8 e7 ff ff       	call   f0100099 <_panic>
		++nfree;
f01018a1:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018a4:	8b 00                	mov    (%eax),%eax
f01018a6:	85 c0                	test   %eax,%eax
f01018a8:	75 f7                	jne    f01018a1 <mem_init+0x14d>
	assert((pp0 = page_alloc(0)));
f01018aa:	83 ec 0c             	sub    $0xc,%esp
f01018ad:	6a 00                	push   $0x0
f01018af:	e8 d9 fa ff ff       	call   f010138d <page_alloc>
f01018b4:	89 c3                	mov    %eax,%ebx
f01018b6:	83 c4 10             	add    $0x10,%esp
f01018b9:	85 c0                	test   %eax,%eax
f01018bb:	0f 84 3b 02 00 00    	je     f0101afc <mem_init+0x3a8>
	assert((pp1 = page_alloc(0)));
f01018c1:	83 ec 0c             	sub    $0xc,%esp
f01018c4:	6a 00                	push   $0x0
f01018c6:	e8 c2 fa ff ff       	call   f010138d <page_alloc>
f01018cb:	89 c7                	mov    %eax,%edi
f01018cd:	83 c4 10             	add    $0x10,%esp
f01018d0:	85 c0                	test   %eax,%eax
f01018d2:	0f 84 46 02 00 00    	je     f0101b1e <mem_init+0x3ca>
	assert((pp2 = page_alloc(0)));
f01018d8:	83 ec 0c             	sub    $0xc,%esp
f01018db:	6a 00                	push   $0x0
f01018dd:	e8 ab fa ff ff       	call   f010138d <page_alloc>
f01018e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01018e5:	83 c4 10             	add    $0x10,%esp
f01018e8:	85 c0                	test   %eax,%eax
f01018ea:	0f 84 50 02 00 00    	je     f0101b40 <mem_init+0x3ec>
	assert(pp1 && pp1 != pp0);
f01018f0:	39 fb                	cmp    %edi,%ebx
f01018f2:	0f 84 6a 02 00 00    	je     f0101b62 <mem_init+0x40e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018fb:	39 c3                	cmp    %eax,%ebx
f01018fd:	0f 84 81 02 00 00    	je     f0101b84 <mem_init+0x430>
f0101903:	39 c7                	cmp    %eax,%edi
f0101905:	0f 84 79 02 00 00    	je     f0101b84 <mem_init+0x430>
	return (pp - pages) << PGSHIFT;
f010190b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010190e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101914:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101916:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010191c:	8b 10                	mov    (%eax),%edx
f010191e:	c1 e2 0c             	shl    $0xc,%edx
f0101921:	89 d8                	mov    %ebx,%eax
f0101923:	29 c8                	sub    %ecx,%eax
f0101925:	c1 f8 03             	sar    $0x3,%eax
f0101928:	c1 e0 0c             	shl    $0xc,%eax
f010192b:	39 d0                	cmp    %edx,%eax
f010192d:	0f 83 73 02 00 00    	jae    f0101ba6 <mem_init+0x452>
f0101933:	89 f8                	mov    %edi,%eax
f0101935:	29 c8                	sub    %ecx,%eax
f0101937:	c1 f8 03             	sar    $0x3,%eax
f010193a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010193d:	39 c2                	cmp    %eax,%edx
f010193f:	0f 86 83 02 00 00    	jbe    f0101bc8 <mem_init+0x474>
f0101945:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101948:	29 c8                	sub    %ecx,%eax
f010194a:	c1 f8 03             	sar    $0x3,%eax
f010194d:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101950:	39 c2                	cmp    %eax,%edx
f0101952:	0f 86 92 02 00 00    	jbe    f0101bea <mem_init+0x496>
	fl = page_free_list;
f0101958:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010195b:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0101961:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101964:	c7 80 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%eax)
f010196b:	00 00 00 
	assert(!page_alloc(0));
f010196e:	83 ec 0c             	sub    $0xc,%esp
f0101971:	6a 00                	push   $0x0
f0101973:	e8 15 fa ff ff       	call   f010138d <page_alloc>
f0101978:	83 c4 10             	add    $0x10,%esp
f010197b:	85 c0                	test   %eax,%eax
f010197d:	0f 85 89 02 00 00    	jne    f0101c0c <mem_init+0x4b8>
	page_free(pp0);
f0101983:	83 ec 0c             	sub    $0xc,%esp
f0101986:	53                   	push   %ebx
f0101987:	e8 89 fa ff ff       	call   f0101415 <page_free>
	page_free(pp1);
f010198c:	89 3c 24             	mov    %edi,(%esp)
f010198f:	e8 81 fa ff ff       	call   f0101415 <page_free>
	page_free(pp2);
f0101994:	83 c4 04             	add    $0x4,%esp
f0101997:	ff 75 d0             	pushl  -0x30(%ebp)
f010199a:	e8 76 fa ff ff       	call   f0101415 <page_free>
	assert((pp0 = page_alloc(0)));
f010199f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a6:	e8 e2 f9 ff ff       	call   f010138d <page_alloc>
f01019ab:	89 c7                	mov    %eax,%edi
f01019ad:	83 c4 10             	add    $0x10,%esp
f01019b0:	85 c0                	test   %eax,%eax
f01019b2:	0f 84 76 02 00 00    	je     f0101c2e <mem_init+0x4da>
	assert((pp1 = page_alloc(0)));
f01019b8:	83 ec 0c             	sub    $0xc,%esp
f01019bb:	6a 00                	push   $0x0
f01019bd:	e8 cb f9 ff ff       	call   f010138d <page_alloc>
f01019c2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019c5:	83 c4 10             	add    $0x10,%esp
f01019c8:	85 c0                	test   %eax,%eax
f01019ca:	0f 84 80 02 00 00    	je     f0101c50 <mem_init+0x4fc>
	assert((pp2 = page_alloc(0)));
f01019d0:	83 ec 0c             	sub    $0xc,%esp
f01019d3:	6a 00                	push   $0x0
f01019d5:	e8 b3 f9 ff ff       	call   f010138d <page_alloc>
f01019da:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019dd:	83 c4 10             	add    $0x10,%esp
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	0f 84 8a 02 00 00    	je     f0101c72 <mem_init+0x51e>
	assert(pp1 && pp1 != pp0);
f01019e8:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01019eb:	0f 84 a3 02 00 00    	je     f0101c94 <mem_init+0x540>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019f1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01019f4:	39 c7                	cmp    %eax,%edi
f01019f6:	0f 84 ba 02 00 00    	je     f0101cb6 <mem_init+0x562>
f01019fc:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019ff:	0f 84 b1 02 00 00    	je     f0101cb6 <mem_init+0x562>
	assert(!page_alloc(0));
f0101a05:	83 ec 0c             	sub    $0xc,%esp
f0101a08:	6a 00                	push   $0x0
f0101a0a:	e8 7e f9 ff ff       	call   f010138d <page_alloc>
f0101a0f:	83 c4 10             	add    $0x10,%esp
f0101a12:	85 c0                	test   %eax,%eax
f0101a14:	0f 85 be 02 00 00    	jne    f0101cd8 <mem_init+0x584>
f0101a1a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a1d:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101a23:	89 f9                	mov    %edi,%ecx
f0101a25:	2b 08                	sub    (%eax),%ecx
f0101a27:	89 c8                	mov    %ecx,%eax
f0101a29:	c1 f8 03             	sar    $0x3,%eax
f0101a2c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101a2f:	89 c1                	mov    %eax,%ecx
f0101a31:	c1 e9 0c             	shr    $0xc,%ecx
f0101a34:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f0101a3a:	3b 0a                	cmp    (%edx),%ecx
f0101a3c:	0f 83 b8 02 00 00    	jae    f0101cfa <mem_init+0x5a6>
	memset(page2kva(pp0), 1, PGSIZE);
f0101a42:	83 ec 04             	sub    $0x4,%esp
f0101a45:	68 00 10 00 00       	push   $0x1000
f0101a4a:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101a4c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a51:	50                   	push   %eax
f0101a52:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a55:	e8 a8 26 00 00       	call   f0104102 <memset>
	page_free(pp0);
f0101a5a:	89 3c 24             	mov    %edi,(%esp)
f0101a5d:	e8 b3 f9 ff ff       	call   f0101415 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a62:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101a69:	e8 1f f9 ff ff       	call   f010138d <page_alloc>
f0101a6e:	83 c4 10             	add    $0x10,%esp
f0101a71:	85 c0                	test   %eax,%eax
f0101a73:	0f 84 97 02 00 00    	je     f0101d10 <mem_init+0x5bc>
	assert(pp && pp0 == pp);
f0101a79:	39 c7                	cmp    %eax,%edi
f0101a7b:	0f 85 b1 02 00 00    	jne    f0101d32 <mem_init+0x5de>
	return (pp - pages) << PGSHIFT;
f0101a81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a84:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101a8a:	89 fa                	mov    %edi,%edx
f0101a8c:	2b 10                	sub    (%eax),%edx
f0101a8e:	c1 fa 03             	sar    $0x3,%edx
f0101a91:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101a94:	89 d1                	mov    %edx,%ecx
f0101a96:	c1 e9 0c             	shr    $0xc,%ecx
f0101a99:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0101a9f:	3b 08                	cmp    (%eax),%ecx
f0101aa1:	0f 83 ad 02 00 00    	jae    f0101d54 <mem_init+0x600>
	return (void *)(pa + KERNBASE);
f0101aa7:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101aad:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101ab3:	80 38 00             	cmpb   $0x0,(%eax)
f0101ab6:	0f 85 ae 02 00 00    	jne    f0101d6a <mem_init+0x616>
f0101abc:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101abf:	39 d0                	cmp    %edx,%eax
f0101ac1:	75 f0                	jne    f0101ab3 <mem_init+0x35f>
	page_free_list = fl;
f0101ac3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ac6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101ac9:	89 8b b0 1f 00 00    	mov    %ecx,0x1fb0(%ebx)
	page_free(pp0);
f0101acf:	83 ec 0c             	sub    $0xc,%esp
f0101ad2:	57                   	push   %edi
f0101ad3:	e8 3d f9 ff ff       	call   f0101415 <page_free>
	page_free(pp1);
f0101ad8:	83 c4 04             	add    $0x4,%esp
f0101adb:	ff 75 d0             	pushl  -0x30(%ebp)
f0101ade:	e8 32 f9 ff ff       	call   f0101415 <page_free>
	page_free(pp2);
f0101ae3:	83 c4 04             	add    $0x4,%esp
f0101ae6:	ff 75 cc             	pushl  -0x34(%ebp)
f0101ae9:	e8 27 f9 ff ff       	call   f0101415 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101aee:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101af4:	83 c4 10             	add    $0x10,%esp
f0101af7:	e9 95 02 00 00       	jmp    f0101d91 <mem_init+0x63d>
	assert((pp0 = page_alloc(0)));
f0101afc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101aff:	8d 83 95 c9 fe ff    	lea    -0x1366b(%ebx),%eax
f0101b05:	50                   	push   %eax
f0101b06:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101b0c:	50                   	push   %eax
f0101b0d:	68 6b 02 00 00       	push   $0x26b
f0101b12:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101b18:	50                   	push   %eax
f0101b19:	e8 7b e5 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b1e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b21:	8d 83 ab c9 fe ff    	lea    -0x13655(%ebx),%eax
f0101b27:	50                   	push   %eax
f0101b28:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101b2e:	50                   	push   %eax
f0101b2f:	68 6c 02 00 00       	push   $0x26c
f0101b34:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101b3a:	50                   	push   %eax
f0101b3b:	e8 59 e5 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b40:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b43:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0101b49:	50                   	push   %eax
f0101b4a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101b50:	50                   	push   %eax
f0101b51:	68 6d 02 00 00       	push   $0x26d
f0101b56:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101b5c:	50                   	push   %eax
f0101b5d:	e8 37 e5 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101b62:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b65:	8d 83 d7 c9 fe ff    	lea    -0x13629(%ebx),%eax
f0101b6b:	50                   	push   %eax
f0101b6c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101b72:	50                   	push   %eax
f0101b73:	68 70 02 00 00       	push   $0x270
f0101b78:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101b7e:	50                   	push   %eax
f0101b7f:	e8 15 e5 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b84:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b87:	8d 83 c0 cd fe ff    	lea    -0x13240(%ebx),%eax
f0101b8d:	50                   	push   %eax
f0101b8e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101b94:	50                   	push   %eax
f0101b95:	68 71 02 00 00       	push   $0x271
f0101b9a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101ba0:	50                   	push   %eax
f0101ba1:	e8 f3 e4 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101ba6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ba9:	8d 83 e9 c9 fe ff    	lea    -0x13617(%ebx),%eax
f0101baf:	50                   	push   %eax
f0101bb0:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101bb6:	50                   	push   %eax
f0101bb7:	68 72 02 00 00       	push   $0x272
f0101bbc:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101bc2:	50                   	push   %eax
f0101bc3:	e8 d1 e4 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101bc8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bcb:	8d 83 06 ca fe ff    	lea    -0x135fa(%ebx),%eax
f0101bd1:	50                   	push   %eax
f0101bd2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101bd8:	50                   	push   %eax
f0101bd9:	68 73 02 00 00       	push   $0x273
f0101bde:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101be4:	50                   	push   %eax
f0101be5:	e8 af e4 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101bea:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bed:	8d 83 23 ca fe ff    	lea    -0x135dd(%ebx),%eax
f0101bf3:	50                   	push   %eax
f0101bf4:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101bfa:	50                   	push   %eax
f0101bfb:	68 74 02 00 00       	push   $0x274
f0101c00:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101c06:	50                   	push   %eax
f0101c07:	e8 8d e4 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101c0c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c0f:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f0101c15:	50                   	push   %eax
f0101c16:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101c1c:	50                   	push   %eax
f0101c1d:	68 7b 02 00 00       	push   $0x27b
f0101c22:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101c28:	50                   	push   %eax
f0101c29:	e8 6b e4 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101c2e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c31:	8d 83 95 c9 fe ff    	lea    -0x1366b(%ebx),%eax
f0101c37:	50                   	push   %eax
f0101c38:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101c3e:	50                   	push   %eax
f0101c3f:	68 82 02 00 00       	push   $0x282
f0101c44:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101c4a:	50                   	push   %eax
f0101c4b:	e8 49 e4 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c50:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c53:	8d 83 ab c9 fe ff    	lea    -0x13655(%ebx),%eax
f0101c59:	50                   	push   %eax
f0101c5a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101c60:	50                   	push   %eax
f0101c61:	68 83 02 00 00       	push   $0x283
f0101c66:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101c6c:	50                   	push   %eax
f0101c6d:	e8 27 e4 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c72:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c75:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f0101c7b:	50                   	push   %eax
f0101c7c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101c82:	50                   	push   %eax
f0101c83:	68 84 02 00 00       	push   $0x284
f0101c88:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101c8e:	50                   	push   %eax
f0101c8f:	e8 05 e4 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101c94:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c97:	8d 83 d7 c9 fe ff    	lea    -0x13629(%ebx),%eax
f0101c9d:	50                   	push   %eax
f0101c9e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101ca4:	50                   	push   %eax
f0101ca5:	68 86 02 00 00       	push   $0x286
f0101caa:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101cb0:	50                   	push   %eax
f0101cb1:	e8 e3 e3 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101cb6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cb9:	8d 83 c0 cd fe ff    	lea    -0x13240(%ebx),%eax
f0101cbf:	50                   	push   %eax
f0101cc0:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101cc6:	50                   	push   %eax
f0101cc7:	68 87 02 00 00       	push   $0x287
f0101ccc:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101cd2:	50                   	push   %eax
f0101cd3:	e8 c1 e3 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101cd8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cdb:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f0101ce1:	50                   	push   %eax
f0101ce2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101ce8:	50                   	push   %eax
f0101ce9:	68 88 02 00 00       	push   $0x288
f0101cee:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101cf4:	50                   	push   %eax
f0101cf5:	e8 9f e3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cfa:	50                   	push   %eax
f0101cfb:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0101d01:	50                   	push   %eax
f0101d02:	6a 52                	push   $0x52
f0101d04:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0101d0a:	50                   	push   %eax
f0101d0b:	e8 89 e3 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101d10:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d13:	8d 83 4f ca fe ff    	lea    -0x135b1(%ebx),%eax
f0101d19:	50                   	push   %eax
f0101d1a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101d20:	50                   	push   %eax
f0101d21:	68 8d 02 00 00       	push   $0x28d
f0101d26:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101d2c:	50                   	push   %eax
f0101d2d:	e8 67 e3 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101d32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d35:	8d 83 6d ca fe ff    	lea    -0x13593(%ebx),%eax
f0101d3b:	50                   	push   %eax
f0101d3c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101d42:	50                   	push   %eax
f0101d43:	68 8e 02 00 00       	push   $0x28e
f0101d48:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101d4e:	50                   	push   %eax
f0101d4f:	e8 45 e3 ff ff       	call   f0100099 <_panic>
f0101d54:	52                   	push   %edx
f0101d55:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0101d5b:	50                   	push   %eax
f0101d5c:	6a 52                	push   $0x52
f0101d5e:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0101d64:	50                   	push   %eax
f0101d65:	e8 2f e3 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101d6a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d6d:	8d 83 7d ca fe ff    	lea    -0x13583(%ebx),%eax
f0101d73:	50                   	push   %eax
f0101d74:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0101d7a:	50                   	push   %eax
f0101d7b:	68 91 02 00 00       	push   $0x291
f0101d80:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0101d86:	50                   	push   %eax
f0101d87:	e8 0d e3 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101d8c:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d8f:	8b 00                	mov    (%eax),%eax
f0101d91:	85 c0                	test   %eax,%eax
f0101d93:	75 f7                	jne    f0101d8c <mem_init+0x638>
	assert(nfree == 0);
f0101d95:	85 f6                	test   %esi,%esi
f0101d97:	0f 85 53 08 00 00    	jne    f01025f0 <mem_init+0xe9c>
	cprintf("check_page_alloc() succeeded!\n");
f0101d9d:	83 ec 0c             	sub    $0xc,%esp
f0101da0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101da3:	8d 83 e0 cd fe ff    	lea    -0x13220(%ebx),%eax
f0101da9:	50                   	push   %eax
f0101daa:	e8 42 17 00 00       	call   f01034f1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101daf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101db6:	e8 d2 f5 ff ff       	call   f010138d <page_alloc>
f0101dbb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101dbe:	83 c4 10             	add    $0x10,%esp
f0101dc1:	85 c0                	test   %eax,%eax
f0101dc3:	0f 84 49 08 00 00    	je     f0102612 <mem_init+0xebe>
	assert((pp1 = page_alloc(0)));
f0101dc9:	83 ec 0c             	sub    $0xc,%esp
f0101dcc:	6a 00                	push   $0x0
f0101dce:	e8 ba f5 ff ff       	call   f010138d <page_alloc>
f0101dd3:	89 c7                	mov    %eax,%edi
f0101dd5:	83 c4 10             	add    $0x10,%esp
f0101dd8:	85 c0                	test   %eax,%eax
f0101dda:	0f 84 54 08 00 00    	je     f0102634 <mem_init+0xee0>
	assert((pp2 = page_alloc(0)));
f0101de0:	83 ec 0c             	sub    $0xc,%esp
f0101de3:	6a 00                	push   $0x0
f0101de5:	e8 a3 f5 ff ff       	call   f010138d <page_alloc>
f0101dea:	89 c6                	mov    %eax,%esi
f0101dec:	83 c4 10             	add    $0x10,%esp
f0101def:	85 c0                	test   %eax,%eax
f0101df1:	0f 84 5f 08 00 00    	je     f0102656 <mem_init+0xf02>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101df7:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101dfa:	0f 84 78 08 00 00    	je     f0102678 <mem_init+0xf24>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101e00:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e03:	0f 84 91 08 00 00    	je     f010269a <mem_init+0xf46>
f0101e09:	39 c7                	cmp    %eax,%edi
f0101e0b:	0f 84 89 08 00 00    	je     f010269a <mem_init+0xf46>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101e11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e14:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0101e1a:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101e1d:	c7 80 b0 1f 00 00 00 	movl   $0x0,0x1fb0(%eax)
f0101e24:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101e27:	83 ec 0c             	sub    $0xc,%esp
f0101e2a:	6a 00                	push   $0x0
f0101e2c:	e8 5c f5 ff ff       	call   f010138d <page_alloc>
f0101e31:	83 c4 10             	add    $0x10,%esp
f0101e34:	85 c0                	test   %eax,%eax
f0101e36:	0f 85 80 08 00 00    	jne    f01026bc <mem_init+0xf68>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101e3c:	83 ec 04             	sub    $0x4,%esp
f0101e3f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101e42:	50                   	push   %eax
f0101e43:	6a 00                	push   $0x0
f0101e45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e48:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e4e:	ff 30                	pushl  (%eax)
f0101e50:	e8 be f7 ff ff       	call   f0101613 <page_lookup>
f0101e55:	83 c4 10             	add    $0x10,%esp
f0101e58:	85 c0                	test   %eax,%eax
f0101e5a:	0f 85 7e 08 00 00    	jne    f01026de <mem_init+0xf8a>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101e60:	6a 02                	push   $0x2
f0101e62:	6a 00                	push   $0x0
f0101e64:	57                   	push   %edi
f0101e65:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e68:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e6e:	ff 30                	pushl  (%eax)
f0101e70:	e8 59 f8 ff ff       	call   f01016ce <page_insert>
f0101e75:	83 c4 10             	add    $0x10,%esp
f0101e78:	85 c0                	test   %eax,%eax
f0101e7a:	0f 89 80 08 00 00    	jns    f0102700 <mem_init+0xfac>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e80:	83 ec 0c             	sub    $0xc,%esp
f0101e83:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e86:	e8 8a f5 ff ff       	call   f0101415 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e8b:	6a 02                	push   $0x2
f0101e8d:	6a 00                	push   $0x0
f0101e8f:	57                   	push   %edi
f0101e90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e93:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101e99:	ff 30                	pushl  (%eax)
f0101e9b:	e8 2e f8 ff ff       	call   f01016ce <page_insert>
f0101ea0:	83 c4 20             	add    $0x20,%esp
f0101ea3:	85 c0                	test   %eax,%eax
f0101ea5:	0f 85 77 08 00 00    	jne    f0102722 <mem_init+0xfce>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101eae:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101eb4:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101eb6:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0101ebc:	8b 08                	mov    (%eax),%ecx
f0101ebe:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101ec1:	8b 13                	mov    (%ebx),%edx
f0101ec3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ec9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ecc:	29 c8                	sub    %ecx,%eax
f0101ece:	c1 f8 03             	sar    $0x3,%eax
f0101ed1:	c1 e0 0c             	shl    $0xc,%eax
f0101ed4:	39 c2                	cmp    %eax,%edx
f0101ed6:	0f 85 68 08 00 00    	jne    f0102744 <mem_init+0xff0>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101edc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ee1:	89 d8                	mov    %ebx,%eax
f0101ee3:	e8 bb ef ff ff       	call   f0100ea3 <check_va2pa>
f0101ee8:	89 fa                	mov    %edi,%edx
f0101eea:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101eed:	c1 fa 03             	sar    $0x3,%edx
f0101ef0:	c1 e2 0c             	shl    $0xc,%edx
f0101ef3:	39 d0                	cmp    %edx,%eax
f0101ef5:	0f 85 6b 08 00 00    	jne    f0102766 <mem_init+0x1012>
	assert(pp1->pp_ref == 1);
f0101efb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f00:	0f 85 82 08 00 00    	jne    f0102788 <mem_init+0x1034>
	assert(pp0->pp_ref == 1);
f0101f06:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f09:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f0e:	0f 85 96 08 00 00    	jne    f01027aa <mem_init+0x1056>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f14:	6a 02                	push   $0x2
f0101f16:	68 00 10 00 00       	push   $0x1000
f0101f1b:	56                   	push   %esi
f0101f1c:	53                   	push   %ebx
f0101f1d:	e8 ac f7 ff ff       	call   f01016ce <page_insert>
f0101f22:	83 c4 10             	add    $0x10,%esp
f0101f25:	85 c0                	test   %eax,%eax
f0101f27:	0f 85 9f 08 00 00    	jne    f01027cc <mem_init+0x1078>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f2d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f32:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f35:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101f3b:	8b 00                	mov    (%eax),%eax
f0101f3d:	e8 61 ef ff ff       	call   f0100ea3 <check_va2pa>
f0101f42:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101f48:	89 f1                	mov    %esi,%ecx
f0101f4a:	2b 0a                	sub    (%edx),%ecx
f0101f4c:	89 ca                	mov    %ecx,%edx
f0101f4e:	c1 fa 03             	sar    $0x3,%edx
f0101f51:	c1 e2 0c             	shl    $0xc,%edx
f0101f54:	39 d0                	cmp    %edx,%eax
f0101f56:	0f 85 92 08 00 00    	jne    f01027ee <mem_init+0x109a>
	assert(pp2->pp_ref == 1);
f0101f5c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f61:	0f 85 a9 08 00 00    	jne    f0102810 <mem_init+0x10bc>

	// should be no free memory
	assert(!page_alloc(0));
f0101f67:	83 ec 0c             	sub    $0xc,%esp
f0101f6a:	6a 00                	push   $0x0
f0101f6c:	e8 1c f4 ff ff       	call   f010138d <page_alloc>
f0101f71:	83 c4 10             	add    $0x10,%esp
f0101f74:	85 c0                	test   %eax,%eax
f0101f76:	0f 85 b6 08 00 00    	jne    f0102832 <mem_init+0x10de>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f7c:	6a 02                	push   $0x2
f0101f7e:	68 00 10 00 00       	push   $0x1000
f0101f83:	56                   	push   %esi
f0101f84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f87:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101f8d:	ff 30                	pushl  (%eax)
f0101f8f:	e8 3a f7 ff ff       	call   f01016ce <page_insert>
f0101f94:	83 c4 10             	add    $0x10,%esp
f0101f97:	85 c0                	test   %eax,%eax
f0101f99:	0f 85 b5 08 00 00    	jne    f0102854 <mem_init+0x1100>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fa7:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101fad:	8b 00                	mov    (%eax),%eax
f0101faf:	e8 ef ee ff ff       	call   f0100ea3 <check_va2pa>
f0101fb4:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0101fba:	89 f1                	mov    %esi,%ecx
f0101fbc:	2b 0a                	sub    (%edx),%ecx
f0101fbe:	89 ca                	mov    %ecx,%edx
f0101fc0:	c1 fa 03             	sar    $0x3,%edx
f0101fc3:	c1 e2 0c             	shl    $0xc,%edx
f0101fc6:	39 d0                	cmp    %edx,%eax
f0101fc8:	0f 85 a8 08 00 00    	jne    f0102876 <mem_init+0x1122>
	assert(pp2->pp_ref == 1);
f0101fce:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fd3:	0f 85 bf 08 00 00    	jne    f0102898 <mem_init+0x1144>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fd9:	83 ec 0c             	sub    $0xc,%esp
f0101fdc:	6a 00                	push   $0x0
f0101fde:	e8 aa f3 ff ff       	call   f010138d <page_alloc>
f0101fe3:	83 c4 10             	add    $0x10,%esp
f0101fe6:	85 c0                	test   %eax,%eax
f0101fe8:	0f 85 cc 08 00 00    	jne    f01028ba <mem_init+0x1166>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101fee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ff1:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0101ff7:	8b 10                	mov    (%eax),%edx
f0101ff9:	8b 02                	mov    (%edx),%eax
f0101ffb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0102000:	89 c3                	mov    %eax,%ebx
f0102002:	c1 eb 0c             	shr    $0xc,%ebx
f0102005:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f010200b:	3b 19                	cmp    (%ecx),%ebx
f010200d:	0f 83 c9 08 00 00    	jae    f01028dc <mem_init+0x1188>
	return (void *)(pa + KERNBASE);
f0102013:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102018:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010201b:	83 ec 04             	sub    $0x4,%esp
f010201e:	6a 00                	push   $0x0
f0102020:	68 00 10 00 00       	push   $0x1000
f0102025:	52                   	push   %edx
f0102026:	e8 7d f4 ff ff       	call   f01014a8 <pgdir_walk>
f010202b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010202e:	8d 51 04             	lea    0x4(%ecx),%edx
f0102031:	83 c4 10             	add    $0x10,%esp
f0102034:	39 d0                	cmp    %edx,%eax
f0102036:	0f 85 bc 08 00 00    	jne    f01028f8 <mem_init+0x11a4>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010203c:	6a 06                	push   $0x6
f010203e:	68 00 10 00 00       	push   $0x1000
f0102043:	56                   	push   %esi
f0102044:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102047:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f010204d:	ff 30                	pushl  (%eax)
f010204f:	e8 7a f6 ff ff       	call   f01016ce <page_insert>
f0102054:	83 c4 10             	add    $0x10,%esp
f0102057:	85 c0                	test   %eax,%eax
f0102059:	0f 85 bb 08 00 00    	jne    f010291a <mem_init+0x11c6>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010205f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102062:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102068:	8b 18                	mov    (%eax),%ebx
f010206a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206f:	89 d8                	mov    %ebx,%eax
f0102071:	e8 2d ee ff ff       	call   f0100ea3 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0102076:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102079:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f010207f:	89 f1                	mov    %esi,%ecx
f0102081:	2b 0a                	sub    (%edx),%ecx
f0102083:	89 ca                	mov    %ecx,%edx
f0102085:	c1 fa 03             	sar    $0x3,%edx
f0102088:	c1 e2 0c             	shl    $0xc,%edx
f010208b:	39 d0                	cmp    %edx,%eax
f010208d:	0f 85 a9 08 00 00    	jne    f010293c <mem_init+0x11e8>
	assert(pp2->pp_ref == 1);
f0102093:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102098:	0f 85 c0 08 00 00    	jne    f010295e <mem_init+0x120a>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010209e:	83 ec 04             	sub    $0x4,%esp
f01020a1:	6a 00                	push   $0x0
f01020a3:	68 00 10 00 00       	push   $0x1000
f01020a8:	53                   	push   %ebx
f01020a9:	e8 fa f3 ff ff       	call   f01014a8 <pgdir_walk>
f01020ae:	83 c4 10             	add    $0x10,%esp
f01020b1:	f6 00 04             	testb  $0x4,(%eax)
f01020b4:	0f 84 c6 08 00 00    	je     f0102980 <mem_init+0x122c>
	assert(kern_pgdir[0] & PTE_U);
f01020ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020bd:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01020c3:	8b 00                	mov    (%eax),%eax
f01020c5:	f6 00 04             	testb  $0x4,(%eax)
f01020c8:	0f 84 d4 08 00 00    	je     f01029a2 <mem_init+0x124e>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020ce:	6a 02                	push   $0x2
f01020d0:	68 00 10 00 00       	push   $0x1000
f01020d5:	56                   	push   %esi
f01020d6:	50                   	push   %eax
f01020d7:	e8 f2 f5 ff ff       	call   f01016ce <page_insert>
f01020dc:	83 c4 10             	add    $0x10,%esp
f01020df:	85 c0                	test   %eax,%eax
f01020e1:	0f 85 dd 08 00 00    	jne    f01029c4 <mem_init+0x1270>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01020e7:	83 ec 04             	sub    $0x4,%esp
f01020ea:	6a 00                	push   $0x0
f01020ec:	68 00 10 00 00       	push   $0x1000
f01020f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020f4:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01020fa:	ff 30                	pushl  (%eax)
f01020fc:	e8 a7 f3 ff ff       	call   f01014a8 <pgdir_walk>
f0102101:	83 c4 10             	add    $0x10,%esp
f0102104:	f6 00 02             	testb  $0x2,(%eax)
f0102107:	0f 84 d9 08 00 00    	je     f01029e6 <mem_init+0x1292>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010210d:	83 ec 04             	sub    $0x4,%esp
f0102110:	6a 00                	push   $0x0
f0102112:	68 00 10 00 00       	push   $0x1000
f0102117:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211a:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102120:	ff 30                	pushl  (%eax)
f0102122:	e8 81 f3 ff ff       	call   f01014a8 <pgdir_walk>
f0102127:	83 c4 10             	add    $0x10,%esp
f010212a:	f6 00 04             	testb  $0x4,(%eax)
f010212d:	0f 85 d5 08 00 00    	jne    f0102a08 <mem_init+0x12b4>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102133:	6a 02                	push   $0x2
f0102135:	68 00 00 40 00       	push   $0x400000
f010213a:	ff 75 d0             	pushl  -0x30(%ebp)
f010213d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102140:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102146:	ff 30                	pushl  (%eax)
f0102148:	e8 81 f5 ff ff       	call   f01016ce <page_insert>
f010214d:	83 c4 10             	add    $0x10,%esp
f0102150:	85 c0                	test   %eax,%eax
f0102152:	0f 89 d2 08 00 00    	jns    f0102a2a <mem_init+0x12d6>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102158:	6a 02                	push   $0x2
f010215a:	68 00 10 00 00       	push   $0x1000
f010215f:	57                   	push   %edi
f0102160:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102163:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102169:	ff 30                	pushl  (%eax)
f010216b:	e8 5e f5 ff ff       	call   f01016ce <page_insert>
f0102170:	83 c4 10             	add    $0x10,%esp
f0102173:	85 c0                	test   %eax,%eax
f0102175:	0f 85 d1 08 00 00    	jne    f0102a4c <mem_init+0x12f8>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010217b:	83 ec 04             	sub    $0x4,%esp
f010217e:	6a 00                	push   $0x0
f0102180:	68 00 10 00 00       	push   $0x1000
f0102185:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102188:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f010218e:	ff 30                	pushl  (%eax)
f0102190:	e8 13 f3 ff ff       	call   f01014a8 <pgdir_walk>
f0102195:	83 c4 10             	add    $0x10,%esp
f0102198:	f6 00 04             	testb  $0x4,(%eax)
f010219b:	0f 85 cd 08 00 00    	jne    f0102a6e <mem_init+0x131a>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01021a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021a4:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01021aa:	8b 18                	mov    (%eax),%ebx
f01021ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01021b1:	89 d8                	mov    %ebx,%eax
f01021b3:	e8 eb ec ff ff       	call   f0100ea3 <check_va2pa>
f01021b8:	89 c2                	mov    %eax,%edx
f01021ba:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021bd:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021c0:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01021c6:	89 f9                	mov    %edi,%ecx
f01021c8:	2b 08                	sub    (%eax),%ecx
f01021ca:	89 c8                	mov    %ecx,%eax
f01021cc:	c1 f8 03             	sar    $0x3,%eax
f01021cf:	c1 e0 0c             	shl    $0xc,%eax
f01021d2:	39 c2                	cmp    %eax,%edx
f01021d4:	0f 85 b6 08 00 00    	jne    f0102a90 <mem_init+0x133c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021da:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021df:	89 d8                	mov    %ebx,%eax
f01021e1:	e8 bd ec ff ff       	call   f0100ea3 <check_va2pa>
f01021e6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01021e9:	0f 85 c3 08 00 00    	jne    f0102ab2 <mem_init+0x135e>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01021ef:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01021f4:	0f 85 da 08 00 00    	jne    f0102ad4 <mem_init+0x1380>
	assert(pp2->pp_ref == 0);
f01021fa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021ff:	0f 85 f1 08 00 00    	jne    f0102af6 <mem_init+0x13a2>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102205:	83 ec 0c             	sub    $0xc,%esp
f0102208:	6a 00                	push   $0x0
f010220a:	e8 7e f1 ff ff       	call   f010138d <page_alloc>
f010220f:	83 c4 10             	add    $0x10,%esp
f0102212:	39 c6                	cmp    %eax,%esi
f0102214:	0f 85 fe 08 00 00    	jne    f0102b18 <mem_init+0x13c4>
f010221a:	85 c0                	test   %eax,%eax
f010221c:	0f 84 f6 08 00 00    	je     f0102b18 <mem_init+0x13c4>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102222:	83 ec 08             	sub    $0x8,%esp
f0102225:	6a 00                	push   $0x0
f0102227:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010222a:	c7 c3 cc a6 11 f0    	mov    $0xf011a6cc,%ebx
f0102230:	ff 33                	pushl  (%ebx)
f0102232:	e8 58 f4 ff ff       	call   f010168f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102237:	8b 1b                	mov    (%ebx),%ebx
f0102239:	ba 00 00 00 00       	mov    $0x0,%edx
f010223e:	89 d8                	mov    %ebx,%eax
f0102240:	e8 5e ec ff ff       	call   f0100ea3 <check_va2pa>
f0102245:	83 c4 10             	add    $0x10,%esp
f0102248:	83 f8 ff             	cmp    $0xffffffff,%eax
f010224b:	0f 85 e9 08 00 00    	jne    f0102b3a <mem_init+0x13e6>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102251:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102256:	89 d8                	mov    %ebx,%eax
f0102258:	e8 46 ec ff ff       	call   f0100ea3 <check_va2pa>
f010225d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102260:	c7 c2 d0 a6 11 f0    	mov    $0xf011a6d0,%edx
f0102266:	89 f9                	mov    %edi,%ecx
f0102268:	2b 0a                	sub    (%edx),%ecx
f010226a:	89 ca                	mov    %ecx,%edx
f010226c:	c1 fa 03             	sar    $0x3,%edx
f010226f:	c1 e2 0c             	shl    $0xc,%edx
f0102272:	39 d0                	cmp    %edx,%eax
f0102274:	0f 85 e2 08 00 00    	jne    f0102b5c <mem_init+0x1408>
	assert(pp1->pp_ref == 1);
f010227a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010227f:	0f 85 f9 08 00 00    	jne    f0102b7e <mem_init+0x142a>
	assert(pp2->pp_ref == 0);
f0102285:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010228a:	0f 85 10 09 00 00    	jne    f0102ba0 <mem_init+0x144c>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102290:	6a 00                	push   $0x0
f0102292:	68 00 10 00 00       	push   $0x1000
f0102297:	57                   	push   %edi
f0102298:	53                   	push   %ebx
f0102299:	e8 30 f4 ff ff       	call   f01016ce <page_insert>
f010229e:	83 c4 10             	add    $0x10,%esp
f01022a1:	85 c0                	test   %eax,%eax
f01022a3:	0f 85 19 09 00 00    	jne    f0102bc2 <mem_init+0x146e>
	assert(pp1->pp_ref);
f01022a9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01022ae:	0f 84 30 09 00 00    	je     f0102be4 <mem_init+0x1490>
	assert(pp1->pp_link == NULL);
f01022b4:	83 3f 00             	cmpl   $0x0,(%edi)
f01022b7:	0f 85 49 09 00 00    	jne    f0102c06 <mem_init+0x14b2>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022bd:	83 ec 08             	sub    $0x8,%esp
f01022c0:	68 00 10 00 00       	push   $0x1000
f01022c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022c8:	c7 c3 cc a6 11 f0    	mov    $0xf011a6cc,%ebx
f01022ce:	ff 33                	pushl  (%ebx)
f01022d0:	e8 ba f3 ff ff       	call   f010168f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022d5:	8b 1b                	mov    (%ebx),%ebx
f01022d7:	ba 00 00 00 00       	mov    $0x0,%edx
f01022dc:	89 d8                	mov    %ebx,%eax
f01022de:	e8 c0 eb ff ff       	call   f0100ea3 <check_va2pa>
f01022e3:	83 c4 10             	add    $0x10,%esp
f01022e6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022e9:	0f 85 39 09 00 00    	jne    f0102c28 <mem_init+0x14d4>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022ef:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022f4:	89 d8                	mov    %ebx,%eax
f01022f6:	e8 a8 eb ff ff       	call   f0100ea3 <check_va2pa>
f01022fb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022fe:	0f 85 46 09 00 00    	jne    f0102c4a <mem_init+0x14f6>
	assert(pp1->pp_ref == 0);
f0102304:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102309:	0f 85 5d 09 00 00    	jne    f0102c6c <mem_init+0x1518>
	assert(pp2->pp_ref == 0);
f010230f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102314:	0f 85 74 09 00 00    	jne    f0102c8e <mem_init+0x153a>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010231a:	83 ec 0c             	sub    $0xc,%esp
f010231d:	6a 00                	push   $0x0
f010231f:	e8 69 f0 ff ff       	call   f010138d <page_alloc>
f0102324:	83 c4 10             	add    $0x10,%esp
f0102327:	39 c7                	cmp    %eax,%edi
f0102329:	0f 85 81 09 00 00    	jne    f0102cb0 <mem_init+0x155c>
f010232f:	85 c0                	test   %eax,%eax
f0102331:	0f 84 79 09 00 00    	je     f0102cb0 <mem_init+0x155c>

	// should be no free memory
	assert(!page_alloc(0));
f0102337:	83 ec 0c             	sub    $0xc,%esp
f010233a:	6a 00                	push   $0x0
f010233c:	e8 4c f0 ff ff       	call   f010138d <page_alloc>
f0102341:	83 c4 10             	add    $0x10,%esp
f0102344:	85 c0                	test   %eax,%eax
f0102346:	0f 85 86 09 00 00    	jne    f0102cd2 <mem_init+0x157e>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010234c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010234f:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102355:	8b 08                	mov    (%eax),%ecx
f0102357:	8b 11                	mov    (%ecx),%edx
f0102359:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010235f:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102365:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102368:	2b 18                	sub    (%eax),%ebx
f010236a:	89 d8                	mov    %ebx,%eax
f010236c:	c1 f8 03             	sar    $0x3,%eax
f010236f:	c1 e0 0c             	shl    $0xc,%eax
f0102372:	39 c2                	cmp    %eax,%edx
f0102374:	0f 85 7a 09 00 00    	jne    f0102cf4 <mem_init+0x15a0>
	kern_pgdir[0] = 0;
f010237a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102380:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102383:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102388:	0f 85 88 09 00 00    	jne    f0102d16 <mem_init+0x15c2>
	pp0->pp_ref = 0;
f010238e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102391:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102397:	83 ec 0c             	sub    $0xc,%esp
f010239a:	50                   	push   %eax
f010239b:	e8 75 f0 ff ff       	call   f0101415 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023a0:	83 c4 0c             	add    $0xc,%esp
f01023a3:	6a 01                	push   $0x1
f01023a5:	68 00 10 40 00       	push   $0x401000
f01023aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023ad:	c7 c3 cc a6 11 f0    	mov    $0xf011a6cc,%ebx
f01023b3:	ff 33                	pushl  (%ebx)
f01023b5:	e8 ee f0 ff ff       	call   f01014a8 <pgdir_walk>
f01023ba:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01023bd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023c0:	8b 1b                	mov    (%ebx),%ebx
f01023c2:	8b 53 04             	mov    0x4(%ebx),%edx
f01023c5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01023cb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01023ce:	c7 c1 c8 a6 11 f0    	mov    $0xf011a6c8,%ecx
f01023d4:	8b 09                	mov    (%ecx),%ecx
f01023d6:	89 d0                	mov    %edx,%eax
f01023d8:	c1 e8 0c             	shr    $0xc,%eax
f01023db:	83 c4 10             	add    $0x10,%esp
f01023de:	39 c8                	cmp    %ecx,%eax
f01023e0:	0f 83 52 09 00 00    	jae    f0102d38 <mem_init+0x15e4>
	assert(ptep == ptep1 + PTX(va));
f01023e6:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01023ec:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f01023ef:	0f 85 5f 09 00 00    	jne    f0102d54 <mem_init+0x1600>
	kern_pgdir[PDX(va)] = 0;
f01023f5:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f01023fc:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01023ff:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102405:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102408:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010240e:	2b 18                	sub    (%eax),%ebx
f0102410:	89 d8                	mov    %ebx,%eax
f0102412:	c1 f8 03             	sar    $0x3,%eax
f0102415:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102418:	89 c2                	mov    %eax,%edx
f010241a:	c1 ea 0c             	shr    $0xc,%edx
f010241d:	39 d1                	cmp    %edx,%ecx
f010241f:	0f 86 51 09 00 00    	jbe    f0102d76 <mem_init+0x1622>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102425:	83 ec 04             	sub    $0x4,%esp
f0102428:	68 00 10 00 00       	push   $0x1000
f010242d:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102432:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102437:	50                   	push   %eax
f0102438:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243b:	e8 c2 1c 00 00       	call   f0104102 <memset>
	page_free(pp0);
f0102440:	83 c4 04             	add    $0x4,%esp
f0102443:	ff 75 d0             	pushl  -0x30(%ebp)
f0102446:	e8 ca ef ff ff       	call   f0101415 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010244b:	83 c4 0c             	add    $0xc,%esp
f010244e:	6a 01                	push   $0x1
f0102450:	6a 00                	push   $0x0
f0102452:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102455:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f010245b:	ff 30                	pushl  (%eax)
f010245d:	e8 46 f0 ff ff       	call   f01014a8 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102462:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0102468:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010246b:	2b 10                	sub    (%eax),%edx
f010246d:	c1 fa 03             	sar    $0x3,%edx
f0102470:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102473:	89 d1                	mov    %edx,%ecx
f0102475:	c1 e9 0c             	shr    $0xc,%ecx
f0102478:	83 c4 10             	add    $0x10,%esp
f010247b:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f0102481:	3b 08                	cmp    (%eax),%ecx
f0102483:	0f 83 06 09 00 00    	jae    f0102d8f <mem_init+0x163b>
	return (void *)(pa + KERNBASE);
f0102489:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010248f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102492:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102498:	f6 00 01             	testb  $0x1,(%eax)
f010249b:	0f 85 07 09 00 00    	jne    f0102da8 <mem_init+0x1654>
f01024a1:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01024a4:	39 d0                	cmp    %edx,%eax
f01024a6:	75 f0                	jne    f0102498 <mem_init+0xd44>
	kern_pgdir[0] = 0;
f01024a8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ab:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01024b1:	8b 00                	mov    (%eax),%eax
f01024b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01024b9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024bc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01024c2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01024c5:	89 93 b0 1f 00 00    	mov    %edx,0x1fb0(%ebx)

	// free the pages we took
	page_free(pp0);
f01024cb:	83 ec 0c             	sub    $0xc,%esp
f01024ce:	50                   	push   %eax
f01024cf:	e8 41 ef ff ff       	call   f0101415 <page_free>
	page_free(pp1);
f01024d4:	89 3c 24             	mov    %edi,(%esp)
f01024d7:	e8 39 ef ff ff       	call   f0101415 <page_free>
	page_free(pp2);
f01024dc:	89 34 24             	mov    %esi,(%esp)
f01024df:	e8 31 ef ff ff       	call   f0101415 <page_free>

	cprintf("check_page() succeeded!\n");
f01024e4:	8d 83 5e cb fe ff    	lea    -0x134a2(%ebx),%eax
f01024ea:	89 04 24             	mov    %eax,(%esp)
f01024ed:	e8 ff 0f 00 00       	call   f01034f1 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, pagesize, PADDR(pages), PTE_P | PTE_U);
f01024f2:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01024f8:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01024fa:	83 c4 10             	add    $0x10,%esp
f01024fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102502:	0f 86 c2 08 00 00    	jbe    f0102dca <mem_init+0x1676>
f0102508:	83 ec 08             	sub    $0x8,%esp
f010250b:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010250d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102512:	50                   	push   %eax
f0102513:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102516:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010251b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010251e:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0102524:	8b 00                	mov    (%eax),%eax
f0102526:	e8 69 f0 ff ff       	call   f0101594 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f010252b:	c7 c0 00 f0 10 f0    	mov    $0xf010f000,%eax
f0102531:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102534:	83 c4 10             	add    $0x10,%esp
f0102537:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010253c:	0f 86 a4 08 00 00    	jbe    f0102de6 <mem_init+0x1692>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102542:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102545:	c7 c3 cc a6 11 f0    	mov    $0xf011a6cc,%ebx
f010254b:	83 ec 08             	sub    $0x8,%esp
f010254e:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f0102550:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102553:	05 00 00 00 10       	add    $0x10000000,%eax
f0102558:	50                   	push   %eax
f0102559:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010255e:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102563:	8b 03                	mov    (%ebx),%eax
f0102565:	e8 2a f0 ff ff       	call   f0101594 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010256a:	83 c4 08             	add    $0x8,%esp
f010256d:	6a 02                	push   $0x2
f010256f:	6a 00                	push   $0x0
f0102571:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102576:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010257b:	8b 03                	mov    (%ebx),%eax
f010257d:	e8 12 f0 ff ff       	call   f0101594 <boot_map_region>
	pgdir = kern_pgdir;
f0102582:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102584:	c7 c0 c8 a6 11 f0    	mov    $0xf011a6c8,%eax
f010258a:	8b 00                	mov    (%eax),%eax
f010258c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010258f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102596:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010259b:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010259e:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01025a4:	8b 00                	mov    (%eax),%eax
f01025a6:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01025a9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01025ac:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01025b2:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f01025b5:	bf 00 00 00 00       	mov    $0x0,%edi
f01025ba:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f01025bd:	0f 86 84 08 00 00    	jbe    f0102e47 <mem_init+0x16f3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01025c3:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f01025c9:	89 f0                	mov    %esi,%eax
f01025cb:	e8 d3 e8 ff ff       	call   f0100ea3 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01025d0:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01025d7:	0f 86 2a 08 00 00    	jbe    f0102e07 <mem_init+0x16b3>
f01025dd:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f01025e0:	39 c2                	cmp    %eax,%edx
f01025e2:	0f 85 3d 08 00 00    	jne    f0102e25 <mem_init+0x16d1>
	for (i = 0; i < n; i += PGSIZE)
f01025e8:	81 c7 00 10 00 00    	add    $0x1000,%edi
f01025ee:	eb ca                	jmp    f01025ba <mem_init+0xe66>
	assert(nfree == 0);
f01025f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f3:	8d 83 87 ca fe ff    	lea    -0x13579(%ebx),%eax
f01025f9:	50                   	push   %eax
f01025fa:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102600:	50                   	push   %eax
f0102601:	68 9e 02 00 00       	push   $0x29e
f0102606:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010260c:	50                   	push   %eax
f010260d:	e8 87 da ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102612:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102615:	8d 83 95 c9 fe ff    	lea    -0x1366b(%ebx),%eax
f010261b:	50                   	push   %eax
f010261c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102622:	50                   	push   %eax
f0102623:	68 f7 02 00 00       	push   $0x2f7
f0102628:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010262e:	50                   	push   %eax
f010262f:	e8 65 da ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102634:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102637:	8d 83 ab c9 fe ff    	lea    -0x13655(%ebx),%eax
f010263d:	50                   	push   %eax
f010263e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102644:	50                   	push   %eax
f0102645:	68 f8 02 00 00       	push   $0x2f8
f010264a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102650:	50                   	push   %eax
f0102651:	e8 43 da ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102656:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102659:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f010265f:	50                   	push   %eax
f0102660:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102666:	50                   	push   %eax
f0102667:	68 f9 02 00 00       	push   $0x2f9
f010266c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102672:	50                   	push   %eax
f0102673:	e8 21 da ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0102678:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010267b:	8d 83 d7 c9 fe ff    	lea    -0x13629(%ebx),%eax
f0102681:	50                   	push   %eax
f0102682:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102688:	50                   	push   %eax
f0102689:	68 fc 02 00 00       	push   $0x2fc
f010268e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102694:	50                   	push   %eax
f0102695:	e8 ff d9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010269a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269d:	8d 83 c0 cd fe ff    	lea    -0x13240(%ebx),%eax
f01026a3:	50                   	push   %eax
f01026a4:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01026aa:	50                   	push   %eax
f01026ab:	68 fd 02 00 00       	push   $0x2fd
f01026b0:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01026b6:	50                   	push   %eax
f01026b7:	e8 dd d9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01026bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026bf:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f01026c5:	50                   	push   %eax
f01026c6:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01026cc:	50                   	push   %eax
f01026cd:	68 04 03 00 00       	push   $0x304
f01026d2:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01026d8:	50                   	push   %eax
f01026d9:	e8 bb d9 ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01026de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e1:	8d 83 00 ce fe ff    	lea    -0x13200(%ebx),%eax
f01026e7:	50                   	push   %eax
f01026e8:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01026ee:	50                   	push   %eax
f01026ef:	68 07 03 00 00       	push   $0x307
f01026f4:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01026fa:	50                   	push   %eax
f01026fb:	e8 99 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102700:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102703:	8d 83 38 ce fe ff    	lea    -0x131c8(%ebx),%eax
f0102709:	50                   	push   %eax
f010270a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102710:	50                   	push   %eax
f0102711:	68 0a 03 00 00       	push   $0x30a
f0102716:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010271c:	50                   	push   %eax
f010271d:	e8 77 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102722:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102725:	8d 83 68 ce fe ff    	lea    -0x13198(%ebx),%eax
f010272b:	50                   	push   %eax
f010272c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102732:	50                   	push   %eax
f0102733:	68 0e 03 00 00       	push   $0x30e
f0102738:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010273e:	50                   	push   %eax
f010273f:	e8 55 d9 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102744:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102747:	8d 83 98 ce fe ff    	lea    -0x13168(%ebx),%eax
f010274d:	50                   	push   %eax
f010274e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102754:	50                   	push   %eax
f0102755:	68 0f 03 00 00       	push   $0x30f
f010275a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102760:	50                   	push   %eax
f0102761:	e8 33 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102766:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102769:	8d 83 c0 ce fe ff    	lea    -0x13140(%ebx),%eax
f010276f:	50                   	push   %eax
f0102770:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102776:	50                   	push   %eax
f0102777:	68 10 03 00 00       	push   $0x310
f010277c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102782:	50                   	push   %eax
f0102783:	e8 11 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102788:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010278b:	8d 83 92 ca fe ff    	lea    -0x1356e(%ebx),%eax
f0102791:	50                   	push   %eax
f0102792:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102798:	50                   	push   %eax
f0102799:	68 11 03 00 00       	push   $0x311
f010279e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01027a4:	50                   	push   %eax
f01027a5:	e8 ef d8 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01027aa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ad:	8d 83 a3 ca fe ff    	lea    -0x1355d(%ebx),%eax
f01027b3:	50                   	push   %eax
f01027b4:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01027ba:	50                   	push   %eax
f01027bb:	68 12 03 00 00       	push   $0x312
f01027c0:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01027c6:	50                   	push   %eax
f01027c7:	e8 cd d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01027cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027cf:	8d 83 f0 ce fe ff    	lea    -0x13110(%ebx),%eax
f01027d5:	50                   	push   %eax
f01027d6:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01027dc:	50                   	push   %eax
f01027dd:	68 15 03 00 00       	push   $0x315
f01027e2:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01027e8:	50                   	push   %eax
f01027e9:	e8 ab d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01027ee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f1:	8d 83 2c cf fe ff    	lea    -0x130d4(%ebx),%eax
f01027f7:	50                   	push   %eax
f01027f8:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01027fe:	50                   	push   %eax
f01027ff:	68 16 03 00 00       	push   $0x316
f0102804:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010280a:	50                   	push   %eax
f010280b:	e8 89 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102810:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102813:	8d 83 b4 ca fe ff    	lea    -0x1354c(%ebx),%eax
f0102819:	50                   	push   %eax
f010281a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102820:	50                   	push   %eax
f0102821:	68 17 03 00 00       	push   $0x317
f0102826:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010282c:	50                   	push   %eax
f010282d:	e8 67 d8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102832:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102835:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f010283b:	50                   	push   %eax
f010283c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102842:	50                   	push   %eax
f0102843:	68 1a 03 00 00       	push   $0x31a
f0102848:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010284e:	50                   	push   %eax
f010284f:	e8 45 d8 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102854:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102857:	8d 83 f0 ce fe ff    	lea    -0x13110(%ebx),%eax
f010285d:	50                   	push   %eax
f010285e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102864:	50                   	push   %eax
f0102865:	68 1d 03 00 00       	push   $0x31d
f010286a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102870:	50                   	push   %eax
f0102871:	e8 23 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102876:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102879:	8d 83 2c cf fe ff    	lea    -0x130d4(%ebx),%eax
f010287f:	50                   	push   %eax
f0102880:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102886:	50                   	push   %eax
f0102887:	68 1e 03 00 00       	push   $0x31e
f010288c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102892:	50                   	push   %eax
f0102893:	e8 01 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102898:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010289b:	8d 83 b4 ca fe ff    	lea    -0x1354c(%ebx),%eax
f01028a1:	50                   	push   %eax
f01028a2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01028a8:	50                   	push   %eax
f01028a9:	68 1f 03 00 00       	push   $0x31f
f01028ae:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01028b4:	50                   	push   %eax
f01028b5:	e8 df d7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01028ba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028bd:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f01028c3:	50                   	push   %eax
f01028c4:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01028ca:	50                   	push   %eax
f01028cb:	68 23 03 00 00       	push   $0x323
f01028d0:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01028d6:	50                   	push   %eax
f01028d7:	e8 bd d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028dc:	50                   	push   %eax
f01028dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e0:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f01028e6:	50                   	push   %eax
f01028e7:	68 26 03 00 00       	push   $0x326
f01028ec:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01028f2:	50                   	push   %eax
f01028f3:	e8 a1 d7 ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01028f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028fb:	8d 83 5c cf fe ff    	lea    -0x130a4(%ebx),%eax
f0102901:	50                   	push   %eax
f0102902:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102908:	50                   	push   %eax
f0102909:	68 27 03 00 00       	push   $0x327
f010290e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102914:	50                   	push   %eax
f0102915:	e8 7f d7 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010291a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010291d:	8d 83 9c cf fe ff    	lea    -0x13064(%ebx),%eax
f0102923:	50                   	push   %eax
f0102924:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010292a:	50                   	push   %eax
f010292b:	68 2a 03 00 00       	push   $0x32a
f0102930:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102936:	50                   	push   %eax
f0102937:	e8 5d d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010293c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010293f:	8d 83 2c cf fe ff    	lea    -0x130d4(%ebx),%eax
f0102945:	50                   	push   %eax
f0102946:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010294c:	50                   	push   %eax
f010294d:	68 2b 03 00 00       	push   $0x32b
f0102952:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102958:	50                   	push   %eax
f0102959:	e8 3b d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010295e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102961:	8d 83 b4 ca fe ff    	lea    -0x1354c(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010296e:	50                   	push   %eax
f010296f:	68 2c 03 00 00       	push   $0x32c
f0102974:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010297a:	50                   	push   %eax
f010297b:	e8 19 d7 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102980:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102983:	8d 83 dc cf fe ff    	lea    -0x13024(%ebx),%eax
f0102989:	50                   	push   %eax
f010298a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102990:	50                   	push   %eax
f0102991:	68 2d 03 00 00       	push   $0x32d
f0102996:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010299c:	50                   	push   %eax
f010299d:	e8 f7 d6 ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01029a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a5:	8d 83 c5 ca fe ff    	lea    -0x1353b(%ebx),%eax
f01029ab:	50                   	push   %eax
f01029ac:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01029b2:	50                   	push   %eax
f01029b3:	68 2e 03 00 00       	push   $0x32e
f01029b8:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01029be:	50                   	push   %eax
f01029bf:	e8 d5 d6 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01029c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029c7:	8d 83 f0 ce fe ff    	lea    -0x13110(%ebx),%eax
f01029cd:	50                   	push   %eax
f01029ce:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01029d4:	50                   	push   %eax
f01029d5:	68 31 03 00 00       	push   $0x331
f01029da:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01029e0:	50                   	push   %eax
f01029e1:	e8 b3 d6 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01029e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029e9:	8d 83 10 d0 fe ff    	lea    -0x12ff0(%ebx),%eax
f01029ef:	50                   	push   %eax
f01029f0:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01029f6:	50                   	push   %eax
f01029f7:	68 32 03 00 00       	push   $0x332
f01029fc:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102a02:	50                   	push   %eax
f0102a03:	e8 91 d6 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102a08:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0b:	8d 83 44 d0 fe ff    	lea    -0x12fbc(%ebx),%eax
f0102a11:	50                   	push   %eax
f0102a12:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102a18:	50                   	push   %eax
f0102a19:	68 33 03 00 00       	push   $0x333
f0102a1e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102a24:	50                   	push   %eax
f0102a25:	e8 6f d6 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102a2a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a2d:	8d 83 7c d0 fe ff    	lea    -0x12f84(%ebx),%eax
f0102a33:	50                   	push   %eax
f0102a34:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102a3a:	50                   	push   %eax
f0102a3b:	68 36 03 00 00       	push   $0x336
f0102a40:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102a46:	50                   	push   %eax
f0102a47:	e8 4d d6 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102a4c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a4f:	8d 83 b4 d0 fe ff    	lea    -0x12f4c(%ebx),%eax
f0102a55:	50                   	push   %eax
f0102a56:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102a5c:	50                   	push   %eax
f0102a5d:	68 39 03 00 00       	push   $0x339
f0102a62:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102a68:	50                   	push   %eax
f0102a69:	e8 2b d6 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102a6e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a71:	8d 83 44 d0 fe ff    	lea    -0x12fbc(%ebx),%eax
f0102a77:	50                   	push   %eax
f0102a78:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102a7e:	50                   	push   %eax
f0102a7f:	68 3a 03 00 00       	push   $0x33a
f0102a84:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102a8a:	50                   	push   %eax
f0102a8b:	e8 09 d6 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102a90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a93:	8d 83 f0 d0 fe ff    	lea    -0x12f10(%ebx),%eax
f0102a99:	50                   	push   %eax
f0102a9a:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102aa0:	50                   	push   %eax
f0102aa1:	68 3d 03 00 00       	push   $0x33d
f0102aa6:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102aac:	50                   	push   %eax
f0102aad:	e8 e7 d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102ab2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab5:	8d 83 1c d1 fe ff    	lea    -0x12ee4(%ebx),%eax
f0102abb:	50                   	push   %eax
f0102abc:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102ac2:	50                   	push   %eax
f0102ac3:	68 3e 03 00 00       	push   $0x33e
f0102ac8:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102ace:	50                   	push   %eax
f0102acf:	e8 c5 d5 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102ad4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ad7:	8d 83 db ca fe ff    	lea    -0x13525(%ebx),%eax
f0102add:	50                   	push   %eax
f0102ade:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102ae4:	50                   	push   %eax
f0102ae5:	68 40 03 00 00       	push   $0x340
f0102aea:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102af0:	50                   	push   %eax
f0102af1:	e8 a3 d5 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102af6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102af9:	8d 83 ec ca fe ff    	lea    -0x13514(%ebx),%eax
f0102aff:	50                   	push   %eax
f0102b00:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102b06:	50                   	push   %eax
f0102b07:	68 41 03 00 00       	push   $0x341
f0102b0c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102b12:	50                   	push   %eax
f0102b13:	e8 81 d5 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102b18:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1b:	8d 83 4c d1 fe ff    	lea    -0x12eb4(%ebx),%eax
f0102b21:	50                   	push   %eax
f0102b22:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102b28:	50                   	push   %eax
f0102b29:	68 44 03 00 00       	push   $0x344
f0102b2e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102b34:	50                   	push   %eax
f0102b35:	e8 5f d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102b3a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b3d:	8d 83 70 d1 fe ff    	lea    -0x12e90(%ebx),%eax
f0102b43:	50                   	push   %eax
f0102b44:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102b4a:	50                   	push   %eax
f0102b4b:	68 48 03 00 00       	push   $0x348
f0102b50:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102b56:	50                   	push   %eax
f0102b57:	e8 3d d5 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102b5c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b5f:	8d 83 1c d1 fe ff    	lea    -0x12ee4(%ebx),%eax
f0102b65:	50                   	push   %eax
f0102b66:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102b6c:	50                   	push   %eax
f0102b6d:	68 49 03 00 00       	push   $0x349
f0102b72:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102b78:	50                   	push   %eax
f0102b79:	e8 1b d5 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102b7e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b81:	8d 83 92 ca fe ff    	lea    -0x1356e(%ebx),%eax
f0102b87:	50                   	push   %eax
f0102b88:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102b8e:	50                   	push   %eax
f0102b8f:	68 4a 03 00 00       	push   $0x34a
f0102b94:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102b9a:	50                   	push   %eax
f0102b9b:	e8 f9 d4 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102ba0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ba3:	8d 83 ec ca fe ff    	lea    -0x13514(%ebx),%eax
f0102ba9:	50                   	push   %eax
f0102baa:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102bb0:	50                   	push   %eax
f0102bb1:	68 4b 03 00 00       	push   $0x34b
f0102bb6:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102bbc:	50                   	push   %eax
f0102bbd:	e8 d7 d4 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102bc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bc5:	8d 83 94 d1 fe ff    	lea    -0x12e6c(%ebx),%eax
f0102bcb:	50                   	push   %eax
f0102bcc:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102bd2:	50                   	push   %eax
f0102bd3:	68 4e 03 00 00       	push   $0x34e
f0102bd8:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102bde:	50                   	push   %eax
f0102bdf:	e8 b5 d4 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102be4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102be7:	8d 83 fd ca fe ff    	lea    -0x13503(%ebx),%eax
f0102bed:	50                   	push   %eax
f0102bee:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102bf4:	50                   	push   %eax
f0102bf5:	68 4f 03 00 00       	push   $0x34f
f0102bfa:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102c00:	50                   	push   %eax
f0102c01:	e8 93 d4 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102c06:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c09:	8d 83 09 cb fe ff    	lea    -0x134f7(%ebx),%eax
f0102c0f:	50                   	push   %eax
f0102c10:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102c16:	50                   	push   %eax
f0102c17:	68 50 03 00 00       	push   $0x350
f0102c1c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102c22:	50                   	push   %eax
f0102c23:	e8 71 d4 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102c28:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2b:	8d 83 70 d1 fe ff    	lea    -0x12e90(%ebx),%eax
f0102c31:	50                   	push   %eax
f0102c32:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102c38:	50                   	push   %eax
f0102c39:	68 54 03 00 00       	push   $0x354
f0102c3e:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102c44:	50                   	push   %eax
f0102c45:	e8 4f d4 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102c4a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c4d:	8d 83 cc d1 fe ff    	lea    -0x12e34(%ebx),%eax
f0102c53:	50                   	push   %eax
f0102c54:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102c5a:	50                   	push   %eax
f0102c5b:	68 55 03 00 00       	push   $0x355
f0102c60:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102c66:	50                   	push   %eax
f0102c67:	e8 2d d4 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102c6c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c6f:	8d 83 1e cb fe ff    	lea    -0x134e2(%ebx),%eax
f0102c75:	50                   	push   %eax
f0102c76:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102c7c:	50                   	push   %eax
f0102c7d:	68 56 03 00 00       	push   $0x356
f0102c82:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102c88:	50                   	push   %eax
f0102c89:	e8 0b d4 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102c8e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c91:	8d 83 ec ca fe ff    	lea    -0x13514(%ebx),%eax
f0102c97:	50                   	push   %eax
f0102c98:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102c9e:	50                   	push   %eax
f0102c9f:	68 57 03 00 00       	push   $0x357
f0102ca4:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102caa:	50                   	push   %eax
f0102cab:	e8 e9 d3 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102cb0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb3:	8d 83 f4 d1 fe ff    	lea    -0x12e0c(%ebx),%eax
f0102cb9:	50                   	push   %eax
f0102cba:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102cc0:	50                   	push   %eax
f0102cc1:	68 5a 03 00 00       	push   $0x35a
f0102cc6:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102ccc:	50                   	push   %eax
f0102ccd:	e8 c7 d3 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102cd2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cd5:	8d 83 40 ca fe ff    	lea    -0x135c0(%ebx),%eax
f0102cdb:	50                   	push   %eax
f0102cdc:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102ce2:	50                   	push   %eax
f0102ce3:	68 5d 03 00 00       	push   $0x35d
f0102ce8:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102cee:	50                   	push   %eax
f0102cef:	e8 a5 d3 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cf4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cf7:	8d 83 98 ce fe ff    	lea    -0x13168(%ebx),%eax
f0102cfd:	50                   	push   %eax
f0102cfe:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102d04:	50                   	push   %eax
f0102d05:	68 60 03 00 00       	push   $0x360
f0102d0a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102d10:	50                   	push   %eax
f0102d11:	e8 83 d3 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102d16:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d19:	8d 83 a3 ca fe ff    	lea    -0x1355d(%ebx),%eax
f0102d1f:	50                   	push   %eax
f0102d20:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102d26:	50                   	push   %eax
f0102d27:	68 62 03 00 00       	push   $0x362
f0102d2c:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102d32:	50                   	push   %eax
f0102d33:	e8 61 d3 ff ff       	call   f0100099 <_panic>
f0102d38:	52                   	push   %edx
f0102d39:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d3c:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0102d42:	50                   	push   %eax
f0102d43:	68 69 03 00 00       	push   $0x369
f0102d48:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102d4e:	50                   	push   %eax
f0102d4f:	e8 45 d3 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102d54:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d57:	8d 83 2f cb fe ff    	lea    -0x134d1(%ebx),%eax
f0102d5d:	50                   	push   %eax
f0102d5e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102d64:	50                   	push   %eax
f0102d65:	68 6a 03 00 00       	push   $0x36a
f0102d6a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102d70:	50                   	push   %eax
f0102d71:	e8 23 d3 ff ff       	call   f0100099 <_panic>
f0102d76:	50                   	push   %eax
f0102d77:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d7a:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0102d80:	50                   	push   %eax
f0102d81:	6a 52                	push   $0x52
f0102d83:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0102d89:	50                   	push   %eax
f0102d8a:	e8 0a d3 ff ff       	call   f0100099 <_panic>
f0102d8f:	52                   	push   %edx
f0102d90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d93:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f0102d99:	50                   	push   %eax
f0102d9a:	6a 52                	push   $0x52
f0102d9c:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0102da2:	50                   	push   %eax
f0102da3:	e8 f1 d2 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102da8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dab:	8d 83 47 cb fe ff    	lea    -0x134b9(%ebx),%eax
f0102db1:	50                   	push   %eax
f0102db2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102db8:	50                   	push   %eax
f0102db9:	68 74 03 00 00       	push   $0x374
f0102dbe:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102dc4:	50                   	push   %eax
f0102dc5:	e8 cf d2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dca:	50                   	push   %eax
f0102dcb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dce:	8d 83 9c cd fe ff    	lea    -0x13264(%ebx),%eax
f0102dd4:	50                   	push   %eax
f0102dd5:	68 bd 00 00 00       	push   $0xbd
f0102dda:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102de0:	50                   	push   %eax
f0102de1:	e8 b3 d2 ff ff       	call   f0100099 <_panic>
f0102de6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102de9:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102def:	8d 83 9c cd fe ff    	lea    -0x13264(%ebx),%eax
f0102df5:	50                   	push   %eax
f0102df6:	68 c9 00 00 00       	push   $0xc9
f0102dfb:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102e01:	50                   	push   %eax
f0102e02:	e8 92 d2 ff ff       	call   f0100099 <_panic>
f0102e07:	ff 75 c0             	pushl  -0x40(%ebp)
f0102e0a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e0d:	8d 83 9c cd fe ff    	lea    -0x13264(%ebx),%eax
f0102e13:	50                   	push   %eax
f0102e14:	68 b6 02 00 00       	push   $0x2b6
f0102e19:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102e1f:	50                   	push   %eax
f0102e20:	e8 74 d2 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e25:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e28:	8d 83 18 d2 fe ff    	lea    -0x12de8(%ebx),%eax
f0102e2e:	50                   	push   %eax
f0102e2f:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102e35:	50                   	push   %eax
f0102e36:	68 b6 02 00 00       	push   $0x2b6
f0102e3b:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102e41:	50                   	push   %eax
f0102e42:	e8 52 d2 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e47:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102e4a:	c1 e7 0c             	shl    $0xc,%edi
f0102e4d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e52:	eb 17                	jmp    f0102e6b <mem_init+0x1717>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102e54:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102e5a:	89 f0                	mov    %esi,%eax
f0102e5c:	e8 42 e0 ff ff       	call   f0100ea3 <check_va2pa>
f0102e61:	39 c3                	cmp    %eax,%ebx
f0102e63:	75 51                	jne    f0102eb6 <mem_init+0x1762>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e65:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e6b:	39 fb                	cmp    %edi,%ebx
f0102e6d:	72 e5                	jb     f0102e54 <mem_init+0x1700>
f0102e6f:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102e74:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102e77:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102e7d:	89 da                	mov    %ebx,%edx
f0102e7f:	89 f0                	mov    %esi,%eax
f0102e81:	e8 1d e0 ff ff       	call   f0100ea3 <check_va2pa>
f0102e86:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102e89:	39 c2                	cmp    %eax,%edx
f0102e8b:	75 4b                	jne    f0102ed8 <mem_init+0x1784>
f0102e8d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102e93:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102e99:	75 e2                	jne    f0102e7d <mem_init+0x1729>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102e9b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ea0:	89 f0                	mov    %esi,%eax
f0102ea2:	e8 fc df ff ff       	call   f0100ea3 <check_va2pa>
f0102ea7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102eaa:	75 4e                	jne    f0102efa <mem_init+0x17a6>
	for (i = 0; i < NPDENTRIES; i++) {
f0102eac:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eb1:	e9 8f 00 00 00       	jmp    f0102f45 <mem_init+0x17f1>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102eb6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eb9:	8d 83 4c d2 fe ff    	lea    -0x12db4(%ebx),%eax
f0102ebf:	50                   	push   %eax
f0102ec0:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102ec6:	50                   	push   %eax
f0102ec7:	68 bb 02 00 00       	push   $0x2bb
f0102ecc:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102ed2:	50                   	push   %eax
f0102ed3:	e8 c1 d1 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102ed8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102edb:	8d 83 74 d2 fe ff    	lea    -0x12d8c(%ebx),%eax
f0102ee1:	50                   	push   %eax
f0102ee2:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102ee8:	50                   	push   %eax
f0102ee9:	68 bf 02 00 00       	push   $0x2bf
f0102eee:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102ef4:	50                   	push   %eax
f0102ef5:	e8 9f d1 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102efa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102efd:	8d 83 bc d2 fe ff    	lea    -0x12d44(%ebx),%eax
f0102f03:	50                   	push   %eax
f0102f04:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102f0a:	50                   	push   %eax
f0102f0b:	68 c0 02 00 00       	push   $0x2c0
f0102f10:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102f16:	50                   	push   %eax
f0102f17:	e8 7d d1 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102f1c:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102f20:	74 52                	je     f0102f74 <mem_init+0x1820>
	for (i = 0; i < NPDENTRIES; i++) {
f0102f22:	83 c0 01             	add    $0x1,%eax
f0102f25:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102f2a:	0f 87 bb 00 00 00    	ja     f0102feb <mem_init+0x1897>
		switch (i) {
f0102f30:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102f35:	72 0e                	jb     f0102f45 <mem_init+0x17f1>
f0102f37:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102f3c:	76 de                	jbe    f0102f1c <mem_init+0x17c8>
f0102f3e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102f43:	74 d7                	je     f0102f1c <mem_init+0x17c8>
			if (i >= PDX(KERNBASE)) {
f0102f45:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102f4a:	77 4a                	ja     f0102f96 <mem_init+0x1842>
				assert(pgdir[i] == 0);
f0102f4c:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102f50:	74 d0                	je     f0102f22 <mem_init+0x17ce>
f0102f52:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f55:	8d 83 99 cb fe ff    	lea    -0x13467(%ebx),%eax
f0102f5b:	50                   	push   %eax
f0102f5c:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102f62:	50                   	push   %eax
f0102f63:	68 cf 02 00 00       	push   $0x2cf
f0102f68:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102f6e:	50                   	push   %eax
f0102f6f:	e8 25 d1 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102f74:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f77:	8d 83 77 cb fe ff    	lea    -0x13489(%ebx),%eax
f0102f7d:	50                   	push   %eax
f0102f7e:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102f84:	50                   	push   %eax
f0102f85:	68 c8 02 00 00       	push   $0x2c8
f0102f8a:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102f90:	50                   	push   %eax
f0102f91:	e8 03 d1 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102f96:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102f99:	f6 c2 01             	test   $0x1,%dl
f0102f9c:	74 2b                	je     f0102fc9 <mem_init+0x1875>
				assert(pgdir[i] & PTE_W);
f0102f9e:	f6 c2 02             	test   $0x2,%dl
f0102fa1:	0f 85 7b ff ff ff    	jne    f0102f22 <mem_init+0x17ce>
f0102fa7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102faa:	8d 83 88 cb fe ff    	lea    -0x13478(%ebx),%eax
f0102fb0:	50                   	push   %eax
f0102fb1:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102fb7:	50                   	push   %eax
f0102fb8:	68 cd 02 00 00       	push   $0x2cd
f0102fbd:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102fc3:	50                   	push   %eax
f0102fc4:	e8 d0 d0 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102fc9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fcc:	8d 83 77 cb fe ff    	lea    -0x13489(%ebx),%eax
f0102fd2:	50                   	push   %eax
f0102fd3:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0102fd9:	50                   	push   %eax
f0102fda:	68 cc 02 00 00       	push   $0x2cc
f0102fdf:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0102fe5:	50                   	push   %eax
f0102fe6:	e8 ae d0 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102feb:	83 ec 0c             	sub    $0xc,%esp
f0102fee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ff1:	8d 87 ec d2 fe ff    	lea    -0x12d14(%edi),%eax
f0102ff7:	50                   	push   %eax
f0102ff8:	89 fb                	mov    %edi,%ebx
f0102ffa:	e8 f2 04 00 00       	call   f01034f1 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102fff:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0103005:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103007:	83 c4 10             	add    $0x10,%esp
f010300a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010300f:	0f 86 44 02 00 00    	jbe    f0103259 <mem_init+0x1b05>
	return (physaddr_t)kva - KERNBASE;
f0103015:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010301a:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f010301d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103022:	e8 f9 de ff ff       	call   f0100f20 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0103027:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f010302a:	83 e0 f3             	and    $0xfffffff3,%eax
f010302d:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0103032:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103035:	83 ec 0c             	sub    $0xc,%esp
f0103038:	6a 00                	push   $0x0
f010303a:	e8 4e e3 ff ff       	call   f010138d <page_alloc>
f010303f:	89 c6                	mov    %eax,%esi
f0103041:	83 c4 10             	add    $0x10,%esp
f0103044:	85 c0                	test   %eax,%eax
f0103046:	0f 84 29 02 00 00    	je     f0103275 <mem_init+0x1b21>
	assert((pp1 = page_alloc(0)));
f010304c:	83 ec 0c             	sub    $0xc,%esp
f010304f:	6a 00                	push   $0x0
f0103051:	e8 37 e3 ff ff       	call   f010138d <page_alloc>
f0103056:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103059:	83 c4 10             	add    $0x10,%esp
f010305c:	85 c0                	test   %eax,%eax
f010305e:	0f 84 33 02 00 00    	je     f0103297 <mem_init+0x1b43>
	assert((pp2 = page_alloc(0)));
f0103064:	83 ec 0c             	sub    $0xc,%esp
f0103067:	6a 00                	push   $0x0
f0103069:	e8 1f e3 ff ff       	call   f010138d <page_alloc>
f010306e:	89 c7                	mov    %eax,%edi
f0103070:	83 c4 10             	add    $0x10,%esp
f0103073:	85 c0                	test   %eax,%eax
f0103075:	0f 84 3e 02 00 00    	je     f01032b9 <mem_init+0x1b65>
	page_free(pp0);
f010307b:	83 ec 0c             	sub    $0xc,%esp
f010307e:	56                   	push   %esi
f010307f:	e8 91 e3 ff ff       	call   f0101415 <page_free>
	return (pp - pages) << PGSHIFT;
f0103084:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103087:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010308d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103090:	2b 08                	sub    (%eax),%ecx
f0103092:	89 c8                	mov    %ecx,%eax
f0103094:	c1 f8 03             	sar    $0x3,%eax
f0103097:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010309a:	89 c1                	mov    %eax,%ecx
f010309c:	c1 e9 0c             	shr    $0xc,%ecx
f010309f:	83 c4 10             	add    $0x10,%esp
f01030a2:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01030a8:	3b 0a                	cmp    (%edx),%ecx
f01030aa:	0f 83 2b 02 00 00    	jae    f01032db <mem_init+0x1b87>
	memset(page2kva(pp1), 1, PGSIZE);
f01030b0:	83 ec 04             	sub    $0x4,%esp
f01030b3:	68 00 10 00 00       	push   $0x1000
f01030b8:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01030ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01030bf:	50                   	push   %eax
f01030c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030c3:	e8 3a 10 00 00       	call   f0104102 <memset>
	return (pp - pages) << PGSHIFT;
f01030c8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030cb:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f01030d1:	89 f9                	mov    %edi,%ecx
f01030d3:	2b 08                	sub    (%eax),%ecx
f01030d5:	89 c8                	mov    %ecx,%eax
f01030d7:	c1 f8 03             	sar    $0x3,%eax
f01030da:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01030dd:	89 c1                	mov    %eax,%ecx
f01030df:	c1 e9 0c             	shr    $0xc,%ecx
f01030e2:	83 c4 10             	add    $0x10,%esp
f01030e5:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01030eb:	3b 0a                	cmp    (%edx),%ecx
f01030ed:	0f 83 fe 01 00 00    	jae    f01032f1 <mem_init+0x1b9d>
	memset(page2kva(pp2), 2, PGSIZE);
f01030f3:	83 ec 04             	sub    $0x4,%esp
f01030f6:	68 00 10 00 00       	push   $0x1000
f01030fb:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f01030fd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103102:	50                   	push   %eax
f0103103:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103106:	e8 f7 0f 00 00       	call   f0104102 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010310b:	6a 02                	push   $0x2
f010310d:	68 00 10 00 00       	push   $0x1000
f0103112:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103115:	53                   	push   %ebx
f0103116:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103119:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f010311f:	ff 30                	pushl  (%eax)
f0103121:	e8 a8 e5 ff ff       	call   f01016ce <page_insert>
	assert(pp1->pp_ref == 1);
f0103126:	83 c4 20             	add    $0x20,%esp
f0103129:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010312e:	0f 85 d3 01 00 00    	jne    f0103307 <mem_init+0x1bb3>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103134:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010313b:	01 01 01 
f010313e:	0f 85 e5 01 00 00    	jne    f0103329 <mem_init+0x1bd5>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103144:	6a 02                	push   $0x2
f0103146:	68 00 10 00 00       	push   $0x1000
f010314b:	57                   	push   %edi
f010314c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010314f:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f0103155:	ff 30                	pushl  (%eax)
f0103157:	e8 72 e5 ff ff       	call   f01016ce <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010315c:	83 c4 10             	add    $0x10,%esp
f010315f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103166:	02 02 02 
f0103169:	0f 85 dc 01 00 00    	jne    f010334b <mem_init+0x1bf7>
	assert(pp2->pp_ref == 1);
f010316f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103174:	0f 85 f3 01 00 00    	jne    f010336d <mem_init+0x1c19>
	assert(pp1->pp_ref == 0);
f010317a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010317d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0103182:	0f 85 07 02 00 00    	jne    f010338f <mem_init+0x1c3b>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103188:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010318f:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0103192:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103195:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f010319b:	89 f9                	mov    %edi,%ecx
f010319d:	2b 08                	sub    (%eax),%ecx
f010319f:	89 c8                	mov    %ecx,%eax
f01031a1:	c1 f8 03             	sar    $0x3,%eax
f01031a4:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01031a7:	89 c1                	mov    %eax,%ecx
f01031a9:	c1 e9 0c             	shr    $0xc,%ecx
f01031ac:	c7 c2 c8 a6 11 f0    	mov    $0xf011a6c8,%edx
f01031b2:	3b 0a                	cmp    (%edx),%ecx
f01031b4:	0f 83 f7 01 00 00    	jae    f01033b1 <mem_init+0x1c5d>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01031ba:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01031c1:	03 03 03 
f01031c4:	0f 85 fd 01 00 00    	jne    f01033c7 <mem_init+0x1c73>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01031ca:	83 ec 08             	sub    $0x8,%esp
f01031cd:	68 00 10 00 00       	push   $0x1000
f01031d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031d5:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01031db:	ff 30                	pushl  (%eax)
f01031dd:	e8 ad e4 ff ff       	call   f010168f <page_remove>
	assert(pp2->pp_ref == 0);
f01031e2:	83 c4 10             	add    $0x10,%esp
f01031e5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01031ea:	0f 85 f9 01 00 00    	jne    f01033e9 <mem_init+0x1c95>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01031f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01031f3:	c7 c0 cc a6 11 f0    	mov    $0xf011a6cc,%eax
f01031f9:	8b 08                	mov    (%eax),%ecx
f01031fb:	8b 11                	mov    (%ecx),%edx
f01031fd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0103203:	c7 c0 d0 a6 11 f0    	mov    $0xf011a6d0,%eax
f0103209:	89 f7                	mov    %esi,%edi
f010320b:	2b 38                	sub    (%eax),%edi
f010320d:	89 f8                	mov    %edi,%eax
f010320f:	c1 f8 03             	sar    $0x3,%eax
f0103212:	c1 e0 0c             	shl    $0xc,%eax
f0103215:	39 c2                	cmp    %eax,%edx
f0103217:	0f 85 ee 01 00 00    	jne    f010340b <mem_init+0x1cb7>
	kern_pgdir[0] = 0;
f010321d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0103223:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103228:	0f 85 ff 01 00 00    	jne    f010342d <mem_init+0x1cd9>
	pp0->pp_ref = 0;
f010322e:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0103234:	83 ec 0c             	sub    $0xc,%esp
f0103237:	56                   	push   %esi
f0103238:	e8 d8 e1 ff ff       	call   f0101415 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010323d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103240:	8d 83 80 d3 fe ff    	lea    -0x12c80(%ebx),%eax
f0103246:	89 04 24             	mov    %eax,(%esp)
f0103249:	e8 a3 02 00 00       	call   f01034f1 <cprintf>
}
f010324e:	83 c4 10             	add    $0x10,%esp
f0103251:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103254:	5b                   	pop    %ebx
f0103255:	5e                   	pop    %esi
f0103256:	5f                   	pop    %edi
f0103257:	5d                   	pop    %ebp
f0103258:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103259:	50                   	push   %eax
f010325a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010325d:	8d 83 9c cd fe ff    	lea    -0x13264(%ebx),%eax
f0103263:	50                   	push   %eax
f0103264:	68 de 00 00 00       	push   $0xde
f0103269:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f010326f:	50                   	push   %eax
f0103270:	e8 24 ce ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0103275:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103278:	8d 83 95 c9 fe ff    	lea    -0x1366b(%ebx),%eax
f010327e:	50                   	push   %eax
f010327f:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0103285:	50                   	push   %eax
f0103286:	68 8f 03 00 00       	push   $0x38f
f010328b:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103291:	50                   	push   %eax
f0103292:	e8 02 ce ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0103297:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010329a:	8d 83 ab c9 fe ff    	lea    -0x13655(%ebx),%eax
f01032a0:	50                   	push   %eax
f01032a1:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01032a7:	50                   	push   %eax
f01032a8:	68 90 03 00 00       	push   $0x390
f01032ad:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01032b3:	50                   	push   %eax
f01032b4:	e8 e0 cd ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01032b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032bc:	8d 83 c1 c9 fe ff    	lea    -0x1363f(%ebx),%eax
f01032c2:	50                   	push   %eax
f01032c3:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01032c9:	50                   	push   %eax
f01032ca:	68 91 03 00 00       	push   $0x391
f01032cf:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01032d5:	50                   	push   %eax
f01032d6:	e8 be cd ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032db:	50                   	push   %eax
f01032dc:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f01032e2:	50                   	push   %eax
f01032e3:	6a 52                	push   $0x52
f01032e5:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f01032eb:	50                   	push   %eax
f01032ec:	e8 a8 cd ff ff       	call   f0100099 <_panic>
f01032f1:	50                   	push   %eax
f01032f2:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f01032f8:	50                   	push   %eax
f01032f9:	6a 52                	push   $0x52
f01032fb:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0103301:	50                   	push   %eax
f0103302:	e8 92 cd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0103307:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010330a:	8d 83 92 ca fe ff    	lea    -0x1356e(%ebx),%eax
f0103310:	50                   	push   %eax
f0103311:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0103317:	50                   	push   %eax
f0103318:	68 96 03 00 00       	push   $0x396
f010331d:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103323:	50                   	push   %eax
f0103324:	e8 70 cd ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103329:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010332c:	8d 83 0c d3 fe ff    	lea    -0x12cf4(%ebx),%eax
f0103332:	50                   	push   %eax
f0103333:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f0103339:	50                   	push   %eax
f010333a:	68 97 03 00 00       	push   $0x397
f010333f:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103345:	50                   	push   %eax
f0103346:	e8 4e cd ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010334b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010334e:	8d 83 30 d3 fe ff    	lea    -0x12cd0(%ebx),%eax
f0103354:	50                   	push   %eax
f0103355:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010335b:	50                   	push   %eax
f010335c:	68 99 03 00 00       	push   $0x399
f0103361:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103367:	50                   	push   %eax
f0103368:	e8 2c cd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010336d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103370:	8d 83 b4 ca fe ff    	lea    -0x1354c(%ebx),%eax
f0103376:	50                   	push   %eax
f0103377:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010337d:	50                   	push   %eax
f010337e:	68 9a 03 00 00       	push   $0x39a
f0103383:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103389:	50                   	push   %eax
f010338a:	e8 0a cd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010338f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103392:	8d 83 1e cb fe ff    	lea    -0x134e2(%ebx),%eax
f0103398:	50                   	push   %eax
f0103399:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010339f:	50                   	push   %eax
f01033a0:	68 9b 03 00 00       	push   $0x39b
f01033a5:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01033ab:	50                   	push   %eax
f01033ac:	e8 e8 cc ff ff       	call   f0100099 <_panic>
f01033b1:	50                   	push   %eax
f01033b2:	8d 83 a8 cb fe ff    	lea    -0x13458(%ebx),%eax
f01033b8:	50                   	push   %eax
f01033b9:	6a 52                	push   $0x52
f01033bb:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f01033c1:	50                   	push   %eax
f01033c2:	e8 d2 cc ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033ca:	8d 83 54 d3 fe ff    	lea    -0x12cac(%ebx),%eax
f01033d0:	50                   	push   %eax
f01033d1:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01033d7:	50                   	push   %eax
f01033d8:	68 9d 03 00 00       	push   $0x39d
f01033dd:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f01033e3:	50                   	push   %eax
f01033e4:	e8 b0 cc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01033e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033ec:	8d 83 ec ca fe ff    	lea    -0x13514(%ebx),%eax
f01033f2:	50                   	push   %eax
f01033f3:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f01033f9:	50                   	push   %eax
f01033fa:	68 9f 03 00 00       	push   $0x39f
f01033ff:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103405:	50                   	push   %eax
f0103406:	e8 8e cc ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010340b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010340e:	8d 83 98 ce fe ff    	lea    -0x13168(%ebx),%eax
f0103414:	50                   	push   %eax
f0103415:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010341b:	50                   	push   %eax
f010341c:	68 a2 03 00 00       	push   $0x3a2
f0103421:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103427:	50                   	push   %eax
f0103428:	e8 6c cc ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010342d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103430:	8d 83 a3 ca fe ff    	lea    -0x1355d(%ebx),%eax
f0103436:	50                   	push   %eax
f0103437:	8d 83 ea c8 fe ff    	lea    -0x13716(%ebx),%eax
f010343d:	50                   	push   %eax
f010343e:	68 a4 03 00 00       	push   $0x3a4
f0103443:	8d 83 c4 c8 fe ff    	lea    -0x1373c(%ebx),%eax
f0103449:	50                   	push   %eax
f010344a:	e8 4a cc ff ff       	call   f0100099 <_panic>

f010344f <tlb_invalidate>:
{
f010344f:	55                   	push   %ebp
f0103450:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103452:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103455:	0f 01 38             	invlpg (%eax)
}
f0103458:	5d                   	pop    %ebp
f0103459:	c3                   	ret    

f010345a <__x86.get_pc_thunk.dx>:
f010345a:	8b 14 24             	mov    (%esp),%edx
f010345d:	c3                   	ret    

f010345e <__x86.get_pc_thunk.cx>:
f010345e:	8b 0c 24             	mov    (%esp),%ecx
f0103461:	c3                   	ret    

f0103462 <__x86.get_pc_thunk.si>:
f0103462:	8b 34 24             	mov    (%esp),%esi
f0103465:	c3                   	ret    

f0103466 <__x86.get_pc_thunk.di>:
f0103466:	8b 3c 24             	mov    (%esp),%edi
f0103469:	c3                   	ret    

f010346a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010346a:	55                   	push   %ebp
f010346b:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010346d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103470:	ba 70 00 00 00       	mov    $0x70,%edx
f0103475:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103476:	ba 71 00 00 00       	mov    $0x71,%edx
f010347b:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010347c:	0f b6 c0             	movzbl %al,%eax
}
f010347f:	5d                   	pop    %ebp
f0103480:	c3                   	ret    

f0103481 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103481:	55                   	push   %ebp
f0103482:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103484:	8b 45 08             	mov    0x8(%ebp),%eax
f0103487:	ba 70 00 00 00       	mov    $0x70,%edx
f010348c:	ee                   	out    %al,(%dx)
f010348d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103490:	ba 71 00 00 00       	mov    $0x71,%edx
f0103495:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103496:	5d                   	pop    %ebp
f0103497:	c3                   	ret    

f0103498 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103498:	55                   	push   %ebp
f0103499:	89 e5                	mov    %esp,%ebp
f010349b:	53                   	push   %ebx
f010349c:	83 ec 10             	sub    $0x10,%esp
f010349f:	e8 ab cc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01034a4:	81 c3 68 4e 01 00    	add    $0x14e68,%ebx
	cputchar(ch);
f01034aa:	ff 75 08             	pushl  0x8(%ebp)
f01034ad:	e8 14 d2 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f01034b2:	83 c4 10             	add    $0x10,%esp
f01034b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034b8:	c9                   	leave  
f01034b9:	c3                   	ret    

f01034ba <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01034ba:	55                   	push   %ebp
f01034bb:	89 e5                	mov    %esp,%ebp
f01034bd:	53                   	push   %ebx
f01034be:	83 ec 14             	sub    $0x14,%esp
f01034c1:	e8 89 cc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01034c6:	81 c3 46 4e 01 00    	add    $0x14e46,%ebx
	int cnt = 0;
f01034cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01034d3:	ff 75 0c             	pushl  0xc(%ebp)
f01034d6:	ff 75 08             	pushl  0x8(%ebp)
f01034d9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01034dc:	50                   	push   %eax
f01034dd:	8d 83 8c b1 fe ff    	lea    -0x14e74(%ebx),%eax
f01034e3:	50                   	push   %eax
f01034e4:	e8 98 04 00 00       	call   f0103981 <vprintfmt>
	return cnt;
}
f01034e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034ef:	c9                   	leave  
f01034f0:	c3                   	ret    

f01034f1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01034f1:	55                   	push   %ebp
f01034f2:	89 e5                	mov    %esp,%ebp
f01034f4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01034f7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01034fa:	50                   	push   %eax
f01034fb:	ff 75 08             	pushl  0x8(%ebp)
f01034fe:	e8 b7 ff ff ff       	call   f01034ba <vcprintf>
	va_end(ap);

	return cnt;
}
f0103503:	c9                   	leave  
f0103504:	c3                   	ret    

f0103505 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103505:	55                   	push   %ebp
f0103506:	89 e5                	mov    %esp,%ebp
f0103508:	57                   	push   %edi
f0103509:	56                   	push   %esi
f010350a:	53                   	push   %ebx
f010350b:	83 ec 14             	sub    $0x14,%esp
f010350e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103511:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103514:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103517:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010351a:	8b 32                	mov    (%edx),%esi
f010351c:	8b 01                	mov    (%ecx),%eax
f010351e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103521:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103528:	eb 2f                	jmp    f0103559 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f010352a:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f010352d:	39 c6                	cmp    %eax,%esi
f010352f:	7f 49                	jg     f010357a <stab_binsearch+0x75>
f0103531:	0f b6 0a             	movzbl (%edx),%ecx
f0103534:	83 ea 0c             	sub    $0xc,%edx
f0103537:	39 f9                	cmp    %edi,%ecx
f0103539:	75 ef                	jne    f010352a <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010353b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010353e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103541:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103545:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103548:	73 35                	jae    f010357f <stab_binsearch+0x7a>
			*region_left = m;
f010354a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010354d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010354f:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0103552:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0103559:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f010355c:	7f 4e                	jg     f01035ac <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f010355e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103561:	01 f0                	add    %esi,%eax
f0103563:	89 c3                	mov    %eax,%ebx
f0103565:	c1 eb 1f             	shr    $0x1f,%ebx
f0103568:	01 c3                	add    %eax,%ebx
f010356a:	d1 fb                	sar    %ebx
f010356c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010356f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103572:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103576:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0103578:	eb b3                	jmp    f010352d <stab_binsearch+0x28>
			l = true_m + 1;
f010357a:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f010357d:	eb da                	jmp    f0103559 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010357f:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103582:	76 14                	jbe    f0103598 <stab_binsearch+0x93>
			*region_right = m - 1;
f0103584:	83 e8 01             	sub    $0x1,%eax
f0103587:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010358a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010358d:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010358f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103596:	eb c1                	jmp    f0103559 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103598:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010359b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010359d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01035a1:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01035a3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01035aa:	eb ad                	jmp    f0103559 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01035ac:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01035b0:	74 16                	je     f01035c8 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01035b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035b5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01035b7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01035ba:	8b 0e                	mov    (%esi),%ecx
f01035bc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01035bf:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01035c2:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01035c6:	eb 12                	jmp    f01035da <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01035c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035cb:	8b 00                	mov    (%eax),%eax
f01035cd:	83 e8 01             	sub    $0x1,%eax
f01035d0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01035d3:	89 07                	mov    %eax,(%edi)
f01035d5:	eb 16                	jmp    f01035ed <stab_binsearch+0xe8>
		     l--)
f01035d7:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01035da:	39 c1                	cmp    %eax,%ecx
f01035dc:	7d 0a                	jge    f01035e8 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01035de:	0f b6 1a             	movzbl (%edx),%ebx
f01035e1:	83 ea 0c             	sub    $0xc,%edx
f01035e4:	39 fb                	cmp    %edi,%ebx
f01035e6:	75 ef                	jne    f01035d7 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01035e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035eb:	89 07                	mov    %eax,(%edi)
	}
}
f01035ed:	83 c4 14             	add    $0x14,%esp
f01035f0:	5b                   	pop    %ebx
f01035f1:	5e                   	pop    %esi
f01035f2:	5f                   	pop    %edi
f01035f3:	5d                   	pop    %ebp
f01035f4:	c3                   	ret    

f01035f5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01035f5:	55                   	push   %ebp
f01035f6:	89 e5                	mov    %esp,%ebp
f01035f8:	57                   	push   %edi
f01035f9:	56                   	push   %esi
f01035fa:	53                   	push   %ebx
f01035fb:	83 ec 3c             	sub    $0x3c,%esp
f01035fe:	e8 4c cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103603:	81 c3 09 4d 01 00    	add    $0x14d09,%ebx
f0103609:	8b 7d 08             	mov    0x8(%ebp),%edi
f010360c:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010360f:	8d 83 ac d3 fe ff    	lea    -0x12c54(%ebx),%eax
f0103615:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103617:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010361e:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103621:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103628:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010362b:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103632:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103638:	0f 86 37 01 00 00    	jbe    f0103775 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010363e:	c7 c0 39 c6 10 f0    	mov    $0xf010c639,%eax
f0103644:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f010364a:	0f 86 04 02 00 00    	jbe    f0103854 <debuginfo_eip+0x25f>
f0103650:	c7 c0 35 e5 10 f0    	mov    $0xf010e535,%eax
f0103656:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010365a:	0f 85 fb 01 00 00    	jne    f010385b <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103660:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103667:	c7 c0 d0 58 10 f0    	mov    $0xf01058d0,%eax
f010366d:	c7 c2 38 c6 10 f0    	mov    $0xf010c638,%edx
f0103673:	29 c2                	sub    %eax,%edx
f0103675:	c1 fa 02             	sar    $0x2,%edx
f0103678:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010367e:	83 ea 01             	sub    $0x1,%edx
f0103681:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103684:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103687:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010368a:	83 ec 08             	sub    $0x8,%esp
f010368d:	57                   	push   %edi
f010368e:	6a 64                	push   $0x64
f0103690:	e8 70 fe ff ff       	call   f0103505 <stab_binsearch>
	if (lfile == 0)
f0103695:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103698:	83 c4 10             	add    $0x10,%esp
f010369b:	85 c0                	test   %eax,%eax
f010369d:	0f 84 bf 01 00 00    	je     f0103862 <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01036a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01036a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01036a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01036ac:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01036af:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01036b2:	83 ec 08             	sub    $0x8,%esp
f01036b5:	57                   	push   %edi
f01036b6:	6a 24                	push   $0x24
f01036b8:	c7 c0 d0 58 10 f0    	mov    $0xf01058d0,%eax
f01036be:	e8 42 fe ff ff       	call   f0103505 <stab_binsearch>

	if (lfun <= rfun) {
f01036c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01036c6:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01036c9:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01036cc:	83 c4 10             	add    $0x10,%esp
f01036cf:	39 c8                	cmp    %ecx,%eax
f01036d1:	0f 8f b6 00 00 00    	jg     f010378d <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01036d7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01036da:	c7 c1 d0 58 10 f0    	mov    $0xf01058d0,%ecx
f01036e0:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01036e3:	8b 11                	mov    (%ecx),%edx
f01036e5:	89 55 c0             	mov    %edx,-0x40(%ebp)
f01036e8:	c7 c2 35 e5 10 f0    	mov    $0xf010e535,%edx
f01036ee:	81 ea 39 c6 10 f0    	sub    $0xf010c639,%edx
f01036f4:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f01036f7:	73 0c                	jae    f0103705 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01036f9:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01036fc:	81 c2 39 c6 10 f0    	add    $0xf010c639,%edx
f0103702:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103705:	8b 51 08             	mov    0x8(%ecx),%edx
f0103708:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f010370b:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f010370d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103710:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103713:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103716:	83 ec 08             	sub    $0x8,%esp
f0103719:	6a 3a                	push   $0x3a
f010371b:	ff 76 08             	pushl  0x8(%esi)
f010371e:	e8 c3 09 00 00       	call   f01040e6 <strfind>
f0103723:	2b 46 08             	sub    0x8(%esi),%eax
f0103726:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular c
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103729:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010372c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010372f:	83 c4 08             	add    $0x8,%esp
f0103732:	57                   	push   %edi
f0103733:	6a 44                	push   $0x44
f0103735:	c7 c0 d0 58 10 f0    	mov    $0xf01058d0,%eax
f010373b:	e8 c5 fd ff ff       	call   f0103505 <stab_binsearch>
	if (lline <= rline)
f0103740:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103743:	83 c4 10             	add    $0x10,%esp
f0103746:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103749:	0f 8f 1a 01 00 00    	jg     f0103869 <debuginfo_eip+0x274>
		info->eip_line = stabs[lline].n_desc;
f010374f:	89 d0                	mov    %edx,%eax
f0103751:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103754:	c1 e2 02             	shl    $0x2,%edx
f0103757:	c7 c1 d0 58 10 f0    	mov    $0xf01058d0,%ecx
f010375d:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0103762:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103765:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103768:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f010376c:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103770:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103773:	eb 36                	jmp    f01037ab <debuginfo_eip+0x1b6>
  	        panic("User address");
f0103775:	83 ec 04             	sub    $0x4,%esp
f0103778:	8d 83 b6 d3 fe ff    	lea    -0x12c4a(%ebx),%eax
f010377e:	50                   	push   %eax
f010377f:	6a 7f                	push   $0x7f
f0103781:	8d 83 c3 d3 fe ff    	lea    -0x12c3d(%ebx),%eax
f0103787:	50                   	push   %eax
f0103788:	e8 0c c9 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f010378d:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103790:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103793:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103796:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103799:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010379c:	e9 75 ff ff ff       	jmp    f0103716 <debuginfo_eip+0x121>
f01037a1:	83 e8 01             	sub    $0x1,%eax
f01037a4:	83 ea 0c             	sub    $0xc,%edx
f01037a7:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01037ab:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01037ae:	39 c7                	cmp    %eax,%edi
f01037b0:	7f 24                	jg     f01037d6 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f01037b2:	0f b6 0a             	movzbl (%edx),%ecx
f01037b5:	80 f9 84             	cmp    $0x84,%cl
f01037b8:	74 46                	je     f0103800 <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01037ba:	80 f9 64             	cmp    $0x64,%cl
f01037bd:	75 e2                	jne    f01037a1 <debuginfo_eip+0x1ac>
f01037bf:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01037c3:	74 dc                	je     f01037a1 <debuginfo_eip+0x1ac>
f01037c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037c8:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01037cc:	74 3b                	je     f0103809 <debuginfo_eip+0x214>
f01037ce:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01037d1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01037d4:	eb 33                	jmp    f0103809 <debuginfo_eip+0x214>
f01037d6:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01037d9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01037dc:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01037df:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01037e4:	39 fa                	cmp    %edi,%edx
f01037e6:	0f 8d 89 00 00 00    	jge    f0103875 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f01037ec:	83 c2 01             	add    $0x1,%edx
f01037ef:	89 d0                	mov    %edx,%eax
f01037f1:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01037f4:	c7 c2 d0 58 10 f0    	mov    $0xf01058d0,%edx
f01037fa:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01037fe:	eb 3b                	jmp    f010383b <debuginfo_eip+0x246>
f0103800:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103803:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103807:	75 26                	jne    f010382f <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103809:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010380c:	c7 c0 d0 58 10 f0    	mov    $0xf01058d0,%eax
f0103812:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103815:	c7 c0 35 e5 10 f0    	mov    $0xf010e535,%eax
f010381b:	81 e8 39 c6 10 f0    	sub    $0xf010c639,%eax
f0103821:	39 c2                	cmp    %eax,%edx
f0103823:	73 b4                	jae    f01037d9 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103825:	81 c2 39 c6 10 f0    	add    $0xf010c639,%edx
f010382b:	89 16                	mov    %edx,(%esi)
f010382d:	eb aa                	jmp    f01037d9 <debuginfo_eip+0x1e4>
f010382f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103832:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103835:	eb d2                	jmp    f0103809 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0103837:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f010383b:	39 c7                	cmp    %eax,%edi
f010383d:	7e 31                	jle    f0103870 <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010383f:	0f b6 0a             	movzbl (%edx),%ecx
f0103842:	83 c0 01             	add    $0x1,%eax
f0103845:	83 c2 0c             	add    $0xc,%edx
f0103848:	80 f9 a0             	cmp    $0xa0,%cl
f010384b:	74 ea                	je     f0103837 <debuginfo_eip+0x242>
	return 0;
f010384d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103852:	eb 21                	jmp    f0103875 <debuginfo_eip+0x280>
		return -1;
f0103854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103859:	eb 1a                	jmp    f0103875 <debuginfo_eip+0x280>
f010385b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103860:	eb 13                	jmp    f0103875 <debuginfo_eip+0x280>
		return -1;
f0103862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103867:	eb 0c                	jmp    f0103875 <debuginfo_eip+0x280>
		return -1;
f0103869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010386e:	eb 05                	jmp    f0103875 <debuginfo_eip+0x280>
	return 0;
f0103870:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103875:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103878:	5b                   	pop    %ebx
f0103879:	5e                   	pop    %esi
f010387a:	5f                   	pop    %edi
f010387b:	5d                   	pop    %ebp
f010387c:	c3                   	ret    

f010387d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010387d:	55                   	push   %ebp
f010387e:	89 e5                	mov    %esp,%ebp
f0103880:	57                   	push   %edi
f0103881:	56                   	push   %esi
f0103882:	53                   	push   %ebx
f0103883:	83 ec 2c             	sub    $0x2c,%esp
f0103886:	e8 d3 fb ff ff       	call   f010345e <__x86.get_pc_thunk.cx>
f010388b:	81 c1 81 4a 01 00    	add    $0x14a81,%ecx
f0103891:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103894:	89 c7                	mov    %eax,%edi
f0103896:	89 d6                	mov    %edx,%esi
f0103898:	8b 45 08             	mov    0x8(%ebp),%eax
f010389b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010389e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01038a1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01038a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01038a7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01038ac:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01038af:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01038b2:	39 d3                	cmp    %edx,%ebx
f01038b4:	72 09                	jb     f01038bf <printnum+0x42>
f01038b6:	39 45 10             	cmp    %eax,0x10(%ebp)
f01038b9:	0f 87 83 00 00 00    	ja     f0103942 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01038bf:	83 ec 0c             	sub    $0xc,%esp
f01038c2:	ff 75 18             	pushl  0x18(%ebp)
f01038c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01038c8:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01038cb:	53                   	push   %ebx
f01038cc:	ff 75 10             	pushl  0x10(%ebp)
f01038cf:	83 ec 08             	sub    $0x8,%esp
f01038d2:	ff 75 dc             	pushl  -0x24(%ebp)
f01038d5:	ff 75 d8             	pushl  -0x28(%ebp)
f01038d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01038db:	ff 75 d0             	pushl  -0x30(%ebp)
f01038de:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01038e1:	e8 1a 0a 00 00       	call   f0104300 <__udivdi3>
f01038e6:	83 c4 18             	add    $0x18,%esp
f01038e9:	52                   	push   %edx
f01038ea:	50                   	push   %eax
f01038eb:	89 f2                	mov    %esi,%edx
f01038ed:	89 f8                	mov    %edi,%eax
f01038ef:	e8 89 ff ff ff       	call   f010387d <printnum>
f01038f4:	83 c4 20             	add    $0x20,%esp
f01038f7:	eb 13                	jmp    f010390c <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01038f9:	83 ec 08             	sub    $0x8,%esp
f01038fc:	56                   	push   %esi
f01038fd:	ff 75 18             	pushl  0x18(%ebp)
f0103900:	ff d7                	call   *%edi
f0103902:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103905:	83 eb 01             	sub    $0x1,%ebx
f0103908:	85 db                	test   %ebx,%ebx
f010390a:	7f ed                	jg     f01038f9 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010390c:	83 ec 08             	sub    $0x8,%esp
f010390f:	56                   	push   %esi
f0103910:	83 ec 04             	sub    $0x4,%esp
f0103913:	ff 75 dc             	pushl  -0x24(%ebp)
f0103916:	ff 75 d8             	pushl  -0x28(%ebp)
f0103919:	ff 75 d4             	pushl  -0x2c(%ebp)
f010391c:	ff 75 d0             	pushl  -0x30(%ebp)
f010391f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103922:	89 f3                	mov    %esi,%ebx
f0103924:	e8 f7 0a 00 00       	call   f0104420 <__umoddi3>
f0103929:	83 c4 14             	add    $0x14,%esp
f010392c:	0f be 84 06 d1 d3 fe 	movsbl -0x12c2f(%esi,%eax,1),%eax
f0103933:	ff 
f0103934:	50                   	push   %eax
f0103935:	ff d7                	call   *%edi
}
f0103937:	83 c4 10             	add    $0x10,%esp
f010393a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010393d:	5b                   	pop    %ebx
f010393e:	5e                   	pop    %esi
f010393f:	5f                   	pop    %edi
f0103940:	5d                   	pop    %ebp
f0103941:	c3                   	ret    
f0103942:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103945:	eb be                	jmp    f0103905 <printnum+0x88>

f0103947 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103947:	55                   	push   %ebp
f0103948:	89 e5                	mov    %esp,%ebp
f010394a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010394d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103951:	8b 10                	mov    (%eax),%edx
f0103953:	3b 50 04             	cmp    0x4(%eax),%edx
f0103956:	73 0a                	jae    f0103962 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103958:	8d 4a 01             	lea    0x1(%edx),%ecx
f010395b:	89 08                	mov    %ecx,(%eax)
f010395d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103960:	88 02                	mov    %al,(%edx)
}
f0103962:	5d                   	pop    %ebp
f0103963:	c3                   	ret    

f0103964 <printfmt>:
{
f0103964:	55                   	push   %ebp
f0103965:	89 e5                	mov    %esp,%ebp
f0103967:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010396a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010396d:	50                   	push   %eax
f010396e:	ff 75 10             	pushl  0x10(%ebp)
f0103971:	ff 75 0c             	pushl  0xc(%ebp)
f0103974:	ff 75 08             	pushl  0x8(%ebp)
f0103977:	e8 05 00 00 00       	call   f0103981 <vprintfmt>
}
f010397c:	83 c4 10             	add    $0x10,%esp
f010397f:	c9                   	leave  
f0103980:	c3                   	ret    

f0103981 <vprintfmt>:
{
f0103981:	55                   	push   %ebp
f0103982:	89 e5                	mov    %esp,%ebp
f0103984:	57                   	push   %edi
f0103985:	56                   	push   %esi
f0103986:	53                   	push   %ebx
f0103987:	83 ec 2c             	sub    $0x2c,%esp
f010398a:	e8 c0 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010398f:	81 c3 7d 49 01 00    	add    $0x1497d,%ebx
f0103995:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103998:	8b 7d 10             	mov    0x10(%ebp),%edi
f010399b:	e9 c3 03 00 00       	jmp    f0103d63 <.L35+0x48>
		padc = ' ';
f01039a0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01039a4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01039ab:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01039b2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01039b9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01039be:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01039c1:	8d 47 01             	lea    0x1(%edi),%eax
f01039c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01039c7:	0f b6 17             	movzbl (%edi),%edx
f01039ca:	8d 42 dd             	lea    -0x23(%edx),%eax
f01039cd:	3c 55                	cmp    $0x55,%al
f01039cf:	0f 87 16 04 00 00    	ja     f0103deb <.L22>
f01039d5:	0f b6 c0             	movzbl %al,%eax
f01039d8:	89 d9                	mov    %ebx,%ecx
f01039da:	03 8c 83 5c d4 fe ff 	add    -0x12ba4(%ebx,%eax,4),%ecx
f01039e1:	ff e1                	jmp    *%ecx

f01039e3 <.L69>:
f01039e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01039e6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01039ea:	eb d5                	jmp    f01039c1 <vprintfmt+0x40>

f01039ec <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01039ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01039ef:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01039f3:	eb cc                	jmp    f01039c1 <vprintfmt+0x40>

f01039f5 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01039f5:	0f b6 d2             	movzbl %dl,%edx
f01039f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01039fb:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0103a00:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103a03:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103a07:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103a0a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103a0d:	83 f9 09             	cmp    $0x9,%ecx
f0103a10:	77 55                	ja     f0103a67 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103a12:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103a15:	eb e9                	jmp    f0103a00 <.L29+0xb>

f0103a17 <.L26>:
			precision = va_arg(ap, int);
f0103a17:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a1a:	8b 00                	mov    (%eax),%eax
f0103a1c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103a1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a22:	8d 40 04             	lea    0x4(%eax),%eax
f0103a25:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103a28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0103a2b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103a2f:	79 90                	jns    f01039c1 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103a31:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103a34:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a37:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0103a3e:	eb 81                	jmp    f01039c1 <vprintfmt+0x40>

f0103a40 <.L27>:
f0103a40:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a43:	85 c0                	test   %eax,%eax
f0103a45:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a4a:	0f 49 d0             	cmovns %eax,%edx
f0103a4d:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103a50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a53:	e9 69 ff ff ff       	jmp    f01039c1 <vprintfmt+0x40>

f0103a58 <.L23>:
f0103a58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103a5b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103a62:	e9 5a ff ff ff       	jmp    f01039c1 <vprintfmt+0x40>
f0103a67:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103a6a:	eb bf                	jmp    f0103a2b <.L26+0x14>

f0103a6c <.L33>:
			lflag++;
f0103a6c:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103a70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0103a73:	e9 49 ff ff ff       	jmp    f01039c1 <vprintfmt+0x40>

f0103a78 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103a78:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a7b:	8d 78 04             	lea    0x4(%eax),%edi
f0103a7e:	83 ec 08             	sub    $0x8,%esp
f0103a81:	56                   	push   %esi
f0103a82:	ff 30                	pushl  (%eax)
f0103a84:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103a87:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103a8a:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103a8d:	e9 ce 02 00 00       	jmp    f0103d60 <.L35+0x45>

f0103a92 <.L32>:
			err = va_arg(ap, int);
f0103a92:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a95:	8d 78 04             	lea    0x4(%eax),%edi
f0103a98:	8b 00                	mov    (%eax),%eax
f0103a9a:	99                   	cltd   
f0103a9b:	31 d0                	xor    %edx,%eax
f0103a9d:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103a9f:	83 f8 06             	cmp    $0x6,%eax
f0103aa2:	7f 27                	jg     f0103acb <.L32+0x39>
f0103aa4:	8b 94 83 50 1d 00 00 	mov    0x1d50(%ebx,%eax,4),%edx
f0103aab:	85 d2                	test   %edx,%edx
f0103aad:	74 1c                	je     f0103acb <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0103aaf:	52                   	push   %edx
f0103ab0:	8d 83 fc c8 fe ff    	lea    -0x13704(%ebx),%eax
f0103ab6:	50                   	push   %eax
f0103ab7:	56                   	push   %esi
f0103ab8:	ff 75 08             	pushl  0x8(%ebp)
f0103abb:	e8 a4 fe ff ff       	call   f0103964 <printfmt>
f0103ac0:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103ac3:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103ac6:	e9 95 02 00 00       	jmp    f0103d60 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103acb:	50                   	push   %eax
f0103acc:	8d 83 e9 d3 fe ff    	lea    -0x12c17(%ebx),%eax
f0103ad2:	50                   	push   %eax
f0103ad3:	56                   	push   %esi
f0103ad4:	ff 75 08             	pushl  0x8(%ebp)
f0103ad7:	e8 88 fe ff ff       	call   f0103964 <printfmt>
f0103adc:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103adf:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103ae2:	e9 79 02 00 00       	jmp    f0103d60 <.L35+0x45>

f0103ae7 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103ae7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aea:	83 c0 04             	add    $0x4,%eax
f0103aed:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103af0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103af3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103af5:	85 ff                	test   %edi,%edi
f0103af7:	8d 83 e2 d3 fe ff    	lea    -0x12c1e(%ebx),%eax
f0103afd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103b00:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103b04:	0f 8e b5 00 00 00    	jle    f0103bbf <.L36+0xd8>
f0103b0a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103b0e:	75 08                	jne    f0103b18 <.L36+0x31>
f0103b10:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103b13:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103b16:	eb 6d                	jmp    f0103b85 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b18:	83 ec 08             	sub    $0x8,%esp
f0103b1b:	ff 75 cc             	pushl  -0x34(%ebp)
f0103b1e:	57                   	push   %edi
f0103b1f:	e8 7e 04 00 00       	call   f0103fa2 <strnlen>
f0103b24:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103b27:	29 c2                	sub    %eax,%edx
f0103b29:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0103b2c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103b2f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103b33:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103b36:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103b39:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b3b:	eb 10                	jmp    f0103b4d <.L36+0x66>
					putch(padc, putdat);
f0103b3d:	83 ec 08             	sub    $0x8,%esp
f0103b40:	56                   	push   %esi
f0103b41:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b44:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103b47:	83 ef 01             	sub    $0x1,%edi
f0103b4a:	83 c4 10             	add    $0x10,%esp
f0103b4d:	85 ff                	test   %edi,%edi
f0103b4f:	7f ec                	jg     f0103b3d <.L36+0x56>
f0103b51:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103b54:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103b57:	85 d2                	test   %edx,%edx
f0103b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b5e:	0f 49 c2             	cmovns %edx,%eax
f0103b61:	29 c2                	sub    %eax,%edx
f0103b63:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103b66:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103b69:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103b6c:	eb 17                	jmp    f0103b85 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103b6e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103b72:	75 30                	jne    f0103ba4 <.L36+0xbd>
					putch(ch, putdat);
f0103b74:	83 ec 08             	sub    $0x8,%esp
f0103b77:	ff 75 0c             	pushl  0xc(%ebp)
f0103b7a:	50                   	push   %eax
f0103b7b:	ff 55 08             	call   *0x8(%ebp)
f0103b7e:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103b81:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103b85:	83 c7 01             	add    $0x1,%edi
f0103b88:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103b8c:	0f be c2             	movsbl %dl,%eax
f0103b8f:	85 c0                	test   %eax,%eax
f0103b91:	74 52                	je     f0103be5 <.L36+0xfe>
f0103b93:	85 f6                	test   %esi,%esi
f0103b95:	78 d7                	js     f0103b6e <.L36+0x87>
f0103b97:	83 ee 01             	sub    $0x1,%esi
f0103b9a:	79 d2                	jns    f0103b6e <.L36+0x87>
f0103b9c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b9f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103ba2:	eb 32                	jmp    f0103bd6 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0103ba4:	0f be d2             	movsbl %dl,%edx
f0103ba7:	83 ea 20             	sub    $0x20,%edx
f0103baa:	83 fa 5e             	cmp    $0x5e,%edx
f0103bad:	76 c5                	jbe    f0103b74 <.L36+0x8d>
					putch('?', putdat);
f0103baf:	83 ec 08             	sub    $0x8,%esp
f0103bb2:	ff 75 0c             	pushl  0xc(%ebp)
f0103bb5:	6a 3f                	push   $0x3f
f0103bb7:	ff 55 08             	call   *0x8(%ebp)
f0103bba:	83 c4 10             	add    $0x10,%esp
f0103bbd:	eb c2                	jmp    f0103b81 <.L36+0x9a>
f0103bbf:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103bc2:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103bc5:	eb be                	jmp    f0103b85 <.L36+0x9e>
				putch(' ', putdat);
f0103bc7:	83 ec 08             	sub    $0x8,%esp
f0103bca:	56                   	push   %esi
f0103bcb:	6a 20                	push   $0x20
f0103bcd:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0103bd0:	83 ef 01             	sub    $0x1,%edi
f0103bd3:	83 c4 10             	add    $0x10,%esp
f0103bd6:	85 ff                	test   %edi,%edi
f0103bd8:	7f ed                	jg     f0103bc7 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103bda:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103bdd:	89 45 14             	mov    %eax,0x14(%ebp)
f0103be0:	e9 7b 01 00 00       	jmp    f0103d60 <.L35+0x45>
f0103be5:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103be8:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103beb:	eb e9                	jmp    f0103bd6 <.L36+0xef>

f0103bed <.L31>:
f0103bed:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103bf0:	83 f9 01             	cmp    $0x1,%ecx
f0103bf3:	7e 40                	jle    f0103c35 <.L31+0x48>
		return va_arg(*ap, long long);
f0103bf5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf8:	8b 50 04             	mov    0x4(%eax),%edx
f0103bfb:	8b 00                	mov    (%eax),%eax
f0103bfd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c00:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c03:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c06:	8d 40 08             	lea    0x8(%eax),%eax
f0103c09:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103c0c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103c10:	79 55                	jns    f0103c67 <.L31+0x7a>
				putch('-', putdat);
f0103c12:	83 ec 08             	sub    $0x8,%esp
f0103c15:	56                   	push   %esi
f0103c16:	6a 2d                	push   $0x2d
f0103c18:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103c1b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103c1e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103c21:	f7 da                	neg    %edx
f0103c23:	83 d1 00             	adc    $0x0,%ecx
f0103c26:	f7 d9                	neg    %ecx
f0103c28:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103c2b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c30:	e9 10 01 00 00       	jmp    f0103d45 <.L35+0x2a>
	else if (lflag)
f0103c35:	85 c9                	test   %ecx,%ecx
f0103c37:	75 17                	jne    f0103c50 <.L31+0x63>
		return va_arg(*ap, int);
f0103c39:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c3c:	8b 00                	mov    (%eax),%eax
f0103c3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c41:	99                   	cltd   
f0103c42:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c48:	8d 40 04             	lea    0x4(%eax),%eax
f0103c4b:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c4e:	eb bc                	jmp    f0103c0c <.L31+0x1f>
		return va_arg(*ap, long);
f0103c50:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c53:	8b 00                	mov    (%eax),%eax
f0103c55:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c58:	99                   	cltd   
f0103c59:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c5f:	8d 40 04             	lea    0x4(%eax),%eax
f0103c62:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c65:	eb a5                	jmp    f0103c0c <.L31+0x1f>
			num = getint(&ap, lflag);
f0103c67:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103c6a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103c6d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c72:	e9 ce 00 00 00       	jmp    f0103d45 <.L35+0x2a>

f0103c77 <.L37>:
f0103c77:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103c7a:	83 f9 01             	cmp    $0x1,%ecx
f0103c7d:	7e 18                	jle    f0103c97 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0103c7f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c82:	8b 10                	mov    (%eax),%edx
f0103c84:	8b 48 04             	mov    0x4(%eax),%ecx
f0103c87:	8d 40 08             	lea    0x8(%eax),%eax
f0103c8a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103c8d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c92:	e9 ae 00 00 00       	jmp    f0103d45 <.L35+0x2a>
	else if (lflag)
f0103c97:	85 c9                	test   %ecx,%ecx
f0103c99:	75 1a                	jne    f0103cb5 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0103c9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c9e:	8b 10                	mov    (%eax),%edx
f0103ca0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ca5:	8d 40 04             	lea    0x4(%eax),%eax
f0103ca8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103cab:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103cb0:	e9 90 00 00 00       	jmp    f0103d45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103cb5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cb8:	8b 10                	mov    (%eax),%edx
f0103cba:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cbf:	8d 40 04             	lea    0x4(%eax),%eax
f0103cc2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103cc5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103cca:	eb 79                	jmp    f0103d45 <.L35+0x2a>

f0103ccc <.L34>:
f0103ccc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103ccf:	83 f9 01             	cmp    $0x1,%ecx
f0103cd2:	7e 15                	jle    f0103ce9 <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0103cd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cd7:	8b 10                	mov    (%eax),%edx
f0103cd9:	8b 48 04             	mov    0x4(%eax),%ecx
f0103cdc:	8d 40 08             	lea    0x8(%eax),%eax
f0103cdf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103ce2:	b8 08 00 00 00       	mov    $0x8,%eax
f0103ce7:	eb 5c                	jmp    f0103d45 <.L35+0x2a>
	else if (lflag)
f0103ce9:	85 c9                	test   %ecx,%ecx
f0103ceb:	75 17                	jne    f0103d04 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0103ced:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cf0:	8b 10                	mov    (%eax),%edx
f0103cf2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cf7:	8d 40 04             	lea    0x4(%eax),%eax
f0103cfa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103cfd:	b8 08 00 00 00       	mov    $0x8,%eax
f0103d02:	eb 41                	jmp    f0103d45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103d04:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d07:	8b 10                	mov    (%eax),%edx
f0103d09:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d0e:	8d 40 04             	lea    0x4(%eax),%eax
f0103d11:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103d14:	b8 08 00 00 00       	mov    $0x8,%eax
f0103d19:	eb 2a                	jmp    f0103d45 <.L35+0x2a>

f0103d1b <.L35>:
			putch('0', putdat);
f0103d1b:	83 ec 08             	sub    $0x8,%esp
f0103d1e:	56                   	push   %esi
f0103d1f:	6a 30                	push   $0x30
f0103d21:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103d24:	83 c4 08             	add    $0x8,%esp
f0103d27:	56                   	push   %esi
f0103d28:	6a 78                	push   $0x78
f0103d2a:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103d2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d30:	8b 10                	mov    (%eax),%edx
f0103d32:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103d37:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103d3a:	8d 40 04             	lea    0x4(%eax),%eax
f0103d3d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103d40:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103d45:	83 ec 0c             	sub    $0xc,%esp
f0103d48:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103d4c:	57                   	push   %edi
f0103d4d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d50:	50                   	push   %eax
f0103d51:	51                   	push   %ecx
f0103d52:	52                   	push   %edx
f0103d53:	89 f2                	mov    %esi,%edx
f0103d55:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d58:	e8 20 fb ff ff       	call   f010387d <printnum>
			break;
f0103d5d:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103d60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103d63:	83 c7 01             	add    $0x1,%edi
f0103d66:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d6a:	83 f8 25             	cmp    $0x25,%eax
f0103d6d:	0f 84 2d fc ff ff    	je     f01039a0 <vprintfmt+0x1f>
			if (ch == '\0')
f0103d73:	85 c0                	test   %eax,%eax
f0103d75:	0f 84 91 00 00 00    	je     f0103e0c <.L22+0x21>
			putch(ch, putdat);
f0103d7b:	83 ec 08             	sub    $0x8,%esp
f0103d7e:	56                   	push   %esi
f0103d7f:	50                   	push   %eax
f0103d80:	ff 55 08             	call   *0x8(%ebp)
f0103d83:	83 c4 10             	add    $0x10,%esp
f0103d86:	eb db                	jmp    f0103d63 <.L35+0x48>

f0103d88 <.L38>:
f0103d88:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103d8b:	83 f9 01             	cmp    $0x1,%ecx
f0103d8e:	7e 15                	jle    f0103da5 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103d90:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d93:	8b 10                	mov    (%eax),%edx
f0103d95:	8b 48 04             	mov    0x4(%eax),%ecx
f0103d98:	8d 40 08             	lea    0x8(%eax),%eax
f0103d9b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103d9e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103da3:	eb a0                	jmp    f0103d45 <.L35+0x2a>
	else if (lflag)
f0103da5:	85 c9                	test   %ecx,%ecx
f0103da7:	75 17                	jne    f0103dc0 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103da9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dac:	8b 10                	mov    (%eax),%edx
f0103dae:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103db3:	8d 40 04             	lea    0x4(%eax),%eax
f0103db6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103db9:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dbe:	eb 85                	jmp    f0103d45 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103dc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dc3:	8b 10                	mov    (%eax),%edx
f0103dc5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103dca:	8d 40 04             	lea    0x4(%eax),%eax
f0103dcd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103dd0:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dd5:	e9 6b ff ff ff       	jmp    f0103d45 <.L35+0x2a>

f0103dda <.L25>:
			putch(ch, putdat);
f0103dda:	83 ec 08             	sub    $0x8,%esp
f0103ddd:	56                   	push   %esi
f0103dde:	6a 25                	push   $0x25
f0103de0:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103de3:	83 c4 10             	add    $0x10,%esp
f0103de6:	e9 75 ff ff ff       	jmp    f0103d60 <.L35+0x45>

f0103deb <.L22>:
			putch('%', putdat);
f0103deb:	83 ec 08             	sub    $0x8,%esp
f0103dee:	56                   	push   %esi
f0103def:	6a 25                	push   $0x25
f0103df1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103df4:	83 c4 10             	add    $0x10,%esp
f0103df7:	89 f8                	mov    %edi,%eax
f0103df9:	eb 03                	jmp    f0103dfe <.L22+0x13>
f0103dfb:	83 e8 01             	sub    $0x1,%eax
f0103dfe:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103e02:	75 f7                	jne    f0103dfb <.L22+0x10>
f0103e04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e07:	e9 54 ff ff ff       	jmp    f0103d60 <.L35+0x45>
}
f0103e0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e0f:	5b                   	pop    %ebx
f0103e10:	5e                   	pop    %esi
f0103e11:	5f                   	pop    %edi
f0103e12:	5d                   	pop    %ebp
f0103e13:	c3                   	ret    

f0103e14 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e14:	55                   	push   %ebp
f0103e15:	89 e5                	mov    %esp,%ebp
f0103e17:	53                   	push   %ebx
f0103e18:	83 ec 14             	sub    $0x14,%esp
f0103e1b:	e8 2f c3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103e20:	81 c3 ec 44 01 00    	add    $0x144ec,%ebx
f0103e26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e29:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e2f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e33:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e3d:	85 c0                	test   %eax,%eax
f0103e3f:	74 2b                	je     f0103e6c <vsnprintf+0x58>
f0103e41:	85 d2                	test   %edx,%edx
f0103e43:	7e 27                	jle    f0103e6c <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e45:	ff 75 14             	pushl  0x14(%ebp)
f0103e48:	ff 75 10             	pushl  0x10(%ebp)
f0103e4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e4e:	50                   	push   %eax
f0103e4f:	8d 83 3b b6 fe ff    	lea    -0x149c5(%ebx),%eax
f0103e55:	50                   	push   %eax
f0103e56:	e8 26 fb ff ff       	call   f0103981 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e5b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e5e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e61:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e64:	83 c4 10             	add    $0x10,%esp
}
f0103e67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103e6a:	c9                   	leave  
f0103e6b:	c3                   	ret    
		return -E_INVAL;
f0103e6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103e71:	eb f4                	jmp    f0103e67 <vsnprintf+0x53>

f0103e73 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e73:	55                   	push   %ebp
f0103e74:	89 e5                	mov    %esp,%ebp
f0103e76:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103e79:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103e7c:	50                   	push   %eax
f0103e7d:	ff 75 10             	pushl  0x10(%ebp)
f0103e80:	ff 75 0c             	pushl  0xc(%ebp)
f0103e83:	ff 75 08             	pushl  0x8(%ebp)
f0103e86:	e8 89 ff ff ff       	call   f0103e14 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103e8b:	c9                   	leave  
f0103e8c:	c3                   	ret    

f0103e8d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103e8d:	55                   	push   %ebp
f0103e8e:	89 e5                	mov    %esp,%ebp
f0103e90:	57                   	push   %edi
f0103e91:	56                   	push   %esi
f0103e92:	53                   	push   %ebx
f0103e93:	83 ec 1c             	sub    $0x1c,%esp
f0103e96:	e8 b4 c2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103e9b:	81 c3 71 44 01 00    	add    $0x14471,%ebx
f0103ea1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ea4:	85 c0                	test   %eax,%eax
f0103ea6:	74 13                	je     f0103ebb <readline+0x2e>
		cprintf("%s", prompt);
f0103ea8:	83 ec 08             	sub    $0x8,%esp
f0103eab:	50                   	push   %eax
f0103eac:	8d 83 fc c8 fe ff    	lea    -0x13704(%ebx),%eax
f0103eb2:	50                   	push   %eax
f0103eb3:	e8 39 f6 ff ff       	call   f01034f1 <cprintf>
f0103eb8:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103ebb:	83 ec 0c             	sub    $0xc,%esp
f0103ebe:	6a 00                	push   $0x0
f0103ec0:	e8 22 c8 ff ff       	call   f01006e7 <iscons>
f0103ec5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ec8:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103ecb:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ed0:	eb 46                	jmp    f0103f18 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103ed2:	83 ec 08             	sub    $0x8,%esp
f0103ed5:	50                   	push   %eax
f0103ed6:	8d 83 b4 d5 fe ff    	lea    -0x12a4c(%ebx),%eax
f0103edc:	50                   	push   %eax
f0103edd:	e8 0f f6 ff ff       	call   f01034f1 <cprintf>
			return NULL;
f0103ee2:	83 c4 10             	add    $0x10,%esp
f0103ee5:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103eea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103eed:	5b                   	pop    %ebx
f0103eee:	5e                   	pop    %esi
f0103eef:	5f                   	pop    %edi
f0103ef0:	5d                   	pop    %ebp
f0103ef1:	c3                   	ret    
			if (echoing)
f0103ef2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103ef6:	75 05                	jne    f0103efd <readline+0x70>
			i--;
f0103ef8:	83 ef 01             	sub    $0x1,%edi
f0103efb:	eb 1b                	jmp    f0103f18 <readline+0x8b>
				cputchar('\b');
f0103efd:	83 ec 0c             	sub    $0xc,%esp
f0103f00:	6a 08                	push   $0x8
f0103f02:	e8 bf c7 ff ff       	call   f01006c6 <cputchar>
f0103f07:	83 c4 10             	add    $0x10,%esp
f0103f0a:	eb ec                	jmp    f0103ef8 <readline+0x6b>
			buf[i++] = c;
f0103f0c:	89 f0                	mov    %esi,%eax
f0103f0e:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f0103f15:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103f18:	e8 b9 c7 ff ff       	call   f01006d6 <getchar>
f0103f1d:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103f1f:	85 c0                	test   %eax,%eax
f0103f21:	78 af                	js     f0103ed2 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103f23:	83 f8 08             	cmp    $0x8,%eax
f0103f26:	0f 94 c2             	sete   %dl
f0103f29:	83 f8 7f             	cmp    $0x7f,%eax
f0103f2c:	0f 94 c0             	sete   %al
f0103f2f:	08 c2                	or     %al,%dl
f0103f31:	74 04                	je     f0103f37 <readline+0xaa>
f0103f33:	85 ff                	test   %edi,%edi
f0103f35:	7f bb                	jg     f0103ef2 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f37:	83 fe 1f             	cmp    $0x1f,%esi
f0103f3a:	7e 1c                	jle    f0103f58 <readline+0xcb>
f0103f3c:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103f42:	7f 14                	jg     f0103f58 <readline+0xcb>
			if (echoing)
f0103f44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103f48:	74 c2                	je     f0103f0c <readline+0x7f>
				cputchar(c);
f0103f4a:	83 ec 0c             	sub    $0xc,%esp
f0103f4d:	56                   	push   %esi
f0103f4e:	e8 73 c7 ff ff       	call   f01006c6 <cputchar>
f0103f53:	83 c4 10             	add    $0x10,%esp
f0103f56:	eb b4                	jmp    f0103f0c <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103f58:	83 fe 0a             	cmp    $0xa,%esi
f0103f5b:	74 05                	je     f0103f62 <readline+0xd5>
f0103f5d:	83 fe 0d             	cmp    $0xd,%esi
f0103f60:	75 b6                	jne    f0103f18 <readline+0x8b>
			if (echoing)
f0103f62:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103f66:	75 13                	jne    f0103f7b <readline+0xee>
			buf[i] = 0;
f0103f68:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103f6f:	00 
			return buf;
f0103f70:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103f76:	e9 6f ff ff ff       	jmp    f0103eea <readline+0x5d>
				cputchar('\n');
f0103f7b:	83 ec 0c             	sub    $0xc,%esp
f0103f7e:	6a 0a                	push   $0xa
f0103f80:	e8 41 c7 ff ff       	call   f01006c6 <cputchar>
f0103f85:	83 c4 10             	add    $0x10,%esp
f0103f88:	eb de                	jmp    f0103f68 <readline+0xdb>

f0103f8a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f8a:	55                   	push   %ebp
f0103f8b:	89 e5                	mov    %esp,%ebp
f0103f8d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f90:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f95:	eb 03                	jmp    f0103f9a <strlen+0x10>
		n++;
f0103f97:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103f9a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103f9e:	75 f7                	jne    f0103f97 <strlen+0xd>
	return n;
}
f0103fa0:	5d                   	pop    %ebp
f0103fa1:	c3                   	ret    

f0103fa2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103fa2:	55                   	push   %ebp
f0103fa3:	89 e5                	mov    %esp,%ebp
f0103fa5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fa8:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fab:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fb0:	eb 03                	jmp    f0103fb5 <strnlen+0x13>
		n++;
f0103fb2:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fb5:	39 d0                	cmp    %edx,%eax
f0103fb7:	74 06                	je     f0103fbf <strnlen+0x1d>
f0103fb9:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103fbd:	75 f3                	jne    f0103fb2 <strnlen+0x10>
	return n;
}
f0103fbf:	5d                   	pop    %ebp
f0103fc0:	c3                   	ret    

f0103fc1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103fc1:	55                   	push   %ebp
f0103fc2:	89 e5                	mov    %esp,%ebp
f0103fc4:	53                   	push   %ebx
f0103fc5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fc8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103fcb:	89 c2                	mov    %eax,%edx
f0103fcd:	83 c1 01             	add    $0x1,%ecx
f0103fd0:	83 c2 01             	add    $0x1,%edx
f0103fd3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103fd7:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103fda:	84 db                	test   %bl,%bl
f0103fdc:	75 ef                	jne    f0103fcd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103fde:	5b                   	pop    %ebx
f0103fdf:	5d                   	pop    %ebp
f0103fe0:	c3                   	ret    

f0103fe1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103fe1:	55                   	push   %ebp
f0103fe2:	89 e5                	mov    %esp,%ebp
f0103fe4:	53                   	push   %ebx
f0103fe5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103fe8:	53                   	push   %ebx
f0103fe9:	e8 9c ff ff ff       	call   f0103f8a <strlen>
f0103fee:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103ff1:	ff 75 0c             	pushl  0xc(%ebp)
f0103ff4:	01 d8                	add    %ebx,%eax
f0103ff6:	50                   	push   %eax
f0103ff7:	e8 c5 ff ff ff       	call   f0103fc1 <strcpy>
	return dst;
}
f0103ffc:	89 d8                	mov    %ebx,%eax
f0103ffe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104001:	c9                   	leave  
f0104002:	c3                   	ret    

f0104003 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104003:	55                   	push   %ebp
f0104004:	89 e5                	mov    %esp,%ebp
f0104006:	56                   	push   %esi
f0104007:	53                   	push   %ebx
f0104008:	8b 75 08             	mov    0x8(%ebp),%esi
f010400b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010400e:	89 f3                	mov    %esi,%ebx
f0104010:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104013:	89 f2                	mov    %esi,%edx
f0104015:	eb 0f                	jmp    f0104026 <strncpy+0x23>
		*dst++ = *src;
f0104017:	83 c2 01             	add    $0x1,%edx
f010401a:	0f b6 01             	movzbl (%ecx),%eax
f010401d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104020:	80 39 01             	cmpb   $0x1,(%ecx)
f0104023:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104026:	39 da                	cmp    %ebx,%edx
f0104028:	75 ed                	jne    f0104017 <strncpy+0x14>
	}
	return ret;
}
f010402a:	89 f0                	mov    %esi,%eax
f010402c:	5b                   	pop    %ebx
f010402d:	5e                   	pop    %esi
f010402e:	5d                   	pop    %ebp
f010402f:	c3                   	ret    

f0104030 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104030:	55                   	push   %ebp
f0104031:	89 e5                	mov    %esp,%ebp
f0104033:	56                   	push   %esi
f0104034:	53                   	push   %ebx
f0104035:	8b 75 08             	mov    0x8(%ebp),%esi
f0104038:	8b 55 0c             	mov    0xc(%ebp),%edx
f010403b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010403e:	89 f0                	mov    %esi,%eax
f0104040:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104044:	85 c9                	test   %ecx,%ecx
f0104046:	75 0b                	jne    f0104053 <strlcpy+0x23>
f0104048:	eb 17                	jmp    f0104061 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010404a:	83 c2 01             	add    $0x1,%edx
f010404d:	83 c0 01             	add    $0x1,%eax
f0104050:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0104053:	39 d8                	cmp    %ebx,%eax
f0104055:	74 07                	je     f010405e <strlcpy+0x2e>
f0104057:	0f b6 0a             	movzbl (%edx),%ecx
f010405a:	84 c9                	test   %cl,%cl
f010405c:	75 ec                	jne    f010404a <strlcpy+0x1a>
		*dst = '\0';
f010405e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104061:	29 f0                	sub    %esi,%eax
}
f0104063:	5b                   	pop    %ebx
f0104064:	5e                   	pop    %esi
f0104065:	5d                   	pop    %ebp
f0104066:	c3                   	ret    

f0104067 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104067:	55                   	push   %ebp
f0104068:	89 e5                	mov    %esp,%ebp
f010406a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010406d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104070:	eb 06                	jmp    f0104078 <strcmp+0x11>
		p++, q++;
f0104072:	83 c1 01             	add    $0x1,%ecx
f0104075:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104078:	0f b6 01             	movzbl (%ecx),%eax
f010407b:	84 c0                	test   %al,%al
f010407d:	74 04                	je     f0104083 <strcmp+0x1c>
f010407f:	3a 02                	cmp    (%edx),%al
f0104081:	74 ef                	je     f0104072 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104083:	0f b6 c0             	movzbl %al,%eax
f0104086:	0f b6 12             	movzbl (%edx),%edx
f0104089:	29 d0                	sub    %edx,%eax
}
f010408b:	5d                   	pop    %ebp
f010408c:	c3                   	ret    

f010408d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010408d:	55                   	push   %ebp
f010408e:	89 e5                	mov    %esp,%ebp
f0104090:	53                   	push   %ebx
f0104091:	8b 45 08             	mov    0x8(%ebp),%eax
f0104094:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104097:	89 c3                	mov    %eax,%ebx
f0104099:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010409c:	eb 06                	jmp    f01040a4 <strncmp+0x17>
		n--, p++, q++;
f010409e:	83 c0 01             	add    $0x1,%eax
f01040a1:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01040a4:	39 d8                	cmp    %ebx,%eax
f01040a6:	74 16                	je     f01040be <strncmp+0x31>
f01040a8:	0f b6 08             	movzbl (%eax),%ecx
f01040ab:	84 c9                	test   %cl,%cl
f01040ad:	74 04                	je     f01040b3 <strncmp+0x26>
f01040af:	3a 0a                	cmp    (%edx),%cl
f01040b1:	74 eb                	je     f010409e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040b3:	0f b6 00             	movzbl (%eax),%eax
f01040b6:	0f b6 12             	movzbl (%edx),%edx
f01040b9:	29 d0                	sub    %edx,%eax
}
f01040bb:	5b                   	pop    %ebx
f01040bc:	5d                   	pop    %ebp
f01040bd:	c3                   	ret    
		return 0;
f01040be:	b8 00 00 00 00       	mov    $0x0,%eax
f01040c3:	eb f6                	jmp    f01040bb <strncmp+0x2e>

f01040c5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040c5:	55                   	push   %ebp
f01040c6:	89 e5                	mov    %esp,%ebp
f01040c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01040cb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040cf:	0f b6 10             	movzbl (%eax),%edx
f01040d2:	84 d2                	test   %dl,%dl
f01040d4:	74 09                	je     f01040df <strchr+0x1a>
		if (*s == c)
f01040d6:	38 ca                	cmp    %cl,%dl
f01040d8:	74 0a                	je     f01040e4 <strchr+0x1f>
	for (; *s; s++)
f01040da:	83 c0 01             	add    $0x1,%eax
f01040dd:	eb f0                	jmp    f01040cf <strchr+0xa>
			return (char *) s;
	return 0;
f01040df:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01040e4:	5d                   	pop    %ebp
f01040e5:	c3                   	ret    

f01040e6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01040e6:	55                   	push   %ebp
f01040e7:	89 e5                	mov    %esp,%ebp
f01040e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040f0:	eb 03                	jmp    f01040f5 <strfind+0xf>
f01040f2:	83 c0 01             	add    $0x1,%eax
f01040f5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01040f8:	38 ca                	cmp    %cl,%dl
f01040fa:	74 04                	je     f0104100 <strfind+0x1a>
f01040fc:	84 d2                	test   %dl,%dl
f01040fe:	75 f2                	jne    f01040f2 <strfind+0xc>
			break;
	return (char *) s;
}
f0104100:	5d                   	pop    %ebp
f0104101:	c3                   	ret    

f0104102 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104102:	55                   	push   %ebp
f0104103:	89 e5                	mov    %esp,%ebp
f0104105:	57                   	push   %edi
f0104106:	56                   	push   %esi
f0104107:	53                   	push   %ebx
f0104108:	8b 7d 08             	mov    0x8(%ebp),%edi
f010410b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010410e:	85 c9                	test   %ecx,%ecx
f0104110:	74 13                	je     f0104125 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104112:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104118:	75 05                	jne    f010411f <memset+0x1d>
f010411a:	f6 c1 03             	test   $0x3,%cl
f010411d:	74 0d                	je     f010412c <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010411f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104122:	fc                   	cld    
f0104123:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104125:	89 f8                	mov    %edi,%eax
f0104127:	5b                   	pop    %ebx
f0104128:	5e                   	pop    %esi
f0104129:	5f                   	pop    %edi
f010412a:	5d                   	pop    %ebp
f010412b:	c3                   	ret    
		c &= 0xFF;
f010412c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104130:	89 d3                	mov    %edx,%ebx
f0104132:	c1 e3 08             	shl    $0x8,%ebx
f0104135:	89 d0                	mov    %edx,%eax
f0104137:	c1 e0 18             	shl    $0x18,%eax
f010413a:	89 d6                	mov    %edx,%esi
f010413c:	c1 e6 10             	shl    $0x10,%esi
f010413f:	09 f0                	or     %esi,%eax
f0104141:	09 c2                	or     %eax,%edx
f0104143:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0104145:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104148:	89 d0                	mov    %edx,%eax
f010414a:	fc                   	cld    
f010414b:	f3 ab                	rep stos %eax,%es:(%edi)
f010414d:	eb d6                	jmp    f0104125 <memset+0x23>

f010414f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010414f:	55                   	push   %ebp
f0104150:	89 e5                	mov    %esp,%ebp
f0104152:	57                   	push   %edi
f0104153:	56                   	push   %esi
f0104154:	8b 45 08             	mov    0x8(%ebp),%eax
f0104157:	8b 75 0c             	mov    0xc(%ebp),%esi
f010415a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010415d:	39 c6                	cmp    %eax,%esi
f010415f:	73 35                	jae    f0104196 <memmove+0x47>
f0104161:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104164:	39 c2                	cmp    %eax,%edx
f0104166:	76 2e                	jbe    f0104196 <memmove+0x47>
		s += n;
		d += n;
f0104168:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010416b:	89 d6                	mov    %edx,%esi
f010416d:	09 fe                	or     %edi,%esi
f010416f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104175:	74 0c                	je     f0104183 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104177:	83 ef 01             	sub    $0x1,%edi
f010417a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010417d:	fd                   	std    
f010417e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104180:	fc                   	cld    
f0104181:	eb 21                	jmp    f01041a4 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104183:	f6 c1 03             	test   $0x3,%cl
f0104186:	75 ef                	jne    f0104177 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104188:	83 ef 04             	sub    $0x4,%edi
f010418b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010418e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104191:	fd                   	std    
f0104192:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104194:	eb ea                	jmp    f0104180 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104196:	89 f2                	mov    %esi,%edx
f0104198:	09 c2                	or     %eax,%edx
f010419a:	f6 c2 03             	test   $0x3,%dl
f010419d:	74 09                	je     f01041a8 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010419f:	89 c7                	mov    %eax,%edi
f01041a1:	fc                   	cld    
f01041a2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01041a4:	5e                   	pop    %esi
f01041a5:	5f                   	pop    %edi
f01041a6:	5d                   	pop    %ebp
f01041a7:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041a8:	f6 c1 03             	test   $0x3,%cl
f01041ab:	75 f2                	jne    f010419f <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01041ad:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01041b0:	89 c7                	mov    %eax,%edi
f01041b2:	fc                   	cld    
f01041b3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041b5:	eb ed                	jmp    f01041a4 <memmove+0x55>

f01041b7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01041b7:	55                   	push   %ebp
f01041b8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01041ba:	ff 75 10             	pushl  0x10(%ebp)
f01041bd:	ff 75 0c             	pushl  0xc(%ebp)
f01041c0:	ff 75 08             	pushl  0x8(%ebp)
f01041c3:	e8 87 ff ff ff       	call   f010414f <memmove>
}
f01041c8:	c9                   	leave  
f01041c9:	c3                   	ret    

f01041ca <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01041ca:	55                   	push   %ebp
f01041cb:	89 e5                	mov    %esp,%ebp
f01041cd:	56                   	push   %esi
f01041ce:	53                   	push   %ebx
f01041cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01041d2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041d5:	89 c6                	mov    %eax,%esi
f01041d7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01041da:	39 f0                	cmp    %esi,%eax
f01041dc:	74 1c                	je     f01041fa <memcmp+0x30>
		if (*s1 != *s2)
f01041de:	0f b6 08             	movzbl (%eax),%ecx
f01041e1:	0f b6 1a             	movzbl (%edx),%ebx
f01041e4:	38 d9                	cmp    %bl,%cl
f01041e6:	75 08                	jne    f01041f0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01041e8:	83 c0 01             	add    $0x1,%eax
f01041eb:	83 c2 01             	add    $0x1,%edx
f01041ee:	eb ea                	jmp    f01041da <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01041f0:	0f b6 c1             	movzbl %cl,%eax
f01041f3:	0f b6 db             	movzbl %bl,%ebx
f01041f6:	29 d8                	sub    %ebx,%eax
f01041f8:	eb 05                	jmp    f01041ff <memcmp+0x35>
	}

	return 0;
f01041fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01041ff:	5b                   	pop    %ebx
f0104200:	5e                   	pop    %esi
f0104201:	5d                   	pop    %ebp
f0104202:	c3                   	ret    

f0104203 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104203:	55                   	push   %ebp
f0104204:	89 e5                	mov    %esp,%ebp
f0104206:	8b 45 08             	mov    0x8(%ebp),%eax
f0104209:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010420c:	89 c2                	mov    %eax,%edx
f010420e:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104211:	39 d0                	cmp    %edx,%eax
f0104213:	73 09                	jae    f010421e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104215:	38 08                	cmp    %cl,(%eax)
f0104217:	74 05                	je     f010421e <memfind+0x1b>
	for (; s < ends; s++)
f0104219:	83 c0 01             	add    $0x1,%eax
f010421c:	eb f3                	jmp    f0104211 <memfind+0xe>
			break;
	return (void *) s;
}
f010421e:	5d                   	pop    %ebp
f010421f:	c3                   	ret    

f0104220 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104220:	55                   	push   %ebp
f0104221:	89 e5                	mov    %esp,%ebp
f0104223:	57                   	push   %edi
f0104224:	56                   	push   %esi
f0104225:	53                   	push   %ebx
f0104226:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104229:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010422c:	eb 03                	jmp    f0104231 <strtol+0x11>
		s++;
f010422e:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104231:	0f b6 01             	movzbl (%ecx),%eax
f0104234:	3c 20                	cmp    $0x20,%al
f0104236:	74 f6                	je     f010422e <strtol+0xe>
f0104238:	3c 09                	cmp    $0x9,%al
f010423a:	74 f2                	je     f010422e <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f010423c:	3c 2b                	cmp    $0x2b,%al
f010423e:	74 2e                	je     f010426e <strtol+0x4e>
	int neg = 0;
f0104240:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0104245:	3c 2d                	cmp    $0x2d,%al
f0104247:	74 2f                	je     f0104278 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104249:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010424f:	75 05                	jne    f0104256 <strtol+0x36>
f0104251:	80 39 30             	cmpb   $0x30,(%ecx)
f0104254:	74 2c                	je     f0104282 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104256:	85 db                	test   %ebx,%ebx
f0104258:	75 0a                	jne    f0104264 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010425a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010425f:	80 39 30             	cmpb   $0x30,(%ecx)
f0104262:	74 28                	je     f010428c <strtol+0x6c>
		base = 10;
f0104264:	b8 00 00 00 00       	mov    $0x0,%eax
f0104269:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010426c:	eb 50                	jmp    f01042be <strtol+0x9e>
		s++;
f010426e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0104271:	bf 00 00 00 00       	mov    $0x0,%edi
f0104276:	eb d1                	jmp    f0104249 <strtol+0x29>
		s++, neg = 1;
f0104278:	83 c1 01             	add    $0x1,%ecx
f010427b:	bf 01 00 00 00       	mov    $0x1,%edi
f0104280:	eb c7                	jmp    f0104249 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104282:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104286:	74 0e                	je     f0104296 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104288:	85 db                	test   %ebx,%ebx
f010428a:	75 d8                	jne    f0104264 <strtol+0x44>
		s++, base = 8;
f010428c:	83 c1 01             	add    $0x1,%ecx
f010428f:	bb 08 00 00 00       	mov    $0x8,%ebx
f0104294:	eb ce                	jmp    f0104264 <strtol+0x44>
		s += 2, base = 16;
f0104296:	83 c1 02             	add    $0x2,%ecx
f0104299:	bb 10 00 00 00       	mov    $0x10,%ebx
f010429e:	eb c4                	jmp    f0104264 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01042a0:	8d 72 9f             	lea    -0x61(%edx),%esi
f01042a3:	89 f3                	mov    %esi,%ebx
f01042a5:	80 fb 19             	cmp    $0x19,%bl
f01042a8:	77 29                	ja     f01042d3 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01042aa:	0f be d2             	movsbl %dl,%edx
f01042ad:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01042b0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01042b3:	7d 30                	jge    f01042e5 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01042b5:	83 c1 01             	add    $0x1,%ecx
f01042b8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01042bc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01042be:	0f b6 11             	movzbl (%ecx),%edx
f01042c1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01042c4:	89 f3                	mov    %esi,%ebx
f01042c6:	80 fb 09             	cmp    $0x9,%bl
f01042c9:	77 d5                	ja     f01042a0 <strtol+0x80>
			dig = *s - '0';
f01042cb:	0f be d2             	movsbl %dl,%edx
f01042ce:	83 ea 30             	sub    $0x30,%edx
f01042d1:	eb dd                	jmp    f01042b0 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01042d3:	8d 72 bf             	lea    -0x41(%edx),%esi
f01042d6:	89 f3                	mov    %esi,%ebx
f01042d8:	80 fb 19             	cmp    $0x19,%bl
f01042db:	77 08                	ja     f01042e5 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01042dd:	0f be d2             	movsbl %dl,%edx
f01042e0:	83 ea 37             	sub    $0x37,%edx
f01042e3:	eb cb                	jmp    f01042b0 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01042e5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01042e9:	74 05                	je     f01042f0 <strtol+0xd0>
		*endptr = (char *) s;
f01042eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01042ee:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01042f0:	89 c2                	mov    %eax,%edx
f01042f2:	f7 da                	neg    %edx
f01042f4:	85 ff                	test   %edi,%edi
f01042f6:	0f 45 c2             	cmovne %edx,%eax
}
f01042f9:	5b                   	pop    %ebx
f01042fa:	5e                   	pop    %esi
f01042fb:	5f                   	pop    %edi
f01042fc:	5d                   	pop    %ebp
f01042fd:	c3                   	ret    
f01042fe:	66 90                	xchg   %ax,%ax

f0104300 <__udivdi3>:
f0104300:	55                   	push   %ebp
f0104301:	57                   	push   %edi
f0104302:	56                   	push   %esi
f0104303:	53                   	push   %ebx
f0104304:	83 ec 1c             	sub    $0x1c,%esp
f0104307:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010430b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010430f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104313:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104317:	85 d2                	test   %edx,%edx
f0104319:	75 35                	jne    f0104350 <__udivdi3+0x50>
f010431b:	39 f3                	cmp    %esi,%ebx
f010431d:	0f 87 bd 00 00 00    	ja     f01043e0 <__udivdi3+0xe0>
f0104323:	85 db                	test   %ebx,%ebx
f0104325:	89 d9                	mov    %ebx,%ecx
f0104327:	75 0b                	jne    f0104334 <__udivdi3+0x34>
f0104329:	b8 01 00 00 00       	mov    $0x1,%eax
f010432e:	31 d2                	xor    %edx,%edx
f0104330:	f7 f3                	div    %ebx
f0104332:	89 c1                	mov    %eax,%ecx
f0104334:	31 d2                	xor    %edx,%edx
f0104336:	89 f0                	mov    %esi,%eax
f0104338:	f7 f1                	div    %ecx
f010433a:	89 c6                	mov    %eax,%esi
f010433c:	89 e8                	mov    %ebp,%eax
f010433e:	89 f7                	mov    %esi,%edi
f0104340:	f7 f1                	div    %ecx
f0104342:	89 fa                	mov    %edi,%edx
f0104344:	83 c4 1c             	add    $0x1c,%esp
f0104347:	5b                   	pop    %ebx
f0104348:	5e                   	pop    %esi
f0104349:	5f                   	pop    %edi
f010434a:	5d                   	pop    %ebp
f010434b:	c3                   	ret    
f010434c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104350:	39 f2                	cmp    %esi,%edx
f0104352:	77 7c                	ja     f01043d0 <__udivdi3+0xd0>
f0104354:	0f bd fa             	bsr    %edx,%edi
f0104357:	83 f7 1f             	xor    $0x1f,%edi
f010435a:	0f 84 98 00 00 00    	je     f01043f8 <__udivdi3+0xf8>
f0104360:	89 f9                	mov    %edi,%ecx
f0104362:	b8 20 00 00 00       	mov    $0x20,%eax
f0104367:	29 f8                	sub    %edi,%eax
f0104369:	d3 e2                	shl    %cl,%edx
f010436b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010436f:	89 c1                	mov    %eax,%ecx
f0104371:	89 da                	mov    %ebx,%edx
f0104373:	d3 ea                	shr    %cl,%edx
f0104375:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104379:	09 d1                	or     %edx,%ecx
f010437b:	89 f2                	mov    %esi,%edx
f010437d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104381:	89 f9                	mov    %edi,%ecx
f0104383:	d3 e3                	shl    %cl,%ebx
f0104385:	89 c1                	mov    %eax,%ecx
f0104387:	d3 ea                	shr    %cl,%edx
f0104389:	89 f9                	mov    %edi,%ecx
f010438b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010438f:	d3 e6                	shl    %cl,%esi
f0104391:	89 eb                	mov    %ebp,%ebx
f0104393:	89 c1                	mov    %eax,%ecx
f0104395:	d3 eb                	shr    %cl,%ebx
f0104397:	09 de                	or     %ebx,%esi
f0104399:	89 f0                	mov    %esi,%eax
f010439b:	f7 74 24 08          	divl   0x8(%esp)
f010439f:	89 d6                	mov    %edx,%esi
f01043a1:	89 c3                	mov    %eax,%ebx
f01043a3:	f7 64 24 0c          	mull   0xc(%esp)
f01043a7:	39 d6                	cmp    %edx,%esi
f01043a9:	72 0c                	jb     f01043b7 <__udivdi3+0xb7>
f01043ab:	89 f9                	mov    %edi,%ecx
f01043ad:	d3 e5                	shl    %cl,%ebp
f01043af:	39 c5                	cmp    %eax,%ebp
f01043b1:	73 5d                	jae    f0104410 <__udivdi3+0x110>
f01043b3:	39 d6                	cmp    %edx,%esi
f01043b5:	75 59                	jne    f0104410 <__udivdi3+0x110>
f01043b7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01043ba:	31 ff                	xor    %edi,%edi
f01043bc:	89 fa                	mov    %edi,%edx
f01043be:	83 c4 1c             	add    $0x1c,%esp
f01043c1:	5b                   	pop    %ebx
f01043c2:	5e                   	pop    %esi
f01043c3:	5f                   	pop    %edi
f01043c4:	5d                   	pop    %ebp
f01043c5:	c3                   	ret    
f01043c6:	8d 76 00             	lea    0x0(%esi),%esi
f01043c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01043d0:	31 ff                	xor    %edi,%edi
f01043d2:	31 c0                	xor    %eax,%eax
f01043d4:	89 fa                	mov    %edi,%edx
f01043d6:	83 c4 1c             	add    $0x1c,%esp
f01043d9:	5b                   	pop    %ebx
f01043da:	5e                   	pop    %esi
f01043db:	5f                   	pop    %edi
f01043dc:	5d                   	pop    %ebp
f01043dd:	c3                   	ret    
f01043de:	66 90                	xchg   %ax,%ax
f01043e0:	31 ff                	xor    %edi,%edi
f01043e2:	89 e8                	mov    %ebp,%eax
f01043e4:	89 f2                	mov    %esi,%edx
f01043e6:	f7 f3                	div    %ebx
f01043e8:	89 fa                	mov    %edi,%edx
f01043ea:	83 c4 1c             	add    $0x1c,%esp
f01043ed:	5b                   	pop    %ebx
f01043ee:	5e                   	pop    %esi
f01043ef:	5f                   	pop    %edi
f01043f0:	5d                   	pop    %ebp
f01043f1:	c3                   	ret    
f01043f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01043f8:	39 f2                	cmp    %esi,%edx
f01043fa:	72 06                	jb     f0104402 <__udivdi3+0x102>
f01043fc:	31 c0                	xor    %eax,%eax
f01043fe:	39 eb                	cmp    %ebp,%ebx
f0104400:	77 d2                	ja     f01043d4 <__udivdi3+0xd4>
f0104402:	b8 01 00 00 00       	mov    $0x1,%eax
f0104407:	eb cb                	jmp    f01043d4 <__udivdi3+0xd4>
f0104409:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104410:	89 d8                	mov    %ebx,%eax
f0104412:	31 ff                	xor    %edi,%edi
f0104414:	eb be                	jmp    f01043d4 <__udivdi3+0xd4>
f0104416:	66 90                	xchg   %ax,%ax
f0104418:	66 90                	xchg   %ax,%ax
f010441a:	66 90                	xchg   %ax,%ax
f010441c:	66 90                	xchg   %ax,%ax
f010441e:	66 90                	xchg   %ax,%ax

f0104420 <__umoddi3>:
f0104420:	55                   	push   %ebp
f0104421:	57                   	push   %edi
f0104422:	56                   	push   %esi
f0104423:	53                   	push   %ebx
f0104424:	83 ec 1c             	sub    $0x1c,%esp
f0104427:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010442b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010442f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0104433:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104437:	85 ed                	test   %ebp,%ebp
f0104439:	89 f0                	mov    %esi,%eax
f010443b:	89 da                	mov    %ebx,%edx
f010443d:	75 19                	jne    f0104458 <__umoddi3+0x38>
f010443f:	39 df                	cmp    %ebx,%edi
f0104441:	0f 86 b1 00 00 00    	jbe    f01044f8 <__umoddi3+0xd8>
f0104447:	f7 f7                	div    %edi
f0104449:	89 d0                	mov    %edx,%eax
f010444b:	31 d2                	xor    %edx,%edx
f010444d:	83 c4 1c             	add    $0x1c,%esp
f0104450:	5b                   	pop    %ebx
f0104451:	5e                   	pop    %esi
f0104452:	5f                   	pop    %edi
f0104453:	5d                   	pop    %ebp
f0104454:	c3                   	ret    
f0104455:	8d 76 00             	lea    0x0(%esi),%esi
f0104458:	39 dd                	cmp    %ebx,%ebp
f010445a:	77 f1                	ja     f010444d <__umoddi3+0x2d>
f010445c:	0f bd cd             	bsr    %ebp,%ecx
f010445f:	83 f1 1f             	xor    $0x1f,%ecx
f0104462:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104466:	0f 84 b4 00 00 00    	je     f0104520 <__umoddi3+0x100>
f010446c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104471:	89 c2                	mov    %eax,%edx
f0104473:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104477:	29 c2                	sub    %eax,%edx
f0104479:	89 c1                	mov    %eax,%ecx
f010447b:	89 f8                	mov    %edi,%eax
f010447d:	d3 e5                	shl    %cl,%ebp
f010447f:	89 d1                	mov    %edx,%ecx
f0104481:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104485:	d3 e8                	shr    %cl,%eax
f0104487:	09 c5                	or     %eax,%ebp
f0104489:	8b 44 24 04          	mov    0x4(%esp),%eax
f010448d:	89 c1                	mov    %eax,%ecx
f010448f:	d3 e7                	shl    %cl,%edi
f0104491:	89 d1                	mov    %edx,%ecx
f0104493:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104497:	89 df                	mov    %ebx,%edi
f0104499:	d3 ef                	shr    %cl,%edi
f010449b:	89 c1                	mov    %eax,%ecx
f010449d:	89 f0                	mov    %esi,%eax
f010449f:	d3 e3                	shl    %cl,%ebx
f01044a1:	89 d1                	mov    %edx,%ecx
f01044a3:	89 fa                	mov    %edi,%edx
f01044a5:	d3 e8                	shr    %cl,%eax
f01044a7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01044ac:	09 d8                	or     %ebx,%eax
f01044ae:	f7 f5                	div    %ebp
f01044b0:	d3 e6                	shl    %cl,%esi
f01044b2:	89 d1                	mov    %edx,%ecx
f01044b4:	f7 64 24 08          	mull   0x8(%esp)
f01044b8:	39 d1                	cmp    %edx,%ecx
f01044ba:	89 c3                	mov    %eax,%ebx
f01044bc:	89 d7                	mov    %edx,%edi
f01044be:	72 06                	jb     f01044c6 <__umoddi3+0xa6>
f01044c0:	75 0e                	jne    f01044d0 <__umoddi3+0xb0>
f01044c2:	39 c6                	cmp    %eax,%esi
f01044c4:	73 0a                	jae    f01044d0 <__umoddi3+0xb0>
f01044c6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01044ca:	19 ea                	sbb    %ebp,%edx
f01044cc:	89 d7                	mov    %edx,%edi
f01044ce:	89 c3                	mov    %eax,%ebx
f01044d0:	89 ca                	mov    %ecx,%edx
f01044d2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01044d7:	29 de                	sub    %ebx,%esi
f01044d9:	19 fa                	sbb    %edi,%edx
f01044db:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01044df:	89 d0                	mov    %edx,%eax
f01044e1:	d3 e0                	shl    %cl,%eax
f01044e3:	89 d9                	mov    %ebx,%ecx
f01044e5:	d3 ee                	shr    %cl,%esi
f01044e7:	d3 ea                	shr    %cl,%edx
f01044e9:	09 f0                	or     %esi,%eax
f01044eb:	83 c4 1c             	add    $0x1c,%esp
f01044ee:	5b                   	pop    %ebx
f01044ef:	5e                   	pop    %esi
f01044f0:	5f                   	pop    %edi
f01044f1:	5d                   	pop    %ebp
f01044f2:	c3                   	ret    
f01044f3:	90                   	nop
f01044f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01044f8:	85 ff                	test   %edi,%edi
f01044fa:	89 f9                	mov    %edi,%ecx
f01044fc:	75 0b                	jne    f0104509 <__umoddi3+0xe9>
f01044fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0104503:	31 d2                	xor    %edx,%edx
f0104505:	f7 f7                	div    %edi
f0104507:	89 c1                	mov    %eax,%ecx
f0104509:	89 d8                	mov    %ebx,%eax
f010450b:	31 d2                	xor    %edx,%edx
f010450d:	f7 f1                	div    %ecx
f010450f:	89 f0                	mov    %esi,%eax
f0104511:	f7 f1                	div    %ecx
f0104513:	e9 31 ff ff ff       	jmp    f0104449 <__umoddi3+0x29>
f0104518:	90                   	nop
f0104519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104520:	39 dd                	cmp    %ebx,%ebp
f0104522:	72 08                	jb     f010452c <__umoddi3+0x10c>
f0104524:	39 f7                	cmp    %esi,%edi
f0104526:	0f 87 21 ff ff ff    	ja     f010444d <__umoddi3+0x2d>
f010452c:	89 da                	mov    %ebx,%edx
f010452e:	89 f0                	mov    %esi,%eax
f0104530:	29 f8                	sub    %edi,%eax
f0104532:	19 ea                	sbb    %ebp,%edx
f0104534:	e9 14 ff ff ff       	jmp    f010444d <__umoddi3+0x2d>
